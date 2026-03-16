# NANA Codex Operating Rules (Authoritative)

## Repo purpose
- Build and operate NANA: a calm-tech Flutter mobile app with Firebase-backed daily briefings (Firestore + Functions + FCM) and SerpApi-sourced content.

## Architecture snapshot
- Flutter client (`lib/`) handles startup, auth bootstrap, onboarding, profile editing, and briefing rendering.
- Firebase stack: anonymous auth, Firestore (`user_profiles`, `briefing_cache`), Cloud Functions v2 callable/scheduled jobs, FCM notifications.
- SerpApi is server-side only via `functions/src/serpapi.ts`.

## Critical directories
- `lib/main.dart`, `lib/app.dart`: startup chain and session bootstrap (**high risk**).
- `lib/services/notification_service.dart`: notification init/permission/full-screen behavior (**high risk**).
- `lib/repositories/profile_repository.dart`: profile bootstrap + token persistence.
- `functions/src/`: callable + scheduler + external API integration.
- `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`: deployment truth.
- `docs/codex/`: long-form runbooks and task templates.

## Required local commands (run relevant ones before done)
- Flutter deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Functions deps/build: `cd functions && npm ci && npm run build`
- Functions lint (if configured): `cd functions && npm run lint`

## Startup-critical path rules
- Treat changes touching `main.dart`, `app.dart`, auth bootstrap, onboarding gate, profile bootstrap, or notification init as high-risk.
- Never block first paint with non-essential work.
- Keep startup async steps bounded with explicit timeouts or clear loading/fallback UI.
- Never swallow initialization exceptions; log context and show recoverable UI state.
- Any startup-path change must include explicit validation steps in the final report.

## Firebase / Firestore / Functions safety
- Never hardcode secrets, API keys, tokens, service-account material, or project credentials.
- Never silently change Firebase project IDs, app IDs, package/bundle IDs, regions, or deploy targets.
- Preserve `us-central1` consistency unless explicitly requested and migration impact is documented.
- Keep callable/scheduled function contracts backward-compatible unless the task explicitly approves breakage.
- Firestore changes must keep profile bootstrap (`getOrCreateProfile`) and scheduled briefing flow compatible.

## Secrets handling
- Do not commit `.env`, real keys, `android/app/google-services.json`, or `ios/Runner/GoogleService-Info.plist` unless explicitly requested.
- Use `.env.example` patterns and docs for required variables.

## Git / change management
- Prefer surgical edits over rewrites.
- Do not reformat or move unrelated files.
- Keep commits small, scoped, and descriptive.
- If assumptions are required, choose the safest option and state assumptions + risk.

## Definition of done (every task)
- Requested scope implemented with minimal diff.
- Relevant analysis/tests/build commands run (or blocked reason documented).
- Assumptions, risks, and follow-ups explicitly called out.
- Changed files summarized with why each changed.

## Hard NEVER rules
- Never invent nonexistent files, collections, routes, commands, or infrastructure.
- Never weaken security rules just to “make it work.”
- Never make startup less diagnosable.
- Never do broad architecture churn without explicit approval.
- Never remove operational docs/comments unless replaced by better guidance.

## Review guidelines (GitHub/Matt)
- Provide file-by-file summary, validation evidence, and known risks.
- Highlight startup/Firebase impact first.
- Call out deploy impacts (Firestore rules/indexes/functions) and exact commands reviewers should run.

## Planning behavior
- For non-trivial tasks: inspect affected flows first, write a brief plan, then edit.
- Prefer reversible steps and checkpoint validation over large one-shot changes.
