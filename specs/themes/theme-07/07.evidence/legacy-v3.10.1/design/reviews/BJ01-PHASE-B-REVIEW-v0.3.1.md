# BJ-01 — Phase B Review v0.3.1

> This artifact records the BJ-01 design candidate only. Product has explicitly prioritized **baseline preservation/isolation** before judging BJ-01 correctness.

## Candidate architecture
`SCR-001 Tồn kho → SCR-003 Chi tiết tồn kho → SCR-004 Chi tiết lô (conditional)`

`SCR-005` is represented as a provenance Bottom Sheet from SCR-003. Deep trace is handed off to BJ-15.

## Release rule for this correction
v0.3.1 is valid only if protected BJ-02/non-BJ01 artifacts remain identical to the exact v0.2.9 input, except for explicitly listed shared metadata/HTML files whose changes are additive and regression-tested.
