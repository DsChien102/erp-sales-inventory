import '../../data/models.dart';
import 'package:c45_design_system/design_system.dart';

String formatProductChangeHistoryDateTime(DateTime occurredAt) {
  final ict = VDateTime.toIct(occurredAt);
  final year = ict.year.toString().padLeft(4, '0');
  final month = ict.month.toString().padLeft(2, '0');
  final day = ict.day.toString().padLeft(2, '0');
  final hour = ict.hour.toString().padLeft(2, '0');
  final minute = ict.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String formatProductChangeHistorySummary({
  required String summary,
  required ProductChangeHistoryAction? changeType,
}) {
  final fromSummary = ProductChangeHistoryAction.tryParse(summary);
  if (fromSummary != null) {
    return fromSummary.labelVi;
  }

  if (changeType != null) {
    return changeType.labelVi;
  }

  final trimmed = summary.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }

  return '';
}

String formatProductPriceBandSourceType(PriceBandSourceType? sourceType) {
  return switch (sourceType) {
    PriceBandSourceType.ruleBased => 'Theo khung giá cửa hàng',
    PriceBandSourceType.customConfig => 'Tự động riêng theo cấu hình',
    PriceBandSourceType.manual => 'Nhập thủ công',
    null => 'Chưa có khung giá',
  };
}

String formatProductPriceBandHistoryTrigger(
  ProductPriceBandHistoryTrigger trigger,
) {
  return switch (trigger) {
    ProductPriceBandHistoryTrigger.direct => 'Thao tác trực tiếp',
    ProductPriceBandHistoryTrigger.basePriceChanged => 'Tự động do Giá cơ sở thay đổi',
    ProductPriceBandHistoryTrigger.storeRuleChanged => 'Tự động do khung giá cửa hàng thay đổi',
  };
}

String formatProductPriceBandHistoryMoney(int? value, String currency) {
  if (value == null) return '—';
  final formatted = VMoneyValidator.format(value).replaceAll(',', '.');
  return currency.toUpperCase() == 'VND' ? '$formatted đ' : '$formatted ${currency.toUpperCase()}';
}

extension ProductChangeHistoryActionLabelVi on ProductChangeHistoryAction {
  String get labelVi {
    switch (this) {
      case ProductChangeHistoryAction.created:
        return 'Tạo sản phẩm';
      case ProductChangeHistoryAction.profileUpdated:
        return 'Cập nhật hồ sơ sản phẩm';
      case ProductChangeHistoryAction.imagesUpdated:
        return 'Cập nhật ảnh sản phẩm';
      case ProductChangeHistoryAction.unitAdded:
        return 'Thêm đơn vị quy đổi';
      case ProductChangeHistoryAction.unitDeactivated:
        return 'Ngừng đơn vị quy đổi';
      case ProductChangeHistoryAction.unitReactivated:
        return 'Kích hoạt lại đơn vị quy đổi';
      case ProductChangeHistoryAction.unitDeleted:
        return 'Xóa đơn vị quy đổi';
      case ProductChangeHistoryAction.baseUnitSet:
        return 'Tạo đơn vị cơ sở';
      case ProductChangeHistoryAction.stockUpdated:
        return 'Cập nhật tồn kho';
      case ProductChangeHistoryAction.manualBasePriceSet:
        return 'Cập nhật giá cơ sở';
      case ProductChangeHistoryAction.storePriceRuleApplied:
        return 'Áp dụng khung giá cửa hàng';
      case ProductChangeHistoryAction.priceBandUpdated:
        return 'Cập nhật khung giá';
      case ProductChangeHistoryAction.customFieldValuesUpdated:
        return 'Cập nhật thuộc tính sản phẩm';
      case ProductChangeHistoryAction.statusChanged:
        return 'Thay đổi trạng thái kinh doanh';
      case ProductChangeHistoryAction.deactivated:
        return 'Ngừng kinh doanh';
      case ProductChangeHistoryAction.reactivated:
        return 'Mở lại kinh doanh';
      case ProductChangeHistoryAction.softDeleted:
        return 'Xóa mềm sản phẩm';
      case ProductChangeHistoryAction.restored:
        return 'Khôi phục sản phẩm';
    }
  }
}
