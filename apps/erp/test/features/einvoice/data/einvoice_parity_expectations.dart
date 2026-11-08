import 'package:flutter_test/flutter_test.dart';

// Parity constants for Task 0.1
const parityTenantId = '11111111-1111-4111-8111-111111111111';
const parityActorId = '22222222-2222-4222-8222-222222222222';
const parityOrderId = '33333333-3333-4333-8333-333333333333';
const parityIdempotencyKey = '44444444-4444-4444-8444-444444444444';

const parityRawUsername = '  misa-user  ';
const parityExpectedUsername = 'misa-user';

const parityRawPassword = ' p ';
const parityExpectedPassword = ' p ';

const parityRawConnectionId = ' CONN-01 ';
const parityExpectedConnectionId = ' CONN-01 ';

const parityRawTemplateId = ' 1C26TAA ';
const parityExpectedTemplateId = '1C26TAA';

const parityRawSigningConfigId = ' SIGN-01 ';
const parityExpectedSigningConfigId = 'SIGN-01';

const parityRawEmail = ' a@b.vn ';
const parityExpectedEmail = ' a@b.vn ';

// Expected params for all 24 RPCs
// C1: get_provider_connection_screen
const expectedGetConnectionScreenParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
};

// C2: connect_provider
const expectedConnectParamsWithVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_username': parityExpectedUsername,
  'p_password': parityExpectedPassword,
  'p_expected_connection_version': 3,
};

const expectedConnectParamsWithoutVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_username': parityExpectedUsername,
  'p_password': parityExpectedPassword,
};

// C3: reconnect_provider
const expectedReconnectParamsWithVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_connection_id': parityExpectedConnectionId,
  'p_username': parityExpectedUsername,
  'p_password': parityExpectedPassword,
  'p_expected_connection_version': 3,
};

const expectedReconnectParamsWithoutVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_connection_id': parityExpectedConnectionId,
  'p_username': parityExpectedUsername,
  'p_password': parityExpectedPassword,
};

// C4: disconnect_provider
const expectedDisconnectParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_connection_id': parityExpectedConnectionId,
  'p_confirm': true,
};

// C5: list_provider_templates
const expectedListTemplatesParamsWithFilters = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_invoice_with_code': true,
  'p_year': 2026,
};

const expectedListTemplatesParamsWithoutFilters = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
};

// C6: get_issuance_profile
const expectedGetIssuanceProfileParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
};

// C7: set_default_issuance_configuration
const expectedSetDefaultConfigurationParamsWithVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_template_id': parityExpectedTemplateId,
  'p_signing_config_id': parityExpectedSigningConfigId,
  'p_expected_profile_version': 2,
};

const expectedSetDefaultConfigurationParamsWithoutVersion = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_template_id': parityExpectedTemplateId,
  'p_signing_config_id': parityExpectedSigningConfigId,
};

// C8: get_automation_policy
const expectedGetAutomationPolicyParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
};

// C9: update_automation_policy
const expectedUpdateAutomationPolicyParamsWithBoth = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_auto_issue_enabled': true,
  'p_auto_send_enabled': false,
  'p_expected_policy_version': 1,
};

const expectedUpdateAutomationPolicyParamsAutoIssueOnly = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_auto_issue_enabled': true,
  'p_expected_policy_version': 1,
};

// C10: get_configuration_readiness
const expectedGetConfigurationReadinessParamsWithPurpose = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_purpose': 'manualIssue',
};

const expectedGetConfigurationReadinessParamsWithoutPurpose = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
};

// O1: get_order_invoice_projection
const expectedGetOrderInvoiceProjectionParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O2: get_issuance_readiness
const expectedGetIssuanceReadinessParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O3: get_issuance_attempt_status
const expectedGetIssuanceAttemptStatusParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O4: request_invoice_preview
const expectedRequestInvoicePreviewParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_expected_order_version': 5,
};

// O5: get_invoice_preview
const expectedGetInvoicePreviewParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O6: issue_invoice
const expectedIssueInvoiceParamsWithAck = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_source_version': '1',
  'p_idempotency_key': parityIdempotencyKey,
  'p_acknowledge_warnings': true,
};

const expectedIssueInvoiceParamsWithoutAck = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_source_version': '1',
  'p_idempotency_key': parityIdempotencyKey,
  'p_acknowledge_warnings': false,
};

// O7: retry_issuance
const expectedRetryIssuanceParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_expected_order_version': '7',
  'p_idempotency_key': parityIdempotencyKey,
  'p_acknowledge_warnings': false,
};

// O8: request_official_invoice_view
const expectedRequestOfficialViewParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O9: get_electronic_invoice_detail
const expectedGetElectronicInvoiceDetailParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O10: request_invoice_document
const expectedRequestDocumentPdfParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_document_type': 'PDF',
};

const expectedRequestDocumentXmlParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_document_type': 'XML',
};

// O11: get_invoice_documents
const expectedGetInvoiceDocumentsParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O12: get_send_invoice_sheet_context
const expectedGetSendSheetContextParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// O13: send_electronic_invoice
const expectedSendElectronicInvoiceParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
  'p_recipient_email': parityExpectedEmail,
  'p_idempotency_key': parityIdempotencyKey,
};

// O14: get_invoice_delivery_history
const expectedGetInvoiceDeliveryHistoryParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_actor_id': parityActorId,
  'p_sales_order_id': parityOrderId,
};

// Sample JSONs for Task 0.2
Map<String, dynamic> sampleConnectionScreenJson() => <String, dynamic>{
  'legal_profile': {
    'legal_name': 'Công ty An Phú',
    'tax_code': '0101234567',
    'address': '123 Đường ABC',
  },
  'connection': {
    'connection_id': 'connection-1',
    'status': 'CONNECTED',
    'last_checked_at': '2026-11-08T09:00:00.000Z',
    'masked_account': 'ke***@anphu.vn',
    'connection_version': 7,
  },
};

Map<String, dynamic> sampleConnectionResultJson() => <String, dynamic>{
  'connection_id': 'connection-1',
  'status': 'CONNECTED',
};

List<dynamic> sampleTemplateListJson() => <dynamic>[
  {
    'template_id': 'tpl-1',
    'name': 'Mẫu 1',
    'serial': '1',
    'symbol': '1C26TAA',
    'invoice_series': '1C26TAA',
    'invoice_with_code': true,
    'is_mtt': false,
    'is_send_summary': false,
  },
  {
    'template_id': 'tpl-2',
    'name': 'Mẫu 2',
    'serial': '2',
    'symbol': '2C26TBB',
    'invoice_series': '2C26TBB',
    'invoice_with_code': false,
    'is_mtt': true,
    'is_send_summary': true,
  },
];

Map<String, dynamic> sampleIssuanceProfileJson() => <String, dynamic>{
  'profile_version': 3,
  'template_id': 'tpl-1',
  'signing_config_id': 'sign-1',
  'signing_method': 'hsm',
  'compatibility_warnings': ['WARN_1', 'WARN_2'],
};

Map<String, dynamic> sampleAutomationPolicyJson() => <String, dynamic>{
  'auto_issue_enabled': true,
  'auto_send_enabled': false,
  'policy_version': 4,
  'blockers': ['CONFIG_NOT_READY'],
};

Map<String, dynamic> sampleConfigurationReadinessJson() => <String, dynamic>{
  'level': 'ready',
  'blockers': [
    {'code': 'B1', 'message': 'Blocker 1'},
  ],
  'warnings': [
    {'code': 'W1', 'message': 'Warning 1'},
  ],
};

Map<String, dynamic> sampleOrderInvoiceProjectionJson() => <String, dynamic>{
  'sales_order_id': parityOrderId,
  'issuance_display_state': 'issued',
  'delivery_display_state': 'sent',
  'has_secondary_attention': false,
  'delivery_pending': false,
  'actions': ['view', 'downloadPdf'],
};

Map<String, dynamic> sampleIssuanceAttemptStatusJson() => <String, dynamic>{
  'attempt_id': 'att-1',
  'status': 'SUCCEEDED',
  'internal_finalization_status': 'completed',
  'has_electronic_invoice': true,
  'has_active_operation': false,
  'failure_code': null,
  'last_error_message': null,
};

Map<String, dynamic> sampleInvoicePreviewResultJson() => <String, dynamic>{
  'viewer_ref': 'preview-ref-1',
  'failure_code': null,
};

Map<String, dynamic> sampleIssueInvoiceResultJson() => <String, dynamic>{
  'issuance_id': 'iss-1',
  'attempt_id': 'att-1',
  'status': 'PREPARING',
};

Map<String, dynamic> sampleOfficialViewJson() => <String, dynamic>{
  'operation_id': 'op-1',
  'status': 'AVAILABLE',
  'viewer_url': 'https://view.misa.vn/doc/1',
  'viewer_token': 'token-123',
  'expires_at': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
};

Map<String, dynamic> sampleDocumentRetrievalJson() => <String, dynamic>{
  'request_id': 'req-1',
  'status': 'AVAILABLE',
  'storage_reference': 'invoices/inv-1.pdf',
  'checksum': 'sha256-abc',
};

Map<String, dynamic> sampleDetailJson() => <String, dynamic>{
  'electronic_invoice_id': 'einvoice-1',
  'sales_order_id': parityOrderId,
  'invoice_number': '0000001',
  'provider_ref': 'MISA-001',
  'issued_at': '2026-11-08T08:00:00.000Z',
  'official_view_operation_id': 'op-1',
  'official_view_status': 'AVAILABLE',
  'official_viewer_url': 'https://view.misa.vn/doc/1',
  'official_viewer_token': 'token-123',
  'official_viewer_expires_at': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
  'official_view_failure_code': null,
};

Map<String, dynamic> sampleDocumentsJson() => <String, dynamic>{
  'pdf_available': true,
  'xml_available': true,
  'retrieval_status': 'AVAILABLE',
  'pdf_operation_id': 'op-pdf',
  'pdf_status': 'AVAILABLE',
  'pdf_storage_reference': 'invoices/inv-1.pdf',
  'pdf_checksum': 'sha256-pdf',
  'pdf_failure_code': null,
  'xml_operation_id': 'op-xml',
  'xml_status': 'PENDING',
  'xml_storage_reference': null,
  'xml_checksum': null,
  'xml_failure_code': null,
};

Map<String, dynamic> sampleSendSheetContextJson() => <String, dynamic>{
  'mode': 'send',
  'suggested_email': 'buyer@example.com',
  'suggested_email_source': 'BUYER_INVOICE_SNAPSHOT',
  'history': [
    {
      'deliveryId': 'del-1',
      'deliveryNo': 1,
      'kind': 'INITIAL_SEND',
      'triggerType': 'MANUAL',
      'recipientEmail': 'buyer@example.com',
      'status': 'PROCESSING',
      'initiatedByActorType': 'USER',
      'initiatedByActorId': parityActorId,
      'startedAt': '2026-11-08T09:00:00.000Z',
      'completedAt': null,
      'failureCode': null,
    }
  ],
  'operation_locked': false,
  'display_state': 'SENDING',
};

Map<String, dynamic> sampleSendInvoiceResultJson() => <String, dynamic>{
  'delivery_id': 'del-1',
  'status': 'PROCESSING',
};

Map<String, dynamic> sampleHistoryJson() => <String, dynamic>{
  'deliveries': [
    {
      'deliveryId': 'del-1',
      'deliveryNo': 1,
      'kind': 'INITIAL_SEND',
      'triggerType': 'MANUAL',
      'recipientEmail': 'buyer@example.com',
      'status': 'SUCCEEDED',
      'initiatedByActorType': 'USER',
      'initiatedByActorId': parityActorId,
      'startedAt': '2026-11-08T09:00:00.000Z',
      'completedAt': '2026-11-08T09:01:00.000Z',
      'failureCode': null,
    }
  ],
  'display_state': 'SENT',
  'has_secondary_attention': false,
};

// Readiness 3 sample sets (Task 0.2)
Map<String, dynamic> sampleReadinessReadyJson() => <String, dynamic>{
  'order_completed': true,
  'has_electronic_invoice': false,
  'has_active_operation': false,
  'config_ready': true,
  'provider_connected': true,
  'provider_supports_preview': true,
  'buyer_type': 'retail',
  'buyer_name': 'Khách lẻ',
  'buyer_completion_state': 'locked',
  'commercial_data_mappable': true,
  'config_warnings': <dynamic>[],
  'source_blockers': <dynamic>[],
};

Map<String, dynamic> sampleReadinessMissingTemplateJson() => <String, dynamic>{
  'order_completed': true,
  'has_electronic_invoice': false,
  'has_active_operation': false,
  'config_ready': false,
  'provider_connected': true,
  'provider_supports_preview': true,
  'buyer_type': 'retail',
  'buyer_name': 'Khách lẻ',
  'buyer_completion_state': 'locked',
  'commercial_data_mappable': true,
  'config_warnings': <dynamic>[],
  'source_blockers': <dynamic>[],
};

Map<String, dynamic> sampleReadinessOrgMissingTaxJson() => <String, dynamic>{
  'order_completed': true,
  'has_electronic_invoice': false,
  'has_active_operation': false,
  'config_ready': true,
  'provider_connected': true,
  'provider_supports_preview': true,
  'buyer_type': 'organization',
  'buyer_name': 'Công ty XYZ',
  'buyer_tax_code': null,
  'buyer_address': '123 Đường XYZ',
  'buyer_completion_state': 'locked',
  'commercial_data_mappable': true,
  'config_warnings': <dynamic>[],
  'source_blockers': <dynamic>[],
};

Map<String, dynamic> sampleReadinessOrgMissingAddressJson() => <String, dynamic>{
  'order_completed': true,
  'has_electronic_invoice': false,
  'has_active_operation': false,
  'config_ready': true,
  'provider_connected': true,
  'provider_supports_preview': true,
  'buyer_type': 'organization',
  'buyer_name': 'Công ty XYZ',
  'buyer_tax_code': '0101234567',
  'buyer_address': null,
  'buyer_completion_state': 'locked',
  'commercial_data_mappable': true,
  'config_warnings': <dynamic>[],
  'source_blockers': <dynamic>[],
};

// Verification functions (expectX) accepting dynamic for old/new compatibility
void expectConnectionScreen(dynamic screen) {
  expect(screen.legalProfile.legalName, 'Công ty An Phú');
  expect(screen.legalProfile.taxCode, '0101234567');
  expect(screen.legalProfile.address, '123 Đường ABC');
  expect(screen.connection.connectionId, 'connection-1');
  expect((screen.connection.status as Enum).name, 'connected');
  expect(screen.connection.maskedAccount, 'ke***@anphu.vn');
  expect(screen.connection.connectionVersion, 7);
}

void expectConnectionResult(dynamic result) {
  expect(result.connectionId, 'connection-1');
  expect((result.status as Enum).name, 'connected');
}

void expectTemplateList(dynamic templates) {
  final list = templates as List;
  expect(list, hasLength(2));
  expect(list[0].templateId, 'tpl-1');
  expect(list[0].symbol, '1C26TAA');
  expect(list[0].invoiceWithCode, isTrue);
  expect(list[1].templateId, 'tpl-2');
  expect(list[1].symbol, '2C26TBB');
  expect(list[1].isMtt, isTrue);
}

void expectIssuanceProfile(dynamic profile) {
  expect(profile.profileVersion, 3);
  expect(profile.templateId, 'tpl-1');
  expect(profile.signingConfigId, 'sign-1');
  expect((profile.signingMethod as Enum?)?.name, 'hsm');
  expect(profile.compatibilityWarnings, ['WARN_1', 'WARN_2']);
}

void expectAutomationPolicy(dynamic policy) {
  expect(policy.autoIssueEnabled, isTrue);
  expect(policy.autoSendEnabled, isFalse);
  expect(policy.policyVersion, 4);
  expect(policy.blockers, ['CONFIG_NOT_READY']);
}

void expectConfigurationReadiness(dynamic readiness) {
  expect((readiness.level as Enum).name, 'ready');
  expect(readiness.blockers, hasLength(1));
  expect(readiness.blockers.first.code, 'B1');
  expect(readiness.warnings, hasLength(1));
  expect(readiness.warnings.first.code, 'W1');
}

