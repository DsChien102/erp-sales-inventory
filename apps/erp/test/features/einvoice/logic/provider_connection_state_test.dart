import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/provider_connection_state.dart';

void main() {
  test('masked account and version participate in loaded-state equality', () {
    ProviderConnectionLoaded state(String account, int version) => ProviderConnectionLoaded(
          screen: ProviderConnectionScreenDto(
            legalProfile: const LegalProfileSummaryDto(
              legalName: 'Công ty An Phú',
              taxCode: '0101234567',
            ),
            connection: ProviderConnectionSummaryDto(
              connectionId: 'connection-1',
              status: ProviderConnectionStatus.connected,
              maskedAccount: account,
              connectionVersion: version,
            ),
          ),
        );

    expect(state('ac***@example.vn', 1), isNot(state('ke***@example.vn', 2)));
  });
}
