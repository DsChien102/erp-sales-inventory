import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/einvoice_configuration_repository.dart';
import '../../logic/default_issuance_configuration_copy.dart';
import '../../logic/default_issuance_configuration_cubit.dart';
import '../widgets/default_issuance_configuration_view.dart';

class DefaultIssuanceConfigurationPage extends StatelessWidget {
  const DefaultIssuanceConfigurationPage({
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
      create: (_) => DefaultIssuanceConfigurationCubit(
        repository: repository,
      )..load(),
      child: VPageScaffold(
        title: DefaultIssuanceConfigurationCopy.pageTitle,
        showBackButton: true,
        body: DefaultIssuanceConfigurationView(
          onCancel: onCancel,
          onBack: onBack,
        ),
      ),
    );
  }
}
