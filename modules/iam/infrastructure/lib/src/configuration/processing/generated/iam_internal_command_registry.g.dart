// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:quiver/collection.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

InternalCommandSerializer createGeneratedIamInternalCommandSerializer() {
  final commandTypes = BiMap<String, Type>()
    ..['iam.notification.send_email_delivery'] = SendEmailDeliveryCommand;

  return InternalCommandSerializer(
    mapper: InternalCommandMapper(internalCommandMap: commandTypes),
    deserializers: {
      'iam.notification.send_email_delivery': SendEmailDeliveryCommand.fromJson,
    },
  );
}
