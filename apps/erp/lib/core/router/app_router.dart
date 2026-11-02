import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_catalog_application/application.dart' hide ProductChangeHistoryPage;
import 'package:erp/features/catalog/presentation.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:erp/features/auth/data/invitation_acceptance_repository.dart';
import 'package:erp/features/iam/data/account_repository.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/organization_repository.dart';
import 'package:erp/features/iam/presentation.dart';

// Sales (typed routes via go_router_builder)
import '../../features/sales/presentation/navigation/sales_typed_routes.dart';

// More Pages
import '../../features/more/presentation/pages/system_settings_page.dart';
import '../../features/more/presentation/pages/users_and_roles_page.dart';
import '../../features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart';
import '../../features/einvoice/presentation/pages/provider_connection_page.dart';
import '../../features/einvoice/presentation/pages/default_issuance_configuration_page.dart';
import '../../features/einvoice/presentation/pages/automation_policy_page.dart';

// Inventory
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/inventory/data/current_receipt_actor.dart';
import '../../features/inventory/data/goods_receipt_repository.dart';
import '../../features/inventory/logic/quick_receipt_session_cubit.dart';
import '../../features/inventory/presentation/pages/goods_receipt_approval_page.dart';
import '../../features/inventory/presentation/pages/goods_receipt_item_detail_page.dart';
import '../../features/inventory/presentation/pages/goods_receipt_items_page.dart';
import '../../features/inventory/presentation/pages/goods_receipt_reconciliation_page.dart';
import '../../features/inventory/presentation/pages/goods_receipt_result_page.dart';
import '../../features/inventory/presentation/pages/goods_receipt_review_page.dart';
import '../../features/inventory/presentation/pages/quick_receipt_header_page.dart';
import '../../features/inventory/presentation/pages/receipt_entry_choice_page.dart';
import '../../features/inventory/presentation/pages/receipt_item_detail_args.dart';
import '../../features/inventory/presentation/pages/warehouse_home_page.dart';
import '../../features/inventory/data/valuation_repository.dart';
import '../../features/inventory/logic/valuation_session_cubit.dart';
import '../../features/inventory/presentation/pages/valuation_queue_page.dart';
import '../../features/inventory/presentation/pages/valuation_workspace_page.dart';
import '../../features/inventory/presentation/pages/valuation_review_page.dart';
import '../../features/inventory/presentation/pages/valuation_result_page.dart';

// Auth
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/invitation_token_page.dart';
import '../../features/auth/presentation/pages/no_organization_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

// Dashboard & Shell
import '../../features/dashboard/presentation/erp_tab_scaffold.dart';
import '../../features/dashboard/presentation/home_tab_page.dart';
import '../../features/dashboard/presentation/store_shell.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/sales/presentation/pages/sales_order_list_page.dart';
import '../../features/catalog/presentation/pages/product_catalog_tab_page.dart';
import '../../features/partner/presentation/pages/partner_list_page.dart';
import '../../features/partner/presentation/partner_area_shell.dart';
import '../../features/partner/presentation/widgets/partner_no_permission_view.dart';
import '../../features/partner/logic/partner_list_cubit.dart';
import '../../features/partner/logic/partner_permissions.dart';

// Catalog
import '../../features/catalog/presentation/pages/product_guided_create_page.dart';
import '../../features/catalog/presentation/pages/product_control_center_page.dart';
import '../../features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import '../../features/catalog/presentation/pages/product_measurement_units_page.dart';
import '../../features/catalog/presentation/pages/product_stock_adjustment_page.dart';
import '../../features/catalog/presentation/pages/product_note_edit_page.dart';
import '../../features/catalog/presentation/pages/product_manual_base_price_page.dart';
import '../../features/catalog/presentation/pages/product_price_bands_page.dart';
import '../../features/catalog/presentation/pages/product_profile_maintenance_page.dart';
import '../../features/catalog/presentation/pages/product_images_maintenance_page.dart';
import '../../features/catalog/presentation/pages/product_change_history_page.dart';
import '../../features/catalog/presentation/pages/product_custom_field_group_edit_page.dart';
import '../../features/catalog/presentation/pages/edit_product_unit_price_band_page.dart';
import '../../features/catalog/presentation/pages/settings/product_settings_page.dart';
import '../../features/catalog/presentation/pages/settings/custom_field_groups_page.dart';
import '../../features/catalog/presentation/pages/settings/upsert_custom_field_group_page.dart';
import '../../features/catalog/presentation/pages/settings/custom_field_group_detail_page.dart';
import '../../features/catalog/presentation/pages/settings/upsert_custom_field_page.dart';
import '../../features/catalog/presentation/pages/settings/store_price_rule_settings_page.dart';
import '../../features/catalog/presentation/pages/settings/edit_store_price_rule_page.dart';
import '../../features/catalog/presentation/pages/settings/store_price_rule_change_history_page.dart';

