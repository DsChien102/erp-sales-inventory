# T7-0d — Nhận hàng theo chứng từ (SCR-007 + chế độ chứng từ của SCR-009, 084, 010, 011, 012)

> Theme: Theme 7 Inventory · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Thuộc [PLAN.md](../../PLAN.md) mục "Theme 7. Inventory" (đợt 0). Ước lượng: **~2,5 ngày, 2 PR**. Làm sau [T7-0c](T7-0c-trang-thai-chung-va-doi-soat.md) (✅, commit `49967966e`).
> Đối chiếu: UC-02-01 (BR-01…BR-09, EF-A, EF-B), Screen Contract SCR-006, 007, 009, 084, 010, 011, 012; câu chữ từ prototype v4.6.8 (`index.html?uif=UIF-02&flow=document&screen=…&state=…` và `v392-bj02-semantic-hardening.js`, trích 2026-10-15).

Đường dẫn tính từ `apps/erp/lib/features/inventory/` nếu không ghi khác. Viết tắt: `VButton('X')` = `VButton(label: 'X', …)`. Câu trong ngoặc kép là câu hiển thị, chép nguyên văn.

## 1. Mục tiêu

Thủ kho nhận hàng **theo chứng từ mua** (đơn mua đã có): chọn chứng từ → hệ thống nạp **mọi** mặt hàng của chứng từ → ghi thực nhận từng mặt hàng (hoặc "Chưa nhận lần này") → rà soát → gửi:

- **không vượt** lượng còn được nhận → hệ thống ghi nhận ngay, thủ kho thấy màn kết quả;
- **vượt** → chờ người duyệt (như nhập nhanh).

Khác nhập nhanh (UC-02-01): không tìm / thêm / xoá sản phẩm (danh sách do chứng từ quyết định), có **bản nháp tự lưu** theo chứng từ, có "Chưa nhận lần này", có "Đổi chứng từ", có kiểm **phiên bản chứng từ** khi gửi, cho phép gửi khi **không có hàng vào tồn** nếu mọi mặt hàng đã xử lý.

## 2. Phạm vi

| Trong T7-0d | Không trong T7-0d |
|---|---|
| Fixture chứng từ mua + bản nháp tự lưu + kiểm phiên bản | Màn chứng từ mua thật (Theme 10, chưa có) → **không** làm lối vào "từ chứng từ" (`entry=document-context`) |
| SCR-007 (7 trạng thái) | Ngưỡng dung sai cấu hình (ApprovalPolicy) — fixture dùng **dung sai 0** |
| Chế độ chứng từ của SCR-009, 084, 010, 011, 012 | Nhận một chứng từ nhiều lần với lô đã nhận trước — fixture chỉ giảm "còn được nhận" |
| Đổi đường dẫn phiên nhận `quick/…` → `session/…` (dùng chung hai chế độ) | |
| Nối BJ-03: phiếu theo chứng từ vào hàng chờ với căn cứ giá từ chứng từ | |
| Chỉnh câu tự duyệt / đã quyết định ở SCR-011 cho khớp prototype | |

## 3. PR 1 — Dữ liệu và phiên nhận

### 3.1 Chứng từ mua (fixture) — `data/models/purchase_document.dart` (tạo)

```dart
class PurchaseDocumentLine extends Equatable {
  const PurchaseDocumentLine({
    required this.lineId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitId,
    required this.unitName,
    required this.isLotTracked,
    required this.requiresExpiry,
    required this.remainingQty,   // lượng còn được nhận, do chứng từ nguồn cung cấp
    required this.unitPrice,      // VND / đơn vị giao dịch — chỉ để tính giá trị rủi ro và căn cứ BJ-03
    this.knownLotExpiry = const {},
  });
  // field final tương ứng; props
}

class PurchaseDocument extends Equatable {
  const PurchaseDocument({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.documentDate,
    required this.version,
    required this.lines,
    this.partiallyReceived = false,
  });
  // field final tương ứng; copyWith; props
}
```

Fixture trong `GoodsReceiptRepository._seed()` (`_documents`):

| Chứng từ | NCC | Ngày chứng từ | Mặt hàng (mã · đơn vị · theo lô · cần HSD · còn được nhận · đơn giá) | Đã nhận một phần |
|---|---|---|---|---|
| `PN-260816-04` | Minh Dũng (`sup_01`) | 16/08/2026 | Nobivac DHPPi `NOB-DHPP` · hộp · có · có · 120 · 83.000 · Amoxicillin LA `AMX-LA` · chai · có · có · 24 · 120.000 | không |
| `PN-260816-05` | An Việt (`sup_02`) | 16/08/2026 | Găng tay khám Nitrile `GLOVE-N` · hộp · không · không · 20 · 45.000 | **có** |

