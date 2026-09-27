# VET45 Theme 7 Prototype Harness — v3.0.1

Parent: **v3.0.0**

## Operations + Valuation UI hardening

This release audits the complete **Inventory Operations + Inventory Valuation** Product UI scope instead of correcting only the screenshots that exposed the issue. Covered journeys: **BJ01, BJ02, BJ03, BJ04, BJ05, BJ06, BJ07, BJ13, BJ14** — 41 canonical screens and 228 declared UI states.

### Canonical List Row rule
- The leading icon is **semantic and optional**, not a mandatory decoration.
- Product identity keeps the product/package icon; other entity-specific icons remain only when they add recognition value.
- Work queues, request/context summaries and LOT/child rows can hide the icon; copy immediately reclaims the canonical leading inset.
- Copy now yields to trailing badge/status/navigation content without visual overlap.

### BJ07 Product → lô hierarchy
- The previous Product/LOT treatment was a **layout composition**, not a core Design System component.
- Parent Product + unit now renders as canonical `DS v2 / List Row · Status · Compact` with product icon and semantic progress badge.
- LOT/non-LOT allocations render as canonical `List Row · Navigation · Default` with the leading icon hidden.
- Legacy connector/tree decoration and nested card-like treatment are removed; one grouped surface owns the collection.

### BJ03 valuation hierarchy and evidence
- Product parent uses canonical `List Row · Status · Compact`; multi-select valuation scopes remain a lightweight composition of existing checkbox + text primitives.
- Redundant **“Công việc”** heading is removed from the queue screen.
- **“Căn cứ và cách tính”** can no longer open as an empty shell; a useful empty state is rendered when no scope is selected.
- Source conflict remains explicit and unselected until the user chooses a source.

### BJ13 / BJ14 density and terminology
- BJ13 queue titles are shortened to the actual document reference so title, subtitle and status no longer collide.
- BJ14 uses **“Thời điểm chốt”** instead of `Cut-off` and no longer exposes raw policy revision suffixes.
- User-facing implementation terms/raw revisions were removed across Operations + Valuation: `UOM`, `LOT`, `FX`, raw `vN`, policy version codes and backend state names are not shown in Product UI.

### Operations-wide cleanup
- Queue rows in BJ03/BJ05/BJ06/BJ07/BJ13/BJ14 are text-first where a leading icon adds no meaning.
- BJ06 request/classification context no longer carries a decorative package icon.
- BJ04/BJ05/BJ06 list-row helpers delegate to the same canonical List Row anatomy instead of feature-specific row markup where possible.
- Existing Product rows retain meaningful product icons/images.

## Behavior and topology

No business rule, mutation boundary, commit semantic, state list or canonical screen topology was changed. v3.0.1 is a Product UI / Design System hardening release.

## Design System authority

Figma file `QVJolM5tAdFKkhP7RIwe3y` remains UI authority. Primary references used: `DS v2 / List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VRadio 522:7410`, `VBottomSheet 4695:6353`, `VAppBar 547:1594`. **No new core Design System component was created.**
