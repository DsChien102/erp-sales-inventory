# Checklist cut-over và chuyển giao — Theme 7 v4.1.0

## 1. Internal package cut-over — hoàn tất

| Gate | Kết quả |
|---|---|
| Baseline v4.0.0 và decision freeze bất biến | `PASSED` |
| 25/25 source BJ có đúng một disposition | `PASSED` |
| 17 BJ / 70 UC canonical đã materialize và re-ID nguyên tử | `PASSED` |
| CAP-01 / PROC-01 / 5 XREF được phân loại | `PASSED` |
| SRS, wiki, UI, prototype, Harness và trace consumers đã rewrite | `PASSED` |
| Package/link/checksum/static Harness validators | `PASSED` |

Trạng thái: `INTERNAL_CUTOVER_COMPLETED`. Package freeze: `T7-PACKAGE-FREEZE-v4.1.0`.

## 2. Outbound receiver transfer — tạm hoãn theo quyết định owner

| Gate | Receiver | Trạng thái |
|---|---|---|
| RECEIVER-T5-POS | Theme 5 — Sales/POS nhận Checkout Journey | `DEFERRED_BY_OWNER_DECISION` |
| RECEIVER-T10-PURCHASE | Theme 10 — Mua hàng nhận Discount Scenario | `DEFERRED_BY_OWNER_DECISION` |
| RECEIVER-T2-PRODUCT | Theme 2 — Sản phẩm nhận Pricing Basis/Review/Publication requirement | `DEFERRED_BY_OWNER_DECISION` |
| RECEIVER-T2-D17 | Theme 2 đóng băng heuristic MAX và override reason | `NOT_EFFECTIVE_PENDING_THEME_2_ADOPTION` |
| RECEIVER-REPORTING | Reporting/Analytics nhận Profit Views | `DEFERRED_BY_OWNER_DECISION` |

Trong thời gian chờ, toàn bộ hồ sơ nằm tại `outbound/` của Theme 7 với trạng thái `TEMPORARY_NON_CANONICAL`; không được tính vào scope canonical hoặc tự động kích hoạt ở theme nhận.

## 3. Chuỗi chuyển giao về sau

1. Receiver xác nhận destination và quyền re-ID.
2. Theme 2 quyết định/đóng băng D17 tại authority của mình.
3. Receiver import artifact, cập nhật trace/checksum và chạy validator tại repository đích.
4. Chỉ sau receiver acceptance mới xóa/chuyển bản tạm khỏi Theme 7 bằng một release kế nhiệm.
