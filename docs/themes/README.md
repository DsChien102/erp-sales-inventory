# Catalog theme sản phẩm (TH-01 .. TH-11)

Đơn vị **deliver** của sản phẩm Vet45 là **theme**, không phải module. Mỗi theme có thể gồm nhiều bounded context / package trong `modules/`.

Khung viết theme mới: [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md)

## Bảng theme

| Mã | Tên | Mô tả ngắn | Folder doc | Trạng thái |
| -- | --- | ---------- | ---------- | ---------- |
| **TH-01** | Thiết lập cửa hàng | Tenant, user, role, phân quyền | [TH-01-store-setup/](TH-01-store-setup/) | in_progress (IAM interim) |
| **TH-02** | Sản phẩm & giá bán | Sản phẩm, SKU, ĐVT, barcode, giá | [TH-02-product-pricing/](TH-02-product-pricing/) | planned |
| **TH-03** | Khách hàng & NCC | Khách hàng, nhà cung cấp, lịch sử giao dịch | [TH-03-partner/](TH-03-partner/) | in_progress |
| **TH-04** | Bán hàng & đơn hàng | Đơn, nháp, thanh toán, tra cứu | [TH-04-sales-orders/](TH-04-sales-orders/) | planned |
| **TH-05** | Công nợ | Phải thu/phải trả, thanh toán, cấn trừ | [TH-05-receivables-payables/](TH-05-receivables-payables/) | planned |
| **TH-06** | Kho & giá vốn | Tồn kho, nhập/xuất, kiểm kê, giá vốn | [TH-06-inventory-and-costing/](TH-06-inventory-and-costing/) | planned |
| **TH-07** | Hóa đơn điện tử | Lập, phát hành, điều chỉnh, đối soát | [TH-07-e-invoice/](TH-07-e-invoice/) | planned |
| **TH-08** | Ghi sổ & kê khai thuế | Sổ HKD, tờ khai, nghĩa vụ thuế | — | planned |
| **TH-09** | Dashboard & báo cáo | KPI, biểu đồ, báo cáo quản trị | [TH-09-dashboard-and-reporting/](TH-09-dashboard-and-reporting/) | planned |
| **TH-10** | Cảnh báo & rủi ro | Cảnh báo dữ liệu, vận hành, tuân thủ | [TH-10-alerts-and-risk/](TH-10-alerts-and-risk/) | planned |
| **TH-11** | Tích hợp | Add-ons, đồng bộ dữ liệu | [TH-11-integration/](TH-11-integration/) | planned |

**Trạng thái:** `planned` | `in_progress` | `mvp` | `done`

## Thực trạng repo (2026-07-02)

| Theme | Code / harness | Ghi chú |
| ----- | -------------- | ------- |
| TH-01 | `modules/iam/` codegen + ERP auth shell | Chưa có Epic/US tree; xem [TH-01 README](TH-01-store-setup/README.md) |
| TH-02 | README + Epic/US/FR tree (2 epic, 7 US) | Skeleton doc; `catalog` module greenfield — xem [TH-02 README](TH-02-product-pricing/README.md) |
| TH-04–TH-07, TH-09–TH-11 | README + business-scope + module-map | Skeleton doc; module packages greenfield |
| TH-03 | README + `harness/00..07` + Epic/US/FR | Epic-01/02 BE+FE done; Epic-03 E2E blocked (cross-module publish) |
| TH-08 | Chưa có folder | Tạo `TH-08-accounting-and-tax/` khi bắt đầu SRS |

Theme `in_progress` dùng **README + harness/ + Epic/US/FR** — xem [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md) và [TH-03-partner/](TH-03-partner/).

## Cấu trúc chuẩn

```text
docs/themes/TH-xx-{{slug}}/
├── README.md                    # Index theme (status, epic rollup)
├── 01-business-scope.md
├── harness/                     # Bắt buộc khi in_progress
├── Epic-{nn}-{slug}/
│   ├── README.md                # Epic overview (trước: 01-overview.md)
│   └── US-{nn}/
│       ├── README.md            # US overview
│       └── FR-{nn}.md
└── 02-module-map.md             # planned: ở root; in_progress: thường trong harness/02-module-map.md
```

## Thêm theme mới (TH-12+)

1. Copy folder mẫu từ [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md)
2. Thêm dòng vào bảng trên
3. Chạy `./scripts/ci/guard_theme_structure.sh`

## Theme ≠ Module

```text
TH-04 (Bán hàng)  →  sales (owner) + catalog + partner + inventory + iam (supporting)
TH-02 (Sản phẩm)  →  catalog (owner) + inventory + costing + iam
TH-03 (Đối tác)   →  partner (owner) + sales/inventory/accounting (event publishers)
```
