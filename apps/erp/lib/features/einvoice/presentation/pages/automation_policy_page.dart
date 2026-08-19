import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class AutomationPolicyPage extends StatelessWidget {
  const AutomationPolicyPage({
    super.key,
    required this.einvoiceModule,
    required this.executionContext,
    this.onCancel,
    this.onBack,
  });

  final IEInvoiceModule einvoiceModule;
  final IExecutionContext executionContext;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AutomationPolicyCubit(
        einvoiceModule: einvoiceModule,
        executionContext: executionContext,
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
