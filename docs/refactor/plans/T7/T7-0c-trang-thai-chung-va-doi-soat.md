# T7-0c — Sửa còn lại của T7-0b, trạng thái chung BJ-02 và màn Đối soát (SCR-013)

> Theme: Theme 7 Inventory · Trạng thái: Plan ✅ | Làm ✅ | Review ✅
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7. Inventory" (đợt 0). Ước lượng: **~1,5–2 ngày, 2 PR**. Làm sau [T7-0b](T7-0b-nhap-nhanh-dung-spec.md) (✅).
> Đối chiếu: Screen Contract SCR-006, 008, 009, 010, 011, 012, 013; UC-02-02 (EF-B, EF-C), UC-02-04 (EF-A, EF-B), UC-02-05; câu chữ lấy từ prototype v4.6.8 (`index.html?uif=UIF-02&flow=quick&screen=…&state=…`, trích 2026-10-14).

Đường dẫn tính từ `apps/erp/lib/features/inventory/` nếu không ghi khác. Viết tắt: `VButton('X')` = `VButton(label: 'X', …)`. Câu trong ngoặc kép là câu hiển thị, chép nguyên văn.

## 1. Mục tiêu

1. Sửa 2 lỗi còn lại từ review T7-0b (G1 xoá lô hiện sai dữ liệu, G2 "Sửa" xoá lịch sử điều hướng).
2. Luồng nhập hàng nhanh có đủ **trạng thái chung** của Screen Contract — không có quyền, kho bị khoá, dữ liệu vừa thay đổi, chưa có người duyệt, đang ghi nhận, chưa rõ kết quả, bị chặn khi ghi nhận — ép được bằng **kịch bản** của repository fixture, mỗi trạng thái có test.
3. Có màn **Đối soát kết quả nhận hàng (SCR-013)**: kết quả `UNKNOWN` không bao giờ bị làm lại mà được xác minh trên cùng lần nhận.

## 2. Phạm vi

| Trong T7-0c | Không trong T7-0c |
|---|---|
| G1, G2, câu "Mã phiếu" (bước 0) | Nhận theo chứng từ (SCR-007, chế độ document) → T7-0d |
| Kịch bản fixture `ReceiptScenario` + trạng thái chung cho SCR-006, 008, 009, 084, 010, 011, 012 | BJ-03 → T7-0e |
| SCR-013 + nối từ SCR-012 | "Xem hỗ trợ xử lý" (chuyển BJ-17) → T7-11; ở T7-0c **ẩn** nút này |
| Bảng "trạng thái → nhánh dựng → test" cho nhập nhanh | |

Trạng thái **không áp dụng** cho nhập nhanh (ghi vào bảng mục 6, không dựng): SCR-009 `EMPTY`, `READ_ONLY` (chỉ có ở nhận theo chứng từ — T7-0d); SCR-010 / 011 `FINANCIAL_MASKED` (nhập nhanh không hiện tiền); SCR-084 `PERMISSION_DENIED` (đã chặn từ SCR-006 / 008, không vào được editor).

## 3. PR 1 — Bước 0 và nền trạng thái

### 3.0 Sửa còn lại của T7-0b

**G1 — key cho thẻ lô** (`presentation/pages/goods_receipt_item_detail_page.dart`):

```dart
late List<ReceiptLotDraft> _lots;
late List<Key> _lotKeys;

@override
void initState() {
  super.initState();
  _lots = widget.item.lots.isEmpty ? [const ReceiptLotDraft()] : List.from(widget.item.lots);
  _lotKeys = List.generate(_lots.length, (_) => UniqueKey());
}

void _addNewLot() => setState(() {
      _lots.add(const ReceiptLotDraft());
      _lotKeys.add(UniqueKey());
    });

void _deleteLot(int index) {
  if (_lots.length <= 1) return;
  setState(() {
    _lots.removeAt(index);
    _lotKeys.removeAt(index);
  });
}
```

Trong vòng `for` dựng thẻ: `ReceiptLotEditorCard(key: _lotKeys[index], …)`.

**G2 — "Sửa" ở SCR-010 không dựng lại stack** (`presentation/pages/goods_receipt_review_page.dart`). Luồng luôn là Home → 008 → 009 → 010:

- `Sửa` (Hàng thực nhận): thay `context.go('/warehouse/receipts/quick/items')` bằng `context.pop()`;
- `Sửa` (Thông tin lần nhận): thay `context.go('/warehouse/receipts/quick/header')` bằng `context.pop(); context.pop();`.

