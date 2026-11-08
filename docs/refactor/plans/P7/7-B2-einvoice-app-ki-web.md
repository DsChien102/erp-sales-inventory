# 7-B2 — E-invoice: sửa KI phía app (KI-01, KI-08) + bố cục web

> **For agentic workers:** REQUIRED SUB-SKILL: dùng superpowers:subagent-driven-development (khuyên dùng) hoặc superpowers:executing-plans để làm theo từng task. Các bước dùng checkbox (`- [ ]`).

> Theme 8 (mã cũ P7) · Bước (b) sửa theo TH-08, phía app · Gồm việc 7.2, 7.3 (KI-01, KI-08, bố cục web) — PLAN.md mục Theme 8
> Trạng thái: Plan ✅ (duyệt 2026-11-08) | Làm ⬜ | Review ⬜
> Trước: 7-A2a (4 trang thiết lập), 7-A2b (khu HĐĐT trên đơn) — đều Review ✅. Sau: 7-C (xoá module).
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) US-01.2 FR-05, US-04.2 FR-03 / FR-05 / AC-06, 5.1, 5.3, 5.4, 5.11, 5.13, KI-01, KI-08; PLAN.md "Thiết bị (chốt 2026-10-20)", "Plan xoá / tách / thay code cũ"; [DEV-LIVE-ACCEPTANCE-CHECKLIST](../../../themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md). Mẫu: `plans/P7/7-A2b-einvoice-ui-tren-don.md`.

**Goal:** HD-04 hiện thời điểm đồng bộ thật (KI-01), HD-12 tóm tắt đúng lần gửi thành công và đúng bố cục TH-08 (KI-08), giờ hiển thị theo giờ máy, và HD-03 / HD-07 … HD-12 thành hộp thoại trên web (sheet trên iPhone).

**Architecture:** Chỉ sửa `apps/erp/lib/features/einvoice` (không đụng server, không migration). HD-04 cubit đọc thêm `getConnectionScreen()` (lỗi thì bỏ dòng). 7 hàm `show…` chuyển sang `showVAdaptiveSheet(title:)`, tiêu đề trong nội dung bỏ đi. HD-01 … HD-05, HD-13 đã nằm trong cột 720 của `VPageScaffold` — chỉ thêm test.

**Tech Stack:** Dart / Flutter, `flutter_bloc`, `flutter_test`, `vet45_design_system` (`showVAdaptiveSheet`, `VSheetDialog`, `VBottomSheet`, `VBreakpoints`).

## Global Constraints

- **Chữ giữ nguyên:** mọi chuỗi lấy từ hằng copy đang có (`OrderEInvoiceCopy`, `OrderEInvoicePostIssueCopy`, `OrderInvoiceDeliveryCopy`, `DisconnectProviderSheet.*`). Chuỗi mới duy nhất: tiền tố `'Đồng bộ gần nhất: '` (TH-08 US-01.2 FR-05).
- **`Key` giữ nguyên:** `wgt_e01_u01_fr08_01`, `wgt_e01_u02_fr04_01`, `action_issue`, `action_preview`, `action_send`, `action_confirm_issue`, `action_cancel_issue`, `action_view_official`, `action_documents`, `action_save_pdf`, `action_save_xml`, `field_recipient_email`, `action_send_invoice`, `action_cancel_send`, `label_suggestion_source`, `action_view_delivery_history`.
- **Giá trị trả về của hàm `show…` giữ nguyên** (kiểu và giá trị khi bấm / khi đóng ngoài). `showDisconnectProviderSheet` vẫn trả `Future<bool>`.
- **Đổi hành vi chỉ ở** các dòng ghi "đổi có chủ đích" trong bảng 3.1 (Q1 … Q5).
- **Không đụng:** server / migration / Edge Function; `modules/einvoice/**` (7-C); khối HĐĐT trên trang đơn (bố cục Theme 5); `VPageScaffold`, `showVAdaptiveSheet` của design system.
- **Không có bước DB / deploy / reset** trong phiên code. Mục 6.6 (checklist live) do người dùng chạy.
- **Trước khi sửa symbol đang có** (danh sách ở từng Task): chạy `impact({target, direction: "upstream"})`, ghi vào Kết quả; HIGH / CRITICAL thì dừng, báo người dùng.
- **Ghi Kết quả ngay sau mỗi task** theo mẫu mục 8. Phiên code không ghi mục 9.

## Review Focus

1. **Bàn phím che nút trên iPhone (HD-11 / HD-12):** bỏ `SafeArea` trong nội dung vẫn còn `SafeArea` + `viewInsets` của `showVBottomSheet` ⇒ nút "Gửi hóa đơn" không bị che (Task 3 `send sheet keeps primary visible with keyboard`).
2. **Snackbar lỗi khi sheet đang mở trên web:** lỗi gửi vẫn hiện snackbar và hộp thoại giữ mở (Task 3 `desktop send failure keeps dialog open`).
3. **HD-13 mở từ hộp thoại trên web:** trang lịch sử đẩy lên trên hộp thoại; quay lại thì về hộp thoại HD-12, không mất email đã sửa (Task 3 `desktop history push returns to resend dialog`).
4. **Đọc kết nối chậm / lỗi trên HD-04:** trang vẫn hiện, không có dòng đồng bộ; lỗi không đổi thành trạng thái lỗi tải (Task 1 `connection read failure hides synced line`).
5. **Giờ quanh nửa đêm UTC:** `2026-08-04T20:30Z` hiện `03:30, 05/08/2026` ở múi +7 (Task 1 `formats in local time`).

