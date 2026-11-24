import 'package:go_router/go_router.dart';

import '../../data/supplier_program/supplier_program_models.dart';
import '../supplier_rebate/rebate_record_page.dart';
import '../supplier_rebate/rebate_result_page.dart';
import 'program_detail_page.dart';
import 'program_form_page.dart';
import 'program_list_page.dart';

List<RouteBase> supplierProgramRoutes() => [
      GoRoute(
        path: '/warehouse/supplier-programs',
        name: 'warehouse.supplier_programs',
        builder: (context, state) {
          final statusRaw = state.uri.queryParameters['status'];
          final initialStatus = (statusRaw == null || statusRaw.isEmpty)
              ? null
              : ProgramStatus.fromJson(statusRaw.toUpperCase());
          return ProgramListPage(
            initialSupplierId: state.uri.queryParameters['supplierId'],
            initialStatus: initialStatus,
          );
        },
        routes: [
          GoRoute(
            path: 'new',
            name: 'warehouse.supplier_programs.new',
            builder: (context, state) => ProgramFormPage.create(
              supplierId: state.uri.queryParameters['supplierId'],
              productId: state.uri.queryParameters['productId'],
            ),
          ),
          GoRoute(
            path: ':programId',
            name: 'warehouse.supplier_programs.detail',
            builder: (context, state) {
              final programId = state.pathParameters['programId']!;
              return ProgramDetailPage(programId: programId);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'warehouse.supplier_programs.edit',
                builder: (context, state) {
                  final programId = state.pathParameters['programId']!;
                  return ProgramFormPage.edit(programId: programId);
                },
              ),
              GoRoute(
                path: 'rebate',
                name: 'warehouse.supplier_programs.rebate',
                builder: (context, state) {
                  final programId = state.pathParameters['programId']!;
                  return RebateRecordPage(programId: programId);
                },
              ),
              GoRoute(
                path: 'rebate/result',
                name: 'warehouse.supplier_programs.rebate_result',
                builder: (context, state) {
                  final programId = state.pathParameters['programId']!;
                  final previewInventoryTotal =
                      state.extra is int ? state.extra as int : null;
                  return RebateResultPage(
                    programId: programId,
                    previewInventoryTotal: previewInventoryTotal,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ];