**Câu không tìm thấy** (`presentation/pages/goods_receipt_result_page.dart`): `'Mã phiếu không tồn tại hoặc đã bị xóa.'` → `'Lần nhận hàng không tồn tại hoặc đã bị xoá.'`.

### 3.1 Kịch bản fixture — `data/models/receipt_scenario.dart` (tạo)

```dart
/// Ép trạng thái chung của BJ-02 khi chạy trên fixture. Chỉ test và demo dùng;
/// khi có backend, trạng thái đến từ lỗi RPC thật và enum này bị xoá.
enum ReceiptScenario {
  normal,
  permissionDenied,   // mọi lời gọi ném AppException(noPermission)
  warehouseLocked,    // capability.warehouseLocked = true → chỉ xem
  catalogChanged,     // lần tải danh mục đầu ném stateChanged, lần sau thành công
  approverMissing,    // gửi phê duyệt ném 'APPROVER_CONFIGURATION_MISSING'
  executionProcessing,// duyệt xong → processing; kiểm tra lần 2 → completed
  executionUnknown,   // duyệt xong → executionUnknown; lần xác minh thứ 2 → completed
  executionUnknownStuck, // duyệt xong → executionUnknown; xác minh mãi chưa có kết quả
  executionRejected,  // duyệt xong → executionRejected (tồn không đổi)
}
```

`data/goods_receipt_repository.dart`:

1. Field `ReceiptScenario scenario = ReceiptScenario.normal;` (public, để test / demo đặt).
2. Hàm kiểm tra quyền dùng ở đầu **mọi** phương thức công khai:

```dart
void _guard() {
  if (scenario == ReceiptScenario.permissionDenied) {
    throw const AppException(AppErrorCode.noPermission);
  }
}
```

3. Capability cho SCR-006 / 008 / 009 / 084 — tạo `data/models/receipt_capability.dart`:

```dart
class ReceiptCapability {
  const ReceiptCapability({required this.canQuickReceive, required this.warehouseLocked});
  final bool canQuickReceive;
  final bool warehouseLocked;
}
```

```dart
Future<ReceiptCapability> getCapability() async {
  _guard();
  return ReceiptCapability(
    canQuickReceive: true,
    warehouseLocked: scenario == ReceiptScenario.warehouseLocked,
  );
}
```

4. `catalogChanged` — trong `getProducts()`:

```dart
bool _catalogChangeServed = false;
...
if (scenario == ReceiptScenario.catalogChanged && !_catalogChangeServed) {
  _catalogChangeServed = true;
  throw const AppException(AppErrorCode.stateChanged);
}
```

5. `submitQuickReceipt`: sau `_guard()`, nếu `approverMissing` → `throw const AppException('APPROVER_CONFIGURATION_MISSING');` **trước** khi tạo ID (UC-02-02 EF-B: không tạo phiếu, không cấp `receiptId`).

6. `approveReceipt`: sau khi qua các kiểm tra của T7-0, trạng thái đích theo kịch bản:

```dart
final executed = switch (scenario) {
  ReceiptScenario.executionProcessing => ReceiptStatus.processing,
  ReceiptScenario.executionUnknown || ReceiptScenario.executionUnknownStuck => ReceiptStatus.executionUnknown,
  ReceiptScenario.executionRejected => ReceiptStatus.executionRejected,
  _ => ReceiptStatus.completed,
};
final approved = doc.copyWith(status: executed, decidedById: …, decidedByName: …, decidedAt: DateTime.now());
_receipts[id] = approved;
if (executed == ReceiptStatus.completed) _valuation?.addQuickReceipt(approved);
```

   Chỉ `completed` mới tạo mục chờ xác lập giá trị — đúng UC-02-04: chưa chắc đã ghi tồn thì chưa có hàng để định giá.

7. `ReceiptStatus` (`data/models/receipt_document_model.dart`) thêm 3 giá trị: `processing`, `executionUnknown`, `executionRejected`. Thêm vào `receiptErrorMessages` (`logic/receipt_rules.dart`):

```dart
'APPROVER_CONFIGURATION_MISSING':
    'Chưa thể tạo phiếu. Cần cấu hình người duyệt đủ quyền và phạm vi rồi gửi lại trong phiên hiện tại.',
```

8. Kiểm tra lại kết quả (dùng cho SCR-012 `PROCESSING` và SCR-013) — mô phỏng máy chủ trả bằng chứng theo **cùng** lần nhận:

