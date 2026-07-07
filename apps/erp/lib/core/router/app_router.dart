import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../../features/more/presentation/pages/system_settings_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_settings_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_connection_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_template_page.dart';
import '../../features/more/presentation/einvoice_settings/pages/einvoice_auto_page.dart';
import '../../features/more/presentation/einvoice_settings/bloc/einvoice_settings_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/dashboard/presentation/models/dashboard_navigation.dart';
import '../../features/partner/presentation/pages/partner_detail_page.dart';
import '../../features/partner/presentation/pages/partner_create_page.dart';
import '../../features/partner/presentation/pages/partner_edit_page.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import '../../features/catalog/presentation/pages/product_guided_create_page.dart';
import '../../features/catalog/presentation/pages/product_control_center_page.dart';
import '../../features/catalog/presentation/pages/product_readiness_checklist_page.dart';
import '../../features/catalog/presentation/pages/product_measurement_units_page.dart';
import '../../features/catalog/presentation/pages/product_stock_adjustment_page.dart';
import '../../features/catalog/presentation/pages/product_manual_base_price_page.dart';
import '../../features/catalog/presentation/pages/product_price_bands_page.dart';
import '../../features/catalog/presentation/pages/edit_product_unit_price_band_page.dart';
import '../../features/catalog/presentation/pages/product_profile_maintenance_page.dart';
import '../../features/catalog/presentation/pages/product_images_maintenance_page.dart';
import '../../features/catalog/presentation/pages/settings/product_settings_page.dart';
import '../../features/catalog/presentation/pages/settings/custom_field_groups_page.dart';
import '../../features/catalog/presentation/pages/settings/upsert_custom_field_group_page.dart';
import '../../features/catalog/presentation/pages/settings/custom_field_group_detail_page.dart';
import '../../features/catalog/presentation/pages/settings/upsert_custom_field_page.dart';
import '../di/injection.dart';

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
      path: '/more/einvoice-settings',
      name: 'more.einvoice-settings',
      builder: (context, state) {
        final session = getIt<IamSession>();
        if (!session.hasPermission('settings.einvoice.configure')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Bạn không có quyền thiết lập hóa đơn điện tử',
                  style: VTypography.bodyDefault.copyWith(color: VColors.neutral0),
                ),
                backgroundColor: VColors.danger,
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
      path: '/partner/create',
      name: 'partner.create',
      builder: (context, state) {
        final hasPermission = getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.create);
        if (!hasPermission) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: 'Bạn không có quyền phù hợp.',
              type: VToastType.danger,
            );
            context.go('/');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return const PartnerCreatePage();
      },
    ),
    GoRoute(
      path: '/partner/detail',
      name: 'partner.detail',
      builder: (context, state) {
        final hasPermission = getIt<IPrincipalSnapshot>().hasPermission(
          PartnerPermissions.viewDetail,
        );
        if (!hasPermission) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: 'Bạn không có quyền phù hợp.',
              type: VToastType.danger,
            );
            context.go('/');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        final partner = state.extra as PartnerItemModel;
        return PartnerDetailPage(
          partnerId: partner.id,
          initialPartner: partner,
        );
      },
    ),
    GoRoute(
      path: '/partner/edit',
      name: 'partner.edit',
      builder: (context, state) {
        final hasPermission = getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.update);
        if (!hasPermission) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: 'Bạn không có quyền phù hợp.',
              type: VToastType.danger,
            );
            context.go('/');
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        final partner = state.extra as PartnerItemModel;
        return PartnerEditPage(
          partnerId: partner.id,
          initialPartner: partner,
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
  ],
);
