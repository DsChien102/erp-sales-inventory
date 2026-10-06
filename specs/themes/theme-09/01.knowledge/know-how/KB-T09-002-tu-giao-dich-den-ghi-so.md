# KB-T09-002 — Từ giao dịch đến ghi sổ

## Trả lời ngắn
Một source event không đồng nghĩa đã ghi sổ. Nó phải trở thành `AccountingCase`, qua validation về source finality, kỳ và policy rồi mới tạo `AccountingEntry`.

## Tuyến xử lý
```text
Source final → Receive → Canonical fact → Validate → Select policy → Post → Project
```

## Kết quả nghiệp vụ
- `POSTED`: đã commit entry.
- `REJECTED`: source/rule không hợp lệ.
- `PERIOD_LOCKED`: kỳ ngăn posting.
- `RECONCILIATION_NEEDED`: chưa thể xác lập an toàn.

## Vì sao tách business result khỏi delivery
Event có thể gửi thành công nhưng posting bị reject; hoặc network timeout nhưng posting thực tế đã thành công. Vì vậy “đã gửi event” không được hiển thị thành “đã ghi sổ”.

## Ghi nhớ
Retry kỹ thuật chỉ xử lý delivery; business rejection cần sửa nguyên nhân nghiệp vụ.
