# 4-A — Partner qua `PartnerRepository` (bỏ `IPartnerModule` khỏi app) + rule MST dùng chung

> Theme 3 (mã cũ P4) · Bước (a) chuyển kiến trúc · Gồm việc 4.1, 4.2 (PLAN.md mục Theme 3)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ (2026-11-01, chưa commit) | Review ✅ R1 (2026-11-01; 3 góp ý P3 không chặn; còn kiểm tay 7.2)
> Tài liệu: [PLAN.md](../../PLAN.md) "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ: test giữ hành vi trước"; [TH-03](../../../02-yeu-cau/TH-03-doi-tac-giao-dich.md) mục 6 (RPC, mã lỗi), 9.1, KI-14.
> Plan sau: [4-B](4-B-sua-ki-th03.md) (sửa KI + trigger), [4-W](4-W-partner-web.md) (bố cục web), [4-C](4-C-don-module-partner.md) (xoá module).

## 1. Mục tiêu

App `erp` gọi partner theo đường mới, giống Theme 1:

```text
Page ─▶ Cubit ─▶ PartnerRepository ─▶ SupabaseRpc ─▶ supabase.schema('partner').rpc(...)
```

Sau 4-A:

- `apps/erp/lib` không còn `import 'package:c45_partner_…'` (kể cả sales, pricing, router, DI).
- Model, enum, rule chuyển vào `features/partner`.
- Cubit chuyển từ `presentation/bloc/` sang `logic/`.
- Test dùng `FakePartnerRepository` thay `FakePartnerModule`.

Module `modules/partner` vẫn còn trên đĩa (4-C mới xoá). Giao diện iPhone không đổi, **trừ** các chỗ đổi có chủ đích ở mục 2 (Q2) và mục 5.

Quy tắc MST của partner gộp vào `core/validation/tax_code.dart`, dùng chung với IAM, và giữ nguyên hành vi đang có của partner (mục 4.6).

## 2. Quyết định (người dùng chốt 2026-11-01)

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Bố cục web của Theme 3 nằm ở plan nào | Plan riêng **4-W**, làm sau 4-B. 4-A không đụng bố cục |
| Q2 | Các chỗ đang hiện thẳng chuỗi lỗi kỹ thuật (`e.toString()`, `error.message` thô) | **Đổi luôn ở 4-A.** Dùng một hàm `partnerErrorMessage` theo TH-03 mục 6.4 (mục 4.5). Mã lạ → câu "Không thể … Vui lòng thử lại." của từng thao tác. Mã đã có câu riêng thì giữ nguyên câu |
| Q3 | Ba việc client mà module cũ làm trước RPC: (1) gọi thêm `get_partner_detail` để so version, (2) kiểm quyền ở client, (3) rule domain | **Bỏ (1)(2), giữ (3).** Server trả cùng mã `STATE_CHANGED` / `permission denied: partner.*`. Rule (3) thành hàm thuần `logic/partner_rules.dart`, repository gọi trước `create` / `update` / `transformToOrganization` |
| Q4 | Thứ tự plan | 4-A → 4-B → 4-W → 4-C, viết cả bốn cùng lúc |
| Q5 | Preview partner trong `apps/erp/example` (dựng trên `FakePartnerModule`, đổi chữ ký trang thì vỡ) | Xoá `apps/erp/example/lib/partner/` và mục "Partner" trong `example/lib/main.dart` ở 4-A. **Đề xuất của plan; duyệt plan là chốt** |

## 3. Hiện trạng (đo 2026-11-01)

### 3.1 Ai đang gọi module

| Nơi | Gọi gì |
|---|---|
| `features/partner/presentation/bloc/` 7 cubit | `IPartnerModule.executeCommandAsync / executeQueryAsync` + `IExecutionContext.requireTenantId / requireUserId` |
| `features/partner/presentation/widgets/partner_contact_select_list.dart:67` | `SearchPartnersQuery(partnerType: person, status: active, limit: 30, page: 1)` |
| `…/widgets/partner_detail_add_contact_flow.dart:53` | `AddOrganizationContactCommand` (vòng lặp, **không** có try/catch) |
| `…/widgets/partner_detail_soft_delete_flow.dart:27` | `CheckDeleteEligibilityQuery` |
| `features/sales/presentation/lookups/sales_partner_customer_lookup.dart` | search (customer, active, 30 ngày khi chưa gõ, limit 40), detail, check duplicate, create |
| `features/pricing/presentation/pages/pricing_pick_customer_page.dart:68` | search (customer, `requireAnyRole`, active, limit 30) |
| `core/router/app_router.dart` | truyền `getIt<IPartnerModule>()` + `getIt<IExecutionContext>()` cho 7 trang; `state.extra as PartnerType?`, `PartnerDetailDto?`, `PartnerContactDto?` |
| `core/di/injection.dart:164–171` | `PartnerStartup.initialize(...)`, đăng ký `IPartnerModule` |
| `features/sales/presentation/support/sales_external_lookups.dart:4,11` | chỉ chú thích nhắc `IPartnerModule` / `GetPartnerDetailQuery` |
| `apps/erp/example/lib/partner/**` | preview trên `FakePartnerModule` |

Đã có sẵn từ 1-B: `features/partner/data/partner_repository.dart` (`getActionLogs`), `data/models/partner_action_log.dart` (enum `PartnerActionType` riêng), `logic/partner_change_history_cubit.dart`. Giữ nguyên ba thứ này, chỉ thêm method.

### 3.2 RPC → tham số → kết quả (chép từ `modules/partner/infrastructure/lib/src/data_access/`)

Mọi RPC ở schema `partner`. `p_tenant_id` lấy từ phiên. `p_actor_id` = user đang đăng nhập.

| Method mới | RPC | Kiểu trả về PostgREST | Tham số (đúng tên, đúng thứ tự giá trị như `PartnerRpcMapper` / `PartnerReadRpcMapper`) | Kết quả |
|---|---|---|---|---|
| `search` | `search_partners` | table, 1 dòng | `p_tenant_id, p_query, p_partner_type (name), p_role, p_status (name), p_updated_within_days, p_page, p_limit, p_sort`. `p_role` = `'both'` nếu `requireBothRoles`; ngược lại `role?.name`; nếu cả hai rỗng mà `requireAnyRole` thì `'any'`; còn lại `null` | `PartnerSearchResultDto` (theo `mapSearchResult`). Không có dòng → coi như `{}` (items rỗng, total 0, page 1, limit 0) |
| `getDetail` | `get_partner_detail` | jsonb (map) | `p_tenant_id, p_partner_id` | `PartnerDetailDto` (theo `mapDetailResult`, `_personDto`, `_organizationDto`, `_contactRole`, `_invoiceDto`, `_deliveryDto`, `_organizationType`). Kết quả không phải map hoặc rỗng → `AppException(NOT_FOUND)` |
| `checkDuplicates` | `check_duplicate` | setof | `p_tenant_id, p_phone, p_email, p_tax_code, p_name, p_exclude_partner_id` | `List<PartnerDuplicateMatchDto>` (theo `mapDuplicateMatches`, `_matchField`, `_deriveMatchLevel`) |
| `checkDeleteEligibility` | `check_delete_eligibility` | table | `p_tenant_id, p_partner_id` | `DeleteEligibilityDto(eligible, reason)` |
| `getActionLogs` | (đã có) | | | |
| `create` | `create_partner` | table | `p_tenant_id, p_actor_id, p_partner_type, p_roles (name[]), p_person_profile, p_organization_profile, p_organization_primary_contact, p_confirm_duplicate` | `CreatePartnerResult(partnerId, warnings)` |
| `update` | `update_partner` | table | `p_tenant_id, p_actor_id, p_partner_id, p_roles, p_person_profile, p_organization_profile, p_confirm_duplicate, p_expected_version` | `UpdatePartnerProfileResult(partnerId, expectedVersion, warnings)` |
| `transformToOrganization` | `transform_to_organization` | table | `p_tenant_id, p_actor_id, p_partner_id, p_organization_profile, p_expected_version, p_confirm_duplicate` | `String partnerId` |
| `addContact` | `add_organization_contact` | table | `p_tenant_id, p_actor_id, p_organization_partner_id, p_person_partner_id, p_new_person_profile, p_contact_role, p_is_primary` | `AddOrganizationContactResult(organizationPartnerId, personPartnerId)` |
| `updateContact` | `update_organization_contact` | void | `p_tenant_id, p_actor_id, p_organization_partner_id, p_person_partner_id, p_contact_role, p_is_primary, p_note, p_person_profile` | `void` |
| `removeContact` | `remove_organization_contact` | void | `p_tenant_id, p_actor_id, p_organization_partner_id, p_person_partner_id` | `void` |
| `deactivate` / `reactivate` / `softDelete` | `deactivate_partner` / `reactivate_partner` / `soft_delete_partner` | table | `p_tenant_id, p_actor_id, p_partner_id, p_reason, p_expected_version` | `PartnerVersionResult(partnerId, expectedVersion)` |

