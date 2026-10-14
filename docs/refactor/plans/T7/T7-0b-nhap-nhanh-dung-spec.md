# T7-0b — Nhập hàng nhanh đúng spec (SCR-006, 008, 009, 084, 010, 011, 012)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7. Inventory" (đợt 0). Ước lượng: **~2 ngày, 2 PR**. Làm sau [T7-0](T7-0-ra-soat-bj02-bj03.md) (✅).
> Đối chiếu: Screen Contract `specs/themes/theme-07/03.design/screens/SCR-006, 008, 009, 084, 010, 011, 012`; câu chữ lấy từ prototype v4.6.8 (`index.html?uif=UIF-02&flow=quick&screen=…&state=…`, trích ngày 2026-10-14).

Đường dẫn tính từ `apps/erp/lib/features/inventory/` nếu không ghi khác. Viết tắt trong plan: `VButton('X')` = `VButton(label: 'X', …)`; các biến thể DS có: `VButtonVariant.primary / secondary / tertiary / link`.

## 1. Mục tiêu

Sau T7-0b, luồng **nhập hàng nhanh** khớp Screen Contract và prototype về nội dung, câu chữ và bố cục:

- Chọn cách nhận đúng spec; Home vào thẳng nhập nhanh.
- Tìm sản phẩm ngay trên màn Hàng thực nhận; một đơn vị thì vào thẳng editor, nhiều đơn vị thì chọn trực tiếp.
- HSD / NSX giữ đúng cách ghi trên bao bì (ngày / tháng / năm); chặn lô trùng mã nhưng khác hạn dùng với lô đã có.
- Rà soát, phê duyệt, kết quả hiển thị đủ từng dòng hàng + lô + HSD, không lộ mã kỹ thuật.
- Sửa 3 góp ý của review T7-0.

## 2. Phạm vi

| Trong T7-0b | Để plan sau |
|---|---|
| Nội dung / bố cục / câu chữ SCR-006, 008, 009, 084, 010, 011, 012 cho **nhập nhanh** | Trạng thái chung (`PERMISSION_DENIED`, `LOCKED` / `READ_ONLY` do khoá kho, `CONFLICT`, `APPROVER_CONFIGURATION_MISSING`, `PROCESSING` / `UNKNOWN` / `REJECTED_EXECUTION`) + SCR-013 → **T7-0c** |
| Trạng thái gắn với nội dung: `APPROVAL_REQUIRED` (banner lý do), `VALIDATION_ERROR` "chưa có hàng vào tồn", `LOT_CONFLICT`, `DUPLICATE_LINE` (đã có từ T7-0), `READ_ONLY` khi xem lại sau khi gửi, `VALUATION_PENDING_RESULT` | Nhận theo chứng từ: SCR-007 + chế độ document của 009 / 084 / 010 / 011 → **T7-0d** |
| Tải danh mục nhà cung cấp / sản phẩm qua Cubit (bỏ repository trong page 008, 009) | BJ-03 theo spec + kiến trúc / DS còn lại → **T7-0e** |

`FINANCIAL_MASKED` ở SCR-010 / 011 **không áp dụng** cho nhập nhanh: nhập nhanh không hiển thị tiền (SCR-011 §1), nên không có gì để che.

## 3. PR 1 — Dữ liệu, luật, góp ý T7-0

### 3.1 Góp ý review T7-0

**a. Home không mở route chưa có** — `data/inventory_repository.dart`:

| Mục | `routePath` mới |
|---|---|
| Task `SO-260827-21`, `KK-0709-03` | `null` (chưa có BJ-05, BJ-08) |
| Tra cứu `lookup_stock` | `null` (T7-1 đặt lại `'/warehouse/stock'`) |
| Tra cứu `lookup_reports`, `lookup_all_features` | `null` |
| Thao tác `quick_receipt` | `'/warehouse/receipts/quick/header'` |
| Thao tác `new_count`, `change_state`, `create_disposal` | `null` |

`presentation/pages/warehouse_home_page.dart`, trong `onSelectAction` của "Bắt đầu việc mới": bỏ `if (action.id == 'quick_receipt')`, dùng chung cách của task:

```dart
onSelectAction: (action) => action.routePath != null
    ? context.push(action.routePath!)
    : VToast.show(context, title: action.title, message: action.subtitle, type: VToastType.info),
```

(`routePath` của `WarehouseManualAction` phải là `String?` — đổi kiểu nếu đang là `String`.)

**b. Màn kết quả bỏ câu cũ** — làm cùng bước 4.7.

**c. Duyệt gặp "đã xử lý" thì tải lại** — `logic/receipt_approval_cubit.dart`, trong `catch` của `approve` và `reject`:

```dart
final error = AppException.from(e);
if (error.code == 'APPROVAL_ALREADY_DECIDED') {
  await load(current.document.id); // hiện banner "Yêu cầu đã được xử lý", ẩn footer
  return;
}
emit(current.copyWith(isProcessing: false, actionError: error.userMessage(receiptErrorMessages)));
```

### 3.2 Ngày có cách ghi (HSD / NSX theo bao bì)

Tạo **`data/models/lot_date.dart`**:

