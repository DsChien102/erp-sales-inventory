/** Commands with their own (smaller) attempt budget; others use retry_or_dead_letter_internal_command. */
export const MAX_ATTEMPTS_BY_COMMAND_TYPE: Readonly<Record<string, number>> = {
  'einvoice.fetch_official_view': 2,
  'einvoice.download_invoice_document': 3,
  'einvoice.send_invoice_email': 3,
  'einvoice.reconcile_invoice_delivery': 3,
}

export function maxAttemptsFor(commandType: string): number | undefined {
  return Object.hasOwn(MAX_ATTEMPTS_BY_COMMAND_TYPE, commandType)
    ? MAX_ATTEMPTS_BY_COMMAND_TYPE[commandType]
    : undefined
}
