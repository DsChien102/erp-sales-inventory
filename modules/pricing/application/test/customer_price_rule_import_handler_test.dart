import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';

void main() {
  late RecordingImportFilePort filePort;
  late RecordingImportGateway gateway;
  late GetCustomerPriceRuleImportTemplateQueryHandler templateHandler;
  late StartCustomerPriceRuleImportCommandHandler startHandler;
  late GetCustomerPriceRuleImportQueryHandler getHandler;
  late ConfirmCustomerPriceRuleImportCommandHandler confirmHandler;
  late CancelCustomerPriceRuleImportCommandHandler cancelHandler;

  setUp(() {
    filePort = RecordingImportFilePort();
    gateway = RecordingImportGateway();
    templateHandler = GetCustomerPriceRuleImportTemplateQueryHandler(
      filePort: filePort,
    );
    startHandler = StartCustomerPriceRuleImportCommandHandler(
      filePort: filePort,
      importGateway: gateway,
    );
    getHandler = GetCustomerPriceRuleImportQueryHandler(importGateway: gateway);
    confirmHandler = ConfirmCustomerPriceRuleImportCommandHandler(
      importGateway: gateway,
    );
    cancelHandler = CancelCustomerPriceRuleImportCommandHandler(
      importGateway: gateway,
    );
  });

  test('template handler delegates to file port', () async {
    final result = await templateHandler.handle(
      GetCustomerPriceRuleImportTemplateQuery(tenantId: 'tenant-1'),
    );

    expect(filePort.templateCalls, 1);
    expect(result.templateVersion, 'customer_price_rules_v1');
  });

  test(
    'start parses once then creates even for expected file failure',
    () async {
      filePort.nextParseResult = CustomerPriceRuleImportParseResult.failed([
        'EMPTY_FILE',
      ]);

      await startHandler.handle(_startCommand());

      expect(filePort.parseCalls, 1);
      expect(gateway.createCalls, 1);
      expect(gateway.lastParseResult?.fileErrorCodes, ['EMPTY_FILE']);
    },
  );

  test(
    'start maps parser technical failure to SYSTEM_ERROR without RPC',
    () async {
      filePort.throwOnParse = true;

      await expectLater(
        startHandler.handle(_startCommand()),
        throwsA(
          isA<PricingBlockedException>().having(
            (error) => error.code,
            'code',
            PricingBlockedCodes.systemError,
          ),
        ),
      );
      expect(gateway.createCalls, 0);
    },
  );

  test('get forwards filters to gateway', () async {
    await getHandler.handle(
      GetCustomerPriceRuleImportQuery(
        tenantId: 'tenant-1',
        importId: 'import-1',
        rowStatus: CustomerPriceRuleImportRowStatus.warning,
        cursor: 'cursor-1',
        limit: 25,
      ),
    );

    expect(gateway.lastGetRowStatus, CustomerPriceRuleImportRowStatus.warning);
    expect(gateway.lastGetCursor, 'cursor-1');
    expect(gateway.lastGetLimit, 25);
  });

  test(
    'confirm forwards normalized business date and acknowledgement',
    () async {
      await confirmHandler.handle(
        ConfirmCustomerPriceRuleImportCommand(
          tenantId: 'tenant-1',
          actorId: 'user-1',
          importId: 'import-1',
          expectedVersion: 2,
          businessDate: DateTime(2026, 7, 16, 15, 30),
          acknowledgeWarningRows: true,
        ),
      );

      expect(gateway.lastBusinessDate, DateTime.utc(2026, 7, 16));
      expect(gateway.lastAcknowledgeWarningRows, isTrue);
      expect(gateway.lastExpectedVersion, 2);
    },
  );

  test('cancel forwards optimistic version', () async {
    await cancelHandler.handle(
      CancelCustomerPriceRuleImportCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        importId: 'import-1',
        expectedVersion: 3,
      ),
    );

    expect(gateway.lastExpectedVersion, 3);
    expect(gateway.cancelCalls, 1);
  });
}

StartCustomerPriceRuleImportCommand _startCommand() =>
    StartCustomerPriceRuleImportCommand(
      tenantId: 'tenant-1',
      actorId: 'user-1',
      templateVersion: 'customer_price_rules_v1',
      originalFileName: 'customer_price_rules_v1.xlsx',
      fileBytes: Uint8List.fromList([1, 2, 3]),
      importMode: CustomerPriceRuleImportMode.upsert,
    );

final class RecordingImportFilePort
    implements ICustomerPriceRuleImportFilePort {
  int templateCalls = 0;
  int parseCalls = 0;
  bool throwOnParse = false;
  CustomerPriceRuleImportParseResult nextParseResult =
      const CustomerPriceRuleImportParseResult.parsed([]);

  @override
  CustomerPriceRuleImportTemplateDto createTemplateV1() {
    templateCalls++;
    return CustomerPriceRuleImportTemplateDto(
      templateVersion: 'customer_price_rules_v1',
      fileName: 'Mau_nho_gia.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: Uint8List(0),
    );
  }

  @override
  CustomerPriceRuleImportParseResult parse({
    required String templateVersion,
    required String originalFileName,
    required Uint8List bytes,
  }) {
    parseCalls++;
    if (throwOnParse) {
      throw StateError('parser exploded');
    }
    return nextParseResult;
  }
}

