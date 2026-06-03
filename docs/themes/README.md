# Catalog theme sản phẩm (TH-01 .. TH-11)

Đơn vị **deliver** của sản phẩm Vet45 là **theme**, không phải module. Mỗi theme có thể gồm nhiều bounded context / package trong `modules/`.

Khung viết theme mới: [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md)

## Bảng theme

| Mã | Tên | Mô tả ngắn | Folder doc | Trạng thái |
| -- | --- | ---------- | ---------- | ---------- |
| **TH-01** | Thiết lập cửa hàng | Tenant, user, role, phân quyền, cấu hình ban đầu | — | planned |
| **TH-02** | Sản phẩm & giá bán | Sản phẩm, SKU, ĐVT, barcode, giá | — | planned |
| **TH-03** | Khách hàng & NCC | Khách hàng, nhà cung cấp, định danh | — | planned |
| **TH-04** | Bán hàng & đơn hàng | Đơn, nháp, thanh toán, tra cứu | — | planned |
| **TH-05** | Công nợ | Phải thu/phải trả, thanh toán, cấn trừ | [TH-05-receivables-payables/](TH-05-receivables-payables/) | planned |
| **TH-06** | Kho & giá vốn | Tồn kho, nhập/xuất, kiểm kê, giá vốn | [TH-06-inventory-and-costing/](TH-06-inventory-and-costing/) | planned |
| **TH-07** | Hóa đơn điện tử | Lập, phát hành, điều chỉnh, đối soát | [TH-07-e-invoice/](TH-07-e-invoice/) | planned |
| **TH-08** | Ghi sổ & kê khai thuế | Sổ HKD, tờ khai, nghĩa vụ thuế | [TH-08-accounting-and-tax/](TH-08-accounting-and-tax/) | planned |
| **TH-09** | Dashboard & báo cáo | KPI, biểu đồ, báo cáo quản trị | [TH-09-dashboard-and-reporting/](TH-09-dashboard-and-reporting/) | planned |
| **TH-10** | Cảnh báo & rủi ro | Cảnh báo dữ liệu, vận hành, tuân thủ | [TH-10-alerts-and-risk/](TH-10-alerts-and-risk/) | planned |
| **TH-11** | Tích hợp | Add-ons, đồng bộ dữ liệu | [TH-11-integration/](TH-11-integration/) | planned |

**Trạng thái:** `planned` | `in_progress` | `mvp` | `done`

Dự án đang ở **greenfield baseline** — module packages là skeleton rỗng; viết theme doc khi bắt đầu deliver từng TH-xx.

## Thêm theme mới (TH-12+)

1. Copy folder mẫu từ `THEME_DOCUMENTATION_TEMPLATE.md`
2. Thêm dòng vào bảng trên

## Theme ≠ Module

```text
TH-04 (Bán hàng)  →  sales (owner) + catalog + partner + inventory + iam (supporting)
TH-02 (Sản phẩm)  →  catalog (owner) + inventory + costing + iam
```
