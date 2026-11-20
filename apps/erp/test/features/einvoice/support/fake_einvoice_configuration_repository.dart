import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:supabase/supabase.dart';

enum FakeEInvoiceConfigurationScenario {
  // §S1a
  connectionScreenOk,
  connectionScreenDisconnected,
  connectionScreenPending,
  connectionScreenError,
  connectOk,
  connectAuthFailed,
  connectLegalMismatch,
  verifyProviderUnavailable,
  disconnectOk,
  connectPermissionDenied,
  // §S1b
  listTemplatesOk,
  setDefaultHsmOk,
  setDefaultIncompatible,
  setDefaultNotConnected,
  listTemplatesPermissionDenied,
  // §S1c
  automationPolicyOk,
  enableAutoIssueOk,
  enableAutoIssueNotReady,
  enableAutoSendOk,
  automationStateChanged,
  // §S1d
  configReadinessReady,
  configReadinessWarnings,
  configReadinessBlocked,
  configReadinessAutoIssueBlocked,
  configurationLoadFailure,
}

abstract final class FakeEInvoiceConfigurationFixtures {
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
  }) =>
      ProviderConnectionScreenDto(
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
        ProviderTemplateDto(
          templateId: 'tpl-mtt',
          name: 'Hóa đơn máy tính tiền',
          serial: '1/003',
          symbol: '2C25MYY',
          invoiceSeries: '2C25MYY',
          invoiceWithCode: true,
          isMtt: true,
          isSendSummary: false,
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
  }) =>
      ConfigurationReadinessDto(
        level: level,
        blockers: blockers,
        warnings: warnings,
      );
}