```dart
final Map<String, int> _checks = {};

/// UC-02-05: hỏi lại kết quả bằng cùng định danh; không tạo thao tác mới.
Future<ReceiptDocumentModel?> checkReceiptResult(String id) async {
  _guard();
  final doc = _receipts[id];
  if (doc == null) return null;
  final n = (_checks[id] ?? 0) + 1;
  _checks[id] = n;
  final resolves = switch (doc.status) {
    ReceiptStatus.processing => n >= 2,
    ReceiptStatus.executionUnknown => scenario != ReceiptScenario.executionUnknownStuck && n >= 2,
    _ => false,
  };
  if (!resolves) return doc;
  final done = doc.copyWith(status: ReceiptStatus.completed, executedAt: DateTime.now());
  _receipts[id] = done;
  _valuation?.addQuickReceipt(done);
  return done;
}
```

   `ReceiptDocumentModel` thêm `final DateTime? executedAt;` (gán `DateTime.now()` khi approve ra `completed`, hoặc khi `checkReceiptResult` chuyển sang `completed`).

### 3.2 Widget trạng thái dùng chung — `presentation/widgets/inventory_state_views.dart` (tạo)

```dart
/// Trang không có quyền (mọi màn BJ-02). Không dựng dữ liệu nghiệp vụ nào.
class InventoryPermissionDenied extends StatelessWidget {
  const InventoryPermissionDenied({super.key});
  // VEmptyState: VEmptyMedia(icon: VIcons.lock),
  // VEmptyTitle('Không có quyền truy cập'),
  // VEmptyDescription('Dữ liệu nghiệp vụ không được tải vào màn hình này. Liên hệ quản trị viên nếu cần cấp quyền.')
}

enum InventoryNotice { conflict, locked, readOnly, validation, stale }

class InventoryNoticeBanner extends StatelessWidget {
  const InventoryNoticeBanner(this.notice, {super.key, this.action});
  final InventoryNotice notice;
  final Widget? action; // vd VButton('Tải lại') — đặt vào VBanner.footer
}
```

| `InventoryNotice` | `VBannerStatus` | Tiêu đề | Mô tả |
|---|---|---|---|
| `conflict` | warning | `'Dữ liệu vừa thay đổi'` | `'Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng.'` |
| `locked` | warning | `'Kho đang được khóa'` | `'Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết.'` |
| `readOnly` | info | `'Chế độ chỉ xem'` | `'Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa.'` |
| `validation` | error | `'Cần kiểm tra dữ liệu'` | `'Dữ liệu đã nhập được giữ lại. Sửa trường được đánh dấu trước khi tiếp tục.'` |
| `stale` | warning | `'Dữ liệu có thể đã cũ'` | `'Làm mới lịch sử trước khi dựa vào trạng thái hiện tại.'` |

(Severity lấy từ bảng state copy trong `app.js` của prototype.)

### 3.3 Session cubit — trạng thái của 008 / 009 / 084 / 010

`logic/quick_receipt_session_state.dart` thêm:

```dart
final bool permissionDenied;   // mặc định false
final bool warehouseLocked;    // mặc định false
final bool catalogConflict;    // mặc định false — catalog vừa đổi, chờ "Tải lại"
final String? submitErrorCode; // mã lỗi của lần gửi gần nhất, vd 'APPROVER_CONFIGURATION_MISSING'
```

(`copyWith` có `clearSubmitErrorCode`.) `canReview` thêm điều kiện `!warehouseLocked`.

`logic/quick_receipt_session_cubit.dart`:

- `loadCatalog()`: gọi `getCapability()` trước rồi tới nhà cung cấp / sản phẩm; `catch`:

```dart
final error = AppException.from(e);
emit(state.copyWith(
  catalogStatus: CatalogStatus.failure,
  permissionDenied: error.isNoPermission,
  catalogConflict: error.isStateChanged,
  errorMessage: error.userMessage(receiptErrorMessages),
));
```

  thành công: `permissionDenied: false, catalogConflict: false, warehouseLocked: capability.warehouseLocked`.

- `submitForApproval()`: `catch` lưu thêm `submitErrorCode: error.code`; `permissionDenied: error.isNoPermission`. Lần gửi mới đặt `clearSubmitErrorCode: true`.

### 3.4 Test PR 1

