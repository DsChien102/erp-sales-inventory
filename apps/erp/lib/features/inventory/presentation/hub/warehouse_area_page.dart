import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/inventory/presentation/hub/warehouse_entries.dart';

/// SCR-091…096: Màn hình chi tiết phân khu kho.
///
/// Hiển thị danh sách các lối vào của khu, lọc bỏ các lối vào có route == null (Q9)
/// hoặc yêu cầu quyền owner mà user không có.
class WarehouseAreaPage extends StatelessWidget {
  const WarehouseAreaPage({
    super.key,
    required this.area,
    this.isOwner,
  });

  final WarehouseArea area;
  final bool? isOwner;

  bool _resolveIsOwner() {
    if (isOwner != null) return isOwner!;
    if (getIt.isRegistered<SessionStore>()) {
      return getIt<SessionStore>().isOwner;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOwner = _resolveIsOwner();
    final entries = warehouseAreaEntries(area)
        .where((e) => e.route != null && (!e.ownerOnly || effectiveOwner))
        .toList();

    return VPageScaffold(
      title: area.title,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: entries.isEmpty
            ? const SizedBox.shrink()
            : VSection(
                child: Column(
                  children: entries.map((e) {
                    return VListRow(
                      leading: e.icon,
                      title: e.title,
                      subtitle: e.subtitle,
                      onTap: () => context.push(e.route!),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
