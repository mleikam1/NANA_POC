# Codex Task Template (NANA)

## Objective
- What exactly must change?
- What should stay unchanged?

## Repo context
- Relevant architecture paths:
  - Flutter:
  - Firebase/Firestore:
  - Functions:
- Startup-path impact? (yes/no)
- Notification-path impact? (yes/no)

## Constraints
- In-scope files:
- Out-of-scope files:
- UX constraints (calm-tech, no noisy patterns):
- Firebase constraints (project/region/secrets immutability):

## Plan
1.
2.
3.

## Affected files (expected)
- `path/to/file` — reason

## Risk analysis
- Primary risks:
- Regression risks:
- Security/config risks:
- Mitigations:

## Validation steps (required)
- `flutter analyze`
- `flutter test`
- `cd functions && npm run build` (when `functions/` touched)
- Additional task-specific checks:

## Rollback path
- Commit-level rollback strategy:
- Data/contract rollback considerations:

## Final response format (required)
1. Summary of changes by file.
2. Validation commands + results.
3. Assumptions made.
4. Risks and follow-up work.

## Done checklist
- [ ] Scope respected with minimal diff.
- [ ] No unrelated churn/reformatting.
- [ ] Startup/Firebase risks called out explicitly.
- [ ] Validation executed and reported.
- [ ] Assumptions + follow-up documented.