| # | Test | Kỳ vọng |
|---|---|---|
| C1 | (G1) editor hai lô A HSD `07/2028`, B HSD `09/2029`, xoá A | thẻ còn lại hiện `09/2029` |
| C2 | (G2) widget: đi Home → 008 → 009 → 010, bấm `Sửa` ở Hàng thực nhận | về 009, Back thêm một lần về 008 |
| C3 | `scenario = permissionDenied` → `getCapability()` | ném `AppException` có `isNoPermission` |
| C4 | `catalogChanged` → `getProducts()` hai lần | lần 1 ném `stateChanged`, lần 2 trả danh mục |
| C5 | `approverMissing` → `submitQuickReceipt` | ném `'APPROVER_CONFIGURATION_MISSING'`; số phiếu trong repository **không đổi** |
| C6 | `executionUnknown` → duyệt → `checkReceiptResult` lần 1, lần 2 | lần 1 vẫn `executionUnknown`; lần 2 `completed`, có mục chờ trong `ValuationRepository` |
| C7 | `executionUnknownStuck` → kiểm tra 5 lần | luôn `executionUnknown`; không có mục chờ định giá |
| C8 | `executionRejected` → duyệt | `executionRejected`; không có mục chờ định giá |

## 4. PR 2 — Các màn

### 4.1 SCR-006 — `ReceiptEntryCubit` (tạo) + `pages/receipt_entry_choice_page.dart`

Tạo `logic/receipt_entry_cubit.dart` + state (sealed hoặc enum status như `ValuationQueueState`):

```dart
enum ReceiptEntryStatus { loading, ready, permissionDenied, conflict }

class ReceiptEntryState {
  final ReceiptEntryStatus status;
  final bool warehouseLocked;
}

class ReceiptEntryCubit extends Cubit<ReceiptEntryState> {
  Future<void> load() async { /* getCapability(); noPermission → permissionDenied; stateChanged → conflict */ }
}
```

Page tạo cubit với `getIt<GoodsReceiptRepository>()` và gọi `load()`.

| Trạng thái | Hiển thị |
|---|---|
| `LOADING` | `VLoading` dưới AppBar `'Nhận hàng'` |
| `READY` | như T7-0b |
| `LOCKED` (`warehouseLocked`) | `InventoryNoticeBanner(locked)` trên hai thẻ; thẻ `Nhập hàng nhanh` **disabled** |
| `CONFLICT` | `InventoryNoticeBanner(conflict, action: VButton('Tải lại', onPressed: cubit.load))`; hai thẻ giữ nguyên |
| `PERMISSION_DENIED` | chỉ `InventoryPermissionDenied` (không dựng thẻ) |

### 4.2 SCR-008, SCR-009, SCR-084 — kho khoá, xung đột, không quyền, lỗi nhập

Chung cho 008 và 009 (đọc từ session state):

| Điều kiện | Hiển thị |
|---|---|
| `permissionDenied` | thân màn chỉ `InventoryPermissionDenied`, không footer |
| `catalogConflict` | `InventoryNoticeBanner(conflict, action: VButton('Tải lại', onPressed: cubit.loadCatalog))` đầu màn |
| `warehouseLocked` | `InventoryNoticeBanner(locked)` đầu màn; **chỉ xem**: 008 — trường nhà cung cấp / vùng chọn tệp disabled, ẩn Sticky Footer; 009 — ẩn `VSearchBar` và danh sách kết quả, thẻ dòng vẫn mở được nhưng editor mở `readOnly: true`, nút `Rà soát` disabled |

**SCR-008 `VALIDATION_ERROR`:** khi `_triedContinue && !header.isValid` → thêm `InventoryNoticeBanner(validation)` đầu màn (lỗi theo trường của T7-0 giữ nguyên).

**SCR-009 `VALIDATION_ERROR`:** nút `Rà soát` bật khi `items.isNotEmpty && !warehouseLocked` (không còn bắt buộc `canReview`); bấm khi `!state.canReview`:

```dart
setState(() => _triedReview = true); // hiện InventoryNoticeBanner(validation) đầu màn
```

   và thẻ dòng không hợp lệ (`!validateReceiptItem(item).isValid`) đổi dòng 2 thành chữ màu `danger`: `'Chưa hoàn tất — mở để sửa'`. `canReview` đúng mới `push` sang review.

**SCR-084:** nhận `warehouseLocked` từ session → coi như `readOnly` (dùng chung nhánh `readOnly` của T7-0b) và hiện `InventoryNoticeBanner(locked)`.

### 4.3 SCR-010 — không quyền, chưa có người duyệt

`pages/goods_receipt_review_page.dart`:

- `permissionDenied` → thân màn chỉ `InventoryPermissionDenied`.
- `submitErrorCode == 'APPROVER_CONFIGURATION_MISSING'` → banner **thay** banner "Cần phê duyệt…" (một nguồn phản hồi): `VBannerStatus.error`, `'Chưa có người duyệt phù hợp'` / `'Chưa thể tạo phiếu. Cần cấu hình người duyệt đủ quyền và phạm vi rồi gửi lại trong phiên hiện tại.'`. Dữ liệu giữ nguyên, nút `Gửi phê duyệt` vẫn bấm được.
- Listener toast lỗi: **không** hiện toast khi `submitErrorCode` là `APPROVER_CONFIGURATION_MISSING` (đã có banner) — `listenWhen` thêm `curr.submitErrorCode != 'APPROVER_CONFIGURATION_MISSING'`.