Version ban đầu = 1.

### 3.2 Mở rộng model dòng và phiếu

`data/models/receipt_item_draft.dart` thêm (nhớ `copyWith`, `props`):

```dart
final String? sourceLineId;   // chỉ chế độ chứng từ
final double? remainingQty;   // lượng còn được nhận của dòng nguồn
final double? unitPrice;      // VND / đơn vị — từ chứng từ
final bool notReceived;       // "Chưa nhận lần này"
```

`data/models/receipt_document_model.dart` thêm:

```dart
enum ReceiptMode { quick, document }

final ReceiptMode mode;               // mặc định quick (giữ dữ liệu cũ)
final String? sourceDocumentId;
final int? sourceDocumentVersion;
final DateTime? sourceDocumentDate;
final bool requiresApproval;          // quick: luôn true; document: true khi có dòng vượt
```

### 3.3 Luật — `logic/receipt_rules.dart`

```dart
/// Vào tồn vật lý vượt lượng còn được nhận (BR-05; dung sai 0 trong fixture).
bool isOverSource(ReceiptItemDraft item) =>
    item.remainingQty != null && !item.notReceived && item.totalPhysicalStock > item.remainingQty!;

/// Dòng đã xử lý: hoặc "Chưa nhận lần này", hoặc nhập hợp lệ.
bool isItemHandled(ReceiptItemDraft item) =>
    item.notReceived || validateReceiptItem(item).isValid;

/// Phiếu theo chứng từ cần duyệt khi có ít nhất một dòng vượt (BR-09).
bool documentNeedsApproval(List<ReceiptItemDraft> items) => items.any(isOverSource);

/// Tổng giá trị rủi ro (SCR-011): Σ vào tồn vật lý × đơn giá chứng từ.
int riskTotalVnd(List<ReceiptItemDraft> items) => items
    .where((i) => !i.notReceived && i.unitPrice != null)
    .fold(0, (sum, i) => sum + (i.totalPhysicalStock * i.unitPrice!).round());
```

`classificationText`: dòng đầu thêm `if (item.notReceived) return 'Chưa nhận lần này';`.

### 3.4 Repository — `data/goods_receipt_repository.dart`

1. `ReceiptScenario` (`data/models/receipt_scenario.dart`) thêm `sourceChanged` và `financialMasked`.
2. Danh sách và chi tiết chứng từ:

```dart
final Map<String, PurchaseDocument> _documents = {};
final Map<String, List<ReceiptItemDraft>> _drafts = {};       // bản nháp tự lưu theo chứng từ
final Map<String, int> _draftVersions = {};                    // version chứng từ lúc nháp

Future<List<PurchaseDocument>> getPendingDocuments() async {
  _guard();
  return _documents.values.where((d) => d.lines.any((l) => l.remainingQty > 0)).toList();
}

Future<PurchaseDocument?> getDocument(String id) async { _guard(); return _documents[id]; }

/// SCR-007 SOURCE_VERSION_STALE: chứng từ đã có bản nháp nhưng version đã đổi.
bool isDraftStale(String documentId) =>
    _drafts.containsKey(documentId) && _draftVersions[documentId] != _documents[documentId]?.version;
```

3. Bản nháp (BC-IO-16 — hệ thống tự lưu, **không** có nút "Lưu nháp"):

```dart
Future<void> saveDraft(String documentId, int version, List<ReceiptItemDraft> items) async {
  _guard();
  _drafts[documentId] = List.of(items);
  _draftVersions[documentId] = version;
}

Future<List<ReceiptItemDraft>?> getDraft(String documentId) async => _drafts[documentId];

Future<void> discardDraft(String documentId) async {
  _drafts.remove(documentId);
  _draftVersions.remove(documentId);
}
```

4. Gửi phiếu theo chứng từ:

