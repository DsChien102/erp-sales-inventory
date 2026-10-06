# Theme 09 — Review Start Here

## 1. Bức tranh đích trong một câu

Theme 09 biến **giao dịch đã được các Theme nghiệp vụ xác lập** thành **dấu vết kế toán có thể giải thích, khóa theo kỳ, lên sổ đúng chế độ và làm nền cho kê khai thuế**.

## 2. Sáu khối chức năng đích

| Khối | Người dùng hiểu đơn giản là | Theme 09 sở hữu |
|---|---|---|
| Thiết lập kế toán | Tôi đang áp dụng chế độ nào, từ khi nào? | Hồ sơ kế toán, phiên bản chế độ, chính sách ghi sổ |
| Tiếp nhận & ghi sổ | Giao dịch nào đã/ chưa được ghi nhận kế toán? | Ca ghi sổ, sự thật kế toán đã chụp, kết quả ghi sổ |
| Kỳ kế toán | Kỳ nào còn mở, kỳ nào đã khóa? | Kỳ kế toán, khóa/mở lại có audit |
| Sổ kế toán | Dữ liệu của tôi lên sổ nào và vì sao? | Bút toán/bản ghi kế toán, projection sổ, snapshot xuất sổ |
| Thuế | Số liệu nào hình thành nghĩa vụ và hồ sơ khai? | Hồ sơ thuế, kỳ thuế, phép tính và snapshot hồ sơ khai |
| Đối chiếu & điều chỉnh | Khi nguồn và sổ lệch nhau thì xử lý ra sao? | Ca đối chiếu, bút toán điều chỉnh/đảo có truy vết |

## 3. Quyết định kiến trúc nghiệp vụ quan trọng nhất

**Không đồng nhất “sự thật vận hành” với “bút toán”.** Theme 05/06/07/08/10 tiếp tục sở hữu giao dịch của mình. Theme 09 nhận một phiên bản sự thật đủ điều kiện, áp chính sách kế toán theo thời điểm hiệu lực rồi sinh cách ghi sổ phù hợp.

Điều này giúp cùng một nguồn dữ liệu có thể:
- lên sổ HKD theo Thông tư 152/2025/TT-BTC;
- về sau lên chế độ doanh nghiệp siêu nhỏ hoặc chế độ có hệ thống tài khoản;
- không phải sửa lịch sử giao dịch nguồn khi chính sách kế toán thay đổi.

## 4. Phase 1 được đề xuất

- Đối tượng ưu tiên: hộ/cá nhân kinh doanh thương mại tại Việt Nam.
- Tiền tệ ghi sổ: VND.
- Chế độ kế toán đầu tiên: Thông tư 152/2025/TT-BTC.
- Tự động nhận sự thật từ bán hàng, công nợ, kho/giá vốn, hóa đơn điện tử và mua hàng khi contract nguồn sẵn sàng.
- Ghi sổ, xem trạng thái chưa ghi/đã ghi/cần xử lý, khóa kỳ.
- Sinh các sổ áp dụng theo chế độ; **không mặc định một hộ phải dùng đồng thời cả 7 mẫu sổ**.
- Cho phép điều chỉnh thủ công có kiểm soát, nhưng không được dùng để sửa ngược số dư authoritative của Theme 6 hoặc giá vốn/tồn kho authoritative của Theme 7.
- Chuẩn bị số liệu và hồ sơ khai thuế có snapshot; nộp điện tử ra cơ quan thuế để Phase sau khi integration contract được chốt.

## 5. Mười điểm nên phản biện đầu tiên

1. Theme 09 nên kết thúc ở “ghi sổ + dữ liệu khai thuế”, hay sở hữu luôn toàn bộ vòng đời kê khai/nộp thuế?
2. Phase 1 chỉ phục vụ HKD/CKD theo TT152 hay phải đồng thời hỗ trợ doanh nghiệp siêu nhỏ theo TT58/2026?
3. Có cần expose khái niệm Nợ/Có cho người dùng phổ thông, hay chỉ hiển thị khi chế độ kế toán yêu cầu?
4. Có cho phép lập bút toán thủ công ngay Phase 1 không; nếu có, quyền và approval đến đâu?
5. Khi sự kiện nguồn đến muộn sau khi kỳ đã khóa, mặc định ghi kỳ hiện tại kèm ngày nghiệp vụ gốc hay bắt buộc mở lại kỳ?
6. Khi hóa đơn điện tử và đơn hàng không khớp, nguồn nào quyết định ghi nhận doanh thu và nguồn nào chỉ là bằng chứng thuế?
7. Tax filing có cần submission trực tiếp ngay Phase 1 không?
8. Có cần “khóa mềm” trước “khóa kỳ” hay chỉ cần Mở/Đã khóa?
9. Mức độ chi tiết dimension cần ngay từ đầu: cửa hàng, kênh, sản phẩm, đối tác, kho, nhân viên?
10. Báo cáo quản trị nào là output của Theme 09, báo cáo nào phải bàn giao cho Theme Dashboard/Báo cáo?
