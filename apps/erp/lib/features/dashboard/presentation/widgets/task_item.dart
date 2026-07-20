import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class TaskItem extends StatelessWidget {
  const TaskItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.title = 'Công việc cần xử lý',
    this.subtitle = 'Mô tả công việc chi tiết',
    this.badgeLabel = 'Chờ xử lý',
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String badgeLabel;

  VBadgeStatus get _badgeStatus {
    if (iconColor == VColors.danger) return VBadgeStatus.danger;
    if (iconColor == VColors.success) return VBadgeStatus.success;
    if (iconColor == VColors.info) return VBadgeStatus.info;
    if (iconColor == VColors.warning) return VBadgeStatus.warning;
    return VBadgeStatus.warning;
  }

  @override
  Widget build(BuildContext context) {
    return VTodoItem(
      leadingIcon: Icon(icon),
      title: title,
      subtitle: subtitle,
      badgeLabel: badgeLabel,
      badgeStatus: _badgeStatus,
      onTap: () {},
    );
  }
}
