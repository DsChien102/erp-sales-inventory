---
id: UC-MAP
type: use-case-map
theme: theme-07
title: "Use Case Map — Theme 07"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# Bản đồ trường hợp sử dụng Theme 7 4.2.0-rc1

> Chỉ liệt kê 70 UC canonical thuộc 17 BJ nội Theme. CAP-01, PROC-01 và 19 UC outbound không được tính vào danh mục này.

| STT | UC | Tên | BJ sở hữu | Hợp đồng hành vi | Màn hình |
|---:|---|---|---|---|---|
| 1 | [UC-01-01](UC-01-01-xac-dinh-ngu-canh-va-san-pham.md) | Xác định ngữ cảnh và sản phẩm | [BJ-01](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) · Theo dõi tồn, khả dụng và chỉ báo vận hành | BC-IO-01, BC-IO-14 | `SCR-001`, `SCR-054` |
| 2 | [UC-01-02](UC-01-02-xem-ton-va-kha-dung.md) | Xem tồn và khả dụng | [BJ-01](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) · Theo dõi tồn, khả dụng và chỉ báo vận hành | BC-IO-01 | `SCR-002`, `SCR-003`, `SCR-004` |
| 3 | [UC-01-03](UC-01-03-xem-trace-summary.md) | Xem trace summary | [BJ-01](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) · Theo dõi tồn, khả dụng và chỉ báo vận hành | BC-IO-01 | `SCR-005`, `SCR-056`, `SCR-057` |
| 4 | [UC-01-04](UC-01-04-xem-ton-thap-va-luong-goi-y.md) | Xem tồn thấp và lượng gợi ý | [BJ-01](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) · Theo dõi tồn, khả dụng và chỉ báo vận hành | BC-IO-14 | `SCR-060`, `SCR-061` |
| 5 | [UC-01-05](UC-01-05-xem-hang-can-han-va-het-han.md) | Xem hàng cận hạn và hết hạn | [BJ-01](../journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) · Theo dõi tồn, khả dụng và chỉ báo vận hành | BC-IO-14 | `SCR-060`, `SCR-061` |
| 6 | [UC-02-01](UC-02-01-chuan-bi-nhan-theo-chung-tu.md) | Chuẩn bị nhận theo chứng từ | [BJ-02](../journeys/BJ-02-nhan-hang-mua.md) · Nhận hàng mua | BC-IC-07, BC-IO-16 | `SCR-006`, `SCR-007`, `SCR-009` |
| 7 | [UC-02-02](UC-02-02-chuan-bi-nhap-hang-nhanh.md) | Chuẩn bị nhập hàng nhanh | [BJ-02](../journeys/BJ-02-nhan-hang-mua.md) · Nhận hàng mua | BC-IC-07, BC-IO-16 | `SCR-006`, `SCR-008`, `SCR-010` |
| 8 | [UC-02-03](UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | Phê duyệt yêu cầu nhận hàng | [BJ-02](../journeys/BJ-02-nhan-hang-mua.md) · Nhận hàng mua | BC-IC-06 | `SCR-010`, `SCR-011` |
| 9 | [UC-02-04](UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | Ghi nhận hàng vào tồn vật lý | [BJ-02](../journeys/BJ-02-nhan-hang-mua.md) · Nhận hàng mua | BC-IO-02 | `SCR-012` |
| 10 | [UC-02-05](UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | Truy vấn và phục hồi ngắn kết quả nhận hàng | [BJ-02](../journeys/BJ-02-nhan-hang-mua.md) · Nhận hàng mua | BC-IO-02 | `SCR-012`, `SCR-013` |
| 11 | [UC-03-01](UC-03-01-chon-pham-vi-can-dinh-gia.md) | Chọn phạm vi cần định giá | [BJ-03](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) · Xác nhận giá trị ban đầu của hàng nhận | BC-IV-01 | `SCR-014`, `SCR-015` |
| 12 | [UC-03-02](UC-03-02-xac-dinh-gia-nhap-thuc-te.md) | Xác định giá nhập thực tế | [BJ-03](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) · Xác nhận giá trị ban đầu của hàng nhận | BC-IV-01 | `SCR-015`, `SCR-016` |
| 13 | [UC-03-03](UC-03-03-xac-nhan-gia-tri.md) | Xác nhận giá trị | [BJ-03](../journeys/BJ-03-xac-nhan-gia-tri-ban-au-cua-hang-nhan.md) · Xác nhận giá trị ban đầu của hàng nhận | BC-IV-01 | `SCR-017`, `SCR-019` |
| 14 | [UC-04-01](UC-04-01-tao-reservation.md) | Tạo reservation | [BJ-04](../journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) · Quản lý vòng đời giữ hàng | BC-IO-03 | `SCR-020`, `SCR-021`, `SCR-022`, `SCR-024` |
| 15 | [UC-04-02](UC-04-02-dieu-chinh-reservation.md) | Điều chỉnh reservation | [BJ-04](../journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) · Quản lý vòng đời giữ hàng | BC-IO-06 | `SCR-021`, `SCR-023`, `SCR-024` |
| 16 | [UC-04-03](UC-04-03-ket-thuc-va-giai-phong.md) | Kết thúc và giải phóng | [BJ-04](../journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) · Quản lý vòng đời giữ hàng | BC-IO-06 | `SCR-023`, `SCR-024` |
| 17 | [UC-04-04](UC-04-04-danh-gia-lai-va-xu-ly-thieu.md) | Đánh giá lại và xử lý thiếu | [BJ-04](../journeys/BJ-04-quan-ly-vong-oi-giu-hang.md) · Quản lý vòng đời giữ hàng | BC-IO-06 | `SCR-021`, `SCR-023`, `SCR-024` |
| 18 | [UC-05-01](UC-05-01-lap-allocation.md) | Lập allocation | [BJ-05](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) · Lấy hàng và bàn giao đơn | BC-IO-15 | `SCR-025`, `SCR-026` |
| 19 | [UC-05-02](UC-05-02-xac-nhan-hang-da-lay.md) | Xác nhận hàng đã lấy | [BJ-05](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) · Lấy hàng và bàn giao đơn | BC-IO-15 | `SCR-027` |
| 20 | [UC-05-03](UC-05-03-ban-giao-hang.md) | Bàn giao hàng | [BJ-05](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) · Lấy hàng và bàn giao đơn | BC-IO-05 | `SCR-028`, `SCR-029` |
| 21 | [UC-05-04](UC-05-04-phuc-hoi-allocation-stale.md) | Phục hồi allocation stale | [BJ-05](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) · Lấy hàng và bàn giao đơn | BC-IO-06, BC-IO-15 | `SCR-026`, `SCR-027` |
| 22 | [UC-05-05](UC-05-05-ghi-xuat-kho-nguyen-tu.md) | Ghi xuất kho nguyên tử | [BJ-05](../journeys/BJ-05-lay-hang-va-ban-giao-on.md) · Lấy hàng và bàn giao đơn | BC-IO-04, BC-IO-05 | `SCR-028`, `SCR-029` |
| 23 | [UC-06-01](UC-06-01-xac-minh-hang-duoc-phep-nhan-tra.md) | Xác minh hàng được phép nhận trả | [BJ-06](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) · Tiếp nhận và phân loại hàng khách trả | BC-IO-07 | `SCR-030`, `SCR-031` |
| 24 | [UC-06-02](UC-06-02-xu-ly-ngoai-le-truy-vet.md) | Xử lý ngoại lệ truy vết | [BJ-06](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) · Tiếp nhận và phân loại hàng khách trả | BC-IO-07 | `SCR-031` |
| 25 | [UC-06-03](UC-06-03-ghi-nhan-hang-khach-tra.md) | Ghi nhận hàng khách trả | [BJ-06](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) · Tiếp nhận và phân loại hàng khách trả | BC-IO-07 | `SCR-032`, `SCR-035` |
| 26 | [UC-06-04](UC-06-04-phan-loai-hang-thuc-nhan.md) | Phân loại hàng thực nhận | [BJ-06](../journeys/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md) · Tiếp nhận và phân loại hàng khách trả | BC-IO-08 | `SCR-033`, `SCR-034`, `SCR-035` |
| 27 | [UC-07-01](UC-07-01-xac-minh-pham-vi-tra.md) | Xác minh phạm vi trả | [BJ-07](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) · Thực hiện trả hàng cho nhà cung cấp | BC-IO-09 | `SCR-036`, `SCR-037` |
| 28 | [UC-07-02](UC-07-02-dua-hang-vao-cho-tra.md) | Đưa hàng vào chờ trả | [BJ-07](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) · Thực hiện trả hàng cho nhà cung cấp | BC-IO-10 | `SCR-038`, `SCR-041` |
| 29 | [UC-07-03](UC-07-03-dieu-chinh-hoac-huy-truoc-ban-giao.md) | Điều chỉnh hoặc hủy trước bàn giao | [BJ-07](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) · Thực hiện trả hàng cho nhà cung cấp | BC-IO-10 | `SCR-038`, `SCR-041` |
| 30 | [UC-07-04](UC-07-04-ghi-nhan-ban-giao-tra-nha-cung-cap.md) | Ghi nhận bàn giao trả nhà cung cấp | [BJ-07](../journeys/BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md) · Thực hiện trả hàng cho nhà cung cấp | BC-IO-09 | `SCR-039`, `SCR-041` |
| 31 | [UC-08-01](UC-08-01-mo-va-khoa-pham-vi.md) | Mở và khóa phạm vi | [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) · Kiểm kê và điều chỉnh chênh lệch | BC-IC-01 | `SCR-042`, `SCR-043` |
| 32 | [UC-08-02](UC-08-02-ghi-nhan-lan-dem-mu.md) | Ghi nhận lần đếm mù | [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) · Kiểm kê và điều chỉnh chênh lệch | BC-IC-02 | `SCR-044` |
| 33 | [UC-08-03](UC-08-03-dem-lai-va-hoan-thien-bang-chung.md) | Đếm lại và hoàn thiện bằng chứng | [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) · Kiểm kê và điều chỉnh chênh lệch | BC-IC-02 | `SCR-045` |
| 34 | [UC-08-04](UC-08-04-duyet-va-dieu-chinh.md) | Duyệt và điều chỉnh | [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) · Kiểm kê và điều chỉnh chênh lệch | BC-IC-03 | `SCR-046`, `SCR-047` |
| 35 | [UC-08-05](UC-08-05-huy-phien-kiem-ke.md) | Hủy phiên kiểm kê | [BJ-08](../journeys/BJ-08-kiem-ke-va-ieu-chinh-chenh-lech.md) · Kiểm kê và điều chỉnh chênh lệch | BC-IC-08 | `SCR-046`, `SCR-047` |
| 36 | [UC-09-01](UC-09-01-chuan-bi-thay-doi-trang-thai.md) | Chuẩn bị thay đổi trạng thái | [BJ-09](../journeys/BJ-09-quan-ly-trang-thai-hang.md) · Quản lý trạng thái hàng | BC-IC-07, BC-IO-16 | `SCR-036`, `SCR-037`, `SCR-038` |
| 37 | [UC-09-02](UC-09-02-phe-duyet-thay-doi-trang-thai.md) | Phê duyệt thay đổi trạng thái | [BJ-09](../journeys/BJ-09-quan-ly-trang-thai-hang.md) · Quản lý trạng thái hàng | BC-IC-06 | `SCR-038`, `SCR-041` |
| 38 | [UC-09-03](UC-09-03-xac-dinh-hang-het-han.md) | Xác định hàng hết hạn | [BJ-09](../journeys/BJ-09-quan-ly-trang-thai-hang.md) · Quản lý trạng thái hàng | BC-IO-10 | `SCR-036`, `SCR-037`, `SCR-041` |
| 39 | [UC-09-04](UC-09-04-ghi-state-movement.md) | Ghi state movement | [BJ-09](../journeys/BJ-09-quan-ly-trang-thai-hang.md) · Quản lý trạng thái hàng | BC-IO-10 | `SCR-038`, `SCR-041`, `SCR-056` |
| 40 | [UC-10-01](UC-10-01-chuan-bi-yeu-cau-tieu-huy.md) | Chuẩn bị yêu cầu tiêu hủy | [BJ-10](../journeys/BJ-10-tieu-huy-hang.md) · Tiêu hủy hàng | BC-IC-07, BC-IO-16 | `SCR-036`, `SCR-037`, `SCR-040` |
| 41 | [UC-10-02](UC-10-02-phe-duyet-tieu-huy.md) | Phê duyệt tiêu hủy | [BJ-10](../journeys/BJ-10-tieu-huy-hang.md) · Tiêu hủy hàng | BC-IC-06 | `SCR-040` |
| 42 | [UC-10-03](UC-10-03-xac-nhan-da-tieu-huy.md) | Xác nhận đã tiêu hủy | [BJ-10](../journeys/BJ-10-tieu-huy-hang.md) · Tiêu hủy hàng | BC-IO-11 | `SCR-040` |
| 43 | [UC-10-04](UC-10-04-ghi-giam-hang-tieu-huy.md) | Ghi giảm hàng tiêu hủy | [BJ-10](../journeys/BJ-10-tieu-huy-hang.md) · Tiêu hủy hàng | BC-IO-11 | `SCR-041` |
| 44 | [UC-11-01](UC-11-01-xac-dinh-duong-xu-ly.md) | Xác định đường xử lý | [BJ-11](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) · Hủy và sửa sai nghiệp vụ kho | BC-IC-07, BC-IO-16 | `SCR-048`, `SCR-049`, `SCR-050` |
| 45 | [UC-11-02](UC-11-02-huy-operation-chua-thuc-thi.md) | Hủy operation chưa thực thi | [BJ-11](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) · Hủy và sửa sai nghiệp vụ kho | BC-IO-12 | `SCR-052`, `SCR-053` |
| 46 | [UC-11-03](UC-11-03-chuan-bi-phuong-an-correction.md) | Chuẩn bị phương án correction | [BJ-11](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) · Hủy và sửa sai nghiệp vụ kho | BC-IC-07, BC-IO-16 | `SCR-049`, `SCR-052` |
| 47 | [UC-11-04](UC-11-04-phe-duyet-correction.md) | Phê duyệt correction | [BJ-11](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) · Hủy và sửa sai nghiệp vụ kho | BC-IC-06 | `SCR-051`, `SCR-053` |
| 48 | [UC-11-05](UC-11-05-ghi-correction-chain.md) | Ghi correction chain | [BJ-11](../journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) · Hủy và sửa sai nghiệp vụ kho | BC-IO-13 | `SCR-049`, `SCR-053` |
| 49 | [UC-12-01](UC-12-01-nap-va-kiem-tra-batch-dau-ky.md) | Nạp và kiểm tra batch đầu kỳ | [BJ-12](../journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) · Khởi tạo số dư tồn kho đầu kỳ | BC-IC-09 | `SCR-066`, `SCR-067`, `SCR-068` |
| 50 | [UC-12-02](UC-12-02-ra-soat-va-duyet-batch.md) | Rà soát và duyệt batch | [BJ-12](../journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) · Khởi tạo số dư tồn kho đầu kỳ | BC-IC-06 | `SCR-069`, `SCR-070` |
| 51 | [UC-12-03](UC-12-03-commit-va-kich-hoat-ton-kho.md) | Commit và kích hoạt tồn kho | [BJ-12](../journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) · Khởi tạo số dư tồn kho đầu kỳ | BC-IC-04 | `SCR-070`, `SCR-071` |
| 52 | [UC-13-01](UC-13-01-xac-dinh-nguon-va-pham-vi.md) | Xác định nguồn và phạm vi | [BJ-13](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) · Ghi nhận chi phí mua đến muộn | BC-IV-04 | `SCR-014`, `SCR-015` |
| 53 | [UC-13-02](UC-13-02-tinh-va-phan-bo-chi-phi.md) | Tính và phân bổ chi phí | [BJ-13](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) · Ghi nhận chi phí mua đến muộn | BC-IV-04 | `SCR-018` |
| 54 | [UC-13-03](UC-13-03-xac-nhan-ghi-nhan-chi-phi.md) | Xác nhận ghi nhận chi phí | [BJ-13](../journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) · Ghi nhận chi phí mua đến muộn | BC-IV-04 | `SCR-017`, `SCR-019` |
| 55 | [UC-14-01](UC-14-01-xac-dinh-ky-pham-vi-va-chinh-sach.md) | Xác định kỳ, phạm vi và chính sách | [BJ-14](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) · Tính và công bố giá vốn | BC-IV-02 | `SCR-072`, `SCR-073` |
| 56 | [UC-14-02](UC-14-02-tinh-gia-von-va-phat-hien-blocker.md) | Tính giá vốn và phát hiện blocker | [BJ-14](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) · Tính và công bố giá vốn | BC-IV-02 | `SCR-074`, `SCR-075` |
| 57 | [UC-14-03](UC-14-03-ra-soat-ket-qua.md) | Rà soát kết quả | [BJ-14](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) · Tính và công bố giá vốn | BC-IV-03 | `SCR-074`, `SCR-075`, `SCR-076` |
| 58 | [UC-14-04](UC-14-04-cong-bo-gia-von.md) | Công bố giá vốn | [BJ-14](../journeys/BJ-14-tinh-va-cong-bo-gia-von.md) · Tính và công bố giá vốn | BC-IV-03 | `SCR-076`, `SCR-077` |
| 59 | [UC-15-01](UC-15-01-xac-dinh-bao-cao-va-pham-vi.md) | Xác định báo cáo và phạm vi | [BJ-15](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) · Tra cứu báo cáo tồn và thẻ kho | BC-IO-01 | `SCR-054` |
| 60 | [UC-15-02](UC-15-02-xem-bao-cao-ton-kho.md) | Xem báo cáo tồn kho | [BJ-15](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) · Tra cứu báo cáo tồn và thẻ kho | BC-IO-01 | `SCR-055` |
| 61 | [UC-15-03](UC-15-03-xem-the-kho-va-lich-su.md) | Xem thẻ kho và lịch sử | [BJ-15](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) · Tra cứu báo cáo tồn và thẻ kho | BC-IO-01 | `SCR-055`, `SCR-056`, `SCR-057` |
| 62 | [UC-15-04](UC-15-04-xuat-bao-cao.md) | Xuất báo cáo | [BJ-15](../journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) · Tra cứu báo cáo tồn và thẻ kho | BC-IO-01 | `SCR-058`, `SCR-059` |
| 63 | [UC-16-01](UC-16-01-mo-va-phan-loai-ho-so-doi-soat.md) | Mở và phân loại hồ sơ đối soát | [BJ-16](../journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) · Điều tra và đối soát sai lệch | BC-IC-05 | `SCR-078` |
| 64 | [UC-16-02](UC-16-02-bao-ve-pham-vi-rui-ro.md) | Bảo vệ phạm vi rủi ro | [BJ-16](../journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) · Điều tra và đối soát sai lệch | BC-IC-05 | `SCR-079`, `SCR-080` |
| 65 | [UC-16-03](UC-16-03-dieu-tra-va-xac-dinh-nguyen-nhan.md) | Điều tra và xác định nguyên nhân | [BJ-16](../journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) · Điều tra và đối soát sai lệch | BC-IC-05 | `SCR-079`, `SCR-080` |
| 66 | [UC-16-04](UC-16-04-xac-minh-va-cap-nhat-ket-qua-doi-soat.md) | Xác minh và cập nhật kết quả đối soát | [BJ-16](../journeys/BJ-16-ieu-tra-va-oi-soat-sai-lech.md) · Điều tra và đối soát sai lệch | BC-IC-05 | `SCR-082`, `SCR-083` |
| 67 | [UC-17-01](UC-17-01-thu-thap-va-danh-gia-bang-chung.md) | Thu thập và đánh giá bằng chứng | [BJ-17](../journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) · Phục hồi nghiệp vụ có kết quả chưa xác định | BC-IC-05 | `SCR-078`, `SCR-079` |
| 68 | [UC-17-02](UC-17-02-xac-lap-operation-da-hoan-tat.md) | Xác lập operation đã hoàn tất | [BJ-17](../journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) · Phục hồi nghiệp vụ có kết quả chưa xác định | BC-IC-05 | `SCR-080`, `SCR-082`, `SCR-083` |
| 69 | [UC-17-03](UC-17-03-tiep-tuc-cung-operation-identity.md) | Tiếp tục cùng operation identity | [BJ-17](../journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) · Phục hồi nghiệp vụ có kết quả chưa xác định | BC-IC-05 | `SCR-080`, `SCR-082`, `SCR-083` |
| 70 | [UC-17-04](UC-17-04-giu-chua-xac-dinh-va-escalated.md) | Giữ chưa xác định và escalated | [BJ-17](../journeys/BJ-17-phuc-hoi-nghiep-vu-co-ket-qua-chua-xac-inh.md) · Phục hồi nghiệp vụ có kết quả chưa xác định | BC-IC-05 | `SCR-079`, `SCR-083` |

# Quy tắc giao việc

BJ là work package; UC là lát nghiệm thu; không sao chép UC giữa các BJ.