**Hồ sơ gửi lên** (`_personInput`, `_organizationInput`, `_invoiceNested`, `_deliveryNested`). Chép **nguyên khoá** vào hàm `toRpcJson()` của model input:

- `invoice` gửi cả hai dạng: lồng (`name/address/email`) và phẳng (`invoice_name/…`).
- `delivery` cũng gửi cả hai dạng.
- `organization_type`: `company` / `business_household` / `other`.
- `title`: `PersonTitle.value`.

Không bớt khoá nào.

**Lỗi.** Mọi RPC báo lỗi dạng `CODE: message` (`partner._raise_partner_error`), riêng thiếu quyền là `permission denied: partner.<mã>`. `SupabaseRpc` đã đổi sang `AppException`:

- `CODE: …` → `code = CODE`, `serverMessage = phần sau dấu hai chấm`;
- `permission denied…` → `NO_PERMISSION`;
- `not authenticated` → `AUTHENTICATION_REQUIRED`;
- lỗi mạng → `NETWORK_ERROR`.

Ví dụ `DUPLICATE_WARNING: [{"code":"DUPLICATE_WARNING","field":"phone",…}]`: `serverMessage` là chuỗi JSON mảng, `details` = null.

## 4. Thiết kế

### 4.1 Model (`apps/erp/lib/features/partner/data/models/`)

Chép class / enum từ module, **giữ nguyên tên class, tên field, constructor, giá trị mặc định**. Chỉ đổi import. Không thêm `Equatable` (bản gốc không có).

| Tệp mới | Chứa (chép từ) |
|---|---|
| `partner_enums.dart` | `PartnerType`, `PartnerStatus`, `PartnerRoleType`, `OrganizationType` (`modules/partner/domain/lib/src/enums/`); `PartnerAvailableAction` (`…/get_partner_detail/partner_available_action.dart`); `PartnerDuplicateMatchField`, `PartnerDuplicateMatchLevel` (`…/check_duplicate/`) |
| `person_title.dart` | `final class PersonTitle { PersonTitle(String raw) : value = raw { if (raw.trim().isEmpty) throw ArgumentError.value(raw, 'raw', 'Person title must not be blank'); } final String value; ==/hashCode theo value; toString() => value; }`. Bản cũ kế thừa `ValueObject`, so bằng theo `value`. Bản mới giữ đúng ngữ nghĩa đó, không phụ thuộc `c45_shared_domain` |
| `partner_inputs.dart` | `PersonProfileInput`, `OrganizationProfileInput`, `InvoiceProfileInput`, `DeliveryAddressInput` (`application/lib/src/partner/shared/`) + `Map<String, dynamic> toRpcJson()` theo mục 3.2 |
| `partner_detail.dart` | `PartnerDetailDto`, `PersonProfileDto`, `OrganizationProfileDto`, `PartnerContactDto` + `factory PartnerDetailDto.fromJson(Map<String, dynamic>)`, thân chép từ `PartnerReadRpcMapper.mapDetailResult` và các hàm `_…` nó gọi |
| `partner_list_item.dart` | `PartnerListItemDto`, `PartnerSearchResultDto` + `PartnerSearchResultDto.fromJson` (từ `mapSearchResult`) |
| `partner_duplicate_match.dart` | `PartnerDuplicateMatchDto` + `fromJson` (từ `mapDuplicateMatches`, `_matchField`, `_deriveMatchLevel`) |
| `partner_write_results.dart` | `PartnerWarningDto`, `CreatePartnerResult`, `UpdatePartnerProfileResult`, `AddOrganizationContactResult`, `DeleteEligibilityDto` (chép), cùng các `fromJson` theo `PartnerRpcMapper.map…Result`. **Mới:** `final class PartnerVersionResult { const PartnerVersionResult({required this.partnerId, required this.expectedVersion}); … }` thay ba class `Deactivate/Reactivate/SoftDeletePartnerResult` (cùng hai field) |
| `partner_error_codes.dart` | `abstract final class PartnerErrorCodes`: cùng tên hằng, cùng giá trị chuỗi với `PartnerBlockedCodes` cũ (`noPermission = AppErrorCode.noPermission`, `notFound = AppErrorCode.notFound`, `validationError = AppErrorCode.validation`, `stateChanged = AppErrorCode.stateChanged`, `systemError = AppErrorCode.unknown`, `duplicateWarning = 'DUPLICATE_WARNING'`, `invalidStatus = 'INVALID_STATUS'`, `hasTransactions = 'HAS_TRANSACTIONS'`, `primaryContactOfOrganization = 'PRIMARY_CONTACT_OF_ORGANIZATION'`) |
| `../../logic/partner_permissions.dart` (tức `features/partner/logic/`) | `PartnerPermissions`, chép nguyên 9 hằng (`modules/partner/domain/lib/src/partner_permissions.dart`) |

Không chuyển các thứ sau: `GetPartnerHistoryQuery`, `PartnerHistoryItemDto`, `PartnerTransactionType`, `RecordPartnerHistoryCommand`. App không dùng chúng; RPC `get_partner_history` giữ ở DB, TH-03 mục 8.

Không chuyển `PartnerActionLogItemDto` / `PartnerActionLogResultDto`: app đã có `PartnerActionLog` / `PartnerActionLogPage`.

### 4.2 `PartnerRepository` (`features/partner/data/partner_repository.dart`, sửa tệp đã có)

```dart
class PartnerRepository {
  PartnerRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  });

  Future<PartnerSearchResultDto> search({
    String? query, PartnerType? partnerType, PartnerRoleType? role,
    bool requireBothRoles = false, bool requireAnyRole = false,
    PartnerStatus? status, int? updatedWithinDays,
    int page = 1, int limit = 20, String? sort,
  });
  Future<PartnerDetailDto> getDetail(String partnerId);
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates({
    String? phone, String? email, String? taxCode, String? name, String? excludePartnerId,
  });
  Future<DeleteEligibilityDto> checkDeleteEligibility(String partnerId);
  Future<PartnerActionLogPage> getActionLogs(String partnerId, {int page = 1, int limit = 20}); // giữ
  Future<CreatePartnerResult> create({
    required PartnerType partnerType, required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile, OrganizationProfileInput? organizationProfile,
    PersonProfileInput? organizationPrimaryContact, bool confirmDuplicate = false,
  });
  Future<UpdatePartnerProfileResult> update({
    required String partnerId, required int expectedVersion, required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile, OrganizationProfileInput? organizationProfile,
    bool confirmDuplicate = false,
  });
  Future<String> transformToOrganization({
    required String partnerId, required int expectedVersion,
    required OrganizationProfileInput organizationProfile, bool confirmDuplicate = false,
  });
  Future<AddOrganizationContactResult> addContact({
    required String organizationPartnerId, String? personPartnerId,
    PersonProfileInput? newPersonProfile, String? contactRole, bool isPrimary = false,
  });
  Future<void> updateContact({
    required String organizationPartnerId, required String personPartnerId,
    String? contactRole, bool? isPrimary, String? note, PersonProfileInput? personProfile,
  });
  Future<void> removeContact({required String organizationPartnerId, required String personPartnerId});
  Future<PartnerVersionResult> deactivate(String partnerId, {required int expectedVersion, String? reason});
  Future<PartnerVersionResult> reactivate(String partnerId, {required int expectedVersion, String? reason});
  Future<PartnerVersionResult> softDelete(String partnerId, {required int expectedVersion, String? reason});
}
```

- RPC kiểu **table**: dùng `_rpc.rows(...)`.
  - `search`: không có dòng → `{}`.
  - Các RPC còn lại: dùng `_rpc.firstRow(...)`, không có dòng → `NOT_FOUND`. Bản cũ trả `{}` rồi vỡ khi ép kiểu, cũng ra lỗi chung.
