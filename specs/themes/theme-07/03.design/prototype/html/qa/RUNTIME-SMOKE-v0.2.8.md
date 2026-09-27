# BJ-02 Runtime / Render Smoke v0.2.8

**Result: 35/35 PASS**

Runs the real BJ-02 renderer in headless Chromium by injecting the self-contained workbench into an `about:blank` target. This avoids the environment policy that blocks local/file URLs while still using Chromium layout, DOM and event/runtime behavior.

## Checks

- [x] workbench boots UIF-02
- [x] mobile frame 402×874
- [x] SCR-008 has receipt header fields
- [x] SCR-008 no redundant optional copy
- [x] Supplier results carry name + code + phone
- [x] Supplier selection resolves master ID
- [x] SCR-008 no horizontal overflow
- [x] Document overview exposes both source products
- [x] SCR-009 no horizontal overflow
- [x] Document editor shows Product/UOM identity
- [x] Document editor does not render UOM select
- [x] Document editor opens first lot
- [x] Add lot appends one lot
- [x] New lot opens and prior lot collapses
- [x] Two-lot editor exposes delete actions
- [x] User can manually open another lot
- [x] Empty extra lot removes without unnecessary confirm
- [x] Document partial shows remaining as info
- [x] Document over-source shows warning
- [x] Exact source quantity suppresses variance banner
- [x] Exception sum overflow is blocked visibly
- [x] Product results are compact discriminators
- [x] Quick selected UOM collapses selector into identity
- [x] Duplicate Product+UOM shows warning + open existing
- [x] Duplicate Product+UOM suppresses lot editor
- [x] Same Product different UOM is not duplicate
- [x] Duplicate lot code shows open-existing action
- [x] Duplicate lot blocks Xong
- [x] Permission state uses end-user empty state copy
- [x] SCR-006 no horizontal overflow
- [x] SCR-007 no horizontal overflow
- [x] SCR-010 no horizontal overflow
- [x] SCR-011 no horizontal overflow
- [x] SCR-012 no horizontal overflow
- [x] SCR-013 no horizontal overflow

## Boundary

- Validates DOM rendering, key interactions, source-variance behavior, duplicate guards and horizontal overflow on the 402 × 874 product viewport.
- Does not claim screenshot pixel-parity against the Vercel Flutter reference; that remains a separate visual gate.
