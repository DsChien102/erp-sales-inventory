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

  /// MISA wire `SignType` for Phase 1: `2` (HSM) or `5` (MTT / no CKS).
  ///
  /// Returns null when [method] is incompatible with [templateIsMtt].
  int? resolveWireSignType({required bool templateIsMtt}) {
    switch (method) {
      case SigningMethod.hsm:
        return templateIsMtt ? null : 2;
      case SigningMethod.noSign:
      case SigningMethod.mtt:
        return templateIsMtt ? 5 : null;
    }
  }

  @override
  List<Object?> get props => [
    signingConfigId,
    method,
    label,
    isAvailable,
    supportsUnsupervisedAutoIssue,
  ];
}
