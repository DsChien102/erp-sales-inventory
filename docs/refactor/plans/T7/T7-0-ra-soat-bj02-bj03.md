# T7-0 — Sửa lỗi dữ liệu và luồng phê duyệt BJ-02 / BJ-03

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7. Inventory" (đợt 0). Ước lượng: **~2 ngày, 2 PR**.
> Đối chiếu: `specs/themes/theme-07/03.design/screens` SCR-008, 009, 084, 010, 011, 012, 014; review code ngày 2026-10-14 (mục 2).
> Ngoài plan này: màn / trạng thái còn thiếu → **T7-0b**; kiến trúc + Design System còn lại → **T7-0c** (mục 8). Viết sau khi T7-0 xong.

Đường dẫn trong plan tính từ `apps/erp/lib/features/inventory/` nếu không ghi khác.

## 1. Mục tiêu

Sau T7-0:

- Không còn mất dữ liệu hay bịa dữ liệu khi nhập hàng nhanh (thêm trùng, dòng chưa xong, HSD tự điền, mã lô rỗng, số âm, phiếu trùng ID).
- BJ-03 không xác lập giá trị được hai lần; phiếu nhập nhanh đã duyệt xuất hiện bên BJ-03.
- Luồng phê duyệt đúng vai: người lập gửi xong thấy màn **chờ duyệt** + `Về Kho`; người lập **không** tự duyệt được; chỉ người khác duyệt.

Vẫn chạy trên fixture (UI trước, backend sau).

## 2. Kết quả review (tóm tắt)

| # | Vấn đề | Sửa ở |
|---|---|---|
| R2 | Người lập tự duyệt được phiếu của mình (nút "Xem xét & Duyệt phiếu ngay"; `approve()` không kiểm người duyệt; tên người duyệt hard-code) | PR 2 · bước 2.1–2.5 |
| R3 | Gửi xong đi sang SCR-012 thay vì ở lại SCR-010 chế độ chờ duyệt | PR 2 · bước 2.3 |
| R4 | Thêm trùng Product + UOM ghi đè dòng đã nhập | PR 1 · bước 1.4 |
| R5 | Dòng chưa xong bị bỏ âm thầm khi gửi; Back khỏi editor để lại dòng rỗng | PR 1 · bước 1.3, 1.4 |
| R6 | HSD / NSX tự điền hôm nay / +365 ngày | PR 1 · bước 1.5 |
| R7 | Mã lô bắt buộc nhưng không kiểm, không kiểm trùng | PR 1 · bước 1.2, 1.5 |
| R8 | Ô số lượng nhận số âm | PR 1 · bước 1.6 |
| R9 | Phiếu toàn bộ "Từ chối" vẫn gửi được | PR 1 · bước 1.3 |
| R10 | BJ-03 xác lập giá trị được hai lần (hai instance `ValuationRepository`) | PR 1 · bước 1.1 |
| R11 | Nút sang BJ-03 mở phiếu không tồn tại | PR 2 · bước 2.6 |
| R12 | SCR-008: chứng từ giao nhận bắt buộc nhưng cho bỏ trống / tên file giả; ngày nhận chọn tự do | PR 1 · bước 1.7 |
| R13 | ID `REC-YYMMDD-01` cố định; `getReceiptById` trả fixture cho id bất kỳ | PR 1 · bước 1.1 |
| Q3 | Controller mã lô tạo mới mỗi lần `build` | PR 1 · bước 1.6 |
| Q4 | `status` của phiếu là `String` | PR 1 · bước 1.1 |
| Q5 | Map `static` trong repository rò dữ liệu giữa các test | PR 1 · bước 1.1 |

R1 (chữ `th` ở dòng 1) đã sửa trước review. Danh sách đầy đủ 🟠 / 🟡 còn lại nằm ở mục 8.

## 3. Quyết định dùng trong plan

**Người dùng hiện tại = phiên đăng nhập thật** (thay gợi ý "tham số kịch bản" của quyết định 4 trong PLAN.md, chỉ cho phần danh tính):

- `id` = `SessionStore.userId`, `tên` = `AccountRepository.getMyAccount().fullName`.
- Lý do: kiểm tra "người lập ≠ người duyệt" cần hai người thật; dùng phiên thật thì không phải thêm công tắc debug vào app. Thử tay bằng hai tài khoản trong cùng tổ chức (Owner + nhân viên đã mời) — dữ liệu fixture vẫn còn khi đăng xuất / đăng nhập lại vì repository là singleton.
- Test không đụng phiên: truyền `actorLoader` giả.

Nếu bạn muốn giữ tham số kịch bản thì báo, tôi sửa bước 2.1.

## 4. PR 1 — Dữ liệu

### 1.1 Repository dùng chung, ID, trạng thái (R10, R13, Q4, Q5)

