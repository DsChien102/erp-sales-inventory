import type { MeInvoiceSignType } from '../me_invoice_sign_type.ts'
import type { MeInvoiceInvoiceData } from '../misa/invoice_data.ts'

/** POST `/invoice` body for HSM publish (§6). */
export class MeInvoicePublishRequest {
  constructor(readonly signType: MeInvoiceSignType, readonly invoiceData: MeInvoiceInvoiceData[]) {}

  toJson(): Record<string, unknown> {
    return {
      SignType: this.signType.wireValue,
      InvoiceData: this.invoiceData.map((e) => e.toJson()),
      PublishInvoiceData: null,
    }
  }
}