- `get_partner_detail` trả map: dùng `_rpc.call(...)`.
- Hai RPC void: dùng `_rpc.call(...)`.
- `create`, `update`, `transformToOrganization` gọi rule mục 4.3 **trước** khi gọi RPC. Rule sai → ném `AppException(AppErrorCode.validation, serverMessage: <message của rule>)`, không gọi RPC.
- Không gọi thêm `get_partner_detail`, không kiểm quyền ở client (Q3).

### 4.3 Rule (`features/partner/logic/partner_rules.dart`)

Hàm thuần, chép đúng điều kiện từ domain (`modules/partner/domain/lib/src/partner/**`):

| Hàm | Kiểm (rule gốc) | Gọi ở |
|---|---|---|
| `checkRoles(List<PartnerRoleType>)` | không rỗng (`PartnerMustHaveAtLeastOneRoleRule`, `CreatePartnerCommandValidator`) | `create`, `update` |
| `checkProfileMatchesType(PartnerType, {person, organization})` | đúng một hồ sơ khớp loại (`PersonOrOrganizationProfileExclusiveRule`, `CreatePartnerCommandValidator`) | `create` |
| `checkPersonProfile(PersonProfileInput)` | `fullName.trim()` không rỗng (`PartnerDisplayNameMustNotBeBlankRule`). `phone` không rỗng và 8–15 chữ số sau khi bỏ ký tự không phải số (`PhoneMustNotBeBlankRule`, `PhoneFormatInvalidRule`). `phone2 != null` → kiểm cùng luật. `email != null` và khác rỗng → khớp `^[^@]+@[^@]+\.[^@]+$` (`EmailFormatInvalidRule`). `taxCode != null` → `trim()` không rỗng (`TaxCodeMustNotBeBlankRule`). `invoice?.invoiceEmail != null` → luật email | `create` (person), `update` (person) |
| `checkOrganizationProfile(OrganizationProfileInput)` | `organizationName` không rỗng. `phone`, `email`, `taxCode`, `invoice.invoiceEmail` theo cùng luật trên | `create` (org), `update` (org), `transformToOrganization` |

**Không** kiểm `organizationPrimaryContact` và hồ sơ người liên hệ: bản cũ cũng không kiểm.

**Không** kiểm chuyển trạng thái, hồ sơ đã xoá, đúng loại khi chuyển đổi: server trả `INVALID_STATUS` (mục 5, dòng H4).

### 4.4 Cubit (`features/partner/logic/`)

Chuyển bằng `git mv` 16 tệp `features/partner/presentation/bloc/*.dart` → `features/partner/logic/` (giữ tên tệp):

- 7 cubit + 7 state;
- `partner_create_draft_mapper.dart`;
- `partner_create_form_validator.dart`.

Rồi trong mỗi cubit:

- Constructor: bỏ `IPartnerModule partnerModule` và `IExecutionContext executionContext`, thêm `required PartnerRepository repository`.
- Bỏ mọi `requireTenantId()` / `requireUserId()`: repository tự lấy.
- `executeQueryAsync(XQuery(...))` / `executeCommandAsync(XCommand(...))` → method tương ứng ở mục 4.2, **cùng giá trị tham số**.
- `on PartnerBlockedException catch (e)` → `on AppException catch (e)`; `e.code` giữ nguyên chỗ so; `PartnerBlockedCodes.x` → `PartnerErrorCodes.x`.
- `e.message` → `e.serverMessage`, chỉ còn ở `PartnerTransformCubit` để lấy JSON trùng (mục 5, H17).

Các chỗ bắt lỗi theo bảng mục 5.

### 4.5 Câu lỗi (`features/partner/logic/partner_error_messages.dart`, Q2)

```dart
/// TH-03 mục 6.4. [fallback] là câu "Không thể … Vui lòng thử lại." của thao tác.
String partnerErrorMessage(Object error, {required String fallback, String? noPermission}) {
  final code = error is AppException ? error.code : AppErrorCode.unknown;
  return switch (code) {
    PartnerErrorCodes.noPermission => noPermission ?? 'Bạn không có quyền thực hiện thao tác này.',
    PartnerErrorCodes.notFound => 'Không tìm thấy hồ sơ.',
    PartnerErrorCodes.stateChanged => 'Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại.',
    PartnerErrorCodes.invalidStatus => 'Trạng thái hồ sơ không cho phép thao tác này.',
    PartnerErrorCodes.duplicateWarning => 'Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại.',
    _ => fallback,
  };
}
```

Mọi chuỗi trong tệp này và trong bảng mục 5 là **nguyên văn**.

### 4.6 MST dùng chung (`core/validation/tax_code.dart`, KI-14)

Hiện có hai bộ:

- **Core** (IAM dùng): `normalizeTaxCode` chỉ `trim()`; `isValidTaxCode('')` = `false`.
- **Partner** (`PartnerCreateFormValidator`): `normalizeTaxCode` bỏ **mọi** khoảng trắng, 13 số liền → `10-3`; rỗng là hợp lệ.

Regex hai bên như nhau.

Thêm vào `core/validation/tax_code.dart`, **không sửa** hai hàm đang có (IAM không đổi):

```dart
/// Ô MST nhập tay (partner): bỏ mọi khoảng trắng; gõ liền 13 số thì thành `10 số-3 số`.
String compactTaxCodeInput(String raw) {
  final compact = raw.replaceAll(RegExp(r'\s'), '');
  if (RegExp(r'^\d{13}$').hasMatch(compact)) {
    return '${compact.substring(0, 10)}-${compact.substring(10)}';
  }
  return compact;
}
```

Trong `PartnerCreateFormValidator`:

- `normalizeTaxCode(v)` → trả `compactTaxCodeInput(v)`;
- `isValidTaxCode(v)` → `final n = compactTaxCodeInput(v); return n.isEmpty || core.isValidTaxCode(n);`;
- xoá `_taxCodePattern`;
- giữ `taxCodeInvalid` (câu riêng của partner, không dùng `taxCodeFormatMessage`).

Vì core có hàm cùng tên `isValidTaxCode` / `normalizeTaxCode`, import core với `as core`.

## 5. Đang làm gì — test giữ hành vi

Thứ bị thay: module (handler + pipeline + mapper + error mapper), cách bắt lỗi trong cubit / widget / sales / pricing, `FakePartnerModule`. Mỗi dòng có test ở bước 0 (mục 6, viết **trên code cũ**). Dòng ghi "**Đổi (Q2/Q3)**" là đổi có chủ đích: bước 0 ghi hành vi cũ, rồi sửa kỳ vọng cùng commit đổi code. Trong mục Kết quả ghi rõ test nào đổi kỳ vọng.

