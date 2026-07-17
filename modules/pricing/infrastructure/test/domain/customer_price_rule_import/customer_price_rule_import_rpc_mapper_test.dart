import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_infrastructure/infrastructure.dart';

void main() {
  test('create params use exact RPC keys and snake-case enums', () {
    final params = CustomerPriceRuleImportRpcMapper.createParams(
      tenantId: 'tenant-1',
      templateVersion: 'customer_price_rules_v1',
      originalFileName: 'customer_price_rules_v1.xlsx',
      importMode: CustomerPriceRuleImportMode.createOnly,
      parseResult: const CustomerPriceRuleImportParseResult.parsed([
        CustomerPriceRuleImportParsedRow(
          rowNumber: 2,
          customerId: '00000000-0000-4000-8000-000000000001',
          productReferenceId: 'VAC-001',
          price: '90000',
        ),
      ]),
    );

    expect(params.keys, [
      'p_tenant_id',
      'p_template_version',
      'p_original_file_name',
      'p_import_mode',
      'p_parse_result',
    ]);
    expect(params['p_import_mode'], 'create_only');
    final parseResult = params['p_parse_result'] as Map;
    expect(parseResult['kind'], 'parsed');
    expect((parseResult['rows'] as List).single['row_number'], 2);
  });

  test('get params allow null cursor and row status', () {
    final params = CustomerPriceRuleImportRpcMapper.getParams(
      tenantId: 'tenant-1',
      importId: 'import-1',
      rowStatus: null,
      cursor: null,
      limit: 50,
    );

    expect(params['p_row_status'], isNull);
    expect(params['p_cursor'], isNull);
    expect(params['p_limit'], 50);
  });

  test('confirm params serialize date-only business date', () {
    final params = CustomerPriceRuleImportRpcMapper.confirmParams(
      tenantId: 'tenant-1',
      importId: 'import-1',
      expectedVersion: 2,
      businessDate: DateTime.utc(2026, 7, 16, 19, 0),
      acknowledgeWarningRows: false,
    );

    expect(params['p_business_date'], '2026-07-16');
    expect(params['p_acknowledge_warning_rows'], isFalse);
  });

  test(
    'detail mapper maps counters, replay flag, and optional redacted fields',
    () {
      final detail = CustomerPriceRuleImportRpcMapper.detailFromJson({
        'batch': {
          'id': 'import-1',
          'template_version': 'customer_price_rules_v1',
          'original_file_name': 'customer_price_rules_v1.xlsx',
          'import_mode': 'upsert',
          'status': 'ready_to_import',
          'version': 1,
          'total_rows': 1,
          'valid_rows': 1,
          'warning_rows': 0,
          'error_rows': 0,
          'imported_rows': 0,
          'skipped_rows': 0,
          'failed_rows': 0,
          'file_error_codes': [],
          'created_at': '2026-07-16T10:00:00Z',
        },
        'rows': {
          'items': [
            {
              'id': 'row-1',
              'row_number': 2,
              'status': 'warning',
              'action': 'create',
              'error_codes': [],
              'warning_codes': ['BELOW_FLOOR_PRICE'],
              'unit_resolution_strategy': 'default_selling_unit',
              'customer_snapshot': {
                'customer_id': 'customer-1',
                'display_name': 'Clinic A',
              },
              'product_snapshot': {
                'product_id': 'product-1',
                'product_name': 'Vaccine',
              },
              'unit_snapshot': {
                'product_unit_id': 'unit-1',
                'unit_name': 'Dose',
              },
            },
          ],
          'has_more': false,
        },
      });
      final result = CustomerPriceRuleImportRpcMapper.resultFromJson({
        'batch': {
          'id': 'import-1',
          'template_version': 'customer_price_rules_v1',
          'original_file_name': 'customer_price_rules_v1.xlsx',
          'import_mode': 'upsert',
          'status': 'completed',
          'version': 2,
          'total_rows': 1,
          'valid_rows': 1,
          'warning_rows': 0,
          'error_rows': 0,
          'imported_rows': 1,
          'skipped_rows': 0,
          'failed_rows': 0,
          'file_error_codes': [],
          'created_at': '2026-07-16T10:00:00Z',
          'confirmed_at': '2026-07-16T11:00:00Z',
        },
        'processed_at': '2026-07-16T11:00:00Z',
        'is_replay': true,
      });

      expect(detail.batch.status, CustomerPriceRuleImportStatus.readyToImport);
      expect(
        detail.rows.items.single.unitResolutionStrategy,
        ProductUnitResolutionStrategy.defaultSellingUnit,
      );
      expect(
        detail.rows.items.single.customerSnapshot?['display_name'],
        'Clinic A',
      );
      expect(
        detail.rows.items.single.productSnapshot?['floor_price_minor'],
        isNull,
      );
      expect(detail.rows.items.single.unitSnapshot?['unit_name'], 'Dose');
      expect(result.isReplay, isTrue);
    },
  );

  test('malformed payload maps to FormatException', () {
    expect(
      () => CustomerPriceRuleImportRpcMapper.batchFromJson({'id': ''}),
      throwsFormatException,
    );
  });
}