**`core/di/injection.dart`** (đường dẫn `apps/erp/lib/core/di/injection.dart`): thêm vào chuỗi `getIt..registerLazySingleton` (cạnh `PartnerRepository`, khoảng dòng 100):

```dart
..registerLazySingleton<ValuationRepository>(() => ValuationRepository())
..registerLazySingleton<GoodsReceiptRepository>(
  () => GoodsReceiptRepository(valuation: getIt<ValuationRepository>()),
)
```

Thay **mọi** chỗ `GoodsReceiptRepository()` / `ValuationRepository()` bằng `getIt<…>()`:

| File | Dòng hiện tại |
|---|---|
| `presentation/pages/quick_receipt_header_page.dart` | 21 |
| `presentation/pages/goods_receipt_items_page.dart` | 21 |
| `presentation/pages/goods_receipt_result_page.dart` | 21 |
| `presentation/pages/goods_receipt_approval_page.dart` | 24 |
| `presentation/pages/valuation_queue_page.dart` | 18 |
| `core/router/app_router.dart` | ShellRoute valuation (khoảng dòng 268) và ShellRoute quick receipt: `QuickReceiptSessionCubit(repository: getIt<GoodsReceiptRepository>(), actorLoader: …)` (bước 2.1) |

`QuickReceiptSessionCubit`: bỏ `repository ?? GoodsReceiptRepository()`, đổi thành `required GoodsReceiptRepository repository`.

**`data/models/receipt_document_model.dart`**: thêm enum, đổi `status`:

```dart
enum ReceiptStatus { pendingApproval, completed, rejected }
```

`final ReceiptStatus status;` — sửa mọi chỗ so sánh chuỗi `'PENDING_APPROVAL'`, `'COMPLETED'`, `'REJECTED'` (repository, `goods_receipt_approval_page.dart:110`, `goods_receipt_result_page.dart:61-62, 172, 182`, test).

**`data/goods_receipt_repository.dart`**:

1. `static final Map<String, ReceiptDocumentModel> _inMemoryReceipts` → field thường `final Map<String, ReceiptDocumentModel> _receipts = {};`.
2. Constructor nhận `ValuationRepository? valuation` (dùng ở bước 2.6) và gọi `_seed()`: chuyển phiếu fixture đang nằm trong nhánh "không tìm thấy" của `getReceiptById` (Amox 500, lô `L2407-A`) vào `_receipts['REC-240715-01']` — Home đang mở đúng id này. Đặt `submittedById: 'fixture-maker'`, `submittedByName: 'Nguyễn Văn An'` để ai đăng nhập cũng duyệt được phiếu mẫu.
3. `getReceiptById(id)` chỉ còn `return _receipts[id];` (trả `null` khi không có).
4. ID tăng dần:

```dart
int _seq = 0;

String _nextId(DateTime now) {
  _seq++;
  String two(int v) => v.toString().padLeft(2, '0');
  return 'REC-${two(now.year % 100)}${two(now.month)}${two(now.day)}-${two(_seq)}';
}
```

### 1.2 Luật kiểm tra dòng hàng (R7, R8, R9 — hàm thuần)

Tạo **`logic/receipt_rules.dart`**:

```dart
import '../data/models/receipt_item_draft.dart';

enum LotIssue {
  emptyQuantity,          // Nhập ít nhất một số lượng
  negativeQuantity,       // Số lượng không được âm
  missingLotCode,         // Nhập số lô
  duplicateLotCode,       // Số lô bị trùng trong mặt hàng này
  missingExpiry,          // Nhập hạn dùng
  expiryNotAfterManufacture, // Hạn dùng phải sau ngày sản xuất
}

class ReceiptItemValidation {
  const ReceiptItemValidation(this.lotIssues);

  /// Cùng thứ tự với item.lots.
  final List<Set<LotIssue>> lotIssues;

  bool get isValid => lotIssues.isNotEmpty && lotIssues.every((s) => s.isEmpty);
}

ReceiptItemValidation validateReceiptItem(ReceiptItemDraft item) {
  final counts = <String, int>{};
  for (final lot in item.lots) {
    final code = lot.lotCode.trim().toUpperCase();
    if (code.isNotEmpty) counts[code] = (counts[code] ?? 0) + 1;
  }
  return ReceiptItemValidation([
    for (final lot in item.lots)
      <LotIssue>{
        if ([lot.accepted, lot.quarantine, lot.damaged, lot.rejected].any((q) => q < 0))
          LotIssue.negativeQuantity,
        if (lot.totalReceived <= 0) LotIssue.emptyQuantity,
        if (item.isLotTracked && lot.lotCode.trim().isEmpty) LotIssue.missingLotCode,
        if (item.isLotTracked && (counts[lot.lotCode.trim().toUpperCase()] ?? 0) > 1)
          LotIssue.duplicateLotCode,
        if (item.isLotTracked && item.requiresExpiry && lot.expiryDate == null)
          LotIssue.missingExpiry,
        if (lot.expiryDate != null &&
            lot.manufactureDate != null &&
            !lot.expiryDate!.isAfter(lot.manufactureDate!))
          LotIssue.expiryNotAfterManufacture,
      },
  ]);
}

String lotIssueMessage(LotIssue issue) => switch (issue) {
      LotIssue.emptyQuantity => 'Nhập ít nhất một số lượng',
      LotIssue.negativeQuantity => 'Số lượng không được âm',
      LotIssue.missingLotCode => 'Nhập số lô',
      LotIssue.duplicateLotCode => 'Số lô bị trùng trong mặt hàng này',
      LotIssue.missingExpiry => 'Nhập hạn dùng',
      LotIssue.expiryNotAfterManufacture => 'Hạn dùng phải sau ngày sản xuất',
    };
```