```dart
import 'package:equatable/equatable.dart';

enum DatePrecision { day, month, year }

/// Ngày trên bao bì, giữ đúng cách ghi gốc (SCR-084 v3.9.2).
class LotDate extends Equatable {
  const LotDate({required this.year, this.month, this.day});

  final int year;
  final int? month;
  final int? day;

  DatePrecision get precision =>
      day != null ? DatePrecision.day : (month != null ? DatePrecision.month : DatePrecision.year);

  /// Ngày đầu kỳ — chỉ dùng để so sánh.
  DateTime get start => DateTime(year, month ?? 1, day ?? 1);

  /// 15/09/2026 · 11/2027 · 2027
  String format() {
    String two(int v) => v.toString().padLeft(2, '0');
    return switch (precision) {
      DatePrecision.day => '${two(day!)}/${two(month!)}/$year',
      DatePrecision.month => '${two(month!)}/$year',
      DatePrecision.year => '$year',
    };
  }

  /// Hai ngày không mâu thuẫn: trùng ở mọi phần mà cả hai cùng có.
  bool isConsistentWith(LotDate other) =>
      year == other.year &&
      (month == null || other.month == null || month == other.month) &&
      (day == null || other.day == null || day == other.day);

  static LotDate? tryParse(String input, DatePrecision precision) {
    final parts = input.trim().split('/');
    final expected = switch (precision) {
      DatePrecision.day => 3,
      DatePrecision.month => 2,
      DatePrecision.year => 1,
    };
    if (parts.length != expected) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    final year = nums.last!;
    if (year < 1900 || year > 2200) return null;
    final month = expected >= 2 ? nums[expected - 2] : null;
    final day = expected == 3 ? nums[0] : null;
    if (month != null && (month < 1 || month > 12)) return null;
    if (day != null) {
      final d = DateTime(year, month!, day);
      if (d.month != month || d.day != day) return null; // 31/02 sai
    }
    return LotDate(year: year, month: month, day: day);
  }

  @override
  List<Object?> get props => [year, month, day];
}
```

**`data/models/receipt_lot_draft.dart`**: `manufactureDate`, `expiryDate` đổi kiểu `DateTime?` → `LotDate?`. Sửa theo: seed `REC-240715-01` trong `goods_receipt_repository.dart` (`LotDate(year: 2026, month: 7)` cho NSX, `LotDate(year: 2028, month: 7)` cho HSD), test.

`copyWith` của `ReceiptLotDraft` không xoá được ngày (người dùng xoá HSD): thêm `bool clearManufactureDate = false, bool clearExpiryDate = false`.

### 3.3 Lô đã có trong hệ thống (`LOT_CONFLICT`)

`data/goods_receipt_repository.dart`:

- `ReceiptProductDto` thêm `final String barcode;` và `final Map<String, LotDate> knownLotExpiry;` (mặc định `const {}`).
- Fixture sản phẩm (dùng cho cả bước 4.3, 4.4):

| id | Tên | Mã | Mã vạch | Theo lô | Cần HSD | Đơn vị | Lô đã có |
|---|---|---|---|---|---|---|---|
| `prod_01` | Amox 500 | AMX-500 | 8938500004068 | có | có | Hộp, Vỉ, Viên | `L2407-A` → `07/2028` |
| `prod_02` | Cefa-Vet 100ml | CFV-100 | 8938500002011 | có | có | Chai, Thùng | — |
| `prod_03` | Bơm kim tiêm 5ml | BKT-05 | 8938500003025 | không | không | Hộp, Cái | — |
| `prod_04` | Găng tay khám Nitrile | GLOVE-N | 8938500003100 | không | không | Hộp (một đơn vị) | — |

`data/models/receipt_item_draft.dart`: thêm `final Map<String, LotDate> knownLotExpiry;` (mặc định `const {}`), gán từ DTO khi tạo dòng (bước 4.3).

### 3.4 Luật bổ sung — `logic/receipt_rules.dart`

1. `LotIssue` thêm `lotConflict` — câu: `'Lô này đã có trong hệ thống với hạn dùng khác'`.
2. Trong `validateReceiptItem`:

```dart
final known = item.knownLotExpiry[lot.lotCode.trim().toUpperCase()];
...
if (item.isLotTracked && known != null && lot.expiryDate != null && !lot.expiryDate!.isConsistentWith(known))
  LotIssue.lotConflict,
```

   (key của `knownLotExpiry` viết hoa.) So sánh HSD / NSX đổi sang `!lot.expiryDate!.start.isAfter(lot.manufactureDate!.start)`.

3. Hàm hiển thị dùng chung (thuần, có test):

```dart
/// 106 · 1,5 · 0,25 — không làm tròn số lẻ.
String formatQuantity(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');
}

/// "120 đạt · 2 cách ly · 1 hỏng · 5 từ chối" hoặc "Chưa ghi nhận" (prototype `classificationText`).
String classificationText(ReceiptItemDraft item) {
  if (item.totalReceived <= 0) return 'Chưa ghi nhận';
  return [
    if (item.isLotTracked) '${item.lots.length} lô',
    if (item.totalAccepted > 0) '${formatQuantity(item.totalAccepted)} đạt',
    if (item.totalQuarantine > 0) '${formatQuantity(item.totalQuarantine)} cách ly',
    if (item.totalDamaged > 0) '${formatQuantity(item.totalDamaged)} hỏng',
    if (item.totalRejected > 0) '${formatQuantity(item.totalRejected)} từ chối',
  ].join(' · ');
}
```

   Thay mọi `toStringAsFixed(0)` của số lượng trong các màn BJ-02 bằng `formatQuantity`.

