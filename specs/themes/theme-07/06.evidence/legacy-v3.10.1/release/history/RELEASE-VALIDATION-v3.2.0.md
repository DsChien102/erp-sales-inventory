# RELEASE VALIDATION — VET45 Theme 7 Prototype Harness v3.2.0

**Status: PASS · REVIEW READY**  
Parent: `v3.1.0`  
Scope: Inventory Audit & Control — BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17.

## Correction intent

End-user UI review found a hierarchy/action-placement regression in BJ08/SCR-042: a redundant list heading (`Phiên đang thực hiện`) and a destructive `Hủy phiên` CTA were presented directly in a browse/list screen. v3.2.0 fixes that case and re-audits the whole Audit & Control cluster for the same class of UI error.

## UI decisions

- Root list screens use **search/filter/list**, without a free-standing heading whose only job is to name the list below it.
- Destructive/mutation actions are not presented as peer CTAs inside browse lists.
- If a count is useful, use existing **DS v2 / List Top Bar** responsibility rather than an ad-hoc section heading.
- Do not repeat the AppBar context as an in-content heading.
- Keep `VChip` anatomy unchanged; dense status filters are explicit horizontal scrollers rather than accidentally clipped rows.
- No new core DS component is introduced.

## Key corrected surfaces

- **BJ08 / SCR-042:** removed `Phiên đang thực hiện`; removed visible `Hủy phiên`; preserved Search, filter chips, session row and `Tạo phiên kiểm kê`.
- **BJ08 / SCR-044:** `2 dòng cần đếm` is lightweight list metadata using `DS v2 / List Top Bar`, not a heading.
- **BJ09 / SCR-056:** removed duplicate `Lịch sử` heading because AppBar already says `Lịch sử tình trạng`.
- **BJ15 / SCR-055:** removed redundant `Sản phẩm` heading above the result list.
- **BJ15 / SCR-057:** removed redundant `Dòng thời gian nghiệp vụ` heading under the already-specific `Nguồn nghiệp vụ` AppBar.
- **Audit across BJ08/BJ09/BJ10/BJ11/BJ16/BJ17 root lists:** no redundant list headings or destructive list CTAs.

## Automated QA

Primary gate: `specs/themes/theme-07/prototype/html/qa/AUDIT-CONTROL-CLUSTER-QA-v3.2.0.md`.

- **61/61 checks PASS**.
- Audit & Control: **44 canonical routes**.
- Audit & Control declared states: **269/269 renders PASS**.
- Full harness: **497/497 declared-state renders PASS** across all 17 BJs.
- Canonical device gate: **85/85 screens PASS at 402×874**.
- List Row copy/status overlap: **0**.
- Root browse-list heading/destructive-action gate: **PASS**.
- Dense chip-scroll label/overflow gate: **PASS**.
- Browser page errors: **0**.

## Visual review

Contact sheet: `specs/themes/theme-07/prototype/html/qa/v320-audit-control-captures/AUDIT-CONTROL-CONTACT-SHEET-v3.2.0.png`.

The review explicitly checks the previously reported BJ08 list plus representative root-list/history/report surfaces across the cluster.

## Result

`v3.2.0` is **review ready** as the cumulative Theme 7 baseline.
