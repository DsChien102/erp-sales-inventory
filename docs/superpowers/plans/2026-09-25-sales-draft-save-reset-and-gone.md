# Soạn đơn — reset sau khi lưu nháp + thoát kẹt khi nháp đã bị xoá — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) Bấm «Lưu nháp» thành công → màn soạn đơn **về đơn mới trống**. (2) Khi lưu nháp bị server từ chối vì nháp **đã bị xoá / không còn / đã bị sửa nơi khác** → toast rõ ràng rồi **về đơn mới trống** (hoặc sang danh sách nháp nếu đang «Lưu nháp và đóng») — không còn vòng lặp sheet «Đơn có thay đổi chưa lưu».

**Architecture:** Chỉ sửa app `apps/erp` (presentation). Server giữ nguyên: `update_sales_order_draft` trả `STALE_DATA` («Draft is no longer active.» / version lệch), `REFERENCE_UNAVAILABLE` («Draft was not found.»). Cubit:
- `saveDraft()` đổi kiểu trả về từ `bool` sang enum `SalesDraftSaveResult { saved, failed, draftGone }`; `draftGone` khi đang cập nhật một nháp server (có `draftId` thật) mà gặp `SalesContractException` code `STALE_DATA` hoặc `REFERENCE_UNAVAILABLE`.
- Thêm `startNewDraft()`: **xoay `composeSessionId`** (khóa idempotency của lần lưu đầu) rồi `loadDraft(SalesComposeDraftRef.newDraft)`.
Page `_saveDraft`: `saved` → toast «Đã lưu đơn nháp.» + (không điều hướng) `startNewDraft()` + tải lại số nháp; `draftGone` → toast «Đơn nháp đã bị xoá hoặc thay đổi…» + (đang «Lưu nháp và đóng») sang danh sách nháp, (ngược lại) `startNewDraft()`.

**Tech Stack:** Flutter/Dart, flutter_bloc; `flutter_test`.

**Spec:** Chốt trong chat 2026-09-25: làm **cả hai** (reset sau lưu + xử lý lưu thất bại); lưu thất bại vì nháp không còn → **báo lỗi rồi về đơn mới trống**. Lỗi đã tái hiện: lưu nháp → sửa → «Đơn nháp (n)» → xoá chính nháp đó → back → back → «Lưu nháp và đóng» lỗi, sheet lặp.

## Global Constraints

- Không đổi SQL/RPC/DTO/command. Không đổi màn danh sách nháp, không đổi sheet rời màn (`sales_compose_leave_sheet.dart`).
- **UI change được user yêu cầu:** hành vi nút «Lưu nháp» đổi thành «lưu rồi về đơn mới trống». Không đổi layout.
- Lỗi lưu thông thường (mạng, dữ liệu sai…) **giữ nguyên hành vi cũ**: `failed`, giữ dữ liệu, toast «Chưa lưu được», cho thử lại.
- Không `dart format` cả package.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa: `node .gitnexus/run.cjs impact "<symbol>" --direction upstream --repo .` cho `SalesComposeCubit`, `SalesOrderComposePage`; báo blast radius, cảnh báo nếu HIGH/CRITICAL.

## Lưu ý dễ sót

- **Phải xoay `composeSessionId` khi về đơn mới.** Khóa idempotency lần lưu đầu = `composeSessionId + payloadHash` (`sales_draft_backend.dart`). Giữ khóa cũ mà đơn mới trùng nội dung đơn trước → server **replay trả lại nháp cũ** (có thể đã bị xoá) → lại kẹt. `_composeSessionId` hiện là `final` → đổi thành biến thường.
- **`draftGone` chỉ khi đang cập nhật nháp server** (`SalesComposeDraftRef.serverId(current.draftId) != null`). Lưu lần đầu (tạo mới) gặp lỗi → vẫn là `failed` như cũ.
- **`draftGone` không set `saveMessage`** — nếu set, `BlocListener` sẽ bắn thêm toast «Chưa lưu được». Page tự hiện toast riêng.
- **Huỷ debounce giá** khi `startNewDraft()` (`_quantityPricingDebounce?.cancel()`), tránh làm mới giá cho đơn cũ sau khi đã reset.
- `SalesDraftSaveResult` phải được export qua barrel `presentation.dart` (test import barrel).
- Sửa các test đang so `bool` (`expect(ok, isTrue)`, `expect(failed, isFalse)`, `expect(retried, isTrue)`) sang enum.

## Khảo sát