**Model** — thêm trường, xoá getter cũ:

| File | Thay đổi |
|---|---|
| `data/goods_receipt_repository.dart` (`ReceiptProductDto`) | thêm `final bool requiresExpiry;` (mặc định `false`). Fixture: Amox 500 `true`, Cefa-Vet 100ml `true`, Bơm kim tiêm `false` |
| `data/models/receipt_item_draft.dart` | thêm `productCode` (String, bắt buộc — dùng ở bước 2.6) và `requiresExpiry` (bool, mặc định `false`), nhớ thêm vào `copyWith` và `props`; **xoá** getter `isComplete` (thay bằng `validateReceiptItem(item).isValid`) |

### 1.3 Session cubit (R4, R5, R9)

**`logic/quick_receipt_session_cubit.dart`**:

```dart
/// Vị trí dòng cùng Product + UOM; -1 nếu chưa có.
int indexOf(String productId, String unitId) => state.items
    .indexWhere((i) => i.productId == productId && i.unitId == unitId);

/// Chỉ gọi khi bấm Xong ở SCR-084. Dòng mới thì thêm, dòng đã có thì thay đúng chỗ.
void saveItem(ReceiptItemDraft item) { /* thân của addOrUpdateItem hiện tại */ }
```

Xoá `addOrUpdateItem` (đổi tên thành `saveItem`). Trong `submitForApproval` gửi **`state.items`** (bỏ `.where((i) => i.isComplete)`).

**`logic/quick_receipt_session_state.dart`**:

```dart
bool get canReview =>
    header.isValid &&
    items.isNotEmpty &&
    items.every((i) => validateReceiptItem(i).isValid) &&
    items.any((i) => i.totalPhysicalStock > 0);
```

### 1.4 Màn Hàng thực nhận — thêm trùng, không để dòng rỗng (R4, R5)

**`presentation/pages/goods_receipt_items_page.dart`**:

1. Thêm `int? _duplicateIndex;` vào `State`.
2. Trong `_addProductFlow`, thay đoạn từ dòng 127 tới hết hàm:

```dart
final cubit = context.read<QuickReceiptSessionCubit>();
final existing = cubit.indexOf(selectedProduct.id, selectedUnit.id);
if (existing >= 0) {
  setState(() => _duplicateIndex = existing);
  return;
}
setState(() => _duplicateIndex = null);
_openItemDetail(
  ReceiptItemDraft(
    productId: selectedProduct.id,
    productName: selectedProduct.name,
    productCode: selectedProduct.code,
    unitId: selectedUnit.id,
    unitName: selectedUnit.name,
    isLotTracked: selectedProduct.isLotTracked,
    requiresExpiry: selectedProduct.requiresExpiry,
    lots: const [ReceiptLotDraft()],
  ),
);
```

   Không gọi cubit trước khi mở editor → Back khỏi editor không để lại dòng.

3. Đầu danh sách (trước các thẻ dòng), khi `_duplicateIndex != null`:

```dart
VBanner(
  status: VBannerStatus.warning,
  title: '${dup.productName} · ${dup.unitName} đã có trong lần nhận',
  description: 'Mở mặt hàng đã có để sửa, không tạo thêm dòng mới.',
  footer: VButton(
    label: 'Mở sản phẩm đã có',
    variant: VButtonVariant.secondary,
    size: VButtonSize.small,
    onPressed: () {
      final index = _duplicateIndex!;
      setState(() => _duplicateIndex = null);
      _openItemDetail(state.items[index]);
    },
  ),
)
```

   (`dup = state.items[_duplicateIndex!]`.) Xoá dòng (`removeItem`) cũng đặt `_duplicateIndex = null`.

4. Chip "Đã kiểm đếm / Chưa hoàn tất" trên thẻ dòng: đổi điều kiện sang `validateReceiptItem(item).isValid` (giao diện thẻ sửa ở T7-0b).

### 1.5 Editor Chi tiết hàng thực nhận (R6, R7)

**`presentation/pages/goods_receipt_item_detail_page.dart`**:

1. `initState`: nếu `widget.item.lots.isEmpty` thì `_lots = [const ReceiptLotDraft()]` — **không** điền NSX / HSD. `_addNewLot` thêm `const ReceiptLotDraft()`.
2. Thêm `bool _showErrors = false;`.
3. Validation:

```dart
final draft = widget.item.copyWith(lots: _lots);
final validation = validateReceiptItem(draft);
```

4. Nút cuối màn luôn bấm được; `_save()`:

```dart
void _save() {
  final draft = widget.item.copyWith(lots: _lots);
  if (!validateReceiptItem(draft).isValid) {
    setState(() => _showErrors = true);
    return;
  }
  context.read<QuickReceiptSessionCubit>().saveItem(draft);
  context.pop();
}
```

5. Truyền cho từng `ReceiptLotEditorCard`: `issues: _showErrors ? validation.lotIssues[index] : const {}`.
6. Hàng không theo lô: ở items page bước 1.4 đã tạo `const ReceiptLotDraft()` (mã lô rỗng) — bỏ hẳn chuỗi `'NO_LOT'` (`goods_receipt_items_page.dart:136`, `goods_receipt_item_detail_page.dart:23`).

### 1.6 Thẻ nhập lô (R7, R8, Q3)

**`presentation/widgets/receipt_lot_editor_card.dart`**:

1. Thêm tham số `final Set<LotIssue> issues;` (mặc định `const {}`).
2. Đổi `ReceiptLotEditorCard` thành `StatefulWidget`; trong `State`:

```dart
late final TextEditingController _lotCodeController =
    TextEditingController(text: widget.lot.lotCode);

@override
void didUpdateWidget(covariant ReceiptLotEditorCard old) {
  super.didUpdateWidget(old);
  if (widget.lot.lotCode != _lotCodeController.text) {
    _lotCodeController.text = widget.lot.lotCode;
  }
}

@override
void dispose() {
  _lotCodeController.dispose();
  super.dispose();
}
```

   Xoá `TextEditingController(text: lot.lotCode)..selection = …` đang tạo trong `build` (dòng 93-96).

3. Lỗi dưới ô: mã lô — `missingLotCode`, `duplicateLotCode`; HSD — `missingExpiry`, `expiryNotAfterManufacture`; dưới nhóm số lượng — `emptyQuantity`. Hiện bằng `VFieldError(lotIssueMessage(issue))` trong `VField(invalid: true, …)` như `valuation_direct_basis_sheet.dart:324-343`.
4. Ô số lượng: thay `_QuantityInputField` (dùng `VTextField`) bằng `VNumberField`:

```dart
VNumberField(
  value: widget.lot.accepted,
  allowNegative: false,
  allowDecimal: false, // UOM hiện tại đều là đơn vị đếm; số lẻ làm ở T7-0c nếu cần
  min: 0,
  textAlign: TextAlign.center,
  onChanged: (v) => widget.onChanged(widget.lot.copyWith(accepted: (v ?? 0).toDouble())),
)
```

   Lặp cho Cách ly / Hỏng / Từ chối. Xoá class `_QuantityInputField`.

### 1.7 Thông tin nhập hàng nhanh (R12)

**`data/models/receipt_header_draft.dart`**:

```dart
bool get isValid =>
    supplierId.isNotEmpty && warehouseId.isNotEmpty && documentFileNames.isNotEmpty;
```

**`presentation/pages/quick_receipt_header_page.dart`**:

1. **Ngày nhận** chỉ đọc: xoá `_pickDate` và `InkWell`; hiển thị như ô "Kho tiếp nhận" (nền `surfaceAlt`, không icon lịch). Giá trị lấy từ `header.receiptDate` (cubit đặt ngày hôm nay khi tạo session).
2. **Chứng từ giao nhận** bắt buộc: thay nút "Thêm tệp" + `_addMockDocument` bằng:

```dart
Future<void> _pickDocuments(ReceiptHeaderDraft header) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    allowMultiple: true,
  );
  if (result == null || !mounted) return;
  context.read<QuickReceiptSessionCubit>().updateHeader(
        header.copyWith(
          documentFileNames: [...header.documentFileNames, ...result.files.map((f) => f.name)],
        ),
      );
}
```

   (Cùng cách gọi `FilePicker.pickFiles` ở `features/catalog/presentation/bloc/product_images_maintenance_cubit.dart:226`. Chỉ giữ tên tệp — fixture, chưa tải lên.)

   Vùng chọn tệp:

```dart
VFileDropZone(
  title: 'Chứng từ giao nhận',
  subtitle: 'Phiếu giao hàng, biên bản, vận đơn hoặc ảnh chụp (PDF, JPG, PNG)',
  state: header.documentFileNames.isEmpty
      ? (_triedContinue ? VFileDropZoneState.invalid : VFileDropZoneState.empty)
      : VFileDropZoneState.valid,
  onTap: () => _pickDocuments(header),
)
```

   Danh sách tệp đã chọn + nút xoá giữ như hiện tại. Nhãn trường có dấu bắt buộc.

