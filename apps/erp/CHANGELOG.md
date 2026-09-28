# Changelog

All notable changes to the **ERP** Flutter app (`apps/erp`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
with Flutter build numbers (`MAJOR.MINOR.PATCH+BUILD`).

Ship unit: this app only. Internal modules are not versioned separately — note them under
**Internal** when they affect this app.

## [Unreleased]

### Added
- Thêm `OrderEInvoiceSection` và `OrderEInvoiceCubit` trong sales presentation, tích hợp luồng phát hành lại hóa đơn điện tử khi thất bại (retry issuance) qua `IModuleMediator` và `IExecutionContext`.
- SG-08 / SG02-R01: chi tiết đơn hàng mở bề mặt e-invoice thật (`OrderEInvoiceSection`) thay sheet placeholder.
- SG-06 / SG02-R02: màn kết quả bán hàng mở cùng `OrderEInvoiceSection` thay sheet placeholder.

### Changed

- HĐĐT: chỉ cho phát hành lại khi projection `failed` có action issue/retry; khóa tap khi processing hoặc failed không retry được; widget test chứng minh auto progress → failure → retry.
- HĐĐT màn kết quả bán hàng: hiển thị `OrderEInvoiceSection` live ngay trên hàng chứng từ (SG02-R02), bỏ card “Chưa phát hành” cố định và sheet mở khi bấm.
- HĐĐT: polling projection qua `vet45_async_query` (`QueryClient.watchQuery`, 5s, key có tenant); bỏ `Timer.periodic` trên screen; refetch khi app resume.
- HĐĐT: khi phát hành thất bại xác định, `OrderEInvoiceCubit` đọc metadata lỗi an toàn qua `GetIssuanceAttemptStatusQuery`; `failed` cũng là terminal và dừng poll (trừ khi delivery còn pending/sending).
- HĐĐT hàng trạng thái đơn: icon leading dùng `VIcon` thay `VIconBox`; badge dùng `VComponentTone` thay `VBadgeStatus` deprecated; action item sheet dùng `VCard` + `VIcon`; post-issue delivery badge bỏ `isSmall`; xem hóa đơn chính thức, xem trước, và tải PDF/XML giữ sheet, hiện loading, disable nút còn lại; dismiss sheet khi đang xem trước thì hủy preview.
- Kết nối MISA meInvoice: tự động làm mới trạng thái kết nối mỗi 2 giây khi ở trạng thái chờ xác thực (`checkRequired`) sử dụng `vet45_async_query` (`refetchInterval`), thay thế thao tác tải lại thủ công; bỏ toast thông báo chờ worker; bổ sung spinner `VLoading` cạnh trạng thái "Chờ kết nối" và phân cách dòng bằng `VDivider`.
- Chi tiết đơn có đổi/trả: tab «Đơn gốc» mở phiếu bán hàng như lúc bán (chỉ đọc); tab «Sau đổi/trả» giữ phiếu hiện tại.
- Readiness: card điều kiện bắt buộc / hồ sơ pháp lý không còn bấm để điều hướng (chỉ còn CTA dưới cùng).
- Hồ sơ pháp lý: MST chấp nhận 10–13 chữ số (tự bỏ dấu `-`).
- Readiness: phân biệt blocker “Đang chờ chủ sở hữu chấp nhận lời mời” và “Lời mời hết hạn” (không nút sửa trên readiness).

### Fixed
- HĐĐT: đơn trả hết báo «Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.»; lệch version nguồn bảo tải lại rồi phát hành.
- Chi tiết đơn tải lại sau khi quay về từ đổi/trả, cùng cách nhánh hủy đơn.
- HĐĐT lưu PDF/XML: bỏ fallback mở browser; share native qua `XFile.fromData` + MIME/`fileNameOverrides` + `sharePositionOrigin` (iOS Share Sheet); fail-closed khi thiếu checksum hoặc tải lỗi; SG-06 đóng sau handoff thành công/dismiss, giữ mở khi lỗi; copy lỗi exporter đúng ngữ nghĩa lưu trên thiết bị.
- HĐĐT: chi tiết đơn luôn mount `OrderEInvoiceSection` khi module sẵn sàng (kể cả projection đầu lỗi); seed inert + `hasLoadedInitialProjection`.
- HĐĐT: result host seed projection không authoritative (`hasLoadedProjection`); khóa tap tới snapshot đầu tiên + readiness (notIssued).
- HĐĐT: bỏ `AppLifecycleRefetch` toàn app; resume chỉ qua `OrderEInvoicePollingHost`; `QueryClient` production `gcTime` 5 phút.
- HĐĐT: bắt lỗi auth khi start poll và swallow lỗi network trên QueryObserver background fetch (không còn uncaught Future).
- HĐĐT: banner lỗi phát hành chỉ map `failureCode` allow-list; RPC `get_issuance_attempt_status` không trả raw `failure_message` provider.
- HĐĐT: sau confirm retry, `setQueryData` snapshot processing để poll observer không re-apply cache `failed` cũ.
- HĐĐT xem trước: kéo dài cửa sổ poll worker/MISA (~45s), bỏ clear URL khi bấm lại, và chặn double-tap khi đang previewing — giảm báo lỗi giả "chưa sẵn sàng" dù preview đã mở.
- HĐĐT sheet xác nhận phát hành: lấy mẫu/ký hiệu/hình thức ký từ issuance profile + template MISA đã sync, không hardcode `1C26TAA`.

- Quyết toán đổi/trả: hiện đúng hoàn tiền / giảm nợ đơn theo server; khóa công tắc «Cấn trừ công nợ hiện tại»; bỏ «Kết hợp» ở phương thức hoàn.
- Soạn đơn: sau «Lưu nháp» về đơn mới trống; nháp đã bị xoá/đổi nơi khác thì toast rồi thoát kẹt (không còn vòng sheet chưa lưu).
- Đổi/trả: trả hàng trên đơn chưa thu không còn hiện «Không phát sinh chênh lệch»; phiếu PDF tách «Giảm nợ đơn» và «Đã hoàn» (bỏ nhãn cấn trừ sai).
- Phiếu bán hàng: sau đổi/trả / thu thêm / hoàn tiền, lần mở phiếu kế tiếp tạo phiếu mới thay vì đọc bản chụp cũ (cần chạy SQL tay hoặc reset DB).
- Checkout: toast «Paid amount cannot exceed the checkout total.» → tiếng Việt.
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

- Einvoice: readiness nhận `sourceBlockers`; evaluator chặn `ORDER_FULLY_RETURNED` và không chồng blocker dữ liệu thương mại khi đơn đã trả hết.
- Einvoice: readiness trả `source_blockers`; phát hành thủ công và retry chặn mọi blocker của Sales; auto bỏ qua đơn trả hết (`SKIPPED` / `ORDER_FULLY_RETURNED`); reevaluate làm mới version nguồn trước khi bắt đầu. Draft `006`, `008`.
- Einvoice: completion người mua unique theo `(tenant_id, sales_order_id)`; `complete_buyer_invoice_data` lấy `buyer_partner_id` từ nguồn đơn, không còn `gen_random_uuid()`.
- Einvoice: draft `018` `get_einvoice_source_snapshot` đọc `sales._sales_order_current_lines`; đơn trả hết trả `ORDER_FULLY_RETURNED`; tổng cộng từ dòng còn lại.
- Einvoice: draft `017` dựng lại `finalize_sales_order` từ theme5 (`20260830008`), chỉ thêm buyerType, snapshot hóa đơn trên customer, và cột `buyer_tax_snapshot`.
- Sales: xác nhận đổi/trả tăng `sales_orders.version` (sửa tại chỗ `20260904001`) để hóa đơn và màn hình nhận ra nội dung đơn đã đổi.
- Sales: helper `sales._sales_order_current_lines` dùng chung cho phiếu in và nguồn hóa đơn sau đổi/trả (sửa tại chỗ `20260830010`; JSON phiếu in giữ nguyên khóa).
- TH-08 H1: fail-closed preview/official view URL (HTTPS + host `*.meinvoice.vn`); `parseDataString` không ép object/list/number; bỏ `print` download adapter; `InvoiceDelivery.hasActiveLock` chỉ `PROCESSING` (UNKNOWN không khóa).
- TH-08 H1: policy retry MISA publish — `InvoiceNumberNotCotinuous` retryable (≤3, cùng RefID/canonical), `InvoiceDuplicated` reconcile-first rồi mới retry, `DuplicateInvoiceRefID` reconciliation-only; draft `020_einvoice_misa_publish_retry_policy.sql`.
- TH-08 H1: publish series lease bền vững `(tenant, provider_connection, invoice_series)` — acquire trước dispatch barrier, busy → `reschedule_internal_command` (không dead-letter), release trong `finally`; draft `019_einvoice_misa_publish_series_lease.sql`.
- TH-08 H1: status/reconciliation dùng classification theo `invoiceSeries` bất biến từ attempt snapshot; poll fail-closed khi thiếu provider transaction id; MISA status query bỏ hard-code `invoiceWithCode: true`.
- TH-08 H1: buyer tổ chức có MST nhưng thiếu địa chỉ bị chặn bằng `BUYER_ADDRESS_REQUIRED` ở readiness/completion/canonical; preview/issue fail-closed và copy lỗi an toàn.
- TH-08 H1: invariant `KCT-only` + blocker `UNSUPPORTED_TAX_DATA` tại canonical boundary; copy lỗi an toàn trên order e-invoice.
- TH-08 H1: resolve template/SignType bất biến; bỏ fallback `1C26TAA`/`tpl-default`; mapper fail-closed khi thiếu SignType.
- TH-08 H1: sync capability template fetch cả có mã + không mã; classify MTT/`IsSendSummary` từ `InvSeries`; snapshot JSON additive (không mất legacy).
- TH-08 Slice 5 closeout: FE `done`, E2E fake/runtime `in_progress` (live DB/MISA/simulator AC còn mở); source guards + focused FE/BE regression pass; harness/traceability cập nhật trung thực.
- TH-08 Slice 5: fake E2E hai host SG02-R01/R02 + catalog specimens SG-07 (send/resend/history) không gọi backend.
- TH-08 Slice 5: projection auto-send visibility — poll khi `deliveryPending`/`sending`, dừng với `unknown`/terminal; secondary attention + UNKNOWN unlock trên post-issue/SG-07.
- TH-08 Slice 5: nối trang lịch sử gửi HĐĐT authoritative (`GetInvoiceDeliveryHistoryQuery`) — newest first, empty/loading/failure + retry; xóa fixture page cũ.
- TH-08 Slice 5: nối SG-07 Send/Resend app-owned vào `OrderEInvoiceSection` (submit trong sheet, refresh sau `PROCESSING`, secondary attention trên post-issue).
- TH-08 Slice 5: app-owned SG-07 Send/Resend sheets với loading thật qua `OrderInvoiceDeliveryCubit` (suggestion source, validate email, khóa submit/hủy khi pending).
- TH-08 Slice 5: tách `OrderInvoiceDeliveryCubit` (load context + submit + idempotency); gỡ send orchestration khỏi `OrderEInvoiceCubit`.
- TH-08 Slice 5: khóa UI contract SG-07 app-owned (`sg07_mapped_ui_tree` + RED `sg07_app_owned_contract_test`); baseline FE HĐĐT pass.
- TH-08 Slice 5: `UNKNOWN` availability-first — chỉ `PROCESSING` khóa gửi cạnh tranh; thêm `DeliveryDisplayState.unknown`; manual resend sau UNKNOWN; draft SQL 013/014 cập nhật lock/projection (chưa promote).
- TH-08 Slice 5: `MeInvoiceClient.sendEmail` chấp nhận envelope Product `success=true, data=""` (acknowledgement) và vẫn tương thích response itemized; capability email chỉ trên host `api.meinvoice.vn`.
- TH-08 Slice 3 repair: draft `008` GRANT EXECUTE auto-issuance RPCs (`start_auto_issuance`, `list_open_auto_issuance_processes`, `reevaluate_auto_issuance`) cho `authenticated, service_role`.
- TH-08 S4 closeout harness: FE lane `done`, E2E `in_progress`; traceability `th08_*` ids; focused regression pass (application/infra/worker/ERP).
- TH-08 S4: runtime E2E hai host Theme 05 (`th08_e2e_e03_u01/u02_sc01_01`); seam optional launcher/exporter trên result; catalog SG-02/SG-06 specimen app-owned.
- TH-08 S4: SnackBar một surface cho `errorMessage` (official view / document); sheet không tự đóng khi lỗi.
- TH-08 S4: relocate SG-02/SG-06 post-issued sheets sang app-owned; exporter verify `expectedSha256`; sibling document action disabled khi PDF/XML loading.
- TH-08 S4: document request fake/command→read split + correlate `operationId`; poll `AVAILABLE` không URL; ẩn literal `FAILED`/`CHECK_REQUIRED`.
- TH-08 S4: official view correlate `operationId`, poll cả replay `AVAILABLE` không URL, loading qua `isOpeningOfficialView`; launcher chỉ mở HTTP(S).
- TH-08 S4: tách `isOpeningOfficialView` khỏi `submitting`; gộp mapper lỗi HĐĐT an toàn (`OrderEInvoiceErrorMessage`) — không lộ raw exception.
- TH-08: gỡ UI Dev Acceptance (task card Dashboard + route `/dev/einvoice-acceptance` + page/widgets/tests); giữ fixture SQL/checklist harness.
- TH-08: gỡ email mock + nhãn mô phỏng / `is_simulated` trên UI delivery (Option B).
- TH-08 email mock: hoàn tất contract `is_simulated` (draft 013/014 + load context), mock HTTP sendemail, polling UI nhãn mô phỏng, và worker log an toàn (mode/scenario không email/token).
- Einvoice: grant `authenticated` execute trên `issue_invoice` / `retry_issuance` + access gate (actor / `einvoice.issue`|`manage_issuance` / sales scope); script repair local cho lỗi 42501 khi phát hành từ ERP.
- Einvoice: thêm schema `extensions` vào `search_path` các RPC phát hành dùng `digest()` (pgcrypto); script repair `ALTER FUNCTION` cho lỗi 42883 `digest(bytea, unknown) does not exist`.
- Einvoice: so sánh `provider_connections.status` với enum `connected` (không `'CONNECTED'`); script repair rewrite function body cho lỗi 22P02 khi `issue_invoice`.
- Einvoice: persist `supports_preview` trong capability snapshot khi sync MISA (command JSON + RPC mapper); readiness surface blocker `PREVIEW_UNSUPPORTED` khi thiếu capability (fix fail-closed chặn preview live acceptance).
- Einvoice: `get_invoice_preview` truyền đúng `p_actor_id` (trước đó nhầm `tenantId` → `NO_PERMISSION: actor mismatch` khi poll preview).
- Einvoice: canonical→MISA mapper mirror field `*Oc` / `VATRateName` / `ItemType` cho payload kiểu seed VND; bổ sung `RefID`, `TotalAmountInWords`, discount defaults; log reason+detail khi unpublished preview fail.
- Sales: `confirm_return_exchange` ghi hoàn theo `payment_method` đã chọn (không còn hardcode `cash`) — cần chạy SQL tay hoặc reset DB.
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

- Einvoice S5 Task 9: wire delivery worker DI (worker-only MISA send on ERP), inbox subscriptions for registered→auto delivery, send/reconcile dead-letter handlers + max-3 attempt policy.
- Einvoice S5 Task 8: MISA delivery provider adapter + safe classifier for invoice email send (typed outcomes; worker HTTP wiring in Task 9).
- Einvoice S5 Task 7: capability-aware delivery reconciliation (`supportsDeliveryResultObservation` fail-closed, `ReconcileInvoiceDeliveryCommand`, draft 015 load/record RPCs, unsupported MISA observation adapter).
- Einvoice S5 Task 6: delivery result RPCs (prepare/record/dead-letter), UNKNOWN→PENDING VERIFY_DELIVERY handoff, projection `delivery_display_state`/`has_secondary_attention`, Supabase delivery gateways/mappers.
- Einvoice S5 Task 5: draft delivery schema (`invoice_deliveries` / `delivery_attempts`) + start/read/load RPCs (`start_auto_delivery`, `send_electronic_invoice`, sheet/history, `load_delivery_attempt_context`).
- Einvoice S5 Task 4: Partner source-owned `partner.get_einvoice_recipient_snapshot` draft contract (service_role only).
- Einvoice S5 Task 3: delivery application ports/handlers, `einvoice.send_invoice_email` internal command, registered→auto delivery event handler, safe delivery integration events.
- Einvoice S5 Task 2: domain InvoiceDelivery lifecycle, recipient/display policies, and pure delivery invariants.
- Einvoice S5 Task 0: freeze EP-04 delivery contracts (typed evidence, recipient provenance enums, BuyerInvoiceSnapshot lineage in S2/S3 attempt snapshots).
- Einvoice S4c: durable worker commands (`fetch_official_view`, `download_invoice_document`, `poll_provider_observation`), provider-call audit, same-operation retry/dead-letter CHECK_REQUIRED, preview interaction wiring.
- Einvoice S4 integration tests: end-to-end official view, document download, observation flows with `FakeMeInvoiceClient` (no live MISA).
- Einvoice S4b: draft `invoice_document_operations` + `invoice_documents`, RPC document retrieval, private bucket `einvoice-documents`, storage port và signed URL read path.
- Einvoice S5: MISA electronic-invoice provider adapter (`previewPublished`, `download`, `getStatus`) + classifiers + worker-only guard.
- Einvoice S6: provider interaction audit, observation RPCs, attention outbox event `einvoice.provider_observation_attention_required`.
- Einvoice S4a: draft `official_invoice_view_operations` + RPC official view (`request_official_invoice_view`, `get_electronic_invoice_detail`); Supabase electronic-invoice gateways (detail/read path).
- Einvoice S3c: `RetryIssuanceCommand` + `RetryIssuanceCommandHandler` và `SupabaseIssuanceCommandGateway.retryIssuance` cho definite failure retry với integer version và idempotent rerun.
- Einvoice S2b: Supabase issuance gateways (`SupabaseIssuanceCommandGateway`, `SupabaseIssuanceResultGateway`, `SupabaseOrderInvoiceProjectionReadGateway`) + `IssuanceRpcMapper`; nested `ISSUANCE_NOT_READY` blockers và `IDEMPOTENCY_CONFLICT` error mapping.
- Einvoice S2b: `IssueInvoiceCommand` dùng opaque `sourceVersion`; thêm typed gateways (`IIssuanceCommandGateway`, `IIssuanceResultGateway`), `EInvoiceIssuanceBlockers`, `PublishPreparationAction`, `IssuanceResultEvidenceDto`, và `IDEMPOTENCY_CONFLICT`.
- Einvoice S2a: Backend support kiểm tra sẵn sàng phát hành, hoàn thiện thông tin người mua và xem trước hóa đơn MISA (draft RPCs & schema seam).
- Einvoice S1: `get_provider_connection_screen` đọc hồ sơ pháp lý từ `iam.tenant_legal_profiles` (không còn `public.tenants`); schema configuration apply trước RPC connection.
- Async Query: mở rộng `refetchInterval` cho `QueryOptions`, `QueryObserver` và `UseQuery` trong `packages/vet45_async_query`.
- Einvoice: đăng ký `QueryClient` trong DI ERP, đồng bộ query cache trực tiếp qua `setQueryData` trong `ProviderConnectionCubit` và tích hợp polling kết nối nhà cung cấp vào `ProviderConnectionView`.

## [1.7.3+40] - 2026-09-14

### Added

- SG-05: `SalesPaymentQrCard` nhận `qrImage` (`ImageProvider`) hiển thị ảnh QR vuông, cạnh bằng chiều cao cột thông tin; null → placeholder icon.
- SG-02: bấm vùng tên/giá trên dòng soạn đơn để chọn lại đơn vị bán (giữ SL; trùng unit thì merge dòng).
- Sales checkout: chụp danh tính hóa đơn người mua (`buyerType` / tên / địa chỉ / email) từ Partner lúc chọn khách và gửi kèm đơn hàng.
### Fixed

- Login tenant: dùng `SignInTenantUserCommand` (auth-only) — không gọi `get_session_context` khi multi-tenant; tenant/store qua `TenantContextCubit.bootstrap`.
- SG-06 example catalog: gỡ preview `showSalesResultEInvoiceSheet` (đã xóa); ghi chú host `OrderEInvoiceSection`.
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
