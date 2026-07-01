import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class TransactionFilterBottomSheet extends StatefulWidget {
  const TransactionFilterBottomSheet({
    required this.initialTimeFilter,
    required this.initialTypeFilter,
    required this.initialStatusFilter,
    required this.partnerRole,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  final String initialTimeFilter;
  final String initialTypeFilter;
  final String initialStatusFilter;
  /// Vai trò đối tác: dùng để lọc loại giao dịch hiển thị trong bộ lọc.
  /// Khách hàng: ẩn Phiếu nhập hàng.
  /// Nhà cung cấp: ẩn Đơn bán hàng.
  final String partnerRole;
  final void Function(String time, String type, String status) onApply;
  final VoidCallback onReset;

  @override
  State<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends State<TransactionFilterBottomSheet> {
  late String _tempTime;
  late String _tempType;
  late String _tempStatus;

  @override
  void initState() {
    super.initState();
    _tempTime = widget.initialTimeFilter;
    _tempType = widget.initialTypeFilter;
    _tempStatus = widget.initialStatusFilter;
  }

  /// Tính danh sách loại giao dịch theo vai trò đối tác.
  /// - Chỉ Khách hàng: ẩn "Phiếu nhập hàng" (purchase).
  /// - Chỉ Nhà cung cấp: ẩn "Đơn bán hàng" (sales).
  /// - Cả hai vai trò hoặc không xác định: hiển thị tất cả.
  List<(String, String)> _typeOptions() {
    final role = widget.partnerRole.toLowerCase();
    final isCustomerOnly =
        role.contains('khách hàng') && !role.contains('nhà cung cấp');
    final isSupplierOnly =
        role.contains('nhà cung cấp') && !role.contains('khách hàng');
    return [
      ('Tất cả', 'all'),
      if (!isSupplierOnly) ('Đơn bán hàng', 'sales'),
      if (!isCustomerOnly) ('Phiếu nhập hàng', 'purchase'),
      ('Hóa đơn bán hàng', 'invoice'),
      ('Phiếu đổi/trả', 'return'),
    ];
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final colors = context.vColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VDuration.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space3,
          vertical: VSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceBrand : colors.surface,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected ? colors.primary : colors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: VTypography.bodySmall.copyWith(
            color: selected ? colors.primary : colors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<(String, String)> options,
    String current,
    void Function(String) onSelect,
  ) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        Wrap(
          spacing: VSpacing.space2,
          runSpacing: VSpacing.space2,
          children: options
              .map(
                (o) => _buildFilterChip(
                  context,
                  o.$1,
                  current == o.$2,
                  () => setState(() => onSelect(o.$2)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space4,
          VSpacing.space4,
          VSpacing.space2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lọc giao dịch',
                  style: VTypography.headingH4.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VIconBox(
                  iconData: Icons.close,
                  backgroundColor: Colors.transparent,
                  iconColor: colors.textPrimary,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: VSpacing.space3),
            _buildFilterSection(
              context,
              'THỜI GIAN',
              [
                ('Tất cả', 'all'),
                ('30 ngày', '30d'),
                ('90 ngày', '90d'),
                ('1 năm', '1y'),
              ],
              _tempTime,
              (v) => _tempTime = v,
            ),
            const SizedBox(height: VSpacing.space4),
            _buildFilterSection(
              context,
              'LOẠI GIAO DỊCH',
              _typeOptions(),
              _tempType,
              (v) => _tempType = v,
            ),
            const SizedBox(height: VSpacing.space4),
            _buildFilterSection(
              context,
              'TRẠNG THÁI',
              [
                ('Tất cả', 'all'),
                ('Đã hoàn tất', 'done'),
                ('Đã giao hàng', 'delivered'),
                ('Nhập', 'draft'),
                ('Đã hủy', 'cancelled'),
              ],
              _tempStatus,
              (v) => _tempStatus = v,
            ),
            const SizedBox(height: VSpacing.space5),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Đặt lại',
                    variant: VButtonVariant.outline,
                    foregroundColor: colors.textPrimary,
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    label: 'Áp dụng',
                    variant: VButtonVariant.primary,
                    onPressed: () {
                      widget.onApply(_tempTime, _tempType, _tempStatus);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space2),
          ],
        ),
      ),
    );
  }
}
