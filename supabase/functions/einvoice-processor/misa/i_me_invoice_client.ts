import type { MeInvoiceResult } from './models/me_invoice_result.ts'
import type { MeInvoiceSessionToken } from './models/me_invoice_session_token.ts'
import type { MeInvoiceInvoiceData } from './models/misa/invoice_data.ts'
import type { MeInvoiceInvoiceStatus } from './models/misa/invoice_status.ts'
import type { MeInvoiceTemplate } from './models/misa/template.ts'
import type { MeInvoiceTicket } from './models/misa/ticket.ts'
import type { MeInvoicePublishRequest } from './models/requests/invoice_publish_request.ts'
import type {
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceQuery,
  MeInvoiceStatusInputType,
} from './models/requests/invoice_query.ts'
import type { MeInvoiceSendEmailRequest } from './models/requests/send_email_request.ts'
import type { MeInvoiceInvoiceDataPublished } from './models/responses/invoice_data_published.ts'
import type { MeInvoicePublishInvoiceResultItem } from './models/responses/publish_invoice_result.ts'
import type { MeInvoiceSendEmailResponse } from './models/responses/send_email_result.ts'

/** Blackbox HTTP port for MISA meInvoice outbound (phát hành HĐĐT). */
export interface IMeInvoiceClient {
  obtainAccessToken(opts?: { forceLogin?: boolean }): Promise<MeInvoiceResult<MeInvoiceSessionToken>>
  listInvoiceTemplates(opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTemplate[]>>
  listTicketTemplates(opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTicket[]>>
  previewUnpublished(invoice: MeInvoiceInvoiceData): Promise<MeInvoiceResult<string>>
  publish(request: MeInvoicePublishRequest): Promise<MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>>
  previewPublished(opts: {
    transactionIds: string[]
    companyTaxCode: string
    query?: MeInvoiceInvoiceQuery | null
  }): Promise<MeInvoiceResult<string>>
  download(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    downloadDataType: MeInvoiceDownloadDataType
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>>
  getStatus(opts: {
    ids: string[]
    inputType: MeInvoiceStatusInputType
    query: MeInvoiceInvoiceQuery
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceStatus[]>>
  sendEmail(request: MeInvoiceSendEmailRequest): Promise<MeInvoiceResult<MeInvoiceSendEmailResponse>>
  convertToPaper(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    converter: string
    convertDate: string
  }): Promise<MeInvoiceResult<string>>
}
