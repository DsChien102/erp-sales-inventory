# TH-02 — Domain model (v3)

> Bounded context: **catalog** (`modules/catalog/`). Schema Postgres: `catalog`.
> Entity tóm tắt / yêu cầu xuyên suốt: [OVERVIEWS.md](../OVERVIEWS.md).
> ERD chi tiết: [APPENDICES.md](../APPENDICES.md) (Phụ lục E).
> Analyze: [ddd-domain-modeling](../../../../.cursor/skills/ddd-domain-modeling/SKILL.md) · Implement: [domain-layer](../../../../.cursor/skills/domain-layer/SKILL.md)

## Entity tree (conceptual)

**Nhóm thông tin / Trường thông tin** = `CustomFieldGroup` / `CustomField` (thông tin bổ sung — không hard-code ngành vào Product).

```text
Product
├─ Product Image
├─ Product Unit
│  └─ Product Unit Price Band
├─ Product Stock Profile
├─ Product Base Price Profile
├─ Product Custom Field Value
├─ Product Readiness
└─ Product Change History

Custom Field Group          ← Nhóm thông tin
└─ Custom Field             ← Trường thông tin
   └─ Product Custom Field Value

Store Price Rule
└─ Product Unit Price Band (suggest/apply)
```

```mermaid
erDiagram
    PRODUCTS ||--o{ PRODUCT_IMAGES : has
    PRODUCTS ||--o{ PRODUCT_UNITS : has
    PRODUCTS ||--|| PRODUCT_STOCK_PROFILES : has
    PRODUCTS ||--|| PRODUCT_BASE_PRICE_PROFILES : has
    PRODUCTS ||--|| PRODUCT_READINESS : has
    PRODUCTS ||--o{ PRODUCT_CUSTOM_FIELD_VALUES : has
    PRODUCTS ||--o{ PRODUCT_CHANGE_HISTORY : has
    PRODUCT_UNITS ||--o{ PRODUCT_UNIT_PRICE_BANDS : has
    STORE_PRICE_RULES ||--o{ PRODUCT_UNIT_PRICE_BANDS : applies
    CUSTOM_FIELD_GROUPS ||--o{ CUSTOM_FIELDS : contains
    CUSTOM_FIELDS ||--o{ PRODUCT_CUSTOM_FIELD_VALUES : defines
```

## Aggregates (target)

| Aggregate | Folder | Ghi chú |
| --------- | ------ | ------- |
| `Product` | `domain/lib/src/product/` | Hồ sơ nhận diện, trạng thái KD, soft delete |
| `ProductUnit` | `domain/lib/src/unit/` | Đơn vị cơ sở + quy đổi (có thể child của Product tùy slice) |
| `ProductStockProfile` | `domain/lib/src/stock/` | Basic vs Advanced stock mode |
| `ProductBasePriceProfile` | `domain/lib/src/pricing/` | Manual vs Costing-module base price |
| `StorePriceRule` | `domain/lib/src/pricing/` | Quy tắc giá cấp cửa hàng/tenant (1/tenant) |
| `ProductUnitPriceBand` | `domain/lib/src/pricing/` | Giá niêm yết + Giá sàn theo UOM |
| `CustomFieldGroup` / `CustomField` | `domain/lib/src/custom_fields/` | Nhóm & trường thông tin bổ sung (tenant-configurable) |
| `ProductReadiness` | `domain/lib/src/readiness/` | Trạng thái + blocker (computed hoặc cached) |

**Không** gộp Change History vào aggregate root — projection/table riêng.

## Value objects

| VO | Mô tả |
| -- | ----- |
| `ProductName` | Tên sản phẩm (bắt buộc); tên thương mại optional |
| `ProductReferenceId` | Mã sản phẩm nội bộ (bắt buộc); unique per tenant (case-sensitive); immutable sau create. Dual mode: hash tự động (guided create) hoặc explicit legacy (`SP-0001`, import). **Không hiển thị UI** |
| `Sku` / `Barcode` | Optional; unique per tenant nếu có |
| `ProductBusinessStatus` | VO closed set: `active` \| `inactive` \| `soft_deleted` (soft delete ghi đè status; nguồn sự thật lifecycle) |
| `ReadinessStatus` | Chưa hoàn thiện, Sẵn sàng bán, Sẵn sàng nhập, … |
| `ReadinessBlocker` | Nhóm + mã blocker (thiếu UOM, thiếu giá, field required, …) |
| `UnitOfMeasure` | Tên đơn vị; vai trò base / conversion |
| `ConversionRate` | > 0; quy về base |
| `StockMode` | `basic` \| `advanced` |
| `StockQuantity` | Non-negative integer theo base unit (Foundation; không lưu thập phân) |
| `BasePriceMode` | `manual` \| `costing_module` |
| `BasePrice` | Giá cơ sở định giá (manual) |
| `ListPrice` / `FloorPrice` | Khung giá bán |
| `PriceRatio` | Tỷ lệ gợi ý từ Store Price Rule |
| `CustomFieldValue` | Typed value theo định nghĩa Trường thông tin |
| Field attrs | `required`, `searchable`, `filterable`, `display_on_list`, `sort_order` (group + field) |

