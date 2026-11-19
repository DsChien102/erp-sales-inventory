import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../logic/receivable_list_cubit.dart';
import '../logic/receivable_permissions.dart';
import 'pages/customer_receivable_page.dart';
import 'pages/receivable_list_page.dart';
import 'receivable_area_shell.dart';
import 'widgets/receivable_parts.dart';

/// `/more/receivables[/:customerId]` — web hai cột, iPhone danh sách rồi push chi tiết.
List<RouteBase> receivableRoutes({required bool Function(String code) hasPermission}) => [
  ShellRoute(
    builder: (context, state, child) {
      if (!hasPermission(receivableViewPermission)) {
        return const Scaffold(
          appBar: VAppBar(title: 'Công nợ phải thu'),
          body: ReceivableEmpty(title: 'Bạn không có quyền thực hiện thao tác này.'),
        );
      }
      return ReceivableAreaShell(
        selectedId: state.pathParameters['customerId'],
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: '/more/receivables',
        name: 'receivable.list',
        builder: (context, state) {
          if (VListDetailLayout.isSplitOf(context)) return const ReceivablePickPlaceholder();
          return ReceivableListPage(cubit: context.read<ReceivableListCubit>());
        },
        routes: [
          GoRoute(
            path: ':customerId',
            name: 'receivable.customer',
            builder: (context, state) {
              final customerId = state.pathParameters['customerId']!;
              return CustomerReceivableDetailPage(key: ValueKey(customerId), customerId: customerId);
            },
          ),
        ],
      ),
    ],
  ),
];
