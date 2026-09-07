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
      if (command.expectedConnectionVersion != null)
        'p_expected_connection_version': command.expectedConnectionVersion,
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
      'p_expected_connection_version': command.expectedConnectionVersion,
      'p_status': command.status.name,
      if (command.capabilities != null)
        'p_capabilities': {
          'supports_email_delivery':
              command.capabilities!.supportsEmailDelivery,
          'supports_preview': command.capabilities!.supportsPreview,
          'supports_delivery_result_observation':
              command.capabilities!.supportsDeliveryResultObservation,
          'template_count': command.capabilities!.templateCount,
          'supported_document_types': [
            for (final type in command.capabilities!.supportedDocumentTypes)
              switch (type) {
                InvoiceDocumentType.pdf => 'PDF',
                InvoiceDocumentType.xml => 'XML',
              },
          ],
          'templates': [
            for (final t in command.capabilities!.templates)
              {
                'template_id': t.templateId,
                'name': t.name,
                'serial': t.serial,
                'symbol': t.symbol,
                'is_mtt': t.isMtt,
                'is_available': t.isAvailable,
              },
          ],
          if (command.capabilities!.syncedAt != null)
            'synced_at': command.capabilities!.syncedAt!
                .toUtc()
                .toIso8601String(),
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
            ? ProviderConnectionStatus.values.byName(
                connection['status'] as String,
              )
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

  // --- S2a Mappers ---

  static IssuanceReadinessInput issuanceReadinessInputFromRow(
    Map<String, dynamic> row,
  ) {
    final warnings = (row['config_warnings'] as List<dynamic>? ?? const [])
        .map(
          (raw) => raw is Map
              ? ReadinessWarning(
                  code: (raw['code'] as String?) ?? '',
                  message: (raw['message'] as String?) ?? '',
                )
              : ReadinessWarning(code: raw.toString(), message: raw.toString()),
        )
        .toList(growable: false);

    final buyerTypeStr = row['buyer_type'] as String? ?? 'retail';
    final buyerType = BuyerType.values.firstWhere(
      (e) => e.name == buyerTypeStr,
      orElse: () => BuyerType.retail,
    );

    final buyer = EffectiveBuyerInvoiceData(
      buyerType: buyerType,
      name: row['buyer_name'] as String? ?? '',
      email: row['buyer_email'] as String?,
      taxCode: row['buyer_tax_code'] as String?,
      address: row['buyer_address'] as String?,
    );

    // No completion row → buyer data already settled from snapshot; within the
    // frozen open/locked enum this maps to `locked` (settled), not `open`.
    final completionStateStr =
        row['buyer_completion_state'] as String? ?? 'locked';
    final buyerCompletionState = BuyerCompletionStatus.values.firstWhere(
      (e) => e.name == completionStateStr,
      orElse: () => BuyerCompletionStatus.locked,
    );

    return IssuanceReadinessInput(
      orderCompleted: row['order_completed'] as bool? ?? false,
      hasElectronicInvoice: row['has_electronic_invoice'] as bool? ?? false,
      hasActiveOperation: row['has_active_operation'] as bool? ?? false,
      configReady: row['config_ready'] as bool? ?? false,
      providerConnected: row['provider_connected'] as bool? ?? false,
      providerSupportsPreview:
          row['provider_supports_preview'] as bool? ?? false,
      buyer: buyer,
      buyerCompletionState: buyerCompletionState,
      commercialDataMappable: row['commercial_data_mappable'] as bool? ?? true,
      configWarnings: warnings,
    );
  }

  static BuyerCompletionContext buyerCompletionContextFromRow(
    Map<String, dynamic> row,
  ) {
    final buyerTypeStr = row['buyer_type'] as String? ?? 'retail';
    final buyerType = BuyerType.values.firstWhere(
      (e) => e.name == buyerTypeStr,
      orElse: () => BuyerType.retail,
    );

    final base = BuyerInvoiceSourceFields(
      buyerType: buyerType,
      name: row['base_name'] as String?,
      email: row['base_email'] as String?,
      taxCode: row['base_tax_code'] as String?,
      address: row['base_address'] as String?,
    );

    BuyerInvoiceSourceFields? completionSource;
    if (row['resolved_values'] != null && row['resolved_values'] is Map) {
      final res = Map<String, dynamic>.from(row['resolved_values'] as Map);
      completionSource = BuyerInvoiceSourceFields(
        buyerType: buyerType,
        name: res['name'] as String?,
        email: res['email'] as String?,
        taxCode: res['taxCode'] as String?,
        address: res['address'] as String?,
      );
    }

    final statusStr = row['status'] as String? ?? 'open';
    final status = BuyerCompletionStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => BuyerCompletionStatus.open,
    );

    final eligibleFields =
        (row['eligible_fields'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false);

    return BuyerCompletionContext(
      base: base,
      completionSource: completionSource,
      status: status,
      salesOrderVersion: (row['sales_order_version'] ?? '').toString(),
      buyerPartnerId: (row['buyer_partner_id'] ?? '').toString(),
      eligibleFields: eligibleFields,
    );
  }

  static InvoicePreviewResultDto invoicePreviewResultFromRow(
    Map<String, dynamic> row,
  ) {
    final payload = row['preview_payload'];
    return InvoicePreviewResultDto(
      viewerRef: row['viewer_ref'] as String?,
      previewPayload: payload is Map
          ? Map<String, Object?>.from(payload)
          : null,
      warnings: const [],
    );
  }
}