```dart
Future<ReceiptDocumentModel> submitDocumentReceipt({
  required String documentId,
  required int documentVersion,
  required ReceiptHeaderDraft header,
  required List<ReceiptItemDraft> items,
  required ReceiptActor maker,
}) async {
  _guard();
  final source = _documents[documentId];
  if (source == null) throw const AppException(AppErrorCode.notFound);

  // EF-A: chứng từ đổi version → không cho gửi trên version cũ.
  if (scenario == ReceiptScenario.sourceChanged && source.version == documentVersion) {
    _documents[documentId] = _bumpVersion(source); // version + 1, AMX-LA còn được nhận 24 → 20
  }
  if (_documents[documentId]!.version != documentVersion) {
    throw const AppException(AppErrorCode.stateChanged);
  }

  final needsApproval = documentNeedsApproval(items);
  if (needsApproval && scenario == ReceiptScenario.approverMissing) {
    throw const AppException('APPROVER_CONFIGURATION_MISSING');
  }

  final now = DateTime.now();
  final id = _nextId(now);
  final base = ReceiptDocumentModel(
    id: id, header: header, items: items, mode: ReceiptMode.document,
    sourceDocumentId: documentId, sourceDocumentVersion: documentVersion,
    sourceDocumentDate: source.documentDate, requiresApproval: needsApproval,
    status: ReceiptStatus.pendingApproval, submittedById: maker.id,
    submittedByName: maker.name, submittedAt: now,
  );
  _receipts[id] = needsApproval ? base : _execute(base, now); // _execute: như nhánh sau duyệt của approveReceipt
  await discardDraft(documentId);
  if (_receipts[id]!.status == ReceiptStatus.completed) _consumeSource(_receipts[id]!);
  return _receipts[id]!;
}
```

   - Tách phần "trạng thái đích theo kịch bản + `executedAt` + nối BJ-03" trong `approveReceipt` (T7-0c 3.1 bước 6) thành `ReceiptDocumentModel _execute(ReceiptDocumentModel doc, DateTime now)` để dùng chung.
   - `_consumeSource(doc)`: giảm `remainingQty` của từng dòng nguồn đúng `totalPhysicalStock` (không âm), đặt `partiallyReceived = true` nếu còn dòng > 0. Gọi cả khi `approveReceipt` / `checkReceiptResult` chuyển phiếu **theo chứng từ** sang `completed`.

5. Nối BJ-03 — đổi tên `ValuationRepository.addQuickReceipt` thành `addReceipt(ReceiptDocumentModel doc)` (2 chỗ gọi trong repository):
   - `mode == quick` → như cũ (`directMissing`, `ValuationEntryType.quick`);
   - `mode == document` → `entryType: ValuationEntryType.document`, `receiptNumber: doc.id`, mỗi nhóm `status: ValuationGroupStatus.ready`, `sources: [ValuationCostSource(id: 'PO', label: 'Đơn mua ${doc.sourceDocumentId}', unitPrice: item.unitPrice ?? 0)]`, `selectedSourceId: 'PO'`.

### 3.5 Phiên nhận dùng chung hai chế độ

**Đổi đường dẫn** `'/warehouse/receipts/quick/'` → `'/warehouse/receipts/session/'` ở mọi chỗ (router 4 route, `inventory_repository.dart`, `receipt_entry_choice_page.dart`, `goods_receipt_review_page.dart`, `quick_receipt_header_page.dart`, `goods_receipt_items_page.dart`, 2 file test). Đây là đổi chuỗi đường dẫn, không đổi tên symbol. Tên route `name:` đổi tương ứng `warehouse.receipts.session.*`.

**Router** — ShellRoute phiên nhận tạo cubit theo query `document`:

```dart
ShellRoute(
  builder: (context, state, child) {
    final documentId = state.uri.queryParameters['document'];
    return BlocProvider(
      create: (_) {
        final cubit = QuickReceiptSessionCubit(
          repository: getIt<GoodsReceiptRepository>(),
          actorLoader: currentReceiptActor,
        );
        return documentId == null ? (cubit..loadCatalog()) : (cubit..startDocument(documentId));
      },
      child: child,
    );
  },
  routes: [ /* header, items, item-detail, review — đường dẫn mới */ ],
),
GoRoute(
  path: '/warehouse/receipts/documents',
  name: 'warehouse.receipts.documents',
  builder: (context, state) => const ReceiptDocumentListPage(),
),
```

Mở chứng từ từ SCR-007: `context.push('/warehouse/receipts/session/items?document=${doc.id}')`. Giữ nguyên tên class `QuickReceiptSessionCubit` trong T7-0d (đổi tên để T7-0e làm bằng GitNexus `rename`).

**State** (`logic/quick_receipt_session_state.dart`) thêm:

```dart
final ReceiptMode mode;            // mặc định quick
final PurchaseDocument? document;  // chế độ chứng từ
final bool sourceStale;            // EF-A: chứng từ đã đổi, chờ "Tải lại chứng từ"
```