### 4.4 SCR-011 — không quyền, không có yêu cầu

`logic/receipt_approval_cubit.dart` + `pages/goods_receipt_approval_page.dart`:

- `load()` gặp `noPermission` → state mới `ReceiptApprovalPermissionDenied` → `InventoryPermissionDenied`.
- Không tìm thấy (`doc == null`) → `VEmptyState` `'Không có yêu cầu để duyệt'` / `'Yêu cầu chỉ xuất hiện sau khi người lập gửi hồ sơ hợp lệ.'` (thay `'Không tìm thấy yêu cầu nhận hàng.'`).

### 4.5 SCR-012 — `ReceiptResultCubit` (tạo) + trạng thái thực thi

Tạo `logic/receipt_result_cubit.dart` (thay việc page tự gọi repository):

```dart
sealed class ReceiptResultState {}
class ReceiptResultLoading extends ReceiptResultState {}
class ReceiptResultPermissionDenied extends ReceiptResultState {}
class ReceiptResultNotFound extends ReceiptResultState {}
class ReceiptResultLoaded extends ReceiptResultState { final ReceiptDocumentModel document; }

class ReceiptResultCubit extends Cubit<ReceiptResultState> {
  ReceiptResultCubit({required GoodsReceiptRepository repository, this.pollInterval = const Duration(seconds: 2)});
  final Duration pollInterval;
  Timer? _poll;

  Future<void> load(String id);           // getReceiptById; processing → _startPolling(id)
  void _startPolling(String id);          // Timer.periodic(pollInterval): checkReceiptResult(id);
                                          // hết processing → emit Loaded + _poll?.cancel()
  @override
  Future<void> close() { _poll?.cancel(); return super.close(); }
}
```

`pages/goods_receipt_result_page.dart` chuyển sang `BlocProvider` + `BlocBuilder`; bảng hiển thị (giữ các nhánh `completed`, `rejected`, `pendingApproval`, không tìm thấy của T7-0b):

| Trạng thái | Hiển thị | Back / footer |
|---|---|---|
| `processing` (`PROCESSING`) | `VEmptyState` + `VLoading`: `'Đang ghi nhận hàng'` / `'Hệ thống đang xử lý. Bạn không cần thực hiện lại.'` | không footer, không nút gửi lại |
| `executionUnknown` (`UNKNOWN`, `COMMIT_UNKNOWN`) | `VEmptyState`: `'Đang xác minh kết quả'` / `'Không thực hiện lại thao tác nhận hàng.'`; `VBanner(status: VBannerStatus.warning, title: 'Giữ nguyên lần nhận hiện tại', description: 'Hệ thống tiếp tục đối soát kết quả của lần nhận này.')` | **không** nút Back (`showBackButton: false`, `PopScope(canPop: false)`); Sticky Footer `VButton('Xác minh kết quả')` → `context.push('/warehouse/receipts/reconciliation/${doc.id}')` |
| `executionRejected` (`REJECTED_EXECUTION`) | `VEmptyState` icon `VIcons.close`: `'Chưa ghi nhận hàng'` / `'Yêu cầu bị chặn trước khi tồn kho thay đổi.'` | footer `'Xong'` → `/inventory` |
| quyền (`PERMISSION_DENIED`) | `InventoryPermissionDenied` | footer `'Về Kho'` |

`COMMIT_UNKNOWN` dùng chung hiển thị với `UNKNOWN` (prototype hai trạng thái giống hệt); fixture chỉ có một giá trị `executionUnknown`.

### 4.6 SCR-013 Đối soát kết quả nhận hàng (tạo)

**Route** — `core/router/app_router.dart`, cạnh route result:

```dart
GoRoute(
  path: '/warehouse/receipts/reconciliation/:id',
  name: 'warehouse.receipts.reconciliation',
  builder: (context, state) =>
      GoodsReceiptReconciliationPage(receiptId: state.pathParameters['id'] ?? ''),
),
```

**Cubit** — `logic/receipt_reconciliation_cubit.dart`:

