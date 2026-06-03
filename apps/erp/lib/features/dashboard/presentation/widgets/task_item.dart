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

  @override
  Widget build(BuildContext context) {
    VBadgeStatus badgeStatus = VBadgeStatus.warning;
    if (iconColor == const Color(0xFFE53935) || iconColor == const Color(0xFFEF4444)) {
      badgeStatus = VBadgeStatus.danger;
    } else if (iconColor == const Color(0xFF2E8D43)) {
      badgeStatus = VBadgeStatus.success;
    } else if (iconColor == const Color(0xFF2563EB)) {
      badgeStatus = VBadgeStatus.info;
    }

    return VTodoItem(
      leadingIcon: Icon(icon),
      title: title,
      subtitle: subtitle,
      badgeLabel: badgeLabel,
      badgeStatus: badgeStatus,
      onTap: () {},
    );
  }
}
