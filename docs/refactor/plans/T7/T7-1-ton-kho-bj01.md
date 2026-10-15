# T7-1 — Tồn kho & khả dụng (BJ-01 · UIF-01 · SCR-001, SCR-003)

> Theme: Theme 7 Inventory · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Tài liệu liên quan: `specs/themes/theme-07` — [UIF-01](../../../../specs/themes/theme-07/03.design/flows/UIF-01-BJ-01.md), [SCR-001](../../../../specs/themes/theme-07/03.design/screens/SCR-001.md), [SCR-003](../../../../specs/themes/theme-07/03.design/screens/SCR-003.md), UC-01-01…05, BC-IO-01, BC-IO-14, PRJ-01; prototype `03.design/prototype/html` v4.6.8 (`render001BJ01`, `render003BJ01`, fixture `bj01Products`).
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7. Inventory" (đợt 1); theo dõi tiến độ ở đó.

## 0. Cập nhật sau T7-0 … T7-0c (review 2026-10-15) — đọc trước, **ưu tiên hơn** các mục bên dưới khi mâu thuẫn

Plan này viết ngày 2026-10-13, trước khi T7-0 / T7-0b / T7-0c thêm hạ tầng dùng chung cho `features/inventory/`. Phiên thực hiện phải theo các điểm sau:

| # | Thay đổi | Lý do / chỗ có sẵn |
|---|---|---|
| U1 | **Home:** đặt lại `routePath: '/warehouse/stock'` cho mục `lookup_stock` trong `data/inventory_repository.dart` (hiện là `null` từ T7-0b). Mục 3 dòng "Không đụng `inventory_repository.dart`" **bỏ**. | Home chỉ mở route có thật (T7-0b) |
| U2 | **Key-value Row:** **không** tạo `inventory_key_value_row.dart`; dùng `ReceiptKeyValueRow(label:, value:, emphasized:)` ở `presentation/widgets/receipt_key_value_row.dart` (`emphasized: true` cho `Khả dụng`). Đổi tên widget thành tên chung để T7-0e làm bằng GitNexus `rename`. | Đã có từ T7-0b |
| U3 | **List Row:** vẫn tạo `presentation/widgets/inventory_list_row.dart` như mục 3. | Chưa có widget chung (các page đang dùng `_ProductResultRow`, `_ReceiptItemRow` riêng) |
| U4 | **Trạng thái:** `PERMISSION_DENIED` dùng `InventoryPermissionDenied`; `STALE` dùng `InventoryNoticeBanner(InventoryNotice.stale, description: 'Hãy làm mới trước khi sử dụng.', action: VButton(label: 'Làm mới', variant: VButtonVariant.secondary, …))` — **thêm** tham số tuỳ chọn `String? description` vào `InventoryNoticeBanner` (mặc định giữ câu hiện tại) vì câu STALE của BJ-01 khác BJ-02. SCR-003 STALE: `description: 'Dữ liệu đến ${queryAsOf}. Hãy làm mới trước khi sử dụng.'`. | `presentation/widgets/inventory_state_views.dart` (T7-0c) |
| U5 | **Kịch bản fixture:** theo mẫu `GoodsReceiptRepository`: `StockScenario scenario = StockScenario.normal;` là **field public đổi được** (không phải tham số constructor), mỗi phương thức gọi `_guard()` ném `AppException(AppErrorCode.noPermission)`; `stale` / `empty` đọc trong `getSnapshot` / `getProduct`. Đăng ký `StockRepository` là `registerLazySingleton` trong `core/di/injection.dart` (cạnh `GoodsReceiptRepository`); page lấy bằng `getIt<StockRepository>()`, cubit nhận qua constructor; test truyền repository mới và `getIt.reset()` ở `tearDown`. | Cùng cách T7-0, T7-0c |
| U6 | **Hạn dùng lô:** `StockLotItem` dùng `LotDate expiry` (`data/models/lot_date.dart`) thay cho `expiryDisplay` + `expiryPrecision`; hiển thị `expiry.format()`. Fixture: `DH2507` → `LotDate(year: 2026, month: 11, day: 30)`, `DH2509` → `LotDate(year: 2026, month: 9, day: 15)`, `TY2408` → `LotDate(year: 2026, month: 7, day: 31)`, `TY2511` → `LotDate(year: 2027, month: 11)`. | `LotDate` có từ T7-0b, đã giữ precision |
| U7 | **Định dạng số lượng:** dùng `formatQuantity` trong `logic/receipt_rules.dart` (không viết hàm mới). | Có từ T7-0b |
| U8 | **Kiểm tra:** `dart analyze lib/features/inventory test/features/inventory lib/core/router lib/core/di`; `flutter analyze` không dùng (sập do đường dẫn có dấu). Mốc trước khi làm: 71 test inventory xanh (commit `49967966e`). | — |

