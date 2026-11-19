import 'package:erp/features/dashboard/presentation/widgets/default_pair_gate_error_view.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class DefaultPairGateErrorPreviewSection extends StatelessWidget {
  const DefaultPairGateErrorPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default pair gate error', style: VTypography.headingH3),
          const SizedBox(height: VSpacing.space2),
          const DefaultPairGateErrorView(
            onRetry: _noop,
            onChooseOrganization: _noop,
          ),
        ],
      ),
    );
  }
}

void _noop() {}
