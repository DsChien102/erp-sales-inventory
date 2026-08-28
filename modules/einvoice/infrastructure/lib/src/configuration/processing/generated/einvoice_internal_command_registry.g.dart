// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:quiver/collection.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

InternalCommandSerializer createGeneratedEinvoiceInternalCommandSerializer() {
  final commandTypes = BiMap<String, Type>()
    ..['einvoice.preview_invoice'] = PreviewInvoiceCommand
    ..['einvoice.publish_invoice'] = PublishInvoiceCommand
    ..['einvoice.configuration.record_connection_verified'] = RecordConnectionVerifiedCommand
    ..['einvoice.sync_capabilities'] = SyncProviderCapabilitiesCommand;

  return InternalCommandSerializer(
    mapper: InternalCommandMapper(internalCommandMap: commandTypes),
    deserializers: {
      'einvoice.preview_invoice': PreviewInvoiceCommand.fromJson,
      'einvoice.publish_invoice': PublishInvoiceCommand.fromJson,
      'einvoice.configuration.record_connection_verified': RecordConnectionVerifiedCommand.fromJson,
      'einvoice.sync_capabilities': SyncProviderCapabilitiesCommand.fromJson,
    },
  );
}
