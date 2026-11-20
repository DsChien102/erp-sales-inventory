import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/provider_connection_cubit.dart';
import 'package:erp/features/einvoice/logic/provider_connection_state.dart';

import '../support/fake_einvoice_configuration_repository.dart';

class _SlowPollRepo extends FakeEInvoiceConfigurationRepository {
  _SlowPollRepo()
      : super(scenario: FakeEInvoiceConfigurationScenario.connectionScreenPending);

  final completer = Completer<void>();
  int getScreenCalls = 0;

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen() async {
    getScreenCalls++;
    calls.add('getConnectionScreen');
    if (getScreenCalls == 2) {
      await completer.future;
    }
    return FakeEInvoiceConfigurationFixtures.connectedScreen(
      status: ProviderConnectionStatus.checkRequired,
    );
  }
}

class _TestableProviderConnectionCubit extends ProviderConnectionCubit {
  _TestableProviderConnectionCubit(EInvoiceConfigurationRepository repo)
      : super(repository: repo);

  void testEmit(ProviderConnectionState s) => emit(s);
}

void main() {
  group('ProviderConnectionCubit', () {
    test('close cancels polling', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.connectionScreenPending,
      );
      final cubit = ProviderConnectionCubit(
        repository: repo,
        pollInterval: const Duration(milliseconds: 10),
      );

      await cubit.load();
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final count = repo.calls.where((c) => c == 'getConnectionScreen').length;
      expect(count, equals(1));
    });

    test('slow poll does not overlap', () async {
      final repo = _SlowPollRepo();
      final cubit = ProviderConnectionCubit(
        repository: repo,
        pollInterval: const Duration(milliseconds: 10),
      );

      await cubit.load();
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(repo.getScreenCalls, equals(2));

      repo.completer.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.getScreenCalls, greaterThanOrEqualTo(3));

      await cubit.close();
    });

    test('poll update keeps reconnect mode', () async {
      final repo = FakeEInvoiceConfigurationRepository();
      final cubit = _TestableProviderConnectionCubit(repo);

      cubit.testEmit(
        ProviderConnectionLoaded(
          screen: FakeEInvoiceConfigurationFixtures.connectedScreen(
            status: ProviderConnectionStatus.reconnectRequired,
          ),
          reconnectMode: true,
          accountError: 'x',
        ),
      );

      cubit.updateScreenFromQuery(
        FakeEInvoiceConfigurationFixtures.connectedScreen(
          status: ProviderConnectionStatus.checkRequired,
        ),
      );

      final state = cubit.state as ProviderConnectionLoaded;
      expect(state.reconnectMode, isTrue);
      expect(state.accountError, equals('x'));
      expect(state.screen.connection.status, equals(ProviderConnectionStatus.checkRequired));

      await cubit.close();
    });

    test('auth failed code maps to authFailed', () async {
      final repo = FakeEInvoiceConfigurationRepository(
        scenario: FakeEInvoiceConfigurationScenario.connectAuthFailed,
      );
      final cubit = ProviderConnectionCubit(repository: repo);
      await cubit.load();

      final result = await cubit.connect(account: 'ketoan@anphu.vn', password: 'bad');
      expect(result, equals(ProviderConnectionSubmitResult.authFailed));

      await cubit.close();
    });
  });
}
