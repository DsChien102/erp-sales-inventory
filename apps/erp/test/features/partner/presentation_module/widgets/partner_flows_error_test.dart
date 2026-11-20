// Bước 0 của 4-A (H14, H15, H16): widget / flow của partner trên code cũ.
// Ca "Q2": trước đây hiện chuỗi lỗi kỹ thuật thô, nay hiện câu theo TH-03 mục 6.4.
import 'package:erp/features/partner/presentation.dart';
import 'package:erp/features/partner/presentation/widgets/partner_detail_add_contact_flow.dart';
import 'package:erp/features/partner/presentation/widgets/partner_detail_soft_delete_flow.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/scripted_partner_repository.dart';

PartnerListItemDto _person(String id, String name) => PartnerListItemDto(
  partnerId: id,
  displayName: name,
  partnerType: PartnerType.person,
  status: PartnerStatus.active,
  roles: const [],
  phone: '0901234567',
);

PartnerDetailDto _detail({
  PartnerStatus status = PartnerStatus.active,
  List<PartnerAvailableAction> actions = const [PartnerAvailableAction.deactivate],
}) => PartnerDetailDto(
  partnerId: 'p-1',
  partnerType: PartnerType.person,
  status: status,
  displayName: 'Nguyễn Văn A',
  roles: const [PartnerRoleType.customer],
  availableActions: actions,
  expectedVersion: 4,
);

