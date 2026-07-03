// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:quiver/collection.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

InternalCommandSerializer createGeneratedPartnerInternalCommandSerializer() {
  final commandTypes = BiMap<String, Type>()
    ..['partner.record_transaction_history'] = RecordPartnerTransactionHistoryCommand;

  return InternalCommandSerializer(
    mapper: InternalCommandMapper(internalCommandMap: commandTypes),
    deserializers: {
      'partner.record_transaction_history': RecordPartnerTransactionHistoryCommand.fromJson,
    },
  );
}
