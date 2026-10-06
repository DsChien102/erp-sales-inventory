import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview/default_pair_gate_error_preview_section.dart';

class DashboardPreviewHomeScreen extends StatelessWidget {
  const DashboardPreviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.space4),
        children: const [DefaultPairGateErrorPreviewSection()],
      ),
    );
  }
}
