# CATALOG — golden-family (EXAMPLE_ONLY)

SSOT `design_status` cho fixture bar B. Pseudo-domain `pin-label` — không dùng trên theme thật.

| id | title | path | design_status | depends_on | sources | family | produces / coverage | lanes / links | blocked_reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SL-010 | Pin label — contract | SL-010-pin-label.be-contract.md | READY_TO_IMPLEMENT | | EXAMPLE-UC-01 | pin-label | Command/DTO + fake | be-contract | |
| SL-011 | Pin label — BE impl | SL-011-pin-label.be-impl.md | READY_TO_IMPLEMENT | SL-010 | EXAMPLE-UC-01 | pin-label | RPC / persistence | be-impl | |
| SL-012 | Pin label — FE | SL-012-pin-label.fe.md | READY_TO_IMPLEMENT | SL-010 | EXAMPLE-SCR-01 | pin-label | Screen pin | fe | |
| SL-013 | Pin label — E2E | SL-013-pin-label.e2e.md | READY_TO_IMPLEMENT | SL-011, SL-012 | EXAMPLE-UC-01 | pin-label | Happy path | e2e | |
