import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../data/einvoice_configuration_repository.dart';
import '../../logic/automation_policy_cubit.dart';
import '../support/automation_policy_copy.dart';
import '../widgets/automation_policy_view.dart';

class AutomationPolicyPage extends StatelessWidget {
  const AutomationPolicyPage({
    super.key,
    required this.repository,
    this.onCancel,
    this.onBack,
  });

  final EInvoiceConfigurationRepository repository;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AutomationPolicyCubit(
        repository: repository,
      )..load(),
      child: VPageScaffold(
        title: AutomationPolicyCopy.pageTitle,
        showBackButton: true,
        body: AutomationPolicyView(
          onCancel: onCancel,
          onBack: onBack,
        ),
      ),
    );
  }
}
