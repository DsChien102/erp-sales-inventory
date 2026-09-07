import 'package:async_query/async_query.dart';
import 'package:async_query_flutter/async_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_application/testing.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_einvoice_presentation/src/support/einvoice_query_keys.dart';
import 'package:vet45_shared_testing/shared_testing.dart';
import 'package:vet45_shared_application/application.dart';

final class _SequencedConnectionModule implements IEInvoiceModule {
  _SequencedConnectionModule(this.screens);

  final List<ProviderConnectionScreenDto> screens;
  int queryCount = 0;
  int verifyCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is VerifyProviderConnectionCommand) {
      final verifyCommand = command as VerifyProviderConnectionCommand;
      verifyCount += 1;
      return ProviderConnectionCheckResultDto(
            connectionId: verifyCommand.connectionId,
            status: ProviderConnectionStatus.connected,
            checkedAt: DateTime.utc(2026, 8, 30),
          )
          as TResult;
    }
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is! GetProviderConnectionScreenQuery) {
      throw UnimplementedError();
    }
    final screen = screens[queryCount < screens.length ? queryCount : screens.length - 1];
    queryCount += 1;
    return screen as TResult;
  }
}

ProviderConnectionScreenDto _screen(ProviderConnectionStatus status) {
  return ProviderConnectionScreenDto(
    legalProfile: const LegalProfileSummaryDto(
      legalName: 'Công ty An Phú',
      taxCode: '0101234567',
    ),
    connection: ProviderConnectionSummaryDto(
      connectionId: 'connection-1',
      status: status,
      maskedAccount: 'ke***@anphu.vn',
    ),
  );
}