### 3.5 Danh mục tải qua Cubit (bỏ repository trong page)

`logic/quick_receipt_session_state.dart` thêm:

```dart
enum CatalogStatus { loading, ready, failure }

final CatalogStatus catalogStatus;          // mặc định loading
final List<ReceiptSupplierDto> suppliers;   // mặc định const []
final List<ReceiptProductDto> products;     // mặc định const []
```

`logic/quick_receipt_session_cubit.dart`:

```dart
Future<void> loadCatalog() async {
  emit(state.copyWith(catalogStatus: CatalogStatus.loading));
  try {
    final suppliers = await _repository.getSuppliers();
    final products = await _repository.getProducts();
    emit(state.copyWith(catalogStatus: CatalogStatus.ready, suppliers: suppliers, products: products));
  } catch (e) {
    emit(state.copyWith(
      catalogStatus: CatalogStatus.failure,
      errorMessage: AppException.from(e).userMessage(receiptErrorMessages),
    ));
  }
}
```

`core/router/app_router.dart` (ShellRoute nhập nhanh): `create: (_) => QuickReceiptSessionCubit(…)..loadCatalog()`.

`quick_receipt_header_page.dart` và `goods_receipt_items_page.dart`: xoá `_repo`, `_loadSuppliers` / `_loadProducts`, `_suppliers` / `_availableProducts`, `_isLoading…`; đọc `state.suppliers`, `state.products`, `state.catalogStatus`.

### 3.6 Test PR 1

Thêm vào `test/features/inventory/logic/receipt_rules_test.dart` (và tạo `lot_date_test.dart`):

| # | Test | Kỳ vọng |
|---|---|---|
| B1 | `LotDate.tryParse('15/09/2026', day)` / `('11/2027', month)` / `('2027', year)` | đúng năm / tháng / ngày; `format()` trả lại đúng chuỗi |
| B2 | `tryParse('31/02/2026', day)`, `('13/2026', month)`, `('15-09-2026', day)` | `null` |
| B3 | `LotDate(2028, 7).isConsistentWith(LotDate(2028, 7, 15))` | `true`; với `LotDate(2028, 8)` → `false` |
| B4 | Amox, lô `l2407-a` HSD `08/2028` | `lotConflict`; HSD `07/2028` hoặc `15/07/2028` → không lỗi |
| B5 | `classificationText`: LOT 2 lô 120 đạt 2 cách ly | `'2 lô · 120 đạt · 2 cách ly'`; chưa nhập → `'Chưa ghi nhận'` |
| B6 | `formatQuantity(106)`, `(1.5)`, `(0.25)` | `'106'`, `'1,5'`, `'0,25'` |
| B7 | Approval: duyệt phiếu đã xử lý | cubit tải lại, state `Loaded` có `isDecided == true`, không có `actionError` |
| B8 | Home: chạm task `SO-260827-21` | hiện toast, không điều hướng |

## 4. PR 2 — Các màn

Mọi câu trong ngoặc kép là câu hiển thị, chép nguyên văn.

### 4.1 Widget dùng chung — `presentation/widgets/receipt_line_summary.dart` (tạo)

Dùng ở SCR-010, 011, 012. Một dòng hàng:

```dart
class ReceiptLineSummary extends StatelessWidget {
  const ReceiptLineSummary({super.key, required this.item, this.onTap, this.trailingLabel});
  final ReceiptItemDraft item;
  final VoidCallback? onTap;          // null = không chạm được
  final String? trailingLabel;        // vd "Đã xong"
}
```

Bố cục (không card riêng cho từng dòng; các dòng nằm trong một bề mặt chung của section, ngăn bằng `VDivider`):

1. Tiêu đề: `item.productName`; phụ đề: `'${item.productCode} · ${item.unitName}'` + (theo lô) `' · ${item.lots.length} lô'`; trailing `trailingLabel` (`VText` phụ) + chevron nếu `onTap != null`.
2. Ba dòng key-value (nhãn trái, số phải, căn theo một trục): `Tổng kiểm nhận` · `Vào tồn vật lý` · `Từ chối (không vào tồn)` — dòng thứ ba chỉ khi > 0. Giá trị `'${formatQuantity(q)} ${item.unitName}'`.
3. Theo lô — mỗi lô một dòng con: `'Lô ${lot.lotCode}'` · `'${formatQuantity(lot.totalReceived)} ${item.unitName}'` · `'HSD ${lot.expiryDate!.format()}'` (bỏ phần HSD nếu null).

### 4.2 SCR-006 Chọn cách nhận hàng — `pages/receipt_entry_choice_page.dart`

