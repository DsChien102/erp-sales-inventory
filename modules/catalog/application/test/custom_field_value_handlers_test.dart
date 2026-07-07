import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCustomFieldValueGateway implements ICatalogCustomFieldValueGateway {
  String? lastTenantId;
  String? lastProductId;
  bool? lastIncludeInactiveValues;
  UpsertCustomFieldValuesCommand? lastCommand;

  ProductCustomFieldValuesDto valuesResult = const ProductCustomFieldValuesDto(
    productId: 'product-1',
    groups: [
      ProductCustomFieldValueGroupDto(
        groupId: 'group-1',
        name: 'Thông tin thuốc',
        fields: [
          ProductCustomFieldValueFieldDto(
            fieldId: 'field-1',
            groupId: 'group-1',
            name: 'Thành phần',
            fieldType: 'text',
            displayValue: 'Vitamin A',
          ),
        ],
      ),
    ],
  );

  UpsertCustomFieldValuesResult upsertResult = UpsertCustomFieldValuesResult(
    productId: 'product-1',
    values: const ProductCustomFieldValuesDto(productId: 'product-1'),
    readinessSummary: const ReadinessSummaryDto(
      status: ReadinessStatus.readyToSell,
    ),
  );

  @override
  Future<ProductCustomFieldValuesDto> getValues({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    lastIncludeInactiveValues = includeInactiveValues;
    return valuesResult;
  }

  @override
  Future<UpsertCustomFieldValuesResult> upsertValues({
    required UpsertCustomFieldValuesCommand command,
  }) async {
    lastCommand = command;
    return upsertResult;
  }
}

void main() {
  group('custom field value handlers', () {
    late _RecordingCustomFieldValueGateway gateway;

    setUp(() {
      gateway = _RecordingCustomFieldValueGateway();
    });

    test('get values query delegates tenant, product and inactive flag', () async {
      final handler = GetProductCustomFieldValuesQueryHandler(
        customFieldValueGateway: gateway,
      );

      final result = await handler.handle(
        GetProductCustomFieldValuesQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactiveValues: true,
        ),
      );

      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastProductId, 'product-1');
      expect(gateway.lastIncludeInactiveValues, isTrue);
      expect(result.groups.single.name, 'Thông tin thuốc');
    });

    test('upsert values command delegates command and returns gateway result', () async {
      final handler = UpsertCustomFieldValuesCommandHandler(
        customFieldValueGateway: gateway,
      );
      final command = UpsertCustomFieldValuesCommand(
        tenantId: 'tenant-1',
        productId: 'product-1',
        values: const [
          ProductCustomFieldValueInput(
            fieldId: 'field-1',
            textValue: 'Vitamin A',
          ),
        ],
      );

      final result = await handler.handle(command);

      expect(gateway.lastCommand, same(command));
      expect(result.productId, 'product-1');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
    });
  });

  group('custom field value validators', () {
    test('query validator rejects blank tenant or product id', () async {
      final validator = GetProductCustomFieldValuesQueryValidator();

      await expectLater(
        validator.validate(
          GetProductCustomFieldValuesQuery(
            tenantId: ' ',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        validator.validate(
          GetProductCustomFieldValuesQuery(
            tenantId: 'tenant-1',
            productId: ' ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('command validator rejects duplicate field ids', () async {
      final validator = UpsertCustomFieldValuesCommandValidator();

      await expectLater(
        validator.validate(
          UpsertCustomFieldValuesCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            values: const [
              ProductCustomFieldValueInput(fieldId: 'field-1', textValue: 'A'),
              ProductCustomFieldValueInput(fieldId: 'field-1', textValue: 'B'),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('command validator rejects more than one typed value', () async {
      final validator = UpsertCustomFieldValuesCommandValidator();

      await expectLater(
        validator.validate(
          UpsertCustomFieldValuesCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            values: const [
              ProductCustomFieldValueInput(
                fieldId: 'field-1',
                textValue: 'A',
                numberValue: 1,
              ),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