`canReview` tách theo chế độ:

```dart
bool get canReview => switch (mode) {
  ReceiptMode.quick => /* như hiện tại */,
  ReceiptMode.document => !warehouseLocked && !sourceStale && items.isNotEmpty && items.every(isItemHandled),
};
```

(Chế độ chứng từ không đòi chứng từ giao nhận và cho phép tổng vào tồn = 0 — SCR-010 v3.9.2.)

**Cubit** (`logic/quick_receipt_session_cubit.dart`) thêm:

```dart
Future<void> startDocument(String documentId) async {
  emit(state.copyWith(mode: ReceiptMode.document, catalogStatus: CatalogStatus.loading));
  try {
    final capability = await _repository.getCapability();
    final doc = await _repository.getDocument(documentId);
    if (doc == null) { /* catalogStatus failure + errorMessage 'Không tìm thấy chứng từ.' */ return; }
    final draft = await _repository.getDraft(documentId);
    emit(state.copyWith(
      catalogStatus: CatalogStatus.ready,
      warehouseLocked: capability.warehouseLocked,
      document: doc,
      header: ReceiptHeaderDraft(
        supplierId: doc.supplierId, supplierName: doc.supplierName, receiptDate: DateTime.now(),
      ),
      items: draft ?? [for (final l in doc.lines) _itemFromLine(l)], // BR-02: nạp mọi dòng
    ));
  } catch (e) { /* như loadCatalog: permissionDenied / catalogConflict */ }
}

ReceiptItemDraft _itemFromLine(PurchaseDocumentLine l) => ReceiptItemDraft(
  productId: l.productId, productName: l.productName, productCode: l.productCode,
  unitId: l.unitId, unitName: l.unitName, isLotTracked: l.isLotTracked,
  requiresExpiry: l.requiresExpiry, knownLotExpiry: l.knownLotExpiry,
  sourceLineId: l.lineId, remainingQty: l.remainingQty, unitPrice: l.unitPrice,
  lots: const [],
);

/// "Chưa nhận lần này": xoá mọi lô, giữ dòng nguồn (BR-03).
void markNotReceived(String productId, String unitId) { /* notReceived: true, lots: [] → saveItem */ }

/// EF-A: tải version mới, giữ số đã nhập, cập nhật "còn được nhận".
Future<void> reloadDocument() async { /* getDocument → map remainingQty theo sourceLineId vào items; sourceStale: false */ }
```

- `saveItem` (và `markNotReceived`): khi `mode == document` gọi thêm `_repository.saveDraft(document.id, document.version, state.items)` sau `emit` (không chờ, không hiện gì — tự lưu nền). Lưu dòng có số liệu thì đặt `notReceived: false`.
- `submitForApproval()`: `mode == document` → gọi `submitDocumentReceipt(documentId: state.document!.id, documentVersion: state.document!.version, …)`; `catch` mã `stateChanged` → `sourceStale: true` (thay vì `catalogConflict`).

### 3.6 Test PR 1

| # | Test | Kỳ vọng |
|---|---|---|
| D1 | `isOverSource`: còn 120, vào tồn 121 / 120 / 119 | `true` / `false` / `false`; `notReceived` → `false` |
| D2 | `isItemHandled`: dòng `notReceived` không có lô | `true` |
| D3 | `riskTotalVnd`: Nobivac 121 × 83.000 + Amox 24 × 120.000 | `12923000` |
| D4 | `startDocument('PN-260816-04')` | mode document; 2 dòng, đúng `remainingQty`; header là Minh Dũng |
| D5 | `saveItem` ở chế độ chứng từ → tạo cubit mới `startDocument` cùng chứng từ | dòng đã nhập còn nguyên (bản nháp) |
| D6 | gửi: hai dòng vừa đủ (120, 24) | `completed` ngay; không qua duyệt; chứng từ hết "còn được nhận"; BJ-03 có phiếu, nhóm `ready`, nguồn "Đơn mua PN-260816-04" |
| D7 | gửi: Nobivac 121 | `pendingApproval`, `requiresApproval == true` |
| D8 | gửi: mọi dòng "Chưa nhận lần này" | `completed`; không tạo mục BJ-03; `canReview` đúng (cho phép tổng vào tồn = 0) |
| D9 | `sourceChanged` → gửi | ném `stateChanged`; `sourceStale == true`; `reloadDocument()` → Amox còn 20, số đã nhập giữ nguyên |
| D10 | gửi xong | `getDraft` trả `null` |

