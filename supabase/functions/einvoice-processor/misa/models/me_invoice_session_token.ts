/** Bearer session issued by meInvoice (`/auth/token` or refresh). */
export interface MeInvoiceSessionToken {
  value: string
  expiresAt: Date
}
