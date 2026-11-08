// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:erp/features/einvoice/data/mappers/configuration_json.dart';
import 'package:erp/features/einvoice/data/mappers/delivery_json.dart';
import 'package:erp/features/einvoice/data/mappers/electronic_invoice_json.dart';
import 'package:erp/features/einvoice/data/mappers/issuance_json.dart';
import 'package:erp/features/einvoice/data/models.dart' as new_models;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/einvoice_rpc_mapper.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/electronic_invoice_rpc_mapper.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/delivery/delivery_rpc_mapper.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/issuance_rpc_mapper.dart';

import 'einvoice_parity_expectations.dart';

void main() {
  group('old', () {
    group('params parity', () {
      test(
        'C1: get_provider_connection_screen',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient (vet45_adapters không nằm trong dependencies của apps/erp); đã đối chiếu mã nguồn SupabaseProviderConnectionReadGateway.getConnectionScreen khớp expectedGetConnectionScreenParams',
      );

      test('C2: connect_provider', () {
        final withVer = EinvoiceRpcMapper.connectProviderParams(
          ConnectProviderCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            username: parityRawUsername,
            password: parityRawPassword,
            expectedConnectionVersion: 3,
          ),
        );
        expect(withVer, equals(expectedConnectParamsWithVersion));

        final withoutVer = EinvoiceRpcMapper.connectProviderParams(
          ConnectProviderCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            username: parityRawUsername,
            password: parityRawPassword,
          ),
        );
        expect(withoutVer, equals(expectedConnectParamsWithoutVersion));
      });

      test('C3: reconnect_provider', () {
        final withVer = EinvoiceRpcMapper.reconnectProviderParams(
          ReconnectProviderCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            connectionId: parityRawConnectionId,
            username: parityRawUsername,
            password: parityRawPassword,
            expectedConnectionVersion: 3,
          ),
        );
        expect(withVer, equals(expectedReconnectParamsWithVersion));

        final withoutVer = EinvoiceRpcMapper.reconnectProviderParams(
          ReconnectProviderCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            connectionId: parityRawConnectionId,
            username: parityRawUsername,
            password: parityRawPassword,
          ),
        );
        expect(withoutVer, equals(expectedReconnectParamsWithoutVersion));
      });

      test('C4: disconnect_provider', () {
        final params = EinvoiceRpcMapper.disconnectProviderParams(
          DisconnectProviderCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            connectionId: parityRawConnectionId,
            confirm: true,
          ),
        );
        expect(params, equals(expectedDisconnectParams));
      });

      test(
        'C5: list_provider_templates',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseProviderConnectionReadGateway.listProviderTemplates khớp expectedListTemplatesParamsWithFilters / expectedListTemplatesParamsWithoutFilters',
      );

      test(
        'C6: get_issuance_profile',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseIssuanceProfileGateway.getProfile khớp expectedGetIssuanceProfileParams',
      );

      test(
        'C7: set_default_issuance_configuration',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseIssuanceProfileGateway.setDefaultConfiguration khớp expectedSetDefaultConfigurationParamsWithVersion / expectedSetDefaultConfigurationParamsWithoutVersion',
      );

      test(
        'C8: get_automation_policy',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseAutomationPolicyGateway.getPolicy khớp expectedGetAutomationPolicyParams',
      );

      test(
        'C9: update_automation_policy',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseAutomationPolicyGateway.updatePolicy khớp expectedUpdateAutomationPolicyParamsWithBoth / expectedUpdateAutomationPolicyParamsAutoIssueOnly',
      );

      test(
        'C10: get_configuration_readiness',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseConfigurationReadinessReadGateway.getReadiness khớp expectedGetConfigurationReadinessParamsWithPurpose / expectedGetConfigurationReadinessParamsWithoutPurpose',
      );

      test('O1: get_order_invoice_projection', () {
        final params = IssuanceRpcMapper.orderInvoiceProjectionParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
        );
        expect(params, equals(expectedGetOrderInvoiceProjectionParams));
      });

      test(
        'O2: get_issuance_readiness',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseIssuanceReadinessReadGateway.load khớp expectedGetIssuanceReadinessParams',
      );

      test('O3: get_issuance_attempt_status', () {
        final params = IssuanceRpcMapper.getIssuanceAttemptStatusParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
        );
        expect(params, equals(expectedGetIssuanceAttemptStatusParams));
      });

      test(
        'O4: request_invoice_preview',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseInvoicePreviewGateway.persistRequestAndEnqueue khớp expectedRequestInvoicePreviewParams',
      );

      test(
        'O5: get_invoice_preview',
        () {},
        skip: '⏭ Gateway cũ dựng map tại chỗ qua SupabaseSchemaRpcClient; đã đối chiếu mã nguồn SupabaseInvoicePreviewGateway.readCached khớp expectedGetInvoicePreviewParams',
      );

      test('O6: issue_invoice', () {
        final withAck = IssuanceRpcMapper.issueInvoiceParams(
          const IssueInvoiceStartRequest(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
            sourceVersion: '1',
            idempotencyKey: parityIdempotencyKey,
            acknowledgeWarnings: true,
          ),
        );
        expect(withAck, equals(expectedIssueInvoiceParamsWithAck));

        final withoutAck = IssuanceRpcMapper.issueInvoiceParams(
          const IssueInvoiceStartRequest(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
            sourceVersion: '1',
            idempotencyKey: parityIdempotencyKey,
            acknowledgeWarnings: false,
          ),
        );
        expect(withoutAck, equals(expectedIssueInvoiceParamsWithoutAck));
      });

      test('O7: retry_issuance', () {
        final params = IssuanceRpcMapper.retryIssuanceParams(
          const RetryIssuanceStartRequest(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
            expectedOrderVersion: 7,
            idempotencyKey: parityIdempotencyKey,
            acknowledgeWarnings: false,
          ),
        );
        expect(params, equals(expectedRetryIssuanceParams));
      });

      test('O8, O9, O11: scopedSalesOrderParams', () {
        final params = ElectronicInvoiceRpcMapper.scopedSalesOrderParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
        );
        expect(params, equals(expectedRequestOfficialViewParams));
        expect(params, equals(expectedGetElectronicInvoiceDetailParams));
        expect(params, equals(expectedGetInvoiceDocumentsParams));
      });

      test('O10: requestDocumentParams', () {
        final pdf = ElectronicInvoiceRpcMapper.requestDocumentParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
          documentType: InvoiceDocumentType.pdf,
        );
        expect(pdf, equals(expectedRequestDocumentPdfParams));

        final xml = ElectronicInvoiceRpcMapper.requestDocumentParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
          documentType: InvoiceDocumentType.xml,
        );
        expect(xml, equals(expectedRequestDocumentXmlParams));
      });

      test('O12: sendSheetContextParams', () {
        final params = DeliveryRpcMapper.sendSheetContextParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
        );
        expect(params, equals(expectedGetSendSheetContextParams));
      });

      test('O13: send_electronic_invoice', () {
        final params = DeliveryRpcMapper.startManualParams(
          const ManualDeliveryStartRequest(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
            recipientEmail: parityRawEmail,
            idempotencyKey: parityIdempotencyKey,
          ),
        );
        expect(params, equals(expectedSendElectronicInvoiceParams));
      });

      test('O14: historyParams', () {
        final params = DeliveryRpcMapper.historyParams(
          tenantId: parityTenantId,
          actorId: parityActorId,
          salesOrderId: parityOrderId,
        );
        expect(params, equals(expectedGetInvoiceDeliveryHistoryParams));
      });
    });

    group('json parsing parity', () {
      test('parse_mapConnectionScreen', () {
        final screen = EinvoiceRpcMapper.mapConnectionScreen(sampleConnectionScreenJson());
        expectConnectionScreen(screen);
      });

      test('parse_mapConnectionResult', () {
        final result = EinvoiceRpcMapper.mapConnectionResult(sampleConnectionResultJson());
        expectConnectionResult(result);
      });

      test('parse_mapTemplateList', () {
        final templates = EinvoiceRpcMapper.mapTemplateList(sampleTemplateListJson());
        expectTemplateList(templates);
      });

      test('parse_mapIssuanceProfile', () {
        final profile = EinvoiceRpcMapper.mapIssuanceProfile(sampleIssuanceProfileJson());
        expectIssuanceProfile(profile);
      });

      test('parse_mapAutomationPolicy', () {
        final policy = EinvoiceRpcMapper.mapAutomationPolicy(sampleAutomationPolicyJson());
        expectAutomationPolicy(policy);
      });

      test('parse_mapConfigurationReadiness', () {
        final readiness = EinvoiceRpcMapper.mapConfigurationReadiness(sampleConfigurationReadinessJson());
        expectConfigurationReadiness(readiness);
      });

      test('parse_orderInvoiceProjectionFromRow', () {
        final projection = IssuanceRpcMapper.orderInvoiceProjectionFromRow(sampleOrderInvoiceProjectionJson());
        expectOrderInvoiceProjection(projection);
      });

      test('parse_issuanceAttemptStatusFromRow', () {
        final status = IssuanceRpcMapper.issuanceAttemptStatusFromRow(sampleIssuanceAttemptStatusJson());
        expectIssuanceAttemptStatus(status);
      });

      test('parse_invoicePreviewResultFromRow', () {
        final preview = EinvoiceRpcMapper.invoicePreviewResultFromRow(sampleInvoicePreviewResultJson());
        expectInvoicePreviewResult(preview);
      });

      test('parse_issueInvoiceResultFromRow', () {
        final result = IssuanceRpcMapper.issueInvoiceResultFromRow(sampleIssueInvoiceResultJson());
        expectIssueInvoiceResult(result);
      });

      test('parse_officialViewFromRow', () {
        final view = ElectronicInvoiceRpcMapper.officialViewFromRow(sampleOfficialViewJson());
        expectOfficialInvoiceView(view);
      });

      test('parse_documentRetrievalFromRow', () {
        final doc = ElectronicInvoiceRpcMapper.documentRetrievalFromRow(sampleDocumentRetrievalJson());
        expectInvoiceDocumentRetrieval(doc);
      });

      test('parse_detailFromRow', () {
        final detail = ElectronicInvoiceRpcMapper.detailFromRow(sampleDetailJson());
        expectElectronicInvoiceDetail(detail);
      });

      test('parse_documentsFromRow', () {
        final docs = ElectronicInvoiceRpcMapper.documentsFromRow(sampleDocumentsJson());
        expectInvoiceDocuments(docs);
      });

      test('parse_sendSheetContextFromRow', () {
        final context = DeliveryRpcMapper.sendSheetContextFromRow(sampleSendSheetContextJson());
        expectSendInvoiceSheetContext(context);
      });

      test('parse_sendInvoiceResultFromRow', () {
        final result = DeliveryRpcMapper.sendInvoiceResultFromRow(sampleSendInvoiceResultJson());
        expectSendInvoiceResult(result);
      });

      test('parse_historyFromRow', () {
        final history = DeliveryRpcMapper.historyFromRow(sampleHistoryJson());
        expectInvoiceDeliveryHistory(history);
      });
    });

    group('readiness_dto via GetIssuanceReadinessQueryHandler', () {
      test('readiness_dto ready', () async {
        final input = EinvoiceRpcMapper.issuanceReadinessInputFromRow(sampleReadinessReadyJson());
        final gateway = _FakeReadinessGateway(input);
        final handler = GetIssuanceReadinessQueryHandler(readinessGateway: gateway);
        final dto = await handler.handle(
          GetIssuanceReadinessQuery(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
          ),
        );
        expectIssuanceReadiness(
          dto,
          expectedLevel: 'ready',
          expectedBlockers: const [],
          expectedWarnings: const [],
        );
      });

      test('readiness_dto missing template', () async {
        final input = EinvoiceRpcMapper.issuanceReadinessInputFromRow(sampleReadinessMissingTemplateJson());
        final gateway = _FakeReadinessGateway(input);
        final handler = GetIssuanceReadinessQueryHandler(readinessGateway: gateway);
        final dto = await handler.handle(
          GetIssuanceReadinessQuery(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
          ),
        );
        expectIssuanceReadiness(
          dto,
          expectedLevel: 'notReady',
          expectedBlockers: ['CONFIG_NOT_READY'],
          expectedWarnings: const [],
        );
      });

      test('readiness_dto org missing tax code', () async {
        final input = EinvoiceRpcMapper.issuanceReadinessInputFromRow(sampleReadinessOrgMissingTaxJson());
        final gateway = _FakeReadinessGateway(input);
        final handler = GetIssuanceReadinessQueryHandler(readinessGateway: gateway);
        final dto = await handler.handle(
          GetIssuanceReadinessQuery(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
          ),
        );
        expectIssuanceReadiness(
          dto,
          expectedLevel: 'notReady',
          expectedBlockers: ['BUYER_TAX_CODE_REQUIRED'],
          expectedWarnings: const [],
        );
      });
    });
  });

  group('new (json)', () {
    test('parse_mapConnectionScreen', () {
      final screen = EInvoiceConfigurationJson.mapConnectionScreen(sampleConnectionScreenJson());
      expectConnectionScreen(screen);
    });

    test('parse_mapConnectionResult', () {
      final result = EInvoiceConfigurationJson.mapConnectionResult(sampleConnectionResultJson());
      expectConnectionResult(result);
    });

    test('parse_mapTemplateList', () {
      final templates = EInvoiceConfigurationJson.mapTemplateList(sampleTemplateListJson());
      expectTemplateList(templates);
    });

    test('parse_mapIssuanceProfile', () {
      final profile = EInvoiceConfigurationJson.mapIssuanceProfile(sampleIssuanceProfileJson());
      expectIssuanceProfile(profile);
    });

    test('parse_mapAutomationPolicy', () {
      final policy = EInvoiceConfigurationJson.mapAutomationPolicy(sampleAutomationPolicyJson());
      expectAutomationPolicy(policy);
    });

    test('parse_mapConfigurationReadiness', () {
      final readiness = EInvoiceConfigurationJson.mapConfigurationReadiness(sampleConfigurationReadinessJson());
      expectConfigurationReadiness(readiness);
    });

    test('parse_orderInvoiceProjectionFromRow', () {
      final projection = EInvoiceIssuanceJson.orderInvoiceProjectionFromRow(sampleOrderInvoiceProjectionJson());
      expectOrderInvoiceProjection(projection);
    });

    test('parse_issuanceAttemptStatusFromRow', () {
      final status = EInvoiceIssuanceJson.issuanceAttemptStatusFromRow(sampleIssuanceAttemptStatusJson());
      expectIssuanceAttemptStatus(status);
    });

    test('parse_invoicePreviewResultFromRow', () {
      final preview = EInvoiceIssuanceJson.invoicePreviewResultFromRow(sampleInvoicePreviewResultJson());
      expectInvoicePreviewResult(preview);
    });

    test('parse_issueInvoiceResultFromRow', () {
      final result = EInvoiceIssuanceJson.issueInvoiceResultFromRow(sampleIssueInvoiceResultJson());
      expectIssueInvoiceResult(result);
    });

    test('parse_officialViewFromRow', () {
      final view = EInvoiceDocumentJson.officialViewFromRow(sampleOfficialViewJson());
      expectOfficialInvoiceView(view);
    });

    test('parse_documentRetrievalFromRow', () {
      final doc = EInvoiceDocumentJson.documentRetrievalFromRow(sampleDocumentRetrievalJson());
      expectInvoiceDocumentRetrieval(doc);
    });

    test('parse_detailFromRow', () {
      final detail = EInvoiceDocumentJson.detailFromRow(sampleDetailJson());
      expectElectronicInvoiceDetail(detail);
    });

    test('parse_documentsFromRow', () {
      final docs = EInvoiceDocumentJson.documentsFromRow(sampleDocumentsJson());
      expectInvoiceDocuments(docs);
    });

    test('parse_sendSheetContextFromRow', () {
      final context = EInvoiceDeliveryJson.sendSheetContextFromRow(sampleSendSheetContextJson());
      expectSendInvoiceSheetContext(context);
    });

    test('parse_sendInvoiceResultFromRow', () {
      final result = EInvoiceDeliveryJson.sendInvoiceResultFromRow(sampleSendInvoiceResultJson());
      expectSendInvoiceResult(result);
    });

    test('parse_historyFromRow', () {
      final history = EInvoiceDeliveryJson.historyFromRow(sampleHistoryJson());
      expectInvoiceDeliveryHistory(history);
    });

    test('delivery_timestamp_is_utc', () {
      final sample = sampleHistoryJson();
      (sample['deliveries'] as List<dynamic>)[0]['startedAt'] = '2026-11-08T10:00:00';
      final history = EInvoiceDeliveryJson.historyFromRow(sample);
      expect(history.deliveries.first.startedAt.isUtc, isTrue);
    });

    test('attempt_status_lowercase_rejected', () {
      final sample = sampleIssuanceAttemptStatusJson();
      sample['status'] = 'pending';
      expect(
        () => EInvoiceIssuanceJson.issuanceAttemptStatusFromRow(sample),
        throwsFormatException,
      );
    });
  });

  group('new (configuration)', () {
    late _RecordingRpc rpc;
    late _RecordingTrigger trigger;
    late EInvoiceConfigurationRepository repository;

    setUp(() {
      rpc = _RecordingRpc();
      trigger = _RecordingTrigger();
      repository = EInvoiceConfigurationRepository(
        rpc: rpc,
        trigger: trigger,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
    });

    test('C1: get_provider_connection_screen', () async {
      rpc.result = [sampleConnectionScreenJson()];
      final res = await repository.getConnectionScreen();
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_provider_connection_screen');
      expect(rpc.calls.single.params, expectedGetConnectionScreenParams);
      expectConnectionScreen(res);
    });

    test('C2: connect_provider', () async {
      rpc.result = [sampleConnectionResultJson()];
      final withVer = await repository.connect(
        username: parityRawUsername,
        password: parityRawPassword,
        expectedConnectionVersion: 3,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'connect_provider');
      expect(rpc.calls.single.params, expectedConnectParamsWithVersion);
      expectConnectionResult(withVer);
      expect(trigger.kicks, [parityTenantId]);

      rpc.calls.clear();
      trigger.kicks.clear();
      rpc.result = [sampleConnectionResultJson()];
      final withoutVer = await repository.connect(
        username: parityRawUsername,
        password: parityRawPassword,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'connect_provider');
      expect(rpc.calls.single.params, expectedConnectParamsWithoutVersion);
      expectConnectionResult(withoutVer);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('C3: reconnect_provider', () async {
      rpc.result = [sampleConnectionResultJson()];
      final withVer = await repository.reconnect(
        connectionId: parityExpectedConnectionId,
        username: parityRawUsername,
        password: parityRawPassword,
        expectedConnectionVersion: 3,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'reconnect_provider');
      expect(rpc.calls.single.params, expectedReconnectParamsWithVersion);
      expectConnectionResult(withVer);
      expect(trigger.kicks, [parityTenantId]);

      rpc.calls.clear();
      trigger.kicks.clear();
      rpc.result = [sampleConnectionResultJson()];
      final withoutVer = await repository.reconnect(
        connectionId: parityExpectedConnectionId,
        username: parityRawUsername,
        password: parityRawPassword,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'reconnect_provider');
      expect(rpc.calls.single.params, expectedReconnectParamsWithoutVersion);
      expectConnectionResult(withoutVer);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('C4: disconnect_provider', () async {
      rpc.result = [sampleConnectionResultJson()];
      final res = await repository.disconnect(
        connectionId: parityExpectedConnectionId,
        confirm: true,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'disconnect_provider');
      expect(rpc.calls.single.params, expectedDisconnectParams);
      expectConnectionResult(res);
      expect(trigger.kicks, isEmpty);
    });

    test('C5: list_provider_templates', () async {
      rpc.result = sampleTemplateListJson();
      final withFilters = await repository.listTemplates(invoiceWithCode: true, year: 2026);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'list_provider_templates');
      expect(rpc.calls.single.params, expectedListTemplatesParamsWithFilters);
      expectTemplateList(withFilters);

      rpc.calls.clear();
      rpc.result = sampleTemplateListJson();
      final withoutFilters = await repository.listTemplates();
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'list_provider_templates');
      expect(rpc.calls.single.params, expectedListTemplatesParamsWithoutFilters);
      expectTemplateList(withoutFilters);
      expect(trigger.kicks, isEmpty);
    });

    test('C6: get_issuance_profile', () async {
      rpc.result = [sampleIssuanceProfileJson()];
      final res = await repository.getIssuanceProfile();
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_issuance_profile');
      expect(rpc.calls.single.params, expectedGetIssuanceProfileParams);
      expectIssuanceProfile(res);
      expect(trigger.kicks, isEmpty);
    });

    test('C7: set_default_issuance_configuration', () async {
      rpc.result = [sampleIssuanceProfileJson()];
      final withVer = await repository.setDefaultConfiguration(
        templateId: parityRawTemplateId,
        signingConfigId: parityRawSigningConfigId,
        expectedProfileVersion: 2,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'set_default_issuance_configuration');
      expect(rpc.calls.single.params, expectedSetDefaultConfigurationParamsWithVersion);
      expectIssuanceProfile(withVer);

      rpc.calls.clear();
      rpc.result = [sampleIssuanceProfileJson()];
      final withoutVer = await repository.setDefaultConfiguration(
        templateId: parityRawTemplateId,
        signingConfigId: parityRawSigningConfigId,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'set_default_issuance_configuration');
      expect(rpc.calls.single.params, expectedSetDefaultConfigurationParamsWithoutVersion);
      expectIssuanceProfile(withoutVer);
      expect(trigger.kicks, isEmpty);
    });

    test('C8: get_automation_policy', () async {
      rpc.result = [sampleAutomationPolicyJson()];
      final res = await repository.getAutomationPolicy();
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_automation_policy');
      expect(rpc.calls.single.params, expectedGetAutomationPolicyParams);
      expectAutomationPolicy(res);
      expect(trigger.kicks, isEmpty);
    });

    test('C9: update_automation_policy', () async {
      rpc.result = [sampleAutomationPolicyJson()];
      final withBoth = await repository.updateAutomationPolicy(
        expectedPolicyVersion: 1,
        autoIssueEnabled: true,
        autoSendEnabled: false,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'update_automation_policy');
      expect(rpc.calls.single.params, expectedUpdateAutomationPolicyParamsWithBoth);
      expectAutomationPolicy(withBoth);

      rpc.calls.clear();
      rpc.result = [sampleAutomationPolicyJson()];
      final autoIssueOnly = await repository.updateAutomationPolicy(
        expectedPolicyVersion: 1,
        autoIssueEnabled: true,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'update_automation_policy');
      expect(rpc.calls.single.params, expectedUpdateAutomationPolicyParamsAutoIssueOnly);
      expectAutomationPolicy(autoIssueOnly);
      expect(trigger.kicks, isEmpty);
    });

    test('C10: get_configuration_readiness', () async {
      rpc.result = [sampleConfigurationReadinessJson()];
      final withPurpose = await repository.getConfigurationReadiness(
        purpose: new_models.IssuancePurpose.manualIssue,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_configuration_readiness');
      expect(rpc.calls.single.params, expectedGetConfigurationReadinessParamsWithPurpose);
      expectConfigurationReadiness(withPurpose);

      rpc.calls.clear();
      rpc.result = [sampleConfigurationReadinessJson()];
      final withoutPurpose = await repository.getConfigurationReadiness();
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_configuration_readiness');
      expect(rpc.calls.single.params, expectedGetConfigurationReadinessParamsWithoutPurpose);
      expectConfigurationReadiness(withoutPurpose);
      expect(trigger.kicks, isEmpty);
    });
  });

  group('new (order)', () {
    late _RecordingRpc rpc;
    late _RecordingTrigger trigger;
    late _FakeSignedUrls signedUrls;
    late EInvoiceRepository repository;

    setUp(() {
      rpc = _RecordingRpc();
      trigger = _RecordingTrigger();
      signedUrls = _FakeSignedUrls();
      repository = EInvoiceRepository(
        rpc: rpc,
        trigger: trigger,
        signedUrls: signedUrls,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
      );
    });

    test('O1: get_order_invoice_projection', () async {
      rpc.result = [sampleOrderInvoiceProjectionJson()];
      final res = await repository.getProjection(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_order_invoice_projection');
      expect(rpc.calls.single.params, expectedGetOrderInvoiceProjectionParams);
      expectOrderInvoiceProjection(res);
      expect(trigger.kicks, isEmpty);
    });

    test('O2: get_issuance_readiness', () async {
      rpc.result = [sampleReadinessReadyJson()];
      final res = await repository.getReadiness(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_issuance_readiness');
      expect(rpc.calls.single.params, expectedGetIssuanceReadinessParams);
      expectIssuanceReadiness(
        res,
        expectedLevel: 'ready',
        expectedBlockers: const [],
        expectedWarnings: const [],
      );
      expect(trigger.kicks, isEmpty);
    });

    test('O3: get_issuance_attempt_status', () async {
      rpc.result = [sampleIssuanceAttemptStatusJson()];
      final res = await repository.getAttemptStatus(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_issuance_attempt_status');
      expect(rpc.calls.single.params, expectedGetIssuanceAttemptStatusParams);
      expectIssuanceAttemptStatus(res);
      expect(trigger.kicks, isEmpty);
    });

    test('O4: request_invoice_preview', () async {
      rpc.onCall = (schema, fn, params) {
        if (fn == 'get_issuance_readiness') return [sampleReadinessReadyJson()];
        if (fn == 'request_invoice_preview') return [sampleInvoicePreviewResultJson()];
        return [];
      };
      final res = await repository.requestPreview(
        salesOrderId: parityOrderId,
        expectedOrderVersion: 5,
      );
      expect(rpc.calls.length, 2);
      expect(rpc.calls[0].schema, 'einvoice');
      expect(rpc.calls[0].fn, 'get_issuance_readiness');
      expect(rpc.calls[0].params, expectedGetIssuanceReadinessParams);
      expect(rpc.calls[1].schema, 'einvoice');
      expect(rpc.calls[1].fn, 'request_invoice_preview');
      expect(rpc.calls[1].params, expectedRequestInvoicePreviewParams);
      expect(res.viewerRef, isNull);
      expect(res.warnings, isEmpty);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O5: get_invoice_preview', () async {
      rpc.result = [sampleInvoicePreviewResultJson()];
      final res = await repository.getPreview(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_invoice_preview');
      expect(rpc.calls.single.params, expectedGetInvoicePreviewParams);
      expectInvoicePreviewResult(res);
      expect(trigger.kicks, isEmpty);
    });

    test('O6: issue_invoice', () async {
      rpc.result = [sampleIssueInvoiceResultJson()];
      final withAck = await repository.issue(
        salesOrderId: parityOrderId,
        sourceVersion: '1',
        idempotencyKey: parityIdempotencyKey,
        acknowledgeWarnings: true,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'issue_invoice');
      expect(rpc.calls.single.params, expectedIssueInvoiceParamsWithAck);
      expectIssueInvoiceResult(withAck);
      expect(trigger.kicks, [parityTenantId]);

      rpc.calls.clear();
      trigger.kicks.clear();
      rpc.result = [sampleIssueInvoiceResultJson()];
      final withoutAck = await repository.issue(
        salesOrderId: parityOrderId,
        sourceVersion: '1',
        idempotencyKey: parityIdempotencyKey,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'issue_invoice');
      expect(rpc.calls.single.params, expectedIssueInvoiceParamsWithoutAck);
      expectIssueInvoiceResult(withoutAck);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O7: retry_issuance', () async {
      rpc.result = [sampleIssueInvoiceResultJson()];
      final res = await repository.retry(
        salesOrderId: parityOrderId,
        expectedOrderVersion: 7,
        idempotencyKey: parityIdempotencyKey,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'retry_issuance');
      expect(rpc.calls.single.params, expectedRetryIssuanceParams);
      expectIssueInvoiceResult(res);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O8: request_official_invoice_view', () async {
      rpc.result = [sampleOfficialViewJson()];
      final res = await repository.requestOfficialView(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'request_official_invoice_view');
      expect(rpc.calls.single.params, expectedRequestOfficialViewParams);
      expectOfficialInvoiceView(res);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O9: get_electronic_invoice_detail', () async {
      rpc.result = [sampleDetailJson()];
      final res = await repository.getDetail(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_electronic_invoice_detail');
      expect(rpc.calls.single.params, expectedGetElectronicInvoiceDetailParams);
      expectElectronicInvoiceDetail(res);
      expect(trigger.kicks, isEmpty);
    });

    test('O10: request_invoice_document', () async {
      rpc.result = [sampleDocumentRetrievalJson()];
      final pdfRes = await repository.requestDocument(
        salesOrderId: parityOrderId,
        documentType: new_models.InvoiceDocumentType.pdf,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'request_invoice_document');
      expect(rpc.calls.single.params, expectedRequestDocumentPdfParams);
      expect(pdfRes.status, new_models.InvoiceDocumentStatus.available);
      expect(pdfRes.downloadUrl, 'https://signed.url/doc');
      expect(trigger.kicks, [parityTenantId]);

      rpc.calls.clear();
      trigger.kicks.clear();
      rpc.result = [sampleDocumentRetrievalJson()];
      final xmlRes = await repository.requestDocument(
        salesOrderId: parityOrderId,
        documentType: new_models.InvoiceDocumentType.xml,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'request_invoice_document');
      expect(rpc.calls.single.params, expectedRequestDocumentXmlParams);
      expect(xmlRes.status, new_models.InvoiceDocumentStatus.available);
      expect(xmlRes.downloadUrl, 'https://signed.url/doc');
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O11: get_invoice_documents', () async {
      rpc.result = [sampleDocumentsJson()];
      final res = await repository.getDocuments(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_invoice_documents');
      expect(rpc.calls.single.params, expectedGetInvoiceDocumentsParams);
      expect(res.pdfAvailable, isTrue);
      expect(res.pdf?.downloadUrl, 'https://signed.url/doc');
      expect(trigger.kicks, isEmpty);
    });

    test('O12: get_send_invoice_sheet_context', () async {
      rpc.result = [sampleSendSheetContextJson()];
      final res = await repository.getSendSheetContext(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_send_invoice_sheet_context');
      expect(rpc.calls.single.params, expectedGetSendSheetContextParams);
      expectSendInvoiceSheetContext(res);
      expect(trigger.kicks, isEmpty);
    });

    test('O13: send_electronic_invoice', () async {
      rpc.result = [sampleSendInvoiceResultJson()];
      final res = await repository.send(
        salesOrderId: parityOrderId,
        recipientEmail: parityRawEmail,
        idempotencyKey: parityIdempotencyKey,
      );
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'send_electronic_invoice');
      expect(rpc.calls.single.params, expectedSendElectronicInvoiceParams);
      expectSendInvoiceResult(res);
      expect(trigger.kicks, [parityTenantId]);
    });

    test('O14: get_invoice_delivery_history', () async {
      rpc.result = [sampleHistoryJson()];
      final res = await repository.getDeliveryHistory(parityOrderId);
      expect(rpc.calls.single.schema, 'einvoice');
      expect(rpc.calls.single.fn, 'get_invoice_delivery_history');
      expect(rpc.calls.single.params, expectedGetInvoiceDeliveryHistoryParams);
      expectInvoiceDeliveryHistory(res);
      expect(trigger.kicks, isEmpty);
    });

    test('readiness_dto parity: new repository matches GetIssuanceReadinessQueryHandler on all 3 sets', () async {
      final samples = [
        sampleReadinessReadyJson(),
        sampleReadinessMissingTemplateJson(),
        sampleReadinessOrgMissingTaxJson(),
      ];

      for (final sample in samples) {
        // old handler
        final oldInput = EinvoiceRpcMapper.issuanceReadinessInputFromRow(sample);
        final oldHandler = GetIssuanceReadinessQueryHandler(
          readinessGateway: _FakeReadinessGateway(oldInput),
        );
        final oldDto = await oldHandler.handle(
          GetIssuanceReadinessQuery(
            tenantId: parityTenantId,
            actorId: parityActorId,
            salesOrderId: parityOrderId,
          ),
        );

        // new repository
        rpc.result = [sample];
        final newDto = await repository.getReadiness(parityOrderId);

        expect(newDto.level.name, oldDto.level.name);
        expect(newDto.buyerCompletionState.name, oldDto.buyerCompletionState.name);
        expect(newDto.blockers.length, oldDto.blockers.length);
        for (var i = 0; i < newDto.blockers.length; i++) {
          expect(newDto.blockers[i].code, oldDto.blockers[i].code);
          expect(newDto.blockers[i].message, oldDto.blockers[i].message);
        }
        expect(newDto.warnings.length, oldDto.warnings.length);
        for (var i = 0; i < newDto.warnings.length; i++) {
          expect(newDto.warnings[i].code, oldDto.warnings[i].code);
          expect(newDto.warnings[i].message, oldDto.warnings[i].message);
        }
      }
    });
  });
}

class _Call {
  _Call(this.schema, this.fn, this.params);
  final String schema;
  final String fn;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_Call>[];
  Object? result;
  Object? Function(String schema, String fn, Map<String, dynamic>? params)? onCall;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add(_Call(schema, fn, params));
    final e = error;
    if (e != null) {
      if (e is PostgrestException) {
        throw AppException.from(e);
      }
      if (e is AppException) throw e;
      throw AppException.from(e);
    }
    if (onCall != null) {
      return onCall!(schema, fn, params);
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    final raw = await call(schema, fn, params: params);
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFunctions implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTrigger extends EInvoiceProcessorTrigger {
  _RecordingTrigger() : super(_DummyFunctions());
  final kicks = <String>[];

  @override
  void kick(String tenantId) {
    kicks.add(tenantId);
  }
}

class _DummyStorageClient implements SupabaseStorageClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSignedUrls extends InvoiceDocumentSignedUrls {
  _FakeSignedUrls() : super(storage: _DummyStorageClient());

  final String? urlToReturn = 'https://signed.url/doc';
  final DateTime? expiresAtToReturn = null;

  @override
  Future<String?> tryCreate(String ref) async => urlToReturn;

  @override
  DateTime leaseExpiresAt({DateTime? now}) =>
      expiresAtToReturn ?? (now ?? DateTime.utc(2026, 11, 8, 12, 5, 0));
}

class _FakeReadinessGateway implements IIssuanceReadinessReadGateway {
  _FakeReadinessGateway(this.input);
  final IssuanceReadinessInput input;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async {
    return input;
  }
}