## 4. PR 2 — Các màn

### 4.1 SCR-006 — bật lối "Nhận theo chứng từ"

`pages/receipt_entry_choice_page.dart`: thẻ `'Nhận theo chứng từ'` hết disabled, phụ đề `'Đã có chứng từ mua để đối chiếu.'`, chạm → `context.push('/warehouse/receipts/documents')`. Khi kho khoá (T7-0c) thì disabled cả hai thẻ.

Home (`data/inventory_repository.dart`): task `PN-260816-04` → `routePath: '/warehouse/receipts/session/items?document=PN-260816-04'`.

### 4.2 SCR-007 Chứng từ chờ nhận (tạo)

`logic/receipt_document_list_cubit.dart` (tạo) — state: `status` (loading / ready / permissionDenied), `documents`, `query`; `load()`, `search(q)`; lọc theo `id` hoặc `supplierName` (không phân biệt hoa thường).

`pages/receipt_document_list_page.dart` (tạo):

- `VAppBar(title: 'Chứng từ chờ nhận')`, Back về SCR-006.
- `VSearchBar(hintText: 'Tìm mã chứng từ hoặc nhà cung cấp')`.
- Mỗi chứng từ một thẻ chạm được (`VCard` + chevron, **không badge** ở trạng thái bình thường):
  - dòng 1: mã chứng từ;
  - dòng 2: `'${supplierName} · ${dd/MM/yyyy}'`;
  - dòng 3: `'${n} mặt hàng đang chờ nhận'`; nếu `partiallyReceived`: `'${n} mặt hàng · đã nhận một phần trước đó'`;
  - **không** cộng số lượng giữa các đơn vị.
- Chạm → `context.push('/warehouse/receipts/session/items?document=${doc.id}')`.

| Trạng thái | Hiển thị |
|---|---|
| `LOADING` | `VLoading` |
| `EMPTY` | `VEmptyState` `'Không có chứng từ đang chờ nhận'` / `'Quay lại để chọn cách nhận hàng khác nếu phù hợp.'` |
| `FILTER_EMPTY` | `VEmptyState` `'Không có kết quả phù hợp'` / `'Thử mã chứng từ hoặc tên nhà cung cấp khác.'` |
| `PERMISSION_DENIED` | `InventoryPermissionDenied` |
| `PARTIAL_RECEIPT` (có chứng từ `partiallyReceived`) | `VBannerStatus.info` `'Có chứng từ đã nhận một phần'` / `'Số còn lại vẫn bám theo chứng từ nguồn và được kiểm tra lũy kế.'` trên danh sách |
| `SOURCE_VERSION_STALE` (`repository.isDraftStale(id)` cho chứng từ nào đó) | `VBannerStatus.warning` `'Chứng từ nguồn đã đổi'` / `'Lượng còn được phép nhận vừa thay đổi. Mở phiên bản hiện hành để đối chiếu.'` |

### 4.3 SCR-009 chế độ chứng từ — `pages/goods_receipt_items_page.dart`

Khi `state.mode == ReceiptMode.document`:

1. AppBar `'Hàng thực nhận'` (giữ).
2. Section `'Thông tin lần nhận'`, trailing `'${handled}/${total} đã xử lý'` (`handled` = số dòng `isItemHandled`); thêm dòng đầu `'Chứng từ'` · `document.id`; sau đó `Nhà cung cấp`, `Kho nhận`, `Ngày nhận`.
3. **Ẩn** `VSearchBar`, danh sách kết quả tìm, banner trùng (danh sách do chứng từ quyết định — BR-02).
4. Thẻ dòng:
   - tiêu đề `productName`; dòng 1 `'${unitName} · ${productCode}'`;
   - chưa ghi nhận: dòng 2 `'Còn chờ nhận ${formatQuantity(remainingQty)} ${unitName}'`, dòng 3 `'Chưa ghi nhận'`;
   - đã ghi nhận: dòng 2 `'${formatQuantity(totalPhysicalStock)} / ${formatQuantity(remainingQty)} ${unitName}'` + (còn thiếu) `' · còn ${formatQuantity(remainingQty - totalPhysicalStock)}'`, dòng 3 `classificationText(item)`;
   - `notReceived`: dòng 2 `'Còn chờ nhận …'`, dòng 3 `'Chưa nhận lần này'`.
