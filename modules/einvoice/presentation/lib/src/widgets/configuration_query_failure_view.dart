import 'package:flutter/material.dart';

import '../support/configuration_query_failure.dart';
import 'configuration_load_error_state.dart';
import 'configuration_permission_denied_state.dart';

class ConfigurationQueryFailureView extends StatelessWidget {
  const ConfigurationQueryFailureView({
    super.key,
    required this.failure,
    this.onBack,
    this.onRetry,
  });

  final ConfigurationQueryFailure failure;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (failure) {
      ConfigurationQueryFailure.permissionDenied => ConfigurationPermissionDeniedState(
        onBack: onBack,
      ),
      ConfigurationQueryFailure.loadFailure => ConfigurationLoadErrorState(onRetry: onRetry),
    };
  }
}