| Vị trí | Hiện trạng |
|---|---|
| `lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart` | `final String _composeSessionId` (dòng ~53, khởi tạo `'compose-${DateTime.now().microsecondsSinceEpoch}'`); `Future<bool> saveDraft()` (dòng ~425) — catch mọi lỗi → `status: error` + `message` → `false`; `loadDraft(String)` về trạng thái Loading rồi `hydrate()`; `_userSafeMessage` chỉ đọc `SalesExternalOperationException` |
| `…/sales_compose_state.dart:136` | `hasUnsavedChanges` = `unsaved || error` → lỗi lưu cũng tính «chưa lưu» (gây lặp sheet) |
| `lib/features/sales/presentation/pages/sales_order_compose_page.dart:238` | `_saveDraft({navigateToDrafts})`: `ok` → toast «Đã lưu đơn nháp.»; `navigateToDrafts` → `SalesDraftsRoute().pushReplacement`, ngược lại `SalesDraftListCubit.load()` |
| `…/pages/sales_order_compose_page.dart:75` `_openDrafts` | back không chọn gì (`pick == null`) → `return`, không kiểm tra nháp đang giữ |
| `modules/sales/infrastructure/lib/src/domain/sales_order_draft/supabase_sales_order_draft_gateway.dart` | map lỗi server ra `SalesContractException` với code ổn định gồm `STALE_DATA`, `REFERENCE_UNAVAILABLE` |
| `test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart` | 4 test dùng kết quả `bool` của `saveDraft()` |
| `test/features/sales/sales_flow_pages_test.dart:252` | `'SG-02 save draft … keeps server draft id'` — kỳ vọng `draftId == 'draft-saved-1'` sau lưu (sẽ đổi) |

## File Structure

- Modify: `apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_draft_contracts.dart` — thêm enum `SalesDraftSaveResult`.
- Modify: `apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart` — `saveDraft()` trả enum; `startNewDraft()`; `_composeSessionId` xoay được.
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart` — `_saveDraft` xử lý 3 kết quả.
- Test: `apps/erp/test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart`, `apps/erp/test/features/sales/sales_flow_pages_test.dart`.

---

### Task 1: Cubit — `SalesDraftSaveResult` + `startNewDraft()`

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_draft_contracts.dart`
- Modify: `apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart`
- Test: `apps/erp/test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart`

**Interfaces:**
- Produces:
  - `enum SalesDraftSaveResult { saved, failed, draftGone }`
  - `Future<SalesDraftSaveResult> SalesComposeCubit.saveDraft()`
  - `Future<void> SalesComposeCubit.startNewDraft()`

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "SalesComposeCubit" --direction upstream --repo .`

- [ ] **Step 2: Sửa test cũ sang enum**

Trong `sales_compose_draft_backend_test.dart`:
- `expect(ok, isTrue);` (3 chỗ) → `expect(ok, SalesDraftSaveResult.saved);`
- `expect(failed, isFalse);` → `expect(failed, SalesDraftSaveResult.failed);`
- `expect(retried, isTrue);` → `expect(retried, SalesDraftSaveResult.saved);`

- [ ] **Step 3: Viết test mới (fail)**

Thêm vào `group('SalesComposeCubit draft backend', …)`:

```dart
    test('updating a draft that is no longer active reports draftGone without a toast message', () async {
      var calls = 0;
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          calls += 1;
          if (calls == 1) {
            return _draftDto(
              draftId: 'server-draft-1',
              version: 1,
              lines: request.lines,
              customer: request.customer,
              orderNote: request.orderNote,
            );
          }
          throw const SalesContractException(
            'STALE_DATA',
            message: 'Draft is no longer active.',
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      expect(await cubit.saveDraft(), SalesDraftSaveResult.saved);

      cubit.setOrderNote('Sửa sau khi nháp bị xoá');
      final result = await cubit.saveDraft();

      expect(result, SalesDraftSaveResult.draftGone);
      expect(cubit.state.saveMessage, isNull);
    });

    test('first save failure stays failed even for a stale-looking error', () async {
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (_) async => throw const SalesContractException('STALE_DATA'),
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();

      expect(await cubit.saveDraft(), SalesDraftSaveResult.failed);
    });

    test('startNewDraft resets to an empty order and rotates the compose session', () async {
      final persistCalls = <SalesDraftPersistRequest>[];
      var nextId = 0;
      final cubit = _cubit(
        draftId: 'draft-new',
        persist: (request) async {
          persistCalls.add(request);
          nextId += 1;
          return _draftDto(
            draftId: 'server-draft-$nextId',
            version: 1,
            lines: request.lines,
            customer: request.customer,
            orderNote: request.orderNote,
          );
        },
      );
      addTearDown(cubit.close);

      await cubit.hydrate();
      cubit.addOrIncrementLine(_selection);
      await _flush();
      await cubit.saveDraft();
      final firstSession = persistCalls.single.composeSessionId;

      await cubit.startNewDraft();

      expect(cubit.state.draftId, SalesComposeDraftRef.newDraft);
      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.hasUnsavedChanges, isFalse);
      expect(cubit.composeSessionId, isNot(firstSession));

      cubit.addOrIncrementLine(_selection);
      await _flush();
      expect(await cubit.saveDraft(), SalesDraftSaveResult.saved);
      expect(persistCalls, hasLength(2));
      expect(persistCalls[1].draftId, isNull);
      expect(persistCalls[1].composeSessionId, isNot(firstSession));
      expect(cubit.state.draftId, 'server-draft-2');
    });
