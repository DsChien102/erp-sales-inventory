# TH-02 — Domain model

> Bounded context: **catalog** (`modules/catalog/`). Schema Postgres: `catalog`.
> Analyze: [ddd-domain-modeling](../../../../.cursor/skills/ddd-domain-modeling/SKILL.md) · Implement: [domain-layer](../../../../.cursor/skills/domain-layer/SKILL.md)

```mermaid
erDiagram
    PRODUCTS ||--o{ PRODUCT_IMAGES : has
    PRODUCTS ||--o{ PRODUCT_UNITS : has
    PRODUCTS ||--|| PRODUCT_STOCK : has
    PRODUCTS ||--o{ PRODUCT_STOCK_MOVEMENTS : has
    PRODUCTS ||--o{ PRODUCT_PRICES : has
    PRODUCTS ||--o{ PRODUCT_PRICE_HISTORY : has
    PRODUCTS ||--o{ CATALOG_AUDIT_LOGS : has
    STORE_PRICING_SETTINGS ||--|| TENANT : per_tenant

    PRODUCTS {
        uuid id PK "Required"
        uuid tenant_id "Required, external reference"
        string internal_name "Required"
        string commercial_name "Optional"
        string sku "Optional, unique per tenant if set"
        string barcode "Optional, unique per tenant if set"
        enum status "Required: ACTIVE|INACTIVE|DELETED, default ACTIVE"
        text description "Optional"
        text note "Optional"
        jsonb medical_info "Optional"
        uuid base_unit_id FK "Required"
        datetime status_changed_at "Optional"
        uuid status_changed_by "Optional"
        datetime deleted_at "Optional"
        uuid deleted_by "Optional"
        datetime created_at "Required"
        uuid created_by "Required"
        datetime updated_at "Optional"
        uuid updated_by "Optional"
        int version "Required, optimistic concurrency"
    }

    PRODUCT_IMAGES {
        uuid id PK "Required"
        uuid product_id FK "Required"
        string storage_path "Required"
        int sort_order "Required"
        boolean is_primary "Required"
        datetime created_at "Required"
    }

    PRODUCT_UNITS {
        uuid id PK "Required"
        uuid product_id FK "Required"
        string unit_name "Required"
        decimal conversion_rate_to_base "Required, > 0"
        uuid reference_unit_id FK "Optional"
        enum status "Required: ACTIVE|INACTIVE"
        datetime created_at "Required"
    }

    PRODUCT_STOCK {
        uuid product_id PK FK "Required"
        decimal quantity "Required, allows negative"
        datetime updated_at "Required"
    }

    PRODUCT_STOCK_MOVEMENTS {
        uuid id PK "Required"
        uuid product_id FK "Required"
        decimal quantity_before "Required"
        decimal quantity_after "Required"
        decimal delta "Required"
        string source "Required: create|adjust"
        uuid actor_id "Required"
        datetime created_at "Required"
    }

    STORE_PRICING_SETTINGS {
        uuid id PK "Required"
        uuid tenant_id "Required, unique"
        decimal list_price_ratio "Required, >= 0"
        decimal floor_price_ratio "Required, >= 0, <= list"
        datetime created_at "Required"
        uuid created_by "Required"
        datetime updated_at "Optional"
        uuid updated_by "Optional"
        int version "Required"
    }

    PRODUCT_PRICES {
        uuid id PK "Required"
        uuid product_id FK "Required"
        enum price_mode "Required: STORE|PRODUCT"
        uuid unit_id FK "Optional, null = base unit"
        decimal list_price "Optional, manual override"
        decimal floor_price "Optional, manual override"
        boolean use_auto_price "Required, default true for non-base units"
        datetime created_at "Required"
        datetime updated_at "Optional"
    }

    PRODUCT_PRICE_HISTORY {
        uuid id PK "Required"
        uuid product_id FK "Required"
        string change_type "Required"
        jsonb snapshot "Required"
        uuid actor_id "Required"
        datetime created_at "Required"
    }

    CATALOG_AUDIT_LOGS {
        uuid id PK "Required"
        uuid product_id FK "Optional"
        string action "Required"
        string field_name "Optional"
        text old_value "Optional"
        text new_value "Optional"
        uuid actor_id "Required"
        datetime created_at "Required"
    }
```

