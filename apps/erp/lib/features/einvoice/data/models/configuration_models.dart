import 'einvoice_enums.dart';

/// Read-only legal profile shown on provider connection screen.
final class LegalProfileSummaryDto {
  const LegalProfileSummaryDto({
    required this.legalName,
    required this.taxCode,
    this.address,
  });

  final String legalName;
  final String taxCode;
  final String? address;
}

/// Connection summary for settings screen.
final class ProviderConnectionSummaryDto {
  const ProviderConnectionSummaryDto({
    this.connectionId,
    required this.status,
    this.lastCheckedAt,
    this.maskedAccount,
    this.connectionVersion,
  });

  final String? connectionId;
  final ProviderConnectionStatus status;
  final DateTime? lastCheckedAt;
  final String? maskedAccount;
  final int? connectionVersion;
}

/// Readiness blocker surfaced to UI.
final class ReadinessBlockerDto {
  const ReadinessBlockerDto({required this.code, required this.message});

  final String code;
  final String message;
}

/// Non-blocking readiness warning.
final class ReadinessWarningDto {
  const ReadinessWarningDto({required this.code, required this.message});

  final String code;
  final String message;
}

/// Provider connection result.
final class ProviderConnectionResultDto {
  const ProviderConnectionResultDto({
    required this.connectionId,
    required this.status,
  });

  final String connectionId;
  final ProviderConnectionStatus status;
}

/// Automation policy settings.
final class AutomationPolicyDto {
  const AutomationPolicyDto({
    required this.autoIssueEnabled,
    required this.autoSendEnabled,
    required this.policyVersion,
    required this.blockers,
  });

  final bool autoIssueEnabled;
  final bool autoSendEnabled;
  final int policyVersion;
  final List<String> blockers;
}

/// Configuration readiness read model.
final class ConfigurationReadinessDto {
  const ConfigurationReadinessDto({
    required this.level,
    required this.blockers,
    required this.warnings,
  });

  final ConfigurationReadinessLevel level;
  final List<ReadinessBlockerDto> blockers;
  final List<ReadinessWarningDto> warnings;
}

/// Issuance profile settings.
final class IssuanceProfileDto {
  const IssuanceProfileDto({
    required this.profileVersion,
    this.templateId,
    this.signingConfigId,
    this.signingMethod,
    required this.compatibilityWarnings,
  });

  final int profileVersion;
  final String? templateId;
  final String? signingConfigId;
  final SigningMethod? signingMethod;
  final List<String> compatibilityWarnings;
}

/// Aggregate provider connection screen data.
final class ProviderConnectionScreenDto {
  const ProviderConnectionScreenDto({
    required this.legalProfile,
    required this.connection,
  });

  final LegalProfileSummaryDto legalProfile;
  final ProviderConnectionSummaryDto connection;
}

/// Provider template.
final class ProviderTemplateDto {
  const ProviderTemplateDto({
    required this.templateId,
    required this.name,
    this.serial,
    this.symbol,
    this.invoiceSeries,
    this.invoiceWithCode,
    this.isMtt,
    this.isSendSummary,
  });

  final String templateId;
  final String name;
  final String? serial;
  final String? symbol;
  final String? invoiceSeries;
  final bool? invoiceWithCode;
  final bool? isMtt;
  final bool? isSendSummary;
}

