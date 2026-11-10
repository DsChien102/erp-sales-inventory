import 'package:go_router/go_router.dart';

import 'stock_detail_page.dart';
import 'stock_list_page.dart';

List<RouteBase> stockRoutes() => [
      GoRoute(
        path: '/warehouse/stock',
        name: 'warehouse.stock',
        builder: (context, state) {
          final q = state.uri.queryParameters['q'];
          return StockListPage(initialQuery: q);
        },
        routes: [
          GoRoute(
            path: ':productId',
            name: 'warehouse.stock.detail',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              final initialName =
                  state.extra is String ? state.extra as String : null;
              return StockDetailPage(
                productId: productId,
                initialName: initialName,
              );
            },
          ),
        ],
      ),
    ];

