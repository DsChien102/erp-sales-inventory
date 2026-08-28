// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final einvoiceModuleManifest = GeneratedModuleManifest(
  name: 'einvoice',
  permissions: [
    'einvoice.download_document',
    'einvoice.issue',
    'einvoice.manage_configuration',
    'einvoice.send',
    'einvoice.view',
  ],
  commandTypes: [
    CompleteBuyerInvoiceDataCommand,
    ConnectProviderCommand,
    DisconnectProviderCommand,
    IssueInvoiceCommand,
    PreviewInvoiceCommand,
    PublishInvoiceCommand,
    ReconnectProviderCommand,
    RecordConnectionVerifiedCommand,
    RequestInvoicePreviewCommand,
    SetDefaultIssuanceConfigurationCommand,
    SyncProviderCapabilitiesCommand,
    UpdateAutomationPolicyCommand,
    VerifyProviderConnectionCommand,
  ],
  queryTypes: [
    GetAutomationPolicyQuery,
    GetConfigurationReadinessQuery,
    GetInvoicePreviewQuery,
    GetIssuanceProfileQuery,
    GetIssuanceReadinessQuery,
    GetOrderInvoiceProjectionQuery,
    GetProviderConnectionScreenQuery,
    ListProviderTemplatesQuery,
  ],
);

