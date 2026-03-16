# Startup Debugging Guide (NANA)

## Exact startup sequence
1. `lib/main.dart`
   - `WidgetsFlutterBinding.ensureInitialized()`
   - `Firebase.initializeApp(...).timeout(12s)`
   - register `FirebaseMessaging.onBackgroundMessage`
   - `NotificationService.initialize().timeout(8s)`
   - `runApp(NanaApp(startupErrorMessage: ...))`
2. `lib/app.dart` -> `SessionGate`
   - `AuthService.ensureSignedIn()`
   - `ProfileRepository.getOrCreateProfile(uid)`
   - `NotificationService.getFcmToken()` and persist token
   - route to onboarding/home

## Debugging hangs in `main.dart`
- Confirm logs reach each step (`MAIN:` markers already present).
- If hang before Firebase initialized:
  - verify generated `lib/firebase_options.dart` matches platform config.
  - verify Android/iOS Firebase files are present locally (but not committed unless requested).
- If hang during notification init:
  - temporarily log each substep in `NotificationService.initialize()`.
  - confirm permission prompt handling does not deadlock UI.

## Firebase init troubleshooting
- Symptoms: startup error splash with Firebase failure.
- Checks:
  - `flutterfire configure` has been run for current package IDs.
  - `firebase_options.dart` project/app IDs align with platform files.
  - No accidental project switch in `.firebaserc`/`firebase.json`.
- Keep timeout and error reporting in place; do not hide failures.

## Notification init troubleshooting
- Symptoms: startup delay, permission issues, missing channel, no foreground notifications.
- Checks:
  - Android notification channel created (`nana_briefing_channel`).
  - Permission request result is handled and logged.
  - Full-screen permission request only in Care preview flow, not forced at cold start.

## Auth bootstrap troubleshooting
- Symptoms: app stuck on splash with `SESSION:` errors.
- Checks:
  - Firebase Auth anonymous provider enabled.
  - Network access available.
  - `ensureSignedIn()` returning non-null user.

## Firestore profile bootstrap troubleshooting
- Symptoms: onboarding loops, profile missing, write/read denied.
- Checks:
  - `user_profiles/{uid}` exists after bootstrap.
  - Firestore rules allow owner create/read/update.
  - Profile document includes required shape (`uid`, `onboardingComplete`, `notificationPreferences`).

## Onboarding dead-end troubleshooting
- Symptoms: cannot finish onboarding or returns to onboarding after save.
- Checks:
  - `onComplete` writes with correct `uid`.
  - `onboardingComplete` set `true`.
  - stream updates in `HomeShell` do not overwrite fresh state unexpectedly.

## Timeout/defer guidance
- Startup-critical work should remain bounded by explicit timeouts.
- Non-critical work (analytics, non-essential prefetch) should be deferred until after first paint.
- Never trade diagnosability for perceived startup speed.

## Logging expectations for startup issues
- Use concise structured prefixes (`MAIN:`, `SESSION:`, `BG:`).
- Log failures with stack traces for async boundaries.
- Remove noisy debug spam; keep operationally useful breadcrumbs.
- In PR/task summary include:
  - failing step,
  - reproduction condition,
  - mitigation,
  - remaining risk.