void main() {
  group('H14 PartnerContactSelectList', () {
    Future<ScriptedPartnerRepository> pump(
      WidgetTester tester, {
      required Object? Function(Map<String, Object?> args) onSearch,
      List<String> exclude = const [],
      void Function(List<Map<String, dynamic>>)? onSelect,
    }) async {
      final module = ScriptedPartnerRepository(onCall: (_, args) => onSearch(args));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerContactSelectList(
              repository: module,
              excludePersonPartnerIds: exclude,
              onSelect: onSelect ?? (_) {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return module;
    }

    testWidgets('tìm đúng tham số (cá nhân, đang hoạt động, 30, trang 1) và bỏ id loại trừ', (
      tester,
    ) async {
      final module = await pump(
        tester,
        exclude: const ['per-2'],
        onSearch: (_) => PartnerSearchResultDto(
          items: [_person('per-1', 'Trần Thị B'), _person('per-2', 'Lê Văn C')],
          page: 1,
          limit: 30,
          total: 2,
        ),
      );

      final args = module.invocations.single.args;
      expect(module.invocations.single.method, 'search');
      expect(args['partnerType'], PartnerType.person);
      expect(args['status'], PartnerStatus.active);
      expect(args['limit'], 30);
      expect(args['page'], 1);
      expect(args['query'], isNull);
      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Lê Văn C'), findsNothing);
    });

    testWidgets('Q2 — lỗi tìm hiện câu fallback, không có tiền tố "Lỗi: " và không lộ chuỗi thô', (
      tester,
    ) async {
      await pump(
        tester,
        onSearch: (_) => throw const AppException('X_UNKNOWN', serverMessage: 'chi tiết kỹ thuật'),
      );

      expect(
        find.text('Không tải được danh sách cá nhân. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.textContaining('chi tiết kỹ thuật'), findsNothing);
    });

    testWidgets('chọn rồi gõ tìm lại: giữ lựa chọn còn trong danh sách mới, debounce 300 ms', (
      tester,
    ) async {
      var calls = 0;
      final module = await pump(
        tester,
        onSearch: (args) {
          calls++;
          final q = args['query'];
          return PartnerSearchResultDto(
            items: q == 'Lan'
                ? [_person('per-3', 'Lan')]
                : [_person('per-1', 'Trần Thị B'), _person('per-3', 'Lan')],
            page: 1,
            limit: 30,
            total: 2,
          );
        },
      );
      expect(calls, 1);

      await tester.tap(find.text('Trần Thị B'));
      await tester.tap(find.text('Lan'));
      await tester.pump();
      expect(find.text('Chọn (2)'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_contact_select_search')), 'Lan');
      await tester.pump(const Duration(milliseconds: 299));
      expect(calls, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(module.invocations.last.args['query'], 'Lan');
      // per-1 không còn trong danh sách mới → bị bỏ khỏi lựa chọn.
      expect(find.text('Chọn (1)'), findsOneWidget);
    });
  });

  group('H15 runPartnerDetailAddContactFlow: chọn có sẵn', () {
    testWidgets('2 người → 2 lệnh thêm đúng thứ tự, rồi tải lại, rồi toast', (tester) async {
      final module = ScriptedPartnerRepository(
        onCall: (_, _) => const AddOrganizationContactResult(
          organizationPartnerId: 'org-1',
          personPartnerId: 'x',
        ),
      );
      var reloads = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => runPartnerDetailAddContactFlow(
                  context: context,
                  partnerId: 'org-1',
                  repository: module,
                  onReload: () async => reloads++,
                ),
                child: const Text('go'),
              ),
            ),
          ),
          GoRoute(
            path: '/partner/:id/contacts/select',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop([
                  {'personPartnerId': 'per-1', 'displayName': 'B'},
                  {'personPartnerId': 'per-2', 'displayName': 'C'},
                ]),
                child: const Text('pick'),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ cá nhân có sẵn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      final calls = module.callsOf('addContact').toList();
      expect(calls.map((c) => c.args['personPartnerId']), ['per-1', 'per-2']);
      expect(calls.every((c) => c.args['organizationPartnerId'] == 'org-1'), isTrue);
      expect(reloads, 1);
      expect(find.text('Thêm người liên hệ thành công'), findsOneWidget);
    });

    testWidgets(
      'G10 (4-B): người thứ 2 lỗi → tải lại, toast lỗi, không toast thành công, không ném',
      (tester) async {
        var addCalls = 0;
        final module = ScriptedPartnerRepository(
          onCall: (_, _) {
            addCalls++;
            if (addCalls == 2) throw const AppException('NO_PERMISSION');
            return const AddOrganizationContactResult(
              organizationPartnerId: 'org-1',
              personPartnerId: 'x',
            );
          },
        );
        var reloads = 0;
        Object? thrown;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    try {
                      await runPartnerDetailAddContactFlow(
                        context: context,
                        partnerId: 'org-1',
                        repository: module,
                        onReload: () async => reloads++,
                      );
                    } catch (e) {
                      thrown = e;
                    }
                  },
                  child: const Text('go'),
                ),
              ),
            ),
            GoRoute(
              path: '/partner/:id/contacts/select',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.pop([
                    {'personPartnerId': 'per-1', 'displayName': 'B'},
                    {'personPartnerId': 'per-2', 'displayName': 'C'},
                  ]),
                  child: const Text('pick'),
                ),
              ),
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chọn từ cá nhân có sẵn'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('pick'));
        await tester.pumpAndSettle();

        expect(thrown, isNull);
        expect(module.callsOf('addContact'), hasLength(2));
        expect(reloads, 1);
        expect(find.text('Bạn không có quyền quản lý người liên hệ.'), findsOneWidget);
        expect(find.text('Thêm người liên hệ thành công'), findsNothing);
      },
    );

    testWidgets('G10: mã lạ → câu fallback "Không thể thêm người liên hệ"', (tester) async {
      final module = ScriptedPartnerRepository(
        onCall: (_, _) => throw const AppException('X_UNKNOWN'),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => runPartnerDetailAddContactFlow(
                  context: context,
                  partnerId: 'org-1',
                  repository: module,
                  onReload: () async {},
                ),
                child: const Text('go'),
              ),
            ),
          ),
          GoRoute(
            path: '/partner/:id/contacts/select',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop([
                  {'personPartnerId': 'per-1', 'displayName': 'B'},
                ]),
                child: const Text('pick'),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ cá nhân có sẵn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(find.text('Không thể thêm người liên hệ. Vui lòng thử lại.'), findsOneWidget);
    });
  });

  group('H16 runPartnerDetailSoftDeleteFlow', () {
    Future<void> run(
      WidgetTester tester, {
      required ScriptedPartnerRepository module,
      PartnerDetailDto? dto,
    }) async {
      final statusCubit = PartnerStatusCubit(repository: module);
      addTearDown(statusCubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => runPartnerDetailSoftDeleteFlow(
                  context: context,
                  repository: module,
                  statusCubit: statusCubit,
                  dto: dto ?? _detail(),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('không đủ điều kiện → sheet chặn, có nút ngừng hoạt động', (tester) async {
      await run(
        tester,
        module: ScriptedPartnerRepository(
          onCall: (_, _) => const DeleteEligibilityDto(eligible: false),
        ),
      );

      expect(find.byKey(const Key('wgt_e02_u02_fr04_01')), findsOneWidget);
      expect(find.byKey(const Key('delete_blocked_deactivate')), findsOneWidget);
    });

    testWidgets('không đủ điều kiện, hồ sơ không còn active → sheet không có nút ngừng', (
      tester,
    ) async {
      await run(
        tester,
        module: ScriptedPartnerRepository(
          onCall: (_, _) => const DeleteEligibilityDto(eligible: false),
        ),
        dto: _detail(status: PartnerStatus.inactive),
      );

      expect(find.byKey(const Key('wgt_e02_u02_fr04_01')), findsOneWidget);
      expect(find.byKey(const Key('delete_blocked_deactivate')), findsNothing);
    });

    testWidgets('NO_PERMISSION → toast "Bạn không có quyền xóa hồ sơ."', (tester) async {
      await run(
        tester,
        module: ScriptedPartnerRepository(
          onCall: (_, _) => throw const AppException('NO_PERMISSION'),
        ),
      );

      expect(find.text('Bạn không có quyền xóa hồ sơ.'), findsOneWidget);
    });

    testWidgets('Q2 — mã lạ → toast fallback, không lộ chuỗi thô', (tester) async {
      await run(
        tester,
        module: ScriptedPartnerRepository(
          onCall: (_, _) =>
              throw const AppException('X_UNKNOWN', serverMessage: 'chi tiết kỹ thuật'),
        ),
      );

      expect(
        find.text('Không kiểm tra được điều kiện xóa. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('chi tiết kỹ thuật'), findsNothing);
    });

    testWidgets('lỗi khác → toast fallback', (tester) async {
      await run(
        tester,
        module: ScriptedPartnerRepository(onCall: (_, _) => throw Exception('socket')),
      );

      expect(
        find.text('Không kiểm tra được điều kiện xóa. Vui lòng thử lại.'),
        findsOneWidget,
      );
    });
  });
}
