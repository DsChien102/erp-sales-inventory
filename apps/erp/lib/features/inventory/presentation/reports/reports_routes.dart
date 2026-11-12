import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_state.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/presentation/reports/gross_profit_page.dart';
import 'package:erp/features/inventory/presentation/reports/movement_detail_page.dart';
import 'package:erp/features/inventory/presentation/reports/stock_card_page.dart';
import 'package:erp/features/inventory/presentation/reports/stock_report_page.dart';
import 'package:erp/features/inventory/presentation/reports/supplier_purchase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Widget _withRepository(ReportsRepository? repository, Widget child) {
  if (repository == null) return child;
  return RepositoryProvider<ReportsRepository>.value(
    value: repository,
    child: child,
  );
}

ReportPeriod _periodOf(GoRouterState state) {
  final q = state.uri.queryParameters;
  return ReportPeriod.fromQuery(q['from'], q['to'], DateTime.now());
}

void _backOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Báo cáo kho (BJ-15): 055 báo cáo + thẻ kho, 056, lãi gộp, nhập theo NCC.
/// Mọi màn nằm ngoài `StatefulShellRoute`, như `costingRoutes()`.
List<RouteBase> reportsRoutes({ReportsRepository? repository}) {
  return [
    GoRoute(
      path: '/warehouse/reports/stock',
      builder: (context, state) => _withRepository(
        repository,
        StockReportPage(
          initialPeriod: _periodOf(state),
          onBack: () => _backOr(context, '/warehouse'),
        ),
      ),
      routes: [
        GoRoute(
          path: ':productId',
          builder: (context, state) {
            final fromStock = state.uri.queryParameters['back'] == 'stock';
            return _withRepository(
              repository,
              StockCardPage(
                productId: state.pathParameters['productId']!,
                initialPeriod: _periodOf(state),
                fromStock: fromStock,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/warehouse/movements/:movementId',
      builder: (context, state) => _withRepository(
        repository,
        MovementDetailPage(
          movementId: state.pathParameters['movementId']!,
          onBack: () => _backOr(context, '/warehouse/reports/stock'),
        ),
      ),
    ),
    GoRoute(
      path: '/warehouse/reports/gross-profit',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] == 'ORDER'
            ? GrossProfitMode.order
            : GrossProfitMode.product;
        return _withRepository(
          repository,
          GrossProfitPage(
            initialPeriod: _periodOf(state),
            initialMode: mode,
            onBack: () => _backOr(context, '/warehouse'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/warehouse/reports/supplier-purchases',
      builder: (context, state) => _withRepository(
        repository,
        SupplierPurchasePage(
          initialPeriod: _periodOf(state),
          onBack: () => _backOr(context, '/warehouse'),
        ),
      ),
    ),
  ];
}
