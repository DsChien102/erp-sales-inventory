# Traceability matrix — v4.3.0

> Screen/Slice phản ánh topology canonical hiện hành. Screen đã retired chỉ giữ ở migration/compatibility evidence, không xuất hiện trong cột Screen hiện hành.

| UC | Tên | BJ | BC | Screen hiện hành | Slice hiện hành | UI Flow |
|---|---|---|---|---|---|---|
| `UC-01-01` | Xác định ngữ cảnh và sản phẩm | `BJ-01` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-001` | `BE-01-01`, `FE-SCR-001`, `FE-SCR-054` | `UIF-01` |
| `UC-01-02` | Xem tồn và khả dụng | `BJ-01` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-003`, `SCR-004` | `BE-01-02`, `FE-SCR-002`, `FE-SCR-003`, `FE-SCR-004` | `UIF-01` |
| `UC-01-03` | Xem trace summary | `BJ-01` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-005`, `SCR-003` | `BE-01-03`, `FE-SCR-003`, `FE-SCR-005`, `FE-SCR-055`, `FE-SCR-056`, `FE-SCR-057` | `UIF-01` |
| `UC-01-04` | Xem tồn thấp và lượng gợi ý | `BJ-01` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-14` | `SCR-001`, `SCR-003` | `BE-01-04`, `FE-SCR-001`, `FE-SCR-003`, `FE-SCR-060`, `FE-SCR-061` | `UIF-01` |
| `UC-01-05` | Xem hàng cận hạn và hết hạn | `BJ-01` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-14` | `SCR-001`, `SCR-003`, `SCR-004` | `BE-01-05`, `FE-SCR-001`, `FE-SCR-003`, `FE-SCR-004`, `FE-SCR-060`, `FE-SCR-061` | `UIF-01` |
| `UC-02-01` | Chuẩn bị nhận theo chứng từ | `BJ-02` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-006`, `SCR-007`, `SCR-009`, `SCR-084`, `SCR-010` | `BE-02-01`, `FE-SCR-006`, `FE-SCR-007`, `FE-SCR-009`, `FE-SCR-010`, `FE-SCR-084` | `UIF-02` |
| `UC-02-02` | Chuẩn bị nhập hàng nhanh | `BJ-02` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-006`, `SCR-008`, `SCR-009`, `SCR-084`, `SCR-010` | `BE-02-02`, `FE-SCR-006`, `FE-SCR-008`, `FE-SCR-009`, `FE-SCR-010`, `FE-SCR-084` | `UIF-02` |
| `UC-02-03` | Phê duyệt yêu cầu nhận hàng | `BJ-02` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06` | `SCR-010`, `SCR-011` | `BE-02-03`, `FE-SCR-010`, `FE-SCR-011` | `UIF-02` |
| `UC-02-04` | Ghi nhận hàng vào tồn vật lý | `BJ-02` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-02` | `SCR-012` | `BE-02-04`, `FE-SCR-012` | `UIF-02` |
| `UC-02-05` | Truy vấn và phục hồi ngắn kết quả nhận hàng | `BJ-02` | `SBC-COM-03`, `BC-IO-02` | `SCR-012`, `SCR-013` | `BE-02-05`, `FE-SCR-012`, `FE-SCR-013` | `UIF-02` |
| `UC-03-01` | Xác lập giá trị nhập ban đầu | `BJ-03` | `BC-IV-05`, `BC-IV-01` | `SCR-014`, `SCR-015`, `SCR-017`, `SCR-019` | `BE-03-01`, `BE-03-02`, `BE-03-03`, `FE-SCR-014`, `FE-SCR-015`, `FE-SCR-017`, `FE-SCR-019` | `UIF-03` |
| `UC-04-01` | Tạo reservation | `BJ-04` | `BC-IO-03` | `SCR-021` | `BE-04-01`, `FE-SCR-020`, `FE-SCR-021`, `FE-SCR-022`, `FE-SCR-024` | `UIF-04` |
| `UC-04-02` | Điều chỉnh reservation | `BJ-04` | `BC-IO-06` | `SCR-021` | `BE-04-02`, `FE-SCR-021`, `FE-SCR-023`, `FE-SCR-024` | `UIF-04` |
| `UC-04-03` | Kết thúc và giải phóng | `BJ-04` | `BC-IO-06` | `SCR-021` | `BE-04-03`, `FE-SCR-021`, `FE-SCR-023`, `FE-SCR-024` | `UIF-04` |
| `UC-04-04` | Đánh giá lại và xử lý thiếu | `BJ-04` | `BC-IO-06` | `SCR-021` | `BE-04-04`, `FE-SCR-021`, `FE-SCR-023`, `FE-SCR-024` | `UIF-04` |
| `UC-05-01` | Lập allocation | `BJ-05` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15` | `SCR-025`, `SCR-026` | `BE-05-01`, `FE-SCR-025`, `FE-SCR-026` | `UIF-05` |
| `UC-05-02` | Xác nhận hàng đã lấy | `BJ-05` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15` | `SCR-027` | `BE-05-02`, `FE-SCR-027` | `UIF-05` |
| `UC-05-03` | Bàn giao hàng | `BJ-05` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-05` | `SCR-028`, `SCR-029` | `BE-05-03`, `FE-SCR-028`, `FE-SCR-029` | `UIF-05` |
| `UC-05-04` | Phục hồi allocation stale | `BJ-05` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-15`, `BC-IO-06` | `SCR-026`, `SCR-027` | `BE-05-04`, `FE-SCR-026`, `FE-SCR-027` | `UIF-05` |
| `UC-05-05` | Ghi xuất kho nguyên tử | `BJ-05` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-04`, `BC-IO-05` | `SCR-028`, `SCR-029` | `BE-05-05`, `FE-SCR-028`, `FE-SCR-029` | `UIF-05` |
| `UC-06-01` | Xác minh hàng được phép nhận trả | `BJ-06` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07` | `SCR-030`, `SCR-031` | `BE-06-01`, `FE-SCR-030`, `FE-SCR-031`, `FE-SCR-032` | `UIF-06` |
| `UC-06-02` | Xử lý ngoại lệ truy vết | `BJ-06` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07` | `SCR-031`, `SCR-032`, `SCR-034` | `BE-06-02`, `FE-SCR-030`, `FE-SCR-031`, `FE-SCR-032`, `FE-SCR-034` | `UIF-06` |
| `UC-06-03` | Ghi nhận hàng khách trả | `BJ-06` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-07` | `SCR-031`, `SCR-032`, `SCR-035` | `BE-06-03`, `FE-SCR-030`, `FE-SCR-031`, `FE-SCR-035` | `UIF-06` |
| `UC-06-04` | Phân loại hàng thực nhận | `BJ-06` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-08` | `SCR-033`, `SCR-035` | `BE-06-04`, `FE-SCR-030`, `FE-SCR-033`, `FE-SCR-035` | `UIF-06` |
| `UC-07-01` | Xác minh phạm vi trả | `BJ-07` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17` | `SCR-036`, `SCR-037` | `BE-07-01`, `FE-SCR-036`, `FE-SCR-037` | `UIF-07` |
| `UC-07-02` | Đồng bộ hàng vào chờ trả | `BJ-07` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17` | `SCR-036`, `SCR-037`, `SCR-041` | `BE-07-02`, `FE-SCR-038`, `FE-SCR-041` | `UIF-07` |
| `UC-07-03` | Điều chỉnh hoặc hủy trước bàn giao | `BJ-07` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-17` | `SCR-036`, `SCR-037` | `BE-07-03`, `FE-SCR-038`, `FE-SCR-041` | `UIF-07` |
| `UC-07-04` | Ghi nhận bàn giao trả nhà cung cấp | `BJ-07` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-09` | `SCR-039`, `SCR-041` | `BE-07-04`, `FE-SCR-039`, `FE-SCR-041` | `UIF-07` |
| `UC-08-01` | Mở và khóa phạm vi | `BJ-08` | `BC-IC-01`, `SBC-COM-03` | `SCR-042`, `SCR-043` | `BE-08-01`, `FE-SCR-042`, `FE-SCR-043` | `UIF-08` |
| `UC-08-02` | Ghi nhận lần đếm mù | `BJ-08` | `BC-IC-02`, `SBC-COM-03` | `SCR-044` | `BE-08-02`, `FE-SCR-044`, `FE-SCR-047` | `UIF-08` |
| `UC-08-03` | Đếm lại và hoàn thiện căn cứ | `BJ-08` | `BC-IC-02`, `SBC-COM-03` | `SCR-045` | `BE-08-03`, `FE-SCR-045`, `FE-SCR-047` | `UIF-08` |
| `UC-08-04` | Duyệt và điều chỉnh | `BJ-08` | `BC-IC-03`, `SBC-COM-03`, `SBC-COM-04` | `SCR-046`, `SCR-047` | `BE-08-04`, `FE-SCR-046`, `FE-SCR-047` | `UIF-08` |
| `UC-08-05` | Hủy phiên kiểm kê | `BJ-08` | `BC-IC-08`, `SBC-COM-03`, `SBC-COM-04` | `SCR-044`, `SCR-045`, `SCR-047` | `BE-08-05`, `FE-SCR-044`, `FE-SCR-045`, `FE-SCR-047` | `UIF-08` |
| `UC-09-01` | Chuẩn bị thay đổi trạng thái | `BJ-09` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-036`, `SCR-037`, `SCR-038` | `BE-09-01`, `FE-SCR-036`, `FE-SCR-037`, `FE-SCR-038` | `UIF-09` |
| `UC-09-02` | Phê duyệt thay đổi trạng thái | `BJ-09` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06` | `SCR-038`, `SCR-041` | `BE-09-02`, `FE-SCR-038`, `FE-SCR-041` | `UIF-09` |
| `UC-09-03` | Xác định hàng hết hạn | `BJ-09` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-10` | `SCR-036`, `SCR-037`, `SCR-041` | `BE-09-03`, `FE-SCR-036`, `FE-SCR-037`, `FE-SCR-041` | `UIF-09` |
| `UC-09-04` | Ghi state movement | `BJ-09` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-10` | `SCR-038`, `SCR-041`, `SCR-056` | `BE-09-04`, `FE-SCR-038`, `FE-SCR-041`, `FE-SCR-056` | `UIF-09` |
| `UC-10-01` | Chuẩn bị yêu cầu tiêu hủy | `BJ-10` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-036`, `SCR-037`, `SCR-040` | `BE-10-01`, `FE-SCR-036`, `FE-SCR-037`, `FE-SCR-040` | `UIF-10` |
| `UC-10-02` | Phê duyệt tiêu hủy | `BJ-10` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06` | `SCR-040` | `BE-10-02`, `FE-SCR-040` | `UIF-10` |
| `UC-10-03` | Xác nhận đã tiêu hủy | `BJ-10` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-11` | `SCR-040` | `BE-10-03`, `FE-SCR-040` | `UIF-10` |
| `UC-10-04` | Ghi giảm hàng tiêu hủy | `BJ-10` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-11` | `SCR-041` | `BE-10-04`, `FE-SCR-041` | `UIF-10` |
| `UC-11-01` | Xác định đường xử lý | `BJ-11` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-048`, `SCR-049`, `SCR-050` | `BE-11-01`, `FE-SCR-048`, `FE-SCR-049` | `UIF-11` |
| `UC-11-02` | Hủy operation chưa thực thi | `BJ-11` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-12` | `SCR-052`, `SCR-053` | `BE-11-02`, `FE-SCR-052`, `FE-SCR-053` | `UIF-11` |
| `UC-11-03` | Chuẩn bị phương án correction | `BJ-11` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-16`, `BC-IC-07` | `SCR-049`, `SCR-052` | `BE-11-03`, `FE-SCR-049`, `FE-SCR-050`, `FE-SCR-052` | `UIF-11` |
| `UC-11-04` | Phê duyệt correction | `BJ-11` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06` | `SCR-051`, `SCR-053` | `BE-11-04`, `FE-SCR-050`, `FE-SCR-051`, `FE-SCR-053` | `UIF-11` |
| `UC-11-05` | Ghi correction chain | `BJ-11` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IO-13` | `SCR-049`, `SCR-053` | `BE-11-05`, `FE-SCR-049`, `FE-SCR-053` | `UIF-11` |
| `UC-12-01` | Nạp và kiểm tra batch đầu kỳ | `BJ-12` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-09` | `SCR-066`, `SCR-067`, `SCR-068` | `BE-12-01`, `FE-SCR-066`, `FE-SCR-067`, `FE-SCR-068` | `UIF-12` |
| `UC-12-02` | Rà soát và duyệt batch | `BJ-12` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-06` | `SCR-069`, `SCR-070` | `BE-12-02`, `FE-SCR-069`, `FE-SCR-070` | `UIF-12` |
| `UC-12-03` | Commit và kích hoạt tồn kho | `BJ-12` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-04` | `SCR-070`, `SCR-071` | `BE-12-03`, `FE-SCR-070`, `FE-SCR-071` | `UIF-12` |
| `UC-13-01` | Ghi nhận điều chỉnh giá trị hàng nhập | `BJ-13` | `BC-IV-06`, `BC-IV-04` | `SCR-085`, `SCR-086`, `SCR-088`, `SCR-089` | `BE-13-01`, `BE-13-02`, `BE-13-03`, `FE-SCR-085`, `FE-SCR-086`, `FE-SCR-088`, `FE-SCR-089` | `UIF-13` |
| `UC-14-01` | Tính và rà soát giá vốn | `BJ-14` | `BC-IV-02` | `SCR-072`, `SCR-074` | `BE-14-01`, `BE-14-02`, `BE-14-03`, `FE-SCR-072`, `FE-SCR-074` | `UIF-14` |
| `UC-14-04` | Công bố giá vốn | `BJ-14` | `BC-IV-03` | `SCR-074`, `SCR-077` | `BE-14-04`, `FE-SCR-074`, `FE-SCR-077` | `UIF-14` |
| `UC-15-01` | Xác định báo cáo và phạm vi | `BJ-15` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-054` | `BE-15-01`, `FE-SCR-054` | `UIF-15` |
| `UC-15-02` | Xem báo cáo tồn kho | `BJ-15` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-055` | `BE-15-02`, `FE-SCR-055` | `UIF-15` |
| `UC-15-03` | Xem thẻ kho và lịch sử | `BJ-15` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-055`, `SCR-056`, `SCR-057` | `BE-15-03`, `FE-SCR-055`, `FE-SCR-056`, `FE-SCR-057` | `UIF-15` |
| `UC-15-04` | Xuất báo cáo | `BJ-15` | `SBC-COM-02`, `BC-COMMON-EXTENSIONS`, `SBC-COM-03`, `BC-IO-01` | `SCR-058`, `SCR-059` | `BE-15-04`, `FE-SCR-058`, `FE-SCR-059` | `UIF-15` |
| `UC-16-01` | Mở và phân loại hồ sơ đối soát | `BJ-16` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-078` | `BE-16-01`, `FE-SCR-078` | `UIF-16` |
| `UC-16-02` | Bảo vệ phạm vi rủi ro | `BJ-16` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-079`, `SCR-080` | `BE-16-02`, `FE-SCR-079`, `FE-SCR-080` | `UIF-16` |
| `UC-16-03` | Điều tra và xác định nguyên nhân | `BJ-16` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-079`, `SCR-080` | `BE-16-03`, `FE-SCR-079`, `FE-SCR-080`, `FE-SCR-081` | `UIF-16` |
| `UC-16-04` | Xác minh và cập nhật kết quả đối soát | `BJ-16` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-082`, `SCR-083` | `BE-16-04`, `FE-SCR-082`, `FE-SCR-083` | `UIF-16` |
| `UC-17-01` | Thu thập và đánh giá bằng chứng | `BJ-17` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-078`, `SCR-079` | `BE-17-01`, `FE-SCR-078`, `FE-SCR-079` | `UIF-17` |
| `UC-17-02` | Xác lập operation đã hoàn tất | `BJ-17` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-080`, `SCR-082`, `SCR-083` | `BE-17-02`, `FE-SCR-080`, `FE-SCR-082`, `FE-SCR-083` | `UIF-17` |
| `UC-17-03` | Tiếp tục cùng operation identity | `BJ-17` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-080`, `SCR-082`, `SCR-083` | `BE-17-03`, `FE-SCR-080`, `FE-SCR-082`, `FE-SCR-083` | `UIF-17` |
| `UC-17-04` | Giữ chưa xác định và escalated | `BJ-17` | `SBC-COM-01`, `BC-COMMON-EXTENSIONS`, `SBC-COM-02`, `SBC-COM-03`, `SBC-COM-04`, `BC-IC-05` | `SCR-079`, `SCR-083` | `BE-17-04`, `FE-SCR-079`, `FE-SCR-083` | `UIF-17` |