3. Nút tiếp tục: luôn bấm được; nếu `!header.isValid` thì `setState(() => _triedContinue = true)` và hiện lỗi `Chọn nhà cung cấp trong danh sách.` dưới ô nhà cung cấp khi chưa chọn; hợp lệ mới `context.push('/warehouse/receipts/quick/items')`.

## 5. PR 2 — Luồng phê duyệt đúng vai

### 2.1 Người dùng hiện tại

Tạo **`data/models/receipt_actor.dart`**:

```dart
class ReceiptActor {
  const ReceiptActor({required this.id, required this.name});
  final String id;
  final String name;
}

typedef ReceiptActorLoader = Future<ReceiptActor> Function();
```

Tạo **`data/current_receipt_actor.dart`**:

```dart
Future<ReceiptActor> currentReceiptActor() async {
  final id = getIt<SessionStore>().userId ?? '';
  final account = await getIt<AccountRepository>().getMyAccount();
  return ReceiptActor(id: id, name: account.fullName);
}
```

Router truyền `actorLoader: currentReceiptActor` cho `QuickReceiptSessionCubit` (ShellRoute quick receipt) và `ReceiptApprovalCubit` (trong `GoodsReceiptApprovalPage`). Test truyền hàm giả.

### 2.2 Model + repository

**`data/models/receipt_document_model.dart`**: thay `submittedBy`, `approvedBy`, `approvedAt` bằng:

```dart
final String submittedById;
final String submittedByName;
final DateTime submittedAt;
final String? decidedById;
final String? decidedByName;
final DateTime? decidedAt;
final String? rejectReason;
```

**`data/goods_receipt_repository.dart`** — chữ ký mới, kiểm tra như máy chủ sẽ kiểm:

```dart
Future<ReceiptDocumentModel> submitQuickReceipt(
  ReceiptHeaderDraft header,
  List<ReceiptItemDraft> items, {
  required ReceiptActor maker,
});

Future<ReceiptDocumentModel> approveReceipt(String id, {required ReceiptActor approver});

Future<ReceiptDocumentModel> rejectReceipt(
  String id, {
  required ReceiptActor approver,
  required String reason,
});
```

Trong `approveReceipt` / `rejectReceipt`, trước khi đổi trạng thái:

```dart
final doc = _receipts[id];
if (doc == null) throw const AppException(AppErrorCode.notFound);
if (doc.status != ReceiptStatus.pendingApproval) {
  throw const AppException('APPROVAL_ALREADY_DECIDED');
}
if (doc.submittedById == approver.id) {
  throw const AppException('SELF_APPROVAL_NOT_ALLOWED');
}
```

Câu hiển thị dùng `userMessage` với override (không sửa `core/errors`):

```dart
const receiptErrorMessages = {
  'APPROVAL_ALREADY_DECIDED': 'Yêu cầu này đã được xử lý trước đó.',
  'SELF_APPROVAL_NOT_ALLOWED': 'Bạn đã gửi yêu cầu này nên không thể tự duyệt.',
};
```

(đặt trong `logic/receipt_rules.dart`).

### 2.3 Gửi xong ở lại màn rà soát, chế độ chờ duyệt (R3)

**`logic/quick_receipt_session_cubit.dart`**: constructor nhận `required ReceiptActorLoader actorLoader`; `submitForApproval`:

```dart
final maker = await _actorLoader();
final doc = await _repository.submitQuickReceipt(state.header, state.items, maker: maker);
emit(state.copyWith(isSubmitting: false, submittedDocument: doc));
```

Lỗi: `errorMessage: AppException.from(e).userMessage(receiptErrorMessages)` (không `e.toString()`).

**`presentation/pages/goods_receipt_review_page.dart`**:

1. Nút gửi: chỉ gọi `cubit.submitForApproval()`; **xoá** `context.go('/warehouse/receipts/result/${doc.id}')`.
2. Khi `state.submittedDocument != null` (chế độ `PENDING_APPROVAL`):
   - đầu màn: `VBanner(status: VBannerStatus.info, title: 'Đã gửi yêu cầu phê duyệt', description: 'Lần nhận hàng đang chờ người phê duyệt. Tồn kho chưa thay đổi.')`;
   - nội dung giữ phần tóm tắt, ẩn mọi nút sửa / gửi;
   - nút cuối màn duy nhất `Về Kho` → `context.go('/inventory')`;
   - nút Back trên app bar: `VAppBar(leading: VButton.icon(icon: VIcons.chevronLeft, semanticLabel: 'Về Kho', variant: VButtonVariant.tertiary, onPressed: () => context.go('/inventory')))`;
   - Back hệ thống: bọc `Scaffold` bằng `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/inventory'); })`.
