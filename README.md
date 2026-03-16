# NANA POC Starter

This starter gives you a calm-tech Flutter shell plus a Firebase + Firestore + Cloud Functions backend scaffold for the NANA concept.

## What is included

- Anonymous Firebase auth bootstrap
- Firestore-backed user profile and notification preferences
- Animated onboarding for:
  - topic interests
  - manual city / zip entry
  - optional location permission
  - scheduled briefing preferences
- A 5-tab calm-tech shell:
  - **Home**
  - **Local**
  - **Nourish**
  - **Unwind**
  - **Care**
- Firebase callable function proxy for SerpApi:
  - weather / answer box
  - local news
  - recipes
  - short videos
  - AI overview
- Scheduled backend job scaffold to send daily briefing push notifications
- Android full-screen-intent friendly notification scaffold for POC testing
- Firestore rules and Firebase config starter files

## Important constraints for this starter

This is a **real starter scaffold**, not a finished production app.

Two areas are intentionally scaffolded rather than fully productionized:

1. **Firebase platform configuration**
   - You still need to run `flutterfire configure`
   - You still need Android/iOS Firebase files in your platform folders

2. **Full-screen intent notifications**
   - Android supports full-screen intent notifications, but Android 14+ limits normal use of `USE_FULL_SCREEN_INTENT` to calling/alarm-style apps, and Play can revoke the default grant for other app categories.
   - For this POC, the code includes:
     - high-priority notifications
     - permission request flow
     - a local full-screen preview path
     - Firestore-backed schedule preferences
   - For production, you will likely need to position this closer to an alarm/reminder pattern instead of assuming unrestricted lock-screen takeover behavior.

## Suggested setup flow

### 1) Create the Flutter project shell

```bash
mkdir nana_poc
cd nana_poc
flutter create . --platforms=android,ios
```

### 2) Copy these starter files in

Replace the generated `lib/`, `pubspec.yaml`, and Firebase config files with the ones in this starter.

### 3) Add Firebase to Flutter

Follow the FlutterFire setup:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4) Install packages

```bash
flutter pub get
```

### 5) Create Firebase backend resources

From the repo root:

```bash
firebase init firestore
firebase init functions
```

Use the included `functions/`, `firestore.rules`, `firestore.indexes.json`, and `firebase.json` as your source of truth.

### 6) Set your SerpApi key for Functions

Use local `.env` for emulator work or Firebase secrets / env for deployed functions.

Example for local emulator:

```bash
cd functions
cp .env.example .env
# then place your real SERPAPI_KEY value in .env
npm install
npm run build
cd ..
```

### 7) Run locally

```bash
flutter run
```

For backend local testing:

```bash
firebase emulators:start
```

## Firestore collections used

### `user_profiles/{uid}`

```json
{
  "uid": "abc123",
  "locationLabel": "Dallas, TX",
  "topics": ["Local News", "Easy Recipes", "Calm Videos"],
  "onboardingComplete": true,
  "notificationPreferences": {
    "enabled": true,
    "hour": 8,
    "minute": 15,
    "timeZone": "America/Chicago",
    "fullScreenIntent": true
  },
  "messagingTokens": ["..."],
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp",
  "lastNotificationKey": "2026-03-15-0815"
}
```

### `briefing_cache/{uid_yyyyMMdd}`

```json
{
  "uid": "abc123",
  "generatedAt": "serverTimestamp",
  "bundle": {
    "...": "callable response payload"
  }
}
```

## Android notes

Add these Android permissions / capabilities into your generated Android project if they are not already present:

- `POST_NOTIFICATIONS`
- `USE_FULL_SCREEN_INTENT`
- `RECEIVE_BOOT_COMPLETED`
- exact alarms if you later move to device-side exact scheduling

This starter includes an `android_manifest_patch.xml` file with the relevant additions.

## iOS notes

You will still need the normal iOS notification setup plus location permission descriptions in `Info.plist`.

## Bottom bar recommendation

The app already ships with the bottom bar I recommend for the NANA POC:

- **Home** — the daily “good for me” briefing
- **Local** — weather, local news, community utility
- **Nourish** — recipes, meal ideas, practical home comfort
- **Unwind** — calm short videos and decompression content
- **Care** — preferences, schedules, topics, and notification controls

## Why the architecture is shaped this way

This starter keeps the app lightweight and puts SerpApi behind callable Firebase functions so the client does not become the permanent home for third-party API credentials. That aligns better with how you will want Codex to expand this later.

## Helpful next files for Codex after you commit this

1. native Android full-screen reminder flow
2. richer Firestore content cache
3. Remote Config theme and feed experimentation
4. deeper local utility cards
5. branded notification landing experience
6. onboarding analytics events
7. soft-haptics + polished motion system
