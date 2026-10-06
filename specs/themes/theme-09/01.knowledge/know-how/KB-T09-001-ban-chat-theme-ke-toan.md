# KB-T09-001 — Bản chất Theme Kế toán

## Trả lời ngắn
Theme 09 không phải nơi “nhập lại” nghiệp vụ. Nó nhận các sự thật đã được Theme vận hành xác lập, diễn giải chúng theo chính sách kế toán có hiệu lực, rồi tạo dấu vết kế toán và dữ liệu tuân thủ có thể truy ngược.

## Vì sao quan trọng
Nếu Theme 09 tự quản lý lại đơn hàng, công nợ hoặc tồn kho, VET45 sẽ có hai nguồn sự thật. Khi hai bên lệch nhau, không còn biết số nào đúng.

## Quy tắc vận hành
1. Source Theme xác lập business fact.
2. Theme 09 chụp tối thiểu dữ liệu cần cho accounting/audit.
3. Policy version quyết định cách ghi sổ.
4. Entry đã post là immutable.
5. Sổ và tax projection sinh từ canonical accounting data.

## Ví dụ
Đơn `SO-00042` hoàn tất. Theme 5 xác lập doanh số; Theme 6 xác lập phần còn phải thu/đã thu; Theme 7 xác lập giá vốn; Theme 8 có thể phát hành hóa đơn. Theme 09 không “chọn một bản thay thế tất cả”, mà nhận từng fact đúng owner/purpose để tạo accounting result.

## Sai thường gặp
- Dùng invoice làm source duy nhất của revenue.
- Cho kế toán sửa số dư công nợ để “khớp sổ”.
- Cho entry kế toán sửa official cost.

## Nguồn
`DEC-T09-002..007`, `scope-baseline.md`.
