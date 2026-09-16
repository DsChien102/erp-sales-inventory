import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class EInvoiceConfigurationOverviewPage extends StatefulWidget {
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
  final Future<void> Function()? onConnectionTap;
  final Future<void> Function()? onIssuanceTap;
  final Future<void> Function()? onAutomationTap;
  final VoidCallback? onBack;

  @override
  State<EInvoiceConfigurationOverviewPage> createState() =>
      _EInvoiceConfigurationOverviewPageState();
}

class _EInvoiceConfigurationOverviewPageState extends State<EInvoiceConfigurationOverviewPage> {
  late final EInvoiceConfigurationOverviewCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = EInvoiceConfigurationOverviewCubit(
      einvoiceModule: widget.einvoiceModule,
      executionContext: widget.executionContext,
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openConnection() async {
    await widget.onConnectionTap?.call();
    if (mounted) {
      await _cubit.load();
    }
  }

  Future<void> _openIssuance() async {
    await widget.onIssuanceTap?.call();
    if (mounted) {
      await _cubit.load();
    }
  }

  Future<void> _openAutomation() async {
    await widget.onAutomationTap?.call();
    if (mounted) {
      await _cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: VPageScaffold(
        title: 'Hóa đơn điện tử',
        showBackButton: true,
        body: EInvoiceConfigurationOverviewView(
          onConnectionTap: _openConnection,
          onIssuanceTap: _openIssuance,
          onAutomationTap: _openAutomation,
          onBack: widget.onBack,
        ),
      ),
    );
  }
}