---

## 1. Mục tiêu

- KI-01: HD-04 dòng phụ ô "Mẫu hóa đơn" = `Đồng bộ gần nhất: HH:mm, dd/MM/yyyy` từ `last_verified_at` (qua `ProviderConnectionSummaryDto.lastCheckedAt`); không có / đọc lỗi → không có dòng. Hằng `EInvoiceConfigurationDisplay.lastSyncedLabel` xoá.
- KI-08: HD-12 dòng "Đã gửi gần nhất đến …" lấy lần `DeliveryStatus.succeeded` **cuối** trong `history`; không có lần thành công → ẩn dòng.
- HD-12 khớp TH-08 5.11: nhãn nguồn hiện khi có gợi ý; dòng tóm tắt nằm dưới ô email, ngay trên "Xem lịch sử gửi".
- Giờ HĐĐT (`EInvoiceDateTimeCopy`) hiển thị theo giờ máy (HD-02 hết lệch 7 giờ).
- Web (≥ `VBreakpoints.desktop`): HD-03, HD-07, HD-08, HD-09, HD-10, HD-11, HD-12 là `VSheetDialog` có tiêu đề + nút "Đóng"; iPhone là `VBottomSheet` có tiêu đề ở header. HD-01 … HD-05, HD-13 trong cột 720 (đã có, thêm test).