## 1. Mục tiêu

Làm xong BJ-01 phía Flutter, **chỉ đọc, dữ liệu mẫu sau lớp Repository** (cùng cách BJ-02/BJ-03 đang làm):

- **SCR-001 Tồn kho**: tìm theo tên / mã sản phẩm / mã vạch, 5 chip lọc (Tất cả · Hết hàng · Tồn thấp · Cận hạn · Hết hạn), danh sách một cột, 6 trạng thái.
- **SCR-003 Chi tiết tồn kho**: Khả dụng, tồn vật lý / đủ điều kiện / đã giữ, lý do chênh lệch, banner hết/tồn thấp, danh sách lô, 2 bottom sheet (Lô, Nguồn và thời điểm cập nhật), 4 trạng thái.
- Mở được từ Home Kho → Tra cứu → **Tồn kho** (hiện đang trỏ `/warehouse/stock` nhưng route chưa tồn tại → bấm vào không đi đâu).

**Ngoài phạm vi** (ghi để khỏi làm lan): RPC/schema Supabase; BJ-15 (thẻ kho, lịch sử); cấu hình ngưỡng/cận hạn (CAP-01); số "3 cần chú ý" động trên Home; SCR-004/005/060/061 (spec ghi "giữ để tương thích", không phải bước điều hướng).

## 2. Hiện trạng

| Thứ | Hiện trạng |
|---|---|
| Home | `InventoryRepository.getLookupUtilities()` có `lookup_stock` → `routePath: '/warehouse/stock'`; `WarehouseHomePage` đã `context.push(routePath)`. `app_router.dart` **chưa** có `/warehouse/stock*`. |
| Dữ liệu | Không có model/repo tồn. BJ-02 (`GoodsReceiptRepository._inMemoryReceipts`) và BJ-03 (`ValuationRepository._receipts`) đều là dữ liệu mẫu trong bộ nhớ. |
| Component | `vet45_design_system` **không có** `VListRow` / `VKeyValueRow` (spec gọi "DS v2 / List Row", "Key-value Row"). Code hiện tại tự dựng riêng từng trang: `_ValuationWorkItemTile` (valuation_queue_page), `_KeyValueRow` (valuation_workspace_page), `WarehouseTaskCard`. Có sẵn: `VSearchBar`, `VChip`, `VBanner`, `VBottomSheet` / `showVBottomSheet`, `VEmptyState`, `VLoading`, `VButton`, `VBadge`, `VDivider`, `VGap`, `VToast`. |
| Lỗi | Mất quyền: dùng `AppException(AppErrorCode.noPermission)` (`lib/core/errors/app_exception.dart`). |
| Kiểu số lượng | `double` (như `ValuationGroupItem.pendingQty`). |
| Mẫu logic | `ValuationQueueState`/`Cubit`: enum `status` + `copyWith` + `search()`/`setFilter()`. |

## 3. Thay đổi

Quy ước thư mục theo `features/inventory/` hiện có (data / logic / presentation), kiến trúc Page → Cubit → Repository.

