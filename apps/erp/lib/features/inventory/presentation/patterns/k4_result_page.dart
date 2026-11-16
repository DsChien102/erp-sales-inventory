import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/core/inventory_command_result.dart';
import '../../logic/inventory_format.dart';
import 'inventory_footer.dart';
import 'inventory_layout.dart';

enum K4Kind {
  success,
  pending,
  warning,
  danger,
}

class K4StockChange {
  const K4StockChange({
    required this.product,
    required this.before,
    required this.after,
  });

  final String product;
  final String before;
  final String after;
}

extension InventoryCommandResultK4X on InventoryCommandResult {
  List<K4StockChange> toK4() {
    return stockChanges.map((sc) {
      final unitSuffix = sc.baseUom.trim().isNotEmpty ? ' ${sc.baseUom.trim()}' : '';
      return K4StockChange(
        product: sc.productName,
        before: '${formatQuantity(sc.before.toDouble())}$unitSuffix',
        after: '${formatQuantity(sc.after.toDouble())}$unitSuffix',
      );
    }).toList(growable: false);
  }
}

class K4ResultPage extends StatelessWidget {
  const K4ResultPage({
    super.key,
    this.screenTitle = 'Kết quả',
    this.kind = K4Kind.success,
    required this.title,
    required this.description,
    this.facts = const [],
    this.stockChanges = const [],
    this.extra,
    this.next = const [],
    this.showBackButton = true,
    this.onBack,
  });

  final String screenTitle;
  final K4Kind kind;
  final String title;
  final String description;
  final List<VKeyValueRow> facts;
  final List<K4StockChange> stockChanges;
  final Widget? extra;
  final List<InventoryFooterAction> next;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton && (onBack != null || canPop);

    final resolvedLeading = shouldShowBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay lại',
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else if (canPop) {
                Navigator.of(context).pop();
              }
            },
          )
        : null;

    final (icon, tone) = switch (kind) {
      K4Kind.success => (VIcons.success, VComponentTone.success),
      K4Kind.pending => (VIcons.clock, VComponentTone.warning),
      K4Kind.warning => (VIcons.warning, VComponentTone.warning),
      K4Kind.danger => (VIcons.error, VComponentTone.danger),
    };

    final allRows = [
      ...facts,
      ...stockChanges.map(
        (c) => VKeyValueRow(
          label: 'Tồn kho đã đổi',
          value: '${c.product} ${c.before} → ${c.after}',
          mono: true,
        ),
      ),
    ];

    Widget body = SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: VSpacing.space4),
          Center(
            child: VIconBox(
              icon: icon,
              size: 56,
              iconSize: 28,
              tone: tone,
              borderRadius: VRadius.r16,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VText(
            title,
            variant: VTextVariant.headingH2,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space1),
          VText(
            description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (allRows.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space4),
            VKeyValueGroup(rows: allRows),
          ],
          if (extra != null) ...[
            const SizedBox(height: VSpacing.space4),
            extra!,
          ],
          if (next.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space4),
            InventoryFooter(actions: next),
          ],
        ],
      ),
    );

    if (isWide) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      );
    }

    return VPageScaffold(
      title: screenTitle,
      showBackButton: false,
      leading: resolvedLeading,
      body: body,
    );
  }
}