5. `sourceStale` → `InventoryNoticeBanner(InventoryNotice.conflict, action: VButton('Tải lại chứng từ', onPressed: cubit.reloadDocument))` đầu màn.
6. `Rà soát`: như T7-0c (bật khi có dòng và không khoá; bấm khi chưa xử lý hết → banner `validation` + thẻ chưa xong `'Chưa hoàn tất — mở để sửa'`).

### 4.4 SCR-084 chế độ chứng từ — `pages/goods_receipt_item_detail_page.dart`

Khi dòng có `remainingQty != null`:

1. Hàng ngữ cảnh sản phẩm: trailing `'Còn ${formatQuantity(remainingQty)} ${unitName}'`.
2. Tiêu đề section lô: `'Các lô thực nhận'` + trailing `'Còn chờ nhận ${…} ${unitName}'`.
3. Dòng tổng: `'Tổng kiểm nhận'` · `'${formatQuantity(totalReceived)} / ${formatQuantity(remainingQty)} ${unitName}'`.
4. Banner chênh lệch (theo `_lots` đang sửa, chỉ khi tổng kiểm nhận > 0; ưu tiên từ trên xuống, chỉ hiện một):

| Điều kiện | Banner |
|---|---|
| vào tồn > còn được nhận | `VBannerStatus.warning` `'Lượng vào tồn vượt chứng từ'` / `'Vào tồn vật lý ${a} ${u}, vượt ${a − r} ${u} so với lượng còn được nhận. Hồ sơ sẽ cần phê duyệt.'` |
| vào tồn < còn được nhận | `VBannerStatus.info` `'Còn hàng chưa nhận'` / `'Vào tồn vật lý ${a} ${u}; còn ${r − a} ${u} theo chứng từ nguồn.'` |
| tổng kiểm nhận > còn được nhận (do có Từ chối) | `VBannerStatus.info` `'Có lượng từ chối ngoài số vào tồn'` / `'Tổng kiểm nhận ${t} ${u}; vào tồn vật lý ${a} ${u}. Lượng từ chối không làm tăng tồn.'` |

   (`a` = vào tồn vật lý, `r` = còn được nhận, `t` = tổng kiểm nhận, `u` = đơn vị; số dùng `formatQuantity`.)

5. Nút `VButton('Chưa nhận lần này', variant: VButtonVariant.secondary)` (trên nút `Xong`) → `cubit.markNotReceived(...)` rồi `context.pop()`.
6. **Không** có `'Xóa khỏi lần nhận'` ở chế độ chứng từ (dòng nguồn không được xoá).

### 4.5 SCR-010 chế độ chứng từ — `pages/goods_receipt_review_page.dart`

1. Section `'Thông tin lần nhận'`: thay nút `'Sửa'` bằng `VButton('Đổi chứng từ', variant: VButtonVariant.link)`:

```dart
showVConfirmDialog(
  context: context,
  title: 'Đổi chứng từ?',
  message: 'Đổi chứng từ sẽ xóa dữ liệu nhận hàng đang nhập để tránh giữ lại số lượng, lô hoặc phiên bản chứng từ không còn đúng.',
  cancelLabel: 'Giữ chứng từ',
  actionLabel: 'Đổi chứng từ',
  isDestructive: true,
  onAction: () async {
    await getIt<GoodsReceiptRepository>().discardDraft(state.document!.id); // hoặc qua cubit
    if (context.mounted) context.go('/warehouse/receipts/documents');
  },
);
```

   Dòng thông tin: `'Chứng từ'`, `'Nhà cung cấp'`, `'Kho nhận'`, `'Ngày chứng từ'`, `'Ngày nhận'` (không có "Chứng từ giao nhận").

2. Banner (một nguồn phản hồi):

| Điều kiện | Banner |
|---|---|
| đã gửi, chờ duyệt | như nhập nhanh: `'Đã gửi phê duyệt'` |
| còn dòng chưa xử lý | `VBannerStatus.warning` `'Còn mặt hàng chưa hoàn tất'` / `'Quay lại Hàng thực nhận để hoàn tất từng mặt hàng.'` |
| `submitErrorCode == APPROVER_CONFIGURATION_MISSING` | như T7-0c |
| có dòng vượt | `VBannerStatus.warning` `'Lượng vào tồn vượt chứng từ'` / `'Đạt + Cách ly + Hỏng vượt lượng còn được nhận. Hồ sơ cần phê duyệt.'` |
| còn lại | **không** banner (không vượt thì hệ thống ghi nhận ngay — không cần giải thích phê duyệt) |

