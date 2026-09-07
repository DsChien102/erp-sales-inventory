import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../configuration/commands/connect_provider/connect_provider_command.dart';
import '../configuration/commands/connect_provider/connect_provider_result.dart';
import '../configuration/commands/disconnect_provider/disconnect_provider_command.dart';
import '../configuration/commands/reconnect_provider/reconnect_provider_command.dart';
import '../configuration/commands/set_default_issuance_configuration/set_default_issuance_configuration_command.dart';
import '../configuration/commands/sync_provider_capabilities/sync_provider_capabilities_command.dart';
import '../configuration/commands/sync_provider_capabilities/sync_provider_capabilities_result.dart';
import '../configuration/commands/update_automation_policy/update_automation_policy_command.dart';
import '../configuration/commands/verify_provider_connection/verify_provider_connection_command.dart';
import '../configuration/queries/get_automation_policy/automation_policy_dto.dart';
import '../configuration/queries/get_automation_policy/get_automation_policy_query.dart';
import '../configuration/queries/get_configuration_readiness/get_configuration_readiness_query.dart';
import '../configuration/queries/get_issuance_profile/get_issuance_profile_query.dart';
import '../configuration/queries/get_provider_connection_screen/get_provider_connection_screen_query.dart';
import '../configuration/queries/list_provider_templates/list_provider_templates_query.dart';
import '../configuration/shared/readiness_blocker_dto.dart';
import '../configuration/shared/readiness_warning_dto.dart';
import '../contracts/i_einvoice_module.dart';
import '../delivery/commands/record_delivery_result/record_delivery_result_command.dart';
import '../delivery/commands/record_delivery_result/record_delivery_result_result.dart';
import '../delivery/commands/send_electronic_invoice/send_electronic_invoice_command.dart';
import '../delivery/commands/send_electronic_invoice/send_electronic_invoice_result.dart';
import '../delivery/commands/start_auto_delivery/start_auto_delivery_command.dart';
import '../delivery/commands/start_auto_delivery/start_auto_delivery_result.dart';
import '../delivery/shared/auto_delivery_disposition.dart';
import '../delivery/shared/auto_delivery_skip_reason.dart';
import '../delivery/queries/get_invoice_delivery_history/get_invoice_delivery_history_query.dart';
import '../delivery/queries/get_invoice_delivery_history/invoice_delivery_history_dto.dart';
import '../delivery/queries/get_invoice_delivery_history/invoice_delivery_item_dto.dart';
import '../delivery/queries/get_send_invoice_sheet_context/get_send_invoice_sheet_context_query.dart';
import '../delivery/queries/get_send_invoice_sheet_context/send_invoice_sheet_context_dto.dart';
import '../delivery/shared/send_invoice_sheet_mode.dart';
import '../electronic_invoice/commands/record_provider_observation/record_provider_observation_command.dart';
import '../electronic_invoice/commands/record_provider_observation/record_provider_observation_result.dart';
import '../electronic_invoice/commands/request_invoice_document/request_invoice_document_command.dart';
import '../electronic_invoice/commands/request_invoice_document/request_invoice_document_result.dart';
import '../electronic_invoice/commands/request_official_invoice_view/request_official_invoice_view_command.dart';
import '../electronic_invoice/commands/request_official_invoice_view/request_official_invoice_view_result.dart';
import '../electronic_invoice/queries/get_electronic_invoice_detail/electronic_invoice_detail_dto.dart';
import '../electronic_invoice/queries/get_electronic_invoice_detail/get_electronic_invoice_detail_query.dart';
import '../electronic_invoice/queries/get_invoice_documents/get_invoice_documents_query.dart';
import '../electronic_invoice/queries/get_invoice_documents/invoice_documents_dto.dart';
import '../electronic_invoice/queries/get_latest_provider_observation/get_latest_provider_observation_query.dart';
import '../electronic_invoice/shared/provider_observation_dto.dart';
import '../exceptions/already_issued_exception.dart';
import '../exceptions/config_not_ready_exception.dart';
import '../exceptions/delivery_not_supported_exception.dart';
import '../exceptions/issuance_not_ready_exception.dart';
import '../exceptions/operation_in_progress_exception.dart';
import '../exceptions/provider_auth_failed_exception.dart';
import '../exceptions/provider_not_connected_exception.dart';
import '../exceptions/provider_unavailable_exception.dart';
import '../issuance/commands/complete_buyer_invoice_data/complete_buyer_invoice_data_command.dart';
import '../issuance/commands/complete_buyer_invoice_data/complete_buyer_invoice_data_result.dart';
import '../issuance/commands/issue_invoice/issue_invoice_command.dart';
import '../issuance/commands/issue_invoice/issue_invoice_result.dart';
import '../issuance/commands/open_reconciliation_case/open_reconciliation_case_command.dart';
import '../issuance/commands/open_reconciliation_case/open_reconciliation_case_result.dart';
import '../issuance/commands/record_issuance_result/record_issuance_result_command.dart';
import '../issuance/commands/record_issuance_result/record_issuance_result_result.dart';
import '../issuance/commands/recover_internal_finalization/recover_internal_finalization_command.dart';
import '../issuance/commands/recover_internal_finalization/recover_internal_finalization_result.dart';
import '../issuance/commands/request_invoice_preview/request_invoice_preview_command.dart';
import '../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';
import '../issuance/commands/resolve_reconciliation_case/resolve_reconciliation_case_command.dart';
import '../issuance/commands/resolve_reconciliation_case/resolve_reconciliation_case_result.dart';
import '../issuance/commands/reevaluate_auto_issuance/reevaluate_auto_issuance_command.dart';
import '../issuance/commands/retry_issuance/retry_issuance_command.dart';
import '../issuance/commands/start_auto_issuance/start_auto_issuance_command.dart';
import '../issuance/commands/start_auto_issuance/start_auto_issuance_result.dart';
import '../issuance/queries/get_invoice_preview/get_invoice_preview_query.dart';
import '../issuance/queries/get_issuance_attempt_status/get_issuance_attempt_status_query.dart';
import '../issuance/queries/get_issuance_attempt_status/issuance_attempt_status_dto.dart';
import '../issuance/queries/get_issuance_readiness/get_issuance_readiness_query.dart';
import '../issuance/queries/get_order_invoice_projection/get_order_invoice_projection_query.dart';
import '../issuance/shared/effective_buyer_preview_dto.dart';
import '../shared/einvoice_blocked_codes.dart';
import '../shared/einvoice_blocked_exception.dart';
import '../shared/electronic_invoice_dto.dart';
import '../shared/order_invoice_action.dart';
import 'fake_einvoice_fixtures.dart';
import 'fake_einvoice_scenario.dart';

