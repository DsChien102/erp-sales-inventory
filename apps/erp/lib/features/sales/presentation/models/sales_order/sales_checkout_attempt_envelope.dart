import 'package:equatable/equatable.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';

final class SalesCheckoutAttemptEnvelope extends Equatable {
  const SalesCheckoutAttemptEnvelope({
    required this.request,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final SalesFinalizeRequest request;
  final String canonicalPayloadJson;
  final String payloadHash;

  @override
  List<Object?> get props => [request.commandId, canonicalPayloadJson, payloadHash];
}
