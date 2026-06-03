import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
    return VMetricCard(
      icon: Icon(icon),
      value: value,
      label: label,
      iconColor: iconColor,
      iconBgColor: iconBackgroundColor,
    );
  }
}