```dart
enum ReconciliationStatus { loading, ready, empty, permissionDenied }

class ReceiptReconciliationState {
  final ReconciliationStatus status;
  final ReceiptDocumentModel? document;
  final DateTime? checkedAt;        // thời điểm hỏi lại gần nhất
  final bool isRefreshing;
  bool get isTerminal => document != null &&
      (document!.status == ReceiptStatus.completed || document!.status == ReceiptStatus.executionRejected);
}

class ReceiptReconciliationCubit extends Cubit<ReceiptReconciliationState> {
  ReceiptReconciliationCubit({required GoodsReceiptRepository repository, DateTime Function()? clock});
  Future<void> check(String id); // checkReceiptResult(id) → null: empty; noPermission: permissionDenied; còn lại: ready + checkedAt = clock()
}
```

`isStale` tính ở page: `clock().difference(checkedAt!) > const Duration(minutes: 1)` (truyền `clock` để test).

**Page** — `pages/goods_receipt_reconciliation_page.dart`:

- `VAppBar(title: 'Đối soát nhận hàng', subtitle: 'Tự mở khi kết quả lần nhận chưa xác định')`. Back về SCR-012 (`context.pop()`); không tạo thao tác mới.
- Mở màn → `cubit.check(receiptId)` một lần.

| Trạng thái | Hiển thị |
|---|---|
| `LOADING` | `VLoading` |
| `EMPTY` (không tìm thấy lần nhận) | `VEmptyState` `'Chưa có kết quả mới'` / `'Hệ thống vẫn đang theo dõi lần nhận này. Bạn không cần tạo lại thao tác.'` |
| `PERMISSION_DENIED` | `InventoryPermissionDenied` |
| `PROCESSING_OR_UNKNOWN` (`executionUnknown` / `processing`) | khối đầu: `'Đang xác minh kết quả nhận hàng'` / `'Chưa cần thực hiện lại lần nhận.'`; dòng `'Lần kiểm tra gần nhất'` · `dd/MM/yyyy · HH:mm:ss`; dòng thời gian (bên dưới); Sticky Footer `VButton('Làm mới', variant: secondary)` → `cubit.check(id)` (chỉ hỏi lại). **Không** hiện "Xem hỗ trợ xử lý" — TODO(T7-11: BJ-17) |
| `STALE` (quá 1 phút chưa làm mới) | như trên + `InventoryNoticeBanner(stale)` dưới khối đầu |
| `TERMINAL` (`completed` / `executionRejected`) | `VBanner(status: VBannerStatus.success, title: 'Đã xác lập kết quả', description: 'Kết quả cuối cùng đã có; hệ thống sẽ đưa bạn về màn kết quả.')` + dòng thời gian đầy đủ; sau 2 giây `context.go('/warehouse/receipts/result/${id}')` (dùng `BlocListener` + `Future.delayed`), kèm nút `VButton('Xem kết quả')` làm ngay |

**Dòng thời gian** — chỉ hiện sự kiện **đã có bằng chứng** (SCR-013 v3.9.2), mỗi sự kiện: tiêu đề, dòng phụ, thời điểm. Một bề mặt chung, các sự kiện ngăn bằng `VDivider`; không mã kỹ thuật ngoài **một** mã lần nhận:

| Sự kiện | Điều kiện hiện | Dòng phụ | Thời điểm |
|---|---|---|---|
| `'Hồ sơ nhận đã được khóa'` | luôn | mã lần nhận (`doc.id`) | `submittedAt` · `submittedByName` |
| `'Yêu cầu đã được duyệt'` | `decidedAt != null` | `'Người duyệt: ${decidedByName}'` | `decidedAt` |
| `'Kết quả ghi nhận đã được xác lập'` | `completed` hoặc `executionRejected` | `'Kết quả của lần nhận hiện tại'` | `executedAt` |
| `'Đang xác lập kết quả cuối cùng'` | `processing` / `executionUnknown` | `'Kết quả của lần nhận hiện tại'` | `'Đang tiếp tục kiểm tra'` |
| `'Biến động tồn kho đã được ghi'` | `completed` | `'${n} dòng hàng'` (dòng có vào tồn > 0) | `executedAt` |
| `'Đang kiểm tra biến động tồn kho'` | `processing` / `executionUnknown` | `'Chưa có bằng chứng xác nhận biến động tồn kho đã được ghi'` | `'Không cần tạo lần nhận mới'` |

Không hiện "mốc sổ" (số thứ tự sổ kho) như prototype — đó là ID kỹ thuật, SCR-013 §4 không cho phép.

### 4.7 Test PR 2