- AppBar `'Nhận hàng'`; giữ nút Back về Kho (điều hướng tích hợp v3.7.0: mọi lối vào có Back rõ về Kho).
- Bỏ câu dẫn `'Lựa chọn cách kiểm đếm…'`.
- Hai thẻ theo **thứ tự** (thẻ `VCard` chạm được, `VCardIcon(icon: …, tone: VComponentTone.neutral)`, trailing `VIcons.chevronRight`, **không badge**):

| Thẻ | Phụ đề | Hành vi |
|---|---|---|
| `'Nhận theo chứng từ'` | `'Chưa có chứng từ mua chờ nhận.'` | **Disabled** (opacity 0.4, không chạm) cho tới T7-0d — SCR-006 v3.9.2: blocker tạm thời = row disabled + lý do. Bỏ SnackBar "sẽ hoàn thiện" |
| `'Nhập hàng nhanh'` | `'Hàng đã đến, chưa có chứng từ mua.'` | `context.push('/warehouse/receipts/quick/header')` |

- `_ChoiceCard` bỏ tham số `badge`, `badgeTone`; thêm `enabled`.

### 4.3 SCR-008 Thông tin nhập hàng nhanh — `pages/quick_receipt_header_page.dart`

1. AppBar `'Nhập hàng nhanh'`.
2. Bỏ hai `VCard` đánh số "1." "2."; một section:
   - tiêu đề `'Thông tin lần nhận'`, mô tả `'Xác định nhà cung cấp, phạm vi nhận và chứng từ giao nhận.'`;
   - **Nhà cung cấp** \* — giữ sheet chọn; khi đang tải danh mục thì trường disabled; lỗi `'Chọn nhà cung cấp trong danh sách.'` (T7-0);
   - **Kho nhận** — `VTextField` disabled, giá trị `header.warehouseName`;
   - **Ngày nhận** — `VTextField` disabled, giá trị `dd/MM/yyyy` (không icon lịch);
   - **Chứng từ giao nhận** \* — `VFileDropZone` (T7-0), `title: 'Chọn hoặc kéo tệp'`, `subtitle: 'Phiếu giao hàng, biên bản bàn giao, vận đơn hoặc bản scan/ảnh rõ nội dung'`;
   - khối chữ phụ (không banner): tiêu đề `'Xác nhận quyền sở hữu'`, nội dung `'Hệ thống lưu người xác nhận, thời điểm và chứng từ giao nhận.'`.
3. **Xoá** trường "Ghi chú nhận hàng" và `notes` khỏi `ReceiptHeaderDraft` (SCR-010: nhập nhanh không có ghi chú chung) — sửa seed, review, approval.
4. Nút `'Xác nhận & tiếp tục'` ở **Sticky Footer**: `bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(VSpacing.space4), child: VButton(… fullWidth: true)))`; logic `_triedContinue` giữ như T7-0.

### 4.4 SCR-009 Hàng thực nhận — `pages/goods_receipt_items_page.dart`

1. AppBar `'Hàng thực nhận'`; bỏ nút `+` trên AppBar, nút "Thêm mặt hàng đầu tiên", "Thêm mặt hàng khác"; **xoá** `widgets/receipt_product_uom_sheet.dart` và sheet chọn sản phẩm trong `_addProductFlow`.
2. Đầu màn — section `'Thông tin lần nhận'`, trailing `'Chưa có mặt hàng'` hoặc `'${n} mặt hàng'`; ba dòng: `Nhà cung cấp`, `Kho nhận`, `Ngày nhận`.
3. Tìm sản phẩm ngay trên màn:

```dart
VSearchBar(
  hintText: 'Tìm tên, mã mặt hàng hoặc mã vạch',
  onChanged: (q) => setState(() => _query = q),
)
```

   Kết quả (lọc `state.products`, không phân biệt hoa thường, khớp `name` / `code` / `barcode`):
   - `_query` rỗng và chưa có mặt hàng → hiện toàn bộ danh mục; `_query` rỗng và đã có mặt hàng → ẩn danh sách kết quả;
   - mỗi kết quả là một hàng chạm được: tiêu đề `name`, phụ đề `'${code} · ${units.map((u) => u.name.toLowerCase()).join(', ')}'`, chevron. **Không** ghi "Quản lý theo lô";
   - không có kết quả → chữ phụ `'Sản phẩm chưa có trong danh mục. Hãy bổ sung mặt hàng trước khi quay lại nhận hàng.'`.
4. Chạm sản phẩm:

```dart
void _onProductTap(ReceiptProductDto p) {
  if (p.units.length == 1) return _onUnitChosen(p, p.units.single);
  setState(() => _expandedProductId = _expandedProductId == p.id ? null : p.id);
}
```

   Sản phẩm đang mở (`_expandedProductId`) hiện **lựa chọn đơn vị trực tiếp** ngay dưới hàng (không sheet, không dropdown):