## Lifecycle

```text
[nháp form] → CreateProduct → ACTIVE
            → Update profile / images / stock
            → deactivate → reactivate
            → manage UOM (add / deactivate / reactivate / delete / change base)
            → soft delete (DELETED) nếu đủ điều kiện
```

Pricing (tenant + product):

```text
SetStorePricingSetting (1/tenant) → products dùng STORE mode inherit ratio
SetProductPriceMode (STORE|PRODUCT) → SetProductPrice / SetProductUnitPrice
```

## Aggregates

| Aggregate | Folder | Ghi chú |
| --------- | ------ | ------- |
| `Product` | `domain/lib/src/product/` | Hồ sơ SP, ảnh, đơn vị đo lường, tồn cơ bản, trạng thái kinh doanh. |
| `StorePricingSetting` | `domain/lib/src/pricing/` | Tỷ lệ Giá niêm yết / Giá sàn cấp cửa hàng — tối đa 1/tenant. |
| `ProductPrice` | `domain/lib/src/pricing/` | Cấp áp dụng giá (STORE/PRODUCT), giá theo SP và theo UOM; lịch sử qua projection/history table. |

## Database tables

| Table | Ghi chú |
| ----- | ------- |
| `products` | Bảng trung tâm hồ sơ sản phẩm. |
| `product_images` | Ảnh sản phẩm; có ảnh đại diện (`is_primary`). |
| `product_units` | Đơn vị cơ sở + đơn vị quy đổi; `conversion_rate_to_base` tính về base. |
| `product_stock` | Tồn kho cơ bản theo đơn vị cơ sở (1 row/product). |
| `product_stock_movements` | Biến động tồn cơ bản (create, adjust) — truy vết delta. |
| `store_pricing_settings` | Cấu hình tỷ lệ giá cấp cửa hàng (1/tenant). |
| `product_prices` | Giá theo SP/UOM; manual override hoặc auto từ ratio. |
| `product_price_history` | Lịch sử thay đổi giá (mode, giá SP, giá UOM). |
| `catalog_audit_logs` | Audit thay đổi hồ sơ, trạng thái, UOM, giá. |

## Value objects

| VO | Mô tả |
| -- | ----- |
| `ProductName` | `internalName` bắt buộc; `commercialName` optional. |
| `Sku` | Optional; không auto-generate; unique per tenant nếu có. |
| `Barcode` | Optional; unique per tenant nếu có. |
| `ProductStatus` | `active`, `inactive`, `deleted` (soft delete). |
| `UnitOfMeasure` | Tên đơn vị; base unit có `conversionRateToBase = 1`. |
| `ConversionRate` | Số dương > 0; tính tỷ lệ về base qua reference unit. |
| `StockQuantity` | Cho phép dương, 0, âm; luôn theo base unit. |
| `MedicalInfo` | Thành phần, chỉ định, chống chỉ định, cách dùng, nguồn gốc — optional. |
| `PriceMode` | `store`, `product` — cấp áp dụng giá. |
| `PriceRatio` | Tỷ lệ ≥ 0; floor ≤ list. |
| `ListPrice` / `FloorPrice` | Giá bán; có thể manual hoặc computed từ giá vốn cơ sở × ratio. |

## Commands

