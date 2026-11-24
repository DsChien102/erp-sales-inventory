import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supplier_program_rules', () {
    final products = [
      const ProductOption(
        productId: 'p1',
        name: 'Nobivac DHPPi',
        code: 'NOBI-01',
        baseUnitId: 'u-hop-1',
        baseUom: 'hộp',
      ),
      const ProductOption(
        productId: 'p2',
        name: 'Nobivac Rabies',
        code: 'NOBI-02',
        baseUnitId: 'u-hop-2',
        baseUom: 'hộp',
      ),
      const ProductOption(
        productId: 'p3',
        name: 'Amox',
        code: 'AMOX-01',
        baseUnitId: 'u-chai-3',
        baseUom: 'chai',
      ),
    ];

    test('format_percent', () {
      expect(formatPercent(2.5), '2,5');
      expect(formatPercent(5.00), '5');
      expect(formatPercent(3), '3');
      expect(formatPercent(12.25), '12,25');
    });

    test('summary_tier', () {
      final row = ProgramRow(
        id: '1',
        name: 'A',
        supplierId: 's1',
        supplierName: 'NCC A',
        kind: ProgramKind.tierDiscount,
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 10),
        productIds: const ['p1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [
          ProgramTier(minQty: 100, discountPercent: 3),
          ProgramTier(minQty: 300, discountPercent: 5),
        ],
        progressQty: 0,
      );
      expect(programSummary(row), 'Từ 100 hộp giảm 3% · từ 300 giảm 5%');
    });

    test('summary_tier_mixed_uom', () {
      final row = ProgramRow(
        id: '1',
        name: 'A',
        supplierId: 's1',
        supplierName: 'NCC A',
        kind: ProgramKind.tierDiscount,
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 10),
        productIds: const ['p1', 'p3'],
        productCount: 2,
        commonUom: null,
        tiers: const [
          ProgramTier(minQty: 100, discountPercent: 3),
          ProgramTier(minQty: 300, discountPercent: 5),
        ],
        progressQty: 0,
      );
      expect(programSummary(row), 'Từ 100 giảm 3% · từ 300 giảm 5%');
    });

    test('summary_buy_x', () {
      final row = ProgramRow(
        id: '1',
        name: 'A',
        supplierId: 's1',
        supplierName: 'NCC A',
        kind: ProgramKind.buyXGetY,
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 10),
        productIds: const ['p1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        buyQty: 10,
        freeQty: 1,
        progressQty: 0,
      );
      expect(programSummary(row), 'Mua 10 tặng 1 hộp');
    });

    test('summary_volume', () {
      final row = ProgramRow(
        id: '1',
        name: 'A',
        supplierId: 's1',
        supplierName: 'NCC A',
        kind: ProgramKind.volumeRebate,
        status: ProgramStatus.active,
        startedOn: DateTime(2026, 11, 10),
        productIds: const ['p1'],
        productCount: 1,
        commonUom: 'hộp',
        tiers: const [],
        targetQty: 1000,
        rebatePercent: 5,
        progressQty: 400,
      );
      expect(programSummary(row), 'Đạt 1.000 hộp giảm 5% tổng tiền mua');
    });

    test('validate_requires_supplier_name_products', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10));
      final errs = validateProgramForm(
        draft,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errs['supplier'], 'Chọn nhà cung cấp');
      expect(errs['name'], 'Nhập tên chương trình');
      expect(errs['products'], 'Chọn ít nhất một sản phẩm');
      expect(errs['tier.0'], 'Nhập số lượng và mức giảm');
    });

    test('validate_buy_x_single_product', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Mua 10 tặng 1',
            kind: ProgramKind.buyXGetY,
            productIds: const ['p1', 'p2'],
            buyQty: '10',
            freeQty: '1',
          );
      final errs = validateProgramForm(
        draft,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errs['products'], 'Mua X tặng Y chỉ áp cho một sản phẩm');
    });

    test('validate_volume_same_uom_name_different_unit_rows', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Đạt mốc cùng ĐVT hộp',
            kind: ProgramKind.volumeRebate,
            productIds: const ['p1', 'p2'],
            targetQty: '1000',
            rebatePercent: '5',
          );
      final errs = validateProgramForm(
        draft,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errs['products'], isNull);
    });

    test('validate_percent_max_two_decimals', () {
      final draftTierInvalid = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Bậc lẻ',
            kind: ProgramKind.tierDiscount,
            productIds: const ['p1'],
            tiers: const [
              (minQty: '100', percent: '0.004'),
            ],
          );
      final errsTier = validateProgramForm(
        draftTierInvalid,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errsTier['tier.0'], 'Mức giảm từ 0,01 đến 100%');

      final draftVolumeInvalid = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Đạt mốc lẻ',
            kind: ProgramKind.volumeRebate,
            productIds: const ['p1'],
            targetQty: '100',
            rebatePercent: '3.001',
          );
      final errsVol = validateProgramForm(
        draftVolumeInvalid,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errsVol['rebatePercent'], '% chiết khấu từ 0,01 đến 100%');
    });

    test('validate_volume_uom_mismatch', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Đạt mốc',
            kind: ProgramKind.volumeRebate,
            productIds: const ['p1', 'p3'],
            targetQty: '1000',
            rebatePercent: '5',
          );
      final errs = validateProgramForm(
        draft,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(
        errs['products'],
        'Các sản phẩm phải cùng đơn vị tính cơ sở (hộp)',
      );
    });

    test('validate_tiers_increasing', () {
      final draftQty = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Bậc',
            kind: ProgramKind.tierDiscount,
            productIds: const ['p1'],
            tiers: const [
              (minQty: '300', percent: '3'),
              (minQty: '100', percent: '5'),
            ],
          );
      final errsQty = validateProgramForm(
        draftQty,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errsQty['tier.1'], 'Số lượng bậc sau phải lớn hơn bậc trước');

      final draftPct = draftQty.copyWith(
        tiers: const [
          (minQty: '100', percent: '5'),
          (minQty: '300', percent: '3'),
        ],
      );
      final errsPct = validateProgramForm(
        draftPct,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errsPct['tier.1'], 'Mức giảm bậc sau phải lớn hơn bậc trước');
    });

    test('validate_tier_max_five', () {
      final draft = ProgramFormDraft.initial(today: DateTime(2026, 11, 10))
          .copyWith(
            supplierId: 's1',
            name: 'Bậc',
            kind: ProgramKind.tierDiscount,
            productIds: const ['p1'],
            tiers: const [
              (minQty: '10', percent: '1'),
              (minQty: '20', percent: '2'),
              (minQty: '30', percent: '3'),
              (minQty: '40', percent: '4'),
              (minQty: '50', percent: '5'),
              (minQty: '60', percent: '6'),
            ],
          );
      final errs = validateProgramForm(
        draft,
        products,
        today: DateTime(2026, 11, 10),
      );
      expect(errs['tiers'], isNotNull);
    });

    test('validate_started_on_range', () {
      final today = DateTime(2026, 11, 10);
      final draft = ProgramFormDraft.initial(today: today).copyWith(
        supplierId: 's1',
        name: 'Bậc',
        kind: ProgramKind.tierDiscount,
        productIds: const ['p1'],
        tiers: const [(minQty: '100', percent: '3')],
        startedOn: today.add(const Duration(days: 366)),
      );
      final errs = validateProgramForm(draft, products, today: today);
      expect(
        errs['startedOn'],
        'Ngày bắt đầu trong vòng một năm so với hôm nay',
      );
    });
  });
}

