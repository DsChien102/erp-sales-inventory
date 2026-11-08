import '../models.dart';

abstract final class EInvoiceConfigurationJson {
  static const _connectionStatusWire = <ProviderConnectionStatus, String>{
    ProviderConnectionStatus.disconnected: 'DISCONNECTED',
    ProviderConnectionStatus.connected: 'CONNECTED',
    ProviderConnectionStatus.checkRequired: 'CHECK_REQUIRED',
    ProviderConnectionStatus.reconnectRequired: 'RECONNECT_REQUIRED',
  };

  static ProviderConnectionStatus connectionStatusFromWire(String raw) {
    for (final entry in _connectionStatusWire.entries) {
      if (entry.value == raw) {
        return entry.key;
      }
    }
    throw ArgumentError.value(
      raw,
      'status',
      'unknown provider connection status',
    );
  }

  static ProviderConnectionResultDto mapConnectionResult(
    Map<String, dynamic> row,
  ) {
    return ProviderConnectionResultDto(
      connectionId: row['connection_id'] as String,
      status: connectionStatusFromWire(row['status'] as String),
    );
  }

  static ProviderConnectionScreenDto mapConnectionScreen(
    Map<String, dynamic> row,
  ) {
    final legal = row['legal_profile'] as Map<String, dynamic>? ?? const {};
    final connection = row['connection'] as Map<String, dynamic>? ?? const {};
    return ProviderConnectionScreenDto(
      legalProfile: LegalProfileSummaryDto(
        legalName: legal['legal_name'] as String? ?? '',
        taxCode: legal['tax_code'] as String? ?? '',
        address: legal['address'] as String?,
      ),
      connection: ProviderConnectionSummaryDto(
        connectionId: connection['connection_id'] as String?,
        status: connection['status'] != null
            ? connectionStatusFromWire(connection['status'] as String)
            : ProviderConnectionStatus.disconnected,
        lastCheckedAt: connection['last_checked_at'] != null
            ? DateTime.parse(connection['last_checked_at'] as String)
            : null,
        maskedAccount: connection['masked_account'] as String?,
        connectionVersion: connection['connection_version'] as int?,
      ),
    );
  }

  static List<ProviderTemplateDto> mapTemplateList(List<dynamic> rows) {
    return rows
        .map((raw) {
          final map = raw as Map;
          final series =
              (map['invoice_series'] as String?)?.trim().isNotEmpty == true
                  ? (map['invoice_series'] as String).trim()
                  : (map['symbol'] as String?)?.trim();
          return ProviderTemplateDto(
            templateId: map['template_id'] as String,
            name: map['name'] as String,
            serial: map['serial'] as String?,
            symbol: series ?? map['symbol'] as String?,
            invoiceSeries: series,
            invoiceWithCode: map['invoice_with_code'] as bool?,
            isMtt: map['is_mtt'] as bool?,
            isSendSummary: map['is_send_summary'] as bool?,
          );
        })
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
      compatibilityWarnings:
          (row['compatibility_warnings'] as List<dynamic>?)
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
      blockers:
          (row['blockers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  static ConfigurationReadinessDto mapConfigurationReadiness(
    Map<String, dynamic> row,
  ) {
    final blockers = (row['blockers'] as List<dynamic>? ?? const [])
        .map(
          (raw) => ReadinessBlockerDto(
            code: (raw as Map)['code'] as String,
            message: raw['message'] as String,
          ),
        )
        .toList(growable: false);
    final warnings = (row['warnings'] as List<dynamic>? ?? const [])
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