/// In-memory einvoice module for FE/widget/contract tests.
final class FakeEInvoiceModule implements IEInvoiceModule {
  FakeEInvoiceModule({this.scenario = FakeEInvoiceScenario.connectOk});

  final FakeEInvoiceScenario scenario;

  /// Whether [scenario] has explicit handling in this fake module.
  static bool handlesScenario(FakeEInvoiceScenario scenario) {
    return _scenarioHandlers.contains(scenario);
  }

  static final Set<FakeEInvoiceScenario> _scenarioHandlers = {
    for (final s in FakeEInvoiceScenario.values) s,
  };

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      ConnectProviderCommand c => _connectProvider<TResult>(c),
      VerifyProviderConnectionCommand c => _verifyConnection<TResult>(c),
      ReconnectProviderCommand c => _connectProvider<TResult>(
        ConnectProviderCommand(
          tenantId: c.tenantId,
          actorId: c.actorId,
          username: c.username,
          password: c.password,
        ),
      ),
      DisconnectProviderCommand _ => _disconnect<TResult>(),
      SyncProviderCapabilitiesCommand _ => _syncCapabilities<TResult>(),
      SetDefaultIssuanceConfigurationCommand _ => _setDefault<TResult>(),
      UpdateAutomationPolicyCommand c => _updateAutomation<TResult>(c),
      CompleteBuyerInvoiceDataCommand _ => _completeBuyer<TResult>(),
      RequestInvoicePreviewCommand _ => _previewCommand<TResult>(),
      IssueInvoiceCommand c => _issueInvoice<TResult>(c),
      StartAutoIssuanceCommand _ => _startAutoIssuance<TResult>(),
      ReevaluateAutoIssuanceCommand _ => _startAutoIssuance<TResult>(),
      RecordIssuanceResultCommand _ => _recordIssuanceResult<TResult>(),
      RetryIssuanceCommand _ => _retryIssuance<TResult>(),
      OpenReconciliationCaseCommand _ => _openReconciliation<TResult>(),
      ResolveReconciliationCaseCommand _ => _resolveReconciliation<TResult>(),
      RecoverInternalFinalizationCommand _ => _recoverFinalization<TResult>(),
      RequestOfficialInvoiceViewCommand _ => _officialView<TResult>(),
      RequestInvoiceDocumentCommand c => _requestDocument<TResult>(c),
      RecordProviderObservationCommand _ => _recordObservation<TResult>(),
      StartAutoDeliveryCommand _ => _startAutoDelivery<TResult>(),
      SendElectronicInvoiceCommand _ => _sendInvoice<TResult>(),
      RecordDeliveryResultCommand _ => _recordDeliveryResult<TResult>(),
      _ => throw UnsupportedError(
        'FakeEInvoiceModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  void _throwIfConfigurationQueryBlocked() {
    switch (scenario) {
      case FakeEInvoiceScenario.connectPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      case FakeEInvoiceScenario.configurationLoadFailure:
        throw const EInvoiceBlockedException(
          EInvoiceBlockedCodes.systemError,
          message: 'Không thể tải thiết lập hóa đơn điện tử',
        );
      default:
        return;
    }
  }

