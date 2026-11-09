import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'inventory_footer.dart';
import 'inventory_layout.dart';

class K3UnknownPage extends StatelessWidget {
  const K3UnknownPage({
    super.key,
    this.title = 'Xác minh kết quả',
    required this.operation,
    required this.scope,
    required this.ref,
    required this.sentAt,
    this.safe = '',
    this.facts = const [],
    this.detail,
    required this.onExit,
    this.onVerify,
  });

  final String title;
  final String operation;
  final String scope;
  final String ref;
  final String sentAt;
  final String safe;
  final List<VKeyValueRow> facts;
  final Widget? detail;
  final VoidCallback onExit;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isWide = inventoryIsWide(context);

    final safeSuffix = safe.isNotEmpty ? ' $safe' : '';
    final description =
        'Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.$safeSuffix';

    final rows = [
      VKeyValueRow(label: 'Nghiệp vụ', value: operation),
      VKeyValueRow(label: 'Phạm vi', value: scope),
      VKeyValueRow(label: 'Mã tham chiếu', value: ref, mono: true),
      VKeyValueRow(label: 'Thời điểm gửi', value: sentAt, mono: true),
      ...facts,
      const VKeyValueRow(label: 'Trạng thái', value: 'Chưa kết luận'),
    ];

    final actions = onVerify != null
        ? [
            InventoryFooterAction(
              label: 'Về Kho',
              onPressed: onExit,
            ),
            InventoryFooterAction(
              label: 'Chuyển sang xác minh',
              primary: true,
              onPressed: onVerify,
            ),
          ]
        : [
            InventoryFooterAction(
              label: 'Về Kho',
              primary: true,
              onPressed: onExit,
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
              icon: VIcons.clock,
              size: 56,
              iconSize: 28,
              tone: VComponentTone.warning,
              borderRadius: VRadius.r16,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          const VText(
            'Kết quả chưa xác định',
            variant: VTextVariant.headingH2,
            style: TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space1),
          VText(
            description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space4),
          VKeyValueGroup(rows: rows),
          if (detail != null) ...[
            const SizedBox(height: VSpacing.space4),
            detail!,
          ],
          const SizedBox(height: VSpacing.space4),
          InventoryFooter(actions: actions),
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
      title: title,
      showBackButton: false,
      body: body,
    );
  }
}
