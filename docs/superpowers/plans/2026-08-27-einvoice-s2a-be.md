# Kế hoạch triển khai BE einvoice §S2a (Kiểm tra sẵn sàng + Hoàn thiện buyer + Xem trước hóa đơn)

> **Cho worker tự động:** SKILL PHỤ BẮT BUỘC: dùng superpowers:subagent-driven-development (khuyến nghị) hoặc superpowers:executing-plans để thực thi từng task. Các bước dùng checkbox (`- [ ]`) để theo dõi.

**Mục tiêu:** Xây backend cho slice §S2a của TH-08 — kiểm tra mức sẵn sàng phát hành theo đơn hàng, resolve/khóa dữ liệu người mua (EffectiveBuyerInvoiceData), và yêu cầu MISA tạo bản xem trước — **không** tạo IssuanceAttempt/ElectronicInvoice.

**Kiến trúc:** CQRS. Tầng domain giữ evaluator/value-object thuần (không đụng DB). Handler ở tầng application phụ thuộc **read port**; nguồn SalesOrder/BuyerInvoiceSnapshot (Theme 05) **chưa tồn tại trong DB**, nên các port đó đi qua một **fake seam** (fake chạy test ngay bây giờ; impl Supabase RPC mỏng để sẵn cho khi Theme 05 landing). Preview MISA chạy dạng worker job bền (`einvoice.preview_invoice`), mô phỏng theo job `einvoice.sync_capabilities` đã có ở S1.

**Tech stack:** Dart 3 (monorepo melos), CQRS kernel `vet45_shared_domain`/`vet45_shared_application`, codegen build_runner `vet45_generator`, Supabase Postgres RPC (schema `einvoice.*`), `packages/vet45_misa` (`IMeInvoiceClient`, `FakeMeInvoiceClient`), `dart test`.

**Spec:**
- `docs/themes/TH-08-e-invoice/harness/07-api-contracts.md` §S2a (dòng 204–245)
- `docs/themes/TH-08-e-invoice/Epic-02-issue-from-sales-order/US-01.md`
- Job catalog: `docs/themes/TH-08-e-invoice/harness/03-architecture-and-flows.md` §8 (`einvoice.preview_invoice` → `previewUnpublished`, idempotency `{tenantId}:preview:{salesOrderId}:{orderVersion}`, retry 2x) và §9 UF-02.

## Ràng buộc toàn cục

- **Không đụng FE** — task này chỉ BE. Không sửa `apps/erp/**` hay `modules/einvoice/presentation/**`.
- **Không tự commit** — user tự commit. Bước "Commit" trong mỗi task chỉ là gợi ý thông điệp; chỉ chạy khi user yêu cầu. Nếu không, dừng khi test xanh.
- **Chỉ draft SQL** — SQL mới nằm trong `supabase/migrations/_drafts/` với header block bắt buộc, DDL idempotent, param prefix `p_`, `returns table(...)`, lỗi `raise exception '<CODE>: <msg>'`, `security definer`, `set search_path`. `Kind: patch` = ≤8 `create or replace function`. **Không** tạo migration timestamp, **không** apply/promote — user tự test+apply qua SQL editor.
- **Codegen, không sửa tay** — sau khi thêm handler hoặc serializable internal command, regen bằng `melos run codegen`. Không bao giờ sửa tay `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/*.g.dart`.
- **Impact analysis trước khi sửa symbol dùng chung** — chạy `impact({target, direction:"upstream"})` trước khi sửa `einvoice_error_mapper`, `IMeInvoiceProviderPort`, `MeInvoiceProviderAdapter`, `einvoice_rpc_mapper`, `data_access_module`, hoặc barrel domain. Cảnh báo user nếu risk HIGH/CRITICAL trước khi tiếp tục.
- **Không chạy `dart format` cả package** — repo dùng style ngắn cũ; SDK mới sẽ reflow file không liên quan. Chỉ format file bạn viết, nếu cần.
- **Validator tách file** — không inline validation trong handler.
- **Preview không tạo issuance state** — DR-02/BR-10: `RequestInvoicePreviewCommand` và worker preview job không được tạo InvoiceIssuance, IssuanceAttempt, AttemptSnapshot hay ElectronicInvoice.
- **Error codes** — dùng hằng `EInvoiceBlockedCodes` (đã định nghĩa trong `modules/einvoice/application/lib/src/shared/einvoice_blocked_codes.dart`). Không hardcode chuỗi.
- **Mô hình dữ liệu = `01-domain-model.md` + §4.3–4.4** — mọi bảng/field draft SQL phải truy được về đó (ritual bước 8). Không tạo bảng ngoài danh mục; không persist Runtime value-object.

---

## Sửa mô hình dữ liệu (bắt buộc, áp dụng toàn plan)

Đối chiếu `harness/01-domain-model.md` (mục "Database tables", "Value objects & enums", Data rules) + canonical §4.3–4.4:

1. **KHÔNG có bảng `preview_requests`.** Danh mục persisted entity đóng ở 12 bảng (§4.3.2); preview là *"dữ liệu tạm thời, correlation-id, không tạo business identity"* (NFR-03). Lưu vết + handoff kết quả preview đi qua **shared technical record `provider_interaction_records`** (§4.3.5), mở rộng thêm cột cho preview (Task 13). Poll đọc lại từ record này.
2. **`buyer_invoice_completions` KHÔNG chứa `effective_buyer`.** `EffectiveBuyerInvoiceData` là **Runtime VO** (§4.3.3, VO table dòng 317) — merge lúc chạy, cấm persist. Bảng chỉ lưu `eligible_fields` (field bắt buộc thiếu được phép completion) + `resolved_values` (giá trị đã resolve) + `buyer_partner_id` + source lineage + `locked_at`, theo §4.4.3.
3. **`sales_order_version` = `varchar(100)`** ở SQL (canonical §4.4.3). Vỏ command freeze giữ `int expectedOrderVersion` (không đổi); **cast int↔text ở ranh giới RPC/mapper**. Port/gateway Dart mang version dạng `String` (opaque); handler nhận `int` từ command rồi `.toString()` khi gọi gateway.
4. **`IssuanceReadiness` là Read Model** (không persist) — chỉ tính, đúng như đã thiết kế. Preview/readiness **không** tạo attempt/invoice (DR-02, anti-pattern dòng 482).

Các Task bị ảnh hưởng: **8** (buyer completion — persist eligible/resolved, không persist effective), **9/11/14** (preview — dùng `provider_interaction_records`), **13** (schema/RPC).

---

## Sửa sau review (đã áp vào code — plan phản ánh trạng thái thật)

Sau khi implement + review đối chiếu canonical, đã sửa các điểm sau (code là nguồn chân lý; ghi ở đây để plan không lệch):

**Từ self-review (F1–F5):**
- **F1** — `CompleteBuyerInvoiceDataCommandHandler` luôn áp `completionSource` (kể cả khi LOCKED) — `resolved_values` đã khóa vẫn dùng để tạo effective; DR-10 chỉ cấm re-resolve Theme 03. Có test nhánh locked `scn_e02_u01_fr04_02`.
- **F2** — Supabase `loadCompletionContext` → `UnimplementedError` + TODO (cần RPC `load_buyer_completion_context` + Theme 05), không map sai từ `get_issuance_readiness`. Mapper `buyerCompletionContextFromRow` giữ cho RPC tương lai.
- **F3** — `store_preview_result` guard `request.jwt.claim.role = 'service_role'` (worker-only writeback).
- **F4** — `saveLockedCompletion` không nuốt lỗi version bằng `?? 0`; parse fail → `VALIDATION_ERROR`.
- **F5** — thêm `actorId` vào port `IBuyerInvoiceDataGateway` (cả 2 method), handler truyền `command.actorId`, gateway dùng cho `p_actor_id`.