final class RecordingImportGateway implements ICustomerPriceRuleImportGateway {
  int createCalls = 0;
  int cancelCalls = 0;
  CustomerPriceRuleImportParseResult? lastParseResult;
  CustomerPriceRuleImportRowStatus? lastGetRowStatus;
  String? lastGetCursor;
  int? lastGetLimit;
  DateTime? lastBusinessDate;
  bool? lastAcknowledgeWarningRows;
  int? lastExpectedVersion;

  @override
  Future<CustomerPriceRuleImportDetailDto> create({
    required String tenantId,
    required String templateVersion,
    required String originalFileName,
    required CustomerPriceRuleImportMode importMode,
    required CustomerPriceRuleImportParseResult parseResult,
  }) async {
    createCalls++;
    lastParseResult = parseResult;
    return CustomerPriceRuleImportDetailDto(
      batch: CustomerPriceRuleImportDto(
        id: 'import-1',
        templateVersion: templateVersion,
        originalFileName: originalFileName,
        importMode: importMode,
        status: parseResult.isParsed
            ? CustomerPriceRuleImportStatus.readyToImport
            : CustomerPriceRuleImportStatus.failed,
        version: 1,
        totalRows: 0,
        validRows: 0,
        warningRows: 0,
        errorRows: 0,
        importedRows: 0,
        skippedRows: 0,
        failedRows: 0,
        fileErrorCodes: parseResult.fileErrorCodes,
        createdAt: DateTime.utc(2026, 7, 16),
      ),
      rows: const CursorPageDto(items: [], hasMore: false),
    );
  }

  @override
  Future<CustomerPriceRuleImportDto> cancel({
    required String tenantId,
    required String importId,
    required int expectedVersion,
  }) async {
    cancelCalls++;
    lastExpectedVersion = expectedVersion;
    return CustomerPriceRuleImportDto(
      id: importId,
      templateVersion: 'customer_price_rules_v1',
      originalFileName: 'customer_price_rules_v1.xlsx',
      importMode: CustomerPriceRuleImportMode.upsert,
      status: CustomerPriceRuleImportStatus.canceled,
      version: expectedVersion + 1,
      totalRows: 0,
      validRows: 0,
      warningRows: 0,
      errorRows: 0,
      importedRows: 0,
      skippedRows: 0,
      failedRows: 0,
      fileErrorCodes: const [],
      createdAt: DateTime.utc(2026, 7, 16),
      canceledAt: DateTime.utc(2026, 7, 16),
    );
  }

  @override
  Future<CustomerPriceRuleImportResultDto> confirm({
    required String tenantId,
    required String importId,
    required int expectedVersion,
    required DateTime businessDate,
    required bool acknowledgeWarningRows,
  }) async {
    lastExpectedVersion = expectedVersion;
    lastBusinessDate = businessDate;
    lastAcknowledgeWarningRows = acknowledgeWarningRows;
    return CustomerPriceRuleImportResultDto(
      batch: CustomerPriceRuleImportDto(
        id: importId,
        templateVersion: 'customer_price_rules_v1',
        originalFileName: 'customer_price_rules_v1.xlsx',
        importMode: CustomerPriceRuleImportMode.upsert,
        status: CustomerPriceRuleImportStatus.completed,
        version: expectedVersion + 1,
        totalRows: 1,
        validRows: 1,
        warningRows: 0,
        errorRows: 0,
        importedRows: 1,
        skippedRows: 0,
        failedRows: 0,
        fileErrorCodes: const [],
        createdAt: DateTime.utc(2026, 7, 16),
        confirmedAt: DateTime.utc(2026, 7, 16),
      ),
      processedAt: DateTime.utc(2026, 7, 16),
      isReplay: false,
    );
  }

  @override
  Future<CustomerPriceRuleImportDetailDto> get({
    required String tenantId,
    required String importId,
    required CustomerPriceRuleImportRowStatus? rowStatus,
    required String? cursor,
    required int limit,
  }) async {
    lastGetRowStatus = rowStatus;
    lastGetCursor = cursor;
    lastGetLimit = limit;
    return CustomerPriceRuleImportDetailDto(
      batch: CustomerPriceRuleImportDto(
        id: importId,
        templateVersion: 'customer_price_rules_v1',
        originalFileName: 'customer_price_rules_v1.xlsx',
        importMode: CustomerPriceRuleImportMode.upsert,
        status: CustomerPriceRuleImportStatus.readyToImport,
        version: 1,
        totalRows: 0,
        validRows: 0,
        warningRows: 0,
        errorRows: 0,
        importedRows: 0,
        skippedRows: 0,
        failedRows: 0,
        fileErrorCodes: const [],
        createdAt: DateTime.utc(2026, 7, 16),
      ),
      rows: const CursorPageDto(items: [], hasMore: false),
    );
  }
}
