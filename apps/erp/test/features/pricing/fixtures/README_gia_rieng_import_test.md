# File mẫu test Import giá riêng

**File:** [`gia_rieng_import_test_mixed.xlsx`](./gia_rieng_import_test_mixed.xlsx)

Sheets: `customer_price_rules` + `instructions` (đúng template V1).

## Cột bắt buộc (đúng thứ tự)

| Cột | Ý nghĩa |
| --- | --- |
| `rule_id` | Trống = tạo mới |
| `customer_id` | Mã KH seed: `KH000123`, `KH000456`, `KH000789`, `KH000321` |
| `product_reference_id` | Seed: `product-1`, `product-2`, `product-3` |
| `rule_price` | Giá VND (số ≥ 0) |
| `effective_from` | `YYYY-MM-DD` (trống → cảnh báo default) |
| `effective_to` | `YYYY-MM-DD` hoặc trống |
| `note` | Ghi chú |

## Các dòng dữ liệu

| Dòng | Kỳ vọng | Mô tả |
| ---: | --- | --- |
| 2 | Hợp lệ | KH000123 × product-1 = 180.000 |
| 3 | Hợp lệ | KH000456 × product-2 = 95.000, có đến ngày |
| 4 | Cảnh báo | Thiếu `effective_from` |
| 5 | Lỗi | Giá âm (-5000) |
| 6 | Lỗi | Giá không phải số (`abc`) |
| 7 | Lỗi | Thiếu `customer_id` |
| 8 | Lỗi | Thiếu `product_reference_id` |
| 9 | Lỗi | KH/SP không tồn tại |
| 10 | Cảnh báo/chặn | Giá 50.000 dưới sàn product-2 |
| 11 | Hợp lệ | KH000321 × product-3 = 75.000 |

## Cách dùng trên app

1. More → Giá riêng / Nhớ giá → FAB → Nhập từ Excel  
2. Chọn file `gia_rieng_import_test_mixed.xlsx`  
3. Quan sát bước 1→2→3→4

### Lưu ý InMemory hiện tại

`InMemoryPricingModule` **chưa parse nội dung Excel** — preview bước 2 đang trả seed cố định. File vẫn đúng format contract để test UX chọn file và dùng lại khi gắn BE import thật.

Tái tạo file:

```bash
cd modules/pricing/infrastructure
dart run tool/generate_import_test_xlsx.dart
```
