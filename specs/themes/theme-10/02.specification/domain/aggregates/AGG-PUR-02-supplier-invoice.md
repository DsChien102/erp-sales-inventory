# AGG-PUR-02 — Hóa đơn nhà cung cấp (`SupplierInvoice`)

**Status:** `PROPOSED_UNFROZEN`

## Mục đích

Quản lý vòng đời thương mại của hóa đơn NCC từ tiếp nhận tới mốc đủ điều kiện tạo nguồn nghĩa vụ, đồng thời giữ liên hệ có nguồn với Đơn mua/lần nhận khi có.

## Root và thành phần

- `SupplierInvoice` — logical invoice identity trong tenant.
- `SupplierInvoiceVersion` — dữ liệu chứng từ tại một version.
- `SupplierInvoiceLine` — product/service line, quantity/UOM/amount/tax-related fields ở mức semantic.
- `InvoiceSourceLink` — link tới order line và/hoặc receipt line; optional.
- `InvoiceQualification` — kết quả kiểm tra nghiệp vụ và reason.
- `PayableSourceReference` — record rằng source version nào đã được bàn giao/acknowledge.

## Lifecycle đề xuất

`Tiếp nhận → Đang kiểm tra → Đủ điều kiện | Chờ làm rõ | Từ chối`.

Version/correction/cancellation sau đó phải có history riêng; chi tiết finality chưa khóa.

## Invariant

1. Một invoice root thuộc đúng một NCC.
2. File attachment chỉ là evidence; không đồng nghĩa invoice qualified.
3. Invoice không bắt buộc có PO/receipt ngay khi intake.
4. Mỗi source version đủ điều kiện chỉ được tạo một logical payable source; retry không tạo source mới.
5. Mua hàng không lưu/điều chỉnh PayableBalance như source truth.
6. Nếu invoice link tới receipt/order, link phải chỉ rõ source identity/version đủ reconcile.

## Blocker

- Q-05: tiêu chí canonical cho “đủ điều kiện”.
- Q-09: service invoice/prepayment.
- Q-10: permission.
