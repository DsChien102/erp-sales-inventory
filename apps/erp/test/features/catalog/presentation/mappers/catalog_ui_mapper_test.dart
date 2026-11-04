import 'package:erp/features/catalog/data/models.dart';
import 'package:erp/features/catalog/presentation/mappers/catalog_ui_mapper.dart';
import 'package:erp/features/catalog/presentation/models/product_business_status.dart';
import 'package:erp/features/catalog/presentation/models/product_list_item_model.dart';
import 'package:erp/features/catalog/presentation/models/product_readiness_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogUiMapper.listItemFromControlCenter', () {
    const sampleDto = ProductControlCenterDto(
      profile: ProductProfileSummaryDto(
        productId: 'prod-123',
        name: 'Paracetamol 500mg',
        tradeName: 'Panadol',
        sku: 'SKU-PARA-500',
        barcode: '893000111222',
        businessStatus: ProductBusinessStatus.active,
        primaryImageUrl: 'https://cdn.example.com/para.png',
        images: ['https://cdn.example.com/para.png', 'https://cdn.example.com/para_box.png'],
        description: 'Thuốc giảm đau hạ sốt',
        note: 'Bảo quản nơi khô ráo',
      ),
      units: ProductUnitsCardDto(
        baseUnitName: 'Hộp',
      ),
      stock: ProductStockCardDto(
        mode: StockMode.basic,
        source: StockDataSource.basicProfile,
        sourceLabel: 'Kho cơ bản',
        quantity: 120,
      ),
      basePrice: ProductBasePriceCardDto(
        mode: BasePriceMode.manual,
        sourceLabel: 'Giá nhập thủ công',
      ),
      priceBand: ProductPriceBandCardDto(
        listBeforeVat: 50000,
        floorBeforeVat: 40000,
      ),
      readinessSummary: ReadinessSummaryDto(
        status: ReadinessStatus.readyToSell,
        blockers: [],
      ),
    );

    test('creates minimal model when base is null and maps fields correctly', () {
      final item = CatalogUiMapper.listItemFromControlCenter(sampleDto);

      expect(item.id, 'prod-123');
      expect(item.name, 'Paracetamol 500mg');
      expect(item.tradeName, 'Panadol');
      expect(item.sku, 'SKU-PARA-500');
      expect(item.barcode, '893000111222');
      expect(item.imageUrl, 'https://cdn.example.com/para.png');
      expect(item.images, ['https://cdn.example.com/para.png', 'https://cdn.example.com/para_box.png']);
      expect(item.businessStatus, ProductBusinessStatus.active);
      expect(item.baseUnit, 'Hộp');
      expect(item.notes, 'Bảo quản nơi khô ráo');
      expect(item.stockQty, 120);
      expect(item.readinessStatus, ProductReadinessStatus.needsReview);
    });

    test('preserves existing pricing and readiness fields when base is provided', () {
      const baseItem = ProductListItemModel(
        id: 'prod-123',
        name: 'Old Name',
        businessStatus: ProductBusinessStatus.inactive,
        readinessStatus: ProductReadinessStatus.ready,
        listBeforeVat: 50000,
        floorBeforeVat: 40000,
        baseCost: 35000,
        stockLabel: 'Tồn kho: 100',
      );

      final item = CatalogUiMapper.listItemFromControlCenter(sampleDto, base: baseItem);

      expect(item.id, 'prod-123');
      expect(item.name, 'Paracetamol 500mg');
      expect(item.tradeName, 'Panadol');
      expect(item.sku, 'SKU-PARA-500');
      expect(item.baseUnit, 'Hộp');
      expect(item.stockQty, 120);
      // Preserved from base:
      expect(item.readinessStatus, ProductReadinessStatus.ready);
      expect(item.listBeforeVat, 50000);
      expect(item.floorBeforeVat, 40000);
      expect(item.baseCost, 35000);
      expect(item.stockLabel, 'Tồn kho: 100');
    });
  });
}
