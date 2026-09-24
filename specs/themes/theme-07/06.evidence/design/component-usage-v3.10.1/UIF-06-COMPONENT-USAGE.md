# UIF-06 Component Usage — Figma DS baseline v2.8.2

UI authority: live Figma DS in `QVJolM5tAdFKkhP7RIwe3y`. Mature Product UI in the same Figma file is a composition/rhythm reference, never a substitute for business contracts.

| Surface | Canonical composition |
|---|---|
| SCR-030 queue | `VSearchBar + VChip + DS v2 / List Row (Navigation) + VBadge` |
| SCR-031 request | compact `List Row (Status, Compact)` request context + `List Row (Navigation)` + contextual `VBanner` + Sticky Footer |
| SCR-032 physical verify | compact `List Row (Status)` identity + grouped `Info Row` facts + `VTextField` + selection controls + conditional evidence + Sticky Footer |
| SCR-034 approval | `List Row (Navigation)` task list; detail uses compact identity + grouped `Info Row`; rejection uses `VBottomSheet + VTextarea + VButton` |
| SCR-033 classification | compact `List Row (Status, Compact)` request context + `List Row (Navigation)` + contextual `VBottomSheet` editor + `VTextField` |
| SCR-035 result | result state + grouped `Info Row` + Product/UOM/LOT result composition + Sticky Footer |

## Geometry and interaction locks

- Product surface is exactly 402×874 CSS px; content edge is 16px and normal content width is 370px.
- List Row Default is 370×76; Compact status context is 370×52.
- Info Row remains a transparent primitive inside a content-sized grouped surface; the group is not given a fixed decorative height.
- `VBottomSheet` uses the canonical 402px shell, 48×4 handle, 12px top padding/gap, 16px horizontal padding and 44px bottom safe area. It hugs actual content until max-height is reached; only then does its content region scroll.
- Disabled appearance uses parent opacity 0.4, not a separate disabled color.
- Maker Back navigation is semantic (`032→031`, `031→030`, `033→030`), not derived from workbench catalog order. `SCR-034` is independent approver navigation.

## v2.9.2 — Result Product-group hardening
- `SCR-035` Product+UOM result identity now uses canonical `List Row / Status / Compact` inside the grouped result surface; LOT/classification details remain `Info Row`.
- The former free-text product header is retired.

## v2.9.3 — DS-native result collection correction

- Supersedes the v2.9.2 per-Product result surfaces in `SCR-035`.
- The entire homogeneous result set owns **one** Layout `Grouped surface` (`4518:1545`); Product+UOM entries are borderless layout subgroups, not cards.
- Product+UOM uses canonical `DS v2 / List Row` (`525:519`), `Type=Status`, `Density=Compact`, exact `370×52`. Status is semantic: `Đã nhận` or `Đã phân loại`.
- LOT/classification evidence stays canonical `DS v2 / Info Row` (`525:351`) at `338×44`. Raw quantity stays in the value column and is never used as `VBadge` content.
- Result section headings keep H4 `16/22` instead of inheriting the legacy result-hero H2 rule.

## v3.9.4 — BJ06 semantic hardening

- `SCR-030` waiting request uses canonical disabled/non-interactive List Row; no chevron/tap affordance.
- `SCR-031/032` bind current ReturnExchangeLine authorized quantity. Raw quantity is text/value, never a status badge. Source LOT and actual LOT remain separate labeled `Info Row` facts.
- `SCR-032` shows Theme 5 `Tình trạng khai báo` as read-only context. Existing actual LOT attributes are read-only; new LOT progressively uses DS inputs only for policy-required attributes.
- Wrong-LOT evidence continues using `VFileDropZone`; approval identity is evidence ID/version/content hash rather than filename.
- `SCR-033` uses `VBottomSheet + VNumberField/VTextField` for **Bán được / Cách ly / Hỏng** only. `Hết hạn` is system-derived and rendered as read-only `Info Row`/status context.
- `SCR-034` remains the separate actor-handoff context and presents maker + source request/order + Product/UOM + source/actual LOT + LOT attributes + image evidence; technical case/version IDs stay hidden.
- `SCR-035` does not invent a return-receipt code; result context uses source request/order and authoritative recorded/classified time. `UNKNOWN` uses the existing BJ17 verification handoff pattern.
