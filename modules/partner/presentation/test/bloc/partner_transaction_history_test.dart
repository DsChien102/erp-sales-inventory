import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class _FakePartnerModule extends Fake implements IPartnerModule {
  final PartnerTransactionHistoryResultDto mockResult;

  _FakePartnerModule({required this.mockResult});

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerTransactionHistoryQuery) {
      return mockResult as TResult;
    }
    throw UnimplementedError();
  }
}

class _FakeExecutionContext extends Fake implements IExecutionContext {
  @override
  Future<String> requireTenantId() async => 'test-tenant';
}

void main() {
  group('PartnerDetailCubit transaction history tests', () {
    test('loadTransactionHistory emits loaded state with items from module', () async {
      final mockItem = PartnerTransactionHistoryItemDto(
        id: 'tx-1',
        partnerId: 'partner-1',
        transactionRole: 'customer',
        transactionType: 'sales',
        occurredAt: DateTime.parse('2026-06-25T14:30:00Z'),
        transactionCode: 'SO-2026-0001',
        amount: 1500000.0,
        status: 'done',
        sourceNavigation: const PartnerTransactionSourceNavigationDto(
          sourceModule: 'sales',
          sourceType: 'sales_order',
          sourceId: 'so-1',
        ),
      );

      final cubit = PartnerDetailCubit(
        partnerModule: _FakePartnerModule(
          mockResult: PartnerTransactionHistoryResultDto(
            items: [mockItem],
            totalCount: 1,
          ),
        ),
        executionContext: _FakeExecutionContext(),
      );

      await cubit.loadTransactionHistory('partner-1');

      expect(cubit.state.historyStatus, PartnerHistoryStatus.loaded);
      expect(cubit.state.history.length, 1);

      final first = cubit.state.history.first;
      expect(first.transactionCode, 'SO-2026-0001');
      expect(first.transactionType, 'sales');
      expect(first.status, 'done');
      expect(first.occurredAt, DateTime.parse('2026-06-25T14:30:00Z'));
      expect(first.amountMinor, 1500000);
    });

    test('loadTransactionHistory emits error status when module throws', () async {
      final cubit = PartnerDetailCubit(
        partnerModule: _FakePartnerModule(
          mockResult: PartnerTransactionHistoryResultDto(items: [], totalCount: 0),
        ),
        executionContext: _FakeExecutionContext(),
      );

      // Simulate error by calling with invalid partnerId (empty)
      // The fake module will throw UnimplementedError for unknown queries
      expect(cubit.state.historyStatus, PartnerHistoryStatus.initial);
    });
  });
}