```

- [ ] **Step 4: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart`
Expected: FAIL (compile) — `SalesDraftSaveResult` / `startNewDraft` chưa tồn tại.

- [ ] **Step 5: Enum kết quả lưu**

Cuối `sales_draft_contracts.dart` thêm:

```dart
/// Outcome of saving the draft being composed.
enum SalesDraftSaveResult {
  saved,

  /// Ordinary failure: keep the edits and let the user retry.
  failed,

  /// The server draft is gone (cancelled, missing, or changed elsewhere):
  /// retrying can never succeed, so the page must leave this draft.
  draftGone,
}
```

Kiểm tra `lib/features/sales/presentation.dart` có `export 'presentation/bloc/sales_order_draft/sales_draft_contracts.dart';` (nếu chưa có thì thêm).

- [ ] **Step 6: `composeSessionId` xoay được**

Trong `SalesComposeCubit`:
- Đổi `final String _composeSessionId;` → `String _composeSessionId;`
- Trong initializer, thay `: 'compose-${DateTime.now().microsecondsSinceEpoch}',` bằng `: _newComposeSessionId(),`
- Thêm (gần `composeSessionId` getter):

```dart
  static String _newComposeSessionId() => 'compose-${DateTime.now().microsecondsSinceEpoch}';
```

- [ ] **Step 7: `startNewDraft()`**

Ngay sau `loadDraft(...)`:

```dart
  /// Starts a fresh empty order after the current draft was saved or is gone.
  /// Rotates the compose session so the next first save gets a new
  /// idempotency identity instead of replaying the previous draft.
  Future<void> startNewDraft() async {
    _quantityPricingDebounce?.cancel();
    _composeSessionId = _newComposeSessionId();
    await loadDraft(SalesComposeDraftRef.newDraft);
  }
```

- [ ] **Step 8: `saveDraft()` trả enum**

- Chữ ký: `Future<bool> saveDraft() async {` → `Future<SalesDraftSaveResult> saveDraft() async {`
- 3 dòng guard đầu hàm `return false;` → `return SalesDraftSaveResult.failed;`
- Nhánh thành công: `if (isClosed) return false;` → `return SalesDraftSaveResult.failed;`; `return true;` → `return SalesDraftSaveResult.saved;`
- Thay khối `catch (error) { … }` bằng:

```dart
    } catch (error) {
      if (isClosed) return SalesDraftSaveResult.failed;
      // Updating a server draft that was cancelled, removed or changed
      // elsewhere can never succeed on retry; report it instead of looping.
      if (serverDraftId != null &&
          error is SalesContractException &&
          (error.code == 'STALE_DATA' || error.code == 'REFERENCE_UNAVAILABLE')) {
        _emitLoaded(
          save: current.save.copyWith(
            status: SalesComposeSaveStatus.error,
            clearMessage: true,
          ),
        );
        return SalesDraftSaveResult.draftGone;
      }
      _emitLoaded(
        save: current.save.copyWith(
          status: SalesComposeSaveStatus.error,
          message: _userSafeMessage(
            error,
            fallback: 'Không lưu được đơn nháp. Vui lòng thử lại.',
          ),
        ),
      );
      return SalesDraftSaveResult.failed;
    }
```

(`SalesContractException` đến từ `package:vet45_sales_application/application.dart` — cubit đã import.)

- [ ] **Step 9: Chạy test**

Run: `cd apps/erp && flutter test test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart`
Expected: PASS toàn bộ (test cũ + 3 test mới). Page chưa sửa nên `flutter analyze` còn lỗi ở `sales_order_compose_page.dart` — xử lý ở Task 2.

- [ ] **Step 10: Tóm tắt, dừng chờ review** (commit gộp sau Task 2 vì Task 1 đơn lẻ không compile được app).

---

