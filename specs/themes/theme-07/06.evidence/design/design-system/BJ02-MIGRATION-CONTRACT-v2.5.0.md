# BJ02 — Figma DS Migration Contract · v2.5.0

Parent: **v2.4.5**. Scope is UIF-02 plus release/QA artifacts; BJ01/BJ08 and other Product flows are regression-protected.

## Corrections applied

1. Revalidated flow against BJ02 + UC/screen contracts before UI migration.
2. Corrected template responsibility: SCR-009 = Nested List; SCR-084 = Form.
3. Replaced false `List Row` reuse on rich source/receipt rows with canonical `Record Card`.
4. Rebuilt SCR-006 with exact List Row anatomy; removed custom icon-card wrapper.
5. Calibrated SearchBar, text/date/file inputs, sticky footer and review geometry from live Figma masters/variables.
6. Removed BJ02 feature component identities that were only one-off layout compositions.
7. Kept four quantity classifications authoritative; no editable total input.
8. Preserved Quick master-data resolution, no quick-create, no visible Save Draft.
9. Preserved actor handoff for approval and same-operation UNKNOWN recovery.
10. Preserved semantic feedback hierarchy; Quick mandatory approval remains Info, not Warning.

## Figma nodes used as direct fidelity references

- List Row `525:519`
- Record Card `1001:7201`
- Product Result Card `1234:6260` / specimen `4531:1929`
- VTextField `522:7186`
- VDatePicker `522:7368`
- VFileDropZone `522:7507`
- VBanner `526:4215`
- Sticky Footer `549:927`
- Search Results Dropdown `1280:6272`

## Definition of done

Business, interaction, runtime, visual and regression gates must all pass. `data-ds-component` alone is never evidence of DS conformance.
