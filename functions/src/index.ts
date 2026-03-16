import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { DateTime } from 'luxon';

import {
  fetchAiOverview,
  fetchLocalNews,
  fetchRecipes,
  fetchShortVideos,
  fetchWeather,
} from './serpapi.js';

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

function todayCacheId(uid: string): string {
  return `${uid}_${DateTime.utc().toFormat('yyyyLLdd')}`;
}

async function buildBundle(locationLabel: string, topics: string[]) {
  const recipeSeed =
    topics.find((item) => /recipe|meal|food|cook/i.test(item)) ??
    'easy weeknight dinner recipes';
  const shortVideoSeed =
    topics.find((item) => /calm|video|reset|routine|cozy/i.test(item)) ??
    'calm home reset short videos';

  const [weather, localNews, recipes, shortVideos, aiOverview] = await Promise.all([
    fetchWeather(locationLabel),
    fetchLocalNews(locationLabel),
    fetchRecipes(recipeSeed),
    fetchShortVideos(shortVideoSeed),
    fetchAiOverview(
      `Create a calm daily overview for ${locationLabel} focused on ${
        topics.join(', ') || 'weather, local news, recipes, and calm routines'
      }`,
    ),
  ]);

  return {
    weather,
    localNews,
    recipes,
    shortVideos,
    aiOverviewTitle: aiOverview.aiOverviewTitle,
    aiOverviewBullets: aiOverview.aiOverviewBullets,
    generatedAt: new Date().toISOString(),
  };
}

export const getDailyBriefing = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'A signed-in user is required.');
    }

    const uid = request.auth.uid;
    const locationLabel = String(request.data?.locationLabel ?? '').trim();
    const topics = Array.isArray(request.data?.topics)
      ? request.data.topics.map((item: unknown) => String(item))
      : [];

    if (!locationLabel) {
      throw new HttpsError('invalid-argument', 'locationLabel is required.');
    }

    const bundle = await buildBundle(locationLabel, topics);

    await db.collection('briefing_cache').doc(todayCacheId(uid)).set(
      {
        uid,
        generatedAt: FieldValue.serverTimestamp(),
        bundle,
      },
      { merge: true },
    );

    return bundle;
  },
);

export const sendScheduledBriefings = onSchedule(
  {
    region: 'us-central1',
    schedule: 'every 15 minutes',
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const snapshot = await db.collection('user_profiles').get();
    const nowUtc = DateTime.utc();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const uid = doc.id;
      const preferences = (data.notificationPreferences ?? {}) as Record<string, unknown>;
      const enabled = Boolean(preferences.enabled);
      const hour = Number(preferences.hour ?? 8);
      const minute = Number(preferences.minute ?? 0);
      const timeZone = String(preferences.timeZone ?? 'America/Chicago');
      const fullScreenIntent = Boolean(preferences.fullScreenIntent);
      const locationLabel = String(data.locationLabel ?? '').trim();
      const topics = Array.isArray(data.topics)
        ? data.topics.map((item: unknown) => String(item))
        : [];
      const tokens = Array.isArray(data.messagingTokens)
        ? data.messagingTokens.map((item: unknown) => String(item)).filter(Boolean)
        : [];

      if (!enabled || tokens.length === 0 || !locationLabel) {
        continue;
      }

      const localNow = nowUtc.setZone(timeZone);
      const minuteDelta = Math.abs(
        localNow.hour * 60 + localNow.minute - (hour * 60 + minute),
      );

      if (minuteDelta > 14) {
        continue;
      }

      const todayKey = `${localNow.toFormat('yyyy-LL-dd')}-${hour
        .toString()
        .padStart(2, '0')}${minute.toString().padStart(2, '0')}`;

      if (data.lastNotificationKey === todayKey) {
        continue;
      }

      let bundle = undefined as any;
      const cacheDoc = await db.collection('briefing_cache').doc(todayCacheId(uid)).get();
      if (cacheDoc.exists) {
        bundle = cacheDoc.data()?.bundle;
      } else {
        try {
          bundle = await buildBundle(locationLabel, topics);
          await db.collection('briefing_cache').doc(todayCacheId(uid)).set(
            {
              uid,
              generatedAt: FieldValue.serverTimestamp(),
              bundle,
            },
            { merge: true },
          );
        } catch (error) {
          logger.error('Failed to generate bundle for scheduled send', { uid, error });
          continue;
        }
      }

      const title = 'Your NANA briefing is ready';
      const body =
        bundle?.weather?.weather && bundle?.weather?.temperature
          ? `${bundle.weather.weather} and ${bundle.weather.temperature}° in ${bundle.weather.location}. Open your calmer daily companion.`
          : 'A calmer daily summary is waiting for you.';

      try {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title,
            body,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'nana_briefing_channel',
              priority: 'max',
              defaultSound: true,
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
              },
            },
          },
          data: {
            route: 'briefing',
            fullScreenIntent: String(fullScreenIntent),
          },
        });

        await doc.ref.set(
          {
            lastNotificationKey: todayKey,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      } catch (error) {
        logger.error('Failed to send scheduled briefing', { uid, error });
      }
    }
  },
);