**Từ đối chiếu canonical §4 (#2/#3/#6):**
- **#3 (FR-06/EC-04)** — `IssuanceReadinessInput` thêm `bool commercialDataMappable` (default `true`); evaluator: `false` → blocker `VALIDATION_ERROR` + `previewForbidden`. RPC `get_issuance_readiness` trả cột `commercial_data_mappable` (`true` + `TODO(Theme05)`); mapper đọc field. Test domain `FR-06/EC-04`.
- **#2 (no-completion state)** — không có completion row = buyer data đã settle từ snapshot → map về `locked` (không phải `open`) trong enum freeze `open/locked`. Sửa `coalesce(v_completion_status, 'locked')` ở RPC + default `'locked'` ở mapper. (Trường `buyerCompletionState` chỉ để hiển thị — không ảnh hưởng cổng readiness.)
- **#6 (preview version-bound, phần khả thi)** — `request_invoice_preview` **supersede** mọi preview record `pending/ready` cũ của đơn + set `expires_at = now()+15min`; `get_invoice_preview` chỉ trả record `status in ('pending','ready')` chưa hết hạn. Phần "so version hiện tại của đơn" phải **deferred tới Theme 05** (vỏ query `GetInvoicePreviewQuery` + DTO đã freeze, không mang version).

**Chưa xử lý (có chủ đích):** #4 (canonical payload rỗng) = hệ quả #3, giữ `TODO(Theme05)`; #5 (permission trong RPC) = không phải gap — permission enforce ở CQRS pipeline qua `@RequiresPermission`, RPC tenant-scoped như S1.

---

## Cấu trúc file

**Domain** (`modules/einvoice/domain/lib/src/issuance/`) — Dart thuần, không DB:
- `buyer_completion/buyer_type.dart` — `enum BuyerType { retail, individual, organization }`.
- `buyer_completion/effective_buyer_invoice_data.dart` — VO + predicate tính đủ điều kiện.
- `buyer_completion/buyer_invoice_data_resolver.dart` — merge source-precedence (base snapshot + nguồn completion tùy chọn).
- `services/issuance_readiness_input.dart` — VO input snapshot cho evaluator.
- `services/issuance_readiness_evaluator.dart` — evaluator thuần → blockers/warnings/level/canPreview.
- Tái dùng `ReadinessBlocker`/`ReadinessWarning` sẵn có trong `shared/services/configuration_readiness_evaluator.dart` (đã export qua barrel domain).

**Application** (`modules/einvoice/application/lib/src/`):
- `ports/i_issuance_readiness_read_gateway.dart` — `load(...) → IssuanceReadinessInput`.
- `ports/i_buyer_invoice_data_gateway.dart` — `loadCompletionContext(...)` + `saveLockedCompletion(...)`.
- `ports/i_invoice_preview_gateway.dart` — `persistRequestAndEnqueue(...) → String previewRequestId` + `readCached(...) → InvoicePreviewResultDto?` + `storeResult(...)`.
- `ports/i_me_invoice_provider_port.dart` — **sửa**: thêm `previewUnpublished(...)`.
- `issuance/queries/get_issuance_readiness/get_issuance_readiness_query_handler.dart` (+ map evaluation → `IssuanceReadinessDto`).
- `issuance/commands/complete_buyer_invoice_data/{_command_handler,_command_validator}.dart`.
- `issuance/commands/request_invoice_preview/{_command_handler,_command_validator}.dart`.
- `issuance/queries/get_invoice_preview/get_invoice_preview_query_handler.dart`.
- `issuance/commands/preview_invoice/preview_invoice_command.dart` — `ISerializableInternalCommand` bền (`einvoice.preview_invoice`).
- `issuance/commands/preview_invoice/preview_invoice_command_handler.dart` — worker handler.
- `testing/fakes/` — fake gateway cho 3 read port + fake `IMeInvoiceProviderPort` preview.

**Infrastructure** (`modules/einvoice/infrastructure/lib/src/`):
- `errors/einvoice_error_mapper.dart` — **sửa**: thêm code S2 vào vòng lặp.
- `adapters/misa/me_invoice_provider_adapter.dart` — **sửa**: implement `previewUnpublished`.
- `data_access/einvoice_rpc_mapper.dart` — **sửa**: thêm param/row mapper S2a.
- `data_access/supabase_issuance_readiness_read_gateway.dart`, `supabase_buyer_invoice_data_gateway.dart`, `supabase_invoice_preview_gateway.dart` — impl RPC mỏng (nối thật hoãn lại).
- `configuration/data_access/data_access_module.dart` — **sửa**: đăng ký 3 gateway mới.

**SQL** (`supabase/migrations/_drafts/`):
- `NNN_einvoice_s2a_schema.sql` — `einvoice.buyer_invoice_completions` (§4.4.3) + mở rộng cột preview cho `einvoice.provider_interaction_records` (KHÔNG tạo bảng `preview_requests`).
- `NNN_einvoice_s2a_rpc.sql` — `get_issuance_readiness`, `complete_buyer_invoice_data`, `request_invoice_preview`, `get_invoice_preview`, `store_preview_result` (`get_issuance_readiness` đọc `iam.tenant_legal_profiles` + bảng einvoice; join `sales.*` là TODO có ghi chú; preview handoff qua `provider_interaction_records`).

**Test** — thư mục `test/` colocated trong mỗi package (xem từng task).

---

## Task 1: Mở rộng RPC error mapper với code S2

**Files:**
- Sửa: `modules/einvoice/infrastructure/lib/src/errors/einvoice_error_mapper.dart`
- Test: `modules/einvoice/infrastructure/test/einvoice_error_mapper_test.dart` (tạo mới)

**Interfaces:**
- Consumes: `EInvoiceBlockedCodes` (có sẵn), `RpcException` (từ `vet45_shared_infrastructure`), `EInvoiceBlockedException` (từ application).
- Produces: `mapEinvoiceRpcError(RpcException) → EInvoiceBlockedException` cover mọi code TH-08.

- [ ] **Bước 1: Chạy impact analysis** (symbol dùng chung)

Chạy: `impact({target: "mapEinvoiceRpcError", direction: "upstream"})`. Báo blast radius cho user; nếu HIGH/CRITICAL, dừng chờ xác nhận.

- [ ] **Bước 2: Viết test đỏ**

```dart
// modules/einvoice/infrastructure/test/einvoice_error_mapper_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  test('maps S2 issuance codes instead of falling back to SYSTEM_ERROR', () {
    for (final code in [
      EInvoiceBlockedCodes.issuanceNotReady,
      EInvoiceBlockedCodes.buyerDataIncomplete,
      EInvoiceBlockedCodes.buyerTaxCodeRequired,
      EInvoiceBlockedCodes.orderNotCompleted,
      EInvoiceBlockedCodes.alreadyIssued,
      EInvoiceBlockedCodes.operationInProgress,
    ]) {
      final ex = mapEinvoiceRpcError(RpcException('$code: boom'));
      expect(ex.code, code, reason: 'code $code should be recognized');
    }
  });
}
```

- [ ] **Bước 3: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/infrastructure && dart test test/einvoice_error_mapper_test.dart`
Kỳ vọng: FAIL — code rơi vào `SYSTEM_ERROR`.

- [ ] **Bước 4: Thêm code vào vòng lặp**

Trong `einvoice_error_mapper.dart`, mở rộng danh sách `for (final code in [ ... ])` (sau `configNotReady`) với:

```dart
    EInvoiceBlockedCodes.issuanceNotReady,
    EInvoiceBlockedCodes.buyerDataIncomplete,
    EInvoiceBlockedCodes.buyerTaxCodeRequired,
    EInvoiceBlockedCodes.orderNotCompleted,
    EInvoiceBlockedCodes.alreadyIssued,
    EInvoiceBlockedCodes.operationInProgress,
    EInvoiceBlockedCodes.resultUndetermined,
    EInvoiceBlockedCodes.documentUnavailable,
    EInvoiceBlockedCodes.deliveryNotSupported,
```

Lưu ý: `BUYER_DATA_INCOMPLETE` không chứa code nào khác làm substring; thứ tự các code này không quan trọng, nhưng giữ `providerAuthFailed`/`providerNotConnected` trước các code generic như hiện tại.

- [ ] **Bước 5: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/infrastructure && dart test test/einvoice_error_mapper_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 6: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/infrastructure/lib/src/errors/einvoice_error_mapper.dart modules/einvoice/infrastructure/test/einvoice_error_mapper_test.dart
git commit -m "fix(einvoice): map S2 issuance error codes in rpc error mapper"
```

---

## Task 2: Domain — BuyerType + EffectiveBuyerInvoiceData VO

**Files:**
- Tạo: `modules/einvoice/domain/lib/src/issuance/buyer_completion/buyer_type.dart`
- Tạo: `modules/einvoice/domain/lib/src/issuance/buyer_completion/effective_buyer_invoice_data.dart`
- Test: `modules/einvoice/domain/test/issuance/effective_buyer_invoice_data_test.dart`

**Interfaces:**
- Produces:
  - `enum BuyerType { retail, individual, organization }`
  - `EffectiveBuyerInvoiceData({required BuyerType buyerType, required String name, String? email, String? taxCode, String? address})` với getter `bool get isComplete` và `bool get isMissingOnlyOrgTaxCode`.

- [ ] **Bước 1: Viết test đỏ**

```dart
// modules/einvoice/domain/test/issuance/effective_buyer_invoice_data_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('EffectiveBuyerInvoiceData', () {
    test('retail buyer with a name is complete', () {
      const d = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.retail, name: 'Người tiêu dùng');
      expect(d.isComplete, isTrue);
      expect(d.isMissingOnlyOrgTaxCode, isFalse);
    });

    test('organization missing tax code is incomplete but flagged as org-tax-only', () {
      const d = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization, name: 'Cty A', address: 'HN');
      expect(d.isComplete, isFalse);
      expect(d.isMissingOnlyOrgTaxCode, isTrue);
    });

    test('organization missing name is incomplete and not org-tax-only', () {
      const d = EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization, name: '', taxCode: '123');
      expect(d.isComplete, isFalse);
      expect(d.isMissingOnlyOrgTaxCode, isFalse);
    });
  });
}
```

- [ ] **Bước 2: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/effective_buyer_invoice_data_test.dart`
Kỳ vọng: FAIL — chưa định nghĩa type.

- [ ] **Bước 3: Implement**

```dart
// modules/einvoice/domain/lib/src/issuance/buyer_completion/buyer_type.dart
/// Buyer classification for invoice content (SRS §buyer data).
enum BuyerType { retail, individual, organization }
```

```dart
// modules/einvoice/domain/lib/src/issuance/buyer_completion/effective_buyer_invoice_data.dart
import 'package:equatable/equatable.dart';

import 'buyer_type.dart';

/// Immutable effective buyer data used for readiness and (later) attempt snapshot.
final class EffectiveBuyerInvoiceData extends Equatable {
  const EffectiveBuyerInvoiceData({
    required this.buyerType,
    required this.name,
    this.email,
    this.taxCode,
    this.address,
  });

  final BuyerType buyerType;
  final String name;
  final String? email;
  final String? taxCode;
  final String? address;

  bool get _hasName => name.trim().isNotEmpty;

  /// Retail uses "Bán cho người tiêu dùng" — only a name is required.
  /// Organization additionally requires a tax code.
  bool get isComplete {
    if (!_hasName) return false;
    if (buyerType == BuyerType.organization) {
      return (taxCode?.trim().isNotEmpty ?? false);
    }
    return true;
  }

  /// True when the only missing required field is an organization's tax code
  /// (BR-08 / UI-06: still previewable, not issuable).
  bool get isMissingOnlyOrgTaxCode =>
      buyerType == BuyerType.organization &&
      _hasName &&
      (taxCode?.trim().isEmpty ?? true);

  @override
  List<Object?> get props => [buyerType, name, email, taxCode, address];
}
```

- [ ] **Bước 4: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/effective_buyer_invoice_data_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/domain/lib/src/issuance/buyer_completion/ modules/einvoice/domain/test/issuance/effective_buyer_invoice_data_test.dart
git commit -m "feat(einvoice): add EffectiveBuyerInvoiceData value object (S2a)"
```

---

## Task 3: Domain — BuyerInvoiceDataResolver (source-precedence)

**Files:**
- Tạo: `modules/einvoice/domain/lib/src/issuance/buyer_completion/buyer_invoice_data_resolver.dart`
- Test: `modules/einvoice/domain/test/issuance/buyer_invoice_data_resolver_test.dart`

**Interfaces:**
- Consumes: `EffectiveBuyerInvoiceData`, `BuyerType` (Task 2).
- Produces:
  - `class BuyerInvoiceSourceFields({required BuyerType buyerType, String? name, String? email, String? taxCode, String? address})` — snapshot nguồn thô (base = snapshot Theme 05, override = hồ sơ partner Theme 03).
  - `abstract final class BuyerInvoiceDataResolver` với `static EffectiveBuyerInvoiceData resolve({required BuyerInvoiceSourceFields base, BuyerInvoiceSourceFields? completionSource})`.
- Rule (BR-05/BR-07/BR-13/BR-15): base thắng; nguồn completion chỉ điền field null/rỗng trong base; `buyerType` của base là authoritative; không ghi đè giá trị base đã có.

- [ ] **Bước 1: Viết test đỏ**

```dart
// modules/einvoice/domain/test/issuance/buyer_invoice_data_resolver_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('BuyerInvoiceDataResolver', () {
    test('uses base snapshot as-is when complete (no completion source read)', () {
      final base = BuyerInvoiceSourceFields(
          buyerType: BuyerType.organization, name: 'Cty A', taxCode: '0101', address: 'HN');
      final d = BuyerInvoiceDataResolver.resolve(base: base);
      expect(d.name, 'Cty A');
      expect(d.taxCode, '0101');
    });

    test('fills only missing fields from completion source, never overwrites base', () {
      final base = BuyerInvoiceSourceFields(
          buyerType: BuyerType.organization, name: 'Cty A', taxCode: null, address: 'HN');
      final src = BuyerInvoiceSourceFields(
          buyerType: BuyerType.organization, name: 'WRONG', taxCode: '0101', address: 'WRONG');
      final d = BuyerInvoiceDataResolver.resolve(base: base, completionSource: src);
      expect(d.name, 'Cty A'); // base preserved
      expect(d.address, 'HN'); // base preserved
      expect(d.taxCode, '0101'); // filled from source
    });

    test('base buyerType is authoritative', () {
      final base = BuyerInvoiceSourceFields(buyerType: BuyerType.retail, name: 'NTD');
      final src = BuyerInvoiceSourceFields(buyerType: BuyerType.organization, name: 'X', taxCode: '9');
      final d = BuyerInvoiceDataResolver.resolve(base: base, completionSource: src);
      expect(d.buyerType, BuyerType.retail);
    });
  });
}
```

- [ ] **Bước 2: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/buyer_invoice_data_resolver_test.dart`
Kỳ vọng: FAIL — chưa định nghĩa type.

- [ ] **Bước 3: Implement**

```dart
// modules/einvoice/domain/lib/src/issuance/buyer_completion/buyer_invoice_data_resolver.dart
import 'buyer_type.dart';
import 'effective_buyer_invoice_data.dart';

/// A raw buyer field snapshot from one source (base = Theme 05, override = Theme 03).
final class BuyerInvoiceSourceFields {
  const BuyerInvoiceSourceFields({
    required this.buyerType,
    this.name,
    this.email,
    this.taxCode,
    this.address,
  });

  final BuyerType buyerType;
  final String? name;
  final String? email;
  final String? taxCode;
  final String? address;
}

/// Source-precedence merge (BR-05/07/13/15): base wins; completionSource only
/// fills fields that are null/blank in base. Base buyerType is authoritative.
abstract final class BuyerInvoiceDataResolver {
  static EffectiveBuyerInvoiceData resolve({
    required BuyerInvoiceSourceFields base,
    BuyerInvoiceSourceFields? completionSource,
  }) {
    String? pick(String? baseValue, String? sourceValue) {
      final b = baseValue?.trim();
      if (b != null && b.isNotEmpty) return baseValue;
      final s = sourceValue?.trim();
      if (s != null && s.isNotEmpty) return sourceValue;
      return null;
    }

    return EffectiveBuyerInvoiceData(
      buyerType: base.buyerType,
      name: pick(base.name, completionSource?.name) ?? '',
      email: pick(base.email, completionSource?.email),
      taxCode: pick(base.taxCode, completionSource?.taxCode),
      address: pick(base.address, completionSource?.address),
    );
  }
}
```

- [ ] **Bước 4: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/buyer_invoice_data_resolver_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/domain/lib/src/issuance/buyer_completion/buyer_invoice_data_resolver.dart modules/einvoice/domain/test/issuance/buyer_invoice_data_resolver_test.dart
git commit -m "feat(einvoice): add buyer invoice data source-precedence resolver (S2a)"
```

---

## Task 4: Domain — IssuanceReadinessInput + IssuanceReadinessEvaluator

**Files:**
- Tạo: `modules/einvoice/domain/lib/src/issuance/services/issuance_readiness_input.dart`
- Tạo: `modules/einvoice/domain/lib/src/issuance/services/issuance_readiness_evaluator.dart`
- Test: `modules/einvoice/domain/test/issuance/issuance_readiness_evaluator_test.dart`

**Interfaces:**
- Consumes: `EffectiveBuyerInvoiceData` (Task 2); tái dùng `ReadinessBlocker`, `ReadinessWarning` từ `configuration_readiness_evaluator.dart` (đã export qua barrel); enum `IssuanceReadinessLevel`, `BuyerCompletionStatus` (có sẵn).
- Produces:
  - `IssuanceReadinessInput({required bool orderCompleted, required bool hasElectronicInvoice, required bool hasActiveOperation, required bool configReady, required bool providerConnected, required bool providerSupportsPreview, required EffectiveBuyerInvoiceData buyer, required BuyerCompletionStatus buyerCompletionState, List<ReadinessWarning> configWarnings = const []})`.
  - `IssuanceReadinessEvaluation({required IssuanceReadinessLevel level, required List<ReadinessBlocker> blockers, required List<ReadinessWarning> warnings, required bool canPreview, required BuyerCompletionStatus buyerCompletionState})`.
  - `abstract final class IssuanceReadinessEvaluator { static IssuanceReadinessEvaluation evaluate(IssuanceReadinessInput input); }`.
- Blocker code là chuỗi giá trị của `EInvoiceBlockedCodes`, nhưng domain **không** được phụ thuộc tầng application — inline literal `'ORDER_NOT_COMPLETED'` v.v. (chúng khớp `EInvoiceBlockedCodes`, được test kiểm chứng ở Task 7).

- [ ] **Bước 1: Viết test đỏ**

```dart
// modules/einvoice/domain/test/issuance/issuance_readiness_evaluator_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

IssuanceReadinessInput _input({
  bool orderCompleted = true,
  bool hasElectronicInvoice = false,
  bool hasActiveOperation = false,
  bool configReady = true,
  bool providerConnected = true,
  bool providerSupportsPreview = true,
  EffectiveBuyerInvoiceData? buyer,
  BuyerCompletionStatus buyerCompletionState = BuyerCompletionStatus.locked,
}) =>
    IssuanceReadinessInput(
      orderCompleted: orderCompleted,
      hasElectronicInvoice: hasElectronicInvoice,
      hasActiveOperation: hasActiveOperation,
      configReady: configReady,
      providerConnected: providerConnected,
      providerSupportsPreview: providerSupportsPreview,
      buyer: buyer ??
          const EffectiveBuyerInvoiceData(
              buyerType: BuyerType.retail, name: 'NTD'),
      buyerCompletionState: buyerCompletionState,
    );

List<String> _codes(List<ReadinessBlocker> b) => b.map((x) => x.code).toList();

void main() {
  group('IssuanceReadinessEvaluator', () {
    test('all good → ready + canPreview', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input());
      expect(r.level, IssuanceReadinessLevel.ready);
      expect(r.blockers, isEmpty);
      expect(r.canPreview, isTrue);
    });

    test('order not completed → blocker ORDER_NOT_COMPLETED, cannot preview', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(orderCompleted: false));
      expect(_codes(r.blockers), contains('ORDER_NOT_COMPLETED'));
      expect(r.level, IssuanceReadinessLevel.notReady);
      expect(r.canPreview, isFalse);
    });

    test('already issued → ALREADY_ISSUED', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(hasElectronicInvoice: true));
      expect(_codes(r.blockers), contains('ALREADY_ISSUED'));
    });

    test('active operation → OPERATION_IN_PROGRESS', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(hasActiveOperation: true));
      expect(_codes(r.blockers), contains('OPERATION_IN_PROGRESS'));
    });

    test('config not ready → CONFIG_NOT_READY', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(configReady: false));
      expect(_codes(r.blockers), contains('CONFIG_NOT_READY'));
    });

    test('provider not connected → PROVIDER_NOT_CONNECTED', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(providerConnected: false));
      expect(_codes(r.blockers), contains('PROVIDER_NOT_CONNECTED'));
    });

    test('org missing tax code → BUYER_TAX_CODE_REQUIRED blocks issue but preview allowed', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(
        buyer: const EffectiveBuyerInvoiceData(
            buyerType: BuyerType.organization, name: 'Cty A', address: 'HN'),
      ));
      expect(_codes(r.blockers), contains('BUYER_TAX_CODE_REQUIRED'));
      expect(r.level, IssuanceReadinessLevel.notReady);
      expect(r.canPreview, isTrue); // BR-08 / UI-06
    });

    test('buyer data incomplete (missing name) → BUYER_DATA_INCOMPLETE, no preview', () {
      final r = IssuanceReadinessEvaluator.evaluate(_input(
        buyer: const EffectiveBuyerInvoiceData(
            buyerType: BuyerType.individual, name: ''),
      ));
      expect(_codes(r.blockers), contains('BUYER_DATA_INCOMPLETE'));
      expect(r.canPreview, isFalse);
    });

    test('config warnings but otherwise ready → readyWithWarnings', () {
      final r = IssuanceReadinessEvaluator.evaluate(IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: const EffectiveBuyerInvoiceData(buyerType: BuyerType.retail, name: 'NTD'),
        buyerCompletionState: BuyerCompletionStatus.locked,
        configWarnings: const [
          ReadinessWarning(code: 'template_deprecated', message: 'x'),
        ],
      ));
      expect(r.level, IssuanceReadinessLevel.readyWithWarnings);
      expect(r.warnings, isNotEmpty);
    });
  });
}
```

- [ ] **Bước 2: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/issuance_readiness_evaluator_test.dart`
Kỳ vọng: FAIL — chưa định nghĩa type.

- [ ] **Bước 3: Implement input VO**

```dart
// modules/einvoice/domain/lib/src/issuance/services/issuance_readiness_input.dart
import '../../shared/services/configuration_readiness_evaluator.dart' show ReadinessWarning;
import '../buyer_completion/effective_buyer_invoice_data.dart';
import '../enums/buyer_completion_status.dart';

/// Authoritative snapshot fed to IssuanceReadinessEvaluator (gathered by the read gateway).
final class IssuanceReadinessInput {
  const IssuanceReadinessInput({
    required this.orderCompleted,
    required this.hasElectronicInvoice,
    required this.hasActiveOperation,
    required this.configReady,
    required this.providerConnected,
    required this.providerSupportsPreview,
    required this.buyer,
    required this.buyerCompletionState,
    this.configWarnings = const [],
  });

  final bool orderCompleted;
  final bool hasElectronicInvoice;
  final bool hasActiveOperation;
  final bool configReady;
  final bool providerConnected;
  final bool providerSupportsPreview;
  final EffectiveBuyerInvoiceData buyer;
  final BuyerCompletionStatus buyerCompletionState;
  final List<ReadinessWarning> configWarnings;
}
```

- [ ] **Bước 4: Implement evaluator**

```dart
// modules/einvoice/domain/lib/src/issuance/services/issuance_readiness_evaluator.dart
import '../../shared/services/configuration_readiness_evaluator.dart'
    show ReadinessBlocker, ReadinessWarning;
import '../enums/buyer_completion_status.dart';
import '../enums/issuance_readiness_level.dart';
import 'issuance_readiness_input.dart';

/// Result of per-order issuance readiness evaluation (read model).
final class IssuanceReadinessEvaluation {
  const IssuanceReadinessEvaluation({
    required this.level,
    required this.blockers,
    required this.warnings,
    required this.canPreview,
    required this.buyerCompletionState,
  });

  final IssuanceReadinessLevel level;
  final List<ReadinessBlocker> blockers;
  final List<ReadinessWarning> warnings;
  final bool canPreview;
  final BuyerCompletionStatus buyerCompletionState;
}

/// Pure evaluator for EP-02/US-01 issuance readiness.
///
/// Codes intentionally match `EInvoiceBlockedCodes` (application layer) but are
/// inlined here to keep the domain free of application imports.
abstract final class IssuanceReadinessEvaluator {
  static IssuanceReadinessEvaluation evaluate(IssuanceReadinessInput input) {
    final blockers = <ReadinessBlocker>[];
    final warnings = <ReadinessWarning>[...input.configWarnings];

    // Hard blockers that also forbid preview.
    var previewForbidden = false;

    if (!input.orderCompleted) {
      blockers.add(const ReadinessBlocker(
          code: 'ORDER_NOT_COMPLETED', message: 'Đơn hàng chưa Hoàn tất'));
      previewForbidden = true;
    }
    if (input.hasElectronicInvoice) {
      blockers.add(const ReadinessBlocker(
          code: 'ALREADY_ISSUED', message: 'Đơn hàng đã có hóa đơn điện tử'));
      previewForbidden = true;
    }
    if (input.hasActiveOperation) {
      blockers.add(const ReadinessBlocker(
          code: 'OPERATION_IN_PROGRESS',
          message: 'Đang có thao tác phát hành khác'));
      previewForbidden = true;
    }
    if (!input.configReady) {
      blockers.add(const ReadinessBlocker(
          code: 'CONFIG_NOT_READY', message: 'Cấu hình phát hành chưa sẵn sàng'));
      previewForbidden = true;
    }
    if (!input.providerConnected) {
      blockers.add(const ReadinessBlocker(
          code: 'PROVIDER_NOT_CONNECTED',
          message: 'Chưa kết nối nhà cung cấp'));
      previewForbidden = true;
    }

    // Buyer data.
    if (input.buyer.isMissingOnlyOrgTaxCode) {
      // Blocks issuance but preview stays allowed when provider supports it (BR-08).
      blockers.add(const ReadinessBlocker(
          code: 'BUYER_TAX_CODE_REQUIRED',
          message: 'Khách tổ chức thiếu mã số thuế'));
    } else if (!input.buyer.isComplete) {
      blockers.add(const ReadinessBlocker(
          code: 'BUYER_DATA_INCOMPLETE',
          message: 'Thông tin người mua chưa đủ'));
      previewForbidden = true;
    }

    final canPreview = !previewForbidden && input.providerSupportsPreview;

    final IssuanceReadinessLevel level;
    if (blockers.isNotEmpty) {
      level = IssuanceReadinessLevel.notReady;
    } else if (warnings.isNotEmpty) {
      level = IssuanceReadinessLevel.readyWithWarnings;
    } else {
      level = IssuanceReadinessLevel.ready;
    }

    return IssuanceReadinessEvaluation(
      level: level,
      blockers: blockers,
      warnings: warnings,
      canPreview: canPreview,
      buyerCompletionState: input.buyerCompletionState,
    );
  }
}
```

- [ ] **Bước 5: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/domain && dart test test/issuance/issuance_readiness_evaluator_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 6: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/domain/lib/src/issuance/services/ modules/einvoice/domain/test/issuance/issuance_readiness_evaluator_test.dart
git commit -m "feat(einvoice): add IssuanceReadinessEvaluator (S2a US-01)"
```

---

## Task 5: Domain — export barrel

**Files:**
- Sửa: `modules/einvoice/domain/lib/domain.dart`

**Interfaces:**
- Produces: các type Task 2–4 import được qua `package:vet45_einvoice_domain/domain.dart`.

- [ ] **Bước 1: Thêm export**

Thêm sau các dòng export `issuance/enums/*` hiện có:

```dart
export 'src/issuance/buyer_completion/buyer_type.dart';
export 'src/issuance/buyer_completion/effective_buyer_invoice_data.dart';
export 'src/issuance/buyer_completion/buyer_invoice_data_resolver.dart';
export 'src/issuance/services/issuance_readiness_input.dart';
export 'src/issuance/services/issuance_readiness_evaluator.dart';
```

- [ ] **Bước 2: Kiểm tra package domain analyze + test xanh**

Chạy: `cd modules/einvoice/domain && dart analyze && dart test`
Kỳ vọng: 0 analyzer issue; mọi test issuance PASS.

- [ ] **Bước 3: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/domain/lib/domain.dart
git commit -m "chore(einvoice): export S2a issuance domain from barrel"
```

---

## Task 6: Application port + handler — GetIssuanceReadiness

**Files:**
- Tạo: `modules/einvoice/application/lib/src/ports/i_issuance_readiness_read_gateway.dart`
- Tạo: `modules/einvoice/application/lib/src/issuance/queries/get_issuance_readiness/get_issuance_readiness_query_handler.dart`
- Sửa: `modules/einvoice/application/lib/application.dart` (export port mới nếu barrel liệt kê port tường minh — kiểm tra pattern trước)

**Interfaces:**
- Consumes: `GetIssuanceReadinessQuery` (vỏ có sẵn); các type `IssuanceReadinessInput`/`IssuanceReadinessEvaluator`/`IssuanceReadinessDto`.
- Produces:
  - `abstract interface class IIssuanceReadinessReadGateway { Future<IssuanceReadinessInput> load({required String tenantId, required String actorId, required String salesOrderId}); }`
  - `GetIssuanceReadinessQueryHandler` map evaluation → `IssuanceReadinessDto` (`level`, `blockers` thành `ReadinessBlockerDto`, `warnings` thành `ReadinessWarningDto`, `buyerCompletionState`).

- [ ] **Bước 1: Viết port**

```dart
// modules/einvoice/application/lib/src/ports/i_issuance_readiness_read_gateway.dart
import 'package:vet45_einvoice_domain/domain.dart';

/// Read port: gathers the authoritative snapshot for per-order issuance readiness.
///
/// NOTE (S2a fake seam): the real implementation reads Theme 05 SalesOrder /
/// BuyerInvoiceSnapshot which do not exist in the DB yet — tests use a fake.
abstract interface class IIssuanceReadinessReadGateway {
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  });
}
```

- [ ] **Bước 2: Viết handler**

```dart
// modules/einvoice/application/lib/src/issuance/queries/get_issuance_readiness/get_issuance_readiness_query_handler.dart
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../configuration/shared/readiness_blocker_dto.dart';
import '../../../configuration/shared/readiness_warning_dto.dart';
import '../../../ports/i_issuance_readiness_read_gateway.dart';
import 'get_issuance_readiness_query.dart';
import 'issuance_readiness_dto.dart';

