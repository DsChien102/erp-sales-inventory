import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_count_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_create_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_list_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_recount_page.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Widget _withRepository(StocktakeRepository? repository, Widget child) {
  if (repository == null) return child;
  return RepositoryProvider<StocktakeRepository>.value(
    value: repository,
    child: child,
  );
}

List<RouteBase> stocktakeRoutes({StocktakeRepository? repository}) {
  void backToList(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse/stocktakes');
    }
  }

  return [
    GoRoute(
      path: '/warehouse/stocktakes',
      builder: (context, state) => _withRepository(
        repository,
        StocktakeListPage(
          onOpen: (row) => context.push(stocktakeRouteFor(row.id, row.status)),
          onCreate: () => context.push('/warehouse/stocktakes/new'),
          onBack: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/warehouse');
            }
          },
        ),
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) {
            final productId = state.uri.queryParameters['productId'];
            final lotId = state.uri.queryParameters['lotId'];
            return _withRepository(
              repository,
              StocktakeCreatePage(
                initialProductId: productId,
                initialLotId: lotId,
                onOpened: (id) => context.go('/warehouse/stocktakes/$id/count'),
                onOpenConflict: (id, status) =>
                    context.go(stocktakeRouteFor(id, status)),
                onBack: () => backToList(context),
              ),
            );
          },
        ),
        GoRoute(
          path: ':sessionId/count',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return _withRepository(
              repository,
              StocktakeCountPage(
                sessionId: sessionId,
                onNavigate: (id, status) =>
                    context.go(stocktakeRouteFor(id, status)),
                onBackToList: () => backToList(context),
              ),
            );
          },
        ),
        GoRoute(
          path: ':sessionId/recount',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return _withRepository(
              repository,
              StocktakeRecountPage(
                sessionId: sessionId,
                onNavigate: (id, status) =>
                    context.go(stocktakeRouteFor(id, status)),
                onBackToList: () => backToList(context),
              ),
            );
          },
        ),
        GoRoute(
          path: ':sessionId/result',
          builder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return _withRepository(
              repository,
              StocktakeResultPage(
                sessionId: sessionId,
                onBackToList: () => context.go('/warehouse/stocktakes'),
                onViewStock: () => context.go('/warehouse/stock'),
              ),
            );
          },
        ),
      ],
    ),
  ];
}

