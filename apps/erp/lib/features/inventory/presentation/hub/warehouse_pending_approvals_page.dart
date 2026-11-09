import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_repository.dart';
import 'package:erp/features/inventory/data/hub/warehouse_hub_summary.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_cubit.dart';
import 'package:erp/features/inventory/logic/hub/warehouse_hub_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';

/// Màn hình danh sách chứng từ chờ duyệt kho.
class WarehousePendingApprovalsPage extends StatefulWidget {
  const WarehousePendingApprovalsPage({super.key, this.cubit});

  final WarehouseHubCubit? cubit;

  @override
  State<WarehousePendingApprovalsPage> createState() =>
      _WarehousePendingApprovalsPageState();
}

class _WarehousePendingApprovalsPageState
    extends State<WarehousePendingApprovalsPage> {
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
    return BlocBuilder<WarehouseHubCubit, WarehouseHubState>(
      bloc: _cubit,
      builder: (context, state) {
        return VPageScaffold(
          title: 'Chờ duyệt',
          leading: IconButton(
            icon: const VIcon(icon: VIcons.arrowLeft),
            tooltip: 'Quay lại',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                GoRouter.of(context).go('/warehouse');
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
              InventorySkeletonBlock.heading,
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
      WarehouseHubLoaded(:final summary) => _buildLoaded(context, summary),
    };
  }

  Widget _buildLoaded(
    BuildContext context,
    WarehouseHubSummary summary,
  ) {
    final items = summary.pending.expand((g) => g.items).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: VSection(
        title: 'Đang chờ xử lý',
        trailing: summary.pendingText.isNotEmpty
            ? VText(summary.pendingText)
            : null,
        child: Column(
          children: items.map<Widget>((item) {
            return VListRow(
              leading: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              trailing: const VBadge(
                label: 'Chờ duyệt',
                tone: VComponentTone.warning,
              ),
              onTap: () => context.push(item.route),
            );
          }).toList(),
        ),
      ),
    );
  }
}