3. `ReceiptLineSummary` thêm `trailingLabel`: `'Vượt chứng từ'` (dòng vượt), `'Nhận một phần'` (vào tồn < còn được nhận), `'Chưa nhận'` (`notReceived`), còn lại `'Đã xong'`.
4. Footer: `'Xác nhận nhận hàng'`. Gửi thành công:
   - `requiresApproval` → ở lại màn, chế độ chờ duyệt như nhập nhanh;
   - không cần duyệt → `context.go('/warehouse/receipts/result/${doc.id}')` (thủ kho thấy kết quả — UIF-02: "no-approval = system execution").

### 4.6 SCR-011 và SCR-012 chế độ chứng từ

**SCR-011** (`pages/goods_receipt_approval_page.dart`), khi `doc.mode == ReceiptMode.document`:

1. Banner lý do: `VBannerStatus.warning` `'Lý do cần duyệt'` / `'Lượng vào tồn vật lý vượt chứng từ nguồn.'`.
2. Thông tin lần nhận: thêm `'Chứng từ'` · `sourceDocumentId`, `'Ngày chứng từ'`; bỏ nút "Xem chứng từ giao nhận" nếu phiếu không có tệp.
3. Thông tin yêu cầu: thêm `'Tổng giá trị rủi ro'` · `MoneyFormatter.formatMinor(riskTotalVnd(doc.items))` (`apps/erp/lib/core/formatting/money_formatter.dart`; vd `12.923.000đ`); `scenario == financialMasked` → `'Không có quyền xem'` và **không** đưa số vào cây widget. Đặt cờ `riskMasked` trong `ReceiptApprovalLoaded` (cubit đọc từ repository `isFinancialMasked()`), không đọc `scenario` trực tiếp ở page.
4. `ReceiptLineSummary` có `trailingLabel` như SCR-010.

**Chỉnh câu theo prototype (cả hai chế độ):**
- tự duyệt: `'Bạn không thể tự duyệt'` → `'Không được tự phê duyệt'` / `'Người lập không thể đồng thời là người quyết định yêu cầu này.'`;
- đã xử lý: `'Yêu cầu đã được xử lý'` → `'Yêu cầu đã có quyết định'` / `'Quyết định hợp lệ đầu tiên có hiệu lực; các thao tác quyết định đã được khóa.'` (bị từ chối thì vẫn thêm `'Đã từ chối: …'`). Sửa các test T17, B7 theo câu mới.

**SCR-012** (`pages/goods_receipt_result_page.dart`), phiếu `completed`:
- tổng vào tồn = 0 (vd mọi dòng "Chưa nhận lần này" hoặc toàn Từ chối) → `'Đã ghi nhận kết quả lần nhận'` / `'Không có hàng vào tồn vật lý trong lần nhận này.'`; **không** có banner "Đang chờ xác nhận giá";
- dòng `notReceived` vẫn nằm trong "Kết quả theo dòng hàng" với nhãn `'Chưa nhận'`.

### 4.7 Test PR 2

| # | Test | Kỳ vọng |
|---|---|---|
| D11 | SCR-006 | thẻ `'Nhận theo chứng từ'` chạm được → SCR-007 |
| D12 | SCR-007 | 2 thẻ; banner `'Có chứng từ đã nhận một phần'`; gõ `an việt` còn `PN-260816-05`; gõ `zzz` → `'Không có kết quả phù hợp'` |
| D13 | SCR-007 `permissionDenied` | `'Không có quyền truy cập'` |
| D14 | SCR-009 document | `'0/2 đã xử lý'`, `'Chứng từ'` `PN-260816-04`, `'Còn chờ nhận 120 hộp'`; không có ô tìm kiếm |
| D15 | SCR-084 Nobivac Đạt 121 | `'Lượng vào tồn vượt chứng từ'`; Đạt 100 → `'Còn hàng chưa nhận'` |
| D16 | SCR-084 `'Chưa nhận lần này'` | về 009, thẻ `'Chưa nhận lần này'`, `'1/2 đã xử lý'` |
| D17 | SCR-010 không vượt → `'Xác nhận nhận hàng'` | sang SCR-012 `'Đã ghi nhận hàng'` |
| D18 | SCR-010 `'Đổi chứng từ'` → xác nhận | về SCR-007; `getDraft` của chứng từ là `null` |
| D19 | SCR-011 document (Nobivac 121, Amox 24) | `'Lượng vào tồn vật lý vượt chứng từ nguồn.'`, `'Tổng giá trị rủi ro'` = `'12.923.000đ'`; `financialMasked` → `'Không có quyền xem'` và không có số |
| D20 | SCR-012 mọi dòng chưa nhận | `'Đã ghi nhận kết quả lần nhận'`; không có `'Đang chờ xác nhận giá'` |
| D21 | `sourceChanged` widget: gửi ở SCR-010 | về SCR-009 thấy `'Dữ liệu vừa thay đổi'` + `'Tải lại chứng từ'`; bấm → banner mất; SCR-007 lúc gửi lỗi có `'Chứng từ nguồn đã đổi'` (nếu kiểm qua danh sách) |

