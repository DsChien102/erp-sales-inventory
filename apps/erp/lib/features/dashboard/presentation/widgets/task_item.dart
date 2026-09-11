import 'package:flutter/material.dart';
import 'package:erp/features/dashboard/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class TaskItem extends StatelessWidget {
  const TaskItem({
    required this.icon,
    required this.badgeStatus,
    this.title = 'Công việc cần xử lý',
    this.subtitle = 'Mô tả công việc chi tiết',
    this.badgeLabel = 'Chờ xử lý',
    super.key,
  });

  final IconData icon;
  final VBadgeStatus badgeStatus;
  final String title;
  final String subtitle;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    return TodoItem(
      leadingIcon: Icon(icon),
      title: title,
      subtitle: subtitle,
      badgeLabel: badgeLabel,
      badgeStatus: badgeStatus,
      onTap: () {},
    );
  }
}