void main() {
  Future<void> pumpConnection(
    WidgetTester tester, {
    required FakeEInvoiceScenario scenario,
    QueryClient? queryClient,
  }) async {
    final client = queryClient ?? QueryClient();
    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => ProviderConnectionCubit(
              einvoiceModule: FakeEInvoiceModule(scenario: scenario),
              executionContext: FakeExecutionContext(),
              queryClient: client,
            )..load(),
            child: const Scaffold(body: ProviderConnectionView()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'wgt_e01_u01_fr03_01: D04-A shows read-only seller info and credential form',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
      );

      expect(find.byKey(const Key('wgt_e01_u01_fr03_01')), findsOneWidget);
      expect(find.text('Thông tin kết nối'), findsOneWidget);
      expect(find.text('Nhà cung cấp'), findsOneWidget);
      expect(find.text('MISA meInvoice'), findsOneWidget);
      expect(find.text('Mã số thuế đơn vị phát hành'), findsOneWidget);
      expect(find.text('0101234567'), findsOneWidget);
      expect(
        find.text('Mã số thuế được lấy từ Hồ sơ pháp lý của Tổ chức.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tài khoản MISA', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Mật khẩu MISA', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mật khẩu được bảo mật và không hiển thị lại sau khi kết nối.',
        ),
        findsOneWidget,
      );
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Kết nối'), findsOneWidget);
      expect(find.text('App ID'), findsNothing);
      expect(find.text('Thao tác'), findsNothing);
    },
  );

  testWidgets(
    'wgt_e01_u01_fr02_01: D04-B shows connected info and Ngắt kết nối',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.configReadinessReady,
      );

      expect(find.byKey(const Key('wgt_e01_u01_fr02_01')), findsOneWidget);
      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('MISA meInvoice'), findsOneWidget);
      expect(find.text('ke***@anphu.vn'), findsOneWidget);
      expect(find.text('ketoan@anphu.vn'), findsNothing);
      expect(find.text('0101234567'), findsOneWidget);
      expect(find.text('Cập nhật gần nhất: 10:40, 05/08/2026'), findsOneWidget);
      expect(find.text('Ngắt kết nối'), findsOneWidget);
      expect(find.text('Thao tác'), findsNothing);
      expect(find.text('Kết nối lại'), findsNothing);
    },
  );

  testWidgets(
    'D04-C shows pending status, info banner, and Ngắt kết nối',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenPending,
      );

      expect(find.text('Chờ kết nối'), findsOneWidget);
      expect(find.text('Đang chờ kết nối'), findsOneWidget);
      expect(
        find.text(
          ProviderConnectionCopy.pendingBannerDescription,
        ),
        findsOneWidget,
      );
      expect(find.text('Ngắt kết nối'), findsOneWidget);
      expect(find.text('Kết nối lại'), findsNothing);
      expect(find.text('Tải lại trạng thái'), findsNothing);
      expect(find.text('Thao tác'), findsNothing);
      expect(find.byType(VLoading), findsOneWidget);
      expect(find.byType(VDivider), findsWidgets);
    },
  );

  testWidgets('pending status automatically polls and updates to connected state', (tester) async {
    final module = _SequencedConnectionModule([
      _screen(ProviderConnectionStatus.checkRequired),
      _screen(ProviderConnectionStatus.connected),
    ]);
    final client = QueryClient();

    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: BlocProvider(
            create: (_) => ProviderConnectionCubit(
              einvoiceModule: module,
              executionContext: FakeExecutionContext(),
              queryClient: client,
            )..load(),
            child: const Scaffold(body: ProviderConnectionView()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chờ kết nối'), findsOneWidget);
    expect(find.byType(VLoading), findsOneWidget);

    // Fast-forward 2 seconds for automatic refetch interval
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đã kết nối'), findsOneWidget);
    expect(find.byType(VLoading), findsNothing);
  });

  testWidgets(
    'D04-D shows error status, error banner, disconnect and reconnect',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenError,
      );

      expect(find.text('Lỗi kết nối'), findsOneWidget);
      expect(find.text('Không thể kết nối với MISA meInvoice'), findsOneWidget);
      expect(
        find.text(
          'Hãy kết nối lại để hệ thống thử lại bằng thông tin hiện có.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ngắt kết nối'), findsOneWidget);
      expect(find.text('Kết nối lại'), findsOneWidget);
      expect(find.text('Thao tác'), findsNothing);
    },
  );

  testWidgets(
    'D04-D Kết nối lại enters reconnect form (D04-A mode)',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenError,
      );

      await tester.tap(find.byKey(const Key('provider_connection_reconnect')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wgt_e01_u01_fr03_01')), findsOneWidget);
      expect(find.text('Kết nối lại'), findsOneWidget);
      expect(
        find.textContaining('Tài khoản MISA', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'D04-A submit without credentials shows required errors',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
      );

      await tester.tap(find.byKey(const Key('provider_connection_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tài khoản MISA'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu MISA'), findsOneWidget);
    },
  );

  testWidgets('connect shows worker-pending copy instead of connected success', (tester) async {
    await pumpConnection(
      tester,
      scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
    );

    await tester.enterText(
      find.widgetWithText(VTextField, 'Tài khoản MISA'),
      'ketoan@anphu.vn',
    );
    await tester.enterText(
      find.widgetWithText(VPasswordField, 'Mật khẩu MISA'),
      'secret',
    );
    await tester.tap(find.byKey(const Key('provider_connection_submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đang chờ kết nối'), findsOneWidget);
    expect(
      find.textContaining('Hệ thống đang tự động hoàn tất kết nối'),
      findsOneWidget,
    );
    expect(find.text('Đã kết nối MISA'), findsNothing);
    expect(find.text('Chờ kết nối'), findsOneWidget);
    expect(find.byType(VLoading), findsOneWidget);
  });

  testWidgets('connect sets query data and updates query cache', (tester) async {
    final client = QueryClient();
    await pumpConnection(
      tester,
      scenario: FakeEInvoiceScenario.connectionScreenDisconnected,
      queryClient: client,
    );

    await tester.enterText(
      find.widgetWithText(VTextField, 'Tài khoản MISA'),
      'ketoan@anphu.vn',
    );
    await tester.enterText(
      find.widgetWithText(VPasswordField, 'Mật khẩu MISA'),
      'secret',
    );
    await tester.tap(find.byKey(const Key('provider_connection_submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final cachedData = client.getQueryData<ProviderConnectionScreenDto>(
      EinvoiceQueryKeys.providerConnection('current-tenant'),
    );
    expect(cachedData, isNotNull);
    expect(cachedData!.connection.status, ProviderConnectionStatus.checkRequired);
    expect(cachedData.connection.maskedAccount, 'ke***@anphu.vn');
  });

  testWidgets(
    'connectPermissionDenied shows S01 on connection surface',
    (tester) async {
      await pumpConnection(
        tester,
        scenario: FakeEInvoiceScenario.connectPermissionDenied,
      );

      expect(find.byKey(const Key('wgt_e01_s01_01')), findsOneWidget);
      expect(find.text('Không có quyền truy cập'), findsOneWidget);
    },
  );
}
