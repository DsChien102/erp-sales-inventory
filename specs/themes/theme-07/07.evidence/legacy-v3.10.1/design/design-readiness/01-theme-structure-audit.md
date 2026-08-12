# 01 — Audit cấu trúc Theme 7 v4.3.1

> Generated `2026-08-24T09:17:52.534357+00:00` · Checkpoint `4.3.1-dr1` · Scope: `BJ → UC → UI Flow → canonical Screen`.

## Executive verdict

- Baseline có **17 BJ, 70 UC, 17 UI Flow, 201 transitions, 83 Screen, 479 state obligations và 33 Action**.
- Cấu trúc BJ/UC/flow đủ làm semantic baseline, nhưng Screen Contract cũ thiên về traceability hơn design interaction.
- **19 Screen có BJ ownership bị khai rộng hơn flow thực tế hoặc thuộc supporting capability**; đã sửa derivable trong registry/markdown. `SCR-081` được bổ sung trace trực tiếp vào `BJ-16 / UC-16-03`.
- Path canonical đã chuẩn hóa thành `ui/flows`; lỗi package path trước đây là relocation defect, không phải semantic flow defect.
- Baseline 83 Screen được giữ nguyên ở checkpoint; structural changes chỉ là proposal để anh duyệt.

## Metrics

| Metric | Value |
|---|---:|
| Business Journeys | 17 |
| Canonical Use Cases | 70 |
| UI Flows | 17 |
| UI transitions | 201 |
| Canonical Screens | 83 |
| Shared Screens (>1 BJ) | 16 |
| UI states | 479 |
| Actions | 33 |
| Supporting capability Screens | 4 |

## Surface distribution

| Surface | Count |
|---|---:|
| `choice` | 1 |
| `dashboard` | 3 |
| `detail` | 12 |
| `form` | 20 |
| `list` | 13 |
| `result` | 13 |
| `review` | 16 |
| `timeline` | 5 |

## Flow inventory

| Flow | BJ | Tên | UC | Screen | Transition | Entry | Terminal |
|---|---|---|---:|---:|---:|---|---|
| `UIF-01` | `BJ-01` | Theo dõi tồn, khả dụng và chỉ báo vận hành | 5 | 10 | 19 | SCR-001, SCR-054, SCR-060 | SCR-002, SCR-004, SCR-057, SCR-061 |
| `UIF-02` | `BJ-02` | Nhận hàng mua | 5 | 8 | 18 | SCR-006 | SCR-012, SCR-013 |
| `UIF-03` | `BJ-03` | Xác nhận giá trị ban đầu của hàng nhận | 3 | 5 | 9 | SCR-014 | SCR-019 |
| `UIF-04` | `BJ-04` | Quản lý vòng đời giữ hàng | 4 | 5 | 10 | SCR-020 | SCR-024 |
| `UIF-05` | `BJ-05` | Lấy hàng và bàn giao đơn | 5 | 5 | 11 | SCR-025 | SCR-029 |
| `UIF-06` | `BJ-06` | Tiếp nhận và phân loại hàng khách trả | 4 | 6 | 10 | SCR-030 | SCR-035 |
| `UIF-07` | `BJ-07` | Thực hiện trả hàng cho nhà cung cấp | 4 | 5 | 11 | SCR-036 | SCR-041 |
| `UIF-08` | `BJ-08` | Kiểm kê và điều chỉnh chênh lệch | 5 | 6 | 13 | SCR-042 | SCR-047 |
| `UIF-09` | `BJ-09` | Quản lý trạng thái hàng | 4 | 5 | 12 | SCR-036 | SCR-041, SCR-056 |
| `UIF-10` | `BJ-10` | Tiêu hủy hàng | 4 | 4 | 9 | SCR-036 | SCR-041 |
| `UIF-11` | `BJ-11` | Hủy và sửa sai nghiệp vụ kho | 5 | 6 | 14 | SCR-048 | SCR-053 |
| `UIF-12` | `BJ-12` | Khởi tạo số dư tồn kho đầu kỳ | 3 | 6 | 10 | SCR-066 | SCR-071 |
| `UIF-13` | `BJ-13` | Ghi nhận chi phí mua đến muộn | 3 | 5 | 11 | SCR-014 | SCR-019 |
| `UIF-14` | `BJ-14` | Tính và công bố giá vốn | 4 | 6 | 10 | SCR-072 | SCR-077 |
| `UIF-15` | `BJ-15` | Tra cứu báo cáo tồn và thẻ kho | 4 | 6 | 11 | SCR-054 | SCR-055, SCR-057, SCR-059 |
| `UIF-16` | `BJ-16` | Điều tra và đối soát sai lệch | 4 | 6 | 13 | SCR-078 | SCR-083 |
| `UIF-17` | `BJ-17` | Phục hồi nghiệp vụ có kết quả chưa xác định | 4 | 5 | 10 | SCR-078 | SCR-083 |

## Derivable corrections applied

- Corrected BJ ownership for: `SCR-014`, `SCR-015`, `SCR-016`, `SCR-017`, `SCR-018`, `SCR-019`, `SCR-038`, `SCR-039`, `SCR-040`, `SCR-055`, `SCR-058`, `SCR-059`, `SCR-060`, `SCR-061`, `SCR-062`, `SCR-063`, `SCR-064`, `SCR-065`, `SCR-081`.
- `SCR-062…SCR-065` are now owned by `CAP-01`, with consumers `BJ-01` and `BJ-09`; they are no longer falsely assigned to BJ-04.
- `SCR-081` is now owned by `BJ-16`, linked directly to `UC-16-03`, while `PROC-01-STEP-03` remains supporting evidence.
- Action IDs are split into `visible_action_ids` and `trace_only_action_ids`; result screens no longer imply a repeated CTA merely because they carry source-lineage Action IDs.
- `screen-registry.md` and `bj-ui-flow-map.md` were regenerated from canonical registries.

## Structural inventory verdict

- `KEEP`/`KEEP_WITH_CONTEXT_MODE`: majority of baseline screens.
- `SPLIT_OR_RECLASSIFY_RECOMMENDED`: `SCR-012`.
- `SPLIT_RECOMMENDED`: `SCR-052`.
- `REVIEW_KEEP_WITH_MODE_OR_SPLIT`: `SCR-041`.
- No evidence-supported `MERGE` or `REMOVE` at this checkpoint.
- Proposed total after decisions is **84–88** screens depending whether approval entry is a framework route and whether `SCR-041` is split.

## Important interpretation

83 is a baseline inventory, not a delivery quota. Screen count changes only when user task/mental context, lifecycle, actor handoff or mutation responsibility proves a structural need.
