import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'support/fake_write_ports.dart';

class _RecordingStorePriceRuleGateway implements IStorePriceRuleGateway {
  StorePriceRuleDto? storedRule;
  ProductUnitPriceSuggestionDto? lastSuggestion;
  AppliedStorePriceRuleDto? lastApplied;
  ApplyStorePriceRuleCommand? lastApplyCommand;

  @override
  Future<AppliedStorePriceRuleDto> apply({
    required ApplyStorePriceRuleCommand command,
  }) async {
    lastApplyCommand = command;
    if (command.productId == 'product-1' && !command.confirmOverwrite) {
      throw PriceBandOverwriteRequiredException(
        existingListBeforeVat: 120000,
        existingFloorBeforeVat: 95000,
      );
    }
    if (command.basePriceVersion != null && command.basePriceVersion != 12345) {
      throw StaleBasePriceException();
    }
    final applied = AppliedStorePriceRuleDto(
      productId: command.productId,
      productUnitId: command.productUnitId ?? 'unit-base',
      listBeforeVat: 37500,
      floorBeforeVat: 31250,
      storePriceRuleId: 'rule-1',
    );
    lastApplied = applied;
    return applied;
  }

  @override
  Future<StorePriceRuleDto?> getRule({required String tenantId}) async {
    return storedRule ??
        const StorePriceRuleDto(
          id: 'rule-1',
          tenantId: 'tenant-1',
          name: 'Mặc định bán lẻ',
          status: StorePriceRuleStatus.active,
          calculationType: StorePriceCalculationType.markup,
          listMarkupRatio: 0.5,
          floorMarkupRatio: 0.25,
        );
  }

  @override
  Future<ProductUnitPriceSuggestionDto> suggest({
    required SuggestProductUnitPriceQuery query,
  }) async {
    if (query.productId == 'product-7') {
      return const ProductUnitPriceSuggestionDto(
        productId: 'product-7',
        basePrice: 0,
        currency: 'VND',
        canSuggest: false,
        unavailableReason: 'Cần có Giá cơ sở định giá trước',
      );
    }
    final suggestion = ProductUnitPriceSuggestionDto(
      productId: query.productId,
      basePrice: 25000,
      currency: 'VND',
      suggestedListBeforeVat: 37500,
      suggestedFloorBeforeVat: 31250,
      storePriceRuleId: 'rule-1',
      storePriceRuleName: 'Mặc định bán lẻ',
      basePriceVersion: 12345,
      canSuggest: true,
    );
    lastSuggestion = suggestion;
    return suggestion;
  }

  @override
  Future<StorePriceRuleDto> upsertRule({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) async {
    storedRule = StorePriceRuleDto(
      id: 'rule-1',
      tenantId: tenantId,
      name: name,
      status: status,
      calculationType: StorePriceCalculationType.markup,
      listMarkupRatio: listMarkupRatio,
      floorMarkupRatio: floorMarkupRatio,
    );
    return storedRule!;
  }

  @override
  Future<StorePriceRuleChangeHistoryResultDto> listChangeHistory({
    required String tenantId,
    int limit = 50,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }
}

class _FakeProductReadinessReadPort implements IProductReadinessReadPort {
  _FakeProductReadinessReadPort({
    this.hasBaseUnit = true,
    this.hasBasePrice = true,
    this.hasPriceBand = false,
  });

  final bool hasBaseUnit;
  final bool hasBasePrice;
  final bool hasPriceBand;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    return ProductReadinessFacts(
      productId: productId,
      productName: 'Test product',
      hasBaseUnit: hasBaseUnit,
      hasImages: true,
      hasStock: true,
      hasBasePrice: hasBasePrice,
      hasPriceBand: hasPriceBand,
      hasRequiredCustomFields: true,
    );
  }
}

void main() {
  group('Store price rule handlers', () {
    test('scn_e06_u02_fr01_01 set and get store price rule', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final setHandler = SetStorePriceRuleCommandHandler(
        storePriceRuleGateway: gateway,
      );
      final getHandler = GetStorePriceRuleQueryHandler(
        storePriceRuleGateway: gateway,
      );
      final validator = SetStorePriceRuleCommandValidator();

      final command = SetStorePriceRuleCommand(
        tenantId: 'tenant-new',
        name: 'Mặc định bán lẻ',
        listMarkupRatio: 0.4,
        floorMarkupRatio: 0.2,
      );
      await validator.validate(command);
      final setResult = await setHandler.handle(command);
      expect(setResult.rule.name, 'Mặc định bán lẻ');

      final rule = await getHandler.handle(
        GetStorePriceRuleQuery(tenantId: 'tenant-new'),
      );
      expect(rule?.listMarkupRatio, 0.4);
    });

    test('scn_e06_u02_fr01_02 set validator rejects negative markup', () async {
      final validator = SetStorePriceRuleCommandValidator();
      await expectLater(
        validator.validate(
          SetStorePriceRuleCommand(
            tenantId: 'tenant-1',
            name: 'Invalid',
            listMarkupRatio: -0.1,
            floorMarkupRatio: 0.2,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('scn_e06_u02_fr02_01 suggest returns list and floor prices', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final handler = SuggestProductUnitPriceQueryHandler(
        storePriceRuleGateway: gateway,
      );

      final suggestion = await handler.handle(
        SuggestProductUnitPriceQuery(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(suggestion.canSuggest, isTrue);
      expect(suggestion.suggestedListBeforeVat, 37500);
      expect(suggestion.storePriceRuleName, 'Mặc định bán lẻ');
    });

    test('scn_e06_u02_fr02_02 suggest without base price is soft-fail', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final handler = SuggestProductUnitPriceQueryHandler(
        storePriceRuleGateway: gateway,
      );

      final suggestion = await handler.handle(
        SuggestProductUnitPriceQuery(
          tenantId: 'tenant-1',
          productId: 'product-7',
        ),
      );

      expect(suggestion.canSuggest, isFalse);
    });

    test('scn_e06_u02_fr03_01 apply persists rule-based band', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final handler = ApplyStorePriceRuleCommandHandler(
        storePriceRuleGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(hasPriceBand: true),
        catalogReadGateway: FakeCatalogReadGateway(basePriceAmount: 25000),
      );

      final result = await handler.handle(
        ApplyStorePriceRuleCommand(
          tenantId: 'tenant-1',
          productId: 'product-4',
        ),
      );

      expect(result.listBeforeVat, 37500);
      expect(result.sourceType, PriceBandSourceType.ruleBased);
      expect(result.readinessSummary.blockers, isEmpty);
    });

    test('scn_e06_u02_fr03_02 apply requires overwrite confirm', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final handler = ApplyStorePriceRuleCommandHandler(
        storePriceRuleGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(),
        catalogReadGateway: FakeCatalogReadGateway(basePriceAmount: 25000),
      );

      await expectLater(
        handler.handle(
          ApplyStorePriceRuleCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<PriceBandOverwriteRequiredException>()),
      );
    });

    test('scn_e06_u02_fr03_03 apply rejects stale base price version', () async {
      final gateway = _RecordingStorePriceRuleGateway();
      final handler = ApplyStorePriceRuleCommandHandler(
        storePriceRuleGateway: gateway,
        readinessReadPort: _FakeProductReadinessReadPort(),
        catalogReadGateway: FakeCatalogReadGateway(basePriceAmount: 25000),
      );

      await expectLater(
        handler.handle(
          ApplyStorePriceRuleCommand(
            tenantId: 'tenant-1',
            productId: 'product-4',
            basePriceVersion: 0,
          ),
        ),
        throwsA(isA<StaleBasePriceException>()),
      );
    });
  });
}
