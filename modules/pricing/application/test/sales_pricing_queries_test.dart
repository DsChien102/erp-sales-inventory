import 'package:test/test.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  group('PreviewSalesWorkingStatePricingQuery', () {
    test(
      'normalizes currency/time and forwards unchanged context version',
      () async {
        final gateway = _RecordingSalesPricingReadGateway();
        final handler = PreviewSalesWorkingStatePricingQueryHandler(
          readGateway: gateway,
          validator: PreviewSalesWorkingStatePricingQueryValidator(),
        );
        final localTime = DateTime.parse('2026-08-10T15:00:00+07:00');

        final result = await handler.handle(
          PreviewSalesWorkingStatePricingQuery(
            tenantId: 'tenant-1',
            storeId: 'store-1',
            customerId: 'customer-1',
            currencyCode: ' vnd ',
            contextVersion: 7,
            effectiveAt: localTime,
            lines: const [_line],
          ),
        );

        expect(gateway.previewInput?.tenantId, 'tenant-1');
        expect(gateway.previewInput?.storeId, 'store-1');
        expect(gateway.previewInput?.currencyCode, 'VND');
        expect(gateway.previewInput?.effectiveAt.isUtc, isTrue);
        expect(gateway.previewInput?.effectiveAt, localTime.toUtc());
        expect(gateway.previewInput?.contextVersion, 7);
        expect(result.contextVersion, 7);
      },
    );

    test(
      'rejects empty lines, duplicate ids, invalid quantity, and manual intent',
      () async {
        final validator = PreviewSalesWorkingStatePricingQueryValidator();

        await expectLater(
          validator.validate(_preview(lines: const [])),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(_preview(lines: const [_line, _line])),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(
            _preview(
              lines: const [
                SalesPricingLineInput(
                  localLineId: 'line-1',
                  productId: 'product-1',
                  productUnitId: 'unit-1',
                  quantityMicros: 0,
                ),
              ],
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(
            _preview(
              lines: const [
                SalesPricingLineInput(
                  localLineId: 'line-1',
                  productId: 'product-1',
                  productUnitId: 'unit-1',
                  quantityMicros: 1000000,
                  manualUnitPriceMinor: 90000,
                  manualDiscountMinor: 10000,
                ),
              ],
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(
            _preview(
              lines: const [
                SalesPricingLineInput(
                  localLineId: 'line-1',
                  productId: 'product-1',
                  productUnitId: 'unit-1',
                  quantityMicros: 1000000,
                  manualDiscountBasisPoints: 10001,
                ),
              ],
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });

  group('EvaluateSalesManualPriceQuery', () {
    test(
      'requires exactly one valid manual intent and positive quantity',
      () async {
        final validator = EvaluateSalesManualPriceQueryValidator();

        await expectLater(
          validator.validate(_manual()),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(
            _manual(manualUnitPriceMinor: 90000, manualDiscountMinor: 10000),
          ),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(_manual(manualUnitPriceMinor: -1)),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(_manual(manualDiscountBasisPoints: 10001)),
          throwsA(isA<ValidationException>()),
        );
        await expectLater(
          validator.validate(
            _manual(quantityMicros: 0, manualUnitPriceMinor: 90000),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      'checks floor override only when gateway requires acknowledgement',
      () async {
        final gateway = _RecordingSalesPricingReadGateway();
        final permissions = _RecordingPermissionChecker();
        final handler = EvaluateSalesManualPriceQueryHandler(
          readGateway: gateway,
          validator: EvaluateSalesManualPriceQueryValidator(),
          permissionChecker: permissions,
        );

        gateway.manualResult = const SalesManualPriceEvaluationDto(
          allowed: true,
          requiresAcknowledgement: false,
          normalizedUnitPriceMinor: 90000,
          floorPriceMinor: null,
          canViewFloor: false,
          warningCodes: [],
          blockingCode: null,
          message: null,
        );
        final plain = await handler.handle(
          _manual(manualUnitPriceMinor: 90000),
        );
        expect(plain.allowed, isTrue);
        expect(permissions.required, isEmpty);

        gateway.manualResult = const SalesManualPriceEvaluationDto(
          allowed: true,
          requiresAcknowledgement: true,
          normalizedUnitPriceMinor: 80000,
          floorPriceMinor: 85000,
          canViewFloor: true,
          warningCodes: ['BELOW_FLOOR'],
          blockingCode: null,
          message: 'Acknowledge below floor.',
        );
        final acknowledged = await handler.handle(
          _manual(manualUnitPriceMinor: 80000),
        );
        expect(acknowledged.requiresAcknowledgement, isTrue);
      expect(permissions.required, [PricingPermissions.overrideFloorPrice]);
      expect(gateway.manualQuery?.tenantId, 'tenant-1');
      expect(gateway.manualQuery?.storeId, 'store-1');
      expect(gateway.manualQuery?.customerId, 'customer-1');
      expect(gateway.manualQuery?.contextVersion, 3);
        expect(gateway.manualQuery?.currencyCode, 'VND');
      },
    );
  });
}

const _line = SalesPricingLineInput(
  localLineId: 'line-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  quantityMicros: 1000000,
);

PreviewSalesWorkingStatePricingQuery _preview({
  required List<SalesPricingLineInput> lines,
}) {
  return PreviewSalesWorkingStatePricingQuery(
    tenantId: 'tenant-1',
    storeId: 'store-1',
    currencyCode: 'VND',
    contextVersion: 3,
    effectiveAt: DateTime.utc(2026, 8, 10),
    lines: lines,
  );
}

EvaluateSalesManualPriceQuery _manual({
  int quantityMicros = 1000000,
  int? manualUnitPriceMinor,
  int? manualDiscountMinor,
  int? manualDiscountBasisPoints,
}) {
  return EvaluateSalesManualPriceQuery(
    tenantId: 'tenant-1',
    storeId: 'store-1',
    customerId: 'customer-1',
    productId: 'product-1',
    productUnitId: 'unit-1',
    quantityMicros: quantityMicros,
    currencyCode: 'vnd',
    contextVersion: 3,
    manualUnitPriceMinor: manualUnitPriceMinor,
    manualDiscountMinor: manualDiscountMinor,
    manualDiscountBasisPoints: manualDiscountBasisPoints,
    acknowledgeBelowFloor: false,
  );
}

final class _RecordingSalesPricingReadGateway
    implements ISalesPricingReadGateway {
  SalesWorkingStatePricingInput? previewInput;
  EvaluateSalesManualPriceQuery? manualQuery;
  SalesManualPriceEvaluationDto manualResult =
      const SalesManualPriceEvaluationDto(
        allowed: true,
        requiresAcknowledgement: false,
        normalizedUnitPriceMinor: 100000,
        floorPriceMinor: null,
        canViewFloor: false,
        warningCodes: [],
        blockingCode: null,
        message: null,
      );

  @override
  Future<SalesWorkingStatePricingPreviewDto> previewWorkingState(
    SalesWorkingStatePricingInput input,
  ) async {
    previewInput = input;
    return SalesWorkingStatePricingPreviewDto(
      contextVersion: input.contextVersion,
      previewToken: 'preview-token',
      currencyCode: input.currencyCode,
      lines: const [
        SalesPricingLinePreviewDto(
          localLineId: 'line-1',
          appliedUnitPriceMinor: 100000,
          discountMinor: 0,
          lineTotalMinor: 100000,
          sourceCode: 'LIST_PRICE',
          listPriceMinor: 100000,
          floorPriceMinor: 90000,
          warningCodes: [],
          blockingCodes: [],
        ),
      ],
    );
  }

  @override
  Future<SalesManualPriceEvaluationDto> evaluateManualPrice(
    EvaluateSalesManualPriceQuery query,
  ) async {
    manualQuery = query;
    return manualResult;
  }
}

final class _RecordingPermissionChecker implements IPermissionChecker {
  final List<String> required = [];

  @override
  Future<void> require(String permissionCode) async {
    required.add(permissionCode);
  }
}