3. Listener lỗi: chỉ hiện khi lỗi **đổi** — `listenWhen: (prev, curr) => curr.errorMessage != null && curr.errorMessage != prev.errorMessage`; hiện bằng `VToast.show(context, title: 'Chưa gửi được', message: …, type: VToastType.danger)` thay `SnackBar`.

### 2.4 Màn phê duyệt chặn tự duyệt (R2)

**`logic/receipt_approval_state.dart`** — `ReceiptApprovalLoaded` thêm:

```dart
final ReceiptActor actor;
final String? actionError;

bool get isSelfApproval => document.submittedById == actor.id;
bool get isDecided => document.status != ReceiptStatus.pendingApproval;
bool get canDecide => !isSelfApproval && !isDecided;
```

**`logic/receipt_approval_cubit.dart`**:

- constructor nhận `required ReceiptActorLoader actorLoader`;
- `load(id)`: lấy `actor` + `document`; `null` → `ReceiptApprovalError('Không tìm thấy yêu cầu nhận hàng.')`;
- `approve()` / `reject(reason)`: **bỏ** tham số `approverName`, dùng `current.actor`; khi lỗi **giữ** `Loaded` và đặt `actionError: AppException.from(e).userMessage(receiptErrorMessages)` thay vì chuyển sang `ReceiptApprovalError`.

**`presentation/pages/goods_receipt_approval_page.dart`**:

- xoá `approverName: 'Quản Lý Kho'` (dòng 48);
- `isSelfApproval` → `VBanner(status: VBannerStatus.warning, title: 'Bạn không thể tự duyệt', description: 'Bạn đã gửi yêu cầu này. Cần một người khác có quyền phê duyệt.')`, **ẩn** footer Duyệt / Từ chối;
- `isDecided` → `VBanner(status: VBannerStatus.info, title: 'Yêu cầu đã được xử lý')`, ẩn footer;
- `actionError` → `VBanner(status: VBannerStatus.error, …)` phía trên footer, footer vẫn còn để thử lại;
- "Người tạo" → `Người gửi: ${doc.submittedByName}`.

### 2.5 Màn kết quả: bỏ đường tự duyệt (R2)

**`presentation/pages/goods_receipt_result_page.dart`**:

- xoá khối `if (doc != null && doc.status == 'PENDING_APPROVAL') VButton('Xem xét & Duyệt phiếu ngay', …)` (dòng 172-181) và nhánh tiêu đề / mô tả "Đã gửi yêu cầu phê duyệt" — người lập không còn tới màn này khi phiếu đang chờ;
- `doc == null` → `VEmptyState` "Không tìm thấy lần nhận hàng" + `Về Kho`.

### 2.6 Nối BJ-02 → BJ-03 (R11)

**`data/valuation_repository.dart`** thêm:

```dart
/// Fixture thay cho backend: phiếu nhập nhanh được duyệt → thêm mục chờ xác lập giá trị.
void addQuickReceipt(ReceiptDocumentModel doc) {
  _receipts[doc.id] = ReceiptValuationData(
    id: doc.id,
    receiptNumber: doc.id,
    supplierName: doc.header.supplierName,
    receivedAt: _formatDate(doc.header.receiptDate), // dd/MM/yyyy, chép hàm `_formatDate` như ở các page
    entryType: ValuationEntryType.quick,
    groups: [
      for (final item in doc.items)
        if (item.totalPhysicalStock > 0)
          ValuationGroupItem(
            id: '${doc.id}-${item.productId}-${item.unitId}',
            productId: item.productId,
            productName: item.productName,
            productCode: item.productCode,
            uom: item.unitName,
            tracking: item.isLotTracked ? 'LOT' : 'NONE',
            pendingQty: item.totalPhysicalStock,
            lotsCount: item.isLotTracked ? item.lots.length : 0,
            status: ValuationGroupStatus.directMissing,
            sources: const [],
          ),
    ],
  );
}
```

`GoodsReceiptRepository.approveReceipt`: sau khi đổi sang `completed`, gọi `_valuation?.addQuickReceipt(approved)`.

`goods_receipt_result_page.dart`: nút "Xác lập giá trị hàng nhận ngay" giữ nguyên route `/warehouse/valuation/receipt/${doc.id}` — giờ mở đúng phiếu vì cùng singleton.

### 2.7 Lối vào cho người duyệt

**`presentation/pages/warehouse_home_page.dart`** (dòng ~142): bỏ `if (task.id == 'receipt_01')`; dùng chung cách của mục "Tra cứu":

```dart
onTap: () => task.routePath != null
    ? context.push(task.routePath!)
    : VToast.show(context, title: task.title, message: task.subtitle, type: VToastType.info),
```

**`data/inventory_repository.dart`**: task đầu tiên đổi `routePath: '/warehouse/receipts/approval/REC-240715-01'` (phiếu mẫu ở bước 1.1). Danh sách "Nhận hàng chờ phê duyệt" lấy động từ repository làm ở T7-15.

## 6. Test

