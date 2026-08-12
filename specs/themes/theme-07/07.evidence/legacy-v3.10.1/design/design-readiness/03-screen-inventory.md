# 03 — Screen Inventory & Readiness Matrix

> Checkpoint `4.3.1-dr1` · Baseline `83` Screen. Structural proposal chưa thay đổi canonical count.

## Summary

| Status | Count |
|---|---:|
| `S1_BLOCKED_BY_DECISION` | 3 |
| `S1_READY_DERIVED` | 68 |
| `S1_READY_WITH_REVIEW` | 12 |

| Disposition | Count |
|---|---:|
| `KEEP` | 67 |
| `KEEP_SUPPORTING_CAPABILITY` | 4 |
| `KEEP_TRACE_CORRECTED` | 1 |
| `KEEP_WITH_CONTEXT_MODE` | 8 |
| `REVIEW_KEEP_WITH_MODE_OR_SPLIT` | 1 |
| `SPLIT_OR_RECLASSIFY_RECOMMENDED` | 1 |
| `SPLIT_RECOMMENDED` | 1 |

## Structural proposals

| Proposal | Disposition | Source | Name | Effect |
|---|---|---|---|---|
| `ADD-01` | `ADD_OR_FRAMEWORK_ROUTE` | `—` | Approval work queue / task route dùng chung | 0 nếu framework route; +1 nếu canonical screen. |
| `SPLIT-01` | `SPLIT_OR_RECLASSIFY` | `SCR-012` | Execution/confirmation nhận hàng + Kết quả nhận hàng | 0 nếu reclassify; +1 nếu split. |
| `SPLIT-02` | `SPLIT` | `SCR-052` | Hủy operation chưa thực thi + Chuẩn bị correction | +1. |
| `REVIEW-01` | `KEEP_WITH_MODE_OR_SPLIT` | `SCR-041` | Kết quả xử lý theo operation_type | 0 nếu keep; +1 đến +2 nếu split. |

## All Screens