### Task 2: Page — reset sau lưu, xử lý `draftGone`

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart`
- Test: `apps/erp/test/features/sales/sales_flow_pages_test.dart`

**Interfaces:**
- Consumes: `SalesDraftSaveResult`, `SalesComposeCubit.startNewDraft()` (Task 1).

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "SalesOrderComposePage" --direction upstream --repo .`

- [ ] **Step 2: Sửa test page (fail)**

Trong `sales_flow_pages_test.dart`, test `'SG-02 save draft dispatches backend persist and keeps server draft id'`:
- Đổi tên thành `'SG-02 save draft dispatches backend persist then resets to a new order'`.
- Thay:

```dart
    expect(cubit.state.draftId, 'draft-saved-1');
    expect(cubit.state.draftVersion, 1);
    expect(find.text('Đã lưu đơn nháp.'), findsOneWidget);
```

bằng:

```dart
    expect(cubit.state.draftId, SalesComposeDraftRef.newDraft);
    expect(cubit.state.lines, isEmpty);
    expect(cubit.state.hasUnsavedChanges, isFalse);
    expect(find.text('Đã lưu đơn nháp.'), findsOneWidget);
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/sales_flow_pages_test.dart --plain-name "SG-02 save draft"`
Expected: FAIL (compile ở page, hoặc `draftId` vẫn là `draft-saved-1`).

- [ ] **Step 4: Sửa `_saveDraft`**

Thay nguyên hàm `_saveDraft` bằng:

```dart
  Future<bool> _saveDraft({required bool navigateToDrafts}) async {
    final result = await _cubit.saveDraft();
    if (!mounted) return false;
    switch (result) {
      case SalesDraftSaveResult.failed:
        return false;
      case SalesDraftSaveResult.draftGone:
        VToast.show(
          context,
          title: 'Đơn nháp không còn',
          message: 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác. Đã chuyển sang đơn mới.',
          type: VToastType.warning,
        );
      case SalesDraftSaveResult.saved:
        _showDraftSavedToast();
    }
    if (navigateToDrafts) {
      setState(() => _allowPop = true);
      const SalesDraftsRoute().pushReplacement(context);
      return result == SalesDraftSaveResult.saved;
    }
    await _cubit.startNewDraft();
    if (!mounted) return false;
    await context.read<SalesDraftListCubit>().load();
    return result == SalesDraftSaveResult.saved;
  }
```

(Import `SalesDraftSaveResult` đã có qua `package:erp/features/sales/presentation.dart`.)

- [ ] **Step 5: Chạy test + analyze**

```bash
cd apps/erp
flutter test test/features/sales/sales_flow_pages_test.dart test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart
flutter test test/features/sales/
flutter analyze lib/features/sales/presentation/bloc/sales_order_draft/ lib/features/sales/presentation/pages/sales_order_compose_page.dart test/features/sales/sales_flow_pages_test.dart test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart
```

Expected: PASS toàn bộ; analyze «No issues found!». Test khác fail → so baseline bằng `git stash` để xác nhận không do plan này.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_draft_contracts.dart apps/erp/lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart apps/erp/lib/features/sales/presentation/pages/sales_order_compose_page.dart apps/erp/test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart apps/erp/test/features/sales/sales_flow_pages_test.dart
git commit -m "fix(sales): lưu nháp xong về đơn mới, thoát kẹt khi nháp đã bị xoá"
```

(User tự commit; nếu `presentation.dart` phải thêm export thì add kèm.)

---

## Kiểm tra thủ công (user)

| Kịch bản | Kỳ vọng |
|---|---|
| Tạo đơn (khách + 1 sản phẩm) → «Lưu nháp» | Toast «Đã lưu đơn nháp.»; màn **về đơn mới trống**; số «Đơn nháp (n)» tăng 1 |
| Kịch bản lỗi gốc: lưu nháp → mở nháp đó từ «Đơn nháp (n)» → sửa số lượng → «Đơn nháp (n)» → **xoá chính nháp đó** → back → back → «Lưu nháp và đóng» | Toast «Đơn nháp không còn…»; **sang danh sách nháp**; không còn vòng lặp sheet |
| Như trên nhưng thay bước cuối bằng bấm nút «Lưu nháp» ở dưới | Toast «Đơn nháp không còn…»; màn **về đơn mới trống** |
| Mở nháp A → sửa → người khác xoá A (tab «Tất cả đơn nháp», máy khác) → «Lưu nháp» | Như dòng trên |
| Lưu nháp → «Đơn nháp (n)» → xoá nháp vừa lưu → back | Màn soạn đơn trống (vì đã reset sau lưu), back tiếp thoát bình thường |
| Lỗi mạng khi lưu | Như cũ: toast «Chưa lưu được…», giữ dữ liệu, thử lại được |
