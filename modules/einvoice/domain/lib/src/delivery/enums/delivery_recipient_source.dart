/// Where a delivery recipient email was resolved from.
///
/// Declaration order is the fixed resolution priority; `buyerInvoiceSnapshot`
/// is the immutable Theme-05 base snapshot carried in invoice lineage, never
/// the effective buyer data of an issuance attempt.
enum DeliveryRecipientSource {
  currentPartnerProfile,
  buyerInvoiceSnapshot,
  lastSuccessfulPartnerDelivery,
  lastInvoiceDelivery,
  userInput,
}
