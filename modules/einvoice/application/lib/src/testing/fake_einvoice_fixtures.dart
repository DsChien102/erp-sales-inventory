import 'package:vet45_einvoice_domain/domain.dart';

import '../configuration/queries/get_automation_policy/automation_policy_dto.dart';
import '../configuration/queries/get_configuration_readiness/configuration_readiness_dto.dart';
import '../configuration/queries/get_issuance_profile/issuance_profile_dto.dart';
import '../configuration/queries/get_provider_connection_screen/provider_connection_screen_dto.dart';
import '../configuration/queries/list_provider_templates/provider_template_dto.dart';
import '../configuration/shared/legal_profile_summary_dto.dart';
import '../configuration/shared/provider_connection_summary_dto.dart';
import '../configuration/shared/readiness_blocker_dto.dart';
import '../configuration/shared/readiness_warning_dto.dart';
import '../configuration/commands/connect_provider/connect_provider_result.dart';
import '../configuration/commands/verify_provider_connection/verify_provider_connection_result.dart';
import '../issuance/commands/issue_invoice/issue_invoice_result.dart';
import '../issuance/queries/get_issuance_readiness/issuance_readiness_dto.dart';
import '../shared/order_invoice_action.dart';
import '../shared/order_invoice_projection_dto.dart';

/// Canned DTO fixtures for FakeEInvoiceModule.
abstract final class FakeEInvoiceFixtures {
  static const tenantId = 'tenant-fake';
  static const actorId = 'actor-fake';
  static const salesOrderId = 'so-fake-001';
  static const connectionId = 'conn-fake-001';

  static LegalProfileSummaryDto get legalProfile => const LegalProfileSummaryDto(
    legalName: 'Công ty TNHH Fake',
    taxCode: '0101234567',
    address: '123 Fake Street',
  );

  static ProviderConnectionScreenDto connectedScreen({
    ProviderConnectionStatus status = ProviderConnectionStatus.connected,
  }) => ProviderConnectionScreenDto(
    legalProfile: legalProfile,
    connection: ProviderConnectionSummaryDto(
      connectionId: connectionId,
      status: status,
      lastCheckedAt: DateTime.utc(2026, 8, 5, 10, 40),
      maskedAccount: 'ke***@anphu.vn',
      connectionVersion: 1,
    ),
  );

  static ProviderConnectionResultDto get connectedResult => const ProviderConnectionResultDto(
    connectionId: connectionId,
    status: ProviderConnectionStatus.checkRequired,
  );

  static ProviderConnectionCheckResultDto get verifyOk => ProviderConnectionCheckResultDto(
    connectionId: connectionId,
    status: ProviderConnectionStatus.connected,
    checkedAt: DateTime.utc(2026, 8, 5, 10, 40),
  );

  static List<ProviderTemplateDto> get templates => const [
    ProviderTemplateDto(
      templateId: 'tpl-1',
      name: 'Hóa đơn GTGT',
      serial: '1/001',
      symbol: 'C22TAA',
    ),
    ProviderTemplateDto(
      templateId: 'tpl-2',
      name: 'Hóa đơn bán hàng',
      serial: '1/002',
      symbol: 'C26TAA',
    ),
  ];

  static IssuanceProfileDto get issuanceProfile => const IssuanceProfileDto(
    profileVersion: 1,
    templateId: 'tpl-1',
    signingConfigId: 'sign-hsm',
    signingMethod: SigningMethod.hsm,
    compatibilityWarnings: [],
  );

  static IssuanceProfileDto get issuanceProfileMissing => const IssuanceProfileDto(
    profileVersion: 1,
    compatibilityWarnings: [],
  );

  static AutomationPolicyDto get automationPolicyDisabled => const AutomationPolicyDto(
    autoIssueEnabled: false,
    autoSendEnabled: false,
    policyVersion: 1,
    blockers: [],
  );

  static AutomationPolicyDto get automationPolicyEnabled => const AutomationPolicyDto(
    autoIssueEnabled: true,
    autoSendEnabled: true,
    policyVersion: 1,
    blockers: [],
  );

  static ConfigurationReadinessDto configReadiness(
    ConfigurationReadinessLevel level, {
    List<ReadinessBlockerDto> blockers = const [],
    List<ReadinessWarningDto> warnings = const [],
  }) => ConfigurationReadinessDto(
    level: level,
    blockers: blockers,
    warnings: warnings,
  );

  static IssuanceReadinessDto issuanceReadiness(
    IssuanceReadinessLevel level, {
    BuyerCompletionStatus buyer = BuyerCompletionStatus.locked,
    List<ReadinessBlockerDto> blockers = const [],
  }) => IssuanceReadinessDto(
    level: level,
    blockers: blockers,
    warnings: const [],
    buyerCompletionState: buyer,
  );

  static IssueInvoiceResultDto get issueProcessing => const IssueInvoiceResultDto(
    issuanceId: 'iss-fake-001',
    attemptId: 'att-fake-001',
    status: IssuanceAttemptStatus.submitted,
  );

  static OrderInvoiceProjectionDto projection({
    IssuanceDisplayState issuance = IssuanceDisplayState.processing,
    DeliveryDisplayState? delivery,
    bool hasSecondaryAttention = false,
    List<OrderInvoiceAction> actions = const [OrderInvoiceAction.issue],
  }) => OrderInvoiceProjectionDto(
    salesOrderId: salesOrderId,
    issuanceDisplayState: issuance,
    deliveryDisplayState: delivery,
    hasSecondaryAttention: hasSecondaryAttention,
    actions: actions,
  );
}
