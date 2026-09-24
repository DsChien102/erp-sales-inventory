# Theme 7 — UI flows — current registry v1.9.0

> Canonical orchestration layer for the 17-UIF Harness. Business semantics remain in SRS/UC/BC/API. Product entry/actor continuity is additionally governed by `../contracts/entry-architecture.md`.

## Conventions

- `NAVIGATION`: move between Product surfaces; no business mutation.
- `QUERY`: read/refresh/export; no inventory/value mutation.
- `MUTATION`: must trace to an existing Action → BC → API contract.
- `SYSTEM`: authoritative state/result routing; UI does not invent finality.
- `HANDOFF`: ownership moves to another actor/domain while preserving object/version/evidence.
- `TERMINAL`: end of the current UI flow; not synonymous with success.

## Current registry

| Flow | Business Journey | UC | Active screen refs | Transitions |
|---|---|---:|---:|---:|
| [`UIF-01`](../../../02.specification/behavior/journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) | `BJ-01` — Theo dõi tồn, khả dụng và chỉ báo vận hành | 5 | 2 | 11 |
| [`UIF-02`](../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) | `BJ-02` — Nhận hàng mua | 5 | 9 | 21 |
| [`UIF-03`](../../../02.specification/behavior/journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) | `BJ-03` — Xác nhận giá trị ban đầu của hàng nhận | 3 | 4 | 8 |
| [`UIF-04`](../../../02.specification/behavior/journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) | `BJ-04` — Quản lý vòng đời giữ hàng | 4 | 1 | 1 |
| [`UIF-05`](../../../02.specification/behavior/journeys/BJ-05-lay-hang-va-ban-giao-on.md) | `BJ-05` — Lấy hàng và bàn giao đơn | 5 | 5 | 11 |
| [`UIF-06`](../../../02.specification/behavior/journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) | `BJ-06` — Tiếp nhận và phân loại hàng khách trả | 4 | 6 | 12 |
| [`UIF-07`](../../../02.specification/behavior/journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) | `BJ-07` — Thực hiện trả hàng cho nhà cung cấp | 4 | 4 | 8 |
| [`UIF-08`](../../../02.specification/behavior/journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) | `BJ-08` — Kiểm kê và điều chỉnh chênh lệch | 5 | 6 | 13 |
| [`UIF-09`](../../../02.specification/behavior/journeys/BJ-09-quan-ly-trang-thai-hang.md) | `BJ-09` — Quản lý trạng thái hàng | 4 | 5 | 14 |
| [`UIF-10`](../../../02.specification/behavior/journeys/BJ-10-tieu-huy-hang.md) | `BJ-10` — Tiêu hủy hàng | 4 | 4 | 10 |
| [`UIF-11`](../../../02.specification/behavior/journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) | `BJ-11` — Hủy và sửa sai nghiệp vụ kho | 5 | 6 | 16 |
| [`UIF-12`](../../../02.specification/behavior/journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) | `BJ-12` — Khởi tạo số dư tồn kho đầu kỳ | 3 | 6 | 11 |
| [`UIF-13`](../../../02.specification/behavior/journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) | `BJ-13` — Ghi nhận chi phí mua đến muộn | 3 | 5 | 9 |
| [`UIF-14`](../../../02.specification/behavior/journeys/BJ-14-tinh-va-cong-bo-gia-von.md) | `BJ-14` — Tính và công bố giá vốn | 4 | 5 | 10 |
| [`UIF-15`](../../../02.specification/behavior/journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) | `BJ-15` — Tra cứu báo cáo tồn và thẻ kho | 4 | 6 | 11 |
| [`UIF-16`](../../../02.specification/behavior/journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) | `BJ-16` — Điều tra và đối soát sai lệch | 4 | 6 | 13 |
| [`UIF-17`](../../../02.specification/behavior/journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) | `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định | 4 | 5 | 10 |

**Total:** 17 UIF · 70 UC references · 85 active flow screen references · 189 transitions.

## v1.9.0 holistic hardening

- Parent v1.8.0 topology is preserved exactly; v1.9.0 changes Product semantics/action ownership metadata, not BJ flow structure.
- Current distinct topology: **17 UIF · 73 canonical active screens · 497 active flow/state render combinations**. The table above contains **85 flow/screen occurrences** because canonical screens may be shared across UIFs.
- BJ10/BJ11/BJ16/BJ17 Product copy no longer leaks implementation/recovery jargon or internal recovery IDs; technical trace stays in contracts/Inspect.
- BJ02/BJ09/BJ10 auto-save actions are system-owned trace-only behavior; they are not visible user tasks.
- `../screen-map.md` is the current generated topology map; exact v4.1.0 historical map is retained under `../legacy/`.
- Frozen v4.x package validator is historical only and must not override the current v1.9 registries.

## v1.7.0 cumulative corrections

- v1.6.0 Inventory Audit & Control và v1.5.0 Inventory Valuation corrections tiếp tục là canonical protected baseline.
- UIF11: cancel/correction tách theo execution finality; maker result và approver task độc lập; correction approved được system execute; UNKNOWN route sang UIF17 cùng operation identity.
- UIF16: evidence-first classification; source/correction/UNKNOWN/projection/ledger-integrity routes tách rõ; projection recovery chỉ khi ledger đúng đã được chứng minh.
- UIF17: commit/no-commit/insufficient-evidence quyết định finality; không blind retry, không operation mới, không duplicate inventory effect.
- Entry/handoff/recovery explanation vẫn thuộc architecture/contracts/Inspect, không render thành Product UI.

## v1.6.0 cumulative corrections

- v1.5.0 Inventory Valuation corrections remain canonical: UIF03 linear active chain, UIF13 late-cost chain, UIF14 immutable cost-run chain.
- UIF08: blind count → discrepancy/recount → maker submit; approver enters by separate task; cancellation is not an approval action.
- UIF09: Product-facing condition model; expiry is derived; maker and approver modes are mutually exclusive; state movement preserves total physical/value.
- UIF10: approval only authorizes disposal; physical decrement occurs only after independent completion assertion.
- Across all three: entry/handoff/orchestration is metadata outside Product UI; UNKNOWN preserves operation identity.

## Source of truth and historical evidence

- `ui-flow-registry.json` is the current machine-readable orchestration registry.
- `validation-report.*` and older Harness reports are historical structural evidence; stale counts/routes in those artifacts must not override this registry.
- Current Product entry classes and Back/re-entry rules live in `../contracts/entry-architecture.md`.
