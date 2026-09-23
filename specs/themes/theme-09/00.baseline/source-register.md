# Source Register — Theme 09

## 1. Thứ tự thẩm quyền

1. Xác nhận trực tiếp mới nhất của Product/Business Owner.
2. Decision Register đã freeze của Theme sở hữu dữ liệu nguồn.
3. Specification/Architecture đã freeze của Theme nguồn.
4. Product Vision và tài liệu định hướng.
5. Prototype/implementation chỉ là bằng chứng dẫn xuất.
6. Pháp luật là authority cho yêu cầu tuân thủ, không tự quyết ownership sản phẩm VET45.

## 2. Nguồn

| ID | Nguồn | Vai trò | Authority | Giới hạn |
|---|---|---|---|---|
| S01 | Yêu cầu trực tiếp ngày 2026-09-23 | Khởi tạo baseline Theme 09 theo cấu trúc Theme 6/7; cho phép tự đề xuất nhưng chưa freeze | Cao nhất cho lượt này | Chưa phê duyệt từng quyết định chi tiết |
| S02 | `1. Product vision (1).docx` | Theme 09 lịch sử: “Ghi sổ kế toán, kê khai thuế”; định hướng HKD, sổ TT152, tính/kê khai thuế | Product direction | Có phần `Updating`, không dùng để freeze form/tax rule chi tiết |
| S03 | Theme 6 — Công nợ v2.1.x, các hand-off đã xác nhận | Theme 6 sở hữu phải thu/phải trả; Theme 09 giữ sổ kế toán/kỳ; contract ghi sổ liên Theme | Cross-theme authority | Payload/API chi tiết chưa khóa ở Theme 09 |
| S04 | Theme 7 — Kho & giá vốn, baseline/harness đã review | Theme 7 sở hữu tồn kho, valuation, official cost; Theme 09 tiêu thụ accounting effect | Cross-theme authority | Không copy ontology kho thành ownership Theme 09 |
| S05 | Theme 8 — Hóa đơn điện tử | Theme 8 sở hữu phát hành và hồ sơ hóa đơn; Theme 09 sử dụng hóa đơn đã phát hành/dữ liệu truy vết | Cross-theme authority | Hóa đơn không tự thay thế nguồn giao dịch thương mại |
| S06 | Theme 10 — Mua hàng hand-off 2026-09-23 | Mua hàng sở hữu điều khoản/chiết khấu mua; Theme 6 công nợ; Theme 7 giá vốn; Theme 09 ghi sổ | Cross-theme working baseline | Một số điểm handoff giữa 6/7/9 còn cần hòa giải |
| L01 | Thông tư 152/2025/TT-BTC, hiệu lực 01/01/2026 | Chế độ kế toán cho hộ/cá nhân kinh doanh | Legal | Chỉ áp cho đúng đối tượng pháp luật quy định |
| L02 | Thông tư 58/2026/TT-BTC, hiệu lực 01/07/2026 theo công bố Bộ Tài chính | Chế độ kế toán cho doanh nghiệp siêu nhỏ | Legal / future product input | Được xếp hướng mở rộng, chưa là Phase 1 |

## 3. Link pháp lý đã kiểm tra ở baseline này

- Bộ Tài chính — Hướng dẫn kế toán cho hộ và cá nhân kinh doanh từ năm 2026: https://mof.gov.vn/quan-ly-gia-1/thong-tin-thi-truong-gia-ca-1/huong-dan-ke-toan-cho-ho-va-ca-nhan-kinh-doanh-tu-nam-2026
- Cổng văn bản Chính phủ — Thông tư 152/2025/TT-BTC: https://vanban.chinhphu.vn/?docid=216533&pageid=27160
- Bộ Tài chính — Quy định mới về chế độ kế toán cho doanh nghiệp siêu nhỏ: https://mof.gov.vn/tin-tuc-tai-chinh/tin-chinh-sach-tai-chinh/quy-dinh-moi-ve-che-do-ke-toan-cho-doanh-nghiep-sieu-nho

## 4. Freeze note

Không có nguồn Theme 09 cũ đủ authority để chọn làm parent. `v0.1.0` vì vậy là greenfield canonical review baseline. Các source cross-theme chỉ khóa boundary mà không tự biến rule nội bộ Theme 09 thành quyết định đã chốt.
