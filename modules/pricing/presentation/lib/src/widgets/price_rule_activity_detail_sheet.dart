import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

import 'price_rule_history_shared.dart';
import 'price_rule_source_order_detail_sheet.dart';

/// D-05 & D-07 SG-06 — Sheet chi tiết Activity — Diff trước/sau & Mask sensitive data.
class PriceRuleActivityDetailSheet extends StatelessWidget {
  const PriceRuleActivityDetailSheet({
    super.key,
    required this.activity,
    this.hasSensitivePermission = true,
    this.onViewRuleDetail,
    this.onViewSourceOrder,
  });

  final CustomerPriceRuleActivityDto activity;
  final bool hasSensitivePermission;
  final VoidCallback? onViewRuleDetail;
  final VoidCallback? onViewSourceOrder;

  static Future<void> show({
    required BuildContext context,
    required CustomerPriceRuleActivityDto activity,
    bool hasSensitivePermission = true,
    VoidCallback? onViewRuleDetail,
    VoidCallback? onViewSourceOrder,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Chi tiết hoạt động',
      semanticLabel: 'Chi tiết hoạt động giá riêng',
      child: PriceRuleActivityDetailSheet(
        activity: activity,
        hasSensitivePermission: hasSensitivePermission,
        onViewRuleDetail: onViewRuleDetail,
        onViewSourceOrder: onViewSourceOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final oldValue = activity.oldValue;
    final newValue = activity.newValue;

    final oldPrice = (oldValue?['rule_price_minor'] as num?)?.toInt();
    final newPrice = (newValue['rule_price_minor'] as num?)?.toInt();
    final oldFrom = oldValue?['effective_from'] as String?;
    final newFrom = newValue['effective_from'] as String?;
    final oldTo = oldValue?['effective_to'] as String?;
    final newTo = newValue['effective_to'] as String?;

    final oldFloorDiff = (oldValue?['floor_price_diff_minor'] as num?)?.toInt();
    final newFloorDiff = (newValue['floor_price_diff_minor'] as num?)?.toInt();

    final orderId = activity.sourceTrace.orderId;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // D-07: Banner ẩn dữ liệu nhạy cảm nếu không có quyền
              if (!hasSensitivePermission) ...[
                VBanner(
                  tone: VComponentTone.info,
                  icon: VIcons.info,
                  title: 'Quyền hạn chế',
                  message: 'Bạn không có quyền xem một số dữ liệu nhạy cảm.',
                ),
                const VGap.md(),
              ],

              // Header Card
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Row(
                  children: [
                    VIconBox(
                      icon: _icon(activity.activityType),
                      size: 44,
                      iconSize: 22,
                      tone: _tone(activity.activityType),
                      isCircular: true,
                    ),
                    const VGap.horizontalMd(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            _activityLabel(activity.activityType),
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const VGap.xs(),
                          VText(
                            '${_formatDateTime(activity.createdAt)} · ${activity.actor.displayName}',
                            variant: VTextVariant.caption,
                            color: colors.textSecondary,
                          ),
                          VText(
                            'Nguồn: ${_formatSource(activity.sourceType)}',
                            variant: VTextVariant.caption,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const VGap.md(),

              // Card 1: So sánh trước / sau (Diff Table)
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'So sánh trước / sau',
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const VGap.sm(),
                    Divider(height: 1, color: colors.borderDefault),
                    const VGap.sm(),
                    _DiffHeaderRow(),
                    const VGap.xs(),
                    _DiffRow(
                      label: 'Giá riêng',
                      before: oldPrice != null ? _formatMoney(oldPrice) : '—',
                      after: newPrice != null ? _formatMoney(newPrice) : '—',
                      highlightAfter: true,
                    ),
                    const VGap.xs(),
                    _DiffRow(
                      label: 'Ngày bắt đầu',
                      before: _formatDateStr(oldFrom),
                      after: _formatDateStr(newFrom),
                    ),
                    const VGap.xs(),
                    _DiffRow(
                      label: 'Ngày kết thúc',
                      before: _formatDateStr(oldTo),
                      after: _formatDateStr(newTo),
                      highlightAfter: oldTo != newTo,
                    ),
                    const VGap.xs(),
                    _DiffRow(
                      label: 'Chênh lệch giá sàn',
                      before: hasSensitivePermission
                          ? _formatDiffMoney(oldFloorDiff)
                          : 'Ẩn theo quyền 🔒',
                      after: hasSensitivePermission
                          ? _formatDiffMoney(newFloorDiff)
                          : 'Ẩn theo quyền 🔒',
                      highlightAfter:
                          hasSensitivePermission && newFloorDiff != null,
                      isMasked: !hasSensitivePermission,
                    ),
                  ],
                ),
              ),
              const VGap.md(),

              // Card 2: Ghi chú / lý do
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      'Ghi chú / lý do',
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const VGap.xs(),
                    VText(
                      activity.reason != null && activity.reason!.isNotEmpty
                          ? activity.reason!
                          : 'Không có ghi chú',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      style: activity.reason == null
                          ? const TextStyle(fontStyle: FontStyle.italic)
                          : null,
                    ),
                  ],
                ),
              ),

              // Nếu có nguồn đơn hàng D-06
              if (orderId != null) ...[
                const VGap.md(),
                VCard(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            'Chứng từ nguồn',
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const VGap.xs(),
                          VText(
                            'Đơn hàng $orderId',
                            variant: VTextVariant.bodySmallMono,
                            color: colors.primary,
                          ),
                        ],
                      ),
                      VButton(
                        label: 'Xem chứng từ',
                        variant: VButtonVariant.outline,
                        onPressed: () {
                          PriceRuleSourceOrderDetailSheet.show(
                            context: context,
                            orderId: orderId,
                            customerName: 'Khách hàng theo đơn',
                            orderDate: _formatDateTime(activity.createdAt),
                            productName: 'Sản phẩm theo đơn',
                            unitName: 'Hộp',
                            priceLabel: newPrice != null
                                ? _formatMoney(newPrice)
                                : '—',
                            staffName: activity.actor.displayName,
                            onViewSourceOrder: onViewSourceOrder,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const VGap.lg(),

              if (onViewRuleDetail != null)
                VButton(
                  label: 'Xem chi tiết giá riêng >',
                  variant: VButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewRuleDetail?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  VIcons _icon(CustomerPriceRuleActivityType type) => switch (type) {
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

  VComponentTone _tone(CustomerPriceRuleActivityType type) => switch (type) {
    CustomerPriceRuleActivityType.disabled ||
    CustomerPriceRuleActivityType.deleted => VComponentTone.danger,
    CustomerPriceRuleActivityType.reenabled => VComponentTone.success,
    CustomerPriceRuleActivityType.updated => VComponentTone.primary,
    CustomerPriceRuleActivityType.created ||
    CustomerPriceRuleActivityType.importCreated ||
    CustomerPriceRuleActivityType.memoryCreated => VComponentTone.info,
    _ => VComponentTone.neutral,
  };

  String _formatDateTime(DateTime d) =>
      PriceRuleHistoryShared.formatDateTime(d);

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Không giới hạn';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatMoney(int amountMinor) {
    return '${amountMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  String _formatDiffMoney(int? diffMinor) {
    if (diffMinor == null) return '—';
    final sign = diffMinor >= 0 ? '+' : '';
    return '$sign${diffMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  String _formatSource(CustomerPriceRuleSourceType src) => switch (src) {
    CustomerPriceRuleSourceType.manual => 'Tạo thủ công',
    CustomerPriceRuleSourceType.excelImport => 'Nhập Excel',
    CustomerPriceRuleSourceType.salesOrder => 'Từ đơn hàng',
    CustomerPriceRuleSourceType.migration => 'Migration',
  };
}

class _DiffHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: VText(
            'Trường',
            variant: VTextVariant.caption,
            color: colors.textMuted,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          flex: 4,
          child: VText(
            'Trước',
            variant: VTextVariant.caption,
            color: colors.textMuted,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          flex: 4,
          child: VText(
            'Sau',
            variant: VTextVariant.caption,
            color: colors.textMuted,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.label,
    required this.before,
    required this.after,
    this.highlightAfter = false,
    this.isMasked = false,
  });

  final String label;
  final String before;
  final String after;
  final bool highlightAfter;
  final bool isMasked;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: VText(
            label,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(right: VSpacing.space2),
            child: VText(
              before,
              variant: VTextVariant.bodySmall,
              color: isMasked ? colors.textMuted : colors.textPrimary,
              style: isMasked
                  ? null
                  : const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          flex: 4,
          child: VText(
            after,
            variant: VTextVariant.bodySmall,
            color: isMasked
                ? colors.textMuted
                : (highlightAfter ? colors.success : colors.textPrimary),
            style: highlightAfter && !isMasked
                ? const TextStyle(fontWeight: FontWeight.w700)
                : (isMasked
                      ? null
                      : const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

String _activityLabel(CustomerPriceRuleActivityType type) => switch (type) {
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
