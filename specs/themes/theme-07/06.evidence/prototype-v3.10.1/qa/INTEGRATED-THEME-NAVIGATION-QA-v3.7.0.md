# Integrated Theme Navigation QA — v3.7.0

**Result: PASS · 16/16 PASS**

- Workbench modes: **Theo BJ / UIF** + **Toàn Theme 7**.
- Integrated entry: **Thêm → Kho**.
- Kho coverage: **17 BJ + CAP-01 = 18 entries**.
- Runtime strategy: **shared renderers/state; no duplicated business screens**.

## Checks

- PASS — runtime version
- PASS — exactly two workbench mode tabs
- PASS — existing BJ/UIF mode is default and selector remains visible
- PASS — Theme 7 tab switches to integrated mode
- PASS — integrated mode starts at Them
- PASS — Them screen exposes Kho as the single enabled Theme 7 module entry
- PASS — out-of-scope More rows are true Disabled Navigation rows
- PASS — Kho module root is reachable from Them
- PASS — Kho root exposes all 17 BJ plus CAP-01
- PASS — Kho root uses Navigation List Row anatomy for every entry
- PASS — every Theme 7 entry opens its own shared flow runtime
- PASS — every Theme 7 flow entry has a deterministic Back to Kho
- PASS — integrated mode reuses BJ08 existing screen renderer
- PASS — switching back restores BJ/UIF workbench mode
- PASS — legacy screen navigation remains rendered
- PASS — no browser page errors
