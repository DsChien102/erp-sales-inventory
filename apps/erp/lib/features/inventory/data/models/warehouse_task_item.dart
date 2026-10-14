import 'package:equatable/equatable.dart';
import 'package:vet45_design_system/design_system.dart';

class WarehouseTaskItem extends Equatable {
  const WarehouseTaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon,
    this.badgeLabel,
    this.badgeTone,
    this.routePath,
  });

  final String id;
  final String title;
  final String subtitle;
  final VIcons? icon;
  final String? badgeLabel;
  final VComponentTone? badgeTone;
  final String? routePath;

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        icon,
        badgeLabel,
        badgeTone,
        routePath,
      ];
}
