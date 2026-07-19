# vet45_resend

HTTP client for [Resend](https://resend.com) email API — reusable by messaging worker and module infrastructure.

## API

- `IResendClient` / `ResendSendResult`
- `ResendEmailClient` — real HTTP; missing `RESEND_API_KEY` soft-fails (`missing_RESEND_API_KEY`)
- `FakeResendClient` / `FakeResendScenario` — unit tests, no network

## Env

Set `RESEND_API_KEY` on the messaging worker (see `config/default/*.env.example`).