Sửa `test/features/inventory/presentation/pages/quick_receipt_flow_test.dart` và `valuation_flow_test.dart` theo chữ ký mới (repository truyền vào, `actorLoader` giả); test widget cần `getIt` thì `setUp` đăng ký `GoodsReceiptRepository` / `ValuationRepository` mới và `tearDown(getIt.reset)`.

Tạo **`test/features/inventory/logic/receipt_rules_test.dart`** và bổ sung test cubit. Danh sách tối thiểu:

| # | Test | Kỳ vọng |
|---|---|---|
| T1 | `validateReceiptItem`: lô theo dõi lô, mã rỗng | `missingLotCode` |
| T2 | hai lô cùng mã `l1` / `L1 ` | cả hai lô có `duplicateLotCode` |
| T3 | `requiresExpiry` và HSD `null` | `missingExpiry` |
| T4 | HSD trước NSX | `expiryNotAfterManufacture` |
| T5 | số lượng -5 | `negativeQuantity` |
| T6 | `canReview` với một dòng hợp lệ + một dòng chưa có số lượng | `false` |
| T7 | `canReview` khi mọi dòng chỉ có Từ chối | `false` |
| T8 | `canReview` khi chưa có chứng từ giao nhận | `false` |
| T9 | `indexOf` sau `saveItem` cùng Product + UOM | trả vị trí cũ; `items.length` không đổi |
| T10 | `submitQuickReceipt` hai lần trong ngày | hai ID khác nhau, cả hai còn trong repository |
| T11 | `getReceiptById('khong-co')` | `null` |
| T12 | `approveReceipt` với approver trùng người gửi | ném `AppException('SELF_APPROVAL_NOT_ALLOWED')`, trạng thái vẫn `pendingApproval` |
| T13 | duyệt lần hai | ném `AppException('APPROVAL_ALREADY_DECIDED')` |
| T14 | duyệt xong → `ValuationRepository.getQueue()` | có phiếu vừa duyệt, nhóm `directMissing` |
| T15 | `confirmValuation` → `getQueue()` trên **cùng** instance | phiếu không còn trong hàng chờ |
| T16 | widget: gửi xong ở màn rà soát | thấy `Đã gửi yêu cầu phê duyệt` và `Về Kho`, không còn nút gửi |
| T17 | widget: màn phê duyệt với actor = người gửi | thấy `Bạn không thể tự duyệt`, không có nút `Phê duyệt` |

## 7. Kiểm tra

- [ ] `cd apps/erp && dart analyze lib/features/inventory test/features/inventory` = 0 lỗi (`flutter analyze` sập do đường dẫn có dấu, không dùng)
- [ ] `flutter test test/features/inventory` xanh, đủ T1–T17
- [ ] `grep -rn "NO_LOT\|'PENDING_APPROVAL'\|'COMPLETED'\|Quản Lý Kho\|GoodsReceiptRepository()\|ValuationRepository()" apps/erp/lib` không còn kết quả (trừ trong `injection.dart`)
- [ ] Thử tay tài khoản A: Kho → Bắt đầu việc mới → Nhập hàng nhanh → chưa chọn chứng từ thì không đi tiếp được → chọn tệp → thêm Amox / Hộp, nhập lô → thêm Amox / Hộp lần nữa thấy cảnh báo + `Mở sản phẩm đã có` → gửi → thấy màn chờ duyệt, Back và `Về Kho` đều về Kho
- [ ] Tài khoản A mở `/warehouse/receipts/approval/<id vừa gửi>`: thấy "Bạn không thể tự duyệt"
- [ ] Đăng nhập tài khoản B cùng tổ chức: duyệt → màn kết quả → `Xác lập giá trị hàng nhận ngay` mở đúng phiếu → thêm căn cứ trực tiếp → xác nhận → về hàng chờ, phiếu không còn

## 8. Ngoài plan này

**T7-0b — Màn và trạng thái còn thiếu của BJ-02/03** (viết sau khi T7-0 review ✅):

- SCR-007 Chứng từ chờ nhận + chế độ document của SCR-009; SCR-013 Đối soát kết quả.
- SCR-006 đúng spec (không badge, thứ tự, tiêu đề); SCR-009 `VSearchBar` trên màn, một UOM đi thẳng editor, nhiều UOM chọn trực tiếp, thẻ dòng hai dòng chữ, xoá có xác nhận; SCR-084 chữ "Không vào tồn", precision HSD DAY / MONTH / YEAR, `Xong` ở Sticky Footer.
- SCR-010 HSD theo lô, `Tổng kiểm nhận` / `Vào tồn vật lý` / `Từ chối không vào tồn`, link `Sửa`, bỏ "Ghi chú"; SCR-011 "Lý do cần duyệt", chứng từ, HSD, tiêu đề không lộ mã; SCR-012 "Kết quả theo dòng hàng", `VEmptyState` + `VIcons.success`, `VALUATION_PENDING_RESULT`.
- SCR-015 form: Tiền tệ, không chọn sẵn "Cách hiểu giá", giả định thuế không thu hồi; SCR-014 nhãn "Cần bổ sung căn cứ", `FINANCIAL_MASKED`.
- Bảng "trạng thái → nhánh dựng → test" cho 58 + 21 trạng thái.

