import 'package:go_router/go_router.dart';

import 'stock_policy_page.dart';
import 'stock_threshold_single_page.dart';

List<RouteBase> stockPolicyRoutes() => [
      GoRoute(
        path: '/warehouse/stock-policy',
        name: 'warehouse.stock_policy',
        builder: (context, state) => StockPolicyPage(
          initialTab: state.uri.queryParameters['tab'],
        ),
        routes: [
          GoRoute(
            path: 'product/:productId',
            name: 'warehouse.stock_policy.product',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              return StockThresholdSinglePage(productId: productId);
            },
          ),
        ],
      ),
    ];

