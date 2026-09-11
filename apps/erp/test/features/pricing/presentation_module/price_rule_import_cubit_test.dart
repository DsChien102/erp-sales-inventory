import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_application/testing.dart';
import 'package:erp/features/pricing/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  test('startImport sends the canonical V1 template version', () async {
    final module = _RecordingImportModule();
    final cubit = PriceRuleImportCubit(
      pricingModule: module,
      executionContext: FakeExecutionContext(
        tenantId: 'tenant-1',
        userId: 'user-1',
      ),
    );
    addTearDown(cubit.close);

    await cubit.startImport(
      fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
      fileBytes: Uint8List.fromList(const [0x50, 0x4B]),
    );

    expect(
      module.lastStartCommand?.templateVersion,
      CustomerPriceRuleImportTemplateDto.versionV1,
    );
  });

  test(
    'loadTemplate queries with the current tenant and returns bytes',
    () async {
      final module = _RecordingImportModule();
      final cubit = _createCubit(module);
      addTearDown(cubit.close);

      final template = await cubit.loadTemplate();

      expect(module.lastTemplateQuery?.tenantId, 'tenant-1');
      expect(
        template.templateVersion,
        CustomerPriceRuleImportTemplateDto.versionV1,
      );
      expect(template.fileName, CustomerPriceRuleImportTemplateDto.fileNameV1);
      expect(
        template.bytes,
        Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
      );
    },
  );

  test(
    'cancelCurrentImport sends batch id/version and resets on success',
    () async {
      final module = _RecordingImportModule();
      final cubit = _createCubit(module);
      addTearDown(cubit.close);
      await _startImport(cubit);

      expect(cubit.hasCancelableBatch, isTrue);
      final errorCode = await cubit.cancelCurrentImport();

      expect(errorCode, isNull);
      expect(module.lastCancelCommand?.importId, 'import-1');
      expect(module.lastCancelCommand?.expectedVersion, 1);
      expect(module.lastCancelCommand?.tenantId, 'tenant-1');
      expect(cubit.state, isA<PriceRuleImportInitial>());
      expect(cubit.hasCancelableBatch, isFalse);
    },
  );

  test(
    'cancelCurrentImport preserves preview when cancel is blocked',
    () async {
      final module = _RecordingImportModule(
        cancelError: const PricingBlockedException(
          PricingBlockedCodes.stateChanged,
        ),
      );
      final cubit = _createCubit(module);
      addTearDown(cubit.close);
      await _startImport(cubit);
      final preview = cubit.state;

      final errorCode = await cubit.cancelCurrentImport();

      expect(errorCode, PricingBlockedCodes.stateChanged);
      expect(cubit.state, same(preview));
      expect(cubit.hasCancelableBatch, isTrue);
    },
  );

  test(
    'failed file exposes its file-level error and is not cancelable',
    () async {
      final module = _RecordingImportModule(
        startScenario: FakePricingScenario.importFailedBadFile,
      );
      final cubit = _createCubit(module);
      addTearDown(cubit.close);

      await _startImport(cubit);

      expect(
        cubit.state,
        isA<PriceRuleImportError>().having(
          (state) => state.code,
          'code',
          'TEMPLATE_HEADER_INVALID',
        ),
      );
      expect(cubit.hasCancelableBatch, isFalse);
    },
  );

  test('selectFile keeps pending bytes until continueWithSelectedFile', () async {
    final module = _RecordingImportModule();
    final cubit = _createCubit(module);
    addTearDown(cubit.close);

    cubit.selectFile(
      fileName: 'demo.xlsx',
      fileBytes: Uint8List.fromList(const [1, 2, 3]),
    );

    expect(
      cubit.state,
      isA<PriceRuleImportFileSelected>()
          .having((s) => s.fileName, 'fileName', 'demo.xlsx')
          .having((s) => s.fileSizeBytes, 'fileSizeBytes', 3),
    );
    expect(module.lastStartCommand, isNull);

    await cubit.continueWithSelectedFile();

    expect(module.lastStartCommand?.originalFileName, 'demo.xlsx');
    expect(cubit.state, isA<PriceRuleImportPreview>());
  });

  test('checkAccess emits NoPermission when template is denied', () async {
    final module = _RecordingImportModule(
      templateError: const PricingBlockedException(
        PricingBlockedCodes.noPermission,
      ),
    );
    final cubit = _createCubit(module);
    addTearDown(cubit.close);

    await cubit.checkAccess();

    expect(cubit.state, isA<PriceRuleImportNoPermission>());
  });

  test('reopenPreviewFromResult opens read-only then backToResult', () async {
    final module = _RecordingImportModule(
      confirmScenario: FakePricingScenario.importConfirmPartial,
    );
    final cubit = _createCubit(module);
    addTearDown(cubit.close);
    await _startImport(cubit);
    cubit.proceedToConfirm();
    await cubit.confirmImport(acknowledgeWarningRows: true);

    expect(cubit.state, isA<PriceRuleImportResult>());

    cubit.reopenPreviewFromResult(tab: PriceRuleImportPreviewTab.error);
    final preview = cubit.state;
    expect(
      preview,
      isA<PriceRuleImportPreview>()
          .having((s) => s.readOnly, 'readOnly', isTrue)
          .having(
            (s) => s.initialTab,
            'initialTab',
            PriceRuleImportPreviewTab.error,
          ),
    );

    cubit.backToResult();
    expect(cubit.state, isA<PriceRuleImportResult>());
  });

  test('setImportMode keeps confirm and refreshes under the same step', () async {
    final module = _RecordingImportModule();
    final cubit = _createCubit(module);
    addTearDown(cubit.close);
    await _startImport(cubit);
    cubit.proceedToConfirm();

    expect(cubit.state, isA<PriceRuleImportConfirm>());
    expect(
      module.lastStartCommand?.importMode,
      CustomerPriceRuleImportMode.upsert,
    );

    final future = cubit.setImportMode(CustomerPriceRuleImportMode.createOnly);
    expect(
      cubit.state,
      isA<PriceRuleImportConfirm>().having(
        (s) => s.isRefreshingMode,
        'isRefreshingMode',
        isTrue,
      ),
    );

    await future;

    expect(
      module.lastStartCommand?.importMode,
      CustomerPriceRuleImportMode.createOnly,
    );
    expect(module.lastCancelCommand, isNotNull);
    expect(
      cubit.state,
      isA<PriceRuleImportConfirm>().having(
        (s) => s.isRefreshingMode,
        'isRefreshingMode',
        isFalse,
      ),
    );
    expect(cubit.importMode, CustomerPriceRuleImportMode.createOnly);
  });
}