**T7-0c — Kiến trúc và Design System BJ-02/03:**

- Header / items / result page tải dữ liệu qua Cubit, lỗi qua `AppException` + `VToast`.
- `VDatePicker`, `VSelect` thay thành phần tự dựng; token màu thay `Colors.grey.shade600`; bỏ chấm màu và `VChip` làm nhãn trạng thái.
- Widget dùng chung `inventory_list_row` / `inventory_key_value_row` (T7-1) thay `_KeyValueRow` và các tile riêng.
- Tiền BJ-03 sang số nguyên đồng; định dạng số lượng không làm tròn số lẻ; `copyWith` xoá được trường nullable.

## 9. Rủi ro / lưu ý

- Đổi chữ ký `submitQuickReceipt`, `approve`, `reject` và model `ReceiptDocumentModel` làm vỡ test hiện có — sửa test cùng PR, đừng tách.
- Thử tay bước 2.x cần **hai tài khoản** cùng tổ chức. Nếu chưa có tài khoản thứ hai: mời qua màn Thành viên (P2 đã xong) hoặc dùng phiếu mẫu `REC-240715-01` (người gửi là `fixture-maker`) để thử nhánh duyệt.
- `getIt` trong widget test: luôn `getIt.reset()` ở `tearDown`, nếu không test sau dùng lại repository của test trước.

## 10. Review

- **Ngày:** 2026-10-14. Code **chưa commit** (thư mục `features/inventory/` và `test/features/inventory/` còn untracked; `injection.dart`, `app_router.dart` modified) — review trên working tree.
- **Kết quả: ✅ đạt.**
- **Đã kiểm:**
  - `dart analyze lib/features/inventory test/features/inventory lib/core/di lib/core/router` → No issues found.
  - `flutter test test/features/inventory` → 32 test xanh (trước T7-0: 14); đủ T1–T17.
  - Lệnh `grep` ở mục 7 → không còn `NO_LOT`, chuỗi trạng thái, `'Quản Lý Kho'`, `…Repository()` ngoài `injection.dart`, `addOrUpdateItem`, `receipt_01`.
  - Đối chiếu từng bước 1.1–1.7, 2.1–2.7 với code: đúng plan. Repository dùng chung qua `getIt`; ID tăng dần; `ReceiptStatus` enum; `receipt_rules.dart` đúng bản plan; `indexOf` / `saveItem` + banner trùng; editor không tự điền HSD, báo lỗi khi lưu; thẻ lô `StatefulWidget` + `VNumberField(allowNegative: false)`; SCR-008 chứng từ bắt buộc + ngày chỉ đọc; `currentReceiptActor` từ phiên; repository chặn tự duyệt / duyệt lần hai; màn rà soát ở lại chế độ chờ duyệt (`PopScope` + `leading` + `Về Kho`); màn duyệt có banner tự duyệt / đã xử lý / lỗi và giữ footer khi lỗi; `addQuickReceipt` nối sang BJ-03.
  - Chưa kiểm tay trên thiết bị (cần hai tài khoản) — **bạn chạy mục 7 phần "Thử tay"** khi tiện.
- **Góp ý (không chặn, chuyển vào T7-0b bước 0):**
  1. **Lỗi do plan bước 2.7** (tôi bỏ sót): Home giờ mở `task.routePath` cho mọi việc, nhưng hai việc `SO-260827-21` (`/warehouse/picks/…`) và `KK-0709-03` (`/warehouse/counts/…`) trỏ tới route chưa đăng ký → GoRouter hiện trang lỗi thay vì toast như trước. Các mục Tra cứu `/warehouse/stock`, `/warehouse/reports`, `/warehouse/catalog` và 3 thao tác "Bắt đầu việc mới" cũng vậy (có từ trước T7-0).
  2. `goods_receipt_result_page.dart:103-125` còn nhánh tiêu đề / mô tả "Đã gửi yêu cầu phê duyệt … chuyển tới Quản lý kho" cho trạng thái chờ duyệt — người lập không còn tới đây, nhưng mở URL trực tiếp vẫn thấy câu cũ.
  3. Duyệt bị lỗi `APPROVAL_ALREADY_DECIDED` thì màn vẫn giữ document cũ (còn footer Duyệt / Từ chối) — nên tải lại phiếu khi gặp mã này để hiện banner "Yêu cầu đã được xử lý".
- **Việc tiếp:** commit T7-0 (gợi ý message `feat(inventory): T7-0 sửa lỗi dữ liệu và luồng phê duyệt BJ-02/03`) trước khi làm T7-0b.