| # | Cơ chế cũ đang làm gì (tệp) | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| H1 | Tham số mọi RPC (`PartnerRpcMapper`, `PartnerReadRpcMapper` `…Params`) | `PartnerRepository` + `toRpcJson()` | `test/features/partner/data/partner_rpc_parity_test.dart`: cùng một bộ input mẫu (mục 6, bước 0.1). Nhóm "old" gọi mapper cũ, so với map mong đợi viết tay. Nhóm "new" gọi repository qua `_Rpc` ghi lời gọi, so với **cùng** map đó |
| H2 | Đọc kết quả mọi RPC (`map…Result`, `mapDetailResult`, `_contactRole` bỏ `'primary'`, `_invoiceDto` rỗng → null, `_organizationType` nhận cả `businessHousehold`, `_matchField` nhận `tax_code`/`taxCode`, `_deriveMatchLevel`, `mapSearchResult` mặc định `total/page/limit`) | `fromJson` ở mục 4.1 | cùng tệp H1: JSON mẫu → DTO, so từng field |
| H3 | Rule domain chạy trước RPC create / update / transform (handler + `PartnerDomainMapper` + value object) | `partner_rules.dart`, gọi trong repository | `test/features/partner/logic/partner_rules_test.dart`: mỗi rule một ca sai + một ca đúng (SĐT 7 / 8 / 15 / 16 số, email `a@b` sai / `a@b.c` đúng, MST `'  '` sai, roles rỗng, person thiếu hồ sơ, org có cả hai hồ sơ). Nhóm "old" gọi `PartnerDomainMapper.validateCreate` / `toPersonProfile` / `toOrganizationProfile`, kỳ vọng ném lỗi. Nhóm "new" gọi hàm mới, kỳ vọng `AppException(VALIDATION_ERROR)`. Thêm 1 ca: repository `create` với SĐT sai **không** gọi RPC |
| H4 | Handler update / deactivate / reactivate / softDelete / transform gọi `get_partner_detail` trước. Version lệch → `STATE_CHANGED`; không có → `NOT_FOUND`; rule trạng thái (đã xoá, chuyển không hợp lệ, có giao dịch) → lỗi domain → cubit rơi vào nhánh `catch (_)` | **Đổi (Q3):** bỏ, server tự trả `STATE_CHANGED` / `NOT_FOUND` / `INVALID_STATUS` / `HAS_TRANSACTIONS` | repository test: `deactivate(...)` gọi **đúng 1** RPC (`deactivate_partner`), không gọi `get_partner_detail`; cubit test `PartnerStatusCubit`: `INVALID_STATUS` → "Trạng thái hồ sơ không cho phép thao tác này." |
| H5 | Pipeline kiểm quyền client theo `partner_access_metadata.g.dart` + kiểm tenant (`ensureAccess` gọi `get_session_context`). Thiếu quyền → `ApplicationException`, cubit rơi vào nhánh lỗi chung | **Đổi (Q3):** bỏ; server `permission denied: partner.*` → `NO_PERMISSION` → câu thiếu quyền của từng thao tác | repository test: `search` không gọi RPC nào khác ngoài `search_partners` |
| H6 | `mapPartnerRpcError`: tìm mã **ở bất kỳ đâu** trong message (`contains`) | `AppException.from` (mã ở đầu message). Mọi lỗi partner đều có dạng `CODE: …` hoặc `permission denied: …` (`_raise_partner_error`, đo 2026-11-01) | repository test: `_Rpc` ném `PostgrestException(message: 'STATE_CHANGED: version mismatch')` → `AppException.code == 'STATE_CHANGED'`. `'permission denied: partner.update'` → `NO_PERMISSION`. `'DUPLICATE_WARNING: [{"field":"phone"}]'` → code `DUPLICATE_WARNING`, `serverMessage` chứa `"field":"phone"` |
| H7 | `PartnerListCubit`: lọc bỏ dòng `roles` rỗng; `hasReachedMax = items.length < 20`; trang tiếp; giữ bộ lọc khi lỗi; map sort; `requireAnyRole: true` | giữ nguyên trong cubit | `partner_list_cubit_test.dart` hiện có (chuyển sang `test/features/partner/logic/`). Bước 0 thêm 1 ca: lỗi → `PartnerListError` giữ `query/partnerType/roleFilter/status/updatedTimeFilter/sortOption` |
| H8 | `PartnerDetailCubit`: `roles` rỗng → lỗi `isContactOnly`. `NOT_FOUND` → `isNotFound`. `NO_PERMISSION` hoặc chuỗi chứa `permission denied` → `isNoPermission`. Còn lại → lỗi chung | `isNotFound = code == NOT_FOUND`, `isNoPermission = code == NO_PERMISSION`, theo `AppException.code` | `partner_detail_cubit_test.dart` (mới ở bước 0): 4 ca (contact-only, không thấy, thiếu quyền, lỗi khác) |
| H9 | `PartnerCreateCubit._mapFailure`: `NO_PERMISSION` → `blocked` + "Bạn chưa có quyền chỉnh sửa KH & NCC." / "Bạn chưa có quyền tạo KH & NCC."; `DUPLICATE_WARNING` → "Đã tồn tại hồ sơ trùng MST/SĐT/email. Vui lòng kiểm tra lại."; `STATE_CHANGED` → "Hồ sơ đã được cập nhật bởi người khác. Vui lòng tải lại rồi thử lại."; `NOT_FOUND` → "Không tìm thấy hồ sơ hoặc bạn không có quyền xem."; mã khác → `error.message` thô hoặc "Không thể lưu KH & NCC."; lỗi không phải partner → "Không thể lưu dữ liệu. Vui lòng thử lại." | giữ 4 mã đầu nguyên câu. **Đổi (Q2):** mã khác → `partnerErrorMessage(e, fallback: 'Không thể lưu dữ liệu. Vui lòng thử lại.')`. `INVALID_STATUS` → "Trạng thái hồ sơ không cho phép thao tác này.". `VALIDATION_ERROR`, mạng, mã lạ → fallback | `partner_create_cubit_test.dart`: thêm 1 ca cho mỗi mã (6 ca) |
| H10 | `PartnerCreateCubit.submit`: kiểm trùng hồ sơ chính (`phone` chuẩn hoá, `email.trim`, MST `normalizeTaxCode`, tên, `excludePartnerId` khi sửa). Khi tạo tổ chức có người liên hệ chính: kiểm trùng **thêm** SĐT / email người liên hệ. Có `exact` → mức exact | giữ nguyên | test hiện có + bước 0 thêm: tạo tổ chức có người liên hệ chính → 2 lời gọi kiểm trùng, lời gọi 2 chỉ có phone / email |
| H11 | `PartnerStatusCubit`: `NO_PERMISSION` → "Bạn không có quyền thay đổi trạng thái hồ sơ." (xoá: "Bạn không có quyền xóa hồ sơ."). `STATE_CHANGED`, `INVALID_STATUS` (xoá: "Trạng thái hồ sơ không cho phép xóa."), `NOT_FOUND`, `HAS_TRANSACTIONS` (chỉ xoá) theo câu hiện có. Mã khác → message thô. Lỗi khác → "Không thể ngừng hoạt động. / kích hoạt lại. / xóa hồ sơ. Vui lòng thử lại." | giữ câu các mã đã có (kể cả "Anh có thể…": 4-B sửa). **Đổi (Q2):** mã khác → câu "Không thể … Vui lòng thử lại." của thao tác đó (cùng câu nhánh lỗi khác) | `partner_status_cubit_test.dart`: thêm mã lạ `X_UNKNOWN` cho cả 3 thao tác |
| H12 | `PartnerContactFormCubit`: mọi lỗi → `errorMessage: e.toString()`, hiện trong `PartnerContactForm`. Có kiểm trùng trước khi tạo (bỏ qua khi `ignoreDuplicate`); `editContact` gửi kèm `personProfile`; `note` gửi cả ở link và hồ sơ | **Đổi (Q2):** `createContact` / `editContact` / `linkExistingContact` → `partnerErrorMessage(e, fallback: 'Không thể lưu người liên hệ. Vui lòng thử lại.', noPermission: 'Bạn không có quyền quản lý người liên hệ.')`. `loadPersonDetail` → `partnerErrorMessage(e, fallback: 'Không tải được thông tin người liên hệ. Vui lòng thử lại.')`. Phần còn lại giữ | `partner_contact_form_cubit_test.dart`: thêm 1 ca `NO_PERMISSION`, 1 ca `DUPLICATE_WARNING` lọt qua, 1 ca mã lạ; kiểm đúng câu |
| H13 | `PartnerContactsCubit`: tải lỗi → `PartnerContactsError(e.toString(), isNoPermission: chuỗi chứa NO_PERMISSION/permission denied)`, hiện câu ở `PartnerContactsErrorBody` khi không thiếu quyền. Lỗi thao tác (đặt chính / gỡ / thêm có sẵn) → `actionError: e.toString()`, `isActionLoading: false`. **Không** chỗ nào hiện `actionError` (grep 2026-11-01) | **Đổi (Q2):** tải lỗi → message `partnerErrorMessage(e, fallback: 'Không tải được danh sách người liên hệ. Vui lòng thử lại.')`, `isNoPermission = code == NO_PERMISSION`. `actionError` → `partnerErrorMessage(e, fallback: 'Không thể cập nhật người liên hệ. Vui lòng thử lại.')`. Hiện `actionError` lên màn: việc của 4-B (G2) | `partner_contacts_cubit_test.dart`: thêm ca tải lỗi thiếu quyền, tải lỗi khác, thao tác lỗi (đúng chuỗi `actionError`) |
| H14 | `PartnerContactSelectList` (widget): lỗi tìm → "Lỗi: ${e.toString()}" | **Đổi (Q2):** `partnerErrorMessage(e, fallback: 'Không tải được danh sách cá nhân. Vui lòng thử lại.')`, hiện **không** có tiền tố "Lỗi: ". Tham số widget: `repository` thay `partnerModule` + `executionContext`. Lọc `excludePersonPartnerIds`, giữ lựa chọn còn trong danh sách mới, debounce 300 ms: giữ | widget test mới: repository ném lỗi → thấy câu fallback; danh sách bỏ id bị loại trừ |
| H15 | `runPartnerDetailAddContactFlow` nhánh chọn có sẵn: vòng lặp `AddOrganizationContactCommand` **không** bắt lỗi (lỗi thoát ra ngoài, không toast) | giữ nguyên, chỉ đổi sang `repository.addContact(organizationPartnerId:, personPartnerId:)`. 4-B G3 thêm toast lỗi | widget test: chọn 2 người → `addContact` gọi 2 lần đúng thứ tự, rồi `onReload`, toast "Thêm người liên hệ thành công" |
| H16 | `runPartnerDetailSoftDeleteFlow`: không đủ điều kiện → sheet chặn (có nút ngừng hoạt động khi `active` và có `deactivate` trong `availableActions`). Lỗi partner `NO_PERMISSION` → toast "Bạn không có quyền xóa hồ sơ."; mã khác → message thô hoặc "Không kiểm tra được điều kiện xóa."; lỗi khác → "Không kiểm tra được điều kiện xóa. Vui lòng thử lại." | **Đổi (Q2):** mọi lỗi → `partnerErrorMessage(e, fallback: 'Không kiểm tra được điều kiện xóa. Vui lòng thử lại.', noPermission: 'Bạn không có quyền xóa hồ sơ.')`. Phần sheet giữ | widget test: 3 ca (không đủ điều kiện → sheet; thiếu quyền → toast; lỗi khác → toast fallback) |
| H17 | `PartnerTransformCubit`: `PRIMARY_CONTACT_OF_ORGANIZATION` → câu "Khách hàng này đang là…" (4-B sửa). `DUPLICATE_WARNING` hoặc message chứa `DUPLICATE_WARNING` → trạng thái `duplicate` + `parseDuplicateFieldErrors(message)`. `NO_PERMISSION` / `STATE_CHANGED` → `blocked`. Mã khác → `_safeUserMessage(message)`. Lỗi khác có chữ `DUPLICATE_WARNING` → duplicate; còn lại → "Không thể chuyển đổi hồ sơ. Vui lòng thử lại." | `on AppException`: `DUPLICATE_WARNING` → `_emitDuplicate(e.serverMessage ?? '')`. Hai nhánh kiểm chữ `DUPLICATE_WARNING` trong chuỗi bỏ (mã đã nằm ở `code`). **Đổi (Q2):** mã khác → "Không thể chuyển đổi hồ sơ. Vui lòng thử lại." (xoá `_safeUserMessage`). `parseDuplicateFieldErrors` giữ nguyên (public, có test) | `partner_transform_cubit_test.dart`: thêm ca `DUPLICATE_WARNING` có `serverMessage` `[{"field":"tax_code"}]` → lỗi trường `taxCode`; ca mã lạ → câu chung |
| H18 | `SalesPartnerCustomerLookup`: `_resolve` (không active → "Khách hàng không còn hoạt động."; không có vai trò KH → "Đối tác không có vai trò khách hàng."; lỗi khác → "Không thể xác minh khách hàng. Vui lòng thử lại."). `_search` (`updatedWithinDays: 30` khi rỗng, limit 40, không bắt lỗi). `_checkDuplicate` (SĐT / MST chỉ chữ số, trả chi tiết của match đầu, không bắt lỗi). `_create` (vai trò `customer`, `OrganizationType.other`, `companyAddress` = địa chỉ cho tổ chức, `delivery.address` cho cá nhân; lỗi partner `NO_PERMISSION` / `DUPLICATE_WARNING` / khác theo `_mapBlocked`; lỗi khác → "Không thể kết nối để tạo khách hàng. Vui lòng thử lại."). Map VM | giữ nguyên, chỉ đổi lời gọi sang `di<PartnerRepository>()` và `on PartnerBlockedException` → `on AppException`. Rule SĐT sai (H3) → `VALIDATION_ERROR` → nhánh `_` của `_mapBlocked` → cùng câu như cũ | `sales_partner_customer_lookup_test.dart` hiện có (đổi cách dựng: đăng ký `FakePartnerRepository` vào GetIt). Bước 0 thêm: `_create` khi `NO_PERMISSION` → "Bạn chưa có quyền tạo khách hàng." |
| H19 | `PricingPickCustomerPage._load`: search (customer, `requireAnyRole`, active, limit 30). Lỗi → "Không tải được danh sách khách hàng." | giữ, đổi sang `GetIt.instance<PartnerRepository>().search(...)` | widget test mới ở bước 0: lời gọi đúng tham số; lỗi → câu trên |
| H20 | `FakePartnerModule` (804 dòng): 34 kịch bản `FakePartnerScenario`, dữ liệu mẫu, `_statusOverrides` / `_versionOverrides` | `apps/erp/test/features/partner/support/fake_partner_repository.dart`: `FakePartnerRepository extends PartnerRepository` (mẫu `FakeMemberRepository` ở `test/features/iam/support/fake_iam_backend.dart:1019`). Cùng enum `FakePartnerScenario`, cùng dữ liệu, cùng nhánh. `PartnerBlockedException(code, message: m)` → `AppException(code, serverMessage: m)` | mọi test đang dùng `FakePartnerModule` chạy lại xanh trên fake mới (danh sách mục 7.3) |
| H21 | `injection.dart`: `PartnerStartup.initialize` + `IPartnerModule`. `PartnerRepository` chỉ có `rpc`, `tenantId` | bỏ `PartnerStartup` và `IPartnerModule`. `PartnerRepository` thêm `actorId: () async => sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired))` (biến `sessionStore` đã có trong hàm) | `test/core/di/injection_test.dart`: `PartnerRepository` đăng ký, `IPartnerModule` **không** đăng ký |
| H22 | `app_router.dart` 9 route partner: truyền module + context; `/partner/new` đọc `extra as PartnerType?` (mặc định person); `/transform` không có `extra` → `go('/partner/:id')`; `/contacts/new` và `/contacts/:contactId/edit` đọc `extra as PartnerContactDto?`; `/contacts/select` đọc `extra as List<String>?`; detail đọc `?created=1`, `?transformed=1` | giữ nguyên mọi nhánh, chỉ đổi tham số trang thành `repository: getIt<PartnerRepository>()`, import kiểu từ `features/partner/data/models/` | test router hiện có của partner (`partner_detail_e2e_test`, `partner_update_e2e_test`, `partner_status_lifecycle_e2e_test`, `partner_contacts_page_e2e_test`) chạy lại xanh |

