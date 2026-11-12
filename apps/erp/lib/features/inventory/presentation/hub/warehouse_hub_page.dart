import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_state.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';

/// SCR-090: Màn hình Home Kho.
class WarehouseHubPage extends StatefulWidget {
  const WarehouseHubPage({super.key, this.cubit});

  final WarehouseHubCubit? cubit;

  @override
  State<WarehouseHubPage> createState() => _WarehouseHubPageState();
}

class _WarehouseHubPageState extends State<WarehouseHubPage> {
  late final WarehouseHubCubit _cubit;
  late final bool _internalCubit;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _internalCubit = false;
      if (_cubit.state is WarehouseHubLoading) {
        _cubit.load();
      }
    } else {
      _cubit = WarehouseHubCubit(
        repository: getIt<WarehouseHubRepository>(),
        isOwner: () => getIt.isRegistered<SessionStore>()
            ? getIt<SessionStore>().isOwner
            : true,
      )..load();
      _internalCubit = true;
    }
  }

  @override
  void dispose() {
    if (_internalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);

    return BlocBuilder<WarehouseHubCubit, WarehouseHubState>(
      bloc: _cubit,
      builder: (context, state) {
        return VPageScaffold(
          title: 'Kho',
          showBackButton: false,
          leading: isWide
              ? null
              : IconButton(
                  icon: const VIcon(icon: VIcons.arrowLeft),
                  tooltip: 'Quay lại',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      GoRouter.of(context).go('/more');
                    }
                  },
                ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WarehouseHubState state) {
    return switch (state) {
      WarehouseHubLoading() => const SingleChildScrollView(
          padding: EdgeInsets.all(VSpacing.space4),
          child: InventoryLoading(
            blocks: [
              InventorySkeletonBlock.search,
              InventorySkeletonBlock.card,
              InventorySkeletonBlock.row,
              InventorySkeletonBlock.row,
            ],
          ),
        ),
      WarehouseHubError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: InventoryEmpty(
              title: 'Chưa tải được Kho',
              description: message,
              actionLabel: 'Thử lại',
              onAction: () => _cubit.load(),
            ),
          ),
        ),
      WarehouseHubLoaded() => _buildLoaded(context, state),
    };
  }

  Widget _buildLoaded(BuildContext context, WarehouseHubLoaded state) {
    final isWide = inventoryIsWide(context);
    final summary = state.summary;

    // 1. Ô tìm kiếm
    final searchWidget = VSearchBar(
      hintText: 'Tìm sản phẩm, SKU hoặc quét mã',
      onSubmitted: (q) {
        if (q.trim().isNotEmpty) {
          final target = warehouseStockSearchRoute;
          context.push(
            '$target?q=${Uri.encodeQueryComponent(q.trim())}',
          );
        }
      },
    );

    final wrappedSearch = isWide
        ? Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: searchWidget,
            ),
          )
        : searchWidget;

    // 2. Banner chưa có hàng
    Widget? bannerWidget;
    if (!summary.activated) {
      final receiptEntries = warehouseAreaEntries(WarehouseArea.movement);
      final receiptEntry = receiptEntries.firstWhere((e) => e.id == 'receipts');

      bannerWidget = VBanner(
        title: 'Kho chưa có hàng',
        tone: VComponentTone.info,
        description:
            'Tạo phiếu nhận đầu tiên để bắt đầu theo dõi tồn kho và biến động.',
        footer: receiptEntry.route != null
            ? VButton(
                label: 'Lập phiếu nhận',
                variant: VButtonVariant.primary,
                onPressed: () => context.push(receiptEntry.route!),
              )
            : null,
      );
    }

    // 3. Nút nhanh (1 hàng trên mobile và web)
    final actionButtons = warehouseQuickActions.map((action) {
      final isEnabled = !action.requiresActivation || summary.activated;
      return VQuickActionButton(
        label: action.label,
        icon: action.icon,
        onPressed: isEnabled && action.route != null
            ? () => context.push(action.route!)
            : null,
      );
    }).toList();

    Widget? quickActionsWidget;
    if (actionButtons.isNotEmpty) {
      if (isWide) {
        quickActionsWidget = Row(
          children: actionButtons
              .map(
                (btn) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: btn,
                  ),
                ),
              )
              .toList(),
        );
      } else {
        quickActionsWidget = Row(
          children: [
            for (int i = 0; i < actionButtons.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: actionButtons[i]),
            ],
          ],
        );
      }
    }

    // 4. Section "Cần chú ý"
    final attentionRows = <Widget>[];

    if (summary.activated && summary.problems != null) {
      attentionRows.add(
        VListRow(
          asCard: true,
          leading: VIcons.shield,
          leadingBackgroundColor: const Color(0xFFFFF7E6),
          leadingIconColor: const Color(0xFFE37400),
          title: 'Tồn kho cần chú ý',
          subtitle: summary.problems!.text,
          trailing: _buildCountBadge(summary.problems!.count),
          onTap: () => context.push('/warehouse/stock'),
        ),
      );
    }

    if (summary.activated && summary.openStocktakes > 0) {
      final n = summary.openStocktakes;
      attentionRows.add(
        VListRow(
          asCard: true,
          leading: VIcons.checkList,
          title: 'Kiểm kê đang dở',
          subtitle: '$n phiên chưa ghi nhận',
          trailing: _buildCountBadge(n),
          onTap: () => context.push('/warehouse/stocktakes'),
        ),
      );
    }

    final attentionWidget = attentionRows.isNotEmpty
        ? VSection(
            title: 'Cần chú ý',
            child: Column(
              children: [
                for (int i = 0; i < attentionRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  attentionRows[i],
                ],
              ],
            ),
          )
        : null;

    // 5. Section "Quản lý kho"
    final managementAreas = [
      WarehouseArea.inventory,
      WarehouseArea.movement,
      WarehouseArea.control,
      if (state.isOwner) WarehouseArea.valuation,
      WarehouseArea.history,
      WarehouseArea.setup,
    ];
    final managementWidget = VSection(
      title: 'Quản lý kho',
      child: Column(
        children: [
          for (int i = 0; i < managementAreas.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            VListRow(
              asCard: true,
              bareLeading: true,
              leading: managementAreas[i].icon,
              title: managementAreas[i].title,
              subtitle: managementAreas[i].subtitle,
              onTap: () => context.push('/warehouse/area/${managementAreas[i].id}'),
            ),
          ],
        ],
      ),
    );

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            wrappedSearch,
            const SizedBox(height: VSpacing.space4),
            if (quickActionsWidget != null) ...[
              quickActionsWidget,
              const SizedBox(height: VSpacing.space4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (bannerWidget != null) ...[
                        bannerWidget,
                        const SizedBox(height: VSpacing.space4),
                      ],
                      ?attentionWidget,
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      managementWidget,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          wrappedSearch,
          const SizedBox(height: VSpacing.space4),
          if (bannerWidget != null) ...[
            bannerWidget,
            const SizedBox(height: VSpacing.space4),
          ],
          if (quickActionsWidget != null) ...[
            quickActionsWidget,
            const SizedBox(height: VSpacing.space4),
          ],
          if (attentionWidget != null) ...[
            attentionWidget,
            const SizedBox(height: VSpacing.space4),
          ],
          managementWidget,
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF202124),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
