# Changelog

All notable changes to the **ERP** Flutter app (`apps/erp`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with Flutter build numbers (`MAJOR.MINOR.PATCH+BUILD`).

Ship unit: this app only. Internal modules are not versioned separately — note them under
**Internal** when they affect this app.

## [Unreleased]

### Added

### Changed

- Vào app: khi tổ chức hợp lệ, chờ thiết lập cửa hàng và kho mặc định trước khi vào trang chủ. Nếu lỗi, có thể thử lại hoặc chọn tổ chức khác.

### Fixed

### Internal

- Inventory: RPC cặp cửa hàng/kho mặc định. Draft `inventory_default_pair.sql`.

## [1.7.5+42] - 2026-10-02

### Changed

- Readiness: card điều kiện bắt buộc / hồ sơ pháp lý không còn bấm để điều hướng (chỉ còn CTA dưới cùng).
- Hồ sơ pháp lý: MST chấp nhận 10–13 chữ số (tự bỏ dấu `-`).
- Readiness: phân biệt blocker “Đang chờ chủ sở hữu chấp nhận lời mời” và “Lời mời hết hạn” (không nút sửa trên readiness).

### Fixed

- ERP: khi tài khoản bị tạm ngừng (đang dùng hoặc mở lại với phiên cũ) → toast đúng lý do + đăng xuất về `/login`; màn chặn dự phòng «Tài khoản bị tạm ngừng».
- Tạo đơn hàng: empty state «Chưa có sản phẩm» không còn overflow khi mở ghi chú đơn (bàn phím).
- Switch tenant: lỗi thiếu active store (`CONTEXT_INVALID`) không còn bị gói thành `SYSTEM_ERROR`.
- Đăng nhập: tài khoản bị tạm ngừng bị chặn với thông báo rõ ràng.
- ERP tự về màn chặn khi tổ chức tạm ngừng/đã đóng (kèm thông báo đúng lý do).
- ERP: mọi tab hiện màn chặn khi tổ chức tạm ngừng/đã đóng; header xoá tên org; giữ mã `TENANT_CLOSED` cho copy «đã đóng».
- ERP: tab Khác vẫn mở khi org bị chặn (đăng xuất / tài khoản cá nhân); badge «Chủ sở hữu» trên Tài khoản của tôi.
- ERP: từ trang con khi org bị tạm ngừng/đóng → toast + về dashboard (sửa `listenWhen` sau bước `loading`).
- ERP: tab Khác khi org bị chặn không còn gọi RPC readiness/session (hết log `SEVERE`); mục «Người dùng & vai trò» vẫn hiện nhưng vô hiệu.
- ERP: danh sách thành viên không còn badge «Chủ sở hữu» cạnh tên (badge chỉ còn trên Tài khoản của tôi).

### Internal

- IAM: `get_tenant_readiness` thêm `OWNER_ACCEPTANCE_PENDING` / `OWNER_INVITATION_EXPIRED` khi provisioning chưa có owner — cần `supabase db reset`.
- IAM: chặn `suspended`/`closed` ở `has_permission` / `get_session_context` / `can_access_store`; vá quyền 2 RPC tồn kho — cần `supabase db reset`.
- IAM: dọn upgrade guard legacy password reset; domain model ghi rõ lưu `code_hash`.
- IAM: `audit_logs` bỏ cột `created_at` (chỉ còn `occurred_at`) — cần `supabase db reset`.
- IAM: gộp 8 bảng `*_operations` thành `iam.idempotency_records`; xoá get/retry onboarding operation — cần `supabase db reset`.
- IAM: `tenant_legal_profiles` CHECK MST 10–13; onboarding `p_org_legal_entity_type` — cần `supabase db reset`.
- IAM: `iam.tenants` thu gọn cột (`display_name` + shared status); RPC `close_platform_tenant` — cần `supabase db reset`.
- IAM: `_ensure_membership_default_store_scope` bỏ qua UUID pending chưa có trong `auth.users` (merge vào `20260916001`).
- IAM: `create_tenant_invitation` không còn chặn invite với role `owner` / `store_owner` (chỉ còn check role `active`).
- IAM draft SQL: ensure default store + `membership_store_scopes` trên onboarding / invite / accept / activate; backfill dữ liệu legacy.

## [1.7.4+41] - 2026-09-14

### Fixed

- Multi-tenant session: không còn `CONTEXT_INVALID` “Exactly one tenant context” khi user có ≥2 membership; `IamActiveStoreContext` không gọi RPC khi chưa chọn tenant.

### Internal

- IAM: tách `SignInTenantUser` / `SignInPlatformAdmin`; bỏ `IamSessionCoordinator`; restore persisted auth thuộc app DI.
- Draft SQL `019_iam_get_session_context_multi_tenant` (filter active; multi-tenant → null; `bootstrap_owner` theo `p_tenant_id`) — cần apply local.

## [1.7.3+40] - 2026-09-14

### Added

- SG-05: `SalesPaymentQrCard` nhận `qrImage` (`ImageProvider`) hiển thị ảnh QR vuông, cạnh bằng chiều cao cột thông tin; null → placeholder icon.
- SG-02: bấm vùng tên/giá trên dòng soạn đơn để chọn lại đơn vị bán (giữ SL; trùng unit thì merge dòng).

### Fixed

- Login tenant: dùng `SignInTenantUserCommand` (auth-only) — không gọi `get_session_context` khi multi-tenant; tenant/store qua `TenantContextCubit.bootstrap`.
- SG-02: unfocus ô tìm SP trong lúc fetch đang treo thì hủy kết quả inflight — không mở menu pick sản phẩm sau khi future hoàn tất.
- SG-02: chặn bấm nhanh mở trùng sheet chọn đơn vị bán.
- SG-02: tóm tắt thanh toán — tổng tiền hàng = Σ max(niêm yết, tiền bán); phần giá riêng thấp hơn list vào “Giảm giá”; thành tiền = tổng − giảm.
- SG-02: `SalesSpecialPriceBanner` — dải góc kiểu Banner (không shadow) gắn trên `SalesOrderLineRow`; thumbnail không còn sở hữu badge.

### Changed

- Catalog: migrate chip/badge/empty/field sang API design system mới (`tone`, `VBadgeVariant`, `VEmptyHeader`, `VField` + `VTextArea`).
- Catalog list: chỉ bọc `VSkeletonScope` khi load-more (tránh `pumpAndSettle` treo trên danh sách đã load).
- Catalog empty: tách `ProductCatalogEmptyState`; CTA tertiary, nền `surface`, không stretch full viewport.
- Catalog list: skeleton tile rút còn một `VSkeleton` (cùng pattern Partner).
- Catalog list: thêm `ProductCatalogErrorState` (`VEmptyState` danger + Thử lại).
- Catalog list: thêm `ProductCatalogErrorState` (`VEmptyState` danger + Thử lại).
- Pricing / Partner: migrate `VBanner` — bỏ `icon` override; dùng `description` thay `message` nơi đã đụng.

### Fixed

### Internal

## [1.7.3+39] - 2026-09-12

### Changed

- Partner: migrate chip/badge/empty/tabs/field sang API design system mới (`tone`, `VEmptyHeader`, `VTabsList`, `VField` + `VTextArea`).
- Partner list: tile dùng `VCard` + `VBadge` thay container/`_StatusBadge` tùy chỉnh; skeleton rút còn một `VSkeleton`.
- Lời mời: filter status dùng nhãn "Hết hạn"; cải thiện sheet filter / member tab body.

- IAM ERP: migrate badge/chip sang `VComponentTone`; form field sang `VField` composition; tách `AdministrativeUnitsFormSection`.

- Profile / onboarding: validate SĐT qua `VPhoneValidator` + `VPhoneField` (thay logic đếm chữ số thủ công).

- SG-08: chi tiết thanh toán dùng chữ "Hoàn một phần" và "Đã hoàn" như danh sách; khối hiện tại cộng mọi khoản đã thu kể cả thu thêm, không trừ hoàn; dòng giao dịch gắn "Thu tiền" hoặc "Hoàn tiền".
- US-06 theo dõi integration deferred; ERP không còn load/retry impact status
- Gỡ chỉnh ghi chú đơn hàng sau bán (SG-09 / EP-04).
- SG-05 / SG-06: tách `SalesLabelHighlightRow` (label + value string); `SalesAmountHighlightRow` chỉ format minor rồi ủy quyền render.
- SG-08: tab Đơn gốc / Sau đổi/trả cố định ngoài scroll; dùng compound `VTabs` + `VTabsList` + `VTabsTrigger`.
- SG-03: sheet chọn đơn vị bán dùng radio + Hủy/Xác nhận, mặc định chọn đơn vị cơ sở.
- SG-02: tóm tắt thanh toán (tổng tiền hàng / giảm giá / thành tiền) dùng số pricing preview trả về theo từng dòng thay vì suy diễn giảm giá từ chênh lệch giá ở widget.
- Design system: card border đậm hơn (`borderStrong`); input / select / combobox / nút secondary outline nhẹ hơn (`borderDefault`).
- Design system: text chính light dùng `neutral900` thay `primary900`.
- Design system: `VCard` hỗ trợ `enabled` (disabled → border nhẹ hơn, không tap).
- Design system: `VSearchBar` cao/radius khớp field; variant filled luôn có viền (`borderDefault` / focus `borderStrong`).
- Design system: `VDatePicker` icon lịch mặc định bên trái (`iconPosition`); dùng `right` nếu cần layout cũ.
- Design system: badge trạng thái `draft` / `cancelled` chữ đậm hơn (`textPrimary`), `locked` đổi nền sang `surfaceAlt`.
- Design system: filter chip đổi sang một kiểu soft theo tone — chip đang chọn dùng màu brand nhạt (`surfaceBrand` + `textBrand`) thay vì fill xanh lá chữ trắng; chip thường nền `surfaceAlt` + viền `borderStrong`.
- Design system: chip có nút xóa thấp lại, không còn cao hơn một dòng chữ.
- Lời mời tổ chức: banner sau khi tiếp nhận nêu rõ tên tổ chức vừa tham gia (`Đã tham gia tổ chức "X" thành công`), áp dụng cho cả luồng tài khoản mới lẫn tài khoản đã có.

### Fixed
- SG-01: `SalesDraftListCard` compose `VSwipeReveal` trực tiếp; bỏ `VSwipeActionRecord` khỏi design system.

- Login: sai email/mật khẩu (`invalidCredentials`) hiện trên `VFieldError` của field email; các lỗi login khác vẫn dùng toast.
- Partner / lời mời: dùng `VPhoneField` + `VPhoneValidator` cho SĐT (định dạng VN, từ chối ký tự không hợp lệ).
- Dashboard: lời chào theo buổi không kèm tên user (tránh trùng với tên tổ chức); bỏ hardcode tên/chi nhánh trên header.
- Lời mời tổ chức (tài khoản đã tồn tại): bấm "Xác nhận" là trở thành thành viên ngay — lời mời hết kẹt "Đang chờ" phía người mời, và đăng nhập xong vào thẳng tổ chức vừa tham gia thay vì rơi về tổ chức cũ. Trước đây màn xác nhận chỉ điều hướng sang đăng nhập mà không hề gọi lệnh tiếp nhận.
- Lời mời tổ chức: lỗi khi tiếp nhận (mã hết hạn / bị thu hồi / đã dùng) hiện toast rõ ràng thay vì bị nuốt, và bottom sheet xác nhận không tự bật lại thành vòng lặp.
- Lời mời tổ chức: tài khoản đã có không còn thoáng thấy form đăng ký tài khoản mới trong lúc hệ thống đang tiếp nhận lời mời.

### Internal

- IAM: dùng IamRoleLabelMapper cho nhãn role trên member mapper / select organization.

- IAM audit logs: filter theo ngày dùng mốc ICT (`VDateTime.ictOffset`) thay vì local→UTC thuần.

- App-owned presentation (ADR 11): UI Partner/Pricing/Catalog/Dashboard/IAM chuyển vào `apps/erp`; xóa package `modules/*/presentation` (trừ Sales). Catalog widget preview: `apps/erp/example`.
- Sales: `20260830005` drop legacy `sales_order_cancellations.reason_code` (còn sót sau rebuild `IF NOT EXISTS`); `confirm_sales_order_cancellation` chỉ ghi `reason`.
- Sales C1: draft `017` summary outstanding/dueAt/checkout cash và `027_sales_review_inquiry.sql` truyền type/direction giao dịch. Chưa promote.
- Sales C2: draft `028_sales_review_inquiry_filters.sql` lọc/search trước cursor; trạng thái trả từ projection; timeline actor không lấy người đang xem. Chưa promote.
- Sales C3: draft `029_sales_review_receipt.sql` giữ `orderTotal` là giá trị đơn gốc; `settlementSnapshot` tách điều chỉnh sau bán; `content_hash` từ snapshot. Chưa promote.
- Sales C4: draft `030_sales_review_receipt_lifecycle.sql` khóa đơn rồi settlement trước khi đọc tiền; phiếu mới thay phiếu `generated` cùng đơn; in/chia sẻ không đổi snapshot. Chưa promote. Concurrency hai session chưa xác minh.
- Sales M1: draft `031_sales_review_facts.sql` phát `sales_settlement_changed.v1` là snapshot tiền sau recompute. Owner consumer còn `MISSING`. Chưa promote.
- Sales M2: draft `032_sales_review_constraints.sql` thêm CHECK/FK `NOT VALID` và audit SELECT. Không sửa dữ liệu cũ, không validate. Chưa promote.
- Sales M3: ghi evidence review. Draft SQL chưa apply. Owner consumer còn thiếu. Chưa promote.
- Sales: re-baseline migration — gỡ bốn bảng policy/reservation không dùng; form-policy trả catalog rỗng; Dart bỏ reserve/release + payload `reservation_ids`; UI lưu phiếu không đòi policy.
- Sales: gỡ OrderAdjustment CQRS, RPC S22, bảng order_adjustments; inquiry/list bỏ hasAdjustment; available-actions bỏ canAdjust.
- Presentation data shapes: chuẩn hóa Sales `*_result` / `*_args` / `*_contracts` (bỏ `*_outcome` / handoff `*_snapshot` / compose `*_ports`); sync presentation skill.
- Extract `MoneyFormatter` (`core/formatting`) — Sales/Pricing dùng chung; bỏ `SalesMoneyFormat` và formatter money local ở Pricing.
- Sales compose: chuyển prepare/result + draft/manual-price contracts vào `bloc/sales_order_draft/` (bỏ khỏi `support/`).
- Sales presentation: tối giản readability — gộp document action sheets; ports rename (`sales_*_ports`); bỏ dual-path compose products route/page/cubit; xóa `SalesReceiptCard`/`SalesSlipCard` và UI `SalesOrderIntegrationSection` (giữ load integration cho e-invoice).
- SG-10: gộp confirm hủy đơn vào `SalesOrderDetailCubit` / `PostSaleActions`; xóa `SalesOrderCancelCubit` orphan (sheet vẫn dumb + callback).
- Sales presentation: dead-code cleanup an toàn — bỏ `SalesPresentationModule`, `showSalesCheckoutBlockedSheet`, typedef `VOrderLineSwipeIconAction`, extension `isAll`, getter discount chết trên compose line; sửa overview catalog ghosts.
- Sales: migrate GoRouter sang `go_router_builder` (`TypedShellRoute` drafts/compose + `*Route.push/go`); xóa `SalesRoutes` string builders.
- Sales messaging: outbox chỉ lifecycle facts (canonical `*.v1`).
- Sales SQL: gỡ handoff Model B khỏi migration 20260827/20260830 + 20260904001 — bỏ bảng `integration_commands` / `*_impact_requests`, helper `_enqueue_*`, RPC 015 (retry/reconcile/status); `get_order_integration_status` trả stub `notRequired`; completion return/exchange không còn gate `IMPACT_PENDING`. Handoff sẽ dựng lại cùng module Inventory/Receivable/e-Invoice.
- SG-01: card nháp dùng `VCardHeader` / `VCardTitle` / `VCardAction` / `VCardContent` / `VCardFooter`.
- SG-01: first-load đơn nháp dùng `VSkeleton` (mimic card) thay spinner.
- SG-02: `SalesComposeOrderNoteTile` dùng `VCard` / `VCardHeader` / `VCardContent` thay Material shell thủ công.
- SG-02: sheet điều chỉnh giá dùng `VMoneyField` (tiền) / `VNumberField` (%).
- SG-02: summary bar khi refresh giá hiện `VSkeleton` thay text “Đang làm mới giá…”.
- SG-04: sheet chọn KH dùng `SalesCustomerPickerBody.sheet` (bỏ `_SheetBody` trùng).
- SG-04: bỏ floating banner; empty/no-result/error hiện qua `SalesCustomerPickerBody*State`; CTA tạo nhanh chỉ nút đáy sheet.
- SG-05: badge “Nợ cũ” trên `SalesCheckoutSummaryCard` dùng `VBadge` (`outstanding`).
- SG-05: `SalesCheckoutReceivableCard` chọn ngày hẹn bằng `VDatePicker`.
- SG-05: khối “Công nợ phát sinh” dùng `VCard` tone success thay `Container`.
- SG-06: `SalesResultFailureView` dùng `VEmptyState` tone danger thay Column icon/text thủ công.
- SG-06: bỏ `SalesResultSuccessBanner` (dead code, không page nào dùng) khỏi sales presentation + preview catalog.
- SG-05 / SG-06: tách `SalesAmountHighlightRow` dùng chung cho hàng tiền nổi bật (công nợ phát sinh, tổng đơn).
- SG-07: `SalesOrderListEmptyState` dùng composition `VEmptyState` (header + content) thay API `title`/`description`/`actionLabel` deprecated.
- SG-07: `SalesOrderListNoResultState` dùng composition `VEmptyState` thay Column icon/text tự dựng.
- SG-07: bỏ `SalesOrderListResultSummary` (dead code, không page nào dùng) khỏi sales presentation + preview catalog.
- SG-02: search sản phẩm hiện spinner ngay trong ô tìm kiếm khi đang tải; không tìm thấy / lỗi hiển thị empty state trong overlay dưới ô tìm kiếm kèm nút Thử lại, thay cho toast đáy màn hình.
- SG-01 / SG-02: hai màn dùng chung một `SalesDraftListCubit` (`ShellRoute` bọc `/sales/drafts` + `/sales/compose`), nên số "Đơn nháp (n)" ở compose đọc `totalCount` từ cache chung thay vì tự chạy `ListSalesOrderDraftsQuery`; mở lại danh sách nháp hiện cache ngay rồi làm mới nền.
- SG-04: trạng thái đang tải / tìm kiếm khách hàng nằm trong `SalesCustomerPickerBody` (state `SalesCustomerPickerLoading` + `SalesCustomerPickerLoadingState`), skeleton phủ cả nhãn đếm kết quả; sheet chọn khách không còn cờ loading cục bộ.
- SG-02: chạm vào ô tìm kiếm sản phẩm mở overlay ngay với danh sách gợi ý mặc định (không cần gõ); overlay dùng chrome giống `VCombobox` (viền `borderStrong`, radius input, shadow design system).
- SG-06 / SG-08: hub chứng từ dùng chung `SalesReceiptEntryCard` / `SalesEInvoiceEntryCard` (base row nội bộ); badge HĐĐT chuyển sang `VBadge` theo tone, bỏ `VBadgeStatus` deprecated và pill tự dựng.

### Fixed

- Tab "Tất cả đơn nháp" hiện đúng đơn nháp của mọi người trong cửa hàng.
- Swipe draft cards: border quanh foreground (opt-in trên reveal), không bị cắt khi vuốt.
- SG-02: `Expanded` bọc ngoài `VPagePadding` cho lines section (tránh ParentData lỗi với Padding).
- SG-02: lỗi tra cứu Catalog khi lưu / khôi phục đơn nháp không còn bị báo là "Sản phẩm không còn bán được" — nay hiện thông báo thử lại; sản phẩm đã bị xóa khỏi danh mục có thông báo riêng.
- SG-02: lookup sản phẩm khi lưu / khôi phục đơn nháp gộp thành một request cho cả đơn (trước đây mỗi dòng hàng một request khi khôi phục).

### Internal

- SG-08: redesign `SalesOrderDetailPaymentSummaryCard` — `SalesOrderDetailPaymentDisplayData` + flag `enabled` thay enum variant/override params.
- Hybrid presentation: `SalesComposeCubit` chuyển lên `apps/erp/.../bloc/`; pricing preview/evaluate/save typedefs thuộc ERP (`sales_pricing_ports`); module sales presentation giữ widgets + `SalesComposeState` / display VMs. ADR: `docs/architecture/10-hybrid-presentation-ownership.md`.
- App-owned presentation (ADR 11): UI Sales/Partner/Pricing/Catalog/Dashboard/IAM chuyển vào `apps/erp` (IAM Admin → `apps/admin`); xóa package `modules/*/presentation`. Catalog widget preview: `apps/erp/example`.
- Sales compose: tách checkout + điều chỉnh giá ra orchestration layer, busy state vào cubit, typed navigation result cho drafts.
- SG-02: sau lưu nháp thành công, working state reconcile `lineId` và số tiền đã persist từ response server.
- Catalog: `ResolveSellableProductsQuery` (lookup-by-ids theo lô, phân biệt `sellable` / `notSellable` / `notFound`); Sales draft orchestration chuyển sang query này thay vì mượn `SearchSellableProductsQuery`. Cần promote draft `_drafts/016_catalog_sellable_lookup_by_ids.sql` trước khi ship DB.
- Design system: bỏ `VComponentState`; dashboard `QuickActionButton` / pricing form dùng `enabled` inherit qua `VComponentScope`.
- Design system: flat `label`/`helperText`/`errorText`/`isRequired` trên fields → `@Deprecated` (prefer `VField`); call sites chưa migrate sẽ thấy analyze warning.
- Design system: `VBadgeStatus` / `VBadge.status` → `@Deprecated`; dùng `tone` + `variant` (`VBadgeVariant.soft` | `strong`); call sites hiện tại vẫn chạy qua bridge nhưng sẽ thấy analyze warning.
- Design system: `VChip.selected` / `VChip.emphasis` → `@Deprecated`; dùng `tone` (`primary` cho chip đang chọn); bridge vẫn hoạt động, call sites chưa migrate sẽ thấy analyze warning.
- IAM: `InvitationAcceptanceCubit.acceptExistingAccount()` — tiếp nhận lời mời ngay khi xác nhận, không cần session; token vẫn không rời cubit.
- Route `/login` nhận thêm `organizationName` qua `extra` để dựng banner; không truyền token hay `targetTenantId` qua điều hướng.
- Draft SQL `004_iam_patch_accept_invitation_anon` (`accept_invitation` cho phép gọi ẩn danh theo `invitee_email`, tái dùng membership sẵn có thay vì `DUPLICATE_MEMBERSHIP`, ghi `user_preferences.last_selected_tenant_id`) — cần promote trước khi ship DB, và phải kiểm chứng bằng `set local role anon;` vì đây là hàm `anon` đầu tiên ghi vào bảng có RLS.

## [1.7.2+38] - 2026-08-26

### Added

- Lịch sử quản trị tổ chức (tenant audit V2): lọc theo danh mục, tìm kiếm, chi tiết sự kiện tiếng Việt kèm diff Trước/Sau, che dữ liệu nhạy cảm và badge nguồn thông tin (snapshot / hiện tại / hệ thống).

### Changed

- Bỏ luồng kích hoạt owner riêng; owner onboard trực tiếp qua invitation tenant.
- Đơn giản hóa màn invitation (xác nhận / đăng ký) cho khớp luồng invitation thống nhất.
- Hiển thị ngày giờ theo giờ Việt Nam (ICT, UTC+7) trên lịch sử thay đổi và các màn IAM liên quan.

### Fixed

- Trạng thái tải readiness IAM tách riêng khỏi session — banner/ready state không “treo” khi readiness lỗi.

### Internal

- IAM: read ports / mapper / catalog tenant audit V2; gắn nguồn app qua header `X-Vet45-App: tenant_app`.
- Draft SQL audit/owner-activation cleanup (`002`, `004`, `006`, `007`; bản cũ archive) — cần promote trước khi ship DB.

## [1.7.1+37] - 2026-08-20

### Added

- Chặn đăng nhập khi tài khoản không còn membership active nào (thông báo rõ trên màn login).
- App icon / launcher icons mới (iOS + Android) qua `flutter_launcher_icons`.

### Changed

- Đồng bộ UI với design system mới: `VSelect` / `VCombobox` / `VDatePicker`, nút secondary, feedback tương tác cập nhật trên catalog, partner, invitation và IAM screens.

### Fixed

- Session restore: nếu không còn tenant accessible thì sign-out sạch, không giữ session “treo”.

### Internal

- IAM: xử lý `MembershipDeactivated` (xóa preference tenant stale); codegen integration-event registry; bỏ `IMessagingModule` facade.
- Analysis options: exclude thư mục build/platform.

## [1.7.0+36] - 2026-08-20

### Internal

- Baseline entry when introducing app-scoped changelog process.