| # | Test | Kỳ vọng |
|---|---|---|
| C9 | SCR-006 `permissionDenied` | `'Không có quyền truy cập'`; không có thẻ `'Nhập hàng nhanh'` |
| C10 | SCR-006 `warehouseLocked` | `'Kho đang được khóa'`; thẻ `'Nhập hàng nhanh'` không chạm được |
| C11 | SCR-009 `catalogChanged` | `'Dữ liệu vừa thay đổi'`; bấm `'Tải lại'` → danh mục hiện, banner mất |
| C12 | SCR-009 `warehouseLocked` | `'Kho đang được khóa'`; không có ô tìm kiếm; `'Rà soát'` tắt |
| C13 | SCR-008 bấm tiếp tục khi chưa đủ | `'Cần kiểm tra dữ liệu'` + lỗi theo trường |
| C14 | SCR-009 có dòng chưa xong, bấm `'Rà soát'` | `'Cần kiểm tra dữ liệu'`; thẻ dòng đó `'Chưa hoàn tất — mở để sửa'`; vẫn ở 009 |
| C15 | SCR-010 `approverMissing` | banner `'Chưa có người duyệt phù hợp'`, không có toast, không có banner `'Cần phê duyệt…'` |
| C16 | SCR-011 id không tồn tại | `'Không có yêu cầu để duyệt'` |
| C17 | SCR-012 `executionProcessing` (`pollInterval` = 10 ms) | lúc đầu `'Đang ghi nhận hàng'`; sau `pump` 30 ms → `'Đã ghi nhận hàng'` |
| C18 | SCR-012 `executionUnknown` | `'Đang xác minh kết quả'`, `'Giữ nguyên lần nhận hiện tại'`, nút `'Xác minh kết quả'`, không nút Back |
| C19 | SCR-013 `executionUnknown`: mở → `'Làm mới'` | lần đầu có `'Đang kiểm tra biến động tồn kho'`, không có `'Biến động tồn kho đã được ghi'`; sau `'Làm mới'` → `'Đã xác lập kết quả'` |
| C20 | SCR-013 `executionUnknownStuck`, `clock` +2 phút | `'Dữ liệu có thể đã cũ'`; không có `'Xem hỗ trợ xử lý'` |
| C21 | SCR-012 `executionRejected` | `'Chưa ghi nhận hàng'`; `ValuationRepository.getQueue()` không có phiếu này |

## 5. Kiểm tra

- [ ] `cd apps/erp && dart analyze lib/features/inventory test/features/inventory lib/core/router lib/core/di` = 0 lỗi
- [ ] `flutter test test/features/inventory` xanh, có C1–C21
- [ ] `grep -rn "Mã phiếu\|context.go('/warehouse/receipts/quick" apps/erp/lib/features/inventory` không còn kết quả
- [ ] Bảng mục 6 điền đủ cột "Test" (tên test hoặc "không áp dụng")
- [ ] Thử tay: đặt tạm `scenario` trong `injection.dart` (`GoodsReceiptRepository(...)..scenario = ReceiptScenario.executionUnknown`), duyệt một phiếu → SCR-012 "Đang xác minh" → "Xác minh kết quả" → SCR-013 → "Làm mới" → tự về SCR-012 "Đã ghi nhận hàng". **Trả lại `normal` trước khi commit.**

## 6. Bảng trạng thái → nhánh dựng → test (nhập nhanh)

| Màn | Trạng thái | Nhánh dựng | Test |
|---|---|---|---|
| 006 | READY · LOADING · CONFLICT · LOCKED · PERMISSION_DENIED | 4.1 | B9, C9, C10 (LOADING, CONFLICT: thêm test nếu kịp) |
| 008 | READY · VALIDATION_ERROR · CONFLICT · LOCKED · PERMISSION_DENIED | 4.2 | C13 (+ dùng chung 009 cho CONFLICT / LOCKED / PERMISSION_DENIED) |
| 009 | READY · VALIDATION_ERROR · CONFLICT · LOCKED · PERMISSION_DENIED | 4.2 | B10–B12, C11, C12, C14 |
| 009 | EMPTY · READ_ONLY | — | không áp dụng (nhận theo chứng từ, T7-0d) |
| 084 | READY · VALIDATION_ERROR · LOT_CONFLICT · DUPLICATE_LINE · READ_ONLY | T7-0b + 4.2 | B13–B15, B4, B11, C1 |
| 084 | PERMISSION_DENIED | — | không áp dụng (chặn từ 006 / 008) |
| 010 | READY · APPROVAL_REQUIRED · VALIDATION_ERROR · PENDING_APPROVAL · APPROVER_CONFIGURATION_MISSING · PERMISSION_DENIED | T7-0b + 4.3 | B16, B17, T16, C15 |
| 010 | FINANCIAL_MASKED | — | không áp dụng (không hiện tiền) |
| 011 | READY · APPROVAL_REQUIRED · VALIDATION_ERROR · SELF_APPROVAL_NOT_ALLOWED · APPROVAL_ALREADY_DECIDED · PERMISSION_DENIED | T7-0, T7-0b + 4.4 | B18, T17, B7, C16 |
| 011 | FINANCIAL_MASKED | — | không áp dụng |
| 012 | COMPLETED · VALUATION_PENDING_RESULT · PROCESSING · UNKNOWN · COMMIT_UNKNOWN · REJECTED_EXECUTION · PERMISSION_DENIED | T7-0b + 4.5 | B19, C17, C18, C21 |
| 013 | READY · LOADING · EMPTY · STALE · PERMISSION_DENIED · PROCESSING_OR_UNKNOWN · TERMINAL | 4.6 | C19, C20 |