## 6. Các bước

Trước khi sửa mỗi symbol: `gitnexus impact({target: "<symbol>", direction: "upstream"})`. Ghi blast radius vào mục Kết quả. Rủi ro HIGH / CRITICAL thì dừng, ghi lại, báo trong mục Kết quả trước khi làm tiếp.

### Bước 0: test giữ hành vi trên code cũ (chưa sửa gì trong `lib/`)

1. `test/features/partner/data/partner_rpc_parity_test.dart`: nhóm `old` (H1, H2).
   - Import mapper cũ: `package:c45_partner_infrastructure/src/data_access/partner_rpc_mapper.dart`, `…/partner_read_rpc_mapper.dart`, kèm `// ignore: implementation_imports`.
   - Bộ input mẫu, mỗi RPC một ca:
     - cá nhân đủ trường kèm invoice + delivery;
     - tổ chức `businessHousehold` kèm người liên hệ chính;
     - search có `requireBothRoles`; search chỉ có `requireAnyRole`; search có `role`;
     - addContact chọn có sẵn; addContact tạo mới;
     - updateContact có `personProfile`;
     - deactivate có `reason`.
   - Ghi **map mong đợi viết tay** (literal) cho từng ca.
   - JSON kết quả mẫu cho detail (có `contact_role: 'primary'`, `invoice: {}`, `organization_type: 'businessHousehold'`), search (thiếu `total`), duplicate (`matched_field: 'tax_code'`, `'name'`).
2. Test H7–H19 như cột cuối mục 5, viết trên cubit / widget **cũ** với `FakePartnerModule` (hoặc fake ném `PartnerBlockedException`). Chạy xanh.
3. Ghi tên từng test vào Kết quả, kèm câu lệnh đã chạy.

### Bước 1: model + rule + MST

1. Tạo các tệp mục 4.1, `partner_error_codes.dart`, `logic/partner_permissions.dart`, `logic/partner_rules.dart`, `logic/partner_error_messages.dart`.
2. `core/validation/tax_code.dart`: thêm `compactTaxCodeInput` (mục 4.6); sửa `PartnerCreateFormValidator` như mục 4.6.
   - Test: `test/core/validation/tax_code_test.dart` thêm 3 ca:
     - `compactTaxCodeInput('0101234567 001')` → `'0101234567-001'` (13 số sau khi bỏ khoảng trắng);
     - `compactTaxCodeInput(' 0101 2345 67 ')` → `'0101234567'`;
     - `compactTaxCodeInput('')` → `''`.
   - Ca IAM hiện có (`normalizeTaxCode`, `isValidTaxCode`) không đổi.
   - `partner_create_form_validator_test.dart` hiện có phải còn xanh.
