# UI Contracts — Theme 07 — current cumulative overlay v1.4.3

This directory contains Screen, Action, navigation, Design System and Product-entry contracts derived from the Theme 7 business source. Historical freeze/version metadata inside individual legacy artifacts is preserved for traceability; **current Product routing/entry semantics are governed by the v1.4.3 overlay below**.

## Open first

- [Product Entry Architecture](entry-architecture.md) — canonical entry classes, actor ownership, Back/re-entry and cross-BJ continuity.
- [Navigation areas](navigation-areas.md) — information taxonomy; not every listed screen is a menu destination.
- [BJ → UC → Screen map](../../../09.generated/matrices/design/bj-ui-flow-map.md) — current active Product flow disposition.
- [Screen Registry](../../../09.generated/registries/design/screen-registry.md) / [JSON](../../../09.generated/registries/design/screen-registry.json).
- [Action Registry](../../../09.generated/registries/design/action-registry.json).
- [Flutter Design System profile](../../../03.design/design-system/design-system-profile.md) and `FLUTTER-DS-LOCK.json`.

## Current machine-readable scale

| Item | Current registry |
|---|---:|
| Business Journeys | 17 |
| Canonical UC references across UIFs | 70 |
| Screen Registry entries | 84 |
| Active flow screen references | 87 |
| UI Actions | 38 |
| Current UIF transitions | 189 |

The active-flow counts come from `flows/ui-flow-registry.json`; Screen Registry includes supporting, shared, migrated and retired artifacts as well. Therefore the two screen counts intentionally measure different things.

## Authority order

`Business decisions → BJ/UC → behavioral/technical contracts → current flow registry + entry architecture → Screen/Action contracts → HTML renderer → Flutter implementation`

`screen-catalog.json`, old validation reports and historical freeze reports are compatibility/evidence artifacts. They must not resurrect retired routes or override current entry architecture.

## v1.4.3 guardrails

- Workbench `UIF selector` is not Product navigation.
- Maker and approver are separate actor sessions for BJ02 and BJ06.
- `SCR-013` is `SYSTEM_RECOVERY`, never a normal menu destination.
- `SCR-021` is `CONTEXTUAL_ONLY` from Order detail.
- `SCR-020/022/023/024` are historical/retired from active UIF04.
- `SCR-037` may be a contextual supplier-return task entry, but it is not a global module entry.
- Result surfaces do not route Back into consumed commit screens.
