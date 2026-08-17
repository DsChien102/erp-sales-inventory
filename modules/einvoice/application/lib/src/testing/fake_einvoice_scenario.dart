/// Named fake scenarios from harness/07-api-contracts.md (77 ids).
enum FakeEInvoiceScenario {
  // §S1a
  connectionScreenOk,
  connectionScreenDisconnected,
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
  // §S2a
  readinessReady,
  readinessBuyerIncomplete,
  previewOk,
  previewConfigNotReady,
  previewProviderUnavailable,
  completeBuyerLocks,
  previewPermissionDenied,
  // §S2b
  issueOk,
  issueAlreadyIssued,
  issueInProgress,
  issueNotReady,
  issueIdempotentReplay,
  issueStateChanged,
  projectionProcessing,
  projectionIssued,
  projectionFailed,
  // §S3a
  autoIssueStarted,
  autoIssueSkippedPolicyOff,
  autoIssueSkippedNotReady,
  autoIssueDuplicateTrigger,
  // §S3b
  recordIssuanceSuccess,
  recordIssuanceDefiniteFail,
  recordIssuanceUndetermined,
  recoverFinalizationOk,
  reconcileResolvedSuccess,
  // §S3c
  retryAfterFailOk,
  retryWhileReconciling,
  retryProjectionFailedState,
  retryNotReady,
  // §S4a
  officialViewOk,
  officialViewNotIssued,
  officialViewProviderDown,
  officialViewPermissionDenied,
  // §S4b
  downloadPdfOk,
  downloadXmlOk,
  downloadUnavailable,
  downloadPermissionDenied,
  documentsListPartial,
  // §S4c
  observationRecorded,
  observationLatestQuery,
  observationProviderUnavailable,
  // §S5a
  autoSendStarted,
  autoSendSkippedNoEmail,
  autoSendSkippedPolicyOff,
  autoSendNotSupported,
  // §S5b
  sendSheetInitial,
  sendSheetResend,
  sendOk,
  sendInvalidEmail,
  sendPermissionDenied,
  sendInProgress,
  // §S5c
  deliverySuccess,
  deliveryFailed,
  deliveryUndetermined,
  deliveryHistoryMulti,
}