3. `partner_rules_test.dart` nhóm `new` (H3).

### Bước 2: repository

1. Viết `PartnerRepository` (mục 4.2).
2. Parity test nhóm `new`: `_Rpc extends SupabaseRpc` ghi lời gọi (mẫu `test/features/iam/data/audit_log_repository_test.dart`), so đúng map của nhóm `old`.
3. Test H4, H5, H6.

### Bước 3: fake

Tạo `test/features/partner/support/fake_partner_repository.dart` (H20):

- Override **mọi** method public của `PartnerRepository`.
- Thêm `final calls = <String>[]` ghi tên method để test đếm lời gọi.
- `super(rpc: _unusedRpc, tenantId: () async => 'tenant-1', actorId: () async => 'user-1')`.

### Bước 4: cubit + widget + trang

1. `git mv` 16 tệp `presentation/bloc/` → `logic/`; sửa import trong toàn bộ `lib/` và `test/` (`presentation.dart` export đường mới).
2. Đổi cubit theo mục 4.4 và cột 2 của H7–H17.
3. Trang / widget nhận `PartnerRepository repository` thay `partnerModule` + `executionContext`:
   - `partner_create_page.dart` (cả `PartnerCreatePage` và `.edit`), `partner_detail_page.dart`, `partner_contacts_page.dart`, `partner_contact_form_page.dart`, `partner_contact_select_page.dart`, `partner_transform_page.dart`;
   - widget `partner_contact_select_list.dart`, `partner_detail_add_contact_flow.dart`, `partner_detail_soft_delete_flow.dart`;
   - `partner_list_page.dart` dùng `GetIt.instance<PartnerRepository>()`; `PartnerPermissions` đổi import sang `logic/partner_permissions.dart`.
4. Mọi widget đang import `c45_partner_domain` / `c45_partner_application` chỉ để lấy kiểu đổi import sang `data/models/…` / `logic/…`. Danh sách: `git grep -l "package:c45_partner" -- apps/erp/lib/features/partner`; đo 2026-11-01 khoảng 45 tệp. Ghi số tệp thực tế vào Kết quả.
5. `partner_transform_blocked_state.dart`, `partner_operation_feedback_state.dart`: `PartnerBlockedCodes` → `PartnerErrorCodes`, không đổi gì khác.

### Bước 5: sales + pricing + router + DI

- `sales_partner_customer_lookup.dart` (H18), `pricing_pick_customer_page.dart` (H19).
- `sales_external_lookups.dart`: sửa hai dòng chú thích: `[IPartnerModule]` → `PartnerRepository`; `[GetPartnerDetailQuery]` → `PartnerRepository.getDetail`.
- `app_router.dart` (H22), `injection.dart` (H21).
- **Không** bỏ `c45_partner_*` khỏi `apps/erp/pubspec.yaml`: test parity nhóm `old` còn cần, 4-C bỏ.

### Bước 6: test chuyển chỗ + example

1. `test/features/partner/presentation_module/bloc/*` → `test/features/partner/logic/`; `presentation_module/support/partner_action_log_diff_test.dart` → `test/features/partner/logic/`.
2. Mọi test dùng `FakePartnerModule` / `FakePartnerScenario` đổi sang `FakePartnerRepository`: 16 tệp ở mục 7.3, cộng 4 tệp sales (`sales_partner_customer_lookup_test`, `sales_checkout_page_test`, `sales_draft_backend_test`, `sales_flow_pages_test`).
   - Chỗ nào đăng ký `getIt.registerSingleton<IPartnerModule>(…)` → `registerSingleton<PartnerRepository>(FakePartnerRepository(…))`. Có `IExecutionContext` chỉ để partner dùng thì bỏ.
3. Xoá `apps/erp/example/lib/partner/` và mục "Partner" trong `apps/erp/example/lib/main.dart` (Q5). Giữ `example/pubspec.yaml` (4-C sửa).

### Bước 7: kiểm (mục 7), ghi Kết quả, `detect_changes()`

## 7. Kiểm tra

### 7.1 Tự động

- [ ] `git grep -n "package:c45_partner" -- apps/erp/lib` **rỗng**.
- [ ] `git grep -nE "IPartnerModule|PartnerBlockedException|PartnerBlockedCodes|FakePartnerModule|executeQueryAsync|executeCommandAsync" -- apps/erp/lib/features/partner apps/erp/lib/features/sales/presentation/lookups apps/erp/lib/features/pricing/presentation/pages/pricing_pick_customer_page.dart apps/erp/lib/core` **rỗng**.
- [ ] `git grep -n "FakePartnerModule\|c45_partner_application/testing" -- apps/erp/test` **rỗng**. Chỉ `partner_rpc_parity_test.dart` và `partner_rules_test.dart` (nhóm `old`) còn import `c45_partner_*`.
- [ ] `ls apps/erp/lib/features/partner/presentation/bloc` → không tồn tại.
- [ ] `cd apps/erp && dart analyze lib test`: không error / warning **mới** so với trước khi làm (ghi số trước / sau). Đường dẫn có dấu tiếng Việt làm `flutter analyze` (LSP) vỡ, nên dùng `dart analyze`.
- [ ] `cd apps/erp && flutter test`: số pass ≥ trước + test mới; danh sách fail **trùng** `docs/refactor/TEST-BASELINE.md` + fail có sẵn ghi ở W-2 (61). Ghi tên fail mới nếu có.
- [ ] `flutter test test/features/partner test/features/sales test/core`: 0 fail mới.
- [ ] Mọi test bước 0 còn xanh (kể cả nhóm `old`).

### 7.2 Kiểm tay (iPhone simulator + Chrome, Dev)

- [ ] Danh sách: tìm, lọc, sắp xếp, cuộn trang 2.
- [ ] Tạo cá nhân; tạo tổ chức có người liên hệ chính; trùng SĐT → sheet "Trùng khớp hoàn toàn".
- [ ] Sửa hồ sơ → lịch sử thao tác có dòng mới.
- [ ] Người liên hệ: thêm mới, chọn có sẵn, đặt chính, gỡ.
- [ ] Chuyển cá nhân thành tổ chức.
- [ ] Ngừng hoạt động / kích hoạt lại / xoá.
- [ ] Bán hàng: chọn khách, tạo nhanh khách. Pricing: chọn khách.

### 7.3 Test đang dùng `FakePartnerModule` (đổi ở bước 6)

`partner_contacts_page_e2e_test`, `partner_create_page_test`, `partner_detail_e2e_test`, `partner_list_page_test`, `partner_status_lifecycle_e2e_test`, `partner_update_e2e_test` (thư mục `presentation/pages`); `partner_contact_form_cubit_test`, `partner_contacts_cubit_test`, `partner_create_cubit_test`, `partner_delivery_cubit_test`, `partner_list_cubit_test`, `partner_status_cubit_test`, `partner_transform_cubit_test` (`presentation_module/bloc`); `partner_create_form_test`, `partner_delivery_section_test` (`presentation_module/widgets`); `test/core/di/injection_test.dart`.

## 8. Rủi ro / lưu ý

- **Chép sai khoá JSON** là rủi ro lớn nhất. Đây là lý do test parity nhóm `old` / `new` dùng **chung** map mong đợi; không sửa map cho khớp code mới.
- `get_partner_detail` trả jsonb chứ không phải table. Đừng dùng `rows()` cho nó.
- Đổi `PersonTitle` (bỏ `ValueObject`): chỗ nào so `==` hai `PersonTitle` vẫn đúng nhờ `==` theo `value`.
- `PartnerType` cũ là enum của domain, nhiều widget `switch` trên nó. Enum mới phải **cùng thứ tự giá trị** (`index` được dùng ở `toggleRole` để sắp `roles`).
- Sales: `_digitsOnly(taxCode)` bỏ cả dấu gạch của MST chi nhánh. Đây là lỗi có sẵn của Theme 5, **không** sửa ở đây; ghi cho Theme 5 (8.1).
- `injection.dart`: `PartnerRepository` đăng ký **sau** khi tạo `sessionStore`; vị trí hiện tại (dòng ~106) đã đúng.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay, không dồn cuối. Mẫu cho mỗi bước:
> - Trạng thái: ✅ / 🔄 dở (ghi tới đâu) / ⏭ (lý do)
> - Tệp:dòng đã đổi
> - Lệch so với plan + lý do
> - Test thêm / sửa (tên test); test đổi kỳ vọng do Q2 / Q3 (dòng H nào)
> - Impact (`gitnexus impact`): symbol, số caller, mức rủi ro
> - Ghi chú cho review
>
> Bước cuối: lệnh đã chạy, số pass / fail, tên test fail đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.

