import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// Shared formatters & labels cho SG-06 (D-01…D-08).
abstract final class PriceRuleHistoryShared {
  static String activityLabel(CustomerPriceRuleActivityType type) =>
      switch (type) {
        CustomerPriceRuleActivityType.created => 'Tạo giá riêng',
        CustomerPriceRuleActivityType.updated => 'Sửa giá',
        CustomerPriceRuleActivityType.disabled => 'Tắt',
        CustomerPriceRuleActivityType.reenabled => 'Bật lại',
        CustomerPriceRuleActivityType.deleted => 'Xóa',
        CustomerPriceRuleActivityType.importCreated ||
        CustomerPriceRuleActivityType.importUpdated => 'Nhập Excel',
        CustomerPriceRuleActivityType.memoryCreated ||
        CustomerPriceRuleActivityType.memoryUpdated => 'Từ đơn hàng',
      };

  static String activityLabelDetail(CustomerPriceRuleActivityType type) =>
      switch (type) {
        CustomerPriceRuleActivityType.created => 'Tạo giá riêng',
        CustomerPriceRuleActivityType.updated => 'Sửa giá riêng',
        CustomerPriceRuleActivityType.disabled => 'Tắt giá riêng',
        CustomerPriceRuleActivityType.reenabled => 'Bật lại giá riêng',
        CustomerPriceRuleActivityType.deleted => 'Xóa giá riêng',
        CustomerPriceRuleActivityType.importCreated => 'Tạo từ nhập Excel',
        CustomerPriceRuleActivityType.importUpdated => 'Cập nhật từ nhập Excel',
        CustomerPriceRuleActivityType.memoryCreated => 'Ghi nhận nhớ giá',
        CustomerPriceRuleActivityType.memoryUpdated => 'Cập nhật giá nhớ',
      };

  static String sourceLabel(CustomerPriceRuleSourceType src) => switch (src) {
    CustomerPriceRuleSourceType.manual => 'Tạo thủ công',
    CustomerPriceRuleSourceType.excelImport => 'Nhập Excel',
    CustomerPriceRuleSourceType.salesOrder => 'Từ đơn hàng',
    CustomerPriceRuleSourceType.migration => 'Hệ thống',
  };

  static VIcons activityIcon(CustomerPriceRuleActivityType type) =>
      switch (type) {
        CustomerPriceRuleActivityType.created => VIcons.addCircle,
        CustomerPriceRuleActivityType.updated => VIcons.edit,
        CustomerPriceRuleActivityType.disabled => VIcons.powerOff,
        CustomerPriceRuleActivityType.reenabled => VIcons.power,
        CustomerPriceRuleActivityType.deleted => VIcons.delete,
        CustomerPriceRuleActivityType.importCreated ||
        CustomerPriceRuleActivityType.importUpdated => VIcons.download,
        CustomerPriceRuleActivityType.memoryCreated ||
        CustomerPriceRuleActivityType.memoryUpdated => VIcons.receipt,
      };

  static VComponentTone activityTone(CustomerPriceRuleActivityType type) =>
      switch (type) {
        CustomerPriceRuleActivityType.disabled ||
        CustomerPriceRuleActivityType.deleted => VComponentTone.danger,
        CustomerPriceRuleActivityType.reenabled => VComponentTone.success,
        CustomerPriceRuleActivityType.updated => VComponentTone.primary,
        CustomerPriceRuleActivityType.created ||
        CustomerPriceRuleActivityType.importCreated ||
        CustomerPriceRuleActivityType.memoryCreated => VComponentTone.info,
        _ => VComponentTone.neutral,
      };

  static VBadgeStatus sourceBadgeStatus(CustomerPriceRuleSourceType src) =>
      switch (src) {
        CustomerPriceRuleSourceType.manual => VBadgeStatus.info,
        CustomerPriceRuleSourceType.excelImport => VBadgeStatus.success,
        CustomerPriceRuleSourceType.salesOrder => VBadgeStatus.processing,
        CustomerPriceRuleSourceType.migration => VBadgeStatus.draft,
      };

  static String formatMoney(int amountMinor) => MoneyFormatter.formatMinor(amountMinor);

  static String formatDiffMoney(int? diffMinor) {
    if (diffMinor == null) return '—';
    final formatted = MoneyFormatter.formatMinor(diffMinor.abs());
    if (diffMinor > 0) return '+$formatted';
    if (diffMinor < 0) return '-$formatted';
    return formatted;
  }

  static String formatDateTime(DateTime d) {
    final ict = VDateTime.toIct(d);
    return '${ict.day.toString().padLeft(2, '0')}/'
        '${ict.month.toString().padLeft(2, '0')}/'
        '${ict.year} '
        '${ict.hour.toString().padLeft(2, '0')}:'
        '${ict.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateStr(String? dateStr) =>
      VDateTime.parseAndFormatCalendarDate(dateStr);

  /// Tóm tắt thay đổi ngắn cho timeline item (D-01, D-02).
  static String? activitySummary(CustomerPriceRuleActivityDto activity) {
    final oldValue = activity.oldValue;
    final newValue = activity.newValue;
    final oldPrice = (oldValue?['rule_price_minor'] as num?)?.toInt();
    final newPrice = (newValue['rule_price_minor'] as num?)?.toInt();
    final orderId = activity.sourceTrace.orderId;

    if (activity.activityType == CustomerPriceRuleActivityType.updated &&
        oldPrice != null &&
        newPrice != null) {
      return 'Giá đổi từ ${formatMoney(oldPrice)} → ${formatMoney(newPrice)}';
    }
    if (orderId != null) return 'Đơn #$orderId';
    if (activity.reason != null && activity.reason!.isNotEmpty) {
      return 'Lý do: ${activity.reason}';
    }
    if (newPrice != null) return 'Giá áp dụng: ${formatMoney(newPrice)}';
    return null;
  }

  /// Kiểm tra activity có khớp bộ lọc thời gian không.
  static bool matchesTimeRange(String timeRange, DateTime createdAt) {
    final now = DateTime.now();
    return switch (timeRange) {
      'Tất cả' => true,
      '7 ngày gần đây' => createdAt.isAfter(
        now.subtract(const Duration(days: 7)),
      ),
      '30 ngày gần đây' => createdAt.isAfter(
        now.subtract(const Duration(days: 30)),
      ),
      '90 ngày gần đây' => createdAt.isAfter(
        now.subtract(const Duration(days: 90)),
      ),
      _ => true, // 'Tùy chọn' — chưa có date picker, giữ tất cả
    };
  }
}