PriceRuleImportCubit _createCubit(_RecordingImportModule module) =>
    PriceRuleImportCubit(
      pricingModule: module,
      executionContext: FakeExecutionContext(
        tenantId: 'tenant-1',
        userId: 'user-1',
      ),
    );

Future<void> _startImport(PriceRuleImportCubit cubit) => cubit.startImport(
  fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
  fileBytes: Uint8List.fromList(const [0x50, 0x4B]),
);

final class _RecordingImportModule implements IPricingModule {
  _RecordingImportModule({
    this.startScenario = FakePricingScenario.importReadyMixed,
    this.confirmScenario = FakePricingScenario.importConfirmPartial,
    this.cancelError,
    this.templateError,
  });

  final FakePricingScenario startScenario;
  final FakePricingScenario confirmScenario;
  final PricingBlockedException? cancelError;
  final PricingBlockedException? templateError;
  StartCustomerPriceRuleImportCommand? lastStartCommand;
  CancelCustomerPriceRuleImportCommand? lastCancelCommand;
  GetCustomerPriceRuleImportTemplateQuery? lastTemplateQuery;

  @override
  Future<TResult> executeCommandAsync<TResult>(
    ICommand<TResult> command,
  ) async {
    if (command is StartCustomerPriceRuleImportCommand) {
      final startCommand = command as StartCustomerPriceRuleImportCommand;
      lastStartCommand = startCommand;
      final result = await FakePricingModule(
        scenario: startScenario,
      ).executeCommandAsync<CustomerPriceRuleImportDetailDto>(startCommand);
      return result as TResult;
    }
    if (command is ConfirmCustomerPriceRuleImportCommand) {
      final confirmCommand = command as ConfirmCustomerPriceRuleImportCommand;
      final result = await FakePricingModule(
        scenario: confirmScenario,
      ).executeCommandAsync<CustomerPriceRuleImportResultDto>(confirmCommand);
      return result as TResult;
    }
    if (command is CancelCustomerPriceRuleImportCommand) {
      final cancelCommand = command as CancelCustomerPriceRuleImportCommand;
      lastCancelCommand = cancelCommand;
      final error = cancelError;
      if (error != null) throw error;
      final result = await FakePricingModule(
        scenario: FakePricingScenario.importCancelOk,
      ).executeCommandAsync<CustomerPriceRuleImportDto>(cancelCommand);
      return result as TResult;
    }
    throw UnsupportedError('Unsupported command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetCustomerPriceRuleImportTemplateQuery) {
      final templateQuery = query as GetCustomerPriceRuleImportTemplateQuery;
      lastTemplateQuery = templateQuery;
      final error = templateError;
      if (error != null) throw error;
      final result = await FakePricingModule(
        scenario: FakePricingScenario.importTemplateV1,
      ).executeQueryAsync<CustomerPriceRuleImportTemplateDto>(templateQuery);
      return result as TResult;
    }
    throw UnsupportedError('Unsupported query ${query.runtimeType}');
  }
}