## 5. Kiểm tra

- [ ] `cd apps/erp && dart analyze lib/features/inventory test/features/inventory lib/core/router lib/core/di` = 0 lỗi
- [ ] `flutter test test/features/inventory` xanh, có D1–D21; T17, B7 sửa theo câu mới vẫn xanh
- [ ] `grep -rn "/warehouse/receipts/quick\|addQuickReceipt\|Bạn không thể tự duyệt\|Yêu cầu đã được xử lý" apps/erp/lib apps/erp/test` không còn kết quả
- [ ] Thử tay: Home → task `PN-260816-04` (hoặc Nhận hàng → Nhận theo chứng từ → `PN-260816-04`) → nhập Nobivac 120, Amox "Chưa nhận lần này" → thoát giữa chừng, mở lại chứng từ thấy số đã nhập (bản nháp) → Rà soát → Xác nhận nhận hàng → SCR-012 → BJ-03 hàng chờ có phiếu với căn cứ "Đơn mua PN-260816-04"; SCR-007 còn `PN-260816-04` với "đã nhận một phần trước đó" (Amox chưa nhận)

## 6. Bảng trạng thái (chế độ chứng từ)

| Màn | Trạng thái | Nhánh dựng | Test |
|---|---|---|---|
| 007 | READY · LOADING · EMPTY · FILTER_EMPTY · PERMISSION_DENIED · PARTIAL_RECEIPT · SOURCE_VERSION_STALE | 4.2 | D12, D13, D21 (LOADING, EMPTY: thêm nếu kịp) |
| 009 | READY · VALIDATION_ERROR · CONFLICT (`sourceStale`) · LOCKED · PERMISSION_DENIED · READ_ONLY (kho khoá) | 4.3 + T7-0c | D14, D16, D21 |
| 009 | EMPTY (chứng từ không còn dòng chờ) | 4.3 — `VEmptyState` `'Không có mặt hàng cần nhận'` / `'Không có dòng hàng phù hợp trong lần nhận hiện tại.'` | thêm nếu kịp |
| 084 | READY · VALIDATION_ERROR · LOT_CONFLICT · READ_ONLY | 4.4 + T7-0b | D15, D16 |
| 084 | DUPLICATE_LINE | — | không áp dụng (chứng từ không thêm dòng) |
| 010 | READY · VALIDATION_ERROR · APPROVAL_REQUIRED · PENDING_APPROVAL · APPROVER_CONFIGURATION_MISSING · PERMISSION_DENIED | 4.5 | D17, D18, D7 |
| 010 | FINANCIAL_MASKED | — | không áp dụng (SCR-010 không hiện tiền) |
| 011 | READY · FINANCIAL_MASKED · SELF_APPROVAL_NOT_ALLOWED · APPROVAL_ALREADY_DECIDED · PERMISSION_DENIED | 4.6 | D19, T17, B7 |
| 012 | COMPLETED (gồm không có hàng vào tồn) · VALUATION_PENDING_RESULT · các trạng thái thực thi của T7-0c | 4.6 + T7-0c | D17, D20 |

## 7. Rủi ro / lưu ý

- Đổi đường dẫn `quick` → `session` chạm nhiều file (kể cả test) — làm trong **một** commit riêng ở đầu PR 1, chạy test ngay sau đó.
- Bản nháp tự lưu chạy nền: lỗi lưu nháp (`_guard` ném) **không** được hiện cho người dùng ở mỗi lần lưu dòng — nuốt lỗi trong `saveDraft` của cubit, chỉ lỗi gửi mới hiện.
- Dung sai 0 là giả định fixture; khi có ApprovalPolicy thật, `isOverSource` nhận ngưỡng từ backend.
- Tổng giá trị rủi ro ở fixture lấy đơn giá chứng từ, không tính chiết khấu / thuế — ghi chú trong comment của `riskTotalVnd`.

## 8. Review
<!-- Claude ghi sau khi người dùng code xong -->
- Ngày, commit được review:
- Kết quả: ⬜
- Góp ý:
