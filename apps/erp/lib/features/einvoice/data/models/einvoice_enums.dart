/// Actor identity class recorded on a business delivery.
enum DeliveryActorType {
  system,
  user,
}

/// Theme 05 delivery display projection.
enum DeliveryDisplayState {
  notSent,
  sending,
  sent,
  failed,
  unknown,
}

/// Business delivery intent kind.
enum DeliveryKind {
  initial,
  resend,
}

/// Where a delivery recipient email was resolved from.
enum DeliveryRecipientSource {
  currentPartnerProfile,
  buyerInvoiceSnapshot,
  lastSuccessfulPartnerDelivery,
  lastInvoiceDelivery,
  userInput,
}

/// Invoice delivery aggregate status.
enum DeliveryStatus {
  processing,
  succeeded,
  failed,
  unknown,
}

/// What started a business delivery.
enum DeliveryTriggerType {
  automatic,
  manual,
}

/// Document retrieval status.
enum InvoiceDocumentStatus {
  pending,
  available,
  failed,
  checkRequired,
}

/// Official invoice document type.
enum InvoiceDocumentType {
  pdf,
  xml,
}

/// Buyer classification for invoice content (SRS §buyer data).
enum BuyerType {
  retail,
  individual,
  organization,
}

/// Buyer invoice data completion state.
enum BuyerCompletionStatus {
  open,
  locked,
}

/// Local finalization after provider success.
enum InternalFinalizationStatus {
  pending,
  completed,
  unresolved,
}

/// Issuance attempt lifecycle.
enum IssuanceAttemptStatus {
  preparing,
  submitted,
  waitingResult,
  reconciling,
  succeeded,
  failed,
}

/// Theme 05 issuance display projection.
enum IssuanceDisplayState {
  notIssued,
  processing,
  issued,
  failed,
}

/// Per-order issuance readiness.
enum IssuanceReadinessLevel {
  notReady,
  readyWithWarnings,
  ready,
}

/// Invoice signing method.
enum SigningMethod {
  hsm,
  mtt,
  noSign,
}

/// Tenant provider connection lifecycle.
enum ProviderConnectionStatus {
  disconnected,
  connected,
  checkRequired,
  reconnectRequired,
}

/// Configuration readiness read model.
enum ConfigurationReadinessLevel {
  notReady,
  readyWithWarnings,
  ready,
}

/// Purpose filter for configuration readiness.
enum IssuancePurpose {
  manualIssue,
  autoIssue,
  autoSend,
}

/// Send sheet mode.
enum SendInvoiceSheetMode {
  send,
  resend,
}

/// Actions exposed on Theme 05 order invoice projection row.
enum OrderInvoiceAction {
  preview,
  issue,
  retryIssue,
  view,
  downloadPdf,
  downloadXml,
  send,
  resend,
}