| File | Hành động | Nội dung |
|---|---|---|
| `data/models/stock_indicator.dart` | tạo | `enum StockFilter {all,out,low,near,expired}`, `enum StockIndicator {out,expired,low,near,notConfigured}` + `label` + thứ tự ưu tiên |
| `data/models/stock_lot_item.dart` | tạo | `StockLotItem` (code, expiryDisplay, expiryPrecision, physical, eligible, indicator, nearExpiryAction, daysToExpiry) |
| `data/models/stock_product_item.dart` | tạo | `StockProductItem` + logic suy ra chỉ báo (mục 4.2) |
| `data/models/stock_snapshot.dart` | tạo | `StockSnapshot {items, queryAsOf, isStale}` và `StockProductDetail {product, queryAsOf, isStale}` |
| `data/stock_repository.dart` | tạo | Dữ liệu mẫu 5 sản phẩm (mục 4.1) + `getSnapshot`, `getProduct`, `refresh` + `StockScenario` để test ép trạng thái |
| `logic/stock_list_state.dart`, `stock_list_cubit.dart` | tạo | Trạng thái + cubit SCR-001 |
| `logic/stock_detail_state.dart`, `stock_detail_cubit.dart` | tạo | Trạng thái + cubit SCR-003 |
| `presentation/widgets/inventory_list_row.dart` | tạo | Row điều hướng dùng chung (title, subtitle, leading icon tuỳ chọn, trailing, chevron, `enabled`) — dùng cho SCR-001, lô, "Nguồn…" |
| `presentation/widgets/inventory_key_value_row.dart` | tạo | Key-value Row 2 chế độ `default` / `emphasis` |
| `presentation/widgets/stock_lot_sheet.dart` | tạo | Bottom sheet "Lô {code}" |
| `presentation/widgets/stock_provenance_sheet.dart` | tạo | Bottom sheet "Nguồn và thời điểm cập nhật" |
| `presentation/pages/stock_list_page.dart` | tạo | SCR-001 |
| `presentation/pages/stock_detail_page.dart` | tạo | SCR-003 |
| `lib/core/router/app_router.dart` | sửa | 2 route + import (mục 4.6) |
| `test/features/inventory/data/stock_product_item_test.dart` | tạo | Unit: chỉ báo, phrase, gợi ý, bất biến breakdown |
| `test/features/inventory/data/stock_repository_test.dart` | tạo | Unit: lọc + tìm + refresh |
| `test/features/inventory/presentation/pages/stock_flow_test.dart` | tạo | Widget: SCR-001 + SCR-003 |

Sửa `data/inventory_repository.dart`: `lookup_stock` → `routePath: '/warehouse/stock'` (xem U1). Không đụng `warehouse_home_*`.

## 4. Các bước

### 4.0 Điều kiện bắt đầu
- [ ] `dart analyze lib/features/inventory` = 0 lỗi (đã đạt 2026-10-14).
- [ ] `flutter test test/features/inventory` xanh (hiện 14 test).

### 4.1 Model + dữ liệu mẫu

Dữ liệu mẫu **chép đúng** `bj01Products` của prototype (để so mắt với HTML):

| id | Tên · mã | UOM | Theo dõi | Vật lý | Đủ ĐK | Giữ | Khả dụng | Ngưỡng/Mục tiêu | Config | Lý do chênh | Lô |
|---|---|---|---|---|---|---|---|---|---|---|---|
| INV-NOB | Nobivac DHPPi · SP-000184 | hộp | LOT | 120 | 118 | 12 | 106 | 30 / 80 | CONFIGURED | Cách ly 2 | DH2507 (30/11/2026, 70/70) · DH2509 (15/09/2026, 50/48, cận hạn, còn 19 ngày, WARN) |
| INV-AMX | Amox 500 · SP-000066 | hộp | NONE | 48 | 47 | 5 | 42 | 50 / 80 | CONFIGURED | Cách ly 1 | — |
| INV-ENRO | Enrofloxacin 10% · SP-000091 | chai | NONE | 0 | 0 | 0 | 0 | 10 / 30 | CONFIGURED | — | — |
| INV-TYLO | Tylosin 20% · SP-000122 | lọ | LOT | 18 | 7 | 3 | 4 | 8 / 24 | CONFIGURED | Hết hạn 11 | TY2408 (31/07/2026, 11/0, hết hạn) · TY2511 (**11/2027**, precision MONTH, 7/7) |
| INV-OXY | Oxytetracycline LA · SP-000147 | chai | NONE | 31 | 30 | 4 | 26 | null / null | NOT_CONFIGURED | Cách ly 1 | — |

Kèm mỗi sản phẩm: `barcode` (8938500001012, …004068, …005096, …006123, …007144), `latestMovement {label, source, delta}`, `reservation {quantity, source}` (xem `bj01Products` trong `app.js`).

`StockRepository`:

