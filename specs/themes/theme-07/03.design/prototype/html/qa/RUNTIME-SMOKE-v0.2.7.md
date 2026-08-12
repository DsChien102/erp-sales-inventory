# BJ-02 Runtime Fixture Smoke v0.2.7

**Result: 10/10 PASS**

Runtime renderer smoke through the BJ-02 mandatory fixture matrix. This complements static DS/contract validation; it is not a pixel-visual regression test.

- [x] Document · 1 Product · NONE
- [x] Document · nhiều Product
- [x] Document · partial / Chưa nhận lần này
- [x] LOT · 1 lot
- [x] LOT · nhiều lot
- [x] Quick · nhiều Product
- [x] Quick · same Product, different UOM
- [x] Quick · duplicate same Product + UOM is blocked
- [x] LOT expiry conflict is a blocking state
- [x] Missing Supplier/Product master → no-create state

## Boundary

- Runs the real `workbench-data.js` + `app.js` in a lightweight DOM shim.
- Confirms core BJ-02 renderer/business branching and fixture reachability.
- Browser pixel parity remains a separate gate because local Chromium is not stable in this environment.
