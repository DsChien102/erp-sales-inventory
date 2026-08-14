import '../me_invoice_sign_type.dart';
import '../misa/invoice_data.dart';

/// POST `/invoice` body for HSM publish (§6).
final class MeInvoicePublishRequest {
  const MeInvoicePublishRequest({
    required this.signType,
    required this.invoiceData,
  });

  final MeInvoiceSignType signType;
  final List<MeInvoiceInvoiceData> invoiceData;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'SignType': signType.wireValue,
    'InvoiceData': invoiceData.map((e) => e.toJson()).toList(),
    'PublishInvoiceData': null,
  };
}
