# Warehouse Hub role-aware QA — v4.6.5

## Scope

- Hub Kho candidate only.
- Four review roles: Chủ cửa hàng, Thủ kho, Kế toán, Nhân viên bán hàng.
- Flat `Quản lý kho` list and Quick Action deduplication.
- BJ02 pending worklist role routing.

## Results

- Static prototype validator: PASS — 0 BLOCKER / 0 HIGH.
- Role profile invariants: PASS.
- `v465` CSS/JS load after v4.6.4 continuity layer: PASS.
- Quick Action is a subset of visible role capabilities: PASS.
- No Quick Action is repeated in the flat management list: PASS.
- Contextual-only `UIF-04`, `UIF-10`, `UIF-17` are not promoted to global management rows: PASS.
- Owner pending goods receipt profile uses approver path; Warehouse maker profile uses read-only goods receipt đã gửi path: PASS.
- Candidate introduces no new broken relative Markdown link compared with the user-provided baseline: PASS.

## Role matrix

| Role | Quick Action | Flat `Quản lý kho` count |
|---|---|---:|
| Chủ cửa hàng | Nhận hàng · Lấy hàng · Kiểm kê · Tra cứu tồn | 11 |
| Thủ kho | Nhận hàng · Lấy hàng · Kiểm kê · Tra cứu tồn | 6 |
| Kế toán | Xác nhận giá · Chi phí mua · Giá vốn · Báo cáo tồn | 2 |
| Nhân viên bán hàng | Tra cứu tồn · Lấy hàng | 0 |

## Evidence limit

The container Chromium runtime is blocked by an organization URL policy for local/file URLs, so a fresh browser screenshot run was not counted as PASS. Validation in this package is static/contract-focused plus JavaScript syntax and navigation-profile invariants. The previously proven v4.6.4 BJ02 continuity layer is preserved; only the Hub presentation layer is added after it.
