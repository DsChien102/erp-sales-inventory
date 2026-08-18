import 'package:equatable/equatable.dart';

import 'signing_method.dart';

/// Reference to a signing configuration option.
final class SigningConfigurationRef extends Equatable {
  const SigningConfigurationRef({
    required this.signingConfigId,
    required this.method,
    this.label,
    this.isAvailable = true,
    this.supportsUnsupervisedAutoIssue = false,
  });

  final String signingConfigId;
  final SigningMethod method;
  final String? label;
  final bool isAvailable;
  final bool supportsUnsupervisedAutoIssue;

  @override
  List<Object?> get props => [
    signingConfigId,
    method,
    label,
    isAvailable,
    supportsUnsupervisedAutoIssue,
  ];
}
