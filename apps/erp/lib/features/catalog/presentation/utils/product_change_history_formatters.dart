import 'package:vet45_catalog_application/application.dart';

String formatProductChangeHistoryDateTime(DateTime occurredAt) {
  final local = occurredAt.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
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