| Command | Epic/US | Ghi chú |
| ------- | ------- | ------- |
| `CreateProductCommand` | Epic-01/US-01 | Tạo hồ sơ + ảnh + tồn khởi tạo; default ACTIVE. |
| `UpdateProductProfileCommand` | Epic-01/US-03 | Cập nhật tên, SKU, barcode, medical, mô tả — không đổi status/UOM/ảnh/tồn/giá. |
| `UpdateProductImagesCommand` | Epic-01/US-03 | Thêm/xóa/đổi ảnh đại diện. |
| `AdjustBasicStockCommand` | Epic-01/US-03 | Chỉnh tồn cơ bản trực tiếp; ghi delta movement. |
| `DeactivateProductCommand` | Epic-01/US-04 | ACTIVE → INACTIVE; chặn nếu nghiệp vụ chưa hoàn tất. |
| `ReactivateProductCommand` | Epic-01/US-04 | INACTIVE → ACTIVE; cần tên + base unit hợp lệ. |
| `DeleteProductCommand` | Epic-01/US-04 | Soft delete → DELETED; stock=0 + chưa phát sinh nghiệp vụ. |
| `AddProductUnitCommand` | Epic-01/US-05 | Thêm đơn vị quy đổi. |
| `DeactivateProductUnitCommand` | Epic-01/US-05 | Ngừng sử dụng đơn vị. |
| `ReactivateProductUnitCommand` | Epic-01/US-05 | Sử dụng lại đơn vị đã ngừng. |
| `DeleteProductUnitCommand` | Epic-01/US-05 | Xóa đơn vị đủ điều kiện. |
| `ChangeBaseUnitCommand` | Epic-01/US-05 | Đổi đơn vị cơ sở; quy đổi tồn; tính lại rates. |
| `SetStorePricingSettingCommand` | Epic-02/US-01 | Thiết lập/cập nhật tỷ lệ giá cấp cửa hàng. |
| `UnsetStorePricingSettingCommand` | Epic-02/US-01 | Gỡ thiết lập tỷ lệ cấp cửa hàng. |
| `SetProductPriceModeCommand` | Epic-02/US-02 | Chọn STORE hoặc PRODUCT. |
| `SetProductPriceCommand` | Epic-02/US-02 | Giá niêm yết/sàn cấp sản phẩm (base unit). |
| `SetProductUnitPriceCommand` | Epic-02/US-02 | Giá manual theo UOM; hoặc reset về auto. |

## Queries

| Query | Epic/US | Ghi chú |
| ----- | ------- | ------- |
| `SearchProductsQuery` | Epic-01/US-02 | Keyword + filter status + stock status; paginated. |
| `GetProductDetailQuery` | Epic-01/US-02 | Chi tiết đầy đủ; ẩn DELETED. |
| `CheckDuplicateProductCodeQuery` | Epic-01/US-01, US-03 | Dup SKU/barcode tenant-scoped. |
| `GetStorePricingSettingQuery` | Epic-02/US-01 | Tỷ lệ giá cấp cửa hàng hiện hành. |
| `GetProductPriceQuery` | Epic-02/US-02 | Giá computed/current theo SP + UOM. |
| `GetProductPriceHistoryQuery` | Epic-02/US-02 | Lịch sử thay đổi giá SP. |

## Domain events

| Event | Khi |
| ----- | --- |
| `ProductCreated` | Sau khi tạo SP thành công. |
| `ProductProfileUpdated` | Sau khi cập nhật hồ sơ. |
| `ProductImagesUpdated` | Sau khi cập nhật ảnh. |
| `ProductStockAdjusted` | Sau khi chỉnh tồn cơ bản. |
| `ProductDeactivated` | Sau khi ngừng kinh doanh. |
| `ProductReactivated` | Sau khi kinh doanh lại. |
| `ProductDeleted` | Sau khi soft delete. |
| `ProductUnitAdded` | Sau khi thêm UOM. |
| `ProductBaseUnitChanged` | Sau khi đổi đơn vị cơ sở. |
| `StorePricingSettingChanged` | Sau khi set/unset tỷ lệ cấp cửa hàng. |
| `ProductPriceChanged` | Sau khi đổi mode/giá SP/UOM. |

## Integration events — publish

| Type | Khi |
| ---- | --- |
| `catalog.product.created` | CreateProduct |
| `catalog.product.profile_updated` | Update profile |
| `catalog.product.images_updated` | Update images |
| `catalog.product.stock_adjusted` | Adjust stock |
| `catalog.product.deactivated` | Deactivate |
| `catalog.product.reactivated` | Reactivate |
| `catalog.product.deleted` | Soft delete |
| `catalog.product.unit_changed` | UOM mutations |
| `catalog.pricing.store_setting_changed` | Set/unset store pricing |
| `catalog.product.price_changed` | Price mode/price changes |

