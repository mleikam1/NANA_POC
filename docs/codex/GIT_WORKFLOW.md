# Git Workflow Guide (NANA)

## Branching expectations
- Work on a task branch; keep one concern per branch.
- Avoid mixing Flutter UI, startup internals, and backend deploy changes unless tightly coupled.

## Small safe commit strategy
- Commit in logical checkpoints (docs, startup logic, backend changes separately when possible).
- Prefer atomic commits that can be reverted independently.

## Edit vs replace files
- Prefer editing existing files to preserve history and context.
- Replace files only when structure is fundamentally changing and reviewer clarity improves.
- Avoid mass rewrites for style-only reasons.

## Avoid unrelated churn
- Do not run broad formatting across untouched areas.
- Do not reorder imports, rename symbols, or change whitespace outside scope.
- Keep lockfile/config churn intentional and explained.

## Preserve user work
- Never discard unknown local changes unless task explicitly says so.
- If encountering pre-existing modifications, isolate your changes and call out overlap risks.

## Summarize code changes clearly
- Report by file:
  - what changed,
  - why it changed,
  - startup/Firebase/notification risk impact.

## Prepare work for Matt review
- Prioritize practical reviewer signal:
  - startup safety,
  - Firebase/deploy implications,
  - user-visible behavior,
  - rollback ease.
- Include concrete commands Matt can run to verify.

## Before opening a PR
- Ensure scope is minimal and complete.
- Run required checks:
  - `flutter analyze`
  - `flutter test`
  - `cd functions && npm run build` (if functions touched)
- Review diff for accidental secrets/config target changes.
- Confirm docs updated when operational behavior changed.