```dart
VChoiceList<String>(
  choices: [
    for (final u in p.units)
      VChoiceOption(
        value: u.id,
        label: u.name,
        helpText: cubit.indexOf(p.id, u.id) >= 0 ? 'Đã có trong lần nhận' : null,
      ),
  ],
  selected: const [],
  onChanged: (ids) => _onUnitChosen(p, p.units.firstWhere((u) => u.id == ids.single)),
)
```

   `_onUnitChosen(p, u)` = phần thân `_addProductFlow` của T7-0 từ chỗ `indexOf` (kiểm trùng → banner, không trùng → mở editor), thêm `knownLotExpiry: p.knownLotExpiry`; sau đó `setState(() { _expandedProductId = null; _query = ''; })`.

5. Thẻ dòng hàng `_ReceiptItemCard`: tiêu đề `productName`; dòng 1 `'${productCode} · ${unitName}'`; dòng 2 `classificationText(item)`; trailing chevron. **Bỏ** `VChip` trạng thái, chấm màu, `_buildBadgeCount`, nút thùng rác (xoá chuyển vào editor, bước 4.5).
6. Trống: `VEmptyState` — tiêu đề `'Chưa có mặt hàng trong lần nhận'`, mô tả `'Tìm mặt hàng ở trên để thêm. Sản phẩm phải có sẵn trong danh mục.'`.
7. Sticky Footer: `VButton('Rà soát')`, `enabled: state.canReview`.
8. `catalogStatus == loading` → `VLoading` thay vùng kết quả; `failure` → chữ lỗi + `VButton('Thử lại', onPressed: cubit.loadCatalog)`.

### 4.5 SCR-084 Chi tiết hàng thực nhận — `pages/goods_receipt_item_detail_page.dart` + `widgets/receipt_lot_editor_card.dart`

**Tham số route.** Tạo `presentation/pages/receipt_item_detail_args.dart`:

```dart
class ReceiptItemDetailArgs {
  const ReceiptItemDetailArgs({required this.item, this.readOnly = false});
  final ReceiptItemDraft item;
  final bool readOnly;
}
```

`app_router.dart` route `item-detail`: `final args = state.extra as ReceiptItemDetailArgs;` → `GoodsReceiptItemDetailPage(item: args.item, readOnly: args.readOnly)`. Sửa mọi `context.push(…item-detail, extra: item)` thành `extra: ReceiptItemDetailArgs(item: item)`.

**Trang:**

1. AppBar `'Chi tiết hàng thực nhận'`.
2. Hàng ngữ cảnh sản phẩm (không chip): tiêu đề `productName`, phụ đề `'${productCode} · ${unitName}'`.
3. Theo lô: tiêu đề section `'Các lô thực nhận'`; danh sách `ReceiptLotEditorCard`; nút cấp collection `VButton(label: 'Thêm lô khác', variant: VButtonVariant.secondary)`. Không theo lô: không có section lô, chỉ một khối `'Phân loại số lượng'` (thẻ lô với `isLotTracked: false` đã ẩn mã lô / HSD).
4. Tóm tắt dòng (key-value): `Tổng kiểm nhận` · `Vào tồn vật lý` (dùng `formatQuantity`).
5. Dòng **đã có** trong session (`cubit.indexOf(...) >= 0`) và không `readOnly`: nút chữ màu nguy hiểm `'Xóa khỏi lần nhận'` (`VButton(variant: VButtonVariant.link, tone: VComponentTone.danger)`):

```dart
showVConfirmDialog(
  context: context,
  title: 'Xóa khỏi lần nhận?',
  message: 'Toàn bộ số lượng và thông tin lô của dòng hàng này sẽ bị xóa.',
  cancelLabel: 'Giữ lại',
  actionLabel: 'Xóa',
  isDestructive: true,
  onAction: () {
    final cubit = context.read<QuickReceiptSessionCubit>();
    cubit.removeItem(cubit.indexOf(widget.item.productId, widget.item.unitId));
    context.pop();
  },
);
```

6. Sticky Footer `VButton('Xong')` (logic `_save` của T7-0 giữ nguyên). `readOnly == true` → **không** footer, không nút xoá, không "Thêm lô khác"; thẻ lô hiển thị giá trị dạng chữ.

**Thẻ lô (`ReceiptLotEditorCard`)** — thêm `final bool readOnly;`:

1. Tiêu đề thẻ (theo lô): `lotCode` (hoặc `'Lô mới'` khi rỗng) + phụ đề `'${formatQuantity(lot.totalReceived)} ${unitName} · ${formatQuantity(lot.accepted)} đạt'`. Bỏ `VChip('Lô #n')`, bỏ dòng `'ĐVT: …'`.
2. `'Mã lô'` \* — hint `'Nhập mã trên bao bì'`.
3. `'Cách ghi hạn dùng'` — `VSegmentedControl` 3 đoạn `'Ngày/tháng/năm'`, `'Tháng/năm'`, `'Năm'` (mặc định Ngày/tháng/năm, hoặc theo precision của HSD đang có).
4. `'Hạn dùng'` \* (khi `requiresExpiry`) — `VTextField`, hint `dd/mm/yyyy` / `mm/yyyy` / `yyyy` theo cách ghi, helper `'Nhập đúng định dạng trên bao bì.'`. Thẻ giữ chuỗi gõ dở trong `State` (`_expiryText`, `_expiryPrecision`); mỗi lần đổi: `final parsed = LotDate.tryParse(_expiryText, _expiryPrecision);` → `onChanged(parsed != null ? lot.copyWith(expiryDate: parsed) : lot.copyWith(clearExpiryDate: true))`. Lỗi hiển thị: chuỗi khác rỗng mà `parsed == null` → `'Hạn dùng không đúng định dạng'` (lỗi tại thẻ); ngược lại dùng `LotIssue` (`missingExpiry`, `expiryNotAfterManufacture`, `lotConflict`).
5. NSX ẩn sau nút chữ `'Thêm ngày sản xuất'`; bấm (hoặc lô đã có NSX) → hiện cặp "Cách ghi ngày sản xuất" + `'Ngày sản xuất'` giống HSD, không bắt buộc.
6. `'Phân loại số lượng'`: bốn `VNumberField` (T7-0) nhãn `Đạt`, `Cách ly`, `Hỏng`, `Từ chối`; khi `rejected > 0` hiện chữ phụ `'Không vào tồn'` dưới ô Từ chối. Bỏ chấm màu trước nhãn.
7. Dòng tổng của lô: `'Tổng kiểm nhận'` · `'${formatQuantity(lot.totalReceived)} ${unitName}'`.
8. Xoá `showDatePicker` / `_pickDate` / `_formatDate` cũ.

### 4.6 SCR-010 Rà soát nhận hàng — `pages/goods_receipt_review_page.dart`

1. AppBar `'Rà soát nhận hàng'`.
2. Banner đầu màn (một nguồn phản hồi cho mỗi trạng thái):

| Điều kiện | Banner |
|---|---|
| Đã gửi (`submittedDocument != null`) | `VBannerStatus.info` — `'Đã gửi phê duyệt'` / `'Đang chờ người duyệt; tồn kho chưa thay đổi.'` (thay câu của T7-0) |
| Chưa gửi, có dòng, mọi dòng hợp lệ nhưng tổng vào tồn = 0 | `VBannerStatus.warning` — `'Chưa có hàng vào tồn'` / `'Nhập hàng nhanh chỉ gửi được khi Đạt + Cách ly + Hỏng lớn hơn 0.'` |
| Chưa gửi, còn lại | `VBannerStatus.info` — `'Cần phê duyệt trước khi ghi nhận'` / `'Nhập hàng nhanh luôn cần người duyệt độc lập. Tồn kho chưa thay đổi.'` |

   Xoá khối `Container` + `VIcons.info` tự dựng và `VChip('Chờ duyệt sau khi gửi')`.

3. Section `'Thông tin lần nhận'` + nút chữ `'Sửa'` (ẩn khi đã gửi) → `context.go('/warehouse/receipts/quick/header')` (cùng ShellRoute nên session giữ nguyên). Dòng: `Nhà cung cấp`, `Kho nhận`, `Ngày nhận`, `Chứng từ giao nhận` (`'${n} tệp'` + tên từng tệp). Bỏ `Ghi chú`.
4. Section `'Hàng thực nhận'`, trailing `'${n} mặt hàng'`, nút `'Sửa'` (ẩn khi đã gửi) → `context.go('/warehouse/receipts/quick/items')`; danh sách `ReceiptLineSummary` cho **mọi** dòng. Chạm dòng → `context.push(…item-detail, extra: ReceiptItemDetailArgs(item: item, readOnly: isSubmitted))`.
5. Footer chưa gửi: `'Gửi phê duyệt'` (đổi từ "Gửi phê duyệt phiếu nhận hàng"); đã gửi: `'Về Kho'` (T7-0).
6. `_buildInfoRow`: thay `Colors.grey.shade600` bằng `context.vColors.textSecondary`.

### 4.7 SCR-011 Phê duyệt + SCR-012 Kết quả

**SCR-011 — `pages/goods_receipt_approval_page.dart`:**

1. `VAppBar(title: 'Phê duyệt yêu cầu nhận hàng', subtitle: 'Việc dành cho người phê duyệt · ${doc.submittedByName} gửi')` (khi chưa tải xong: subtitle `'Việc dành cho người phê duyệt'`). Bỏ `'Duyệt phiếu: $receiptId'`, bỏ `doc.id` và `_buildStatusBadge`.
2. Chưa xử lý, không tự duyệt → `VBannerStatus.info` `'Lý do cần duyệt'` / `'Nhập hàng nhanh bắt buộc phê duyệt.'`. Hai banner tự duyệt / đã xử lý của T7-0 giữ nguyên; bị từ chối thì banner đã xử lý thêm `description: 'Đã từ chối: ${doc.rejectReason}'`.
3. Section `'Thông tin lần nhận'`: `Nhà cung cấp`, `Kho nhận`, `Ngày nhận`, nút `VButton(label: 'Xem chứng từ giao nhận', variant: VButtonVariant.secondary)` → `VBottomSheet` liệt kê tên tệp (fixture chưa có xem trước tệp).
4. Section `'Thông tin yêu cầu'`: `Người gửi` · `submittedByName`; `Gửi lúc` · `dd/MM/yyyy · HH:mm`. Không có tổng giá trị rủi ro (nhập nhanh).
5. Section `'Hàng thực nhận'`, trailing `'${n} mặt hàng'`: `ReceiptLineSummary` từng dòng (không chạm).
6. Footer: `'Từ chối'` (secondary, tone danger) · `'Duyệt'` (primary, `tone: VComponentTone.success`) — đổi nhãn từ "Phê duyệt".
7. `widgets/receipt_reject_reason_sheet.dart`: tiêu đề `'Từ chối yêu cầu'`; ô lý do `minLines: 3, maxLines: 5`; nút `'Huỷ'` · `'Từ chối'` (danger).

