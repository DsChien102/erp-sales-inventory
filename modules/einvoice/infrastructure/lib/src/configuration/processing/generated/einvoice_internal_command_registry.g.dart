// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:quiver/collection.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

InternalCommandSerializer createGeneratedEinvoiceInternalCommandSerializer() {
  final commandTypes = BiMap<String, Type>()
    ..['einvoice.download_invoice_document'] = DownloadInvoiceDocumentCommand
    ..['einvoice.fetch_official_view'] = FetchOfficialInvoiceViewCommand
    ..['einvoice.poll_issuance_status'] = PollIssuanceStatusCommand
    ..['einvoice.poll_provider_observation'] = PollProviderObservationCommand
    ..['einvoice.preview_invoice'] = PreviewInvoiceCommand
    ..['einvoice.publish_invoice'] = PublishInvoiceCommand
    ..['einvoice.reconcile_invoice_delivery'] = ReconcileInvoiceDeliveryCommand
    ..['einvoice.configuration.record_connection_verified'] =
        RecordConnectionVerifiedCommand
    ..['einvoice.send_invoice_email'] = SendInvoiceEmailCommand
    ..['einvoice.sync_capabilities'] = SyncProviderCapabilitiesCommand;

  return InternalCommandSerializer(
    mapper: InternalCommandMapper(internalCommandMap: commandTypes),
    deserializers: {
      'einvoice.download_invoice_document':
          DownloadInvoiceDocumentCommand.fromJson,
      'einvoice.fetch_official_view': FetchOfficialInvoiceViewCommand.fromJson,
      'einvoice.poll_issuance_status': PollIssuanceStatusCommand.fromJson,
      'einvoice.poll_provider_observation':
          PollProviderObservationCommand.fromJson,
      'einvoice.preview_invoice': PreviewInvoiceCommand.fromJson,
      'einvoice.publish_invoice': PublishInvoiceCommand.fromJson,
      'einvoice.reconcile_invoice_delivery':
          ReconcileInvoiceDeliveryCommand.fromJson,
      'einvoice.configuration.record_connection_verified':
          RecordConnectionVerifiedCommand.fromJson,
      'einvoice.send_invoice_email': SendInvoiceEmailCommand.fromJson,
      'einvoice.sync_capabilities': SyncProviderCapabilitiesCommand.fromJson,
    },
  );
}