extension FakeEInvoiceScenarioId on FakeEInvoiceScenario {
  String get scenarioId => switch (this) {
        FakeEInvoiceScenario.connectionScreenOk => 'connection_screen_ok',
        FakeEInvoiceScenario.connectionScreenDisconnected =>
          'connection_screen_disconnected',
        FakeEInvoiceScenario.connectOk => 'connect_ok',
        FakeEInvoiceScenario.connectAuthFailed => 'connect_auth_failed',
        FakeEInvoiceScenario.connectLegalMismatch => 'connect_legal_mismatch',
        FakeEInvoiceScenario.verifyProviderUnavailable =>
          'verify_provider_unavailable',
        FakeEInvoiceScenario.disconnectOk => 'disconnect_ok',
        FakeEInvoiceScenario.connectPermissionDenied =>
          'connect_permission_denied',
        FakeEInvoiceScenario.listTemplatesOk => 'list_templates_ok',
        FakeEInvoiceScenario.setDefaultHsmOk => 'set_default_hsm_ok',
        FakeEInvoiceScenario.setDefaultIncompatible => 'set_default_incompatible',
        FakeEInvoiceScenario.setDefaultNotConnected => 'set_default_not_connected',
        FakeEInvoiceScenario.listTemplatesPermissionDenied =>
          'list_templates_permission_denied',
        FakeEInvoiceScenario.automationPolicyOk => 'automation_policy_ok',
        FakeEInvoiceScenario.enableAutoIssueOk => 'enable_auto_issue_ok',
        FakeEInvoiceScenario.enableAutoIssueNotReady =>
          'enable_auto_issue_not_ready',
        FakeEInvoiceScenario.enableAutoSendOk => 'enable_auto_send_ok',
        FakeEInvoiceScenario.automationStateChanged => 'automation_state_changed',
        FakeEInvoiceScenario.configReadinessReady => 'config_readiness_ready',
        FakeEInvoiceScenario.configReadinessWarnings =>
          'config_readiness_warnings',
        FakeEInvoiceScenario.configReadinessBlocked => 'config_readiness_blocked',
        FakeEInvoiceScenario.configReadinessAutoIssueBlocked =>
          'config_readiness_auto_issue_blocked',
        FakeEInvoiceScenario.readinessReady => 'readiness_ready',
        FakeEInvoiceScenario.readinessBuyerIncomplete =>
          'readiness_buyer_incomplete',
        FakeEInvoiceScenario.previewOk => 'preview_ok',
        FakeEInvoiceScenario.previewConfigNotReady => 'preview_config_not_ready',
        FakeEInvoiceScenario.previewProviderUnavailable =>
          'preview_provider_unavailable',
        FakeEInvoiceScenario.completeBuyerLocks => 'complete_buyer_locks',
        FakeEInvoiceScenario.previewPermissionDenied =>
          'preview_permission_denied',
        FakeEInvoiceScenario.issueOk => 'issue_ok',
        FakeEInvoiceScenario.issueAlreadyIssued => 'issue_already_issued',
        FakeEInvoiceScenario.issueInProgress => 'issue_in_progress',
        FakeEInvoiceScenario.issueNotReady => 'issue_not_ready',
        FakeEInvoiceScenario.issueIdempotentReplay => 'issue_idempotent_replay',
        FakeEInvoiceScenario.issueStateChanged => 'issue_state_changed',
        FakeEInvoiceScenario.projectionProcessing => 'projection_processing',
        FakeEInvoiceScenario.projectionIssued => 'projection_issued',
        FakeEInvoiceScenario.projectionFailed => 'projection_failed',
        FakeEInvoiceScenario.autoIssueStarted => 'auto_issue_started',
        FakeEInvoiceScenario.autoIssueSkippedPolicyOff =>
          'auto_issue_skipped_policy_off',
        FakeEInvoiceScenario.autoIssueSkippedNotReady =>
          'auto_issue_skipped_not_ready',
        FakeEInvoiceScenario.autoIssueDuplicateTrigger =>
          'auto_issue_duplicate_trigger',
        FakeEInvoiceScenario.recordIssuanceSuccess => 'record_issuance_success',
        FakeEInvoiceScenario.recordIssuanceDefiniteFail =>
          'record_issuance_definite_fail',
        FakeEInvoiceScenario.recordIssuanceUndetermined =>
          'record_issuance_undetermined',
        FakeEInvoiceScenario.recoverFinalizationOk => 'recover_finalization_ok',
        FakeEInvoiceScenario.reconcileResolvedSuccess =>
          'reconcile_resolved_success',
        FakeEInvoiceScenario.retryAfterFailOk => 'retry_after_fail_ok',
        FakeEInvoiceScenario.retryWhileReconciling => 'retry_while_reconciling',
        FakeEInvoiceScenario.retryProjectionFailedState =>
          'retry_projection_failed_state',
        FakeEInvoiceScenario.retryNotReady => 'retry_not_ready',
        FakeEInvoiceScenario.officialViewOk => 'official_view_ok',
        FakeEInvoiceScenario.officialViewNotIssued => 'official_view_not_issued',
        FakeEInvoiceScenario.officialViewProviderDown =>
          'official_view_provider_down',
        FakeEInvoiceScenario.officialViewPermissionDenied =>
          'official_view_permission_denied',
        FakeEInvoiceScenario.downloadPdfOk => 'download_pdf_ok',
        FakeEInvoiceScenario.downloadXmlOk => 'download_xml_ok',
        FakeEInvoiceScenario.downloadUnavailable => 'download_unavailable',
        FakeEInvoiceScenario.downloadPermissionDenied =>
          'download_permission_denied',
        FakeEInvoiceScenario.documentsListPartial => 'documents_list_partial',
        FakeEInvoiceScenario.observationRecorded => 'observation_recorded',
        FakeEInvoiceScenario.observationLatestQuery => 'observation_latest_query',
        FakeEInvoiceScenario.observationProviderUnavailable =>
          'observation_provider_unavailable',
        FakeEInvoiceScenario.autoSendStarted => 'auto_send_started',
        FakeEInvoiceScenario.autoSendSkippedNoEmail =>
          'auto_send_skipped_no_email',
        FakeEInvoiceScenario.autoSendSkippedPolicyOff =>
          'auto_send_skipped_policy_off',
        FakeEInvoiceScenario.autoSendNotSupported => 'auto_send_not_supported',
        FakeEInvoiceScenario.sendSheetInitial => 'send_sheet_initial',
        FakeEInvoiceScenario.sendSheetResend => 'send_sheet_resend',
        FakeEInvoiceScenario.sendOk => 'send_ok',
        FakeEInvoiceScenario.sendInvalidEmail => 'send_invalid_email',
        FakeEInvoiceScenario.sendPermissionDenied => 'send_permission_denied',
        FakeEInvoiceScenario.sendInProgress => 'send_in_progress',
        FakeEInvoiceScenario.deliverySuccess => 'delivery_success',
        FakeEInvoiceScenario.deliveryFailed => 'delivery_failed',
        FakeEInvoiceScenario.deliveryUndetermined => 'delivery_undetermined',
        FakeEInvoiceScenario.deliveryHistoryMulti => 'delivery_history_multi',
      };
}
