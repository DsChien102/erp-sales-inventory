import 'package:flutter/material.dart';
import 'package:vet45_dashboard_presentation/presentation.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.label,
    this.value = '-',
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      icon: Icon(icon),
      value: value,
      label: label,
      iconColor: iconColor,
      iconBgColor: iconBackgroundColor,
    );
  }
}