### Tóm tắt (2026-11-01)

- Toàn bộ 7 bước đã làm; `apps/erp/lib` không còn `package:c45_partner_*`.
- `dart analyze lib test`: **249 → 249** vấn đề (không error; diff theo nội dung không có mục mới).
- `flutter test` (cả `apps/erp`): **1555 đạt / 61 lỗi → 1676 đạt / 61 lỗi**. Tập 61 tên lỗi **trùng khít** lúc trước khi làm (so bằng reporter json, 0 lỗi mới, 0 lỗi được sửa). Không có lỗi nào thuộc partner / sales / partner-lookup.
- `detect_changes(scope: all)`: 112 tệp, 66 symbol, **0 execution flow bị ảnh hưởng**, risk low. Symbol đổi đúng dự kiến (`PartnerRepository`, các trang partner, `appRouter`). Index GitNexus cũ (commit `e73727491`), nên hàm top-level (`normalizeTaxCode`, `isValidTaxCode`) báo UNKNOWN.
- Chưa `git commit` (người dùng chưa yêu cầu).

### Bước 0 — test giữ hành vi trên code cũ ✅

- Impact (`gitnexus impact`, upstream): `PartnerRepository` MEDIUM (37, direct 5); `PartnerCreateCubit` MEDIUM (34, direct 11); `PartnerCreateFormValidator` MEDIUM (34, direct 4); `PartnerCreateDraftMapper` MEDIUM (31); `PartnerBlockedCodes` MEDIUM (6); các cubit khác, `PartnerContactSelectList`, 2 flow, `SalesPartnerCustomerLookup`, `PricingPickCustomerPage` LOW. **Không có HIGH / CRITICAL.** 0 execution flow ảnh hưởng (trừ 5 process nhẹ của 2 flow widget).
- Chạy trên code cũ, xanh:
  - `test/features/partner/data/partner_rpc_parity_test.dart` nhóm `old` — 22 ca (H1: 15 ca tham số, H2: 7 ca đọc kết quả).
  - `test/features/partner/logic/partner_rules_test.dart` nhóm `old` — 12 ca (H3).
  - `partner_error_mapping_test.dart` (30 ca; H7, H8, H9, H11, H12, H13, H17), `partner_flows_error_test.dart` (10 ca; H14, H15, H16), `sales_partner_customer_lookup_test.dart` +8 ca (H18), `pricing_pick_customer_page_test.dart` 2 ca (H19).
- Lệch plan:
  - Các ca H7–H13, H17 gom vào **một tệp** `partner_error_mapping_test.dart` thay vì thêm vào từng tệp cubit.
  - **H10** không thêm ca mới: `partner_create_cubit_test` ("organization submit checks primary contact phone for duplicates") đã khẳng định 2 lời gọi kiểm trùng, lời gọi 2 chỉ có phone, name null.
  - **H18** `_create` + `NO_PERMISSION` đã có sẵn từ trước; thêm các ca còn thiếu.
  - Helper tạm `ScriptedPartnerModule` chỉ sống ở bước 0, bị thay bằng `ScriptedPartnerRepository` ở bước 4.
- Lệnh: `flutter test test/features/partner test/features/sales test/features/pricing test/core` → 1039 đạt, 11 lỗi, cả 11 nằm trong 61 lỗi có sẵn.

### Bước 1 — model + rule + MST ✅

- Tệp mới (`apps/erp/lib/features/partner/`): `data/models/{partner_enums,person_title,partner_inputs,partner_detail,partner_list_item,partner_duplicate_match,partner_write_results,partner_error_codes}.dart`; `logic/{partner_permissions,partner_rules,partner_error_messages}.dart`.
- Lệch plan: thêm **barrel** `data/models/partner_models.dart` (export mọi model, kể cả `partner_action_log.dart`) để đổi import ~60 tệp bằng một dòng. Thêm hai helper `toNestedJson()` (`InvoiceProfileInput`, `DeliveryAddressInput`) để `toRpcJson()` không lặp.
- `core/validation/tax_code.dart:14` thêm `compactTaxCodeInput`; `PartnerCreateFormValidator.normalizeTaxCode` / `isValidTaxCode` gọi nó (import core `as core`), xoá `_taxCodePattern`. IAM không đổi.
- Test: `tax_code_test.dart` +1 test (3 khẳng định đúng như plan); `partner_rules_test.dart` nhóm `new` — 12 ca.

### Bước 2 — repository ✅

- `data/partner_repository.dart`: viết lại, thêm `actorId`, 14 method theo mục 4.2. Rule gọi trước `create` / `update` / `transformToOrganization`, ném `AppException(VALIDATION_ERROR, serverMessage: câu rule)`, không gọi RPC.
- Test: `partner_rpc_parity_test.dart` nhóm `new` (14 ca, cùng map hằng với nhóm `old`, tổng 36 ca); `partner_repository_test.dart` +11 ca (H3, H4, H5, H6, NOT_FOUND). Helper `test/features/partner/support/recording_rpc.dart` (mẫu `audit_log_repository_test`, đổi lỗi qua `AppException.from` như `SupabaseRpc` thật).

### Bước 3 — fake ✅

- `test/features/partner/support/fake_partner_repository.dart`: `FakePartnerRepository extends PartnerRepository`, override mọi method public, `calls` ghi tên method, cùng enum `FakePartnerScenario` và dữ liệu như `FakePartnerModule`. `PartnerBlockedException(code, message: m)` → `AppException(code, serverMessage: m)`.
- Thêm `support/scripted_partner_repository.dart` (`ScriptedPartnerRepository`, `RepoCall`): ghi lời gọi + chạy kịch bản của test (ném lỗi cụ thể / chờ `Completer`). Ngoài plan, dùng ở các test cần ném lỗi hoặc kiểm đối số.
- Các kịch bản `history*` giữ trong enum nhưng không còn method tương ứng (app không dùng `get_partner_history`).

### Bước 4 — cubit, widget, trang ✅

- `git mv` 16 tệp `presentation/bloc/*` → `logic/` (thư mục `bloc` đã xoá). `presentation.dart` export đường mới. 7 cubit nhận `repository`.
- 59 tệp `lib` đổi import sang `partner_models.dart`; trang / widget nhận `PartnerRepository repository`: `partner_{create,detail,contacts,contact_form,contact_select,transform}_page.dart`, `partner_contact_select_list.dart`, `partner_detail_add_contact_flow.dart`, `partner_detail_soft_delete_flow.dart`; `partner_list_page.dart` dùng `GetIt.instance<PartnerRepository>()`.
- Hành vi:
  - **Q2 đã đổi, kỳ vọng test đổi cùng lúc:** H9 (mã khác → `partnerErrorMessage`; `INVALID_STATUS` → "Trạng thái hồ sơ không cho phép thao tác này."; hết "Không thể lưu KH & NCC." và message thô), H11 (mã lạ → câu của thao tác), H12 (4 câu theo mục 4.5), H13 (tải lỗi + `actionError`), H14 (bỏ tiền tố "Lỗi: "), H16 (mọi lỗi qua `partnerErrorMessage`), H17 (bỏ `_safeUserMessage`).
  - **Q3:** bỏ `get_partner_detail` trước ghi và kiểm quyền client; test H4/H5 xác nhận.
  - **H8:** `isNotFound` / `isNoPermission` theo `AppException.code`; `PartnerDetailError.message` vẫn là `e.toString()` như cũ.
  - `PartnerListCubit`: mất một dòng `if (isClosed) return;` sau `requireTenantId()` (không còn bước chờ đó); vẫn còn kiểm `isClosed` sau lời gọi search (test "ignores a search response…" xanh).
  - `PartnerTransformCubit`: bỏ cả hai nhánh dò chữ `DUPLICATE_WARNING` trong chuỗi; `DUPLICATE_WARNING` lấy từ `code`, JSON trùng từ `serverMessage`.
- Số tệp `lib/features/partner` từng import `c45_partner_*`: **59** tệp toàn `lib` (plan ước ~45 chỉ tính riêng partner).

### Bước 5 — sales, pricing, router, DI ✅

