# functions/ Codex Rules

Applies to Firebase Functions code under `functions/`.

- Keep function region consistent (`us-central1`) unless explicit migration is part of task.
- Preserve callable/scheduler contracts unless breaking change is explicitly approved.
- All external API access must remain server-side; never move SerpApi calls to Flutter client.
- Validate inputs and fail with explicit `HttpsError` where applicable.
- Never hardcode secrets; use env/secrets only (`SERPAPI_KEY`).
- Run `npm run build` before claiming function changes done.