## Commands (by epic)

| Command | Epic/US | Ghi chú |
| ------- | ------- | ------- |
| `CreateProductCommand` | EPIC-02/US-01 | Guided minimal create |
| `CheckDuplicateProductCodeQuery` | EPIC-02/US-01 | SKU/barcode tenant-scoped |
| `SetProductBaseUnitCommand` | EPIC-02/US-01, EPIC-04/US-01 | Đơn vị cơ sở |
| `SetBasicStockQuantityBaseCommand` | EPIC-02/US-02, EPIC-05/US-02 | Basic stock ban đầu |
| `SetManualBasePriceCommand` | EPIC-02/US-02, EPIC-06/US-01 | Giá cơ sở thủ công |
| `SetInitialPriceBandCommand` | EPIC-02/US-02, EPIC-06/US-03 | Khung giá ban đầu (optional step) |
| `GetProductReadinessQuery` | EPIC-02/US-03 | Checklist + suggested actions + refresh |
| `SearchProductsQuery` | EPIC-01/US-01 | + readiness filter; sau EPIC-03/US-03: searchable fields |
| `GetProductControlCenterQuery` | EPIC-01/US-02 | Detail + cards + readinessSummary + actions; checklist chi tiết **pending** (FR-04) |
| `GetProductChangeHistoryQuery` | EPIC-01/US-02, EPIC-07/US-04 | Lịch sử thay đổi |
| `AddProductUnitCommand` | EPIC-04/US-02 | Đơn vị quy đổi |
| `DeactivateProductUnitCommand` | EPIC-04/US-02 | |
| `ReactivateProductUnitCommand` | EPIC-04/US-02 | |
| `SetProductUnitRolesCommand` | EPIC-04/US-02/FR-02 | **pending** — vai trò bán/nhập/hiển thị |
| `ChangeBaseUnitCommand` | EPIC-04/US-03 | **out_of_scope** — không implement |
| `AdjustBasicStockCommand` | EPIC-05/US-02 | Không tạo phiếu kho |
| `SetStockModeCommand` | EPIC-05/US-01, US-04 | Basic → Advanced; US-04 **pending** |
| `SetStorePriceRuleCommand` | EPIC-06/US-02 | Store-level rule |
| `SetProductUnitPriceBandCommand` | EPIC-06/US-03 | List + floor per UOM |
| `UpdateProductProfileCommand` | EPIC-07/US-01 | Nhận diện, không đổi mode |
| `UpdateProductImagesCommand` | EPIC-07/US-01 | |
| `DeactivateProductCommand` | EPIC-07/US-02 | |
| `ReactivateProductCommand` | EPIC-07/US-02 | |
| `DeleteProductCommand` | EPIC-07/US-03 | Soft delete |
| `RestoreProductCommand` | EPIC-07/US-03 | Khôi phục |
| `InitializeCustomFieldTemplateCommand` | EPIC-03/US-01/FR-01 | Template từ onboarding (không khóa ngành) |
| `UpsertCustomFieldGroupCommand` | EPIC-03/US-01/FR-02 | Tạo/sửa/tạm tắt nhóm |
| `ReorderCustomFieldGroupsCommand` | EPIC-03/US-01/FR-03 | `group.sort_order` |
| `UpsertCustomFieldCommand` | EPIC-03/US-01/FR-04 | Tạo/sửa/tạm tắt trường |
| `ConfigureCustomFieldAttributesCommand` | EPIC-03/US-01/FR-05 | required, searchable, filterable, display_on_list |
| `ReorderCustomFieldsCommand` | EPIC-03/US-01/FR-06 | `field.sort_order` trong nhóm |
| `UpsertCustomFieldValuesCommand` | EPIC-03/US-02 | Giá trị theo sản phẩm |

