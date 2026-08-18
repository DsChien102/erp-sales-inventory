import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

abstract final class EinvoiceRpcMapper {
  static Map<String, dynamic> connectProviderParams(
    ConnectProviderCommand command,
  ) {
    return {
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_username': command.username.trim(),
      'p_password': command.password,
      if (command.expectedConnectionVersion != null)
        'p_expected_connection_version': command.expectedConnectionVersion,
    };
  }

  static Map<String, dynamic> verifyProviderParams(
    VerifyProviderConnectionCommand command,
  ) {
    return {
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_connection_id': command.connectionId,
    };
  }

  static Map<String, dynamic> reconnectProviderParams(
    ReconnectProviderCommand command,
  ) {
    return {
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_connection_id': command.connectionId,
      'p_username': command.username.trim(),
      'p_password': command.password,
    };
  }

  static Map<String, dynamic> disconnectProviderParams(
    DisconnectProviderCommand command,
  ) {
    return {
      'p_tenant_id': command.tenantId,
      'p_actor_id': command.actorId,
      'p_connection_id': command.connectionId,
      'p_confirm': command.confirm,
    };
  }

  static Map<String, dynamic> recordConnectionVerifiedParams(
    RecordConnectionVerifiedCommand command,
  ) {
    return {
      'p_tenant_id': command.tenantId,
      'p_connection_id': command.connectionId,
      'p_status': command.status.name,
      if (command.capabilities != null)
        'p_capabilities': {
          'supports_email_delivery': command.capabilities!.supportsEmailDelivery,
          'template_count': command.capabilities!.templateCount,
          if (command.capabilities!.syncedAt != null)
            'synced_at': command.capabilities!.syncedAt!.toUtc().toIso8601String(),
        },
      if (command.verifiedAt != null)
        'p_verified_at': command.verifiedAt!.toUtc().toIso8601String(),
      if (command.correlationId != null)
        'p_correlation_id': command.correlationId,
    };
  }

  static ProviderConnectionResultDto mapConnectionResult(
    Map<String, dynamic> row,
  ) {
    return ProviderConnectionResultDto(
      connectionId: row['connection_id'] as String,
      status: ProviderConnectionStatus.values.byName(row['status'] as String),
    );
  }

  static ProviderConnectionCheckResultDto mapConnectionCheckResult(
    Map<String, dynamic> row,
  ) {
    return ProviderConnectionCheckResultDto(
      connectionId: row['connection_id'] as String,
      status: ProviderConnectionStatus.values.byName(row['status'] as String),
      checkedAt: DateTime.parse(row['checked_at'] as String),
    );
  }

  static ProviderConnectionScreenDto mapConnectionScreen(
    Map<String, dynamic> row,
  ) {
    final legal = row['legal_profile'] as Map<String, dynamic>? ?? const {};
    final connection =
        row['connection'] as Map<String, dynamic>? ?? const {};
    return ProviderConnectionScreenDto(
      legalProfile: LegalProfileSummaryDto(
        legalName: legal['legal_name'] as String? ?? '',
        taxCode: legal['tax_code'] as String? ?? '',
        address: legal['address'] as String?,
      ),
      connection: ProviderConnectionSummaryDto(
        connectionId: connection['connection_id'] as String?,
        status: connection['status'] != null
            ? ProviderConnectionStatus.values.byName(
                connection['status'] as String,
              )
            : ProviderConnectionStatus.disconnected,
        lastCheckedAt: connection['last_checked_at'] != null
            ? DateTime.parse(connection['last_checked_at'] as String)
            : null,
      ),
    );
  }

  static List<ProviderTemplateDto> mapTemplateList(List<dynamic> rows) {
    return rows
        .map(
          (raw) => ProviderTemplateDto(
            templateId: raw['template_id'] as String,
            name: raw['name'] as String,
            serial: raw['serial'] as String?,
            symbol: raw['symbol'] as String?,
          ),
        )
        .toList(growable: false);
  }

  static IssuanceProfileDto mapIssuanceProfile(Map<String, dynamic> row) {
    return IssuanceProfileDto(
      profileVersion: row['profile_version'] as int? ?? 0,
      templateId: row['template_id'] as String?,
      signingConfigId: row['signing_config_id'] as String?,
      signingMethod: row['signing_method'] != null
          ? SigningMethod.values.byName(row['signing_method'] as String)
          : null,
      compatibilityWarnings: (row['compatibility_warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  static AutomationPolicyDto mapAutomationPolicy(Map<String, dynamic> row) {
    return AutomationPolicyDto(
      autoIssueEnabled: row['auto_issue_enabled'] as bool? ?? false,
      autoSendEnabled: row['auto_send_enabled'] as bool? ?? false,
      policyVersion: row['policy_version'] as int? ?? 0,
      blockers: (row['blockers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  static ConfigurationReadinessDto mapConfigurationReadiness(
    Map<String, dynamic> row,
  ) {
    final blockers =
        (row['blockers'] as List<dynamic>? ?? const [])
            .map(
              (raw) => ReadinessBlockerDto(
                code: (raw as Map)['code'] as String,
                message: raw['message'] as String,
              ),
            )
            .toList(growable: false);
    final warnings =
        (row['warnings'] as List<dynamic>? ?? const [])
            .map(
              (raw) => ReadinessWarningDto(
                code: (raw as Map)['code'] as String,
                message: raw['message'] as String,
              ),
            )
            .toList(growable: false);
    return ConfigurationReadinessDto(
      level: ConfigurationReadinessLevel.values.byName(row['level'] as String),
      blockers: blockers,
      warnings: warnings,
    );
  }
}
