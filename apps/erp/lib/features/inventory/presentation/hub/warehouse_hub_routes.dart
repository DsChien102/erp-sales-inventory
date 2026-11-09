import 'package:go_router/go_router.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_hub_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_area_page.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_pending_approvals_page.dart';

List<RouteBase> warehouseHubRoutes() => [
      GoRoute(
        path: '/warehouse',
        name: 'warehouse',
        builder: (context, state) => const WarehouseHubPage(),
        routes: [
          GoRoute(
            path: 'area/:areaId',
            name: 'warehouse.area',
            redirect: (context, state) {
              final areaId = state.pathParameters['areaId'];
              final area =
                  areaId != null ? WarehouseArea.fromId(areaId) : null;
              if (area == null) {
                return '/warehouse';
              }
              final isOwner = getIt.isRegistered<SessionStore>()
                  ? getIt<SessionStore>().isOwner
                  : true;
              if (area.ownerOnly && !isOwner) {
                return '/warehouse';
              }
              return null;
            },
            builder: (context, state) {
              final areaId = state.pathParameters['areaId']!;
              final area = WarehouseArea.fromId(areaId)!;
              final isOwner = getIt.isRegistered<SessionStore>()
                  ? getIt<SessionStore>().isOwner
                  : true;
              return WarehouseAreaPage(area: area, isOwner: isOwner);
            },
          ),
          GoRoute(
            path: 'approvals',
            name: 'warehouse.approvals',
            builder: (context, state) => const WarehousePendingApprovalsPage(),
          ),
        ],
      ),
    ];

GoRoute inventoryRedirectRoute() => GoRoute(
      path: '/inventory',
      redirect: (_, _) => '/warehouse',
    );