## Domain events

| Event | Khi |
| ----- | --- |
| `ProductCreated` | Sau guided create |
| `ProductReadinessChanged` | Blocker resolved/added |
| `ProductProfileUpdated` | Sửa hồ sơ |
| `ProductStockAdjusted` | Basic stock adjust |
| `ProductBaseUnitChanged` | Đổi đơn vị cơ sở (**out_of_scope** cho đến khi US-03 mở lại) |
| `ProductPriceBandChanged` | Khung giá thay đổi |
| `ProductDeactivated` / `ProductReactivated` | Trạng thái KD |
| `ProductDeleted` / `ProductRestored` | Soft delete / restore |
| `StorePriceRuleChanged` | Cấp cửa hàng |
| `CustomFieldConfigChanged` | Cấu hình nhóm/trường/attrs/sort |
| `CustomFieldValuesUpdated` | Giá trị trên sản phẩm |

## Integration events — publish

| Type | Khi |
| ---- | --- |
| `catalog.product.created` | CreateProduct |
| `catalog.product.readiness_changed` | Readiness update |
| `catalog.product.profile_updated` | Update profile |
| `catalog.product.stock_adjusted` | Adjust basic stock |
| `catalog.product.unit_changed` | UOM mutations |
| `catalog.product.price_band_changed` | Price band |
| `catalog.pricing.store_rule_changed` | Store price rule |
| `catalog.product.deactivated` / `reactivated` / `deleted` | Lifecycle |
| `catalog.custom_field.config_changed` | Config nhóm/trường |

## Integration events — consume

| Source | Event | Mục đích |
| ------ | ----- | -------- |
| onboarding | `onboarding.tenant.configured` | Seed template nhóm & trường (EPIC-03/US-01) |
| costing | `costing.base_cost.updated` | Read model Costing-module base price (Growth; **pending** module) |
| inventory | `inventory.stock.summary_updated` | Read model Advanced stock (Growth; **pending** module) |

## Data rules (v3 highlights)

| Rule ID | Rule |
| ------- | ---- |
| DR-01 | Tên sản phẩm bắt buộc; guided create không ép toàn bộ field |
| DR-02 | SKU/barcode optional; unique per tenant |
| DR-02b | `ProductReferenceId` bắt buộc; unique per tenant (case-sensitive, exact match); immutable sau create. **Không expose UI** — chỉ dùng import/tracking DB. Guided create: hash tự động. Import: explicit legacy (`SP-0001`) qua `CreateProductCommand.referenceId?` |
| DR-03 | Readiness tách khỏi trạng thái kinh doanh |
| DR-04 | Basic stock theo base unit; không tạo phiếu nhập |
| DR-05 | Advanced stock: read-only trong Product |
| DR-06 | Manual base price (Foundation); costing read (Growth) |
| DR-07 | Giá sàn ≤ Giá niêm yết |
| DR-08 | Thông tin bổ sung qua nhóm & trường — không hard-code ngành vào Product |
| DR-09 | Soft delete; bảo toàn snapshot giao dịch |
| DR-10 | Đổi base unit: **out_of_scope** (khi mở lại: preview; không sửa snapshot cũ) |
| DR-11 | Field `required` trong nhóm active tham gia validation + readiness blocker |
| DR-12 | Tạm tắt nhóm/trường **không xóa** giá trị đã nhập |

## Anti-patterns

- God aggregate gộp readiness history + change history vào `Product`
- Hard-code thông tin thú y / ngành vào `Product` entity
- Chỉnh tồn trực tiếp khi `StockMode = advanced`
- Tính giá cuối sau khuyến mãi trong catalog
- Dup-check SKU/barcode chỉ ở UI
- Hiển thị `ACTIVE` / `READY_TO_SELL` cho end user
- Implement FR/US `pending` hoặc `out_of_scope`

## Implement

Code domain: [domain-layer skill](../../../../.cursor/skills/domain-layer/SKILL.md) → `modules/catalog/domain/lib/src/`.

Commands/handlers: [application-layer](../../../../.cursor/skills/application-layer/SKILL.md).

**Lưu ý:** EPIC-02/US-01 CONTRACT + BE done — `Product.create`, readiness seed, handlers, gateways, draft SQL `catalog_guided_create.sql`, IAM-style codegen. FE/E2E còn lại.
