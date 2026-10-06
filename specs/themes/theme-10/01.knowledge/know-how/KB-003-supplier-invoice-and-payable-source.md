# KB-003 — Khi nào hóa đơn NCC trở thành nguồn nghĩa vụ phải trả?

## Câu trả lời ngắn

Không phải lúc người dùng tải tệp lên. Baseline đề xuất một mốc nghiệp vụ rõ là **Hóa đơn đủ điều kiện**; chỉ mốc này mới được phép phát nguồn nghĩa vụ sang Công nợ.

## Vì sao cần tách “tiếp nhận” và “đủ điều kiện”

Một file có thể trùng, sai NCC, thiếu thông tin, đang tranh chấp hoặc đến trước hàng. Nếu upload đồng nghĩa phát sinh nghĩa vụ, hệ thống sẽ phải sửa ledger liên tục và có nguy cơ trả tiền cho chứng từ chưa được chấp nhận.

## Mô hình đề xuất

`Tiếp nhận → Đang kiểm tra/đối chiếu → Đủ điều kiện | Chờ làm rõ | Từ chối`

Hóa đơn có thể được liên kết với Đơn mua, lần nhận hoặc cả hai, nhưng baseline **không bắt buộc có Đơn mua**. Hóa đơn đến trước hàng được phép tồn tại ở trạng thái phù hợp thay vì ép tạo Đơn mua bù.

## Những gì chưa được tự quyết

- Kiểm tra pháp lý/thuế cuối cùng thuộc miền nào.
- Hóa đơn dịch vụ và trả trước có vào Phase đầu không.
- Role nào có quyền xác nhận đủ điều kiện.

Các điểm này giữ ở Q-05/Q-09/Q-10.

Nguồn: D-03, D-09, D-14, D-15.
