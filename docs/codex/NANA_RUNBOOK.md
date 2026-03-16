# NANA Codex Runbook

## 1) Mission and product intent
NANA is a calm-tech daily companion: low-noise utility, predictable daily briefing, and minimal-cortisol UX. Engineering choices must optimize startup reliability, trust, and operational safety over novelty.

## 2) Engineering philosophy
- Prefer small, reversible changes.
- Keep startup paths observable and bounded.
- Optimize for maintainability over abstraction cleverness.
- Keep user-facing behavior stable unless task explicitly requests UX change.
- Backend contracts are product contracts; avoid silent breakage.

## 3) Calm-tech UX guardrails (enforced)
- Avoid addictive loops, noisy badge spam, aggressive prompts, and manipulative urgency.
- Preserve breathing room in layouts and copy.
- Prefer gentle fallback text over technical jargon.
- Any notification or permission flow must be intentionally timed and justified.

## 4) Architecture map
### Flutter client (`lib/`)
- `main.dart`: app startup orchestration: Firebase init, FCM background handler registration, notification service init, startup error capture.
- `app.dart`: `MaterialApp`, `SessionGate`, auth bootstrap, profile bootstrap, onboarding/home routing.
- `services/auth_service.dart`: anonymous sign-in gateway.
- `services/notification_service.dart`: local notification channel, notification permissions, FCM foreground/open handling, preview flow.
- `repositories/profile_repository.dart`: Firestore read/write for `user_profiles` + messaging tokens.
- `repositories/briefing_repository.dart`: callable invocation (`getDailyBriefing`) + mock fallback.
- `screens/`: onboarding, shell tabs, care settings.

### Backend (`functions/`)
- `src/index.ts`
  - `getDailyBriefing` callable: authenticated, requires `locationLabel`, builds bundle from SerpApi, caches into `briefing_cache`.
  - `sendScheduledBriefings` scheduler (every 15 min): checks profile notification preferences, sends FCM multicast, writes `lastNotificationKey`.
- `src/serpapi.ts`: SerpApi wrapper, normalization, key via `process.env.SERPAPI_KEY`.

### Firebase config & policies
- `firebase.json`, `.firebaserc`: deploy source + project mapping.
- `firestore.rules`: owner-based access on `user_profiles` and `briefing_cache`.
- `firestore.indexes.json`: currently empty.

## 5) Startup chain map (actual)
1. `main()` binds Flutter runtime.
2. `Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform`, 12s timeout.
3. Register `FirebaseMessaging.onBackgroundMessage`.
4. `NotificationService.initialize`, 8s timeout.
5. `runApp(NanaApp(...))` with optional startup error.
6. `SessionGate._bootstrap()`:
   - `ensureSignedIn()` anonymous auth.
   - `getOrCreateProfile(uid)` Firestore bootstrap.
   - `getFcmToken()` + persist token.
   - route to onboarding or home shell.

## 6) Onboarding chain map
- Incomplete or missing profile routes to `OnboardingScreen`.
- Collects topics, location (manual/coordinates), notification preferences.
- `onComplete` writes profile and sets `onboardingComplete=true`.
- Timezone defaults to `America/Chicago` unless profile already set.

## 7) Auth/bootstrap flow expectations
- Auth is anonymous-first. Breaking anonymous auth blocks entire app path.
- `uid` continuity is critical for profile + cache ownership.
- Do not introduce auth-dependent UI before bootstrap completion unless graceful fallbacks are explicit.

## 8) Firestore profile lifecycle
- Collection: `user_profiles/{uid}`.
- Creation path in `getOrCreateProfile` with defaults + server timestamps.
- Ongoing updates use merge semantics.
- Messaging tokens stored with `arrayUnion`.
- Be careful: `onboarding_screen.dart` builds profile with empty uid when no existing profile; this relies on existing profile being present after bootstrap. Preserve this invariant or harden it if touched.

## 9) Notification lifecycle
- Init in `main()` via `NotificationService.initialize()`.
- Requests FCM permission during init (currently startup-adjacent; high UX sensitivity).
- Foreground messages -> local notification.
- Open notification routes via `_routeToBriefing` placeholder.
- Care screen can request full-screen permission + preview local notification.
- Scheduled pushes from Cloud Functions use profile preferences + timezone.