```dart
enum StockScenario { normal, empty, stale, permissionDenied }

class StockRepository {
  StockRepository({this.scenario = StockScenario.normal});
  final StockScenario scenario;

  Future<StockSnapshot> getSnapshot({String query = '', StockFilter filter = StockFilter.all});
  Future<StockProductDetail> getProduct(String productId);
  /// Lấy lại; queryAsOf lấy từ "server" (dãy mẫu 09:47, 09:51), KHÔNG dùng DateTime.now().
  Future<StockSnapshot> refresh({String query = '', StockFilter filter = StockFilter.all});
}
```

- `permissionDenied` → `throw const AppException(AppErrorCode.noPermission)` **trước** khi trả bất kỳ số lượng nào.
- `getProduct` không có id → `AppException(AppErrorCode.notFound)` (spec: `PRODUCT_NOT_FOUND`).
- `queryAsOf` ban đầu `09:42 · 27/08/2026` (đúng prototype). Hiển thị "Dữ liệu đến 09:42, 27/08/2026".
- Tìm: không phân biệt hoa/thường, khớp tên + mã + mã vạch (đúng `bj01SearchText`).

### 4.2 Logic suy ra chỉ báo (đặt trong `StockProductItem`, thuần Dart)

Hai chiều độc lập: **mức tồn** và **hạn dùng** (SCR-001 revision v3.9.1).

| Chỉ báo | Điều kiện | Phrase trên row | Cấp |
|---|---|---|---|
| `out` | `available == 0` | `Hết hàng` | Product |
| `expired` | có lô `EXPIRED` | `Có lô hết hạn` | LOT |
| `low` | đã cấu hình **và** `available > 0` **và** `threshold != null` **và** `available <= threshold` | `Tồn thấp` | Product |
| `near` | có lô `NEAR_EXPIRY` | `Có lô cận hạn` | LOT |
| `notConfigured` | `config == NOT_CONFIGURED` | `Chưa có ngưỡng tồn` | Monitoring |

- Phrase ưu tiên trên row: filter ≠ Tất cả → phrase của filter đó (không có thì rơi về `notConfigured` nếu có); filter = Tất cả → thứ tự `out > expired > low > near > notConfigured`.
- Gợi ý bổ sung = `max(0, target - available)` **chỉ khi** đã cấu hình và `target != null`; NOT_CONFIGURED → không gợi ý, không suy ngưỡng (UC-01-04 AF-A).
- `NONE` không có lô → không bao giờ vào `near`/`expired` (UC-01-04 BR-06).
- Bất biến: tổng `eligibilityBreakdown.quantity` = `physical - eligible` (PRJ-01). Đưa vào test trên cả 5 mẫu.

Kết quả mong đợi với dữ liệu mẫu (đưa nguyên vào test):

| Sản phẩm | Row, filter Tất cả | Chỉ báo có |
|---|---|---|
| Nobivac DHPPi · SP-000184 | `106 hộp khả dụng · Có lô cận hạn` | near |
| Amox 500 · SP-000066 | `42 hộp khả dụng · Tồn thấp` | low |
| Enrofloxacin 10% · SP-000091 | `0 chai khả dụng · Hết hàng` | out (không low: available = 0) |
| Tylosin 20% · SP-000122 | `4 lọ khả dụng · Có lô hết hạn` (filter Tồn thấp → `… · Tồn thấp`) | expired, low |
| Oxytetracycline LA · SP-000147 | `26 chai khả dụng · Chưa có ngưỡng tồn` | notConfigured |

Lọc: Hết hàng → {Enro}; Tồn thấp → {Amox, Tylosin}; Cận hạn → {Nobivac}; Hết hạn → {Tylosin}.

Định dạng số lượng: bỏ phần thập phân khi nguyên (`106`, không `106.0`); UOM luôn đi cùng số (spec: "UOM chỉ đi với quantity").

### 4.3 Cubit

`StockListCubit(repository)`:
- State: `status {initial, loading, ready, failure, permissionDenied}`, `items`, `query`, `filter`, `queryAsOf`, `isStale`, `errorMessage`, `hasAnyData` (phân biệt `EMPTY` — chưa có dữ liệu — với `FILTER_EMPTY` — có dữ liệu nhưng lọc/tìm ra rỗng).
- `load()`, `search(q)`, `setFilter(f)`, `refresh()`.
- Bắt `AppException`: `isNoPermission` → `permissionDenied` (xoá `items`); lỗi khác → `failure` + `userMessage()`.
- `search`/`setFilter` **giữ nguyên bộ lọc kia** và không chớp `LOADING` toàn màn hình (chỉ lần `load()` đầu): spec T04 "giữ nguyên phạm vi".
- Debounce tìm kiếm không bắt buộc (dữ liệu mẫu), nhưng bỏ kết quả cũ nếu có yêu cầu mới hơn (so `query`/`filter` hiện tại trước khi `emit`) để sau này nối RPC không bị đua.