**Không làm:** phím Enter gửi form email; bố cục khối HĐĐT trên trang đơn (Theme 5); đổi `VPageScaffold` / `showVAdaptiveSheet`; gỡ module (7-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | KI-01 lấy giờ từ đâu (cubit HD-04 chỉ gọi `getIssuanceProfile` + `listTemplates`) | **Người dùng chốt 2026-11-08:** cubit gọi thêm `getConnectionScreen()` sau 2 lời gọi cũ, `try/catch` riêng; lỗi hoặc `lastCheckedAt == null` → bỏ dòng. Không sửa server. `last_verified_at` do handler `sync_capabilities` ghi (`supabase/functions/einvoice-processor/index.ts:54` → `record_*` `20261031003:118`), cùng lúc đồng bộ mẫu |
| Q2 | Tiêu đề sheet khi đổi sang `showVAdaptiveSheet` | **Người dùng chốt 2026-11-08:** truyền `title:` + `semanticLabel:` (hằng copy đang dùng); bỏ dòng tiêu đề `headingH3`, `SafeArea` và padding trên trong nội dung (giống 8-B3 `sales_record_payment_sheet.dart:63-66`). iPhone: tiêu đề chuyển lên header `VBottomSheet` (chữ giữ, vị trí đổi — **đổi có chủ đích**) |
| Q3 | HD-03 code là `showVConfirmDialog` (cả iPhone), TH-08 5.1 ghi bottom sheet | **Người dùng chốt 2026-11-08:** `showVAdaptiveSheet(title: DisconnectProviderSheet.title)`; nội dung = message + nút "Ngắt kết nối" (`VButton` primary, `tone: VComponentTone.danger` — như `VConfirmDialog` `v_modal.dart:79`) + "Giữ kết nối". **Đổi có chủ đích** |
| Q4 | HD-12 lệch TH-08 ngoài KI-08: thiếu nhãn nguồn (FR-03), dòng tóm tắt nằm trên ô email | **Người dùng chốt 2026-11-08:** sửa cả hai. **Đổi có chủ đích** |
| Q5 | `EInvoiceDateTimeCopy` không gọi `toLocal()`; mapper `configuration_json.dart:49-50` trả UTC ⇒ HD-02 lệch 7 giờ | **Người dùng chốt 2026-11-08:** sửa trong 7-B2 — `_hm` / `_dmy` dùng `value.toLocal()`. **Đổi có chủ đích**, ghi **KI-27** TH-08 |
| Q6 | HD-01 … HD-05, HD-13 trên web | Đã dùng `VPageScaffold` mặc định (`v_page_scaffold.dart:41-45`: desktop 720) ⇒ không sửa code, thêm test bề rộng 1280. **Duyệt plan là chốt** |
| Q7 | HD-03 nội dung căn giữa (như sheet xác nhận partner) hay căn trái | Căn trái như HD-08 (cùng feature). **Duyệt plan là chốt** |
| Q8 | Checklist live (7-E3 Q3) | Người dùng chạy (cần MISA testapi, Edge Function đã deploy, Dev đã reset — việc của người dùng); plan chỉ ghi các bước bấm (mục 6.6) |

## 3. Hiện trạng (đo 2026-11-08, commit `a26db5628`)

- HD-04: `default_issuance_configuration_view.dart:123` `helperText: EInvoiceConfigurationDisplay.lastSyncedLabel` (`einvoice_configuration_display.dart:7`). Cubit `default_issuance_configuration_cubit.dart:26-48`. State `DefaultIssuanceConfigurationLoaded` (`default_issuance_configuration_state.dart:20-73`) chưa có trường giờ.
- `EInvoiceDateTimeCopy` (`presentation/support/einvoice_datetime_copy.dart`): `checkedAt` (không ai gọi), `updatedAt` (`provider_connection_view.dart:364`). Test `provider_connection_view_test.dart:133` kỳ vọng `'Cập nhật gần nhất: 10:40, 05/08/2026'` từ `DateTime.utc(2026, 8, 5, 10, 40)` (fixture `fake_einvoice_configuration_repository.dart:61`) — chỉ đúng khi máy chạy test ở UTC.
- HD-12: `resend_invoice_sheet.dart:88-108` `_latestSummary()` lấy `history.last` bất kể trạng thái; `history` rỗng → `'Đã gửi gần nhất đến <suggested> · —'`. Dòng tóm tắt ở `:149-153` (trên form); form `:155-174` không truyền `sourceLabel`. Server trả `history` theo `delivery_no` tăng (`20261031013` `get_send_invoice_sheet_context`, `order by d.delivery_no`), `suggested_email_source = 'LAST_INVOICE_DELIVERY'` ở chế độ gửi lại. Nhãn đã có: `OrderInvoiceDeliveryCopy.suggestionSource` (`order_invoice_delivery_copy.dart:28-35`). HD-11 truyền nhãn ở `send_invoice_sheet.dart:81-84,129-135`.
- 6 hàm `showVBottomSheet`: `pre_issue_einvoice_action_sheet.dart:56`, `issue_invoice_confirmation_sheet.dart:39`, `post_issue_einvoice_action_sheet.dart:41`, `invoice_documents_action_sheet.dart:34`, `send_invoice_sheet.dart:17`, `resend_invoice_sheet.dart:18`. Mỗi nội dung tự vẽ `Material` trong suốt + `SafeArea(top: false)` + tiêu đề `VText(headingH3, w700)` (`pre_issue :97-118`, `issue_confirmation :97-115`, `post_issue :81-102`, `documents :104-125`, `send :100-119`, `resend :130-148`).
- HD-03: `disconnect_provider_sheet.dart:32-46` `showVConfirmDialog`; widget `DisconnectProviderSheet` (`:4-30`) bọc `VConfirmDialog` có `Key('wgt_e01_u01_fr08_01')`, không ai dựng trực tiếp ngoài test. Người gọi: `provider_connection_view.dart:263`.
- `showVBottomSheet` (`v_bottom_sheet.dart:97-130`) đã bọc nội dung bằng `SafeArea(top: false)` + `Padding(bottom: viewInsets)`; có `title` thì vẽ tiêu đề + `VDivider`. `VSheetDialog` (`v_adaptive_sheet.dart:16-130`) có `title` thì header + nút "Đóng" + `SingleChildScrollView(child)` **không padding**; rộng tối đa 480.
- Test đang kiểm tiêu đề bằng cách dựng widget trực tiếp (sẽ phải mở qua hàm `show…`): `pre_issue_einvoice_action_sheet_test.dart:23`, `post_issue_einvoice_action_sheet_test.dart:29`, `issue_invoice_confirmation_sheet_test.dart:31`, `invoice_documents_action_sheet_test.dart:73`, `send_invoice_sheet_test.dart:84,225`, `resend_invoice_sheet_test.dart:124`; qua section: `order_einvoice_section_test.dart:891,1141`. HD-03: `provider_connection_overlays_test.dart` (1 ca).
- Bố cục trang: 5 trang (`automation_policy_page.dart:28`, `default_issuance_configuration_page.dart:28`, `einvoice_configuration_overview_page.dart:72`, `provider_connection_page.dart:28`, `invoice_delivery_history_page.dart:39`) dùng `VPageScaffold` không truyền `contentMaxWidth`.

### 3.1 Đang làm gì (giữ hành vi)

Thứ bị thay: 7 hàm `show…`, phần đầu của 7 nội dung sheet, `_latestSummary`, `EInvoiceDateTimeCopy`, hằng `lastSyncedLabel`.

| # | Cơ chế cũ (nguồn) | Hành vi | Sau 7-B2 nằm ở | Test giữ hành vi |
|---|---|---|---|---|
| H1 | Tiêu đề trong nội dung (7 sheet) | Hiện đúng 1 lần chữ tiêu đề | `title:` của `showVAdaptiveSheet` — **vị trí đổi (Q2)** | B0-1 … B0-7 `title shown once` |
| H2 | `SafeArea(top: false)` trong nội dung | Không đè vùng home indicator | `SafeArea` của `showVBottomSheet` (`v_bottom_sheet.dart:122-128`) | Task 3 `send sheet keeps primary visible with keyboard` |
| H3 | `SingleChildScrollView` trong nội dung | Cuộn khi thấp / bàn phím mở | giữ trong nội dung | cùng ca H2 |
| H4 | `Navigator.pop(<action>)` ở HD-07 / 09 / 10 | Hàm `show…` trả đúng enum | giữ | B0-1, B0-3, B0-4 `tap returns action` |
| H5 | HD-08 `pop(true)` / huỷ → `false` (`result ?? false`) | `Future<bool>` | giữ | B0-2 |
| H6 | HD-11 / 12 `submit` thành công → `pop(true)`; lỗi → snackbar, sheet mở | giữ | B0-5, B0-6 (đã có ca lỗi trong `send_invoice_sheet_test`, chỉ đổi cách mở) |
| H7 | HD-07 / 09 / 10 cập nhật qua `StreamBuilder(states)` | Mục đang tải / mờ đổi khi stream phát | giữ (chỉ đổi hàm bọc) | các ca đã có của 3 tệp test |
| H8 | HD-03 `showVConfirmDialog` → `true` khi bấm "Ngắt kết nối", `false` khi "Giữ kết nối" / đóng ngoài | **Đổi có chủ đích (Q3)**: sheet trên iPhone; kết quả giữ | B0-8 |
| H9 | `_latestSummary` `history.last` | **Đổi có chủ đích (KI-08)**: lần `succeeded` cuối; không có → ẩn | Task 2 |
| H10 | Dòng tóm tắt trên form, không nhãn nguồn | **Đổi có chủ đích (Q4)** | Task 2 |
| H11 | `EInvoiceDateTimeCopy` lấy giờ thô | **Đổi có chủ đích (Q5)**: `toLocal()` | Task 1 |
| H12 | HD-04 dòng phụ cố định | **Đổi có chủ đích (KI-01)** | Task 1 |
| H13 | HD-12 `onViewHistory(sheetNavContext)` push `MaterialPageRoute` | Trang lịch sử trên sheet; quay lại về sheet | giữ (`order_einvoice_section.dart:338`) | Task 3 `desktop history push returns to resend dialog` |

## 4. Tệp

Sửa (`apps/erp/lib/features/einvoice/`):

| Tệp | Việc |
|---|---|
| `logic/default_issuance_configuration_cubit.dart`, `logic/default_issuance_configuration_state.dart` | Q1 |
| `logic/einvoice_configuration_display.dart` | xoá `lastSyncedLabel` |
| `presentation/support/einvoice_datetime_copy.dart` | Q5 + `syncedAt` |
| `presentation/widgets/default_issuance_configuration_view.dart` | `helperText` |
| `presentation/widgets/resend_invoice_sheet.dart` | KI-08, Q4, Q2 |
| `presentation/widgets/{pre_issue_einvoice_action_sheet,issue_invoice_confirmation_sheet,post_issue_einvoice_action_sheet,invoice_documents_action_sheet,send_invoice_sheet}.dart` | Q2 |
| `presentation/widgets/disconnect_provider_sheet.dart` | Q3 |

Test: `apps/erp/test/features/einvoice/` — tạo `presentation/widgets/einvoice_sheets_adaptive_test.dart`, `presentation/einvoice_pages_web_layout_test.dart`, `presentation/support/einvoice_datetime_copy_test.dart`; sửa các tệp ở mục 3 (dòng "Test đang kiểm tiêu đề"), `logic/default_issuance_configuration_cubit_test.dart`, `presentation/widgets/default_issuance_configuration_view_test.dart`, `presentation/widgets/provider_connection_view_test.dart:133`, `presentation/widgets/resend_invoice_sheet_test.dart`.

Tài liệu: `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` (KI-01, KI-08 cột cuối; thêm KI-27; 5.4 bỏ 🔧 KI-01; 5.11 bỏ 🔧 KI-08; 5.13 thêm dòng bố cục web), `docs/refactor/PLAN.md` (dòng 7-B2), `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md` (người dùng ghi kết quả).

## 5. Giao diện mới

```dart
// logic/default_issuance_configuration_state.dart
final class DefaultIssuanceConfigurationLoaded … {
  const DefaultIssuanceConfigurationLoaded({…, this.lastSyncedAt});
  final DateTime? lastSyncedAt;          // thêm vào props; copyWith giữ nguyên giá trị (không có tham số đổi)
}

// presentation/support/einvoice_datetime_copy.dart
static String syncedAt(DateTime value);  // 'Đồng bộ gần nhất: HH:mm, dd/MM/yyyy' theo giờ máy

// presentation/widgets/resend_invoice_sheet.dart (hàm top-level, để test được)
InvoiceDeliveryItemDto? latestSuccessfulDelivery(List<InvoiceDeliveryItemDto> history);
// duyệt từ cuối, trả phần tử đầu tiên có status == DeliveryStatus.succeeded; không có → null
```

Thời điểm in ở dòng tóm tắt: `completedAt ?? startedAt` của lần đó, `toLocal()`, định dạng `dd/MM/yyyy, HH:mm` (giữ như `:96-103`).

Mỗi hàm `show…` sau Q2 (tiêu đề → `title:` và `semanticLabel:` cùng giá trị):

| Hàm | `title` |
|---|---|
| `showPreIssueEInvoiceActionSheet` | `OrderEInvoiceCopy.sheetTitle` |
| `showIssueInvoiceConfirmationSheet` | `OrderEInvoiceCopy.issueConfirmationTitle` |
| `showPostIssueEInvoiceActionSheet` | `OrderEInvoicePostIssueCopy.sheetTitle` |
| `showInvoiceDocumentsActionSheet` | `OrderEInvoicePostIssueCopy.documentsSheetTitle` |
| `showOrderInvoiceSendSheet` | `OrderInvoiceDeliveryCopy.sendTitle` |
| `showOrderInvoiceResendSheet` | `OrderInvoiceDeliveryCopy.resendTitle` |
| `showDisconnectProviderSheet` | `DisconnectProviderSheet.title` |

Padding nội dung sau Q2: sheet danh sách thao tác (HD-07, 09, 10) không padding ngoài, mục `EInvoiceActionItem` sát mép như cũ, thêm `VGap.sm()` cuối; sheet form / xác nhận (HD-03, 08, 11, 12) `EdgeInsets.fromLTRB(space4, space3, space4, space4)`. `Material(color: transparent)` giữ (cho `InkWell`).

## 6. Task

### Task 0: Bước 0 — test giữ hành vi trên code cũ

**Files:** Create `apps/erp/test/features/einvoice/presentation/widgets/einvoice_sheets_adaptive_test.dart`

Chỉ thêm test, không sửa `lib/`. Mỗi ca mở sheet **qua hàm `show…`** từ một `VButton('Open')` trong `MaterialApp(theme: VTheme.lightTheme, home: Scaffold(body: Builder(...)))`, bề rộng iPhone `tester.view.physicalSize = Size(390, 844)`, `devicePixelRatio = 1` (reset trong `addTearDown`). Giữ kết quả `show…` vào biến để kiểm.

- [ ] **B0-1** `pre-issue: title shown once, tap issue returns issue` — `PreIssueSheetState(isProviderConnected: true, …)`; `find.text(OrderEInvoiceCopy.sheetTitle)` `findsOneWidget`; tap `Key('action_issue')` → kết quả `PreIssueAction.issue`.
- [ ] **B0-2** `issue confirmation: title once, confirm → true, cancel → false` (2 lượt mở).
- [ ] **B0-3** `post-issue: title once, tap documents returns documents`.
- [ ] **B0-4** `documents: title once, tap pdf returns pdf` (state `idle`).
- [ ] **B0-5** `send: title once, valid email + send returns true` — `FakeEInvoiceRepository` (`sendResult` mặc định), `OrderInvoiceDeliveryCubit` như `send_invoice_sheet_test.dart`.
- [ ] **B0-6** `resend: title once, history link calls onViewHistory`.
- [ ] **B0-7** `disconnect: title once, confirm → true, keep → false` — tap chữ `DisconnectProviderSheet.actionLabel` / `cancelLabel`.
- [ ] **B0-8** `disconnect: tap outside returns false` — `tester.tapAt(const Offset(10, 10))`.
- [ ] Chạy `cd apps/erp && flutter test test/features/einvoice/presentation/widgets/einvoice_sheets_adaptive_test.dart` → 8 ca PASS. Ca nào đỏ trên code cũ: dừng, ghi Kết quả, báo người dùng.
- [ ] Ghi số lỗi nền: `flutter test` cả `apps/erp` → ghi "đạt / lỗi" vào Kết quả làm mốc cho 5.4.
- [ ] Commit `test(einvoice): 7-B2 bước 0 — giữ hành vi 7 sheet HĐĐT`.

Sau Task 3 tám ca này vẫn phải xanh, không đổi điều kiện kiểm.

### Task 1: Giờ theo máy (Q5) + KI-01 HD-04

**Files:** Modify mục 4 dòng Q1 / Q5 / `lastSyncedLabel` / view; Test `presentation/support/einvoice_datetime_copy_test.dart` (tạo), `logic/default_issuance_configuration_cubit_test.dart`, `presentation/widgets/default_issuance_configuration_view_test.dart`, `presentation/widgets/provider_connection_view_test.dart`.

**Impact trước khi sửa:** `EInvoiceDateTimeCopy`, `DefaultIssuanceConfigurationCubit.load`, `DefaultIssuanceConfigurationLoaded`, `EInvoiceConfigurationDisplay`.

**Interfaces:** Produces `EInvoiceDateTimeCopy.syncedAt(DateTime)`, `DefaultIssuanceConfigurationLoaded.lastSyncedAt` (mục 5).

- [ ] **1.1 Test đỏ** `einvoice_datetime_copy_test.dart`: với `final v = DateTime.utc(2026, 8, 4, 20, 30); final l = v.toLocal();` kỳ vọng chuỗi dựng từ `l` (`'Đồng bộ gần nhất: ${hh(l)}:${mm(l)}, ${dd(l)}/${MM(l)}/${l.year}'`) cho `syncedAt`, tương tự `updatedAt` (`'Cập nhật gần nhất: '`) — ca `formats in local time`. Thêm ca giá trị local `DateTime(2026, 8, 5, 9, 5)` → `'Đồng bộ gần nhất: 09:05, 05/08/2026'`.
- [ ] **1.2 Test đỏ** cubit (`default_issuance_configuration_cubit_test.dart`):
  - `load reads connection after profile and templates` — `calls == ['getIssuanceProfile', 'listTemplates', 'getConnectionScreen']`; `state.lastSyncedAt == FakeEInvoiceConfigurationFixtures.connectedScreen().connection.lastCheckedAt`.
  - `connection read failure hides synced line` — lớp con override `getConnectionScreen` ném `AppException(EInvoiceErrorCodes.systemError)` → state là `Loaded`, `lastSyncedAt == null`.
  - `lastCheckedAt null keeps line hidden` — override trả `ProviderConnectionScreenDto` có `lastCheckedAt: null`.
  - `select and save keep lastSyncedAt` — sau `selectTemplate('tpl-2')` và `save()` thành công, `lastSyncedAt` không đổi.
- [ ] **1.3 Test đỏ** view: thay dòng `:74` bằng `find.text(EInvoiceDateTimeCopy.syncedAt(FakeEInvoiceConfigurationFixtures.connectedScreen().connection.lastCheckedAt!))` `findsOneWidget`; thêm ca `no synced line when connection read fails` → `find.textContaining('Đồng bộ gần nhất')` `findsNothing`. `provider_connection_view_test.dart:133` đổi kỳ vọng thành `EInvoiceDateTimeCopy.updatedAt(DateTime.utc(2026, 8, 5, 10, 40))` (điều kiện kiểm giữ: đúng chuỗi từ giá trị fixture).
- [ ] **1.4** Sửa: `_hm` / `_dmy` gọi trên `value.toLocal()`; thêm `syncedAt`; cubit `load()` sau `listTemplates` gọi `_readLastSyncedAt()` (`Future<DateTime?>`: `try { return (await _repository.getConnectionScreen()).connection.lastCheckedAt; } catch (_) { return null; }`); state thêm `lastSyncedAt`; view `helperText: state.lastSyncedAt == null ? null : EInvoiceDateTimeCopy.syncedAt(state.lastSyncedAt!)` (logic không import presentation: view tự định dạng); xoá `lastSyncedLabel`.
- [ ] **1.5** `flutter test test/features/einvoice/` → PASS; ghi số ca.
- [ ] **1.6** Commit `fix(einvoice): 7-B2 KI-01 HD-04 hiện giờ đồng bộ thật, giờ HĐĐT theo máy (KI-27)`.

### Task 2: KI-08 + bố cục HD-12 (Q4)

**Files:** Modify `presentation/widgets/resend_invoice_sheet.dart`; Test `presentation/widgets/resend_invoice_sheet_test.dart`.

**Impact trước khi sửa:** `OrderInvoiceResendSheet`, `_OrderInvoiceResendSheetState._latestSummary`.

**Interfaces:** Produces `latestSuccessfulDelivery` (mục 5).

- [ ] **2.1 Test đỏ** (`resend_invoice_sheet_test.dart`, dùng helper `delivery(...)` có sẵn, thêm tham số `status`):
  - `summary uses last successful delivery` — history `[#1 a@x.vn succeeded 05/08 09:20, #2 b@x.vn failed]` → `find.textContaining('Đã gửi gần nhất đến a@x.vn')` `findsOneWidget`, `find.textContaining('b@x.vn ·')` `findsNothing`.
  - `summary hidden without successful delivery` — history `[#1 failed, #2 processing]` → `find.textContaining('Đã gửi gần nhất')` `findsNothing`.
  - `summary hidden when history empty` — `findsNothing` (trước đây hiện "· —").
  - `source label shown for last invoice delivery` — `suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery` → `find.byKey(Key('label_suggestion_source'))` có chữ `'Lần gửi gần nhất của hóa đơn này'`.
  - `summary sits between email field and history link` — `tester.getTopLeft(field_recipient_email).dy < getTopLeft(summary).dy < getTopLeft(action_view_delivery_history).dy`.
  - `latestSuccessfulDelivery` unit: `[]` → null; `[s1, f2, s3, u4]` → `s3`.
- [ ] **2.2** Sửa: thêm `latestSuccessfulDelivery`; `_latestSummary()` trả `String?` (null khi không có lần thành công); bỏ `VText` tóm tắt ở trên form; `sourceLabel` dựng như `send_invoice_sheet.dart:129-135` (cùng `Key('label_suggestion_source')`); `footerAboveActions: Column(crossAxisAlignment: stretch, children: [if (summary != null) …[VText(summary, bodyDefault, textSecondary), VGap.sm()], Align(center, VButton link 'Xem lịch sử gửi' như cũ)])`.
- [ ] **2.3** `flutter test test/features/einvoice/presentation/widgets/resend_invoice_sheet_test.dart test/features/einvoice/presentation/order_einvoice_section_test.dart` → PASS. Ca cũ `:127` (kỳ vọng `accounting@company.com`) giữ nếu lần đó `succeeded`; nếu không, ghi lệch vào Kết quả.
- [ ] **2.4** Commit `fix(einvoice): 7-B2 KI-08 HD-12 tóm tắt lần gửi thành công, nhãn nguồn, đúng vị trí`.

### Task 3: 7 sheet → `showVAdaptiveSheet` (Q2, Q3)

**Files:** Modify 7 tệp sheet (mục 4); Test `einvoice_sheets_adaptive_test.dart` + các tệp ở mục 3 "Test đang kiểm tiêu đề", `provider_connection_overlays_test.dart`.

**Impact trước khi sửa:** 7 hàm `show…` (bảng mục 5), `DisconnectProviderSheet`, `PreIssueEInvoiceActionSheet`, `IssueInvoiceConfirmationSheet`, `PostIssueEInvoiceActionSheet`, `InvoiceDocumentsActionSheet`, `OrderInvoiceSendSheet`, `OrderInvoiceResendSheet`.

- [ ] **3.1 Test đỏ** trong `einvoice_sheets_adaptive_test.dart`, `group('desktop 1280x800')` (`physicalSize = Size(1280, 800)`), mỗi hàm 1 ca `<sheet>: desktop shows titled dialog`: sau khi mở → `find.byType(VSheetDialog)` `findsOneWidget`, `find.byType(VBottomSheet)` `findsNothing`, `find.text(<title>)` `findsOneWidget`, `find.byTooltip('Đóng')` `findsOneWidget`. Thêm `group('iphone 390x844')` mỗi hàm 1 ca `<sheet>: phone shows titled bottom sheet` → `find.byType(VBottomSheet)` `findsOneWidget`, tiêu đề `findsOneWidget`.
- [ ] **3.2 Test đỏ** các ca Review Focus:
  - `desktop: escape closes dialog` (HD-09) — `tester.sendKeyEvent(LogicalKeyboardKey.escape)` → kết quả `null`, không còn `VSheetDialog`.
  - `send sheet keeps primary visible with keyboard` (iPhone) — đặt `tester.view.viewInsets = FakeViewPadding(bottom: 300)`; `tester.getBottomLeft(find.byKey(Key('action_send_invoice'))).dy <= 844 - 300`.
  - `desktop send failure keeps dialog open` — `FakeEInvoiceRepository..throwOn['send'] = const AppException(EInvoiceErrorCodes.systemError)`; gửi → `find.byType(SnackBar)` `findsOneWidget`, `VSheetDialog` vẫn còn.
  - `desktop history push returns to resend dialog` — mở HD-12 với `onViewHistory: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('history'))))`; sửa email thành `'moi@x.vn'`, tap `action_view_delivery_history` → thấy `'history'`; `Navigator.pop` → `VSheetDialog` còn, ô email vẫn `'moi@x.vn'`.
- [ ] **3.3** Sửa 7 hàm `show…` theo bảng mục 5; nội dung bỏ tiêu đề + `SafeArea`, padding theo mục 5. HD-03: `DisconnectProviderSheet` thành nội dung sheet (`Column`: `VText(message)`, nút đỏ "Ngắt kết nối" → `Navigator.pop(true)`, nút "Giữ kết nối" → `pop(false)`), `Key('wgt_e01_u01_fr08_01')` trên gốc nội dung; `showDisconnectProviderSheet` trả `(await showVAdaptiveSheet<bool>(…)) ?? false`. Nút đỏ: `VButton(tone: VComponentTone.danger)` như `v_modal.dart:79`.
- [ ] **3.4** Sửa test cũ đang dựng widget trực tiếp mà kiểm tiêu đề (mục 3): chuyển sang mở qua hàm `show…` (helper dùng chung trong từng tệp); điều kiện kiểm giữ nguyên. `provider_connection_overlays_test.dart`: giữ 4 `expect` chữ.
- [ ] **3.5** `flutter test test/features/einvoice/` → PASS (gồm B0-1 … B0-8 không sửa điều kiện). Ghi số ca.
- [ ] **3.6** Commit `feat(einvoice): 7-B2 sheet HĐĐT thành hộp thoại trên web (HD-03, HD-07…12)`.

### Task 4: Test bố cục trang trên web (Q6)

**Files:** Create `apps/erp/test/features/einvoice/presentation/einvoice_pages_web_layout_test.dart`.

- [ ] **4.1** Với `physicalSize = Size(1280, 800)`, dựng 5 trang HD-01, HD-02, HD-04, HD-05 (qua page + `FakeEInvoiceConfigurationRepository` như `einvoice_configuration_overview_page_test.dart`) và HD-13 (`InvoiceDeliveryHistoryPage` + `FakeEInvoiceRepository`). Mỗi ca `<page>: desktop body is 720 column`: `tester.getSize(find.byType(VPagePadding).first).width == 720` (hoặc phần tử đầu của body nếu trang không dùng `VPagePadding` — ghi phần tử chọn vào Kết quả); ca `<page>: phone body is full width` ở 390 → `== 390`.
- [ ] **4.2** `flutter test test/features/einvoice/presentation/einvoice_pages_web_layout_test.dart` → PASS (10 ca). Ca nào đỏ: dừng, báo người dùng (Q6 sai).
- [ ] **4.3** Commit `test(einvoice): 7-B2 bố cục trang thiết lập và lịch sử gửi trên web`.

### Task 5: Kiểm cuối + tài liệu

- [ ] **5.1** `cd apps/erp && dart analyze lib test` → không lỗi / cảnh báo mới.
- [ ] **5.2** `dart run tool/check_feature_imports.dart` → không dòng mới.
- [ ] **5.3** `git grep -n "lastSyncedLabel\|showVBottomSheet\|showVConfirmDialog" -- apps/erp/lib/features/einvoice` → rỗng.
- [ ] **5.4** `flutter test` cả `apps/erp` → số lỗi không tăng so với mốc Task 0 (so từng tên).
- [ ] **5.5** TH-08: KI-01, KI-08 cột cuối "✅ 7-B2 (2026-…)"; thêm **KI-27** "HD-02 / HD-04 hiện giờ UTC (`EInvoiceDateTimeCopy` không `toLocal`) — sửa: định dạng theo giờ máy — ✅ 7-B2"; 5.4 bỏ 🔧 dòng "Mẫu hóa đơn"; 5.11 bỏ 🔧 dòng tóm tắt, ghi "lần gửi **thành công** gần nhất; không có thì ẩn"; 5.13 thêm "Web: HD-01 … HD-05, HD-13 cột 720; HD-03, HD-07 … HD-12 là hộp thoại (rộng 480) có tiêu đề + nút Đóng, Esc đóng". PLAN.md: dòng 7-B2 cột Làm.
- [ ] **5.6** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "compare", base_ref: "<commit trước Task 0>"})` → chỉ tệp mục 4 + test + tài liệu; ghi số tệp / symbol / luồng / rủi ro.
- [ ] **5.7** Kiểm tay giao diện (phiên code tự chạy được trên simulator / Chrome với dữ liệu giả hoặc Dev hiện có; không cần MISA): iPhone + Chrome rộng (≥ 1280) + Chrome hẹp (~ 600): HD-04 dòng đồng bộ; HD-03 sheet / hộp thoại; HD-07 … HD-12 mở đúng dạng, Tab đi qua các mục, Esc đóng hộp thoại; HD-13 từ HD-12 rồi quay lại.

### 6.6 Checklist live — người dùng chạy (7-E3 Q3)

Tiền đề (việc của người dùng): Dev đã `db reset`, Edge Function `einvoice-processor` deploy, cron chạy, MISA testapi kết nối, seed `TEST-HDDT-001` (checklist mục 2, 4.0, 4.1). Chạy `DEV-LIVE-ACCEPTANCE-CHECKLIST` mục 3 **bước 1 – 8 và 10** trên iPhone **và** Chrome rộng, ghi trạng thái từng bước (ĐẠT / Đang xử lý / LỖI + ảnh hoặc ghi chú) vào checklist, mục "Kết quả 7-B2 (ngày)". Bước 9 (script quan sát) và 11 (gửi tự động, fixture riêng) không thuộc 7-B2. Lỗi tìm được: ghi vào mục 8 dưới dạng việc cần sửa, không sửa trong phiên này.

## 7. Rủi ro / lưu ý

- **`VSheetDialog` bọc `SingleChildScrollView` không padding:** nội dung tự lo padding (mục 5); nội dung còn `SingleChildScrollView` riêng ⇒ cuộn lồng, chấp nhận (như 8-B3).
- **Snackbar dưới lớp phủ:** snackbar của trang hiện dưới barrier của hộp thoại / sheet — như hiện nay trên iPhone; không đổi.
- **Test giờ phụ thuộc múi máy:** mọi kỳ vọng giờ dựng từ `toLocal()` của chính giá trị, không viết cứng chuỗi UTC.
- **`order_einvoice_section_test` tìm `'Hóa đơn điện tử'`:** dòng HĐĐT và tiêu đề sheet cùng chữ; nếu ca nào đổi số lượng tìm thấy do tiêu đề chuyển lên header, ghi vào Kết quả, không đổi điều kiện kiểm khác.

## 8. Kết quả (phiên làm code ghi)

Mỗi task ghi ngay sau khi xong:

- **Task N — ✅ / ⚠️**
  - Tệp:dòng đã đổi / thêm:
  - Lệch plan + lý do:
  - Test thêm / sửa, lệnh, số ca pass / fail:
  - Impact (symbol, số caller, luồng, mức rủi ro):
  - Ghi chú cho review:

- **Task 0 — ✅** (`f36075a32`)
  - Tệp: `test/features/einvoice/presentation/widgets/einvoice_sheets_adaptive_test.dart` (B0-1 … B0-8 + ca desktop / iPhone của Task 3 cùng tệp).
  - Lệch plan: B0-7 / B0-8 chạy ở **600×844** (`_narrow`), không phải 390 — `VConfirmDialog` cũ tràn 126 px bên phải ở 390 nên nút "Ngắt kết nối" nằm ngoài màn, không bấm được (đúng lỗi Q3 sửa). Điều kiện kiểm giữ nguyên sau Task 3.
  - Mốc nền `flutter test` cả `apps/erp`: 55 ca đỏ sẵn (catalog, my_account, pricing, tenant_admin …, không thuộc einvoice); danh sách lưu để so từng tên.
  - Impact: gitnexus MCP không có trong phiên này — thay bằng `grep` người gọi; không có HIGH / CRITICAL.
- **Task 1 — ✅** (`ddeb10d8f`)
  - Tệp: `einvoice_datetime_copy.dart` (`toLocal()`, `syncedAt`), `default_issuance_configuration_{cubit,state}.dart` (`_readLastSyncedAt`, `lastSyncedAt`), `default_issuance_configuration_view.dart` (helperText), `einvoice_configuration_display.dart` (xoá `lastSyncedLabel`).
  - Test: `einvoice_datetime_copy_test.dart` (2), cubit +4, view +1 và sửa 1, `provider_connection_view_test` sửa 1. Đỏ trước (lỗi biên dịch) → xanh.
  - Ghi chú: `copyWith` luôn giữ `lastSyncedAt`.
- **Task 2 — ✅** (`e732a9538`)
  - Tệp: `resend_invoice_sheet.dart` (`latestSuccessfulDelivery`, `_latestSummary` → `String?`, `sourceLabel`, tóm tắt vào `footerAboveActions`). Test +6 trong `resend_invoice_sheet_test.dart`. Ca cũ `accounting@company.com` giữ nguyên (lần cuối `succeeded`). `order_einvoice_section_test` xanh.
- **Task 3 — ✅** (`9372028e2`)
  - Tệp: 7 tệp sheet → `showVAdaptiveSheet(title:, semanticLabel:)`; bỏ tiêu đề / `SafeArea` trong nội dung; `disconnect_provider_sheet.dart` viết lại (nút đỏ + "Giữ kết nối", `Key('wgt_e01_u01_fr08_01')` trên gốc nội dung, `DisconnectProviderSheet` không còn `onConfirm`).
  - Lệch plan: 4 test dựng widget trực tiếp (pre_issue, post_issue, issue_confirmation, documents) + send ×2 + resend ×1 **bỏ dòng kiểm tiêu đề** thay vì mở qua `show…` — tiêu đề giờ thuộc khung sheet, đã kiểm bởi B0-x và các ca desktop / iPhone trong `einvoice_sheets_adaptive_test.dart`. Điều kiện kiểm các dòng khác giữ nguyên.
  - Test: `flutter test test/features/einvoice/` → 447 pass, 0 fail (10 ca skip sẵn). 8 ca B0 xanh không đổi điều kiện.
- **Task 4 — ✅**
  - `einvoice_pages_web_layout_test.dart` 10 ca xanh. Phần tử đo: `VPagePadding` đầu tiên; **HD-13 không dùng `VPagePadding`** nên đo `InvoiceDeliveryHistoryView` (720 / 390).
- **Task 5 — ⚠️**
  - 5.1 `dart analyze lib test`: 259 issue, bằng mốc (stash so sánh). 5.2 `check_feature_imports`: chỉ dòng pricing cũ, không dòng einvoice. 5.3 `git grep` rỗng. 5.4 `flutter test` cả app: 55 đỏ, so từng tên: 0 mới, 0 hết.
  - 5.5 TH-08 (KI-01, KI-08, KI-27, 5.4, 5.11, 5.13) và PLAN.md đã sửa.
  - **Chưa làm:** 5.6 (`gitnexus detect_changes` — công cụ không có trong phiên) và 5.7 (kiểm tay trên simulator / Chrome). Mục 6.6 là việc của người dùng.
  - Ghi chú review: `dart format` đã chạm vài tệp ngoài phạm vi, đã hoàn nguyên; chỉ giữ thay đổi liên quan.

## 9. Review
