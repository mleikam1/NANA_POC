# lib/ Codex Rules

Applies to all Flutter client code under `lib/`.

- Treat `main.dart`, `app.dart`, `services/notification_service.dart`, onboarding, and profile bootstrap paths as high-risk.
- Keep startup non-blocking and diagnosable; preserve timeout/error-path behavior.
- Keep theming centralized in `theme/`; avoid ad-hoc style constants in screens.
- Preserve calm-tech UX (low-noise copy, no manipulative UI patterns).
- Do not change Firestore field names or callable payload contracts without coordinated backend/client updates in same task.
- Prefer surgical widget/repository edits over architectural rewrites.