`StockDetailCubit(repository, productId)`: `load()`, `refresh()`; trạng thái `loading / ready / failure / permissionDenied`, thêm `isStale`, `queryAsOf`.

### 4.4 SCR-001 — `stock_list_page.dart`

Thứ tự theo "Information hierarchy" của spec:

1. `VAppBar` title `Tồn kho`, `centerTitle: false`, không action phải (theo `VPageScaffold`/`VAppBar` như `valuation_queue_page`).
2. Dòng ngữ cảnh nhỏ: `Kho trung tâm · Dữ liệu đến 09:42, 27/08/2026` (từ `queryAsOf` server).
3. `STALE`: `VBanner` warning "Dữ liệu có thể đã cũ" + `VButton` secondary `Làm mới` (gọi `refresh()`; thành công chỉ đổi `queryAsOf`).
4. `VSearchBar`, hint `Tên, mã sản phẩm hoặc mã vạch`. Chữ **"mã vạch"**, không "barcode".
5. Hàng `VChip` cuộn ngang một dòng, **không wrap/cắt chữ**: `Tất cả / Hết hàng / Tồn thấp / Cận hạn / Hết hạn`; chọn = `VComponentTone.primary`, còn lại `neutral` (như `valuation_queue_page`).
6. Danh sách `InventoryListRow`: title `Tên · Mã`, subtitle theo 4.2, trailing chevron; **không card quanh từng sản phẩm, không badge cho số lượng, không nút "Mở"**; cả row bấm được → SCR-003.
7. Trạng thái:
   - `LOADING`: `VLoading` (hoặc `VSkeleton`), vẫn giữ dòng ngữ cảnh.
   - `EMPTY`: `VEmptyState` "Chưa có dữ liệu tồn kho" (sản phẩm tồn 0 **vẫn là một row**, không phải EMPTY).
   - `FILTER_EMPTY`: `VEmptyState` "Không có kết quả phù hợp" (+ nút/hành động xoá lọc nếu muốn, giống `data-bj01-clear`).
   - `PERMISSION_DENIED`: `VEmptyState`/màn từ chối, **không** dựng bất kỳ tên/số lượng nào vào cây widget.
   - `failure`: dùng cách hiện lỗi chung của `WarehouseHomePage` (tiêu đề + `Thử lại`), không hiện exception thô.

Quay lại từ SCR-003 phải **giữ nguyên query + filter**: SCR-001 vẫn nằm trong stack khi `push`, nên cubit tạo trong page là đủ; đừng `go()` thay `push()`.

Deep link: `/warehouse/stock?filter=low|out|near|expired` chỉ **chọn sẵn** chip (UIF: "deep link chỉ preselect filter"). Tham số lạ → `all`.

### 4.5 SCR-003 — `stock_detail_page.dart`

Thứ tự:

1. `VAppBar` `Chi tiết tồn kho`, có Back. Dòng ngữ cảnh `Kho trung tâm · Dữ liệu đến …`.
2. `STALE`: banner + `Làm mới` như SCR-001.
3. Danh tính sản phẩm gọn, **không badge**: dòng 1 tên; dòng 2 `SP-000184 · hộp`.
4. `Khả dụng` = `InventoryKeyValueRow(emphasis)`, giá trị `106 hộp`. Đây là outcome chính duy nhất, **không lặp** ở chỗ khác, không lưới metric, không card tổng.
5. Cùng một nhóm (một bề mặt chung, row bên trong không thành card riêng): `Tồn vật lý 120 hộp`, `Đủ điều kiện bán 118 hộp`, `Đã giữ 12 hộp`.
6. Khi `physical > eligible`: thêm các row lý do (`Cách ly 2 hộp`), **chỉ lý do có quantity > 0**.
7. Banner theo chỉ báo: `out` → `VBanner` error "Hết hàng" + "Khả dụng 0 {uom}. Gợi ý bổ sung: {n} {uom} để đạt mức mục tiêu {target} {uom}."; `low` → warning "Tồn thấp" + "Khả dụng N · Ngưỡng T. Gợi ý bổ sung …". Bình thường **không banner**. `notConfigured` → dòng chữ phụ "Chưa cấu hình ngưỡng tồn; chưa thể xác định trạng thái tồn thấp/bình thường." (không giả NORMAL).
8. Chỉ khi `tracking == LOT`: mục "Lô và hạn dùng · N lô"; mỗi lô một `InventoryListRow`: title `Lô DH2509`, subtitle `HSD 15/09/2026 · Tồn 50 hộp · Cận hạn`. Giữ **precision gốc** (`11/2027`, không đổi thành 01/11/2027). Lô **không** hiện đã giữ/khả dụng (chưa có allocation — BC-IO-01).
9. Một row điều hướng `Nguồn và thời điểm cập nhật` (leading icon history) → `StockProvenanceSheet`.
10. Hành động duy nhất ngoài đọc là `Làm mới` (query). Không footer, không Add/Edit/Delete.

