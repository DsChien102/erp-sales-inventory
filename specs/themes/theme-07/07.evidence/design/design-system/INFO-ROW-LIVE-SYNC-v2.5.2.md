# Info Row live Figma sync — v2.5.2

Source authority: live Figma `DS v2 / Info Row` (`525:351`) checked 2026-09-10.

Current master anatomy:
- 338 × 44 px.
- Horizontal Auto Layout, `justify-between`, no explicit label/value gap.
- Label: Inter Regular 13/20, Text/Secondary, left.
- Value: Inter Semi Bold 14/20, Text/Primary, right-aligned in Default.
- Disabled: parent opacity 0.4.

HTML rule:
- Every active `data-ds-component="DS v2 / Info Row"` consumes this anatomy from the final live-sync layer.
- Do not preserve the historical 8px-gap anatomy from older releases.
- Do not stretch Info Row to 370px or turn it into a wrapping two-column table.
- Long/multiline review values are not Info Row; compose them from existing text styles/layout instead of mutating the component.

Historical v2.4.x/v2.1.x reports are retained as release history and may describe the older Figma master. They are not current UI authority.
