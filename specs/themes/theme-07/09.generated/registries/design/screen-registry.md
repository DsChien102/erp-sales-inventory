# Screen Registry — Theme 7 v4.6.0

> Nguồn hiện hành: Screen Contract + runtime/workbench. Màn `RETIRED` chỉ tồn tại để migration/trace và không phải route sản phẩm.

| Screen | Tên | Surface | BJ | UC | Trạng thái | Prototype |
|---|---|---|---|---|---|---|
| `SCR-001` | Tồn kho | list | BJ-01 | UC-01-01, UC-01-04, UC-01-05 | BUSINESS_JOURNEY | BJ01_ACTIVE_v3.9.1 |
| `SCR-002` | Kết quả khả dụng | dashboard | BJ-01 | UC-01-02 | BUSINESS_JOURNEY | MERGED_INTO_SCR-003 |
| `SCR-003` | Chi tiết tồn kho | detail | BJ-01 | UC-01-02, UC-01-03, UC-01-04, UC-01-05 | BUSINESS_JOURNEY | BJ01_ACTIVE_v3.9.1 |
| `SCR-004` | Chi tiết lô | overlay | BJ-01 | UC-01-02, UC-01-05 | BUSINESS_JOURNEY | OVERLAY_IN_SCR-003_v3.9.1 |
| `SCR-005` | Nguồn và thời điểm cập nhật | overlay | BJ-01 | UC-01-03 | BUSINESS_JOURNEY | OVERLAY_IN_SCR-003_v3.9.1 |
| `SCR-006` | Chọn cách nhận hàng — Đã gộp vào SCR-007 | choice | — | — | HISTORICAL_MIGRATION | RETIRED_v5.8.0 |
| `SCR-007` | Chứng từ chờ nhận | list | BJ-02 | UC-02-01 | BUSINESS_JOURNEY | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-008` | Thông tin nhập hàng nhanh | form | BJ-02 | UC-02-02 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-009` | Hàng thực nhận | list | BJ-02 | UC-02-01, UC-02-02 | BUSINESS_JOURNEY | BJ02_PILOT_REFINED_v0.3.4 |
| `SCR-010` | Rà soát và gửi xử lý | review | BJ-02 | UC-02-01, UC-02-02, UC-02-03 | BUSINESS_JOURNEY | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-011` | Phê duyệt yêu cầu nhận hàng | review | BJ-02 | UC-02-03 | BUSINESS_JOURNEY | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-012` | Kết quả nhận hàng | result | BJ-02 | UC-02-04, UC-02-05 | BUSINESS_JOURNEY | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-013` | Đối soát kết quả nhận hàng | timeline | BJ-02 | UC-02-05 | BUSINESS_JOURNEY | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-014` | Hàng chờ xác lập giá trị | list | BJ-03 | UC-03-01 | BUSINESS_JOURNEY | UIUX_HARDENED_v4.3.0 |
| `SCR-015` | Xác lập giá trị nhập ban đầu | detail | BJ-03 | UC-03-01 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-016` | Căn cứ và cách tính — Đã hợp nhất | form | BJ-03 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-017` | Rà soát giá trị nhập ban đầu | review | BJ-03 | UC-03-01 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-018` | Ghi chi phí mua bổ sung — Đã thay thế | form | BJ-13 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-019` | Kết quả xác lập giá trị | result | BJ-03 | UC-03-01 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-020` | Đơn cần giữ hàng | list | BJ-04 | UC-04-01 | HISTORICAL_MIGRATION | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-021` | Giữ hàng theo đơn | detail | BJ-04 | UC-04-01, UC-04-02, UC-04-03, UC-04-04 | BUSINESS_JOURNEY | ACTIVE_v3.9.6 |
| `SCR-022` | Rà soát giữ hàng | review | BJ-04 | UC-04-01 | HISTORICAL_MIGRATION | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-023` | Giải phóng hoặc phân bổ lại | form | BJ-04 | UC-04-02, UC-04-03, UC-04-04 | HISTORICAL_MIGRATION | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-024` | Kết quả reservation | result | BJ-04 | UC-04-01, UC-04-02, UC-04-03, UC-04-04 | HISTORICAL_MIGRATION | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-025` | Đơn cần lấy hàng | list | BJ-05 | UC-05-01 | BUSINESS_JOURNEY | ACTIVE_v1.3.7 |
| `SCR-026` | Hàng cần lấy | detail | BJ-05 | UC-05-01, UC-05-04 | BUSINESS_JOURNEY | ACTIVE_v1.3.7 |
| `SCR-027` | Chi tiết lấy hàng | form | BJ-05 | UC-05-02, UC-05-04 | BUSINESS_JOURNEY | ACTIVE_v1.3.7 |
| `SCR-028` | Rà soát bàn giao | review | BJ-05 | UC-05-03, UC-05-05 | BUSINESS_JOURNEY | ACTIVE_v1.3.7 |
| `SCR-029` | Kết quả bàn giao | result | BJ-05 | UC-05-03, UC-05-05 | BUSINESS_JOURNEY | ACTIVE_v1.3.7 |
| `SCR-030` | Hàng khách trả | list | BJ-06 | UC-06-01, UC-06-02, UC-06-03, UC-06-04 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-031` | Hàng khách trả | detail | BJ-06 | UC-06-01, UC-06-02, UC-06-03 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-032` | Chi tiết hàng trả | form | BJ-06 | UC-06-01, UC-06-02 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-033` | Phân loại hàng trả | form | BJ-06 | UC-06-04 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-034` | Ngoại lệ lô cần duyệt | review | BJ-06 | UC-06-02 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-035` | Kết quả hàng trả | result | BJ-06 | UC-06-03, UC-06-04 | BUSINESS_JOURNEY | ACTIVE_v1.3.9 |
| `SCR-036` | Hàng chờ trả nhà cung cấp | list | BJ-07, BJ-09, BJ-10 | UC-07-01, UC-09-01, UC-09-03, UC-10-01 | BUSINESS_JOURNEY | UIF07_CONTEXT_ACTIVE_v1.3.6 |
| `SCR-037` | Chuẩn bị hàng trả | detail | BJ-07, BJ-09, BJ-10 | UC-07-01, UC-09-01, UC-09-03, UC-10-01 | BUSINESS_JOURNEY | UIF07_CONTEXT_ACTIVE_v1.3.6 |
| `SCR-038` | Chuyển trạng thái | form | BJ-07, BJ-09 | UC-07-02, UC-07-03, UC-09-01, UC-09-02, UC-09-04 | BUSINESS_JOURNEY | EXCLUDED_FROM_UIF07_v1.3.4 |
| `SCR-039` | Bàn giao trả nhà cung cấp | review | BJ-07 | UC-07-04 | BUSINESS_JOURNEY | UIF07_DEEP_CORRECTED_v1.3.9 |
| `SCR-040` | Yêu cầu tiêu hủy | review | BJ-10 | UC-10-01, UC-10-02, UC-10-03 | BUSINESS_JOURNEY | HARNESS_FULL_WORKBENCH |
| `SCR-041` | Kết quả xử lý | result | BJ-07, BJ-09, BJ-10 | UC-07-02, UC-07-03, UC-07-04, UC-09-02, UC-09-03, UC-09-04, UC-10-04 | BUSINESS_JOURNEY | UIF07_CONTEXT_ACTIVE_v1.3.4 |
| `SCR-042` | Kiểm kê kho | list | BJ-08 | UC-08-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-043` | Tạo phiên kiểm kê | form | BJ-08 | UC-08-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-044` | Đếm mù | form | BJ-08 | UC-08-02, UC-08-05 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-045` | Chênh lệch và đếm lại | form | BJ-08 | UC-08-03, UC-08-05 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-046` | Duyệt điều chỉnh | review | BJ-08 | UC-08-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-047` | Kết quả kiểm kê | result | BJ-08 | UC-08-02, UC-08-03, UC-08-04, UC-08-05 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-048` | Nghiệp vụ cần kiểm soát | list | BJ-11 | UC-11-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-049` | Chi tiết nghiệp vụ kho | timeline | BJ-11 | UC-11-01, UC-11-03, UC-11-05 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-050` | Nội dung sửa sai | form | BJ-11 | UC-11-03, UC-11-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-051` | Duyệt sửa sai | review | BJ-11 | UC-11-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-052` | Hủy hoặc chọn cách sửa | form | BJ-11 | UC-11-02, UC-11-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-053` | Kết quả sửa sai | result | BJ-11 | UC-11-02, UC-11-04, UC-11-05 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-054` | Tra cứu thẻ kho | form | BJ-01, BJ-15 | UC-01-01, UC-15-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-055` | Danh sách biến động | list | BJ-15, BJ-01 | UC-15-02, UC-15-03, UC-01-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-056` | Chi tiết movement | detail | BJ-01, BJ-09, BJ-15 | UC-01-03, UC-09-04, UC-15-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-057` | Dòng thời gian nguồn | timeline | BJ-01, BJ-15 | UC-01-03, UC-15-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-058` | Xuất báo cáo | review | BJ-15 | UC-15-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-059` | Kết quả xuất báo cáo | result | BJ-15 | UC-15-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-060` | Chỉ báo tồn kho | dashboard | BJ-01 | UC-01-04, UC-01-05 | BUSINESS_JOURNEY | MERGED_INTO_SCR-001 |
| `SCR-061` | Chi tiết chỉ báo sản phẩm | detail | BJ-01 | UC-01-04, UC-01-05 | BUSINESS_JOURNEY | MERGED_INTO_SCR-003 |
| `SCR-062` | Cấu hình chính sách tồn | form | — | — | BUSINESS_JOURNEY | RENDERED_v3.6.0 |
| `SCR-063` | Cấu hình hàng cận hạn | form | — | — | BUSINESS_JOURNEY | RENDERED_v3.6.0 |
| `SCR-064` | Rà soát chính sách — Đã thay bằng sheet tác động (SCR-062) | review | — | — | HISTORICAL_MIGRATION | RETIRED_v5.7.0 |
| `SCR-065` | Kết quả cập nhật | result | — | — | BUSINESS_JOURNEY | RENDERED_v3.6.0 |
| `SCR-066` | Khởi tạo tồn kho | status / entry | BJ-12 | UC-12-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-067` | Dữ liệu tồn kho đầu kỳ | form | BJ-12 | UC-12-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-068` | Kết quả kiểm tra dữ liệu | validation result | BJ-12 | UC-12-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-069` | Rà soát số dư đầu kỳ — Đã hợp nhất | review | BJ-12 | — | HISTORICAL_MIGRATION | RETIRED_v5.5.0 |
| `SCR-070` | Duyệt số dư đầu kỳ | approval review | BJ-12 | UC-12-02, UC-12-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-071` | Kết quả khởi tạo tồn kho | result | BJ-12 | UC-12-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-072` | Công việc giá vốn | list | BJ-14 | UC-14-01, UC-14-04 | BUSINESS_JOURNEY | UIUX_HARDENED_v4.3.0 |
| `SCR-073` | Thiết lập lần tính — Đã hợp nhất | form | BJ-14 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-074` | Tính và rà soát giá vốn | dashboard | BJ-14 | UC-14-01, UC-14-04 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-075` | Blocker và adjustment — Đã hợp nhất | detail | BJ-14 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-076` | Rà soát công bố — Đã hợp nhất | review | BJ-14 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-077` | Kết quả công bố giá vốn | result | BJ-14 | UC-14-04 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-078` | Hồ sơ cần kiểm tra | list | BJ-16, BJ-17 | UC-16-01, UC-17-01 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-079` | Bằng chứng & kết luận | timeline | BJ-16, BJ-17 | UC-16-02, UC-16-03, UC-17-01, UC-17-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-080` | Phương án xử lý | form | BJ-16, BJ-17 | UC-16-02, UC-16-03, UC-17-02, UC-17-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-081` | Đang khôi phục số liệu | detail | BJ-16 | UC-16-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-082` | Rà soát kết quả | review | BJ-16, BJ-17 | UC-16-04, UC-17-02, UC-17-03 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-083` | Kết quả xử lý | result | BJ-16, BJ-17 | UC-16-04, UC-17-02, UC-17-03, UC-17-04 | BUSINESS_JOURNEY | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-084` | Chi tiết hàng thực nhận | form | BJ-02 | UC-02-01, UC-02-02 | BUSINESS_JOURNEY | BJ02_PILOT_REFINED_v1.3.4 |
| `SCR-085` | Điều chỉnh giá trị hàng nhập | list | BJ-13 | UC-13-01 | BUSINESS_JOURNEY | UIUX_HARDENED_v4.3.0 |
| `SCR-086` | Phân bổ điều chỉnh giá trị | detail | BJ-13 | UC-13-01 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
| `SCR-087` | Phân bổ điều chỉnh — Đã hợp nhất | form | BJ-13 | — | HISTORICAL_MIGRATION | RETIRED_v3.13.0 |
| `SCR-088` | Rà soát điều chỉnh — Đã hợp nhất | review | BJ-13 | — | HISTORICAL_MIGRATION | RETIRED_v4.6.0 |
| `SCR-089` | Kết quả điều chỉnh giá trị | result | BJ-13 | UC-13-01 | BUSINESS_JOURNEY | SEMANTIC_UX_v4.6.0 |
