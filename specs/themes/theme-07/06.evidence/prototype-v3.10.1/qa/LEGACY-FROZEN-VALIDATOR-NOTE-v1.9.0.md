# Legacy frozen validator note — v1.9.0

**Status: NOT A CURRENT RELEASE GATE**

The frozen package validator under `specs/themes/theme-07/validation/validate-package.py` targets an older prototype package schema.

After regenerating the current `prototype/screen-map.md`, the validator exits with `FileNotFoundError` because it requires legacy `prototype/prototype.manifest.json`, which is not an artifact of the current cumulative Harness.

Evidence: `LEGACY-FROZEN-VALIDATOR-v1.9.0.log`.

V1.9.0 does **not** fabricate historical files just to make this validator green. Current release readiness is checked by:

- `HOLISTIC-STATIC-QA-v1.9.0.md`
- `HOLISTIC-HARDENING-QA-v1.9.0.md`
- `VISUAL-QA-v1.9.0.md`
- `TOPOLOGY-REGRESSION-QA-v1.9.0.md`
- `SOURCE-IMMUTABILITY-QA-v1.9.0.md`
- `ALL-FLOWS-RUNTIME-SMOKE-v1.9.0.md`

This boundary is explicit to avoid a false claim that static green status on an obsolete schema is equivalent to current Product correctness.
