# BJ02 Input + UX QA — v2.5.4

**Result: PASS · 20/20 checks**

- Scope: SCR-009 / SCR-084 quick + document modes; prior v2.5.2 flow invariants retained.
- Editable classification quantities use explicit numeric input hit areas + VNumericKeypadSheet; they are not Key-value Rows.
- Quick multi-UOM returns to the v2.5.0 in-product-card selection model while retaining v2.5.2 flow behavior.

## Checks

- [x] Quick multi-UOM stays on SCR009 — `SCR-009`
- [x] UOM choices are inside selected product card
- [x] Selected product card contains product identity and UOM group
- [x] Quick UOM screen no overflow
- [x] Choosing UOM opens detail
- [x] Four classification controls render as editable input surfaces — `4`
- [x] No Key-value Row used as editable classification control
- [x] Quantity input surface is 44px with visible field border — `{'w': 148, 'h': 44, 'b': '1px', 'rad': '8px', 'bg': 'rgb(255, 255, 255)'}`
- [x] Quantity input opens numeric keypad
- [x] Value not committed before Save — `0->0`
- [x] Value commits after Save — `3`
- [x] Detail no overflow after edit
- [x] Quick remove action is red text link — `{'c': 'rgb(209, 67, 67)', 'b': '0px', 'bg': 'rgba(0, 0, 0, 0)', 'w': 119.71875}`
- [x] Document detail exposes Chưa nhận lần này
- [x] Document not-received action matches red text-link treatment — `{'c': 'rgb(209, 67, 67)', 'b': '0px', 'bg': 'rgba(0, 0, 0, 0)', 'w': 125.1875}`
- [x] Document classification is also editable input surfaces
- [x] Document detail no overflow
- [x] Quick single-UOM still skips redundant UOM step
- [x] No new Theme7 component identity added
- [x] Browser errors zero — `[]`
