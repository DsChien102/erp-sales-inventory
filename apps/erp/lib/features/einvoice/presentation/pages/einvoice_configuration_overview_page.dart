import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class EInvoiceConfigurationOverviewPage extends StatelessWidget {
  const EInvoiceConfigurationOverviewPage({
    super.key,
    required this.einvoiceModule,
    required this.executionContext,
    this.onConnectionTap,
    this.onIssuanceTap,
    this.onAutomationTap,
    this.onBack,
  });

  final IEInvoiceModule einvoiceModule;
  final IExecutionContext executionContext;
  final VoidCallback? onConnectionTap;
  final VoidCallback? onIssuanceTap;
  final VoidCallback? onAutomationTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EInvoiceConfigurationOverviewCubit(
        einvoiceModule: einvoiceModule,
        executionContext: executionContext,
      )..load(),
      child: VPageScaffold(
        title: 'Hóa đơn điện tử',
        showBackButton: true,
        body: EInvoiceConfigurationOverviewView(
          onConnectionTap: onConnectionTap,
          onIssuanceTap: onIssuanceTap,
          onAutomationTap: onAutomationTap,
          onBack: onBack,
        ),
      ),
    );
  }
}
