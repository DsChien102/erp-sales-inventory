# Catalog theme sản phẩm (TH-01 .. TH-12)

Đơn vị **deliver** của sản phẩm Mosaic Retail là **theme**, không phải module. Mỗi theme có thể gồm nhiều bounded context / package trong `modules/`.

Khung viết theme mới: [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md)

## Bảng theme

| Mã | Tên | Mô tả ngắn | Folder doc | Trạng thái |
| -- | --- | ---------- | ---------- | ---------- |
| **TH-01** | Tổ chức & người dùng | Tenant, user, role, phân quyền | [TH-01-organization-users/](TH-01-organization-users/) | in_progress (IAM + harness scaffold) |
| **TH-02** | Sản phẩm & giá bán | Sản phẩm, SKU, ĐVT, barcode, giá | [TH-02-product-pricing/](TH-02-product-pricing/) | in_progress |
| **TH-03** | Khách hàng & NCC | Khách hàng, nhà cung cấp, lịch sử giao dịch | [TH-03-partner/](TH-03-partner/) | in_progress |
| **TH-04** | Chính sách giá & ưu đãi | Bảng giá, giá riêng/nhớ giá, khuyến mãi và kiểm soát áp dụng giá | [TH-04-pricing-promotions/](TH-04-pricing-promotions/) | in_progress (EP02) |
| **TH-05** | Đơn hàng | Lập đơn, checkout, thanh toán, tra cứu và xử lý sau bán | [TH-05-sales-orders/](TH-05-sales-orders/) | in_progress (harness bootstrap) |
| **TH-06** | Công nợ | Phải thu/phải trả, thanh toán, cấn trừ | [TH-06-receivables-payables/](TH-06-receivables-payables/) | planned |
| **TH-07** | Kho & giá vốn | Tồn kho, nhập/xuất, kiểm kê, giá vốn | [TH-07-inventory-and-costing/](TH-07-inventory-and-costing/) | planned |
| **TH-08** | Hóa đơn điện tử | Lập, phát hành, điều chỉnh, đối soát | [TH-08-e-invoice/](TH-08-e-invoice/) | planned |
| **TH-09** | Ghi sổ & kê khai thuế | Sổ HKD, tờ khai, nghĩa vụ thuế | — | planned |
| **TH-10** | Dashboard & báo cáo | KPI, biểu đồ, báo cáo quản trị | [TH-10-dashboard-and-reporting/](TH-10-dashboard-and-reporting/) | planned |
| **TH-11** | Cảnh báo & rủi ro | Cảnh báo dữ liệu, vận hành, tuân thủ | [TH-11-alerts-and-risk/](TH-11-alerts-and-risk/) | planned |
| **TH-12** | Tích hợp | Add-ons, đồng bộ dữ liệu | [TH-12-integration/](TH-12-integration/) | planned |

**Trạng thái:** `planned` | `in_progress` | `mvp` | `done`

## Thực trạng repo (2026-07-02)

| Theme | Code / harness | Ghi chú |
| ----- | -------------- | ------- |
| TH-01 | `modules/iam/` codegen + ERP auth shell | Epic/US + OVERVIEWS/APPENDICES + `harness/00..07` (Resend + App Link) — [TH-01 README](TH-01-organization-users/README.md) |
| TH-02 | README + `harness/00..07` + Epic/US/FR (2 epic, 7 US) | Harness scaffold; `catalog` module greenfield — xem [TH-02 README](TH-02-product-pricing/README.md) |
| TH-04 | Canonical spec + `harness/00..07` + 6 epic folders; EP02 có 10 US | Harness EP02; `pricing` module greenfield — xem [TH-04 README](TH-04-pricing-promotions/README.md) |
| TH-05 | Canonical + harness + Phase 1 Dart contracts (6 Epic / **34 US**) | `sales` domain/infra/presentation vẫn skeleton |
| TH-06–TH-12 | Chưa có theme package canonical | Module/context tương ứng planned hoặc skeleton |
| TH-03 | README + `harness/00..07` + Epic/US/FR | Epic-01/02 BE+FE done; Epic-03 E2E blocked (cross-module publish) |
| TH-09 | Chưa có folder | Tạo `TH-09-accounting-and-tax/` khi bắt đầu SRS |

Theme `in_progress` dùng **README + harness/ + Epic/US/FR** — xem [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md) và [TH-03-partner/](TH-03-partner/).

## Cấu trúc chuẩn

```text
docs/themes/TH-xx-{{slug}}/
├── README.md                    # Index theme (status, epic rollup)
├── OVERVIEWS.md                 # Purpose, scope, epic map (legacy: 01-business-scope.md)
├── APPENDICES.md                # optional — flows, ERD, permissions
├── harness/                     # Bắt buộc khi in_progress
├── Epic-{nn}-{slug}/
│   ├── README.md                # Epic overview (trước: 01-overview.md)
│   └── US-{nn}/
│       ├── README.md            # US overview
│       └── FR-{nn}.md
└── 02-module-map.md             # planned: ở root; in_progress: thường trong harness/02-module-map.md
```

## Thêm theme mới (TH-13+)

1. Copy folder mẫu từ [THEME_DOCUMENTATION_TEMPLATE.md](THEME_DOCUMENTATION_TEMPLATE.md)
2. Thêm dòng vào bảng trên
3. Chạy `./scripts/ci/guard_theme_structure.sh`

## Theme ≠ Module

```text
TH-04 (Giá bán) → pricing (owner) + catalog + partner + sales + iam (supporting)
TH-02 (Sản phẩm)  →  catalog (owner) + inventory + costing + iam
TH-03 (Đối tác)   →  partner (owner) + sales/inventory/accounting (event publishers)
TH-08 (HĐĐT)      →  einvoice (owner TBD) + sales/partner/catalog/accounting/iam
```
