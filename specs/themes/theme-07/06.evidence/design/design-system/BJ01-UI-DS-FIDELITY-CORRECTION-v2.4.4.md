# BJ01 UI / Figma DS Fidelity Correction — v2.4.4

**Parent:** v2.4.3  
**Authority:** live Figma DS v2.0.3 + BJ01 Product contracts  
**Business behavior:** unchanged

## Defects corrected

1. **Supporting stock quantities used the wrong DS row.** `Info Row` places value immediately after its label with an 8px gap; with different label lengths, values do not share a stable column. BJ01 needs comparable numeric summary data, so the correct existing component is `DS v2 / Key-value Row` (`525:358`). `Khả dụng` remains `Emphasis`; `Tồn vật lý / Đủ điều kiện bán / Đã giữ` are `Default`.
2. **Key-value Row had been stretched to 370px.** The live Figma master is 338px. v2.4.4 preserves 338px and centers the row in the 370px content column.
3. **VBanner had a forced 96px minimum height.** This created dead vertical space for one-line copy. v2.4.4 uses content-driven height (Hug Content behavior) while preserving canonical padding/gap/border/radius/icon/typography.
4. **VSearchBar text input did not explicitly fill remaining width.** It now flexes to the canonical search control width without placeholder/value clipping.
5. **VChip touch-target pseudo element was not anchored.** Each chip is now `position: relative`; the expanded hit area is scoped to that chip only.
6. **Default Key-value numeric values require JetBrains Mono.** The HTML now requests JetBrains Mono together with Inter from the remote font provider. No font files are packaged.

## Reuse decision

No component is created. The correction moves BJ01 further toward the project priority:

`semantically valid V_component → existing canonical non-V component → existing Pattern/Template → layout composition → new component only after proven reusable gap`

## Figma evidence

- `DS v2 / Key-value Row` `525:358`: Default = read-only key/value row; Emphasis = totals/summary outcomes.
- `DS v2 / Info Row` `525:351`: supporting metadata with label/value separated by a fixed 8px gap; not suitable for aligned comparable quantity columns.
- `VBanner` `526:4215`: 370px width, 16px default padding, 12px content gap, 20px semantic icon, 12px radius; brief content must not be padded to an arbitrary 96px minimum in Product HTML.
- `VBottomSheet` `4695:6353`: retained unchanged; current BJ01 geometry already matches the live master.