## Integration events — consume

| Source | Event | Mục đích |
| ------ | ----- | -------- |
| costing (TH-06) | `costing.base_cost.updated` | Read reference cho tính giá — **không consume ở MVP slice đầu**; query cross-module read gateway khi cần hiển thị giá vốn. |

## Data rules

| Rule ID | Rule |
| ------- | ---- |
| DR-01 | Mỗi sản phẩm phải có `internal_name` và đơn vị đo lường cơ sở. |
| DR-02 | SKU và barcode optional; không auto-generate; unique per tenant nếu có. |
| DR-03 | Sản phẩm mới mặc định `active`. |
| DR-04 | Tồn khởi tạo default 0; cho phép âm; luôn theo base unit. |
| DR-05 | Chỉnh tồn cơ bản không tạo phiếu nhập/công nợ — thuộc TH-06. |
| DR-06 | `inactive` vẫn xem được; không chọn cho giao dịch mới. |
| DR-07 | Soft delete (`deleted`) chỉ khi stock=0 và chưa phát sinh nghiệp vụ. |
| DR-08 | Mỗi SP có đúng 1 base unit; base unit `conversion_rate_to_base = 1`. |
| DR-09 | Không trùng tên đơn vị trong cùng SP; không vòng lặp quy đổi. |
| DR-10 | Đổi base unit quy đổi tồn; không đổi snapshot giao dịch cũ. |
| DR-11 | Store pricing: 1 setting/tenant; floor ratio ≤ list ratio. |
| DR-12 | Product mới default price mode = STORE. |
| DR-13 | Giá theo UOM: auto = base price × conversion rate; manual override ưu tiên. |
| DR-14 | Thay đổi giá chỉ ảnh hưởng giao dịch mới; không sửa dòng đơn cũ. |
| DR-15 | Giá vốn hiện hành / cơ sở định giá do TH-06 cung cấp — catalog chỉ đọc. |

## Constraints & indexes

| Type | Target | Rule |
| ---- | ------ | ---- |
| Primary key | `products.id` | Khóa chính sản phẩm. |
| Unique | `products.tenant_id + sku` | WHERE sku IS NOT NULL. |
| Unique | `products.tenant_id + barcode` | WHERE barcode IS NOT NULL. |
| Unique | `store_pricing_settings.tenant_id` | 1 setting/tenant. |
| Unique | `product_units.product_id + unit_name` | Không trùng tên đơn vị/SP. |
| Foreign key | `product_units.product_id` | → `products.id`. |
| Foreign key | `product_stock.product_id` | → `products.id`. |
| Index | `products.tenant_id` | Lọc theo tenant. |
| Index | `products.internal_name` | Tìm kiếm. |
| Index | `products.status` | Lọc ACTIVE/INACTIVE. |
| Check | `products.status` | `active`, `inactive`, `deleted`. |
| Check | `store_pricing_settings` | `floor_price_ratio <= list_price_ratio`. |

## Anti-patterns

- God aggregate gộp pricing history và stock movements vào `Product` aggregate root.
- Query-time fan-out sang costing/inventory để tính giá vốn — dùng read gateway/DTO.
- Dup-check SKU/barcode chỉ ở UI — cần RPC tenant-scoped.
- Hard delete sản phẩm đã phát sinh nghiệp vụ.
- Tự tính lại giá niêm yết/sàn khi đổi base unit (US-05/FR-05 BR-07).
- Tạo phiếu nhập khi chỉnh tồn cơ bản từ hồ sơ SP.

## Implement

Code domain từ document này: [domain-layer skill](../../../../.cursor/skills/domain-layer/SKILL.md) → `modules/catalog/domain/lib/src/`. Commands/handlers: [application-layer](../../../../.cursor/skills/application-layer/SKILL.md).
