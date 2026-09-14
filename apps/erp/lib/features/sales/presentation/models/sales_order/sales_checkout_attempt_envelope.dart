import 'package:equatable/equatable.dart';
import 'package:vet45_sales_application/application.dart';

final class SalesCheckoutAttemptEnvelope extends Equatable {
  const SalesCheckoutAttemptEnvelope({
    required this.command,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final FinalizeSalesOrderCommand command;
  final String canonicalPayloadJson;
  final String payloadHash;

  @override
  List<Object?> get props => [command.id, canonicalPayloadJson, payloadHash];
}