// Partner
import '../../features/partner/presentation/pages/partner_create_page.dart';
import '../../features/partner/presentation/pages/partner_detail_page.dart';
import '../../features/partner/presentation/pages/partner_contacts_page.dart';
import '../../features/partner/presentation/pages/partner_contact_form_page.dart';
import '../../features/partner/presentation/pages/partner_contact_select_page.dart';
import '../../features/partner/presentation/pages/partner_transform_page.dart';
import '../../features/partner/data/partner_repository.dart';
import '../../features/partner/presentation/pages/partner_change_history_page.dart';

// Pricing
import '../../features/pricing/presentation/pages/pricing_list_page.dart';
import '../../features/pricing/presentation/pages/pricing_detail_page.dart';
import '../../features/pricing/presentation/pages/pricing_choose_method_page.dart';
import '../../features/pricing/presentation/pages/pricing_form_page.dart';
import '../../features/pricing/presentation/pages/pricing_import_page.dart';
import '../../features/pricing/presentation/pages/pricing_history_page.dart';
import '../../features/pricing/presentation/pages/pricing_pick_customer_page.dart';
import '../../features/pricing/presentation/pages/pricing_pick_product_page.dart';
import '../../features/pricing/presentation/pages/pricing_pick_unit_page.dart';

import '../di/injection.dart';
import '../errors/app_exception.dart';
import '../session/session_controller.dart';
import '../session/session_state.dart';
import 'route_guard.dart';
import 'session_refresh.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: sessionRefresh,
  redirect: (context, state) {
    if (!getIt.isRegistered<SessionController>()) return null;
    return routeGuard(
      session: getIt<SessionController>().state,
      location: state.matchedLocation,
    );
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return LoginPage(
          auth: getIt<AuthRepository>(),
          session: getIt<SessionController>(),
          prefilledEmail: extra?['prefilledEmail'] as String?,
          organizationName: extra?['organizationName'] as String?,
          showSuccessBanner: extra?['showSuccessBanner'] as bool? ?? false,
          passwordResetSuccess: extra?['passwordResetSuccess'] as bool? ?? false,
        );
      },
      routes: [
        GoRoute(
          path: 'reset-password',
          name: 'login.reset_password',
          builder: (context, state) {
            final email = state.extra as String? ?? '';
            return ResetPasswordPage(
              authRepository: getIt<AuthRepository>(),
              requestEmail: email,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => SignupPage(
        auth: getIt<AuthRepository>(),
        session: getIt<SessionController>(),
      ),
    ),
    GoRoute(
      path: '/verify-email',
      name: 'verify_email',
      builder: (context, state) {
        final extra = state.extra;
        final email = extra is String ? extra : state.uri.queryParameters['email'] ?? '';
        return VerifyEmailPage(
          email: email,
          auth: getIt<AuthRepository>(),
          session: getIt<SessionController>(),
        );
      },
    ),
    GoRoute(
      path: '/no-organization',
      name: 'no_organization',
      builder: (context, state) => NoOrganizationPage(
        session: getIt<SessionController>(),
      ),
    ),
    GoRoute(
      path: '/invitation',
      name: 'invitation',
      builder: (context, state) => InvitationTokenPage(
        invitations: getIt<InvitationAcceptanceRepository>(),
        auth: getIt<AuthRepository>(),
        session: getIt<SessionController>(),
      ),
    ),
    // KH & NCC: các route cụ thể khai báo TRƯỚC ShellRoute(StoreShell) để khớp
    // trước `/partner/:partnerId` (route con của tab, xem nhánh KH & NCC bên dưới).
    GoRoute(
      path: '/partner/new',
      name: 'partner.new',
      builder: (context, state) {
        final partnerType = state.extra as PartnerType? ?? PartnerType.person;
        return PartnerCreatePage(
          partnerType: partnerType,
          repository: getIt<PartnerRepository>(),
          onCreated: (partnerId) {
            if (context.mounted) {
              // Return id to PartnerListPage so it can refresh before handoff.
              context.pop(partnerId);
            }
          },
          onOpenExisting: (partnerId) {
            if (context.mounted) {
              context.pushReplacement('/partner/$partnerId');
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/edit',
      name: 'partner.edit',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        return PartnerCreatePage.edit(
          partnerId: partnerId,
          repository: getIt<PartnerRepository>(),
          onUpdated: (id) {
            if (context.mounted) {
              context.pop(true);
            }
          },
          onOpenExisting: (existingId) {
            if (context.mounted) {
              context.pushReplacement('/partner/$existingId');
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/transform',
      name: 'partner.transform',
      // Thiếu `extra` (vd. Forward/Back của trình duyệt) → về hồ sơ. Dùng
      // redirect thay vì `go` trong builder để không dựng hai bản nhánh tab
      // cùng lúc (Duplicate GlobalKey).
      redirect: (context, state) => state.extra is PartnerDetailDto
          ? null
          : '/partner/${state.pathParameters['partnerId']}',
      builder: (context, state) {
        final partner = state.extra as PartnerDetailDto;
        return PartnerTransformPage(
          partner: partner,
          repository: getIt<PartnerRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/history',
      name: 'partner.history',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final partnerName = state.extra as String? ?? 'Đối tác';
        return PartnerChangeHistoryPage(
          partnerId: partnerId,
          partnerName: partnerName,
          repository: getIt<PartnerRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/contacts',
      name: 'partner.contacts',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        return PartnerContactsPage(
          partnerId: partnerId,
          repository: getIt<PartnerRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/contacts/new',
      name: 'partner.contacts.new',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final contact = state.extra as PartnerContactDto?;
        return PartnerContactFormPage(
          partnerId: partnerId,
          contact: contact,
          repository: getIt<PartnerRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/contacts/select',
      name: 'partner.contacts.select',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final excludeIds = state.extra as List<String>? ?? const [];
        return PartnerContactSelectPage(
          partnerId: partnerId,
          repository: getIt<PartnerRepository>(),
          excludePersonPartnerIds: excludeIds,
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId/contacts/:contactId/edit',
      name: 'partner.contacts.edit',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final contactId = state.pathParameters['contactId']!;
        final contact = state.extra as PartnerContactDto?;
        return PartnerContactFormPage(
          partnerId: partnerId,
          contactId: contactId,
          contact: contact,
          repository: getIt<PartnerRepository>(),
        );
      },
    ),
    ShellRoute(
      builder: (context, state, child) => StoreShell(child: child),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ErpTabScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  name: 'dashboard',
                  builder: (context, state) => const HomeTabPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: SalesNav.ordersList,
                  name: SalesNav.ordersListName,
                  builder: (context, state) => const SalesOrderListPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/products/items',
                  name: 'products.items',
                  builder: (context, state) => const ProductCatalogTabPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                ShellRoute(
                  builder: (context, state, child) {
                    if (!_hasTenantPermission(PartnerPermissions.view)) {
                      return const PartnerNoPermissionView();
                    }
                    return PartnerAreaShell(
                      selectedId: state.pathParameters['partnerId'],
                      child: child,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: '/partner',
                      name: 'partner.list',
                      builder: (context, state) {
                        if (VListDetailLayout.isSplitOf(context)) {
                          return Scaffold(
                            backgroundColor: context.vColors.surfaceAlt,
                            body: const Center(
                              child: VEmptyState(
                                child: VEmptyHeader(
                                  children: [
                                    VEmptyMedia(icon: VIcons.info),
                                    VEmptyTitle('Chọn một KH & NCC để xem chi tiết.'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return PartnerListPage(
                          cubit: context.read<PartnerListCubit>(),
                        );
                      },
                      routes: [
                        GoRoute(
                          path: ':partnerId',
                          name: 'partner.detail',
                          builder: (context, state) {
                            final partnerId = state.pathParameters['partnerId']!;
                            final showCreateSuccessToast =
                                state.uri.queryParameters['created'] == '1';
                            final showTransformSuccessToast =
                                state.uri.queryParameters['transformed'] == '1';
                            final listCubit = context.read<PartnerListCubit>();
                            return PartnerDetailPage(
                              key: ValueKey(partnerId),
                              partnerId: partnerId,
                              repository: getIt<PartnerRepository>(),
                              showCreateSuccessToast: showCreateSuccessToast,
                              showTransformSuccessToast: showTransformSuccessToast,
                              onMutated: () => listCubit.fetchPartners(isRefresh: true),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/more',
                  name: 'more',
                  builder: (context, state) => BlocBuilder<SessionController, SessionState>(
                    builder: (context, session) => Scaffold(
                      appBar: const VAppBar(title: 'Thêm', showBackButton: false),
                      body: MorePage(tenantBlocked: session.isBlocked),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    GoRoute(
      path: '/inventory',
      name: 'inventory',
      builder: (context, state) => const WarehouseHomePage(),
    ),
    GoRoute(
      path: '/warehouse/receipts/new',
      name: 'warehouse.receipts.new',
      builder: (context, state) => const ReceiptEntryChoicePage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(
          create: (_) => QuickReceiptSessionCubit(
            repository: getIt<GoodsReceiptRepository>(),
            actorLoader: currentReceiptActor,
          )..loadCatalog(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/warehouse/receipts/quick/header',
          name: 'warehouse.receipts.quick.header',
          builder: (context, state) => const QuickReceiptHeaderPage(),
        ),
        GoRoute(
          path: '/warehouse/receipts/quick/items',
          name: 'warehouse.receipts.quick.items',
          builder: (context, state) => const GoodsReceiptItemsPage(),
        ),
        GoRoute(
          path: '/warehouse/receipts/quick/item-detail',
          name: 'warehouse.receipts.quick.item-detail',
          builder: (context, state) {
            final args = state.extra as ReceiptItemDetailArgs;
            return GoodsReceiptItemDetailPage(
              item: args.item,
              readOnly: args.readOnly,
            );
          },
        ),
        GoRoute(
          path: '/warehouse/receipts/quick/review',
          name: 'warehouse.receipts.quick.review',
          builder: (context, state) => const GoodsReceiptReviewPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/warehouse/receipts/approval/:id',
      name: 'warehouse.receipts.approval',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return GoodsReceiptApprovalPage(receiptId: id);
      },
    ),
    GoRoute(
      path: '/warehouse/receipts/result/:id',
      name: 'warehouse.receipts.result',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return GoodsReceiptResultPage(receiptId: id);
      },
    ),
    GoRoute(
      path: '/warehouse/receipts/reconciliation/:id',
      name: 'warehouse.receipts.reconciliation',
      builder: (context, state) => GoodsReceiptReconciliationPage(
        receiptId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/warehouse/valuation/queue',
      name: 'warehouse.valuation.queue',
      builder: (context, state) => const ValuationQueuePage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(
          create: (_) => ValuationSessionCubit(
            repository: getIt<ValuationRepository>(),
          ),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/warehouse/valuation/receipt/:id',
          name: 'warehouse.valuation.receipt',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ValuationWorkspacePage(receiptId: id);
          },
        ),
        GoRoute(
          path: '/warehouse/valuation/review',
          name: 'warehouse.valuation.review',
          builder: (context, state) => const ValuationReviewPage(),
        ),
        GoRoute(
          path: '/warehouse/valuation/result/:id',
          name: 'warehouse.valuation.result',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ValuationResultPage(receiptId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/more/settings',
      name: 'more.settings',
      builder: (context, state) => const SystemSettingsPage(),
    ),
    GoRoute(
      path: '/more/users-and-roles',
      name: 'more.users-and-roles',
      builder: (context, state) => UsersAndRolesPage(
        session: getIt<SessionController>(),
      ),
    ),
    GoRoute(
      path: '/more/users/invite',
      name: 'more.users.invite',
      builder: (context, state) => OrganizationInviteMemberPage(
        session: getIt<SessionController>(),
        invitations: getIt<InvitationRepository>(),
      ),
    ),
    GoRoute(
      path: '/more/users/invitation-detail',
      redirect: (context, state) => '/more/users',
    ),
    GoRoute(
      path: '/more/users/member-detail',
      redirect: (context, state) => '/more/users',
    ),
    GoRoute(
      path: '/more/users/select-role',
      name: 'more.users.select-role',
      redirect: (context, state) => '/more/users-and-roles',
    ),
    GoRoute(
      path: '/more/users/preview-role-change',
      name: 'more.users.preview-role-change',
      redirect: (context, state) => '/more/users-and-roles',
    ),
    ShellRoute(
      builder: (context, state, child) {
        if (!_hasTenantPermission(IamPermissions.memberView)) {
          return _permissionDeniedScaffold(
            context,
            message: 'Bạn không có quyền xem thành viên',
          );
        }
        final selectedId = state.pathParameters['membershipId'] ??
            state.pathParameters['invitationId'];
        return UsersAreaShell(
          selectedId: selectedId,
          canInvite: _hasTenantPermission(IamPermissions.memberInvite),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/more/users',
          name: 'more.users',
          builder: (context, state) {
            if (VListDetailLayout.isSplitOf(context)) {
              return Scaffold(
                backgroundColor: context.vColors.surfaceAlt,
                body: const Center(
                  child: VEmptyState(
                    child: VEmptyHeader(
                      children: [
                        VEmptyMedia(icon: VIcons.info),
                        VEmptyTitle('Chọn một thành viên hoặc lời mời để xem chi tiết.'),
                      ],
                    ),
                  ),
                ),
              );
            }
            return OrganizationUsersPage(
              cubit: context.read<OrganizationUsersCubit>(),
              canInvite: _hasTenantPermission(IamPermissions.memberInvite),
            );
          },
          routes: [
            GoRoute(
              path: 'invitations/:invitationId',
              name: 'more.users.invitation-detail',
              builder: (context, state) {
                final invitationId = state.pathParameters['invitationId'];
                if (invitationId == null || invitationId.isEmpty) {
                  return _permissionDeniedScaffold(
                    context,
                    message: 'Thiếu mã lời mời',
                  );
                }
                return OrganizationInvitationDetailPage(
                  invitationId: invitationId,
                  invitations: getIt<InvitationRepository>(),
                  onMutated: () =>
                      context.read<OrganizationUsersCubit>().refreshActiveTab(),
                );
              },
            ),
            GoRoute(
              path: 'members/:membershipId',
              name: 'more.users.member-detail',
              builder: (context, state) {
                final membershipId = state.pathParameters['membershipId'];
                if (membershipId == null || membershipId.isEmpty) {
                  return _permissionDeniedScaffold(
                    context,
                    message: 'Thiếu mã thành viên',
                  );
                }
                return OrganizationMemberDetailPage(
                  membershipId: membershipId,
                  members: getIt<MemberRepository>(),
                  onMutated: () =>
                      context.read<OrganizationUsersCubit>().refreshActiveTab(),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/more/roles/detail',
      name: 'more.roles.detail',
      redirect: (context, state) => '/more/roles',
    ),
    ShellRoute(
      builder: (context, state, child) {
        if (!getIt<SessionController>().isOwner) {
          return _permissionDeniedScaffold(
            context,
            message: 'Bạn không có quyền xem vai trò',
          );
        }
        final selectedId = state.pathParameters['code'];
        return RolesAreaShell(
          selectedId: selectedId,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/more/roles',
          name: 'more.roles',
          builder: (context, state) {
            if (VListDetailLayout.isSplitOf(context)) {
              return Scaffold(
                backgroundColor: context.vColors.surfaceAlt,
                body: const Center(
                  child: VEmptyState(
                    child: VEmptyHeader(
                      children: [
                        VEmptyMedia(icon: VIcons.info),
                        VEmptyTitle('Chọn một vai trò để xem chi tiết.'),
                      ],
                    ),
                  ),
                ),
              );
            }
            return OrganizationRolesPage(
              cubit: context.read<RolesCubit>(),
            );
          },
          routes: [
            GoRoute(
              path: ':code',
              name: 'more.roles.code',
              builder: (context, state) {
                if (!getIt<SessionController>().isOwner) {
                  return _permissionDeniedScaffold(
                    context,
                    message: 'Bạn không có quyền xem vai trò',
                  );
                }
                final extra = state.extra;
                if (extra is RoleUiModel) {
                  return OrganizationRoleDetailPage(role: extra);
                }
                return OrganizationRoleDetailPage(
                  code: state.pathParameters['code'],
                  invitations: getIt<InvitationRepository>(),
                  members: getIt<MemberRepository>(),
                  cubit: context.read<RolesCubit>(),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/more/audit-logs/detail',
      redirect: (context, state) => '/more/audit-logs',
    ),
    ShellRoute(
      builder: (context, state, child) {
        if (!_hasTenantPermission(IamPermissions.tenantAuditView)) {
          return _permissionDeniedScaffold(
            context,
            message: 'Bạn không có quyền xem lịch sử quản trị',
          );
        }
        final selectedId = state.pathParameters['auditLogId'];
        return AuditAreaShell(
          selectedId: selectedId,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/more/audit-logs',
          name: 'more.audit-logs',
          builder: (context, state) {
            if (VListDetailLayout.isSplitOf(context)) {
              return Scaffold(
                backgroundColor: context.vColors.surfaceAlt,
                body: const Center(
                  child: VEmptyState(
                    child: VEmptyHeader(
                      children: [
                        VEmptyMedia(icon: VIcons.info),
                        VEmptyTitle('Chọn một mục lịch sử để xem chi tiết.'),
                      ],
                    ),
                  ),
                ),
              );
            }
            return OrganizationAuditLogsPage(
              cubit: context.read<TenantAuditLogsCubit>(),
            );
          },
          routes: [
            GoRoute(
              path: ':auditLogId',
              name: 'more.audit-logs.detail',
              builder: (context, state) {
                final auditLogId = state.pathParameters['auditLogId'];
                if (auditLogId == null ||
                    auditLogId.isEmpty ||
                    auditLogId == 'detail') {
                  return _permissionDeniedScaffold(
                    context,
                    message: 'Thiếu mã nhật ký',
                  );
                }
                return AuditLogDetailPage(
                  auditLogId: auditLogId,
                  auditLogs: getIt<AuditLogRepository>(),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/more/my-account',
      name: 'more.my-account',
      builder: (context, state) => MyAccountPage(
        accountRepository: getIt<AccountRepository>(),
        authRepository: getIt<AuthRepository>(),
        session: getIt<SessionController>(),
        onLogout: () async {
          try {
            final result = await getIt<SessionController>().signOut();
            if (!context.mounted) return;
            if (!result.localCleared) {
              VToast.show(
                context,
                title: 'Đăng xuất thất bại',
                message: 'Không thể đóng phiên trên máy.',
                type: VToastType.danger,
              );
              return;
            }
            if (!result.remoteSucceeded) {
              VToast.show(
                context,
                title: 'Cảnh báo',
                message: 'Phiên trên máy đã đóng; máy chủ chưa xác nhận đăng xuất',
                type: VToastType.warning,
              );
            }
            context.go('/login');
          } on AppException catch (error) {
            if (!context.mounted) return;
            VToast.show(
              context,
              title: 'Đăng xuất thất bại',
              message: error.userMessage(),
              type: VToastType.danger,
            );
          }
        },
      ),
    ),
    GoRoute(
      path: '/more/my-account/edit',
      name: 'more.my-account.edit',
      builder: (context, state) => EditMyAccountPage(
        accountRepository: getIt<AccountRepository>(),
      ),
    ),
    GoRoute(
      path: '/more/my-account/reset-password',
      name: 'more.my-account.reset-password',
      builder: (context, state) => ResetPasswordPage(
        authRepository: getIt<AuthRepository>(),
      ),
    ),
    GoRoute(
      path: '/more/organization-profile',
      name: 'more.organization-profile',
      builder: (context, state) {
        if (!_hasTenantPermission(IamPermissions.tenantView)) {
          return _permissionDeniedScaffold(
            context,
            message: 'Bạn không có quyền xem hồ sơ tổ chức',
          );
        }
        return OrganizationProfilePage(
          organizationRepository: getIt<OrganizationRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/more/organization-profile/edit',
      name: 'more.organization-profile.edit',
      builder: (context, state) {
        final cubit = state.extra is OrganizationProfileCubit
            ? state.extra! as OrganizationProfileCubit
            : null;
        if (cubit != null) {
          return OrganizationEditProfilePage(cubit: cubit);
        }
        return OrganizationEditProfilePage(
          organizationRepository: getIt<OrganizationRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/more/organization-profile/legal',
      name: 'more.organization-profile.legal',
      builder: (context, state) {
        final cubit = state.extra is OrganizationProfileCubit
            ? state.extra! as OrganizationProfileCubit
            : null;
        if (cubit != null) {
          return OrganizationLegalProfileFormPage(cubit: cubit);
        }
        return OrganizationLegalProfileFormPage(
          organizationRepository: getIt<OrganizationRepository>(),
        );
      },
    ),
    GoRoute(
      path: '/more/einvoice',
      name: 'more.einvoice.overview',
      builder: (context, state) {
        final session = getIt<SessionController>();
        void goBack() {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }

        if (!session.hasPermission(EInvoicePermissions.manageConfiguration)) {
          return VPageScaffold(
            title: 'Hóa đơn điện tử',
            showBackButton: true,
            body: ConfigurationPermissionDeniedState(onBack: goBack),
          );
        }
        return EInvoiceConfigurationOverviewPage(
          einvoiceModule: getIt<IEInvoiceModule>(),
          executionContext: getIt<IExecutionContext>(),
          onBack: goBack,
          onConnectionTap: () async {
            await context.push('/more/einvoice/connection');
          },
          onIssuanceTap: () async => context.push('/more/einvoice/issuance'),
          onAutomationTap: () async => context.push('/more/einvoice/automation'),
        );
      },
    ),
    GoRoute(
      path: '/more/einvoice/connection',
      name: 'more.einvoice.connection',
      builder: (context, state) {
        return ProviderConnectionPage(
          einvoiceModule: getIt<IEInvoiceModule>(),
          executionContext: getIt<IExecutionContext>(),
          onCancel: () => context.pop(),
          onBack: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/more/einvoice/issuance',
      name: 'more.einvoice.issuance',
      builder: (context, state) {
        return DefaultIssuanceConfigurationPage(
          einvoiceModule: getIt<IEInvoiceModule>(),
          executionContext: getIt<IExecutionContext>(),
          onCancel: () => context.pop(),
          onBack: () => context.pop(),
        );
      },
    ),
    GoRoute(
      path: '/more/einvoice/automation',
      name: 'more.einvoice.automation',
      builder: (context, state) {
        return AutomationPolicyPage(
          einvoiceModule: getIt<IEInvoiceModule>(),
          executionContext: getIt<IExecutionContext>(),
          onCancel: () => context.pop(),
          onBack: () => context.pop(),
        );
      },
    ),
    // Sales typed routes: ShellRoute(drafts+compose) + remaining /sales/* ($appRoutes).
    ...$appRoutes,
    GoRoute(
      path: '/products/items/new',
      name: 'products.items.new',
      builder: (context, state) => const ProductGuidedCreatePage(),
    ),
    GoRoute(
      path: '/products/items/pcc',
      name: 'products.items.pcc',
      builder: (context, state) {
        final args = state.extra as ProductControlCenterRouteArgs;
        return ProductControlCenterPage(product: args.product);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/checklist',
      name: 'products.items.pcc.checklist',
      builder: (context, state) {
        final args = state.extra as ProductReadinessChecklistRouteArgs;
        return ProductReadinessChecklistPage(
          readinessView: args.readinessView,
          product: args.product,
          customFieldGroupCards: args.customFieldGroupCards,
        );
      },
    ),
    GoRoute(
      path: '/products/items/pcc/measurement-units',
      name: 'products.items.pcc.measurement-units',
      builder: (context, state) {
        final args = state.extra as ProductMeasurementUnitsRouteArgs;
        return ProductMeasurementUnitsPage(product: args.product);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/stock',
      name: 'products.items.pcc.stock',
      builder: (context, state) {
        final args = state.extra as ProductStockAdjustmentRouteArgs;
        return ProductStockAdjustmentPage(args: args);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/note',
      name: 'products.items.pcc.note',
      builder: (context, state) {
        final args = state.extra as ProductNoteEditRouteArgs;
        return ProductNoteEditPage(args: args);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/manual-base-price',
      name: 'products.items.pcc.manual-base-price',
      builder: (context, state) {
        final args = state.extra as ProductManualBasePriceRouteArgs;
        return ProductManualBasePricePage(
          product: args.product,
          basePriceCard: args.basePriceCard,
        );
      },
    ),
    GoRoute(
      path: '/products/items/pcc/price-bands',
      name: 'products.items.pcc.price-bands',
      builder: (context, state) {
        final args = state.extra as ProductPriceBandsRouteArgs;
        return ProductPriceBandsPage(args: args);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/price-bands/edit',
      name: 'products.items.pcc.price-bands.edit',
      builder: (context, state) {
        final args = state.extra as EditProductUnitPriceBandRouteArgs;
        return EditProductUnitPriceBandPage(args: args);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/custom-fields/edit',
      name: 'products.items.pcc.custom-fields.edit',
      builder: (context, state) {
        final args = state.extra as ProductCustomFieldGroupEditRouteArgs;
        return ProductCustomFieldGroupEditPage(args: args);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/profile-maintenance',
      name: 'products.items.pcc.profile-maintenance',
      builder: (context, state) {
        final product = state.extra as ProductListItemModel;
        return ProductProfileMaintenancePage(product: product);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/images-maintenance',
      name: 'products.items.pcc.images-maintenance',
      builder: (context, state) {
        final product = state.extra as ProductListItemModel;
        return ProductImagesMaintenancePage(product: product);
      },
    ),
    GoRoute(
      path: '/products/items/pcc/change-history',
      name: 'products.items.pcc.change-history',
      builder: (context, state) {
        final product = state.extra as ProductListItemModel;
        return ProductChangeHistoryPage(
          productId: product.id,
          productName: product.name,
        );
      },
    ),
    GoRoute(
      path: '/more/product-settings',
      name: 'more.product-settings',
      builder: (context, state) {
        // We will just let anyone with view permission access the settings and do checking later, or use manage permission.
        return const ProductSettingsPage();
      },
    ),
    GoRoute(
      path: '/more/product-settings/custom-fields',
      name: 'more.product-settings.custom-fields',
      builder: (context, state) => const CustomFieldGroupsPage(),
    ),
    GoRoute(
      path: '/more/product-settings/custom-fields/upsert-group',
      name: 'more.product-settings.custom-fields.upsert-group',
      builder: (context, state) {
        final cubit = state.extra as CustomFieldConfigCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/more/product-settings/custom-fields');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final groupId = state.uri.queryParameters['groupId'];
        return UpsertCustomFieldGroupPage(cubit: cubit, initialGroupId: groupId);
      },
    ),
    GoRoute(
      path: '/more/product-settings/custom-fields/:groupId',
      name: 'more.product-settings.custom-fields.detail',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        final cubit = state.extra as CustomFieldConfigCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/more/product-settings/custom-fields');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return CustomFieldGroupDetailPage(groupId: groupId, cubit: cubit);
      },
    ),
    GoRoute(
      path: '/more/product-settings/custom-fields/:groupId/upsert-field',
      name: 'more.product-settings.custom-fields.upsert-field',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        final cubit = state.extra as CustomFieldConfigCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/more/product-settings/custom-fields');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final fieldId = state.uri.queryParameters['fieldId'];
        return UpsertCustomFieldPage(groupId: groupId, cubit: cubit, initialFieldId: fieldId);
      },
    ),
    GoRoute(
      path: '/more/product-settings/store-price-rule',
      name: 'more.product-settings.store-price-rule',
      builder: (context, state) => const StorePriceRuleSettingsPage(),
    ),
    GoRoute(
      path: '/more/product-settings/store-price-rule/edit',
      name: 'more.product-settings.store-price-rule.edit',
      builder: (context, state) {
        final rule = state.extra as StorePriceRuleDto?;
        return EditStorePriceRulePage(existingRule: rule);
      },
    ),
    GoRoute(
      path: '/more/product-settings/store-price-rule/history',
      name: 'more.product-settings.store-price-rule.history',
      builder: (context, state) => const StorePriceRuleChangeHistoryPage(),
    ),

    // ── Pricing (TH-04 EP02) ──
    GoRoute(
      path: '/pricing',
      name: 'pricing.list',
      builder: (context, state) => const PricingListPage(),
    ),
    GoRoute(
      path: '/pricing/choose-method',
      name: 'pricing.choose-method',
      builder: (context, state) => const PricingChooseMethodPage(),
    ),
    GoRoute(
      path: '/pricing/new',
      name: 'pricing.new',
      builder: (context, state) => const PricingFormPage(),
    ),
    GoRoute(
      path: '/pricing/import',
      name: 'pricing.import',
      builder: (context, state) => const PricingImportPage(),
    ),
    // SG-03: pickers — search & chọn trực tiếp, không footer action.
    GoRoute(
      path: '/pricing/pick-customer',
      name: 'pricing.pick-customer',
      builder: (context, state) => const PricingPickCustomerPage(),
    ),
    GoRoute(
      path: '/pricing/pick-product',
      name: 'pricing.pick-product',
      builder: (context, state) => const PricingPickProductPage(),
    ),
    GoRoute(
      path: '/pricing/pick-unit/:productId',
      name: 'pricing.pick-unit',
      builder: (context, state) => PricingPickUnitPage(
        productId: state.pathParameters['productId']!,
      ),
    ),
    GoRoute(
      path: '/pricing/:ruleId',
      name: 'pricing.detail',
      builder: (context, state) {
        final ruleId = state.pathParameters['ruleId']!;
        return PricingDetailPage(ruleId: ruleId);
      },
    ),
    GoRoute(
      path: '/pricing/:ruleId/edit',
      name: 'pricing.edit',
      builder: (context, state) {
        final rule = state.extra as CustomerPriceRuleDetailDto?;
        if (rule == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/pricing');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PricingFormPage(initialRule: rule);
      },
    ),
        GoRoute(
          path: '/pricing/:ruleId/history',
          name: 'pricing.history',
          builder: (context, state) {
            final ruleId = state.pathParameters['ruleId']!;
            return PricingHistoryPage(ruleId: ruleId);
          },
        ),
      ],
    ),
  ],
);

bool _hasTenantPermission(String code) {
  return getIt<SessionController>().hasPermission(code);
}

Widget _permissionDeniedScaffold(
  BuildContext context, {
  required String message,
}) {
  return Scaffold(
    appBar: const VAppBar(title: 'Không có quyền', showBackButton: true),
    body: Center(
      child: VEmptyState(
        child: VEmptyHeader(
          children: [
            const VEmptyMedia(icon: VIcons.error),
            VEmptyTitle(message),
          ],
        ),
      ),
    ),
  );
}
