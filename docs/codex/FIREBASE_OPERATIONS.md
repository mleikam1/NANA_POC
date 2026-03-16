# Firebase Operations Guide (NANA)

## FlutterFire configure expectations
- Run `flutterfire configure` whenever package ID/bundle ID/app registration changes.
- Regeneration must keep app IDs aligned with:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json` (local)
  - `ios/Runner/GoogleService-Info.plist` (local)
- Do not manually hand-edit app IDs unless absolutely necessary.

## Firebase project alignment rules
- Current default project in repo: `nanapoc-7c5f9` (`.firebaserc`, `firebase.json`).
- Any project switch requires explicit task approval + documented impact on dev/prod data.
- Never silently repoint deploys.

## Package/bundle/app ID sensitivity
- Android package ID, iOS bundle ID, and Firebase app IDs must remain aligned.
- Mismatch can present as startup Firebase init failures or messaging token issues.
- If IDs change, document exact files touched and re-run Firebase setup checks.

## Anonymous auth expectations
- Anonymous auth is required for bootstrap path.
- Disabling anonymous auth in Firebase Console breaks onboarding/home gate.
- If auth model changes, design migration path first (not in opportunistic refactors).

## Firestore deployment flow
1. Update `firestore.rules` and/or `firestore.indexes.json`.
2. Validate with emulator where possible.
3. Deploy explicitly:
   - `firebase deploy --only firestore:rules`
   - `firebase deploy --only firestore:indexes`
4. Record behavioral impact in PR/task notes.

## Firestore rules/index discipline
- Keep least-privilege owner rules for `user_profiles` and `briefing_cache`.
- Do not broaden reads/writes without explicit rationale.
- Add indexes only for proven query needs.

## Functions deployment flow
1. `cd functions && npm ci && npm run build`
2. Optional lint/tests if present.
3. Deploy explicit scope:
   - `firebase deploy --only functions:getDailyBriefing`
   - `firebase deploy --only functions:sendScheduledBriefings`
   - or `firebase deploy --only functions`
4. Verify region remains `us-central1` unless migration plan approved.

## Env var handling
- `SERPAPI_KEY` required by `functions/src/serpapi.ts`.
- Local: use untracked `functions/.env` based on `.env.example`.
- Hosted: use Firebase Functions environment/secrets tooling.
- Never reference secrets from client code.

## Secrets rules
- Never commit:
  - `.env`
  - real API keys
  - service account JSONs
  - `google-services.json` / `GoogleService-Info.plist` unless explicitly requested.
- Use placeholders/examples in docs only.

## Regional consistency rules
- Keep Functions callable + scheduler in `us-central1` and Flutter callable client configured to same region (`AppConfig.functionsRegion`).
- Region mismatch can create callable failures and latency spikes.

## Must never be committed
- Secret values, private tokens, local emulator state, or generated credentials.
- Unreviewed project-target changes (`.firebaserc`, deploy targets).

## Local config vs deployed config
- Local developer config can differ for testing, but changes must not be committed unless intended for team-wide baseline.
- If local-only behavior is required, isolate with ignored files and document override steps.
