import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../queries/list_product_unit_price_bands/price_band_source_type.dart';
import 'set_product_unit_price_band_command.dart';

final class SetProductUnitPriceBandCommandValidator
    implements ICommandValidator<SetProductUnitPriceBandCommand> {
  @override
  Future<void> validate(SetProductUnitPriceBandCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    switch (command.sourceType) {
      case PriceBandSourceType.ruleBased:
        throw ValidationException(
          'Vui lòng dùng lệnh áp dụng khung giá cửa hàng.',
        );
      case PriceBandSourceType.customConfig:
        return _validateCustomConfig(command);
      case PriceBandSourceType.manual:
        return _validateManual(command);
    }
  }

  void _validateCustomConfig(SetProductUnitPriceBandCommand command) {
    if (command.storePriceRuleId != null) {
      throw ValidationException(
        'Cấu hình riêng không được tham chiếu quy tắc cửa hàng.',
      );
    }
    if (command.listBeforeVat != null ||
        command.listAfterVat != null ||
        command.floorBeforeVat != null ||
        command.floorAfterVat != null) {
      throw ValidationException('Cấu hình riêng chỉ nhận tỷ lệ phần trăm.');
    }
    final listRatio = command.listMarkupRatio;
    if (listRatio == null) {
      throw ValidationException('Tỷ lệ giá niêm yết là bắt buộc.');
    }
    if (listRatio < 0) {
      throw ValidationException('Tỷ lệ không được âm.');
    }
    final floorRatio = command.floorMarkupRatio;
    if (floorRatio != null) {
      if (floorRatio < 0) {
        throw ValidationException('Tỷ lệ không được âm.');
      }
      if (floorRatio > listRatio) {
        throw ValidationException(
          'Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.',
        );
      }
    }
  }

  void _validateManual(SetProductUnitPriceBandCommand command) {
    if (command.storePriceRuleId != null ||
        command.listMarkupRatio != null ||
        command.floorMarkupRatio != null) {
      throw ValidationException('Giá thủ công không được có nguồn công thức.');
    }
    final listBefore = command.listBeforeVat;
    final listAfter = command.listAfterVat;
    if (listBefore == null || listAfter == null) {
      throw ValidationException('Giá niêm yết là bắt buộc.');
    }
    if (listBefore < 0 || listAfter < 0) {
      throw ValidationException('Giá không được âm.');
    }
    final floorBefore = command.floorBeforeVat;
    if (floorBefore != null) {
      if (floorBefore < 0) {
        throw ValidationException('Giá không được âm.');
      }
      if (floorBefore > listBefore) {
        throw FloorPriceGreaterThanListPriceException();
      }
    }
    final floorAfter = command.floorAfterVat;
    if (floorAfter != null) {
      if (floorAfter < 0) {
        throw ValidationException('Giá không được âm.');
      }
      if (floorAfter > listAfter) {
        throw FloorPriceGreaterThanListPriceException();
      }
    }
  }
}