@QueryHandlerFor(GetIssuanceReadinessQuery)
final class GetIssuanceReadinessQueryHandler
    implements IQueryHandler<GetIssuanceReadinessQuery, IssuanceReadinessDto> {
  GetIssuanceReadinessQueryHandler({
    required IIssuanceReadinessReadGateway readinessGateway,
  }) : _readinessGateway = readinessGateway;

  final IIssuanceReadinessReadGateway _readinessGateway;

  @override
  Future<IssuanceReadinessDto> handle(GetIssuanceReadinessQuery query) async {
    final input = await _readinessGateway.load(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
    final evaluation = IssuanceReadinessEvaluator.evaluate(input);
    return IssuanceReadinessDto(
      level: evaluation.level,
      blockers: [
        for (final b in evaluation.blockers)
          ReadinessBlockerDto(code: b.code, message: b.message),
      ],
      warnings: [
        for (final w in evaluation.warnings)
          ReadinessWarningDto(code: w.code, message: w.message),
      ],
      buyerCompletionState: evaluation.buyerCompletionState,
    );
  }
}
```

- [ ] **Bước 3: Kiểm tra package application analyze**

Chạy: `cd modules/einvoice/application && dart analyze`
Kỳ vọng: 0 issue (handler chưa đăng ký — sẽ làm ở codegen Task 12; analyze độc lập với việc đó).

- [ ] **Bước 4: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/ports/i_issuance_readiness_read_gateway.dart modules/einvoice/application/lib/src/issuance/queries/get_issuance_readiness/get_issuance_readiness_query_handler.dart
git commit -m "feat(einvoice): add issuance readiness read port + query handler (S2a)"
```

---

## Task 7: Fake readiness gateway + handler test

**Files:**
- Tạo: `modules/einvoice/application/lib/src/testing/fakes/fake_issuance_readiness_read_gateway.dart`
- Test: `modules/einvoice/application/test/issuance/scn_e02_u01_get_issuance_readiness_handler_test.dart`

**Interfaces:**
- Consumes: `IIssuanceReadinessReadGateway` (Task 6).
- Produces: `FakeIssuanceReadinessReadGateway({required IssuanceReadinessInput result})` trả `IssuanceReadinessInput` theo kịch bản.

- [ ] **Bước 1: Viết test đỏ**

```dart
// modules/einvoice/application/test/issuance/scn_e02_u01_get_issuance_readiness_handler_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  IssuanceReadinessInput ready() => const IssuanceReadinessInput(
        orderCompleted: true,
        hasElectronicInvoice: false,
        hasActiveOperation: false,
        configReady: true,
        providerConnected: true,
        providerSupportsPreview: true,
        buyer: EffectiveBuyerInvoiceData(buyerType: BuyerType.retail, name: 'NTD'),
        buyerCompletionState: BuyerCompletionStatus.locked,
      );

  test('scn_e02_u01_fr01_01: ready order maps to READY dto with no blockers', () async {
    final handler = GetIssuanceReadinessQueryHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(result: ready()),
    );
    final dto = await handler.handle(GetIssuanceReadinessQuery(
        tenantId: 't1', actorId: 'a1', salesOrderId: 'so1'));
    expect(dto.level, IssuanceReadinessLevel.ready);
    expect(dto.blockers, isEmpty);
    expect(dto.buyerCompletionState, BuyerCompletionStatus.locked);
  });

  test('scn_e02_u01_fr10_01: org missing tax code surfaces BUYER_TAX_CODE_REQUIRED blocker', () async {
    final input = IssuanceReadinessInput(
      orderCompleted: true,
      hasElectronicInvoice: false,
      hasActiveOperation: false,
      configReady: true,
      providerConnected: true,
      providerSupportsPreview: true,
      buyer: const EffectiveBuyerInvoiceData(
          buyerType: BuyerType.organization, name: 'Cty A', address: 'HN'),
      buyerCompletionState: BuyerCompletionStatus.locked,
    );
    final handler = GetIssuanceReadinessQueryHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(result: input));
    final dto = await handler.handle(GetIssuanceReadinessQuery(
        tenantId: 't1', actorId: 'a1', salesOrderId: 'so1'));
    expect(dto.level, IssuanceReadinessLevel.notReady);
    expect(dto.blockers.map((b) => b.code), contains(EInvoiceBlockedCodes.buyerTaxCodeRequired));
  });
}
```

Lưu ý: test thứ hai đồng thời chứng minh literal `'BUYER_TAX_CODE_REQUIRED'` inline trong domain bằng `EInvoiceBlockedCodes.buyerTaxCodeRequired` (guard type-consistency từ Task 4).

- [ ] **Bước 2: Viết fake**

```dart
// modules/einvoice/application/lib/src/testing/fakes/fake_issuance_readiness_read_gateway.dart
import 'package:vet45_einvoice_domain/domain.dart';

import '../../ports/i_issuance_readiness_read_gateway.dart';

final class FakeIssuanceReadinessReadGateway
    implements IIssuanceReadinessReadGateway {
  FakeIssuanceReadinessReadGateway({required this.result});

  final IssuanceReadinessInput result;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async =>
      result;
}
```

- [ ] **Bước 3: Export fake** ở testing surface

Kiểm tra `modules/einvoice/application/lib/src/testing/` được export thế nào (qua `application.dart` hoặc barrel `testing.dart`) và thêm fake mới theo đúng pattern của `fake_einvoice_fixtures.dart`.

- [ ] **Bước 4: Chạy test**

Chạy: `cd modules/einvoice/application && dart test test/issuance/scn_e02_u01_get_issuance_readiness_handler_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 5: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/testing/fakes/fake_issuance_readiness_read_gateway.dart modules/einvoice/application/test/issuance/scn_e02_u01_get_issuance_readiness_handler_test.dart modules/einvoice/application/lib/application.dart
git commit -m "test(einvoice): fake readiness gateway + readiness handler scenarios (S2a)"
```

---

## Task 8: CompleteBuyerInvoiceData — port, handler, validator, test

**Files:**
- Tạo: `modules/einvoice/application/lib/src/ports/i_buyer_invoice_data_gateway.dart`
- Tạo: `modules/einvoice/application/lib/src/issuance/commands/complete_buyer_invoice_data/complete_buyer_invoice_data_command_validator.dart`
- Tạo: `modules/einvoice/application/lib/src/issuance/commands/complete_buyer_invoice_data/complete_buyer_invoice_data_command_handler.dart`
- Tạo: `modules/einvoice/application/lib/src/testing/fakes/fake_buyer_invoice_data_gateway.dart`
- Test: `modules/einvoice/application/test/issuance/scn_e02_u01_complete_buyer_handler_test.dart`

**Interfaces:**
- Consumes: `CompleteBuyerInvoiceDataCommand`/`BuyerCompletionResultDto`/`EffectiveBuyerPreviewDto` (vỏ có sẵn); `BuyerInvoiceDataResolver`/`BuyerInvoiceSourceFields`/`EffectiveBuyerInvoiceData` (domain).
- Produces:
  - `class BuyerCompletionContext({required BuyerInvoiceSourceFields base, BuyerInvoiceSourceFields? completionSource, required BuyerCompletionStatus status, required String salesOrderVersion, required String buyerPartnerId, List<String> eligibleFields})` — maps buyer_invoice_completions row (§4.4.3); `completionSource` là projection của `resolved_values`.
  - `abstract interface class IBuyerInvoiceDataGateway { Future<BuyerCompletionContext> loadCompletionContext({required String tenantId, required String salesOrderId, required int expectedOrderVersion}); Future<void> saveLockedCompletion({required String tenantId, required String salesOrderId, required String salesOrderVersion, required List<String> eligibleFields, required Map<String, String?> resolvedValues}); }` — persist eligible/resolved, **không** persist effective.
  - Ném `EInvoiceBlockedException(EInvoiceBlockedCodes.buyerTaxCodeRequired)` / `...buyerDataIncomplete` khi chưa đủ điều kiện.

- [ ] **Bước 1: Viết port**

```dart
// modules/einvoice/application/lib/src/ports/i_buyer_invoice_data_gateway.dart
import 'package:vet45_einvoice_domain/domain.dart';

/// Snapshot needed to resolve + (maybe) lock buyer invoice completion.
/// Maps the buyer_invoice_completions row (§4.4.3): completionSource is a
/// projection of resolved_values into the same shape as base. EffectiveBuyerInvoiceData
/// is Runtime and is NEVER stored — the handler recomputes it.
final class BuyerCompletionContext {
  const BuyerCompletionContext({
    required this.base,
    this.completionSource,
    required this.status,
    required this.salesOrderVersion, // varchar(100) in SQL → String here (§4.4.3)
    required this.buyerPartnerId,
    this.eligibleFields = const [],
  });

  final BuyerInvoiceSourceFields base;
  final BuyerInvoiceSourceFields? completionSource; // from resolved_values
  final BuyerCompletionStatus status;
  final String salesOrderVersion;
  final String buyerPartnerId;
  final List<String> eligibleFields; // e.g. ['taxCode','email','address']
}

/// Read/persist port for buyer invoice completion (S2a fake seam).
abstract interface class IBuyerInvoiceDataGateway {
  Future<BuyerCompletionContext> loadCompletionContext({
    required String tenantId,
    required String salesOrderId,
    required int expectedOrderVersion, // command boundary stays int
  });

  /// Persist the completion fields per §4.4.3 — NOT the runtime effective blob.
  Future<void> saveLockedCompletion({
    required String tenantId,
    required String salesOrderId,
    required String salesOrderVersion,
    required List<String> eligibleFields,
    required Map<String, String?> resolvedValues,
  });
}
```

- [ ] **Bước 2: Viết validator**

```dart
// .../complete_buyer_invoice_data/complete_buyer_invoice_data_command_validator.dart
import 'package:vet45_shared_application/application.dart';

import 'complete_buyer_invoice_data_command.dart';

final class CompleteBuyerInvoiceDataCommandValidator
    implements ICommandValidator<CompleteBuyerInvoiceDataCommand> {
  @override
  Future<void> validate(CompleteBuyerInvoiceDataCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
  }
}
```

- [ ] **Bước 3: Viết test handler (đỏ)**

```dart
// modules/einvoice/application/test/issuance/scn_e02_u01_complete_buyer_handler_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  test('scn_e02_u01_fr04_01: resolving completes buyer data and locks completion', () async {
    final gateway = FakeBuyerInvoiceDataGateway(
      context: const BuyerCompletionContext(
        base: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization, name: 'Cty A', address: 'HN'),
        completionSource: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization, taxCode: '0101'),
        status: BuyerCompletionStatus.open,
        salesOrderVersion: '3',
        buyerPartnerId: 'bp1',
        eligibleFields: ['taxCode'],
      ),
    );
    final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
    final result = await handler.handle(CompleteBuyerInvoiceDataCommand(
        tenantId: 't1', actorId: 'a1', salesOrderId: 'so1', expectedOrderVersion: 3));
    expect(result.locked, isTrue);
    expect(result.effectiveBuyer.taxCode, '0101');
    expect(gateway.savedResolvedValues?['taxCode'], '0101'); // persisted resolved_values, not effective blob
  });

  test('scn_e02_u01_fr08_01: org still missing tax code throws BUYER_TAX_CODE_REQUIRED and does not lock', () async {
    final gateway = FakeBuyerInvoiceDataGateway(
      context: const BuyerCompletionContext(
        base: BuyerInvoiceSourceFields(
            buyerType: BuyerType.organization, name: 'Cty A', address: 'HN'),
        status: BuyerCompletionStatus.open,
        salesOrderVersion: '1',
        buyerPartnerId: 'bp1',
        eligibleFields: ['taxCode'],
      ),
    );
    final handler = CompleteBuyerInvoiceDataCommandHandler(gateway: gateway);
    expect(
      () => handler.handle(CompleteBuyerInvoiceDataCommand(
          tenantId: 't1', actorId: 'a1', salesOrderId: 'so1', expectedOrderVersion: 1)),
      throwsA(isA<EInvoiceBlockedException>()
          .having((e) => e.code, 'code', EInvoiceBlockedCodes.buyerTaxCodeRequired)),
    );
    expect(gateway.savedResolvedValues, isNull);
  });
}
```

- [ ] **Bước 4: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/application && dart test test/issuance/scn_e02_u01_complete_buyer_handler_test.dart`
Kỳ vọng: FAIL — chưa có handler/fake.

- [ ] **Bước 5: Viết handler**

```dart
// .../complete_buyer_invoice_data/complete_buyer_invoice_data_command_handler.dart
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_buyer_invoice_data_gateway.dart';
import '../../../shared/einvoice_blocked_codes.dart';
import '../../../shared/einvoice_blocked_exception.dart';
import '../../shared/effective_buyer_preview_dto.dart';
import 'complete_buyer_invoice_data_command.dart';
import 'complete_buyer_invoice_data_result.dart';

@CommandHandlerFor(CompleteBuyerInvoiceDataCommand)
final class CompleteBuyerInvoiceDataCommandHandler
    implements ICommandHandler<CompleteBuyerInvoiceDataCommand, BuyerCompletionResultDto> {
  CompleteBuyerInvoiceDataCommandHandler({
    required IBuyerInvoiceDataGateway gateway,
  }) : _gateway = gateway;

  final IBuyerInvoiceDataGateway _gateway;

  @override
  Future<BuyerCompletionResultDto> handle(
    CompleteBuyerInvoiceDataCommand command,
  ) async {
    final ctx = await _gateway.loadCompletionContext(
      tenantId: command.tenantId,
      salesOrderId: command.salesOrderId,
      expectedOrderVersion: command.expectedOrderVersion,
    );

    final effective = BuyerInvoiceDataResolver.resolve(
      base: ctx.base,
      completionSource:
          ctx.status == BuyerCompletionStatus.open ? ctx.completionSource : null,
    );

    var locked = ctx.status == BuyerCompletionStatus.locked;
    if (!effective.isComplete) {
      // Org missing only tax code is the specific blocker (BR-14); otherwise generic.
      final code = effective.isMissingOnlyOrgTaxCode
          ? EInvoiceBlockedCodes.buyerTaxCodeRequired
          : EInvoiceBlockedCodes.buyerDataIncomplete;
      throw EInvoiceBlockedException(code, message: 'Buyer data incomplete');
    }

    if (!locked) {
      // Persist ONLY the completion fields (§4.4.3) — the resolved value for each
      // eligible field. EffectiveBuyerInvoiceData is Runtime and never stored.
      String? fieldValue(String f) => switch (f) {
            'name' => effective.name,
            'email' => effective.email,
            'taxCode' => effective.taxCode,
            'address' => effective.address,
            _ => null,
          };
      final resolvedValues = <String, String?>{
        for (final f in ctx.eligibleFields) f: fieldValue(f),
      };
      await _gateway.saveLockedCompletion(
        tenantId: command.tenantId,
        salesOrderId: command.salesOrderId,
        salesOrderVersion: ctx.salesOrderVersion,
        eligibleFields: ctx.eligibleFields,
        resolvedValues: resolvedValues,
      );
      locked = true;
    }

    return BuyerCompletionResultDto(
      locked: locked,
      effectiveBuyer: EffectiveBuyerPreviewDto(
        name: effective.name,
        email: effective.email,
        taxCode: effective.taxCode,
        address: effective.address,
      ),
    );
  }
}
```

Lưu ý: xác nhận constructor `EInvoiceBlockedException` bằng cách đọc `modules/einvoice/application/lib/src/shared/einvoice_blocked_exception.dart` trước khi viết — error mapper dùng `EInvoiceBlockedException(code, message: message)`, nên chữ ký này khớp.

- [ ] **Bước 6: Viết fake gateway**

```dart
// modules/einvoice/application/lib/src/testing/fakes/fake_buyer_invoice_data_gateway.dart
import 'package:vet45_einvoice_domain/domain.dart';

import '../../ports/i_buyer_invoice_data_gateway.dart';

final class FakeBuyerInvoiceDataGateway implements IBuyerInvoiceDataGateway {
  FakeBuyerInvoiceDataGateway({required this.context});

  final BuyerCompletionContext context;
  Map<String, String?>? savedResolvedValues;
  List<String>? savedEligibleFields;

  @override
  Future<BuyerCompletionContext> loadCompletionContext({
    required String tenantId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async =>
      context;

  @override
  Future<void> saveLockedCompletion({
    required String tenantId,
    required String salesOrderId,
    required String salesOrderVersion,
    required List<String> eligibleFields,
    required Map<String, String?> resolvedValues,
  }) async {
    savedEligibleFields = eligibleFields;
    savedResolvedValues = resolvedValues;
  }
}
```

- [ ] **Bước 7: Export fake** (cùng barrel như Task 7 Bước 3).

- [ ] **Bước 8: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/application && dart test test/issuance/scn_e02_u01_complete_buyer_handler_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 9: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/ports/i_buyer_invoice_data_gateway.dart modules/einvoice/application/lib/src/issuance/commands/complete_buyer_invoice_data/ modules/einvoice/application/lib/src/testing/fakes/fake_buyer_invoice_data_gateway.dart modules/einvoice/application/test/issuance/scn_e02_u01_complete_buyer_handler_test.dart
git commit -m "feat(einvoice): complete buyer invoice data handler + validator (S2a)"
```

---

## Task 9: RequestInvoicePreview + GetInvoicePreview — port, handlers, validator, test

**Files:**
- Tạo: `modules/einvoice/application/lib/src/ports/i_invoice_preview_gateway.dart`
- Tạo: `.../issuance/commands/request_invoice_preview/request_invoice_preview_command_validator.dart`
- Tạo: `.../issuance/commands/request_invoice_preview/request_invoice_preview_command_handler.dart`
- Tạo: `.../issuance/queries/get_invoice_preview/get_invoice_preview_query_handler.dart`
- Tạo: `modules/einvoice/application/lib/src/testing/fakes/fake_invoice_preview_gateway.dart`
- Test: `modules/einvoice/application/test/issuance/scn_e02_u01_request_preview_handler_test.dart`

**Interfaces:**
- Consumes: `RequestInvoicePreviewCommand`/`InvoicePreviewResultDto`/`GetInvoicePreviewQuery` (vỏ có sẵn); `IIssuanceReadinessReadGateway` (Task 6, để re-check readiness trước khi enqueue preview).
- Produces:
  - `abstract interface class IInvoicePreviewGateway { Future<String> persistRequestAndEnqueue({required String tenantId, required String actorId, required String salesOrderId, required int expectedOrderVersion}); Future<InvoicePreviewResultDto?> readCached({required String tenantId, required String salesOrderId}); Future<void> storeResult({required String tenantId, required String previewRequestId, String? viewerRef, Map<String, Object?>? previewPayload}); }`
- Preview vẫn cho phép khi `BUYER_TAX_CODE_REQUIRED` là blocker duy nhất (evaluation.canPreview == true); blocker khác → ném `EInvoiceBlockedException(EInvoiceBlockedCodes.issuanceNotReady)`.

- [ ] **Bước 1: Viết port**

```dart
// modules/einvoice/application/lib/src/ports/i_invoice_preview_gateway.dart
import '../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';

/// Persists a preview request (which enqueues the einvoice.preview_invoice job)
/// and reads back the cached preview result. Creates NO issuance state (DR-02).
abstract interface class IInvoicePreviewGateway {
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  });

  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String salesOrderId,
  });

  Future<void> storeResult({
    required String tenantId,
    required String previewRequestId,
    String? viewerRef,
    Map<String, Object?>? previewPayload,
  });
}
```

- [ ] **Bước 2: Viết validator**

```dart
// .../request_invoice_preview/request_invoice_preview_command_validator.dart
import 'package:vet45_shared_application/application.dart';

import 'request_invoice_preview_command.dart';

final class RequestInvoicePreviewCommandValidator
    implements ICommandValidator<RequestInvoicePreviewCommand> {
  @override
  Future<void> validate(RequestInvoicePreviewCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
  }
}
```

- [ ] **Bước 3: Viết test đỏ**

```dart
// modules/einvoice/application/test/issuance/scn_e02_u01_request_preview_handler_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

IssuanceReadinessInput _input({
  bool orderCompleted = true,
  bool configReady = true,
  EffectiveBuyerInvoiceData? buyer,
}) =>
    IssuanceReadinessInput(
      orderCompleted: orderCompleted,
      hasElectronicInvoice: false,
      hasActiveOperation: false,
      configReady: configReady,
      providerConnected: true,
      providerSupportsPreview: true,
      buyer: buyer ??
          const EffectiveBuyerInvoiceData(buyerType: BuyerType.retail, name: 'NTD'),
      buyerCompletionState: BuyerCompletionStatus.locked,
    );

void main() {
  test('scn_e02_u01_fr07_01: ready order enqueues preview and returns pending result', () async {
    final preview = FakeInvoicePreviewGateway(requestId: 'pv1');
    final handler = RequestInvoicePreviewCommandHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(result: _input()),
      previewGateway: preview,
    );
    final dto = await handler.handle(RequestInvoicePreviewCommand(
        tenantId: 't1', actorId: 'a1', salesOrderId: 'so1', expectedOrderVersion: 2));
    expect(preview.enqueuedFor, 'so1');
    expect(dto.warnings, isNotNull);
  });

  test('scn_e02_u01_fr08_01: org missing tax code still previews (canPreview)', () async {
    final preview = FakeInvoicePreviewGateway(requestId: 'pv2');
    final handler = RequestInvoicePreviewCommandHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(
          result: _input(buyer: const EffectiveBuyerInvoiceData(
              buyerType: BuyerType.organization, name: 'Cty A', address: 'HN'))),
      previewGateway: preview,
    );
    await handler.handle(RequestInvoicePreviewCommand(
        tenantId: 't1', actorId: 'a1', salesOrderId: 'so1', expectedOrderVersion: 1));
    expect(preview.enqueuedFor, 'so1');
  });

  test('scn_e02_u01_fr02_01: order not completed blocks preview with ISSUANCE_NOT_READY', () async {
    final preview = FakeInvoicePreviewGateway(requestId: 'pv3');
    final handler = RequestInvoicePreviewCommandHandler(
      readinessGateway: FakeIssuanceReadinessReadGateway(result: _input(orderCompleted: false)),
      previewGateway: preview,
    );
    expect(
      () => handler.handle(RequestInvoicePreviewCommand(
          tenantId: 't1', actorId: 'a1', salesOrderId: 'so1', expectedOrderVersion: 1)),
      throwsA(isA<EInvoiceBlockedException>()
          .having((e) => e.code, 'code', EInvoiceBlockedCodes.issuanceNotReady)),
    );
    expect(preview.enqueuedFor, isNull);
  });
}
```

- [ ] **Bước 4: Chạy test để xác nhận đỏ**

Chạy: `cd modules/einvoice/application && dart test test/issuance/scn_e02_u01_request_preview_handler_test.dart`
Kỳ vọng: FAIL — chưa có handler/fake.

- [ ] **Bước 5: Viết handler request-preview**

```dart
// .../request_invoice_preview/request_invoice_preview_command_handler.dart
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_issuance_readiness_read_gateway.dart';
import '../../../shared/einvoice_blocked_codes.dart';
import '../../../shared/einvoice_blocked_exception.dart';
import 'request_invoice_preview_command.dart';
import 'request_invoice_preview_result.dart';

@CommandHandlerFor(RequestInvoicePreviewCommand)
final class RequestInvoicePreviewCommandHandler
    implements ICommandHandler<RequestInvoicePreviewCommand, InvoicePreviewResultDto> {
  RequestInvoicePreviewCommandHandler({
    required IIssuanceReadinessReadGateway readinessGateway,
    required IInvoicePreviewGateway previewGateway,
  })  : _readinessGateway = readinessGateway,
        _previewGateway = previewGateway;

  final IIssuanceReadinessReadGateway _readinessGateway;
  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<InvoicePreviewResultDto> handle(
    RequestInvoicePreviewCommand command,
  ) async {
    final input = await _readinessGateway.load(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
    );
    final evaluation = IssuanceReadinessEvaluator.evaluate(input);

    if (!evaluation.canPreview) {
      throw EInvoiceBlockedException(
        EInvoiceBlockedCodes.issuanceNotReady,
        message: 'Không đủ điều kiện xem trước',
      );
    }

    await _previewGateway.persistRequestAndEnqueue(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
      expectedOrderVersion: command.expectedOrderVersion,
    );

    // Preview is produced asynchronously by the worker; return pending with
    // any non-blocking warnings so the UI can render them immediately.
    return InvoicePreviewResultDto(
      viewerRef: null,
      previewPayload: null,
      warnings: [for (final w in evaluation.warnings) w.message],
    );
  }
}
```

- [ ] **Bước 6: Viết handler get-preview**

```dart
// .../get_invoice_preview/get_invoice_preview_query_handler.dart
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../commands/request_invoice_preview/request_invoice_preview_result.dart';
import 'get_invoice_preview_query.dart';

@QueryHandlerFor(GetInvoicePreviewQuery)
final class GetInvoicePreviewQueryHandler
    implements IQueryHandler<GetInvoicePreviewQuery, InvoicePreviewResultDto> {
  GetInvoicePreviewQueryHandler({required IInvoicePreviewGateway previewGateway})
      : _previewGateway = previewGateway;

  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<InvoicePreviewResultDto> handle(GetInvoicePreviewQuery query) async {
    final cached = await _previewGateway.readCached(
      tenantId: query.tenantId,
      salesOrderId: query.salesOrderId,
    );
    return cached ??
        const InvoicePreviewResultDto(
            viewerRef: null, previewPayload: null, warnings: []);
  }
}
```

- [ ] **Bước 7: Viết fake preview gateway**

```dart
// modules/einvoice/application/lib/src/testing/fakes/fake_invoice_preview_gateway.dart
import '../../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';
import '../../ports/i_invoice_preview_gateway.dart';

final class FakeInvoicePreviewGateway implements IInvoicePreviewGateway {
  FakeInvoicePreviewGateway({required this.requestId, this.cached});

  final String requestId;
  final InvoicePreviewResultDto? cached;
  String? enqueuedFor;
  String? storedRequestId;

  @override
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    enqueuedFor = salesOrderId;
    return requestId;
  }

  @override
  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String salesOrderId,
  }) async =>
      cached;

  @override
  Future<void> storeResult({
    required String tenantId,
    required String previewRequestId,
    String? viewerRef,
    Map<String, Object?>? previewPayload,
  }) async {
    storedRequestId = previewRequestId;
  }
}
```

- [ ] **Bước 8: Export fake** (cùng barrel như Task 7 Bước 3).

- [ ] **Bước 9: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/application && dart test test/issuance/scn_e02_u01_request_preview_handler_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 10: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/ports/i_invoice_preview_gateway.dart modules/einvoice/application/lib/src/issuance/commands/request_invoice_preview/ modules/einvoice/application/lib/src/issuance/queries/get_invoice_preview/ modules/einvoice/application/lib/src/testing/fakes/fake_invoice_preview_gateway.dart modules/einvoice/application/test/issuance/scn_e02_u01_request_preview_handler_test.dart
git commit -m "feat(einvoice): request/get invoice preview handlers (S2a)"
```

---

## Task 10: MISA port — thêm previewUnpublished + adapter impl

**Files:**
- Sửa: `modules/einvoice/application/lib/src/ports/i_me_invoice_provider_port.dart`
- Sửa: `modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_provider_adapter.dart`
- Test: `modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart`

**Interfaces:**
- Consumes: `IMeInvoiceClient.previewUnpublished(MeInvoiceInvoiceData)` (từ `packages/vet45_misa`), `FakeMeInvoiceClient` cho test.
- Produces:
  - Trên `IMeInvoiceProviderPort`: `Future<MeInvoicePreviewOutcome> previewUnpublished({required String tenantId, required Map<String, Object?> canonicalInvoice});`
  - `final class MeInvoicePreviewOutcome` với `.success({required String viewerRef})`, `.authFailed()`, `.providerUnavailable()`, và `bool get isSuccess`, `String? get viewerRef` (mô phỏng `MeInvoiceAuthOutcome`).

- [ ] **Bước 1: Chạy impact analysis**

Chạy: `impact({target: "IMeInvoiceProviderPort", direction: "upstream"})`. Báo; dừng nếu HIGH/CRITICAL. (Caller dự kiến: `MeInvoiceProviderAdapter`, `SyncProviderCapabilitiesCommandHandler`, DI trong `EinvoiceStartup`.)

- [ ] **Bước 2: Đọc contract MISA client** để lấy type chính xác

Chạy: đọc `packages/vet45_misa/lib/src/e_invoice/i_me_invoice_client.dart`, `.../models/misa/invoice_data.dart` (`MeInvoiceInvoiceData`), và `.../models/me_invoice_result.dart` (`MeInvoiceResult`). Xác nhận `previewUnpublished(MeInvoiceInvoiceData) → Future<MeInvoiceResult<String>>` và cách dựng `MeInvoiceInvoiceData` / có `fromJson` hay constructor từ map không. Nếu không có constructor từ map, thêm mapper nhỏ `MeInvoiceInvoiceData _fromCanonical(Map<String,Object?>)` trong adapter (có ghi chú, không phải placeholder).

- [ ] **Bước 3: Thêm method port + outcome VO**

Thêm vào `i_me_invoice_provider_port.dart`:

```dart
  // add to IMeInvoiceProviderPort:
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  });
```

```dart
/// Result of a MISA unpublished-preview request.
final class MeInvoicePreviewOutcome {
  const MeInvoicePreviewOutcome.success({required String viewerRef})
      : _viewerRef = viewerRef,
        authFailed = false,
        providerUnavailable = false;

  const MeInvoicePreviewOutcome.authFailed()
      : _viewerRef = null,
        authFailed = true,
        providerUnavailable = false;

  const MeInvoicePreviewOutcome.providerUnavailable()
      : _viewerRef = null,
        authFailed = false,
        providerUnavailable = true;

  final String? _viewerRef;
  final bool authFailed;
  final bool providerUnavailable;

  bool get isSuccess => !authFailed && !providerUnavailable;
  String? get viewerRef => _viewerRef;
}
```

- [ ] **Bước 4: Viết test adapter (đỏ)**

```dart
// modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
// Test qua adapter với FakeMeInvoiceClient inject qua TenantMeInvoiceClientFactory.
// Mô phỏng đúng wiring của sync_provider_capabilities_handler_test.dart.

void main() {
  test('previewUnpublished maps a successful MISA preview to viewerRef', () async {
    // Dựng adapter với FakeMeInvoiceClient trả preview URL, theo đúng cách dựng
    // trong modules/einvoice/infrastructure/test/sync_provider_capabilities_handler_test.dart.
    // Assert outcome.isSuccess && outcome.viewerRef == '<fake url>'.
  }, skip: 'fill in using the sync_capabilities test harness pattern');
}
```

Sau đó thay phần skip bằng test cụ thể copy cấu trúc từ `sync_provider_capabilities_handler_test.dart` (đọc trước), assert `outcome.isSuccess` và `outcome.viewerRef`.

- [ ] **Bước 5: Implement `previewUnpublished` trong adapter**

Thêm vào `MeInvoiceProviderAdapter` (mô phỏng pattern credential-load + client-factory của `authenticateAndListTemplates`):

```dart
  @override
  Future<MeInvoicePreviewOutcome> previewUnpublished({
    required String tenantId,
    required Map<String, Object?> canonicalInvoice,
  }) async {
    try {
      final creds = await _readCredentials(tenantId: tenantId);
      if (creds == null) {
        return const MeInvoicePreviewOutcome.authFailed();
      }
      final client = _clientFactory.getOrCreate(
        tenantId: tenantId,
        config: MeInvoiceConfig(
          baseUrl: creds['base_url'] as String? ?? _defaultBaseUrl,
          appId: _defaultAppId,
          taxCode: creds['tax_code'] as String?,
          username: creds['username'] as String?,
          password: creds['password'] as String?,
        ),
        httpClient: _httpClient,
      );
      final invoice = _invoiceFromCanonical(canonicalInvoice);
      final result = await client.previewUnpublished(invoice);
      if (!result.isSuccess) {
        final message = (result.error ?? '').toLowerCase();
        if (message.contains('unavailable') || message.contains('timeout')) {
          return const MeInvoicePreviewOutcome.providerUnavailable();
        }
        return const MeInvoicePreviewOutcome.authFailed();
      }
      return MeInvoicePreviewOutcome.success(viewerRef: result.data ?? '');
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }

  MeInvoiceInvoiceData _invoiceFromCanonical(Map<String, Object?> canonical) {
    // Build MeInvoiceInvoiceData from the canonical map. Use the constructor /
    // fromJson confirmed in Step 2. Keep this mapping total (no silent drops).
    return MeInvoiceInvoiceData.fromJson(canonical); // adjust to real API
  }
```

- [ ] **Bước 6: Chạy test để xác nhận xanh**

Chạy: `cd modules/einvoice/infrastructure && dart test test/me_invoice_provider_adapter_preview_test.dart`
Kỳ vọng: PASS.

- [ ] **Bước 7: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/ports/i_me_invoice_provider_port.dart modules/einvoice/infrastructure/lib/src/adapters/misa/me_invoice_provider_adapter.dart modules/einvoice/infrastructure/test/me_invoice_provider_adapter_preview_test.dart
git commit -m "feat(einvoice): add MISA previewUnpublished port + adapter (S2a)"
```

---

## Task 11: Worker preview job — PreviewInvoiceCommand + handler

**Files:**
- Tạo: `modules/einvoice/application/lib/src/issuance/commands/preview_invoice/preview_invoice_command.dart`
- Tạo: `modules/einvoice/application/lib/src/issuance/commands/preview_invoice/preview_invoice_command_handler.dart`
- Test: `modules/einvoice/application/test/issuance/preview_invoice_command_json_test.dart`
- Test: `modules/einvoice/infrastructure/test/preview_invoice_worker_test.dart` (integration với FakeMeInvoiceClient — mô phỏng `sync_provider_capabilities_handler_test.dart`)

**Interfaces:**
- Consumes: `InternalCommandBase`/`ISerializableInternalCommand` (kernel), `IMeInvoiceProviderPort` (Task 10), `IInvoicePreviewGateway.storeResult` (Task 9).
- Produces: `PreviewInvoiceCommand` (`static const type = 'einvoice.preview_invoice'`) mang `tenantId, salesOrderId, previewRequestId, orderVersion, canonicalInvoice (Map<String,Object?>)`; worker handler `@CommandHandlerFor(PreviewInvoiceCommand)`.

- [ ] **Bước 1: Viết serializable command (mô phỏng SyncProviderCapabilitiesCommand)**

```dart
// .../preview_invoice/preview_invoice_command.dart
import 'package:vet45_shared_application/application.dart';

/// Internal — worker builds a MISA unpublished preview (durable). Creates no
/// issuance state (DR-02).
final class PreviewInvoiceCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  PreviewInvoiceCommand({
    String? id,
    required this.tenantId,
    required this.salesOrderId,
    required this.previewRequestId,
    required this.orderVersion,
    required this.canonicalInvoice,
  }) : super(id);

  static const type = 'einvoice.preview_invoice';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String salesOrderId;
  final String previewRequestId;
  final int orderVersion;
  final Map<String, Object?> canonicalInvoice;

  @override
  Map<String, dynamic> toJson() {
    return stripInternalCommandRowId(<String, dynamic>{
      'tenant_id': tenantId,
      'sales_order_id': salesOrderId,
      'preview_request_id': previewRequestId,
      'order_version': orderVersion,
      'canonical_invoice': canonicalInvoice,
    });
  }

  factory PreviewInvoiceCommand.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final n = normalizeInternalCommandDeserializeJson(json, rowId: id);
    return PreviewInvoiceCommand(
      id: id,
      tenantId: n['tenant_id'] as String,
      salesOrderId: n['sales_order_id'] as String,
      previewRequestId: n['preview_request_id'] as String,
      orderVersion: (n['order_version'] as num).toInt(),
      canonicalInvoice: Map<String, Object?>.from(n['canonical_invoice'] as Map),
    );
  }
}
```

- [ ] **Bước 2: Viết test round-trip JSON**

```dart
// modules/einvoice/application/test/issuance/preview_invoice_command_json_test.dart
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';

void main() {
  test('PreviewInvoiceCommand json round-trips', () {
    final cmd = PreviewInvoiceCommand(
      tenantId: 't1', salesOrderId: 'so1', previewRequestId: 'pv1',
      orderVersion: 2, canonicalInvoice: {'total': 100},
    );
    final back = PreviewInvoiceCommand.fromJson(cmd.toJson(), id: 'row1');
    expect(back.commandType, 'einvoice.preview_invoice');
    expect(back.salesOrderId, 'so1');
    expect(back.orderVersion, 2);
    expect(back.canonicalInvoice['total'], 100);
  });
}
```

Chạy: `cd modules/einvoice/application && dart test test/issuance/preview_invoice_command_json_test.dart` → PASS.

- [ ] **Bước 3: Viết worker handler**

```dart
// .../preview_invoice/preview_invoice_command_handler.dart
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import 'preview_invoice_command.dart';

@CommandHandlerFor(PreviewInvoiceCommand)
final class PreviewInvoiceCommandHandler
    implements ICommandHandler<PreviewInvoiceCommand, void> {
  PreviewInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IInvoicePreviewGateway previewGateway,
  })  : _providerPort = providerPort,
        _previewGateway = previewGateway;

  final IMeInvoiceProviderPort _providerPort;
  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<void> handle(PreviewInvoiceCommand command) async {
    final outcome = await _providerPort.previewUnpublished(
      tenantId: command.tenantId,
      canonicalInvoice: command.canonicalInvoice,
    );
    // Soft-fail path: missing credential / provider down should fail the job with
    // a stable code (worker tick continues) — throw so the internal-commands
    // handler records a fail and retries per policy (2x per job catalog).
    if (!outcome.isSuccess) {
      throw StateError(outcome.authFailed
          ? 'PROVIDER_NOT_CONNECTED'
          : 'PROVIDER_UNAVAILABLE');
    }
    await _previewGateway.storeResult(
      tenantId: command.tenantId,
      previewRequestId: command.previewRequestId,
      viewerRef: outcome.viewerRef,
    );
  }
}
```

Lưu ý: xác nhận cách `SyncProviderCapabilitiesCommandHandler` báo soft-fail (nó trả về các biến thể outcome và ghi qua gateway thay vì ném). Đọc và làm khớp convention đó — nếu nó dùng RPC result riêng thay vì ném, thì lưu trạng thái preview failed qua `previewGateway` thay cho `throw`. Điều chỉnh trước khi chốt (không placeholder: chọn đúng pattern sync handler dùng).

- [ ] **Bước 4: Viết test integration worker** mô phỏng `sync_provider_capabilities_handler_test.dart` (FakeMeInvoiceClient trả preview URL → handler lưu result; fake thiếu credential → soft-fail).

Chạy: `cd modules/einvoice/infrastructure && dart test test/preview_invoice_worker_test.dart` → PASS.

- [ ] **Bước 5: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/application/lib/src/issuance/commands/preview_invoice/ modules/einvoice/application/test/issuance/preview_invoice_command_json_test.dart modules/einvoice/infrastructure/test/preview_invoice_worker_test.dart
git commit -m "feat(einvoice): preview_invoice worker command + handler (S2a)"
```

---

## Task 12: Regen codegen + wiring DI cho handler mới

**Files:**
- Regen (không sửa tay): `modules/einvoice/infrastructure/lib/src/configuration/processing/generated/*.g.dart`
- Kiểm tra DI: registrar sinh ra wiring dependency của handler qua `container.get<IFoo>()`. Ba read gateway mới (Task 6/8/9) + `IMeInvoiceProviderPort` (đã đăng ký) phải resolve — đăng ký thật thêm ở Task 14. Với codegen + unit test, handler được dựng trực tiếp bằng fake, nên codegen chỉ cần annotation biên dịch được.

**Interfaces:**
- Consumes: mọi annotation `@CommandHandlerFor`/`@QueryHandlerFor` thêm ở Task 6–11, cộng `PreviewInvoiceCommand` (`ISerializableInternalCommand`).
- Produces: cập nhật `einvoice_cqrs_registrar.g.dart` (business handler: GetIssuanceReadiness, CompleteBuyerInvoiceData, RequestInvoicePreview, GetInvoicePreview; internal handler: PreviewInvoiceCommand), `einvoice_internal_command_registry.g.dart` (`einvoice.preview_invoice`), refresh manifest/access-metadata.

- [ ] **Bước 1: Regen**

Chạy: `melos run codegen` (fallback: `cd modules/einvoice/infrastructure && dart run build_runner build --delete-conflicting-outputs`).

- [ ] **Bước 2: Soi diff**

Chạy: `git diff --stat modules/einvoice/infrastructure/lib/src/configuration/processing/generated/`
Kỳ vọng: registrar thêm 4 business + 1 internal registration; internal registry thêm `preview_invoice`; access-metadata đã có sẵn command S2a (không churn ngoài preview command mới).

- [ ] **Bước 3: Analyze cả module**

Chạy: `cd modules/einvoice/infrastructure && dart analyze`
Kỳ vọng: 0 issue. (Nếu registrar tham chiếu gateway chưa đăng ký DI, điều đó ổn lúc analyze; resolve runtime lo ở Task 14.)

- [ ] **Bước 4: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/infrastructure/lib/src/configuration/processing/generated/
git commit -m "chore(einvoice): regenerate CQRS codegen for S2a handlers"
```

---

## Task 13: Draft SQL seam (schema + RPC)

**Files:**
- Tạo: `supabase/migrations/_drafts/NNN_einvoice_s2a_schema.sql`
- Tạo: `supabase/migrations/_drafts/NNN_einvoice_s2a_rpc.sql`

Chọn `NNN` là số prefix trống kế tiếp sau số cao nhất trong `_drafts/` (đọc `supabase/migrations/_drafts/` và `_drafts/README.md` trước).

**Interfaces:**
- Produces các RPC được Task 14 gateway gọi: `einvoice.get_issuance_readiness`, `einvoice.complete_buyer_invoice_data`, `einvoice.request_invoice_preview`, `einvoice.get_invoice_preview`, `einvoice.store_preview_result`. Tên phải khớp `07-api-contracts.md §S2a`.

- [ ] **Bước 1: Viết schema draft**

Header block + DDL idempotent. Bảng:

```sql
-- Title: einvoice S2a — buyer completion table + preview handoff columns
-- Kind: patch
-- Intent: buyer_invoice_completions per §4.4.3; extend provider_interaction_records for preview handoff (NO new business table)
-- Context: TH-08 EP-02/US-01; fake-seam — sales.* not yet available
-- Touches: einvoice.buyer_invoice_completions, einvoice.provider_interaction_records
-- Safety: idempotent (create/alter if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_s1_schema_configuration.sql

-- buyer_invoice_completions per canonical §4.4.3 (process entity, one of the 12 sanctioned).
-- NOTE: stores eligible_fields + resolved_values, NOT the runtime EffectiveBuyerInvoiceData.
create table if not exists einvoice.buyer_invoice_completions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  sales_order_id uuid not null,
  sales_order_version varchar(100) not null,
  buyer_partner_id uuid not null,
  status text not null default 'open',              -- open | locked
  eligible_fields jsonb not null default '[]',      -- required fields missing in BuyerInvoiceSnapshot, allowed to complete
  resolved_values jsonb not null default '{}',      -- controlled-completion values for eligible fields
  source_partner_revision varchar(100),
  source_partner_updated_at timestamptz,
  last_resolved_at timestamptz,
  locked_at timestamptz,
  version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, sales_order_id, sales_order_version)
);
alter table einvoice.buyer_invoice_completions enable row level security;

-- Preview handoff rides on the shared technical record provider_interaction_records (§4.3.5) —
-- NO new business table. S1 created a minimal version; extend it for preview target/status/result.
alter table einvoice.provider_interaction_records
  add column if not exists sales_order_id uuid,
  add column if not exists correlation_id uuid,
  add column if not exists order_version varchar(100),
  add column if not exists status text not null default 'pending',  -- pending | ready | failed
  add column if not exists viewer_ref text,                          -- transient; NFR-06: short-lived, not fully logged
  add column if not exists expires_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists provider_interaction_preview_idx
  on einvoice.provider_interaction_records
     (tenant_id, sales_order_id, interaction_type, created_at desc);
```

- [ ] **Bước 2: Viết RPC draft** (≤8 function — file này có 5)

Mỗi hàm `security definer`, `set search_path = einvoice, iam, public`, param `p_`, `returns table`, lỗi `raise exception '<CODE>: ...'`. Quy tắc mấu chốt: `get_issuance_readiness` đọc `iam.tenant_legal_profiles` (có sẵn) + bảng einvoice connection/profile/policy; join SalesOrder/BuyerInvoiceSnapshot là **TODO có ghi chú** trả default an toàn cho tới khi Theme 05 landing.

```sql
-- Title: einvoice S2a — readiness/preview/completion RPCs
-- Kind: patch
-- Intent: S2a read+command RPCs (get_issuance_readiness, complete_buyer_invoice_data,
--         request_invoice_preview, get_invoice_preview, store_preview_result)
-- Context: TH-08 EP-02/US-01. NOTE: sales.* source not available — see TODO markers.
-- Touches: einvoice.get_issuance_readiness, einvoice.complete_buyer_invoice_data,
--          einvoice.request_invoice_preview, einvoice.get_invoice_preview,
--          einvoice.store_preview_result
-- Safety: security definer, tenant scoped, raises stable CODE errors
-- Depends on: NNN_einvoice_s2a_schema.sql, 002_einvoice_s1_install_module_messaging.sql

-- p_expected_order_version is int at the Dart boundary but sales_order_version is
-- varchar(100) per §4.4.3 → cast to text on the way in.
create or replace function einvoice.request_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_expected_order_version int
) returns table(preview_request_id uuid) as $$
declare
  v_id uuid;
begin
  -- Preview handoff record on the shared technical table (NOT a business entity).
  insert into einvoice.provider_interaction_records(
    tenant_id, interaction_type, sales_order_id, correlation_id, order_version, status)
  values (
    p_tenant_id, 'preview', p_sales_order_id, gen_random_uuid(),
    p_expected_order_version::text, 'pending')
  returning id into v_id;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.preview_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', p_sales_order_id,
      'preview_request_id', v_id,           -- = provider_interaction_records.id
      'order_version', p_expected_order_version::text,
      -- TODO(Theme05): build canonical invoice from sales.* + buyer snapshot.
      'canonical_invoice', '{}'::jsonb
    ),
    p_source_event_id => v_id
  );
  return query select v_id;
end;
$$ language plpgsql security definer set search_path = einvoice, public;
```

Viết 4 hàm còn lại trong cùng file, theo đúng convention (nhớ `sales_order_version` là varchar → cast `int::text`):
- `get_issuance_readiness(p_tenant_id, p_actor_id, p_sales_order_id) returns table(level text, blockers jsonb, warnings jsonb, buyer_completion_state text)` — join `iam.tenant_legal_profiles` + bảng config einvoice + `buyer_invoice_completions`; `-- TODO(Theme05)` cho field order/buyer từ `sales.*` (default `order_completed=false` → an toàn cho tới khi có sales, hoặc trả các field thô mà Dart evaluator cần — khớp `IssuanceReadinessInput`).
- `complete_buyer_invoice_data(p_tenant_id, p_actor_id, p_sales_order_id, p_expected_order_version) returns table(locked boolean, eligible_fields jsonb, resolved_values jsonb)` — upsert vào `buyer_invoice_completions` (`eligible_fields`/`resolved_values`, **không** effective_buyer) guard theo `version` + `sales_order_version`; raise `STATE_CHANGED`/`BUYER_TAX_CODE_REQUIRED`/`BUYER_DATA_INCOMPLETE`.
- `get_invoice_preview(p_tenant_id, p_actor_id, p_sales_order_id) returns table(viewer_ref text, status text)` — row `provider_interaction_records` mới nhất với `interaction_type='preview'` cho sales_order (dùng `provider_interaction_preview_idx`).
- `store_preview_result(p_tenant_id, p_preview_request_id, p_viewer_ref text, p_status text) returns table(updated boolean)` — writeback từ worker vào đúng `provider_interaction_records.id`; guard `current_setting('request.jwt.claim.role', true) = 'service_role'` (mô phỏng `read_provider_credentials`); NFR-06: viewer_ref transient, đừng log đầy đủ.

- [ ] **Bước 3: Giao draft cho user test**

KHÔNG apply hay promote. Nói với user: "Draft SQL sẵn sàng ở `_drafts/NNN_einvoice_s2a_*.sql` — chạy thử trong SQL editor để kiểm tra cú pháp/idempotency; các join `sales.*` còn TODO vì Theme 05 chưa có." Xác nhận tên RPC khớp `07-api-contracts.md §S2a`.

- [ ] **Bước 4: Commit** (chỉ khi user yêu cầu)

```bash
git add supabase/migrations/_drafts/NNN_einvoice_s2a_schema.sql supabase/migrations/_drafts/NNN_einvoice_s2a_rpc.sql
git commit -m "feat(einvoice): draft S2a schema + RPC seam (deferred sales wiring)"
```

---

## Task 14: Supabase gateway mỏng + RPC mapper + đăng ký DI

**Files:**
- Tạo: `modules/einvoice/infrastructure/lib/src/data_access/supabase_issuance_readiness_read_gateway.dart`
- Tạo: `modules/einvoice/infrastructure/lib/src/data_access/supabase_buyer_invoice_data_gateway.dart`
- Tạo: `modules/einvoice/infrastructure/lib/src/data_access/supabase_invoice_preview_gateway.dart`
- Sửa: `modules/einvoice/infrastructure/lib/src/data_access/einvoice_rpc_mapper.dart`
- Sửa: `modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart`

**Interfaces:**
- Consumes: 3 port (Task 6/8/9), `SupabaseSchemaRpcClient`, `EinvoiceRpcMapper`, `mapEinvoiceRpcError`.
- Produces: `IIssuanceReadinessReadGateway`, `IBuyerInvoiceDataGateway`, `IInvoicePreviewGateway` đăng ký DI. Nhờ đó các lời gọi `container.get<...>()` của registrar codegen resolve được lúc runtime.

- [ ] **Bước 1: Thêm method mapper** vào `einvoice_rpc_mapper.dart`

Thêm `issuanceReadinessInputFromRow(Map)`, `buyerCompletionContextFromRow(Map)`, `invoicePreviewResultFromRow(Map)`, và param builder với key đúng tên `p_`. Theo style row-mapper hiện có (đọc snake_case, `Enum.values.byName`, xử lý jsonb list). Tái dùng parse blocker/`ReadinessWarningDto` đã có cho readiness S1.

- [ ] **Bước 2: Viết 3 gateway** (pattern = `supabase_provider_connection_command_gateway.dart`: `callList` → `.first` → mapper; `on RpcException catch (e) { throw mapEinvoiceRpcError(e); }`). Mỗi constructor nhận `SupabaseSchemaRpcClient rpcClient`.

Ví dụ (readiness):

```dart
// supabase_issuance_readiness_read_gateway.dart
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../errors/einvoice_error_mapper.dart';
import 'einvoice_rpc_mapper.dart';

final class SupabaseIssuanceReadinessReadGateway
    implements IIssuanceReadinessReadGateway {
  SupabaseIssuanceReadinessReadGateway({required SupabaseSchemaRpcClient rpcClient})
      : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_issuance_readiness',
        params: {
          'p_tenant_id': tenantId,
          'p_actor_id': actorId,
          'p_sales_order_id': salesOrderId,
        },
      );
      if (rows.isEmpty) throw RpcException('get_issuance_readiness returned no rows');
      return EinvoiceRpcMapper.issuanceReadinessInputFromRow(
          Map<String, dynamic>.from(rows.first));
    } on RpcException catch (error) {
      throw mapEinvoiceRpcError(error);
    }
  }
}
```

Viết buyer + preview gateway tương tự (preview `persistRequestAndEnqueue` gọi `request_invoice_preview` trả `preview_request_id`; `readCached` gọi `get_invoice_preview`; `storeResult` gọi `store_preview_result`).

- [ ] **Bước 3: Đăng ký trong `EinvoiceDataAccessModule.load`**

Thêm, cạnh các dòng `registerSingleton<...>` hiện có:

```dart
container.registerSingleton<IIssuanceReadinessReadGateway>(
  SupabaseIssuanceReadinessReadGateway(
      rpcClient: container.get<SupabaseSchemaRpcClient>()));
container.registerSingleton<IBuyerInvoiceDataGateway>(
  SupabaseBuyerInvoiceDataGateway(
      rpcClient: container.get<SupabaseSchemaRpcClient>()));
container.registerSingleton<IInvoicePreviewGateway>(
  SupabaseInvoicePreviewGateway(
      rpcClient: container.get<SupabaseSchemaRpcClient>()));
```

(Chạy `impact({target:"EinvoiceDataAccessModule", direction:"upstream"})` trước — đây là composition root.)

- [ ] **Bước 4: Analyze**

Chạy: `cd modules/einvoice/infrastructure && dart analyze`
Kỳ vọng: 0 issue.

- [ ] **Bước 5: Commit** (chỉ khi user yêu cầu)

```bash
git add modules/einvoice/infrastructure/lib/src/data_access/ modules/einvoice/infrastructure/lib/src/configuration/data_access/data_access_module.dart
git commit -m "feat(einvoice): thin Supabase gateways + DI for S2a (deferred sales)"
```

---

## Task 15: Cập nhật traceability/roadmap + verify toàn bộ

**Files:**
- Sửa: `docs/themes/TH-08-e-invoice/harness/05-traceability.md` (hàng §S2a BE)
- Sửa: `docs/themes/TH-08-e-invoice/harness/04-slice-roadmap.md` (S2 BE → `in_progress`)
- Sửa: `docs/themes/TH-08-e-invoice/README.md` (ghi chú Việc tiếp theo)

- [ ] **Bước 1: Cập nhật traceability** — đặt hàng §S2a BE thành `in_progress` (hoặc `done` chỗ đã có test id `scn_e02_u01_*`) và ghi lại test id thật đã tạo: `scn_e02_u01_fr01_01`, `scn_e02_u01_fr04_01`, `scn_e02_u01_fr07_01`, `scn_e02_u01_fr08_01`. Thêm dòng ghi chú: "BE qua fake read-port seam; nối sales.* hoãn tới Theme 05."

- [ ] **Bước 2: Cập nhật roadmap** — S2 lane BE `todo` → `in_progress`; thêm footnote về fake seam + hoãn join sales.

- [ ] **Bước 3: Chạy toàn bộ test suite module**

Chạy:
```bash
cd modules/einvoice/domain && dart test
cd ../application && dart test
cd ../infrastructure && dart test
```
Kỳ vọng: tất cả PASS, gồm mọi `scn_e02_u01_*` và test evaluator/resolver domain.

- [ ] **Bước 4: Analyze cả 4 package einvoice**

Chạy: `melos run analyze` (hoặc `dart analyze` trong domain/application/infrastructure). Kỳ vọng: 0 issue. KHÔNG chạy `dart format` cả package.

- [ ] **Bước 5: Kiểm tra phạm vi regression**

Chạy: `detect_changes({scope: "compare", base_ref: "main"})`. Xác nhận chỉ symbol/flow einvoice thay đổi; không rò sang module khác.

- [ ] **Bước 6: Guards**

Chạy: `./scripts/ci/guard_theme_traceability.sh && ./scripts/ci/guard_theme_structure.sh`
Kỳ vọng: PASS.

- [ ] **Bước 7: Commit** (chỉ khi user yêu cầu)

```bash
git add docs/themes/TH-08-e-invoice/
git commit -m "docs(einvoice): mark S2a BE in_progress + traceability test ids"
```

---

## Ghi chú tự rà (Self-Review)

- **Phủ spec (§S2a):** `GetIssuanceReadinessQuery` (Task 6/7), `CompleteBuyerInvoiceDataCommand` (Task 8), `RequestInvoicePreviewCommand` + `GetInvoicePreviewQuery` (Task 9), worker preview `previewUnpublished` (Task 10–11), tên RPC (Task 13). BR-08/UI-06 "khách tổ chức thiếu MST vẫn preview" mã hóa ở Task 4 (`canPreview`) và test ở Task 7/9. DR-02 "không tạo issuance state" được tôn trọng (đường preview không bao giờ tạo attempt/invoice).
- **Hoãn (có ghi chú, không im lặng):** mọi join `sales.*` mang marker `TODO(Theme05)`; gateway thật tồn tại nhưng chỉ trả dữ liệu khi Theme 05 landing — test chạy qua fake.
- **Ngoài phạm vi (S2b, plan riêng):** `IssueInvoiceCommand`, `AttemptSnapshot`, job `einvoice.publish_invoice`, `GetOrderInvoiceProjectionQuery`, aggregate `IssuanceAttempt`/`ElectronicInvoice`.
- **Guard type-consistency:** evaluator domain inline chuỗi blocker code; Task 7 Bước 1 test thứ hai assert `'BUYER_TAX_CODE_REQUIRED' == EInvoiceBlockedCodes.buyerTaxCodeRequired`, bắt được drift.
- **Giả định cần xác nhận-trước-khi-viết lúc thực thi:** constructor `EInvoiceBlockedException` (ghi chú Task 8), cách dựng `MeInvoiceInvoiceData` từ map canonical (Task 10 Bước 2), và convention soft-fail của sync handler (Task 11 Bước 3). Mỗi bước đều nói "đọc file tham chiếu trước" — không phải placeholder.