**SCR-012 — `pages/goods_receipt_result_page.dart`** (AppBar `'Kết quả nhận hàng'`, không Back; Sticky Footer `'Xong'` → `context.go('/inventory')`):

| Trạng thái phiếu | Nội dung |
|---|---|
| `completed` (`VALUATION_PENDING_RESULT`) | `VEmptyState` icon `VIcons.success`: `'Đã ghi nhận hàng'` / `'Đã tăng tồn vật lý theo ${n} dòng hàng được xử lý.'`; section `'Kết quả theo dòng hàng'` = `ReceiptLineSummary` từng dòng; `VBannerStatus.info` `'Đang chờ xác nhận giá'` / `'Phần Đạt chờ xác nhận giá; Cách ly/Hỏng giữ nguyên trạng thái.'`, `footer:` `VButton(label: 'Xác lập giá trị', variant: VButtonVariant.secondary)` → `/warehouse/valuation/receipt/${doc.id}` (nút của T7-0 chuyển vào đây) |
| `rejected` | `VEmptyState` icon `VIcons.close`: `'Đã từ chối yêu cầu'` / `'Lý do: ${doc.rejectReason}. Tồn kho không thay đổi.'` |
| `pendingApproval` (góp ý b) | `VEmptyState`: `'Yêu cầu đang chờ phê duyệt'` / `'Tồn kho chưa thay đổi.'` — xoá câu "chuyển tới Quản lý kho" |
| không tìm thấy | giữ như T7-0 |

Bỏ vòng tròn icon tự dựng, `'Mã phiếu'`, `'Số mặt hàng'`, `_buildDetailRow`.

### 4.8 Test PR 2

Sửa test cũ theo nhãn / route mới. Thêm:

| # | Test | Kỳ vọng |
|---|---|---|
| B9 | SCR-006 | thứ tự "Nhận theo chứng từ" rồi "Nhập hàng nhanh"; thẻ chứng từ không chạm được; không có badge |
| B10 | SCR-009 gõ `glove` | còn một kết quả "Găng tay khám Nitrile"; chạm → mở editor (một đơn vị) |
| B11 | SCR-009 chạm "Amox 500" | hiện 3 lựa chọn Hộp / Vỉ / Viên; sau khi đã lưu Amox / Hộp thì Hộp có `'Đã có trong lần nhận'` |
| B12 | SCR-009 gõ `zzz` | thấy `'Sản phẩm chưa có trong danh mục…'` |
| B13 | SCR-084 Từ chối = 5 | thấy `'Không vào tồn'` |
| B14 | SCR-084 HSD `13/2026` cách ghi Tháng/năm | thấy `'Hạn dùng không đúng định dạng'` |
| B15 | SCR-084 dòng đã có → `'Xóa khỏi lần nhận'` → `'Xóa'` | dòng biến mất khỏi session |
| B16 | SCR-010 mọi dòng chỉ có Từ chối | banner `'Chưa có hàng vào tồn'`; nút `'Gửi phê duyệt'` tắt |
| B17 | SCR-010 dòng LOT | thấy `'Lô L2407-A'` và `'HSD 07/2028'` |
| B18 | SCR-011 | subtitle có `'Nguyễn Văn An gửi'`; banner `'Lý do cần duyệt'`; nút `'Duyệt'` |
| B19 | SCR-012 sau khi duyệt | `'Đã ghi nhận hàng'`, `'Kết quả theo dòng hàng'`, `'Đang chờ xác nhận giá'` |

## 5. Kiểm tra

- [ ] `cd apps/erp && dart analyze lib/features/inventory test/features/inventory lib/core/router` = 0 lỗi
- [ ] `flutter test test/features/inventory` xanh, có B1–B19
- [ ] `grep -rn "toStringAsFixed(0)\|receipt_product_uom_sheet\|Quản lý theo lô\|Colors.grey\|notes" apps/erp/lib/features/inventory` không còn kết quả liên quan BJ-02
- [ ] Đối chiếu prototype: mở `specs/themes/theme-07/03.design/prototype/html/index.html?uif=UIF-02&flow=quick` và đi từng màn 006 → 008 → 009 → 084 → 010 → 011 → 012, so câu chữ và thứ tự khối
- [ ] Thử tay (hai tài khoản như T7-0): Home → Bắt đầu việc mới → Nhập hàng nhanh vào thẳng SCR-008 → tìm `amox` → Hộp → lô `L2407-A` HSD `08/2028` (thấy lỗi lô đã có) → sửa `07/2028` → Xong → gửi → tài khoản khác duyệt → SCR-012

## 6. Rủi ro / lưu ý

