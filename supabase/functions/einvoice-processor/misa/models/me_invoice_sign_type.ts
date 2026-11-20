/** HSM signing types supported by Mosaic Retail (§6). */
export const MeInvoiceSignType = {
  /** Ký số qua HSM, có hiển thị CKS. */
  hsmWithCks: { name: 'hsmWithCks', wireValue: 2 },
  /** Ký số sau loại HĐ MTT, không hiển thị CKS. */
  hsmNoCks: { name: 'hsmNoCks', wireValue: 5 },
} as const

export type MeInvoiceSignType = (typeof MeInvoiceSignType)[keyof typeof MeInvoiceSignType]