- `sales_partner_customer_lookup.dart` (H18): `di<PartnerRepository>()`, `on AppException`; `pricing_pick_customer_page.dart` (H19); `sales_external_lookups.dart` đổi 2 dòng chú thích.
- `app_router.dart`: **8** route partner đổi sang `repository: getIt<PartnerRepository>()` (route thứ 9, lịch sử thay đổi, đã dùng repository từ 1-B). Mọi nhánh `extra` / query giữ nguyên.
- `core/di/injection.dart`: bỏ `PartnerStartup` + `IPartnerModule`; `PartnerRepository` thêm `actorId` (ném `AppErrorCode.authRequired` nếu chưa có `userId`). `PartnerStartup` không đăng ký bus / event handler nào nên bỏ không mất hành vi.
- `pubspec.yaml` giữ nguyên `c45_partner_*` (4-C bỏ).

### Bước 6 — test chuyển chỗ + example ✅

- `test/features/partner/presentation_module/bloc/*` và `support/partner_action_log_diff_test.dart` → `test/features/partner/logic/`.
- Đổi sang `FakePartnerRepository` / `ScriptedPartnerRepository`: 16 tệp ở mục 7.3 + 4 tệp sales (`sales_partner_customer_lookup_test`, `sales_checkout_page_test`, `sales_draft_backend_test`, `sales_flow_pages_test`) + `partner_error_mapping_test`, `partner_flows_error_test`, `pricing_pick_customer_page_test`.
- Xoá `apps/erp/example/lib/partner/` và mục "Partner" trong `example/lib/main.dart` (Q5). `example/pubspec.yaml` giữ nguyên.

### Bước 7 — kiểm ✅

- `git grep "package:c45_partner" apps/erp/lib` → rỗng.
- Grep dòng 2 mục 7.1 (`IPartnerModule|PartnerBlocked*|FakePartnerModule|executeQueryAsync|executeCommandAsync`) → **hết ở mọi tệp partner**. Còn khớp ở `sales_catalog_product_lookup.dart` và `sales_pricing_lookup.dart` (module Catalog / Pricing, thuộc Theme 2 / 5, không phải partner): plan quét cả thư mục `lookups` nên dính; không sửa.
- `grep FakePartnerModule|c45_partner_application/testing` trong `apps/erp/test` → rỗng.
- **Lệch:** `test/core/di/injection_test.dart` vẫn `import c45_partner_application` để khẳng định `IPartnerModule` **không đăng ký** (H21). Nghĩa là ba tệp test còn import `c45_partner_*`: `partner_rpc_parity_test.dart`, `partner_rules_test.dart`, `injection_test.dart`. 4-C bỏ ba chỗ này cùng pubspec.
- 7.2 (kiểm tay iPhone / Chrome trên Dev): **chưa làm**, cần người dùng hoặc review chạy.
- Ghi cho Theme 5: `_digitsOnly(taxCode)` trong sales lookup vẫn bỏ dấu gạch MST chi nhánh (đúng plan mục 8, không sửa).

## 10. Review

### R1 — 2026-11-01 — ✅ đạt (0 P1, 0 P2, 3 P3)

**Kết luận: ĐẠT. Phiên code không phải sửa gì.**

| Hạng mục | Kết quả |
|---|---|
| Code 4-A | Đúng plan, giữ hành vi cũ, đổi đúng các chỗ Q2 / Q3 |
| Test | Xanh; 61 lỗi đều là lỗi có sẵn (baseline) |
| Analyze | Không có lỗi / cảnh báo mới |
| **Bắt buộc sửa** | **Không có** |
| Tuỳ chọn sửa | P3-3 (thứ tự import, 1 dòng) |
| Chỉ ghi nhận, không sửa | P3-1, P3-2 |
| Còn lại để đóng plan | (1) Kiểm tay 7.2: người dùng. (2) Trước khi commit: `node .gitnexus/run.cjs analyze` rồi `detect_changes()` |

Chi tiết bên dưới.

Cây làm việc lúc review đã gồm cả 4-B, 4-W, 4-C (chưa commit, tệp chồng nhau). Review chỉ xét phần của 4-A; router, bố cục, chữ "Anh" → "Bạn", `roleAsc`, `selectTab`, toast thêm người liên hệ thuộc 4-B / 4-W.

**Đã chạy (phiên review):**
- `flutter test` toàn bộ `apps/erp`: **1699 đạt / 61 lỗi**. Cả 61 tên khớp `TEST-BASELINE.md` + W-2. Không lỗi nào thuộc partner / sales.
- `flutter test test/features/partner test/features/sales test/core/di test/core/validation` + `pricing_pick_customer_page_test`: 953 đạt, 0 lỗi.
- `dart analyze` (`lib/features/partner`, `lib/core`, sales lookups, pricing, `test/features/partner`): 0 error / warning, chỉ `deprecated_member_use` có sẵn.
- Grep 7.1: `package:c45_partner` trong `apps/erp/lib` và `apps/erp/test` rỗng; `IPartnerModule|PartnerBlocked*|FakePartnerModule` chỉ còn trong 2 chú thích; `presentation/bloc` không còn.

**Đối chiếu tay với module cũ** (`git show HEAD:modules/partner/...`), vì 4-C đã xoá nhóm `old`:
- H1: tham số 14 RPC trong `PartnerRepository` khớp `PartnerRpcMapper` / `PartnerReadRpcMapper` (tên khoá, `p_role` both / any, `toRpcJson` lồng + phẳng, `organization_type` snake_case).
- H2: `fromJson` khớp `mapDetailResult`, `_contactRole`, `_invoiceDto` / `_deliveryDto`, `_organizationType`, `_matchField`, `_deriveMatchLevel`, `mapSearchResult`. Thứ tự giá trị 7 enum giữ nguyên.
- H3: `PartnerRules` khớp `PhoneNumber` / `EmailAddress` / `TaxCode` / 4 rule (trim, 8–15 chữ số, email rỗng bỏ qua, MST chỉ khoảng trắng sai).
- H6: `_raise_partner_error` luôn ra `CODE: …`. `DUPLICATE_WARNING` luôn kèm mảng có `field` (`_guard_duplicates`), nên bỏ nhánh dò chuỗi ở `PartnerTransformCubit` không mất trường lỗi.
- H8–H17: các câu giữ nguyên văn, chỉ đổi đúng các chỗ Q2. `PartnerDetailError.message` vẫn là `e.toString()` nhưng trang không hiện nó (chỉ dùng cờ), nên không trái Q2.
- H21: `actorId` lấy `sessionStore.userId`, cùng nguồn với `requireUserId` cũ.

**Đạt:** mục tiêu 1, Q1–Q5, mục 4.1–4.6, H1–H22, bước 0–7. Lệch plan đã ghi ở mục 9 hợp lý: barrel `partner_models.dart`, `toNestedJson`, `ScriptedPartnerRepository`, gom test lỗi vào `partner_error_mapping_test`.

#### P3 (không chặn)

1. **[Không sửa — chỉ ghi nhận] Mục 9 đã cũ sau 4-C.** Dòng "Lệch: `injection_test.dart` vẫn import `c45_partner_application`" không còn đúng: grep `apps/erp/test` giờ rỗng. Nhóm `old` của `partner_rpc_parity_test` / `partner_rules_test` đã bị 4-C xoá, nên ô 7.1 "Mọi test bước 0 còn xanh (kể cả nhóm `old`)" không kiểm lại được nữa. Map viết tay còn giữ, và review đã đối chiếu tay (ở trên). Không cần sửa code.
2. **[Không sửa — chỉ ghi nhận]** Thay đổi nhỏ chưa ghi ở bảng mục 5: `SalesPartnerCustomerLookup._create` trước lấy tenant / actor **ngoài** `try` (thiếu phiên thì lỗi thoát ra ngoài), nay nằm trong repository nên rơi vào câu "Không thể kết nối để tạo khách hàng. Vui lòng thử lại.". Tốt hơn trước, giữ nguyên.
3. **[Tuỳ chọn sửa]** `logic/partner_contacts_cubit.dart`: `import 'package:erp/core/errors/app_exception.dart'` đặt sau các import tương đối. Thứ tự import, tuỳ ý sửa.

**Còn trước khi đóng:**
- Kiểm tay 7.2 (iPhone + Chrome, Dev): người dùng.
- Trước khi commit: index GitNexus đang ở `e73727491`. Chạy `node .gitnexus/run.cjs analyze` rồi `detect_changes()` lại (CLAUDE.md).
