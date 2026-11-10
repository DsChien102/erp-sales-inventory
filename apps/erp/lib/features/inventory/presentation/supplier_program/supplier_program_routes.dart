import 'package:go_router/go_router.dart';

import 'program_detail_page.dart';
import 'program_form_page.dart';
import 'program_list_page.dart';

List<RouteBase> supplierProgramRoutes() => [
      GoRoute(
        path: '/warehouse/supplier-programs',
        name: 'warehouse.supplier_programs',
        builder: (context, state) => ProgramListPage(
          initialSupplierId: state.uri.queryParameters['supplierId'],
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'warehouse.supplier_programs.new',
            builder: (context, state) => ProgramFormPage.create(
              supplierId: state.uri.queryParameters['supplierId'],
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
            ],
          ),
        ],
      ),
    ];

