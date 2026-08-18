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
    ConnectProviderCommand,
    DisconnectProviderCommand,
    ReconnectProviderCommand,
    RecordConnectionVerifiedCommand,
    SetDefaultIssuanceConfigurationCommand,
    SyncProviderCapabilitiesCommand,
    UpdateAutomationPolicyCommand,
    VerifyProviderConnectionCommand,
  ],
  queryTypes: [
    GetAutomationPolicyQuery,
    GetConfigurationReadinessQuery,
    GetIssuanceProfileQuery,
    GetProviderConnectionScreenQuery,
    ListProviderTemplatesQuery,
  ],
);