`StockLotSheet`: title `Lô {code}`; dòng phụ `{tên SP} · HSD {expiry}`; `Tồn vật lý`, `Đủ điều kiện bán`; banner theo lô: hết hạn → error "Hết hạn — Lượng của lô này không đủ điều kiện bán."; cận hạn + `BLOCK_SALE` → warning "Cận hạn · Đã chặn bán"; cận hạn thường → warning "Cận hạn" + "Còn {n} ngày · vẫn đủ điều kiện bán theo chính sách hiện tại."

`StockProvenanceSheet`: `Dữ liệu đến`, `{label} gần nhất` (vd `Nhận hàng gần nhất: PN-260816-04 · +118 hộp`; `Chưa có biến động` khi không có), `Đã giữ` (`12 hộp · SO-260817-08`, hoặc `0 hộp`). Cuối sheet một row "Xem lịch sử biến động" là handoff sang BJ-15 (UIF-01-T06): vì BJ-15 chưa có, để **State Disabled (opacity 0.4)** và ghi `// TODO(T7-13: BJ-15)` — không toast giả hành vi.

Dùng `showVBottomSheet` như `valuation_direct_basis_sheet.dart`; sheet thường, không nút X (theo DS-CONFORMANCE).

### 4.6 Router

Trong `app_router.dart`, cạnh nhóm `/warehouse/...` (đặt **trước** `/warehouse/stock/:productId` nếu có route tĩnh cùng tiền tố):

```dart
GoRoute(
  path: '/warehouse/stock',
  name: 'warehouse.stock',
  builder: (context, state) => StockListPage(
    initialFilter: StockFilter.fromQuery(state.uri.queryParameters['filter']),
  ),
),
GoRoute(
  path: '/warehouse/stock/:productId',
  name: 'warehouse.stock.detail',
  builder: (context, state) =>
      StockDetailPage(productId: state.pathParameters['productId'] ?? ''),
),
```

- Không cần `ShellRoute`/`BlocProvider` chung (khác BJ-02/03): hai màn đọc, cubit tạo trong page.
- Truyền `productId` bằng path param chứ không `extra` → deep link từ ngữ cảnh sản phẩm mở thẳng SCR-003 và Back về nơi gọi, không ép qua SCR-001.
- Back từ SCR-003: `context.canPop() ? context.pop() : context.go('/warehouse/stock')`.

### 4.7 Test

Unit (`stock_product_item_test.dart`, `stock_repository_test.dart`):
- Bảng 4.2: 5 sản phẩm → đúng phrase ở filter Tất cả; đúng tập sản phẩm ở 4 filter.
- Biên: `available == threshold` → `low`; `available == 0` → `out` và **không** `low`; NOT_CONFIGURED + `available == 0` vẫn `out`.
- Gợi ý: Amox = 38 (80−42), Enro = 30, Oxy = null.
- Bất biến breakdown trên cả 5 mẫu.
- Repository: tìm `8938500006123` ra Tylosin; tìm `nobi` ra Nobivac; `refresh()` đổi `queryAsOf` sang `09:47 · 27/08/2026` rồi `09:51 · 27/08/2026`; `permissionDenied` ném `AppException.isNoPermission`; `getProduct('x')` ném `notFound`.