## 10) Backend/API architecture
- Client should never call SerpApi directly.
- Cloud Function builds weather/news/recipes/videos/AI overview bundle and returns unified payload.
- Caching in `briefing_cache` keyed by `uid_yyyyMMdd` UTC.
- Scheduler avoids duplicate daily sends with `lastNotificationKey`.

## 11) SerpApi server-side handling expectations
- `SERPAPI_KEY` must exist in function runtime env.
- External request failures should be logged with context and handled without crashing all user sends.
- Keep output shape stable for Flutter parsing in `BriefingBundle.fromMap`.
- If changing normalization fields, coordinate with client model updates in same PR.

## 12) Functions deployment conventions
- Build before deploy:
  - `cd functions && npm ci && npm run build`
- Deploy target should be explicit (`--only functions` or specific functions).
- Region should remain `us-central1` unless migration plan covers:
  - callable region in app config,
  - scheduler region,
  - data locality implications,
  - rollout + rollback.

## 13) Firestore deployment conventions
- Update `firestore.rules` and `firestore.indexes.json` together when needed.
- Validate rules with emulator where possible.
- Deploy with explicit scope (`firebase deploy --only firestore:rules,firestore:indexes`).

## 14) Local development workflow
1. `flutter pub get`
2. `cd functions && npm ci && npm run build && cd ..`
3. Optional emulators: `firebase emulators:start`
4. Run app: `flutter run -d <device>`
5. Validate: `flutter analyze && flutter test`

## 15) Android-first workflow (with intentional iOS/web handling)
- Primary runtime is Android due full-screen intent testing and notification behavior.
- Keep iOS/web compile sanity unless task explicitly Android-only.
- Any Android-specific permission or manifest behavior must call out iOS parity gaps.

## 16) Debugging methodology
- Reproduce once, instrument minimally, confirm hypothesis, patch surgically, revalidate startup and affected flow.
- Prefer targeted logs near async boundaries.
- Remove noisy debug-only instrumentation before finalizing unless operationally useful.

## 17) Code review checklist
- Is scope minimal and reversible?
- Any startup-path risk introduced?
- Any Firebase project/region/rules/deploy target changes?
- Are secrets/config safe?
- Are function/client contracts still aligned?
- Is calm-tech UX preserved?

## 18) Validation checklist (before claiming done)
- `flutter analyze`
- `flutter test`
- `cd functions && npm run build`
- If backend changed: deploy commands documented (not executed unless asked).
- If startup touched: cold-start test evidence and fallback/error-path behavior checked.

## 19) Release readiness checklist
- No secret leakage.
- Firebase project alignment verified.
- Rules/index/function changes reviewed together.
- Startup path tested on clean launch.
- Notification behavior tested for foreground/open + scheduled path assumptions.

## 20) Rollback strategy
- Keep commits granular so each risky area (startup, functions, rules) can be reverted independently.
- For backend contract changes, deploy additive first, then remove deprecated fields in later PR.
- If scheduler causes bad sends, disable function or deploy previous revision immediately.

## 21) Common Codex failure modes in this repo
1. Editing startup chain without preserving timeout/fallback behavior.
2. Moving SerpApi usage client-side and leaking key risk.
3. Breaking callable payload shape expected by `BriefingBundle.fromMap`.
4. Changing region in Functions but not Flutter `AppConfig.functionsRegion`.
5. Touching `firebase.json` or `.firebaserc` unintentionally.
6. Overwriting user profile semantics (`uid`, `onboardingComplete`, notification fields).
7. Introducing unrelated formatting churn.
8. Treating full-screen intent as guaranteed production capability.
9. Ignoring timezone logic in scheduled notifications.
10. Claiming success without `flutter analyze` + functions build.

## 22) How future Codex tasks should be prompted
Use this structure:
1. Objective and user-visible outcome.
2. Scope boundaries (files/areas explicitly in/out).
3. Risk tolerance (startup/Firebase/notification sensitivity).
4. Required validation commands.
5. Expected final deliverables (diff summary, assumptions, risks, follow-ups).

Example prompt starter:
> Modify only `lib/screens/care_screen.dart` and `lib/repositories/profile_repository.dart` to add one profile toggle. Do not change startup. Keep Firestore schema backward compatible. Run `flutter analyze` and `flutter test`. Report assumptions and rollback plan.
