// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final einvoiceAccessMetadataRegistry = AccessMetadataRegistry({
  CompleteBuyerInvoiceDataCommand: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  ConnectProviderCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  DisconnectProviderCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  GetAutomationPolicyQuery: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  GetConfigurationReadinessQuery: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  GetElectronicInvoiceDetailQuery: AccessMetadata(
    permission: 'einvoice.view',
    requiresTenant: true,
  ),
  GetInvoiceDeliveryHistoryQuery: AccessMetadata(
    permission: 'einvoice.send',
    requiresTenant: true,
  ),
  GetInvoiceDocumentsQuery: AccessMetadata(
    permission: 'einvoice.download_document',
    requiresTenant: true,
  ),
  GetInvoicePreviewQuery: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  GetIssuanceAttemptStatusQuery: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  GetIssuanceProfileQuery: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  GetIssuanceReadinessQuery: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  GetLatestProviderObservationQuery: AccessMetadata(
    permission: 'einvoice.view',
    requiresTenant: true,
  ),
  GetOrderInvoiceProjectionQuery: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  GetProviderConnectionScreenQuery: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  GetSendInvoiceSheetContextQuery: AccessMetadata(
    permission: 'einvoice.send',
    requiresTenant: true,
  ),
  IssueInvoiceCommand: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  ListProviderTemplatesQuery: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  OpenReconciliationCaseCommand: AccessMetadata(requiresTenant: true),
  ReconnectProviderCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  RecordDeliveryResultCommand: AccessMetadata(requiresTenant: true),
  RecordIssuanceResultCommand: AccessMetadata(requiresTenant: true),
  RecordProviderObservationCommand: AccessMetadata(requiresTenant: true),
  RecoverInternalFinalizationCommand: AccessMetadata(requiresTenant: true),
  ReevaluateAutoIssuanceCommand: AccessMetadata(requiresTenant: true),
  RequestInvoiceDocumentCommand: AccessMetadata(
    permission: 'einvoice.download_document',
    requiresTenant: true,
  ),
  RequestInvoicePreviewCommand: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  RequestOfficialInvoiceViewCommand: AccessMetadata(
    permission: 'einvoice.view',
    requiresTenant: true,
  ),
  ResolveReconciliationCaseCommand: AccessMetadata(requiresTenant: true),
  RetryIssuanceCommand: AccessMetadata(
    permission: 'einvoice.issue',
    requiresTenant: true,
  ),
  SendElectronicInvoiceCommand: AccessMetadata(
    permission: 'einvoice.send',
    requiresTenant: true,
  ),
  SetDefaultIssuanceConfigurationCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  StartAutoDeliveryCommand: AccessMetadata(requiresTenant: true),
  StartAutoIssuanceCommand: AccessMetadata(requiresTenant: true),
  UpdateAutomationPolicyCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
  VerifyProviderConnectionCommand: AccessMetadata(
    permission: 'einvoice.manage_configuration',
    requiresTenant: true,
  ),
});
