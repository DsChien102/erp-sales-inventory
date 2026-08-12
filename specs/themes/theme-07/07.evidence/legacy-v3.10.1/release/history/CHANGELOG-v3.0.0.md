# VET45 Theme 7 Prototype Harness — v3.0.0

Parent: **v2.9.4**

## Inventory Valuation cluster

This release redesigns **BJ03 + BJ13 + BJ14 together** so valuation reads as one coherent product area rather than three unrelated screen sets. Business rules, state machines, handlers and canonical journey topology remain unchanged.

### BJ03 — Xác nhận giá trị ban đầu
- Product/UOM is the primary context; LOT/non-LOT + physical state are nested valuation scopes rather than peer cards.
- Partial quantity is shown only inside the selected scope.
- Evidence/provenance is contextual in `VBottomSheet`; conflicting sources are never preselected.
- Review/result reuse the same hierarchy so users do not relearn the object model between steps.

### BJ13 — Chi phí mua đến muộn
- Separates cost source, target scope, allocation preview, accounting-period effect and final impact without stacking cards.
- Multi-target selection and allocation rows use one grouped surface per collection.
- Monetary facts use Info/Key-value rows; no money-as-badge treatment.

### BJ14 — Tính và công bố giá vốn
- Run list/setup/calculation/blocker/review/result use a consistent immutable-run mental model.
- Policy method is read-only context, not a user-editable selector.
- Replaces the previous custom 2-option segmented treatment with canonical `VRadio` for “Chốt kỳ” / “Cập nhật trong kỳ”.
- Blockers are presented as one actionable collection; final publish remains one primary CTA.

## Figma DS alignment
References: List Row `525:519`, Info Row `525:351`, Key-value Row `525:358`, VBadge `525:309`, VRadio `522:7410`, VSelect `522:7291`, VBottomSheet `4695:6353`, VAppBar `547:1594`. No new core DS component was created.

## Canonical routes
- BJ03: `SCR-014 → SCR-015 → SCR-017 → SCR-019` (`SCR-016` remains retired/support only).
- BJ13: `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`.
- BJ14: `SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077` (`SCR-075` remains retired/support only).
