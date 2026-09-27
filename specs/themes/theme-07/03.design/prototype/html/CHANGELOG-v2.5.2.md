# CHANGELOG v2.5.2

Parent: **v2.5.1**

- Fixed BJ02 Quick `SCR-008 → SCR-009` fatal render (`total is not defined`) that left stale SCR-008 UI visible.
- Restored current SRS/UC interaction: single-UOM Product opens `SCR-084` immediately; multi-UOM Product shows all UOMs directly then opens `SCR-084`.
- Duplicate Product+UOM opens the existing item instead of adding a blocker/tap cycle.
- Fixed nested LOT editor 370/338 width mismatch and long content overflow.
- Kept long uploaded evidence names outside VFileDropZone title anatomy and allowed wrapping in review/approval metadata.
- Added real-click Quick flow QA so screen seeding cannot hide navigation/render failures.
- No new Theme7 shared component; BJ01/BJ08 carried forward.
- Synced every HTML `DS v2 / Info Row` to the live Figma master refreshed 2026-09-10: 338×44, justify-between, gap 0, value right-aligned.
- Removed obsolete long-value mutations of Info Row; long/multiline review metadata now uses a VText layout composition instead of changing component anatomy.
- Added 497-state / 1052-instance Info Row geometry, typography, alignment and overlap regression QA.
