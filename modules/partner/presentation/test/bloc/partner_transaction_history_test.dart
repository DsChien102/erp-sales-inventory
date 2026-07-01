import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class _FakePartnerModule extends Fake implements IPartnerModule {}
class _FakeExecutionContext extends Fake implements IExecutionContext {}

void main() {
  late String jsonFixture;

  setUpAll(() {
    final pathsToTry = [
      'test/bloc/transactions_fixture.json',
      'modules/partner/presentation/test/bloc/transactions_fixture.json',
    ];
    File? file;
    for (final path in pathsToTry) {
      final f = File(path);
      if (f.existsSync()) {
        file = f;
        break;
      }
    }
    if (file == null) {
      throw Exception(
        'Could not find transactions_fixture.json in paths: $pathsToTry. Current working dir: ${Directory.current.path}',
      );
    }
    jsonFixture = file.readAsStringSync();
  });

  group('PartnerDetailCubit & DTO Parsing Tests', () {
    test('loads transactions from JSON successfully and maps old format fields correctly', () {
      final cubit = PartnerDetailCubit(
        partnerModule: _FakePartnerModule(),
        executionContext: _FakeExecutionContext(),
      );
      cubit.loadTransactionsFromJson(jsonFixture);

      expect(cubit.state.historyStatus, PartnerHistoryStatus.loaded);
      expect(cubit.state.history.length, 6);

      // Verify first item
      final first = cubit.state.history.first;
      expect(first.transactionCode, 'SO-2026-0001');
      expect(first.transactionType, 'Đơn bán hàng');
      expect(first.status, 'Đã hoàn tất');
      expect(first.occurredAt, DateTime.parse('2026-06-25T14:30:00Z'));
      expect(first.amountMinor, 1500000);

      // Verify null/empty amount parsing
      final emptyAmountTx = cubit.state.history[5];
      expect(emptyAmountTx.transactionCode, 'SO-2026-0005');
      expect(emptyAmountTx.amountMinor, null);
    });

    test('handles invalid JSON gracefully by emitting error status', () {
      final cubit = PartnerDetailCubit(
        partnerModule: _FakePartnerModule(),
        executionContext: _FakeExecutionContext(),
      );
      cubit.loadTransactionsFromJson('{ invalid json }');
      expect(cubit.state.historyStatus, PartnerHistoryStatus.error);
    });
  });
}