  bool _isConfigurationQuery(IQuery<dynamic> query) {
    return query is GetProviderConnectionScreenQuery ||
        query is ListProviderTemplatesQuery ||
        query is GetIssuanceProfileQuery ||
        query is GetAutomationPolicyQuery ||
        query is GetConfigurationReadinessQuery;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (_isConfigurationQuery(query)) {
      _throwIfConfigurationQueryBlocked();
    }
    return switch (query) {
      GetProviderConnectionScreenQuery _ => _connectionScreen<TResult>(),
      ListProviderTemplatesQuery _ => _listTemplates<TResult>(),
      GetIssuanceProfileQuery _ => _issuanceProfileQuery<TResult>(),
      GetAutomationPolicyQuery _ => _automationPolicyQuery<TResult>(),
      GetConfigurationReadinessQuery q => _configReadiness<TResult>(q),
      GetIssuanceReadinessQuery _ => _issuanceReadinessQuery<TResult>(),
      GetInvoicePreviewQuery _ => _previewQuery<TResult>(),
      GetOrderInvoiceProjectionQuery _ => _projectionQuery<TResult>(),
      GetIssuanceAttemptStatusQuery _ => _attemptStatusQuery<TResult>(),
      GetElectronicInvoiceDetailQuery _ => _invoiceDetailQuery<TResult>(),
      GetInvoiceDocumentsQuery _ => _documentsQuery<TResult>(),
      GetLatestProviderObservationQuery _ => _latestObservationQuery<TResult>(),
      GetSendInvoiceSheetContextQuery _ => _sendSheetQuery<TResult>(),
      GetInvoiceDeliveryHistoryQuery _ => _deliveryHistoryQuery<TResult>(),
      _ => throw UnsupportedError(
        'FakeEInvoiceModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  Future<TResult> _connectionScreen<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.connectionScreenDisconnected:
      case FakeEInvoiceScenario.configReadinessBlocked:
        return Future.value(
          FakeEInvoiceFixtures.connectedScreen(
                status: ProviderConnectionStatus.disconnected,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.connectionScreenPending:
        return Future.value(
          FakeEInvoiceFixtures.connectedScreen(
                status: ProviderConnectionStatus.checkRequired,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.connectionScreenError:
        return Future.value(
          FakeEInvoiceFixtures.connectedScreen(
                status: ProviderConnectionStatus.reconnectRequired,
              )
              as TResult,
        );
      default:
        return Future.value(FakeEInvoiceFixtures.connectedScreen() as TResult);
    }
  }

  Future<TResult> _connectProvider<TResult>(ConnectProviderCommand _) {
    switch (scenario) {
      case FakeEInvoiceScenario.connectAuthFailed:
        throw const ProviderAuthFailedException();
      case FakeEInvoiceScenario.connectLegalMismatch:
        throw const EInvoiceBlockedException(
          EInvoiceBlockedCodes.validationError,
          message: 'Legal identity mismatch',
          details: {'subcode': 'legal_mismatch'},
        );
      case FakeEInvoiceScenario.connectPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      default:
        return Future.value(FakeEInvoiceFixtures.connectedResult as TResult);
    }
  }

  Future<TResult> _verifyConnection<TResult>(VerifyProviderConnectionCommand _) {
    if (scenario == FakeEInvoiceScenario.verifyProviderUnavailable) {
      throw const ProviderUnavailableException();
    }
    return Future.value(FakeEInvoiceFixtures.verifyOk as TResult);
  }

  Future<TResult> _disconnect<TResult>() {
    return Future.value(
      const ProviderConnectionResultDto(
            connectionId: FakeEInvoiceFixtures.connectionId,
            status: ProviderConnectionStatus.disconnected,
          )
          as TResult,
    );
  }

  Future<TResult> _syncCapabilities<TResult>() {
    return Future.value(
      const ProviderCapabilitiesDto(
            connectionId: FakeEInvoiceFixtures.connectionId,
            supportsEmailDelivery: true,
            templateCount: 2,
          )
          as TResult,
    );
  }

  Future<TResult> _listTemplates<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.listTemplatesPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      case FakeEInvoiceScenario.setDefaultNotConnected:
        throw const ProviderNotConnectedException();
      default:
        return Future.value(FakeEInvoiceFixtures.templates as TResult);
    }
  }

  Future<TResult> _setDefault<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.setDefaultIncompatible:
        throw ValidationException('Incompatible template and signing');
      case FakeEInvoiceScenario.setDefaultNotConnected:
        throw const ProviderNotConnectedException();
      default:
        return Future.value(FakeEInvoiceFixtures.issuanceProfile as TResult);
    }
  }

  Future<TResult> _issuanceProfileQuery<TResult>() {
    if (scenario == FakeEInvoiceScenario.configReadinessBlocked) {
      return Future.value(
        FakeEInvoiceFixtures.issuanceProfileMissing as TResult,
      );
    }
    return Future.value(FakeEInvoiceFixtures.issuanceProfile as TResult);
  }

  Future<TResult> _automationPolicyQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.automationPolicyOk:
      case FakeEInvoiceScenario.enableAutoIssueOk:
      case FakeEInvoiceScenario.enableAutoSendOk:
        return Future.value(
          FakeEInvoiceFixtures.automationPolicyEnabled as TResult,
        );
      default:
        return Future.value(
          FakeEInvoiceFixtures.automationPolicyDisabled as TResult,
        );
    }
  }

  Future<TResult> _updateAutomation<TResult>(UpdateAutomationPolicyCommand c) {
    switch (scenario) {
      case FakeEInvoiceScenario.enableAutoIssueNotReady:
        throw ConfigNotReadyException(blockers: ['missing_signing']);
      case FakeEInvoiceScenario.automationStateChanged:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.stateChanged);
      default:
        return Future.value(
          AutomationPolicyDto(
                autoIssueEnabled: c.autoIssueEnabled ?? false,
                autoSendEnabled: c.autoSendEnabled ?? false,
                policyVersion: 2,
                blockers: const [],
              )
              as TResult,
        );
    }
  }

  Future<TResult> _configReadiness<TResult>(GetConfigurationReadinessQuery q) {
    switch (scenario) {
      case FakeEInvoiceScenario.configReadinessWarnings:
        return Future.value(
          FakeEInvoiceFixtures.configReadiness(
                ConfigurationReadinessLevel.readyWithWarnings,
                warnings: const [
                  ReadinessWarningDto(
                    code: 'template_deprecated',
                    message: 'Template deprecated',
                  ),
                ],
              )
              as TResult,
        );
      case FakeEInvoiceScenario.configReadinessBlocked:
        return Future.value(
          FakeEInvoiceFixtures.configReadiness(
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
              )
              as TResult,
        );
      case FakeEInvoiceScenario.configReadinessAutoIssueBlocked:
        if (q.purpose == IssuancePurpose.autoIssue) {
          return Future.value(
            FakeEInvoiceFixtures.configReadiness(
                  ConfigurationReadinessLevel.notReady,
                  warnings: const [
                    ReadinessWarningDto(code: 'auto_issue', message: 'Warnings only'),
                  ],
                )
                as TResult,
          );
        }
        return Future.value(
          FakeEInvoiceFixtures.configReadiness(
                ConfigurationReadinessLevel.readyWithWarnings,
              )
              as TResult,
        );
      default:
        return Future.value(
          FakeEInvoiceFixtures.configReadiness(
                ConfigurationReadinessLevel.ready,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _issuanceReadinessQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.readinessBuyerIncomplete:
        return Future.value(
          FakeEInvoiceFixtures.issuanceReadiness(
                IssuanceReadinessLevel.notReady,
                buyer: BuyerCompletionStatus.open,
                blockers: const [
                  ReadinessBlockerDto(
                    code: 'BUYER_DATA_INCOMPLETE',
                    message: 'Missing buyer email',
                  ),
                ],
              )
              as TResult,
        );
      default:
        return Future.value(
          FakeEInvoiceFixtures.issuanceReadiness(
                IssuanceReadinessLevel.ready,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _completeBuyer<TResult>() {
    return Future.value(
      const BuyerCompletionResultDto(
            locked: true,
            effectiveBuyer: EffectiveBuyerPreviewDto(
              name: 'Buyer Fake',
              email: 'buyer@fake.test',
            ),
          )
          as TResult,
    );
  }

  Future<TResult> _previewCommand<TResult>() => _previewQuery<TResult>();

  Future<TResult> _previewQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.previewConfigNotReady:
        throw ConfigNotReadyException();
      case FakeEInvoiceScenario.previewProviderUnavailable:
        throw const ProviderUnavailableException();
      case FakeEInvoiceScenario.previewPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      default:
        return Future.value(
          const InvoicePreviewResultDto(
                viewerRef: 'https://preview.fake/invoice',
                warnings: [],
              )
              as TResult,
        );
    }
  }

  Future<TResult> _issueInvoice<TResult>(IssueInvoiceCommand _) {
    switch (scenario) {
      case FakeEInvoiceScenario.issueAlreadyIssued:
        throw AlreadyIssuedException(salesOrderId: FakeEInvoiceFixtures.salesOrderId);
      case FakeEInvoiceScenario.issueInProgress:
        throw const OperationInProgressException();
      case FakeEInvoiceScenario.issueNotReady:
        throw IssuanceNotReadyException(blockers: ['config']);
      case FakeEInvoiceScenario.issueStateChanged:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.stateChanged);
      case FakeEInvoiceScenario.issueIdempotentReplay:
        return Future.value(
          const IssueInvoiceResultDto(
                issuanceId: 'iss-existing',
                attemptId: 'att-existing',
                status: IssuanceAttemptStatus.submitted,
              )
              as TResult,
        );
      default:
        return Future.value(FakeEInvoiceFixtures.issueProcessing as TResult);
    }
  }

  Future<TResult> _projectionQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.projectionIssued:
      case FakeEInvoiceScenario.retryProjectionFailedState:
        if (scenario == FakeEInvoiceScenario.retryProjectionFailedState) {
          return Future.value(
            FakeEInvoiceFixtures.projection(
                  issuance: IssuanceDisplayState.failed,
                  actions: const [OrderInvoiceAction.issue],
                )
                as TResult,
          );
        }
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                actions: const [OrderInvoiceAction.view],
              )
              as TResult,
        );
      case FakeEInvoiceScenario.projectionFailed:
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.failed,
                actions: const [OrderInvoiceAction.issue],
              )
              as TResult,
        );
      case FakeEInvoiceScenario.deliverySuccess:
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                delivery: DeliveryDisplayState.sent,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.deliveryFailed:
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                delivery: DeliveryDisplayState.failed,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.deliveryUndetermined:
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.issued,
                delivery: DeliveryDisplayState.sending,
              )
              as TResult,
        );
      default:
        return Future.value(
          FakeEInvoiceFixtures.projection(
                issuance: IssuanceDisplayState.processing,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _startAutoIssuance<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.autoIssueSkippedPolicyOff:
        return Future.value(
          const AutoIssuanceResultDto(
                started: false,
                skipped: true,
                reason: 'policy',
              )
              as TResult,
        );
      case FakeEInvoiceScenario.autoIssueSkippedNotReady:
        return Future.value(
          const AutoIssuanceResultDto(
                started: false,
                skipped: true,
                reason: 'readiness',
              )
              as TResult,
        );
      case FakeEInvoiceScenario.autoIssueDuplicateTrigger:
        return Future.value(
          const AutoIssuanceResultDto(
                started: false,
                skipped: true,
                reason: 'duplicate',
              )
              as TResult,
        );
      default:
        return Future.value(
          const AutoIssuanceResultDto(started: true, skipped: false) as TResult,
        );
    }
  }

  Future<TResult> _recordIssuanceResult<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.recordIssuanceDefiniteFail:
        return Future.value(
          const RecordIssuanceResultDto(
                attemptStatus: IssuanceAttemptStatus.failed,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.recordIssuanceUndetermined:
        return Future.value(
          const RecordIssuanceResultDto(
                attemptStatus: IssuanceAttemptStatus.reconciling,
              )
              as TResult,
        );
      default:
        return Future.value(
          const RecordIssuanceResultDto(
                attemptStatus: IssuanceAttemptStatus.succeeded,
                electronicInvoiceId: 'ei-fake-001',
              )
              as TResult,
        );
    }
  }

  Future<TResult> _retryIssuance<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.retryWhileReconciling:
        throw const OperationInProgressException();
      case FakeEInvoiceScenario.retryNotReady:
        throw IssuanceNotReadyException();
      default:
        return Future.value(FakeEInvoiceFixtures.issueProcessing as TResult);
    }
  }

  Future<TResult> _openReconciliation<TResult>() {
    return Future.value(
      const ReconciliationCaseDto(
            caseId: 'rc-fake-001',
            attemptId: 'att-fake-001',
            status: ReconciliationCaseStatus.pending,
          )
          as TResult,
    );
  }

  Future<TResult> _resolveReconciliation<TResult>() {
    return Future.value(
      const ReconciliationCaseDto(
            caseId: 'rc-fake-001',
            attemptId: 'att-fake-001',
            status: ReconciliationCaseStatus.resolved,
          )
          as TResult,
    );
  }

  Future<TResult> _recoverFinalization<TResult>() {
    return Future.value(
      RecoverInternalFinalizationResultDto(
            invoice: const ElectronicInvoiceDto(
              electronicInvoiceId: 'ei-fake-001',
              salesOrderId: FakeEInvoiceFixtures.salesOrderId,
              invoiceNumber: '000001',
            ),
          )
          as TResult,
    );
  }

  Future<TResult> _attemptStatusQuery<TResult>() {
    return Future.value(
      const IssuanceAttemptStatusDto(
            attemptId: 'att-fake-001',
            status: IssuanceAttemptStatus.failed,
            internalFinalizationStatus: InternalFinalizationStatus.pending,
            hasElectronicInvoice: false,
            hasActiveOperation: false,
            failureCode: 'PROVIDER_REJECTED',
            lastErrorMessage: 'Provider rejected',
          )
          as TResult,
    );
  }

  Future<TResult> _officialView<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.officialViewNotIssued:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.notFound);
      case FakeEInvoiceScenario.officialViewProviderDown:
        throw const ProviderUnavailableException();
      case FakeEInvoiceScenario.officialViewPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      default:
        return Future.value(
          OfficialInvoiceViewDto(
                viewerUrl: 'https://view.fake/invoice',
                expiresAt: DateTime.utc(2026, 12, 31),
              )
              as TResult,
        );
    }
  }

  Future<TResult> _invoiceDetailQuery<TResult>() {
    return Future.value(
      const ElectronicInvoiceDetailDto(
            electronicInvoiceId: 'ei-fake-001',
            salesOrderId: FakeEInvoiceFixtures.salesOrderId,
            invoiceNumber: '000001',
          )
          as TResult,
    );
  }

  Future<TResult> _requestDocument<TResult>(RequestInvoiceDocumentCommand c) {
    switch (scenario) {
      case FakeEInvoiceScenario.downloadUnavailable:
        return Future.value(
          InvoiceDocumentRetrievalDto(
                operationId: 'op-doc-failed-1',
                status: InvoiceDocumentStatus.failed,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.downloadPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      default:
        return Future.value(
          InvoiceDocumentRetrievalDto(
                downloadUrl: 'https://download.fake/${c.documentType.name}',
                checksum: 'abc123',
              )
              as TResult,
        );
    }
  }

  Future<TResult> _documentsQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.documentsListPartial:
        return Future.value(
          const InvoiceDocumentsDto(
                pdfAvailable: true,
                xmlAvailable: false,
                retrievalStatus: InvoiceDocumentStatus.pending,
              )
              as TResult,
        );
      default:
        return Future.value(
          const InvoiceDocumentsDto(
                pdfAvailable: true,
                xmlAvailable: true,
                retrievalStatus: InvoiceDocumentStatus.available,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _recordObservation<TResult>() {
    if (scenario == FakeEInvoiceScenario.observationProviderUnavailable) {
      throw const ProviderUnavailableException();
    }
    return Future.value(
      ProviderObservationDto(
            observationId: 'obs-fake-001',
            electronicInvoiceId: 'ei-fake-001',
            providerStateCode: 'PUBLISHED',
            observedAt: DateTime.utc(2026, 1, 1),
            source: 'worker',
            correlationId: 'corr-fake-001',
            detailsSnapshot: const {'publishStatus': 1},
          )
          as TResult,
    );
  }

  Future<TResult> _latestObservationQuery<TResult>() {
    return Future.value(
      ProviderObservationDto(
            observationId: 'obs-fake-001',
            electronicInvoiceId: 'ei-fake-001',
            providerStateCode: 'PUBLISHED',
            observedAt: DateTime.utc(2026, 1, 1),
            source: 'worker',
            correlationId: 'corr-fake-001',
            detailsSnapshot: const {'publishStatus': 1},
          )
          as TResult,
    );
  }

  Future<TResult> _startAutoDelivery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.autoSendSkippedNoEmail:
        return Future.value(
          const AutoDeliveryResultDto(
                disposition: AutoDeliveryDisposition.skipped,
                skipReason: AutoDeliverySkipReason.invalidOrMissingEmail,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.autoSendSkippedPolicyOff:
        return Future.value(
          const AutoDeliveryResultDto(
                disposition: AutoDeliveryDisposition.skipped,
                skipReason: AutoDeliverySkipReason.policyOff,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.autoSendNotSupported:
        throw const DeliveryNotSupportedException();
      default:
        return Future.value(
          const AutoDeliveryResultDto(
                disposition: AutoDeliveryDisposition.started,
                deliveryId: 'del-fake-001',
              )
              as TResult,
        );
    }
  }

  Future<TResult> _sendSheetQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.sendSheetResend:
        return Future.value(
          SendInvoiceSheetContextDto(
                mode: SendInvoiceSheetMode.resend,
                suggestedEmail: 'buyer@fake.test',
                suggestedEmailSource: DeliveryRecipientSource.lastInvoiceDelivery,
                history: [_fakeDelivery(no: 1, kind: DeliveryKind.initial)],
                operationLocked: false,
                displayState: DeliveryDisplayState.sent,
              )
              as TResult,
        );
      default:
        return Future.value(
          const SendInvoiceSheetContextDto(
                mode: SendInvoiceSheetMode.send,
                suggestedEmail: 'buyer@fake.test',
                suggestedEmailSource: DeliveryRecipientSource.currentPartnerProfile,
                history: [],
                operationLocked: false,
                displayState: DeliveryDisplayState.notSent,
              )
              as TResult,
        );
    }
  }

  InvoiceDeliveryItemDto _fakeDelivery({
    required int no,
    required DeliveryKind kind,
    DeliveryStatus status = DeliveryStatus.succeeded,
  }) {
    final startedAt = DateTime.utc(2026, 1, no);
    return InvoiceDeliveryItemDto(
      deliveryId: 'del-$no',
      deliveryNo: no,
      kind: kind,
      triggerType: kind == DeliveryKind.initial
          ? DeliveryTriggerType.automatic
          : DeliveryTriggerType.manual,
      recipientEmail: 'buyer@fake.test',
      status: status,
      initiatedByActorType: kind == DeliveryKind.initial
          ? DeliveryActorType.system
          : DeliveryActorType.user,
      initiatedByActorId: kind == DeliveryKind.initial ? null : 'a1',
      startedAt: startedAt,
      completedAt: status == DeliveryStatus.processing ? null : startedAt,
      failureCode: null,
    );
  }

  Future<TResult> _sendInvoice<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.sendInvalidEmail:
        throw ValidationException('Invalid email format');
      case FakeEInvoiceScenario.sendPermissionDenied:
        throw const EInvoiceBlockedException(EInvoiceBlockedCodes.noPermission);
      case FakeEInvoiceScenario.sendInProgress:
        throw const OperationInProgressException();
      default:
        return Future.value(
          const SendInvoiceResultDto(
                deliveryId: 'del-fake-001',
                status: DeliveryStatus.processing,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _deliveryHistoryQuery<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.deliveryHistoryMulti:
        return Future.value(
          InvoiceDeliveryHistoryDto(
                deliveries: [
                  _fakeDelivery(no: 1, kind: DeliveryKind.initial),
                  _fakeDelivery(
                    no: 2,
                    kind: DeliveryKind.resend,
                    status: DeliveryStatus.processing,
                  ),
                ],
                displayState: DeliveryDisplayState.sent,
                hasSecondaryAttention: false,
              )
              as TResult,
        );
      default:
        return Future.value(
          const InvoiceDeliveryHistoryDto(
                deliveries: [],
                displayState: DeliveryDisplayState.notSent,
                hasSecondaryAttention: false,
              )
              as TResult,
        );
    }
  }

  Future<TResult> _recordDeliveryResult<TResult>() {
    switch (scenario) {
      case FakeEInvoiceScenario.deliveryFailed:
        return Future.value(
          const RecordDeliveryResultDto(
                deliveryStatus: DeliveryStatus.failed,
                displayState: DeliveryDisplayState.failed,
                hasSecondaryAttention: false,
              )
              as TResult,
        );
      case FakeEInvoiceScenario.deliveryUndetermined:
        return Future.value(
          const RecordDeliveryResultDto(
                deliveryStatus: DeliveryStatus.unknown,
                displayState: DeliveryDisplayState.sending,
                hasSecondaryAttention: true,
              )
              as TResult,
        );
      default:
        return Future.value(
          const RecordDeliveryResultDto(
                deliveryStatus: DeliveryStatus.succeeded,
                displayState: DeliveryDisplayState.sent,
                hasSecondaryAttention: false,
              )
              as TResult,
        );
    }
  }
}