## 7. Rủi ro / lưu ý

- `ReceiptScenario` là công cụ fixture; ghi rõ trong comment để khi nối backend thì **xoá**, trạng thái lấy từ lỗi RPC thật (`AppException.code`).
- Timer trong `ReceiptResultCubit` phải huỷ ở `close()`; test widget dùng `pollInterval` ngắn và `tester.pump(...)`, không `pumpAndSettle` khi timer còn chạy.
- Tự chuyển màn ở SCR-013 `TERMINAL` dùng `Future.delayed` — kiểm `context.mounted` trước khi `go`.
- "Xem hỗ trợ xử lý" (BJ-17) cố ý chưa có; khi làm T7-11 thì thêm nút ở `PROCESSING_OR_UNKNOWN`.

## 8. Review

- **Ngày:** 2026-10-14, trên working tree sau commit `7dc1757c3` (T7-0c chưa commit).
- **Kết quả: ✅ đạt.**
- **Đã kiểm:**
  - `dart analyze lib/features/inventory test/features/inventory lib/core/router lib/core/di` → No issues found.
  - `flutter test test/features/inventory` → 71 test xanh (trước T7-0c: 50); đủ C1–C21.
  - Lệnh `grep` mục 5 → sạch; `injection.dart` không còn đặt `scenario` (mặc định `normal`).
  - Bước 0: G1 có `_lotKeys` thêm / xoá cùng `_lots` và truyền `key:`; G2 "Sửa" dùng `pop()` / `pop()` hai lần; câu không tìm thấy đã đổi.
  - Repository: `_guard()` ở mọi phương thức công khai; `getCapability`; `catalogChanged` chỉ ném lần đầu; `approverMissing` ném trước khi cấp ID; trạng thái sau duyệt theo kịch bản, chỉ `completed` mới tạo mục chờ định giá; `checkReceiptResult` theo cùng định danh, `executionUnknownStuck` không bao giờ có kết quả.
  - Màn: SCR-006 `ReceiptEntryCubit` đủ 5 trạng thái; 008 / 009 / 084 không quyền, xung đột (+ "Tải lại", ẩn lỗi "Thử lại" trùng), kho khoá chỉ xem, lỗi nhập; 010 banner "Chưa có người duyệt phù hợp" thay banner phê duyệt và không toast; 011 không quyền / "Không có yêu cầu để duyệt"; 012 `ReceiptResultCubit` có hỏi lại khi đang ghi nhận, huỷ timer ở `close()`, nhánh chưa rõ kết quả khoá Back + "Xác minh kết quả"; 013 dòng thời gian chỉ hiện sự kiện có bằng chứng, không "mốc sổ", không "Xem hỗ trợ xử lý", tự về màn kết quả bằng `Timer` huỷ được.
- **Góp ý (không chặn, ghi lại để làm khi chạm tới):**
  1. SCR-013 `STALE`: `isStale` chỉ tính lại khi màn rebuild; đứng yên trên màn quá 1 phút mà không thao tác thì banner "Dữ liệu có thể đã cũ" không tự hiện (plan bước 4.6 của tôi không nói cách rebuild). Thêm một `Timer` trong `_ReconciliationViewState` gọi `setState` khi tới `checkedAt + 1 phút` (huỷ ở `dispose` và khi `checkedAt` đổi).
  2. `ReceiptEntryCubit` và `ReceiptResultCubit` đổi lỗi lạ (không phải quyền / xung đột) thành `ready` / "không tìm thấy" — ổn với fixture; khi nối backend cần trạng thái lỗi có "Thử lại" (T7-0e hoặc plan backend).
- **Việc tiếp:** commit T7-0c; plan tiếp theo T7-0d (nhận theo chứng từ).