| Screen | Name | Type | Owner | BJ | UC | Status | Disposition | Gaps |
|---|---|---|---|---|---|---|---|---|
| [`SCR-001`](../../../../03.design/screens/SCR-001.md) | Tra cứu tồn kho | `list` | BJ-01 | BJ-01 | UC-01-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-002`](../../../../03.design/screens/SCR-002.md) | Kết quả khả dụng | `dashboard` | BJ-01 | BJ-01 | UC-01-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-003`](../../../../03.design/screens/SCR-003.md) | Chi tiết sản phẩm | `detail` | BJ-01 | BJ-01 | UC-01-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-004`](../../../../03.design/screens/SCR-004.md) | Chi tiết lô và hạn dùng | `detail` | BJ-01 | BJ-01 | UC-01-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-005`](../../../../03.design/screens/SCR-005.md) | Nguồn số liệu | `timeline` | BJ-01 | BJ-01 | UC-01-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-006`](../../../../03.design/screens/SCR-006.md) | Chọn cách nhận hàng | `choice` | BJ-02 | BJ-02 | UC-02-01,UC-02-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-007`](../../../../03.design/screens/SCR-007.md) | Chứng từ chờ nhận | `list` | BJ-02 | BJ-02 | UC-02-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-008`](../../../../03.design/screens/SCR-008.md) | Thông tin nhập hàng nhanh | `form` | BJ-02 | BJ-02 | UC-02-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-009`](../../../../03.design/screens/SCR-009.md) | Hàng thực nhận và phân bổ lô | `form` | BJ-02 | BJ-02 | UC-02-01,UC-02-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-010`](../../../../03.design/screens/SCR-010.md) | Rà soát và gửi xử lý | `review` | BJ-02 | BJ-02 | UC-02-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-011`](../../../../03.design/screens/SCR-011.md) | Phê duyệt yêu cầu nhận hàng | `review` | BJ-02 | BJ-02 | UC-02-03 | `S1_BLOCKED_BY_DECISION` | `KEEP` | BG-002,BG-003 |
| [`SCR-012`](../../../../03.design/screens/SCR-012.md) | Kết quả nhận hàng | `result` | BJ-02 | BJ-02 | UC-02-04,UC-02-05 | `S1_BLOCKED_BY_DECISION` | `SPLIT_OR_RECLASSIFY_RECOMMENDED` | BG-001 |
| [`SCR-013`](../../../../03.design/screens/SCR-013.md) | Đối soát kết quả nhận hàng | `timeline` | BJ-02 | BJ-02 | UC-02-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-014`](../../../../03.design/screens/SCR-014.md) | Việc chờ xác nhận giá | `list` | BJ-03 | BJ-03 | UC-03-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-015`](../../../../03.design/screens/SCR-015.md) | Bằng chứng và receipt | `detail` | BJ-03 | BJ-03 | UC-03-01,UC-03-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-016`](../../../../03.design/screens/SCR-016.md) | Nhập và tính giá trực tiếp | `form` | BJ-03 | BJ-03 | UC-03-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-017`](../../../../03.design/screens/SCR-017.md) | Rà soát xác nhận giá | `review` | BJ-03 | BJ-03 | UC-03-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-018`](../../../../03.design/screens/SCR-018.md) | Ghi chi phí mua bổ sung | `form` | — | — | — | `S1_RETIRED_FROM_ACTIVE_BJ13` | `HISTORICAL_ONLY` | — |
| [`SCR-019`](../../../../03.design/screens/SCR-019.md) | Kết quả định giá receipt | `result` | BJ-03 | BJ-03 | UC-03-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-020`](../../../../03.design/screens/SCR-020.md) | Đơn cần giữ hàng | `list` | BJ-04 | BJ-04 | UC-04-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-021`](../../../../03.design/screens/SCR-021.md) | Chi tiết nhu cầu và khả dụng | `detail` | BJ-04 | BJ-04 | UC-04-01,UC-04-02,UC-04-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-022`](../../../../03.design/screens/SCR-022.md) | Rà soát giữ hàng | `review` | BJ-04 | BJ-04 | UC-04-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-023`](../../../../03.design/screens/SCR-023.md) | Giải phóng hoặc phân bổ lại | `form` | BJ-04 | BJ-04 | UC-04-02,UC-04-03,UC-04-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-024`](../../../../03.design/screens/SCR-024.md) | Kết quả reservation | `result` | BJ-04 | BJ-04 | UC-04-01,UC-04-02,UC-04-03,UC-04-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-025`](../../../../03.design/screens/SCR-025.md) | Đơn cần lấy hàng | `list` | BJ-05 | BJ-05 | UC-05-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-026`](../../../../03.design/screens/SCR-026.md) | Chi tiết phân bổ | `detail` | BJ-05 | BJ-05 | UC-05-01,UC-05-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-027`](../../../../03.design/screens/SCR-027.md) | Lấy hàng theo lô | `form` | BJ-05 | BJ-05 | UC-05-02,UC-05-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-028`](../../../../03.design/screens/SCR-028.md) | Rà soát bàn giao | `review` | BJ-05 | BJ-05 | UC-05-03,UC-05-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-029`](../../../../03.design/screens/SCR-029.md) | Kết quả bàn giao | `result` | BJ-05 | BJ-05 | UC-05-03,UC-05-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-030`](../../../../03.design/screens/SCR-030.md) | Yêu cầu khách trả | `list` | BJ-06 | BJ-06 | UC-06-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-031`](../../../../03.design/screens/SCR-031.md) | Đối chiếu hàng trả | `detail` | BJ-06 | BJ-06 | UC-06-01,UC-06-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-032`](../../../../03.design/screens/SCR-032.md) | Nhận hàng thực tế | `form` | BJ-06 | BJ-06 | UC-06-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-033`](../../../../03.design/screens/SCR-033.md) | Phân loại hàng trả | `form` | BJ-06 | BJ-06 | UC-06-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-034`](../../../../03.design/screens/SCR-034.md) | Rà soát và xác nhận | `review` | BJ-06 | BJ-06 | UC-06-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-035`](../../../../03.design/screens/SCR-035.md) | Kết quả hàng trả | `result` | BJ-06 | BJ-06 | UC-06-03,UC-06-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-036`](../../../../03.design/screens/SCR-036.md) | Hàng cần xử lý | `list` | BJ-07,BJ-09,BJ-10 | BJ-07,BJ-09,BJ-10 | UC-07-01,UC-09-01,UC-09-03,UC-10-01 | `S1_READY_WITH_REVIEW` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-037`](../../../../03.design/screens/SCR-037.md) | Chi tiết hàng và bằng chứng | `detail` | BJ-07,BJ-09,BJ-10 | BJ-07,BJ-09,BJ-10 | UC-07-01,UC-09-01,UC-09-03,UC-10-01 | `S1_READY_WITH_REVIEW` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-038`](../../../../03.design/screens/SCR-038.md) | Chuyển trạng thái | `form` | BJ-07,BJ-09 | BJ-07,BJ-09 | UC-07-02,UC-07-03,UC-09-01,UC-09-02,UC-09-04 | `S1_READY_WITH_REVIEW` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-039`](../../../../03.design/screens/SCR-039.md) | Bàn giao trả nhà cung cấp | `review` | BJ-07 | BJ-07 | UC-07-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-040`](../../../../03.design/screens/SCR-040.md) | Xác nhận tiêu hủy | `review` | BJ-10 | BJ-10 | UC-10-01,UC-10-02,UC-10-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-041`](../../../../03.design/screens/SCR-041.md) | Kết quả xử lý | `result` | BJ-07,BJ-09,BJ-10 | BJ-07,BJ-09,BJ-10 | UC-07-02,UC-07-03,UC-07-04,UC-09-02,UC-09-03,UC-09-04,UC-10-04 | `S1_READY_WITH_REVIEW` | `REVIEW_KEEP_WITH_MODE_OR_SPLIT` | BG-004 |
| [`SCR-042`](../../../../03.design/screens/SCR-042.md) | Phiên kiểm kê | `list` | BJ-08 | BJ-08 | UC-08-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-043`](../../../../03.design/screens/SCR-043.md) | Chọn phạm vi và mở phiên | `form` | BJ-08 | BJ-08 | UC-08-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-044`](../../../../03.design/screens/SCR-044.md) | Đếm mù | `form` | BJ-08 | BJ-08 | UC-08-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-045`](../../../../03.design/screens/SCR-045.md) | Chênh lệch và đếm lại | `form` | BJ-08 | BJ-08 | UC-08-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-046`](../../../../03.design/screens/SCR-046.md) | Duyệt điều chỉnh | `review` | BJ-08 | BJ-08 | UC-08-04,UC-08-05 | `S1_READY_WITH_REVIEW` | `KEEP` | BG-003 |
| [`SCR-047`](../../../../03.design/screens/SCR-047.md) | Kết quả kiểm kê | `result` | BJ-08 | BJ-08 | UC-08-04,UC-08-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-048`](../../../../03.design/screens/SCR-048.md) | Danh sách operation | `list` | BJ-11 | BJ-11 | UC-11-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-049`](../../../../03.design/screens/SCR-049.md) | Chi tiết operation | `timeline` | BJ-11 | BJ-11 | UC-11-01,UC-11-03,UC-11-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-050`](../../../../03.design/screens/SCR-050.md) | Nháp và gửi operation | `form` | BJ-11 | BJ-11 | UC-11-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-051`](../../../../03.design/screens/SCR-051.md) | Quyết định phê duyệt | `review` | BJ-11 | BJ-11 | UC-11-04 | `S1_READY_WITH_REVIEW` | `KEEP` | BG-003 |
| [`SCR-052`](../../../../03.design/screens/SCR-052.md) | Hủy hoặc sửa sai | `form` | BJ-11 | BJ-11 | UC-11-02,UC-11-03 | `S1_BLOCKED_BY_DECISION` | `SPLIT_RECOMMENDED` | BG-005 |
| [`SCR-053`](../../../../03.design/screens/SCR-053.md) | Kết quả kiểm soát operation | `result` | BJ-11 | BJ-11 | UC-11-02,UC-11-04,UC-11-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-054`](../../../../03.design/screens/SCR-054.md) | Tra cứu thẻ kho | `form` | BJ-01,BJ-15 | BJ-01,BJ-15 | UC-01-01,UC-15-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-055`](../../../../03.design/screens/SCR-055.md) | Danh sách biến động | `list` | BJ-15 | BJ-15 | UC-15-02,UC-15-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-056`](../../../../03.design/screens/SCR-056.md) | Chi tiết movement | `detail` | BJ-01,BJ-09,BJ-15 | BJ-01,BJ-09,BJ-15 | UC-01-03,UC-09-04,UC-15-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-057`](../../../../03.design/screens/SCR-057.md) | Dòng thời gian nguồn | `timeline` | BJ-01,BJ-15 | BJ-01,BJ-15 | UC-01-03,UC-15-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-058`](../../../../03.design/screens/SCR-058.md) | Rà soát bản xuất | `review` | BJ-15 | BJ-15 | UC-15-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-059`](../../../../03.design/screens/SCR-059.md) | Kết quả xuất báo cáo | `result` | BJ-15 | BJ-15 | UC-15-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-060`](../../../../03.design/screens/SCR-060.md) | Chỉ báo tồn kho | `dashboard` | BJ-01 | BJ-01 | UC-01-04,UC-01-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-061`](../../../../03.design/screens/SCR-061.md) | Chi tiết chỉ báo sản phẩm | `detail` | BJ-01 | BJ-01 | UC-01-04,UC-01-05 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-062`](../../../../03.design/screens/SCR-062.md) | Cấu hình chính sách tồn | `form` | CAP-01 | — | — | `S1_READY_WITH_REVIEW` | `KEEP_SUPPORTING_CAPABILITY` | BG-006 |
| [`SCR-063`](../../../../03.design/screens/SCR-063.md) | Cấu hình hàng cận hạn | `form` | CAP-01 | — | — | `S1_READY_WITH_REVIEW` | `KEEP_SUPPORTING_CAPABILITY` | BG-006 |
| [`SCR-064`](../../../../03.design/screens/SCR-064.md) | Rà soát chính sách | `review` | CAP-01 | — | — | `S1_READY_WITH_REVIEW` | `KEEP_SUPPORTING_CAPABILITY` | BG-006 |
| [`SCR-065`](../../../../03.design/screens/SCR-065.md) | Kết quả cập nhật | `result` | CAP-01 | — | — | `S1_READY_WITH_REVIEW` | `KEEP_SUPPORTING_CAPABILITY` | BG-006 |
| [`SCR-066`](../../../../03.design/screens/SCR-066.md) | Các batch số dư đầu kỳ | `list` | BJ-12 | BJ-12 | UC-12-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-067`](../../../../03.design/screens/SCR-067.md) | Nạp file và thiết lập cut-off | `form` | BJ-12 | BJ-12 | UC-12-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-068`](../../../../03.design/screens/SCR-068.md) | Kiểm tra dữ liệu | `detail` | BJ-12 | BJ-12 | UC-12-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-069`](../../../../03.design/screens/SCR-069.md) | Rà soát và gửi duyệt | `review` | BJ-12 | BJ-12 | UC-12-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-070`](../../../../03.design/screens/SCR-070.md) | Xác nhận kích hoạt | `review` | BJ-12 | BJ-12 | UC-12-02,UC-12-03 | `S1_READY_WITH_REVIEW` | `KEEP` | BG-003 |
| [`SCR-071`](../../../../03.design/screens/SCR-071.md) | Báo cáo kích hoạt | `result` | BJ-12 | BJ-12 | UC-12-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-072`](../../../../03.design/screens/SCR-072.md) | Kỳ và lần tính giá vốn | `list` | BJ-14 | BJ-14 | UC-14-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-073`](../../../../03.design/screens/SCR-073.md) | Khởi tạo lần tính | `form` | BJ-14 | BJ-14 | UC-14-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-074`](../../../../03.design/screens/SCR-074.md) | Kết quả hai phương pháp | `dashboard` | BJ-14 | BJ-14 | UC-14-02,UC-14-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-075`](../../../../03.design/screens/SCR-075.md) | Blocker và adjustment | `detail` | BJ-14 | BJ-14 | UC-14-02,UC-14-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-076`](../../../../03.design/screens/SCR-076.md) | Rà soát công bố | `review` | BJ-14 | BJ-14 | UC-14-03,UC-14-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-077`](../../../../03.design/screens/SCR-077.md) | Kết quả công bố | `result` | BJ-14 | BJ-14 | UC-14-04 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-078`](../../../../03.design/screens/SCR-078.md) | Hồ sơ cần đối soát | `list` | BJ-16,BJ-17 | BJ-16,BJ-17 | UC-16-01,UC-17-01 | `S1_READY_DERIVED` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-079`](../../../../03.design/screens/SCR-079.md) | Bằng chứng đối soát | `timeline` | BJ-16,BJ-17 | BJ-16,BJ-17 | UC-16-02,UC-16-03,UC-17-01,UC-17-04 | `S1_READY_DERIVED` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-080`](../../../../03.design/screens/SCR-080.md) | Chọn hành động phục hồi | `form` | BJ-16,BJ-17 | BJ-16,BJ-17 | UC-16-02,UC-16-03,UC-17-02,UC-17-03 | `S1_READY_DERIVED` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-081`](../../../../03.design/screens/SCR-081.md) | Tiến độ dựng lại | `detail` | BJ-16 | BJ-16 | UC-16-03 | `S1_READY_WITH_REVIEW` | `KEEP_TRACE_CORRECTED` | BG-007 |
| [`SCR-082`](../../../../03.design/screens/SCR-082.md) | Rà soát kết quả | `review` | BJ-16,BJ-17 | BJ-16,BJ-17 | UC-16-04,UC-17-02,UC-17-03 | `S1_READY_DERIVED` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-083`](../../../../03.design/screens/SCR-083.md) | Kết quả đối soát | `result` | BJ-16,BJ-17 | BJ-16,BJ-17 | UC-16-04,UC-17-02,UC-17-03,UC-17-04 | `S1_READY_DERIVED` | `KEEP_WITH_CONTEXT_MODE` | — |
| [`SCR-084`](../../../../03.design/screens/SCR-084.md) | Chi tiết hàng thực nhận | `form` | BJ-02 | BJ-02 | UC-02-01,UC-02-02 | `S1_READY_DERIVED` | `ADD` | — |
| [`SCR-085`](../../../../03.design/screens/SCR-085.md) | Chi phí mua bổ sung | `list` | BJ-13 | BJ-13 | UC-13-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-086`](../../../../03.design/screens/SCR-086.md) | Nguồn và phạm vi chi phí | `detail` | BJ-13 | BJ-13 | UC-13-01 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-087`](../../../../03.design/screens/SCR-087.md) | Phân bổ chi phí | `form` | BJ-13 | BJ-13 | UC-13-02 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-088`](../../../../03.design/screens/SCR-088.md) | Rà soát ghi chi phí | `review` | BJ-13 | BJ-13 | UC-13-03 | `S1_READY_DERIVED` | `KEEP` | — |
| [`SCR-089`](../../../../03.design/screens/SCR-089.md) | Kết quả ghi chi phí | `result` | BJ-13 | BJ-13 | UC-13-03 | `S1_READY_DERIVED` | `KEEP` | — |
