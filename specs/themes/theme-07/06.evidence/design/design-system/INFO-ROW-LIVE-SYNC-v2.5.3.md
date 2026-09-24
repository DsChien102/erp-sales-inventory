# INFO-ROW-LIVE-SYNC — v2.5.3

**Authority:** live Figma `DS v2 / Info Row` (`525:351`), refreshed 2026-09-10.

Current master anatomy applied to every HTML Info Row instance:

- frame: 338 × 44
- layout: horizontal, align center, `justify-between`, gap 0, padding 0
- label: Inter Regular 13/20, Text/Secondary, left aligned
- value: Inter Semi Bold 14/20, Text/Primary, right aligned
- Disabled: parent opacity 0.4
- responsibility remains read-only supporting metadata, not primary navigation

Implementation rule: exact anatomy is enforced by the shared DS selector and the current release live-sync layer. Historical feature CSS may not override the component geometry or typography. Long/multiline content must use a non-Info-Row text/layout composition rather than mutate this fixed single-line component.

No Product business behavior changes in this patch.