- Đổi `DateTime?` → `LotDate?` chạm model, seed, rules, test cùng lúc — làm trọn trong PR 1.
- `context.go(...)` từ SCR-010 về 008 / 009 chỉ giữ session khi các route nằm **cùng ShellRoute** (đang đúng). Đừng tách route ra ngoài shell.
- Thẻ "Nhận theo chứng từ" disabled là tạm thời; T7-0d mở lại khi có SCR-007.
- VAppBar SCR-006: spec ghi `showBackButton=false` (màn gốc của module), nhưng v3.7.0 yêu cầu Back rõ về Kho khi vào từ Home — plan giữ Back theo v3.7.0.

## 7. Review

- **Ngày:** 2026-10-14. Code vẫn **chưa commit** — review trên working tree.
- **Kết quả: ✅ đạt, kèm 2 việc sửa chuyển sang [T7-0c](T7-0c-trang-thai-chung-va-doi-soat.md) bước 0 (theo yêu cầu 2026-10-14): G1 (bắt buộc) và G2.**
- **Đã kiểm:**
  - `dart analyze lib/features/inventory test/features/inventory lib/core/router lib/core/di` → No issues found.
  - `flutter test test/features/inventory` → 50 test xanh, đủ B1–B19.
  - Lệnh `grep` mục 5 → sạch.
  - PR 1 đúng plan: 3 góp ý T7-0 (Home chỉ mở route có thật, màn kết quả bỏ câu cũ, duyệt gặp "đã xử lý" thì tải lại); `LotDate` + `clear…Date`; fixture 4 sản phẩm có mã vạch + lô đã có; `lotConflict`; `formatQuantity`, `classificationText`; danh mục tải qua `loadCatalog()`, page 008 / 009 không còn repository.
  - PR 2 đúng plan về câu chữ và bố cục: SCR-006 (thứ tự, thẻ chứng từ disabled + lý do, không badge), SCR-008 (một section, kho / ngày disabled, khối "Xác nhận quyền sở hữu", Sticky Footer), SCR-009 (tìm trên màn, một đơn vị vào thẳng editor, chọn đơn vị trực tiếp + "Đã có trong lần nhận", thẻ dòng hai dòng chữ), SCR-084 (args `readOnly`, cách ghi HSD / NSX, "Không vào tồn", xoá có xác nhận, "Xong"), SCR-010 (3 banner, "Sửa", `ReceiptLineSummary`, xem lại chỉ đọc), SCR-011 (subtitle người gửi, lý do cần duyệt, xem chứng từ, thông tin yêu cầu, "Duyệt" / "Từ chối"), SCR-012 (`VIcons.success`, kết quả theo dòng, banner chờ xác nhận giá + "Xác lập giá trị").
- **Cần sửa:**
  - **G1 — Xoá lô ở giữa làm thẻ lô còn lại hiện sai dữ liệu.** `goods_receipt_item_detail_page.dart` dựng các `ReceiptLotEditorCard` trong vòng `for` **không có `key`**; thẻ lô giờ là `StatefulWidget` giữ `_expiryController`, `_manufactureController`, `_expiryPrecision`, `_showManufacture` (và `VNumberField` giữ ô số của nó). Xoá lô 1 trong [A, B] → Flutter dùng lại `State` của thẻ A cho lô B: mã lô được đồng bộ trong `didUpdateWidget`, nhưng **HSD / NSX / cách ghi vẫn là của A**; người dùng sửa HSD lúc này sẽ ghi đè sai vào B. Sửa:
    ```dart
    // _GoodsReceiptItemDetailPageState
    late List<Key> _lotKeys = List.generate(_lots.length, (_) => UniqueKey());
    // _addNewLot: thêm _lotKeys.add(UniqueKey());
    // _deleteLot: thêm _lotKeys.removeAt(index);
    // trong vòng for: ReceiptLotEditorCard(key: _lotKeys[index], …)
    ```
    (khởi tạo `_lotKeys` sau khi gán `_lots` trong `initState`). Thêm test **B20**: hai lô A (HSD `07/2028`) và B (HSD `09/2029`), xoá A → thẻ còn lại hiện `09/2029`.
  - **G2 — "Sửa" ở SCR-010 xoá lịch sử điều hướng** (lỗi do plan bước 4.6 của tôi). `context.go('/warehouse/receipts/quick/header' | '/items')` dựng lại cả stack: session vẫn giữ (cùng ShellRoute), nhưng Home không còn phía sau — ở SCR-008 không còn nút Back về Kho. Sửa theo đúng thứ tự stack của luồng (Home → 008 → 009 → 010):
    - `Sửa` hàng thực nhận → `context.pop()`;
    - `Sửa` thông tin lần nhận → `context.pop(); context.pop();`.
- **Không chặn:** `goods_receipt_result_page.dart:84` câu `'Mã phiếu không tồn tại hoặc đã bị xóa.'` → nên là `'Lần nhận hàng không tồn tại hoặc đã bị xoá.'` (không nói "mã phiếu" với người dùng).
- **Việc tiếp:** commit T7-0 + T7-0b, rồi làm T7-0c (bước 0 là G1, G2).
