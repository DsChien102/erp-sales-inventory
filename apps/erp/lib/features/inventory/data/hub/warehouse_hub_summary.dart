import 'package:equatable/equatable.dart';
import 'package:vet45_design_system/design_system.dart';

class WarehousePendingItem extends Equatable {
  const WarehousePendingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final VIcons icon;
  final String route;

  @override
  List<Object?> get props => [title, subtitle, icon, route];
}

class WarehousePendingGroup extends Equatable {
  const WarehousePendingGroup({
    required this.sourceId,
    required this.label,
    required this.items,
  });

  final String sourceId;
  final String label;
  final List<WarehousePendingItem> items;

  @override
  List<Object?> get props => [sourceId, label, items];
}

class WarehouseAttention extends Equatable {
  const WarehouseAttention({
    required this.count,
    required this.text,
  });

  final int count;
  final String text;

  @override
  List<Object?> get props => [count, text];
}

class WarehouseHubSummary extends Equatable {
  const WarehouseHubSummary({
    required this.activated,
    this.pending = const [],
    this.problems,
    this.reconciliation,
  });

  final bool activated;
  final List<WarehousePendingGroup> pending;
  final WarehouseAttention? problems;
  final WarehouseAttention? reconciliation;

  int get pendingTotal =>
      pending.fold<int>(0, (sum, g) => sum + g.items.length);

  String get pendingText {
    final activeGroups = pending.where((g) => g.items.isNotEmpty).toList();
    if (activeGroups.isEmpty) return '';
    return activeGroups
        .map((g) => '${g.items.length} ${g.label}')
        .join(' · ');
  }

  @override
  List<Object?> get props => [activated, pending, problems, reconciliation];
}
