import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_cubit.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_state.dart';

import '../support/fake_einvoice_configuration_repository.dart';

class _CustomErrorIssuanceRepo extends FakeEInvoiceConfigurationRepository {
  _CustomErrorIssuanceRepo({required this.errorToThrow});

  final Object errorToThrow;
  String? lastSigningConfigId;
  String? lastTemplateId;

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) async {
    calls.add('setDefaultConfiguration');
    lastTemplateId = templateId;
    lastSigningConfigId = signingConfigId;
    throw einvoiceException(errorToThrow);
  }
}

class _SigningCaptureRepo extends FakeEInvoiceConfigurationRepository {
  String? capturedSigningConfigId;
  String? capturedTemplateId;

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) async {
    calls.add('setDefaultConfiguration');
    capturedTemplateId = templateId;
    capturedSigningConfigId = signingConfigId;
    return FakeEInvoiceConfigurationFixtures.issuanceProfile;
  }
}

class _ConnectionOverrideRepo extends FakeEInvoiceConfigurationRepository {
  _ConnectionOverrideRepo({this.failure});

  final Object? failure;

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen() async {
    calls.add('getConnectionScreen');
    if (failure != null) {
      throw failure!;
    }
    final base = FakeEInvoiceConfigurationFixtures.connectedScreen();
    return ProviderConnectionScreenDto(
      legalProfile: base.legalProfile,
      connection: ProviderConnectionSummaryDto(
        connectionId: base.connection.connectionId,
        status: base.connection.status,
        lastCheckedAt: null,
        maskedAccount: base.connection.maskedAccount,
        connectionVersion: base.connection.connectionVersion,
      ),
    );
  }
}

void main() {
  group('DefaultIssuanceConfigurationCubit last synced', () {
    test('load reads connection after profile and templates', () async {
      final repo = FakeEInvoiceConfigurationRepository();
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();
      expect(repo.calls, ['getIssuanceProfile', 'listTemplates', 'getConnectionScreen']);
      final state = cubit.state as DefaultIssuanceConfigurationLoaded;
      expect(
        state.lastSyncedAt,
        FakeEInvoiceConfigurationFixtures.connectedScreen().connection.lastCheckedAt,
      );
      await cubit.close();
    });

    test('connection read failure hides synced line', () async {
      final repo = _ConnectionOverrideRepo(
        failure: const AppException(EInvoiceErrorCodes.systemError),
      );
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();
      final state = cubit.state as DefaultIssuanceConfigurationLoaded;
      expect(state.lastSyncedAt, isNull);
      await cubit.close();
    });

    test('lastCheckedAt null keeps line hidden', () async {
      final cubit = DefaultIssuanceConfigurationCubit(
        repository: _ConnectionOverrideRepo(),
      );
      await cubit.load();
      expect((cubit.state as DefaultIssuanceConfigurationLoaded).lastSyncedAt, isNull);
      await cubit.close();
    });

    test('select and save keep lastSyncedAt', () async {
      final cubit = DefaultIssuanceConfigurationCubit(
        repository: FakeEInvoiceConfigurationRepository(),
      );
      await cubit.load();
      final before = (cubit.state as DefaultIssuanceConfigurationLoaded).lastSyncedAt;
      expect(before, isNotNull);
      cubit.selectTemplate('tpl-2');
      expect((cubit.state as DefaultIssuanceConfigurationLoaded).lastSyncedAt, before);
      await cubit.save();
      expect((cubit.state as DefaultIssuanceConfigurationLoaded).lastSyncedAt, before);
      await cubit.close();
    });
  });

  group('DefaultIssuanceConfigurationCubit', () {
    test('server template error shows incompatible', () async {
      final repo = _CustomErrorIssuanceRepo(
        errorToThrow: AppException(
          'SYSTEM_ERROR',
          cause: const PostgrestException(
            message: 'TEMPLATE_NOT_AVAILABLE: template has no invoice series',
            code: 'P0001',
          ),
        ),
      );
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(DefaultIssuanceSaveResult.incompatible));

      await cubit.close();
    });

    test('SIGNING_CONFIGURATION_NOT_AVAILABLE shows incompatible', () async {
      final repo = _CustomErrorIssuanceRepo(
        errorToThrow: const AppException(EInvoiceErrorCodes.signingConfigurationNotAvailable),
      );
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(DefaultIssuanceSaveResult.incompatible));

      await cubit.close();
    });

    test('setDefaultNotConnected only on setDefaultConfiguration maps to notConnected', () async {
      final repo = _CustomErrorIssuanceRepo(
        errorToThrow: const AppException(EInvoiceErrorCodes.providerNotConnected),
      );
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(DefaultIssuanceSaveResult.notConnected));

      await cubit.close();
    });

    test('STATE_CHANGED maps to failed', () async {
      final repo = _CustomErrorIssuanceRepo(
        errorToThrow: const AppException(EInvoiceErrorCodes.stateChanged),
      );
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();

      final result = await cubit.save();
      expect(result, equals(DefaultIssuanceSaveResult.failed));

      await cubit.close();
    });

    test('signing id uses sign-nosign for MTT and sign-hsm for non-MTT', () async {
      final repo = _SigningCaptureRepo();
      final cubit = DefaultIssuanceConfigurationCubit(repository: repo);
      await cubit.load();

      // Non-MTT template ('tpl-1')
      cubit.selectTemplate('tpl-1');
      await cubit.save();
      expect(repo.capturedSigningConfigId, equals('sign-hsm'));

      // MTT template ('tpl-mtt')
      cubit.selectTemplate('tpl-mtt');
      await cubit.save();
      expect(repo.capturedSigningConfigId, equals('sign-nosign'));

      await cubit.close();
    });
  });
}
