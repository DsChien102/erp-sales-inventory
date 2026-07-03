import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _FakePartnerModule implements IPartnerModule {
  PartnerDetailDto? detailDto;
  PartnerTransactionHistoryResultDto? historyResultDto;
  bool shouldThrowOnHistory = false;
  GetPartnerTransactionHistoryQuery? lastHistoryQuery;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerDetailQuery) {
      final q = query as GetPartnerDetailQuery;
      if (detailDto != null) {
        return detailDto as TResult;
      }
      return PartnerDetailDto(
        id: q.partnerId,
        displayName: 'Test Partner',
        phone: '0912345678',
        roles: const {PartnerRole.customer},
        entityType: EntityType.individual,
        status: PartnerStatus.active,
        createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        version: 1,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      ) as TResult;
    }
    if (query is GetPartnerTransactionHistoryQuery) {
      final q = query as GetPartnerTransactionHistoryQuery;
      lastHistoryQuery = q;
      if (shouldThrowOnHistory) {
        throw Exception('Failed to load history');
      }
      if (historyResultDto != null) {
        return historyResultDto as TResult;
      }
      return PartnerTransactionHistoryResultDto(
        items: [],
        totalCount: 0,
      ) as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

void main() {
  late _FakePartnerModule partnerModule;
  late _FakeExecutionContext executionContext;

  setUp(() async {
    await getIt.reset();
    partnerModule = _FakePartnerModule();
    executionContext = _FakeExecutionContext();
    getIt
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IExecutionContext>(executionContext);
  });

  Widget createTestWidget({
    required String partnerId,
    PartnerItemModel? initialPartner,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PartnerDetailPage(
          partnerId: partnerId,
          initialPartner: initialPartner,
          canManageStatus: false,
          canDelete: false,
        ),
      ),
    );
  }

  group('FR-01: Mở lịch sử làm việc của đối tác', () {
    testWidgets('SCN-02: Mở lịch sử làm việc thành công', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();

      // Tap on "Lịch sử giao dịch" tab
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Verify transaction list contains our transaction
      expect(find.text('Đơn bán hàng'), findsOneWidget);
      expect(find.text('SO-2026-0001'), findsOneWidget);
      expect(find.text('Đã hoàn tất'), findsOneWidget);
    });

    testWidgets('SCN-05: Đối tác chưa có lịch sử làm việc', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [],
        totalCount: 0,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Chưa có lịch sử giao dịch'), findsOneWidget);
      expect(find.text('Các giao dịch phát sinh sẽ hiển thị tại đây.'), findsOneWidget);
    });

    testWidgets('SCN-06: Không tải được lịch sử làm việc', (tester) async {
      partnerModule.shouldThrowOnHistory = true;

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Verify error empty state
      expect(find.text('Không thể tải lịch sử giao dịch'), findsOneWidget);
    });
  });

  group('FR-02: Hiển thị danh sách lịch sử làm việc', () {
    testWidgets('SCN-01: Hiển thị danh sách và sắp xếp mặc định', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-2',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-02T10:00:00Z'),
            transactionCode: 'SO-2026-0002',
            amount: 250000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-2',
            ),
          ),
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
            ),
          ),
        ],
        totalCount: 2,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Both items shown
      expect(find.text('SO-2026-0001'), findsOneWidget);
      expect(find.text('SO-2026-0002'), findsOneWidget);
    });

    testWidgets('SCN-04 & SCN-06: Role badges and Read-only UI', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng & NCC',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Check role badge
      expect(find.text('Khách hàng'), findsWidgets); // One for tab content, one for item role badge possibly

      // Check read-only UI: Edit button is hidden when on transaction history tab
      expect(find.text('Chỉnh sửa'), findsNothing);
    });
  });

  group('FR-03: Lọc và tìm kiếm trong lịch sử làm việc', () {
    testWidgets('SCN-01: Tìm kiếm theo mã giao dịch', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [],
        totalCount: 0,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Enter search keyword
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'SO-2026');
      await tester.pumpAndSettle();

      // Verify cubit reload called with criteria keyword
      expect(partnerModule.lastHistoryQuery?.criteria.keyword, 'SO-2026');
    });

    testWidgets('SCN-03: Lọc loại giao dịch ẩn/hiện theo vai trò', (tester) async {
      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Tap filter button to open bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // For "Khách hàng", "Phiếu nhập hàng" must be hidden
      expect(find.text('Phiếu nhập hàng'), findsNothing);
      expect(find.text('Đơn bán hàng'), findsOneWidget);

      // Close filter sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('SCN-04: Lọc vai trò liên quan cho Khách hàng & NCC', (tester) async {
      partnerModule.detailDto = PartnerDetailDto(
        id: 'partner-1',
        displayName: 'Test Partner',
        phone: '0912345678',
        roles: const {PartnerRole.customer, PartnerRole.supplier},
        entityType: EntityType.individual,
        status: PartnerStatus.active,
        createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        version: 1,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng & NCC',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Verify "VAI TRÒ LIÊN QUAN" exists
      expect(find.text('VAI TRÒ LIÊN QUAN'), findsOneWidget);

      // Select "Nhà cung cấp" chip
      final supplierChip = find.text('Nhà cung cấp');
      expect(supplierChip, findsOneWidget);
      await tester.tap(supplierChip);
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(partnerModule.lastHistoryQuery?.criteria.transactionRole, PartnerRole.supplier);
    });

    testWidgets('SCN-08: Reset filters back to default state', (tester) async {
      partnerModule.detailDto = PartnerDetailDto(
        id: 'partner-1',
        displayName: 'Test Partner',
        phone: '0912345678',
        roles: const {PartnerRole.customer, PartnerRole.supplier},
        entityType: EntityType.individual,
        status: PartnerStatus.active,
        createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        version: 1,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng & NCC',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Tap Reset
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();

      // Expect default query
      expect(partnerModule.lastHistoryQuery?.criteria.transactionRole, isNull);
      expect(partnerModule.lastHistoryQuery?.criteria.transactionTypes, isNull);
    });
  });

  group('FR-04: Mở chi tiết giao dịch từ lịch sử', () {
    testWidgets('SCN-01: Mở chi tiết giao dịch nguồn thành công', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byType(PartnerTransactionItem));
      await tester.pump();

      // Check snackbar
      expect(find.textContaining('Đang mở chi tiết giao dịch: SO-2026-0001'), findsOneWidget);
    });

    testWidgets('SCN-02: Không có quyền xem chi tiết giao dịch nguồn', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
              requiredPermission: 'forbidden',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PartnerTransactionItem));
      await tester.pump();

      expect(find.text('Bạn không có quyền phù hợp để xem chi tiết giao dịch này.'), findsOneWidget);
    });

    testWidgets('SCN-03: Giao dịch nguồn không còn tồn tại', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'non-existent',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PartnerTransactionItem));
      await tester.pump();

      expect(find.text('Không tìm thấy giao dịch nguồn hoặc giao dịch đã bị xóa.'), findsOneWidget);
    });

    testWidgets('SCN-04: Giao dịch nguồn không thuộc tenant hiện tại', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'tenant-mismatch',
            ),
          )
        ],
        totalCount: 1,
      );

      await tester.pumpWidget(createTestWidget(
        partnerId: 'partner-1',
        initialPartner: const PartnerItemModel(
          id: 'partner-1',
          avatarText: 'TP',
          name: 'Test Partner',
          role: 'Khách hàng',
          status: 'Đang hoạt động',
          phone: '0912345678',
          email: '',
          taxId: '',
          updatedAt: '08:00 01/07/2026',
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lịch sử giao dịch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PartnerTransactionItem));
      await tester.pump();

      expect(find.text('Từ chối truy cập: Giao dịch không thuộc chi nhánh hiện tại.'), findsOneWidget);
    });
  });

  group('FR-05: Xử lý lịch sử khi trạng thái đối tác thay đổi', () {
    testWidgets('SCN-04: Xem lịch sử của đối tác đã xóa trong luồng được phép (isTraceFlow = true)', (tester) async {
      partnerModule.historyResultDto = PartnerTransactionHistoryResultDto(
        items: [
          PartnerTransactionHistoryItemDto(
            id: 'tx-1',
            partnerId: 'partner-1',
            transactionRole: 'customer',
            transactionType: 'sales',
            occurredAt: DateTime.parse('2026-07-01T10:00:00Z'),
            transactionCode: 'SO-2026-0001',
            amount: 150000.0,
            status: 'done',
            sourceNavigation: const PartnerTransactionSourceNavigationDto(
              sourceModule: 'sales',
              sourceType: 'sales_order',
              sourceId: 'so-1',
            ),
          )
        ],
        totalCount: 1,
      );

      // Render directly PartnerTransactionHistoryTab with isTraceFlow = true
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => PartnerDetailCubit(
              partnerModule: partnerModule,
              executionContext: executionContext,
            )..load('partner-1'),
            child: const PartnerTransactionHistoryTab(
              partner: PartnerItemModel(
                id: 'partner-1',
                avatarText: 'TP',
                name: 'Test Partner',
                role: 'Khách hàng',
                status: 'Đã xóa',
                phone: '0912345678',
                email: '',
                taxId: '',
                updatedAt: '08:00 01/07/2026',
              ),
              isTraceFlow: true,
            ),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // It should display the list item since isTraceFlow = true
      expect(find.text('SO-2026-0001'), findsOneWidget);
      expect(find.text('Hạn chế truy cập'), findsNothing);
    });

    testWidgets('SCN-05: Không hiển thị lịch sử của đối tác đã xóa ngoài luồng được phép (isTraceFlow = false)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => PartnerDetailCubit(
              partnerModule: partnerModule,
              executionContext: executionContext,
            )..load('partner-1'),
            child: const PartnerTransactionHistoryTab(
              partner: PartnerItemModel(
                id: 'partner-1',
                avatarText: 'TP',
                name: 'Test Partner',
                role: 'Khách hàng',
                status: 'Đã xóa',
                phone: '0912345678',
                email: '',
                taxId: '',
                updatedAt: '08:00 01/07/2026',
              ),
              isTraceFlow: false,
            ),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // It should display "Hạn chế truy cập" since isTraceFlow = false
      expect(find.text('Hạn chế truy cập'), findsOneWidget);
      expect(find.text('Không thể xem lịch sử giao dịch của đối tác đã bị xóa.'), findsOneWidget);
    });
  });
}
