import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../data/einvoice_configuration_repository.dart';
import '../../logic/provider_connection_copy.dart';
import '../../logic/provider_connection_cubit.dart';
import '../widgets/provider_connection_view.dart';

class ProviderConnectionPage extends StatelessWidget {
  const ProviderConnectionPage({
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
      create: (_) => ProviderConnectionCubit(
        repository: repository,
      )..load(),
      child: VPageScaffold(
        title: ProviderConnectionCopy.pageTitle,
        showBackButton: true,
        body: ProviderConnectionView(
          onCancel: onCancel,
          onBack: onBack,
        ),
      ),
    );
  }
}
