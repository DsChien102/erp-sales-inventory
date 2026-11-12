import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/data/costing/costing_repository.dart';
import 'package:erp/features/inventory/presentation/costing/cost_overview_page.dart';
import 'package:erp/features/inventory/presentation/costing/cost_result_page.dart';
import 'package:erp/features/inventory/presentation/costing/cost_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Widget _withRepository(CostingRepository? repository, Widget child) {
  if (repository == null) return child;
  return RepositoryProvider<CostingRepository>.value(
    value: repository,
    child: child,
  );
}

DateTime? _parseYearMonth(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return DateTime(year, month, 1);
}

List<RouteBase> costingRoutes({CostingRepository? repository}) {
  return [
    GoRoute(
      path: '/warehouse/costing',
      builder: (context, state) => _withRepository(
        repository,
        CostOverviewPage(
          onOpenRun: (row) {
            final path = row.status == CostRunStatus.published
                ? '/warehouse/costing/runs/${row.runId}/result'
                : '/warehouse/costing/runs/${row.runId}';
            context.push(path);
          },
          onCreateRunWithPeriod: (kind, period) {
            final periodParam = period != null
                ? '&period=${period.year}-${period.month.toString().padLeft(2, '0')}'
                : '';
            context.push('/warehouse/costing/new?kind=${kind.wire}$periodParam');
          },
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
            final kind = CostRunKind.fromWire(
              state.uri.queryParameters['kind'],
            );
            final initialPeriod = _parseYearMonth(
              state.uri.queryParameters['period'],
            );
            return _withRepository(
              repository,
              CostRunPage(
                kind: kind,
                initialPeriod: initialPeriod,
                onNavigate: (path) => context.go(path),
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/warehouse/costing');
                  }
                },
              ),
            );
          },
        ),
        GoRoute(
          path: 'runs/:runId',
          builder: (context, state) {
            final runId = state.pathParameters['runId']!;
            return _withRepository(
              repository,
              CostRunPage(
                runId: runId,
                kind: CostRunKind.midPeriod,
                onNavigate: (path) => context.go(path),
                onBack: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/warehouse/costing');
                  }
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'result',
              builder: (context, state) {
                final runId = state.pathParameters['runId']!;
                return _withRepository(
                  repository,
                  CostResultPage(
                    runId: runId,
                    onToList: () => context.go('/warehouse/costing'),
                    onBack: () => context.go('/warehouse/costing'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];
}

