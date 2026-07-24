import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_catalog_application/application.dart' hide ProductChangeHistoryPage;
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

// More Pages
import '../../features/more/presentation/pages/system_settings_page.dart';
import '../../features/more/presentation/pages/users_and_roles_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_settings_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_connection_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_template_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_auto_page.dart';
import '../../features/more/presentation/einvoice_settings/bloc/einvoice_settings_cubit.dart';

// Auth
import '../../features/auth/presentation/pages/login_page.dart';

// Dashboard
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/dashboard_navigation.dart';

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
import '../errors/exception_mapper.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuthenticated = getIt<ICurrentUser>().userId != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoginRoute) {
      return '/login';
    }

    if (isAuthenticated && isLoginRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) {
        final tab = state.extra as DashboardTab? ?? DashboardTab.home;
        return DashboardPage(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/more/settings',
      name: 'more.settings',
      builder: (context, state) => const SystemSettingsPage(),
    ),
    GoRoute(
      path: '/more/users-and-roles',
      name: 'more.users-and-roles',
      builder: (context, state) => const UsersAndRolesPage(),
    ),
    GoRoute(
      path: '/more/users',
      name: 'more.users',
      builder: (context, state) => const OrganizationUsersPage(),
    ),
    GoRoute(
      path: '/more/users/invite',
      name: 'more.users.invite',
      builder: (context, state) => const OrganizationInviteMemberPage(),
    ),
    GoRoute(
      path: '/more/users/invitation-detail',
      name: 'more.users.invitation-detail',
      builder: (context, state) {
        final invitation = state.extra as InvitationUiModel?;
        return invitation != null
            ? OrganizationInvitationDetailPage(invitation: invitation)
            : const OrganizationInvitationDetailPage();
      },
    ),
    GoRoute(
      path: '/more/users/member-detail',
      name: 'more.users.member-detail',
      builder: (context, state) {
        final member = state.extra as MemberUiModel?;
        return member != null
            ? OrganizationMemberDetailPage(member: member)
            : const OrganizationMemberDetailPage(
                member: MemberUiModel(
                  id: 'm1',
                  name: 'Nguyễn Văn Minh',
                  email: 'minh@minhphat.vn',
                  role: 'Nhân viên bán hàng',
                  status: MemberStatus.active,
                ),
              );
      },
    ),
    GoRoute(
      path: '/more/users/select-role',
      name: 'more.users.select-role',
      builder: (context, state) {
        final member = state.extra as MemberUiModel?;
        return OrganizationSelectRolePage(
          member: member ??
              const MemberUiModel(
                id: 'm1',
                name: 'Nguyễn Văn Minh',
                email: 'minh@minhphat.vn',
                role: 'Nhân viên bán hàng',
                status: MemberStatus.active,
              ),
        );
      },
    ),
    GoRoute(
      path: '/more/users/preview-role-change',
      name: 'more.users.preview-role-change',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final member = extra?['member'] as MemberUiModel? ??
            const MemberUiModel(
              id: 'm1',
              name: 'Nguyễn Văn Minh',
              email: 'minh@minhphat.vn',
              role: 'Nhân viên bán hàng',
              status: MemberStatus.active,
            );
        final newRole = extra?['newRole'] as String? ?? 'Kế toán';
        return OrganizationPreviewRoleChangePage(
          member: member,
          newRole: newRole,
        );
      },
    ),
    GoRoute(
      path: '/more/roles',
      name: 'more.roles',
      builder: (context, state) => const OrganizationRolesPage(),
    ),
    GoRoute(
      path: '/more/roles/detail',
      name: 'more.roles.detail',
      builder: (context, state) {
        final role = state.extra as RoleUiModel?;
        return OrganizationRoleDetailPage(
          role: role ?? FakeRolesData.sampleRoles[1],
        );
      },
    ),
    GoRoute(
      path: '/more/audit-logs',
      name: 'more.audit-logs',
      builder: (context, state) => const OrganizationAuditLogsPage(),
    ),
    GoRoute(
      path: '/more/audit-logs/detail',
      name: 'more.audit-logs.detail',
      builder: (context, state) {
        final log = state.extra as AuditLogItemUiModel?;
        return AuditLogDetailPage(
          log: log ?? FakeAuditLogsData.sampleAuditLogs[0],
        );
      },
    ),
    GoRoute(
      path: '/more/my-account',
      name: 'more.my-account',
      builder: (context, state) => MyAccountPage(
        onLogout: () async {
          final result = await guard(
            () => getIt<IIamModule>().executeCommandAsync(SignOutCommand()),
          );
          if (!context.mounted) return;
          result.fold(
            (failure) {
              VToast.show(
                context,
                title: 'Đăng xuất thất bại',
                message: failure.message,
                type: VToastType.danger,
              );
            },
            (_) => context.go('/login'),
          );
        },
      ),
    ),
    GoRoute(
      path: '/more/my-account/edit',
      name: 'more.my-account.edit',
      builder: (context, state) {
        final data =
            state.extra as MyAccountUiModel? ?? MyAccountUiModel.sample;
        return EditMyAccountPage(data: data);
      },
    ),
    GoRoute(
      path: '/more/my-account/reset-password',
      name: 'more.my-account.reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: '/more/organization-profile',
      name: 'more.organization-profile',
      builder: (context, state) => const OrganizationProfilePage(),
    ),
    GoRoute(
      path: '/more/organization-profile/edit',
      name: 'more.organization-profile.edit',
      builder: (context, state) => const OrganizationEditProfilePage(),
    ),
    GoRoute(
      path: '/more/organization-profile/legal',
      name: 'more.organization-profile.legal',
      builder: (context, state) {
        final isEdit = state.extra as bool? ?? false;
        return OrganizationLegalProfileFormPage(isEdit: isEdit);
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings',
      name: 'more.einvoice-settings',
      builder: (context, state) {
        final session = getIt<IamSession>();
        if (!session.hasPermission('settings.einvoice.configure')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: VText(
                  'Bạn không có quyền thiết lập hóa đơn điện tử',
                ),
                backgroundColor: context.vColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.card),
                ),
                margin: const EdgeInsets.all(VSpacing.space4),
              ),
            );
            context.go('/');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return const EInvoiceSettingsPage();
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/connection',
      name: 'more.einvoice-settings.connection',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/more/einvoice-settings');
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return EInvoiceConnectionPage(cubit: cubit);
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/template',
      name: 'more.einvoice-settings.template',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/more/einvoice-settings');
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return EInvoiceTemplatePage(cubit: cubit);
      },
    ),
    GoRoute(
      path: '/more/einvoice-settings/auto',
      name: 'more.einvoice-settings.auto',
      builder: (context, state) {
        final cubit = state.extra as EInvoiceSettingsCubit?;
        if (cubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/more/einvoice-settings');
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return EInvoiceAutoPage(cubit: cubit);
      },
    ),
    GoRoute(
      path: '/products/items',
      name: 'products.items',
      builder: (context, state) => const DashboardPage(initialTab: DashboardTab.products),
    ),
    GoRoute(
      path: '/partner',
      name: 'partner.list',
      builder: (context, state) => const DashboardPage(initialTab: DashboardTab.partners),
    ),
    GoRoute(
      path: '/partner/new',
      name: 'partner.new',
      builder: (context, state) {
        final partnerType = state.extra as PartnerType? ?? PartnerType.person;
        return PartnerCreatePage(
          partnerType: partnerType,
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final partner = state.extra as PartnerDetailDto?;
        if (partner == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/partner/$partnerId');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PartnerTransformPage(
          partner: partner,
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
        );
      },
    ),
    GoRoute(
      path: '/partner/:partnerId',
      name: 'partner.detail',
      builder: (context, state) {
        final partnerId = state.pathParameters['partnerId']!;
        final showCreateSuccessToast = state.uri.queryParameters['created'] == '1';
        final showTransformSuccessToast = state.uri.queryParameters['transformed'] == '1';
        return PartnerDetailPage(
          partnerId: partnerId,
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
          showCreateSuccessToast: showCreateSuccessToast,
          showTransformSuccessToast: showTransformSuccessToast,
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
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
          partnerModule: getIt<IPartnerModule>(),
          executionContext: getIt<IExecutionContext>(),
        );
      },
    ),

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
);
