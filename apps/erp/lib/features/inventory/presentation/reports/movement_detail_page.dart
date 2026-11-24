import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/reports/movement_detail_cubit.dart';
import 'package:erp/features/inventory/logic/reports/movement_detail_state.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

const VResponsiveValue<double> _wideContentMaxWidth = VResponsiveValue(
  mobile: double.infinity,
  tablet: 640,
  desktop: 960,
);

/// SCR-056: Chi tiết một biến động kho.
class MovementDetailPage extends StatelessWidget {
  const MovementDetailPage({
    super.key,
    required this.movementId,
    this.onOpenSource,
    this.onBack,
  });

  final String movementId;

  /// Nhận đường dẫn của phiếu gốc (Q-7-5). Mặc định `context.push`.
  final ValueChanged<String>? onOpenSource;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          MovementDetailCubit(resolveReportsRepository(ctx), movementId)..load(),
      child: _MovementDetailView(onOpenSource: onOpenSource, onBack: onBack),
    );
  }
}

class _MovementDetailView extends StatelessWidget {
  const _MovementDetailView({required this.onOpenSource, required this.onBack});

  final ValueChanged<String>? onOpenSource;
  final VoidCallback? onBack;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/warehouse');
    }
  }

  void _openSource(BuildContext context, String route) {
    if (onOpenSource != null) {
      onOpenSource!(route);
      return;
    }
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<MovementDetailCubit>();
    final state = cubit.state;
    final data = state.data;
    final isWide = inventoryIsWide(context);
    final ready = state.status == ReportStatus.ready && data != null;
    final route = ready ? data.source.route : null;

    final String title;
    String? subtitle;
    if (ready) {
      final label = movementLabel(data.movementKind, data.intentType, data.reason);
      title = data.source.docCode.isEmpty
          ? label
          : '$label ${data.source.docCode}';
      subtitle = data.product.name +
          (data.product.isLotTracked && data.lotCode != null
              ? ' · Lô ${data.lotCode}'
              : '');
    } else {
      title = 'Chi tiết biến động';
    }

    return VPageScaffold(
      title: title,
      subtitle: subtitle,
      // Web: hai cột (số liệu rộng hơn Nguồn), nội dung có bề rộng tối đa như prototype.
      contentMaxWidth: isWide ? _wideContentMaxWidth : VPageScaffold.defaultContentMaxWidth,
      leading: reportBackButton(() => _back(context)),
      bottomBar: route == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: InventoryFooter(
                actions: [
                  InventoryFooterAction(
                    label: 'Mở phiếu gốc',
                    onPressed: () => _openSource(context, route),
                  ),
                ],
              ),
            ),
      body: _body(context, cubit, state, data),
    );
  }

  Widget _body(
    BuildContext context,
    MovementDetailCubit cubit,
    MovementDetailState state,
    MovementDetail? data,
  ) {
    if (state.status == ReportStatus.denied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryDenied(
            what: 'xem chi tiết biến động',
            next: 'Liên hệ chủ cửa hàng để được cấp quyền xem Kho.',
            onExit: () => _back(context),
          ),
        ),
      );
    }
    if (state.status == ReportStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(VSpacing.space4),
        child: InventoryLoading(
          blocks: [
            InventorySkeletonBlock.heading,
            InventorySkeletonBlock.card,
            InventorySkeletonBlock.card,
          ],
        ),
      );
    }
    if (state.status == ReportStatus.error || data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: InventoryEmpty(
            title: state.message ?? 'Không tải được chi tiết biến động.',
            description: 'Kiểm tra kết nối rồi thử lại.',
            actionLabel: 'Thử lại',
            onAction: cubit.load,
          ),
        ),
      );
    }

    final uom = data.product.uom;
    final delta = data.quantityDelta;
    final deltaText =
        delta == 0 ? '0 $uom' : '${signedQty(delta)} $uom';

    final quantity = VKeyValueGroup(
      title: 'Số lượng',
      rows: [
        VKeyValueRow(
          label: 'Trước',
          value: formatStockQuantity(data.beforeQty, uom),
          mono: true,
        ),
        VKeyValueRow(label: 'Biến động', value: deltaText, mono: true),
        VKeyValueRow(
          label: 'Sau',
          value: formatStockQuantity(data.afterQty, uom),
          mono: true,
        ),
        if (data.product.isLotTracked && data.lotCode != null)
          VKeyValueRow(label: 'Lô', value: data.lotCode!, mono: true),
      ],
    );
    final who = VKeyValueGroup(
      title: 'Thời gian và người thực hiện',
      rows: [
        VKeyValueRow(
          label: 'Ngày nghiệp vụ',
          value: reportDate(data.businessDate),
          mono: true,
        ),
        VKeyValueRow(
          label: 'Ngày ghi nhận',
          value: asOfText(data.recordedAt),
          mono: true,
        ),
        VKeyValueRow(label: 'Người thực hiện', value: data.actorName),
      ],
    );
    final value = data.valueAmount == null
        ? null
        : VKeyValueGroup(
            title: 'Giá trị',
            rows: [
              VKeyValueRow(
                label: 'Tác động',
                value: signedMoney(data.valueAmount!),
                mono: true,
              ),
            ],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: K7Split(
        wideMain: true,
        main: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            quantity,
            const SizedBox(height: VSpacing.space3),
            who,
            if (value != null) ...[
              const SizedBox(height: VSpacing.space3),
              value,
            ],
          ],
        ),
        aside: MovementSourceTimeline(detail: data),
      ),
    );
  }
}

/// Khối "Nguồn": giao dịch gốc → ghi nhận kho → tồn thay đổi.
class MovementSourceTimeline extends StatelessWidget {
  const MovementSourceTimeline({super.key, required this.detail});

  final MovementDetail detail;

  @override
  Widget build(BuildContext context) {
    final uom = detail.product.uom;
    final delta = detail.quantityDelta;
    final move = delta == 0
        ? 'Tồn không đổi'
        : '${delta > 0 ? 'Tồn tăng' : 'Tồn giảm'} '
            '${formatStockQuantity(delta.abs(), uom)}';

    final items = <_TimelineItem>[
      _TimelineItem(
        icon: VIcons.success,
        title: detail.source.docCode.isEmpty ? '—' : detail.source.docCode,
        detail: 'Giao dịch nguồn được hoàn tất',
      ),
      _TimelineItem(
        icon: VIcons.info,
        title: 'Đã ghi nhận kho',
        detail: asOfText(detail.recordedAt),
      ),
      _TimelineItem(
        icon: VIcons.edit,
        title: move,
        detail: 'Số dư sau biến động: ${formatStockQuantity(detail.afterQty, uom)}',
      ),
    ];

    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.space2),
          child: Text(
            'Nguồn',
            style: VTypography.headingH4.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        VCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: VSpacing.space2),
                    child: VDivider(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final VIcons icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VIcon(icon: icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: VSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                detail,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 20 / 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