void expectOrderInvoiceProjection(dynamic projection) {
  expect(projection.salesOrderId, parityOrderId);
  expect((projection.issuanceDisplayState as Enum).name, 'issued');
  expect((projection.deliveryDisplayState as Enum?)?.name, 'sent');
  expect(projection.hasSecondaryAttention, isFalse);
  expect(projection.deliveryPending, isFalse);
  expect(
    (projection.actions as List).map((a) => (a as Enum).name).toList(),
    ['view', 'downloadPdf'],
  );
}

void expectIssuanceAttemptStatus(dynamic attempt) {
  expect(attempt.attemptId, 'att-1');
  expect((attempt.status as Enum).name, 'succeeded');
  expect((attempt.internalFinalizationStatus as Enum).name, 'completed');
  expect(attempt.hasElectronicInvoice, isTrue);
  expect(attempt.hasActiveOperation, isFalse);
}

void expectInvoicePreviewResult(dynamic preview) {
  expect(preview.viewerRef, 'preview-ref-1');
}

void expectIssueInvoiceResult(dynamic result) {
  expect(result.issuanceId, 'iss-1');
  expect(result.attemptId, 'att-1');
  expect((result.status as Enum).name, 'preparing');
}

void expectOfficialInvoiceView(dynamic view) {
  expect(view.operationId, 'op-1');
  expect((view.status as Enum).name, 'available');
  expect(view.viewerUrl, 'https://view.misa.vn/doc/1');
  expect(view.token, 'token-123');
  expect(view.expiresAt, isNotNull);
}

void expectInvoiceDocumentRetrieval(dynamic doc) {
  expect(doc.operationId, 'req-1');
  expect((doc.status as Enum).name, 'available');
  expect(doc.fileRef, 'invoices/inv-1.pdf');
  expect(doc.checksum, 'sha256-abc');
}

void expectElectronicInvoiceDetail(dynamic detail) {
  expect(detail.electronicInvoiceId, 'einvoice-1');
  expect(detail.salesOrderId, parityOrderId);
  expect(detail.invoiceNumber, '0000001');
  expect(detail.providerRef, 'MISA-001');
  expect((detail.officialViewStatus as Enum?)?.name, 'available');
  expect(detail.officialViewerUrl, 'https://view.misa.vn/doc/1');
}

void expectInvoiceDocuments(dynamic docs) {
  expect(docs.pdfAvailable, isTrue);
  expect(docs.xmlAvailable, isTrue);
  expect((docs.retrievalStatus as Enum).name, 'available');
  expect(docs.pdf?.operationId, 'op-pdf');
  expect((docs.pdf?.status as Enum?)?.name, 'available');
  expect(docs.xml?.operationId, 'op-xml');
  expect((docs.xml?.status as Enum?)?.name, 'pending');
}

void expectSendInvoiceSheetContext(dynamic context) {
  expect((context.mode as Enum).name, 'send');
  expect(context.suggestedEmail, 'buyer@example.com');
  expect((context.suggestedEmailSource as Enum?)?.name, 'buyerInvoiceSnapshot');
  expect(context.history, hasLength(1));
  expect(context.history.first.recipientEmail, 'buyer@example.com');
  expect((context.history.first.status as Enum).name, 'processing');
  expect(context.operationLocked, isFalse);
  expect((context.displayState as Enum).name, 'sending');
}

void expectSendInvoiceResult(dynamic result) {
  expect(result.deliveryId, 'del-1');
  expect((result.status as Enum).name, 'processing');
}

void expectInvoiceDeliveryHistory(dynamic history) {
  expect(history.deliveries, hasLength(1));
  expect(history.deliveries.first.recipientEmail, 'buyer@example.com');
  expect((history.deliveries.first.status as Enum).name, 'succeeded');
  expect((history.displayState as Enum).name, 'sent');
  expect(history.hasSecondaryAttention, isFalse);
}

void expectIssuanceReadiness(
  dynamic readiness, {
  required String expectedLevel,
  required List<String> expectedBlockers,
  required List<String> expectedWarnings,
}) {
  expect((readiness.level as Enum).name, expectedLevel);
  final actualBlockers =
      (readiness.blockers as List).map((b) => b.code as String).toList();
  expect(actualBlockers, expectedBlockers);
  final actualWarnings =
      (readiness.warnings as List).map((w) => w.code as String).toList();
  expect(actualWarnings, expectedWarnings);
}