class _DummyRpc implements SupabaseRpc {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFunctions implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #invoke) {
      return Future.value(FunctionResponse(status: 200, data: null));
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeEInvoiceConfigurationRepository extends EInvoiceConfigurationRepository {
  FakeEInvoiceConfigurationRepository({
    this.scenario = FakeEInvoiceConfigurationScenario.connectionScreenOk,
  }) : super(
          rpc: _DummyRpc(),
          trigger: EInvoiceProcessorTrigger(_DummyFunctions()),
          tenantId: () async => 'tenant-1',
          actorId: () async => 'actor-1',
        );

  final FakeEInvoiceConfigurationScenario scenario;
  final List<String> calls = [];

  void _throwIfConfigurationQueryBlocked() {
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.connectPermissionDenied:
        throw const AppException(EInvoiceErrorCodes.noPermission);
      case FakeEInvoiceConfigurationScenario.configurationLoadFailure:
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'Không thể tải thiết lập hóa đơn điện tử',
        );
      default:
        return;
    }
  }

  @override
  Future<ProviderConnectionScreenDto> getConnectionScreen() async {
    calls.add('getConnectionScreen');
    _throwIfConfigurationQueryBlocked();
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.connectionScreenDisconnected:
      case FakeEInvoiceConfigurationScenario.configReadinessBlocked:
        return FakeEInvoiceConfigurationFixtures.connectedScreen(
          status: ProviderConnectionStatus.disconnected,
        );
      case FakeEInvoiceConfigurationScenario.connectionScreenPending:
        return FakeEInvoiceConfigurationFixtures.connectedScreen(
          status: ProviderConnectionStatus.checkRequired,
        );
      case FakeEInvoiceConfigurationScenario.connectionScreenError:
        return FakeEInvoiceConfigurationFixtures.connectedScreen(
          status: ProviderConnectionStatus.reconnectRequired,
        );
      default:
        return FakeEInvoiceConfigurationFixtures.connectedScreen();
    }
  }

  @override
  Future<ProviderConnectionResultDto> connect({
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) async {
    calls.add('connect');
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.connectAuthFailed:
        throw const AppException(EInvoiceErrorCodes.providerAuthFailed);
      case FakeEInvoiceConfigurationScenario.connectLegalMismatch:
        throw const AppException(
          EInvoiceErrorCodes.validationError,
          serverMessage: 'Legal identity mismatch',
          details: {'subcode': 'legal_mismatch'},
        );
      case FakeEInvoiceConfigurationScenario.connectPermissionDenied:
        throw const AppException(EInvoiceErrorCodes.noPermission);
      default:
        return FakeEInvoiceConfigurationFixtures.connectedResult;
    }
  }

  @override
  Future<ProviderConnectionResultDto> reconnect({
    required String connectionId,
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) async {
    calls.add('reconnect');
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.connectAuthFailed:
        throw const AppException(EInvoiceErrorCodes.providerAuthFailed);
      case FakeEInvoiceConfigurationScenario.connectLegalMismatch:
        throw const AppException(
          EInvoiceErrorCodes.validationError,
          serverMessage: 'Legal identity mismatch',
          details: {'subcode': 'legal_mismatch'},
        );
      case FakeEInvoiceConfigurationScenario.connectPermissionDenied:
        throw const AppException(EInvoiceErrorCodes.noPermission);
      default:
        return FakeEInvoiceConfigurationFixtures.connectedResult;
    }
  }

  @override
  Future<ProviderConnectionResultDto> disconnect({
    required String connectionId,
    required bool confirm,
  }) async {
    calls.add('disconnect');
    return const ProviderConnectionResultDto(
      connectionId: FakeEInvoiceConfigurationFixtures.connectionId,
      status: ProviderConnectionStatus.disconnected,
    );
  }

  @override
  Future<List<ProviderTemplateDto>> listTemplates({
    bool? invoiceWithCode,
    int? year,
  }) async {
    calls.add('listTemplates');
    _throwIfConfigurationQueryBlocked();
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.listTemplatesPermissionDenied:
        throw const AppException(EInvoiceErrorCodes.noPermission);
      case FakeEInvoiceConfigurationScenario.setDefaultNotConnected:
        throw const AppException(EInvoiceErrorCodes.providerNotConnected);
      default:
        return FakeEInvoiceConfigurationFixtures.templates;
    }
  }

  @override
  Future<IssuanceProfileDto> getIssuanceProfile() async {
    calls.add('getIssuanceProfile');
    _throwIfConfigurationQueryBlocked();
    if (scenario == FakeEInvoiceConfigurationScenario.configReadinessBlocked) {
      return FakeEInvoiceConfigurationFixtures.issuanceProfileMissing;
    }
    return FakeEInvoiceConfigurationFixtures.issuanceProfile;
  }

  @override
  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) async {
    calls.add('setDefaultConfiguration');
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.setDefaultIncompatible:
        throw const AppException(EInvoiceErrorCodes.templateNotAvailable);
      case FakeEInvoiceConfigurationScenario.setDefaultNotConnected:
        throw const AppException(EInvoiceErrorCodes.providerNotConnected);
      default:
        return FakeEInvoiceConfigurationFixtures.issuanceProfile;
    }
  }

  @override
  Future<AutomationPolicyDto> getAutomationPolicy() async {
    calls.add('getAutomationPolicy');
    _throwIfConfigurationQueryBlocked();
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.automationPolicyOk:
      case FakeEInvoiceConfigurationScenario.enableAutoIssueOk:
      case FakeEInvoiceConfigurationScenario.enableAutoSendOk:
        return FakeEInvoiceConfigurationFixtures.automationPolicyEnabled;
      default:
        return FakeEInvoiceConfigurationFixtures.automationPolicyDisabled;
    }
  }

  @override
  Future<AutomationPolicyDto> updateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) async {
    calls.add('updateAutomationPolicy');
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.enableAutoIssueNotReady:
        throw const AppException(EInvoiceErrorCodes.configNotReady);
      case FakeEInvoiceConfigurationScenario.automationStateChanged:
        throw const AppException(EInvoiceErrorCodes.stateChanged);
      default:
        return AutomationPolicyDto(
          autoIssueEnabled: autoIssueEnabled ?? false,
          autoSendEnabled: autoSendEnabled ?? false,
          policyVersion: 2,
          blockers: const [],
        );
    }
  }

  @override
  Future<ConfigurationReadinessDto> getConfigurationReadiness({
    IssuancePurpose? purpose,
  }) async {
    calls.add('getConfigurationReadiness');
    _throwIfConfigurationQueryBlocked();
    switch (scenario) {
      case FakeEInvoiceConfigurationScenario.configReadinessWarnings:
        return FakeEInvoiceConfigurationFixtures.configReadiness(
          ConfigurationReadinessLevel.readyWithWarnings,
          warnings: const [
            ReadinessWarningDto(
              code: 'template_deprecated',
              message: 'Template deprecated',
            ),
          ],
        );
      case FakeEInvoiceConfigurationScenario.configReadinessBlocked:
        return FakeEInvoiceConfigurationFixtures.configReadiness(
          ConfigurationReadinessLevel.notReady,
          blockers: const [
            ReadinessBlockerDto(
              code: 'provider_not_connected',
              message: 'Chưa kết nối nhà cung cấp',
            ),
            ReadinessBlockerDto(
              code: 'missing_template',
              message: 'Chưa chọn mẫu hóa đơn mặc định',
            ),
          ],
        );
      case FakeEInvoiceConfigurationScenario.configReadinessAutoIssueBlocked:
        if (purpose == IssuancePurpose.autoIssue) {
          return FakeEInvoiceConfigurationFixtures.configReadiness(
            ConfigurationReadinessLevel.notReady,
            warnings: const [
              ReadinessWarningDto(code: 'auto_issue', message: 'Warnings only'),
            ],
          );
        }
        return FakeEInvoiceConfigurationFixtures.configReadiness(
          ConfigurationReadinessLevel.readyWithWarnings,
        );
      default:
        return FakeEInvoiceConfigurationFixtures.configReadiness(
          ConfigurationReadinessLevel.ready,
        );
    }
  }
}
