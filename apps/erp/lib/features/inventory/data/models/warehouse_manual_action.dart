import 'package:equatable/equatable.dart';
import 'package:vet45_design_system/design_system.dart';

class WarehouseManualAction extends Equatable {
  const WarehouseManualAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.routePath,
  });

  final String id;
  final String title;
  final String subtitle;
  final VIcons icon;
  final String? routePath;

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        icon,
        routePath,
      ];
}
