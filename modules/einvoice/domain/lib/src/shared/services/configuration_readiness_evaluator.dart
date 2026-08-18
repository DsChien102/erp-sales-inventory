import 'package:equatable/equatable.dart';

import '../configuration_readiness_level.dart';
import '../issuance_purpose.dart';
import '../../provider_connection/provider_connection_status.dart';
import '../../issuance_profile/signing_method.dart';

/// A readiness blocker with machine code and human message.
final class ReadinessBlocker extends Equatable {
  const ReadinessBlocker({required this.code, required this.message});

  final String code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

/// A readiness warning with machine code and human message.
final class ReadinessWarning extends Equatable {
  const ReadinessWarning({required this.code, required this.message});

  final String code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

/// Result of configuration readiness evaluation (read model).
final class ConfigurationReadinessEvaluation extends Equatable {
  const ConfigurationReadinessEvaluation({
    required this.level,
    required this.blockers,
    required this.warnings,
  });

  final ConfigurationReadinessLevel level;
  final List<ReadinessBlocker> blockers;
  final List<ReadinessWarning> warnings;

  @override
  List<Object?> get props => [level, blockers, warnings];
}

/// Input snapshot for readiness evaluation.
final class ConfigurationReadinessInput {
  const ConfigurationReadinessInput({
    this.hasLegalProfile = false,
    this.legalName,
    this.taxCode,
    this.connectionStatus = ProviderConnectionStatus.disconnected,
    this.hasDefaultTemplate = false,
    this.templateAvailable = false,
    this.signingMethod,
    this.signingAvailable = false,
    this.templateIsMtt = false,
    this.signingSupportsAutoIssue = false,
    this.autoIssueEnabled = false,
    this.providerSupportsEmail = false,
    this.templateDeprecated = false,
    this.purpose,
  });

  final bool hasLegalProfile;
  final String? legalName;
  final String? taxCode;
  final ProviderConnectionStatus connectionStatus;
  final bool hasDefaultTemplate;
  final bool templateAvailable;
  final SigningMethod? signingMethod;
  final bool signingAvailable;
  final bool templateIsMtt;
  final bool signingSupportsAutoIssue;
  final bool autoIssueEnabled;
  final bool providerSupportsEmail;
  final bool templateDeprecated;
  final IssuancePurpose? purpose;
}

/// Pure evaluator for configuration readiness (US-04).
abstract final class ConfigurationReadinessEvaluator {
  static ConfigurationReadinessEvaluation evaluate(
    ConfigurationReadinessInput input,
  ) {
    final blockers = <ReadinessBlocker>[];
    final warnings = <ReadinessWarning>[];

    if (!input.hasLegalProfile ||
        (input.legalName?.trim().isEmpty ?? true) ||
        (input.taxCode?.trim().isEmpty ?? true)) {
      blockers.add(
        const ReadinessBlocker(
          code: 'legal_profile_incomplete',
          message: 'Legal profile is missing required seller information',
        ),
      );
    }

    if (input.connectionStatus != ProviderConnectionStatus.connected) {
      blockers.add(
        const ReadinessBlocker(
          code: 'provider_not_connected',
          message: 'Provider connection is not verified',
        ),
      );
    }

    if (!input.hasDefaultTemplate || !input.templateAvailable) {
      blockers.add(
        const ReadinessBlocker(
          code: 'template_unavailable',
          message: 'Default invoice template is not available',
        ),
      );
    }

    if (input.signingMethod == null || !input.signingAvailable) {
      blockers.add(
        const ReadinessBlocker(
          code: 'signing_unavailable',
          message: 'Signing configuration is missing or unavailable',
        ),
      );
    } else if (input.signingMethod == SigningMethod.noSign &&
        !input.templateIsMtt) {
      blockers.add(
        const ReadinessBlocker(
          code: 'signing_incompatible',
          message: 'No-sign is only valid for MTT templates',
        ),
      );
    }

    if (input.templateDeprecated) {
      warnings.add(
        const ReadinessWarning(
          code: 'template_deprecated',
          message: 'Default template may be deprecated at provider',
        ),
      );
    }

    final purpose = input.purpose;
    if (purpose == IssuancePurpose.autoIssue || input.autoIssueEnabled) {
      if (!input.signingSupportsAutoIssue) {
        blockers.add(
          const ReadinessBlocker(
            code: 'auto_issue_signing_unsupervised',
            message: 'Signing method does not support unsupervised auto-issue',
          ),
        );
      }
    }

    if (purpose == IssuancePurpose.autoSend && !input.providerSupportsEmail) {
      blockers.add(
        const ReadinessBlocker(
          code: 'auto_send_not_supported',
          message: 'Provider does not support email delivery',
        ),
      );
    }

    if (blockers.isNotEmpty) {
      return ConfigurationReadinessEvaluation(
        level: ConfigurationReadinessLevel.notReady,
        blockers: blockers,
        warnings: warnings,
      );
    }

    if (warnings.isNotEmpty) {
      final level = purpose == IssuancePurpose.autoIssue
          ? ConfigurationReadinessLevel.notReady
          : ConfigurationReadinessLevel.readyWithWarnings;
      return ConfigurationReadinessEvaluation(
        level: level,
        blockers: purpose == IssuancePurpose.autoIssue
            ? [
                const ReadinessBlocker(
                  code: 'auto_issue_warnings_present',
                  message: 'Auto-issue blocked while warnings remain',
                ),
              ]
            : const [],
        warnings: warnings,
      );
    }

    return const ConfigurationReadinessEvaluation(
      level: ConfigurationReadinessLevel.ready,
      blockers: [],
      warnings: [],
    );
  }
}