Widget (`stock_flow_test.dart`, theo `valuation_flow_test.dart`):
- SCR-001 READY: 5 row đúng subtitle; có 5 chip.
- Bấm chip `Hết hạn` → chỉ còn Tylosin; tìm `zzz` → `Không có kết quả phù hợp`.
- `StockScenario.empty` → `Chưa có dữ liệu tồn kho`.
- `StockScenario.stale` → có banner + nút `Làm mới`; bấm → dòng `Dữ liệu đến` đổi, banner mất.
- `StockScenario.permissionDenied` → `find.text('Nobivac DHPPi')` rỗng, không có `106`.
- Bấm row Nobivac → SCR-003 (GoRouter test): thấy `Khả dụng`, `106 hộp`, `Cách ly 2 hộp`, mục `Lô và hạn dùng`; bấm `Lô DH2509` → sheet có `Cận hạn` và `Còn 19 ngày`.
- SCR-003 với Amox (NONE): **không** có mục `Lô và hạn dùng`; có banner `Tồn thấp` + `Gợi ý bổ sung: 38 hộp`.
- SCR-003 Oxy: có chữ `Chưa cấu hình ngưỡng tồn`, không banner, không "Gợi ý bổ sung".
- Back về SCR-001 giữ chip `Hết hạn` đã chọn.

## 5. Kiểm tra

- [ ] `dart analyze lib/features/inventory test/features/inventory` = 0 lỗi (`flutter analyze` sập do đường dẫn có dấu; dùng `dart analyze`).
- [ ] `flutter test test/features/inventory` xanh, gồm test mới.
- [ ] So với `TEST-BASELINE.md`: không lỗi thêm ngoài inventory.
- [ ] Không còn chuỗi `barcode`, `LOT`/`Theo lô` trên row, ID kỹ thuật hay câu "implementation" trong UI (SCR-001 mục "Security/content hygiene").
- [ ] Thao tác tay (`flutter run`): Thêm → Kho → Tra cứu → Tồn kho → lọc `Hết hạn` → mở Tylosin → mở lô `TY2408` → Back, Back: chip vẫn là `Hết hạn`.
- [ ] Đối chiếu mắt với prototype `index.html` → UIF-01 → SCR-001/SCR-003 (đủ 6 + 4 trạng thái trong inspector).

## 6. Rủi ro / lưu ý

- **Không có `VListRow`/`VKeyValueRow` trong DS.** Plan tạo 2 widget dùng chung trong `features/inventory/presentation/widgets/` thay vì thêm tiếp bản riêng trong từng page. Việc gộp các bản trùng của BJ-02/03 để việc khác; nếu muốn đưa lên `vet45_design_system` thì là plan riêng (đụng package dùng chung).
- **Fixture lệch giữa các BJ.** BJ-01 dùng `SP-000184`, BJ-03 dùng `SP-00142` cho cùng "Nobivac DHPPi". Trong prototype cũng đã lệch, không sửa ở plan này; khi nối backend thật thì mã lấy từ catalog nên tự hết lệch.
- **BJ-02/03 chưa ảnh hưởng tồn.** Nhận hàng xong, tồn ở BJ-01 chưa đổi (dữ liệu mẫu tách nhau). Chấp nhận ở giai đoạn UI; nối thật ở plan backend (`BC-IO-02` ghi sổ nhận hàng → `PRJ-01`).
- **`query_as_of` luôn lấy từ server.** Không dùng `DateTime.now()` để hiển thị hay làm mới (spec SCR-001 §4). Khi thay repository bằng RPC, giữ nguyên chỗ này.
- **Tìm kiếm chưa bỏ dấu** (đúng prototype: `toLocaleLowerCase('vi')`). Gõ "nobi" khớp, gõ "tylosin" khớp, nhưng "amoxicillin" không khớp "Amóx". Nếu muốn không dấu, thêm hàm chuẩn hoá trong repository — ghi nhận, không làm ở đây.
- **Quyền tài chính.** BJ-01 không hiện đơn giá/giá trị nên chưa cần `FINANCIAL_MASKED`; đừng thêm trường giá vào model.
- **Nối RPC sau này:** giữ chữ ký `StockRepository` (3 hàm) để chỉ thay phần thân; `StockScenario` chỉ dùng cho test/dev, bỏ khi có backend.

## 7. Review
<!-- Claude ghi sau khi người dùng code xong -->
- Ngày, commit được review:
- Kết quả: ⬜
- Góp ý:
