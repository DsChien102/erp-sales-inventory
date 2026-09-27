# Visual QA — v1.3.5

**Result: PASS · 8 end-user specimens manually reviewed at 402 × 874**

## Reviewed specimens
- `BJ02-SCR008-quick-header.png` — disabled warehouse select, date picker, uploaded delivery evidence and sticky Continue.
- `BJ02-SCR009-uom-choices.png` — all valid UOM choices visible without dropdown.
- `BJ02-SCR084-lot-bottom.png` — `Thêm lô khác` visually separated from the sticky `Xong` completion CTA.
- `BJ06-SCR032-wrong-lot.png` — mismatch warning + structured reason entry without English/technical leakage.
- `BJ06-SCR032-evidence-bottom.png` — direct reason choices + required image upload above sticky maker CTA.
- `BJ06-SCR034-approver.png` — approver evidence hierarchy.
- `BJ05-SCR028-handover.png` — physical-handover confirmation surface.
- `BJ07-SCR039-handover.png` — physical-handover confirmation without technical `commit/actor/source` copy.

## Issues found and corrected during visual QA
1. New v1.3.5 CSS had been appended with literal escaped newlines, so upload/UOM/reason-choice styles did not apply. Corrected to real CSS newlines and re-captured affected screens.
2. BJ06 selected evidence filename did not visibly refresh after file selection. Changed file-change handling to re-render the affected surface.
3. BJ06 warning leaked the English word `reason`; BJ07 handover exposed `commit`, `actor`, `source/LOT`. Rewritten in user-facing Vietnamese.
4. File upload initially attempted an unverified semantic `upload` icon. Replaced with the already mapped Flutter-DS `VIcons.description` / `fileText` semantic rather than inventing a DS mapping.

## Visual acceptance
- No observed horizontal overflow on the reviewed mobile surfaces.
- Sticky footer actions remain visually separated from scrollable content.
- Direct-choice rows remain at least the existing 44 px interaction profile.
- Upload zones, choice groups and banners preserve the existing Flutter-DS visual language used by the cumulative harness.
- This report validates the affected v1.3.5 surfaces only; it does not re-approve unrelated BJ UX.
