import type { IMeInvoiceClient } from './i_me_invoice_client.ts'
import { MeInvoiceResult } from './models/me_invoice_result.ts'
import type { MeInvoiceSessionToken } from './models/me_invoice_session_token.ts'
import type { MeInvoiceInvoiceData } from './models/misa/invoice_data.ts'
import { MeInvoiceInvoiceStatus } from './models/misa/invoice_status.ts'
import { MeInvoiceTemplate } from './models/misa/template.ts'
import { MeInvoiceTicket } from './models/misa/ticket.ts'
import type { MeInvoicePublishRequest } from './models/requests/invoice_publish_request.ts'
import type {
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceQuery,
  MeInvoiceStatusInputType,
} from './models/requests/invoice_query.ts'
import type { MeInvoiceSendEmailRequest } from './models/requests/send_email_request.ts'
import { MeInvoiceInvoiceDataPublished } from './models/responses/invoice_data_published.ts'
import { MeInvoicePublishInvoiceResultItem } from './models/responses/publish_invoice_result.ts'
import { MeInvoiceSendEmailResponse, MeInvoiceSendEmailResultItem } from './models/responses/send_email_result.ts'

/** Test scenarios for FakeMeInvoiceClient. */
export const FakeMeInvoiceScenario = {
  ok: 'ok',
  failed: 'failed',
  rateLimited: 'rateLimited',
  missingCredentials: 'missingCredentials',
  tokenExpiredThenOk: 'tokenExpiredThenOk',
} as const
export type FakeMeInvoiceScenario = (typeof FakeMeInvoiceScenario)[keyof typeof FakeMeInvoiceScenario]

/** Test double for IMeInvoiceClient — no network. */
export class FakeMeInvoiceClient implements IMeInvoiceClient {
  scenario: FakeMeInvoiceScenario
  readonly #getStatusQueue: MeInvoiceResult<MeInvoiceInvoiceStatus[]>[]

  constructor(opts: { scenario?: FakeMeInvoiceScenario; getStatusQueue?: MeInvoiceResult<MeInvoiceInvoiceStatus[]>[] } = {}) {
    this.scenario = opts.scenario ?? FakeMeInvoiceScenario.ok
    this.#getStatusQueue = [...(opts.getStatusQueue ?? [])]
  }

  listInvoiceTemplatesCount = 0
  listTicketTemplatesCount = 0
  previewUnpublishedCount = 0
  publishCount = 0
  previewPublishedCount = 0
  getStatusCount = 0
  downloadCount = 0
  sendEmailCount = 0
  convertToPaperCount = 0
  obtainAccessTokenCount = 0

  lastPublishRequest: MeInvoicePublishRequest | null = null
  lastPreviewInvoice: MeInvoiceInvoiceData | null = null
  lastTransactionIds: string[] | null = null
  lastCompanyTaxCode: string | null = null
  lastPreviewPublishedQuery: MeInvoiceInvoiceQuery | null = null
  lastDownloadQuery: MeInvoiceInvoiceQuery | null = null
  lastDownloadDataType: MeInvoiceDownloadDataType | null = null
  lastStatusInputType: MeInvoiceStatusInputType | null = null
  lastStatusQuery: MeInvoiceInvoiceQuery | null = null
  lastSendEmailRequest: MeInvoiceSendEmailRequest | null = null
  lastListInvoiceWithCode: boolean[] = []

  readonly #previewPublishedQueue: MeInvoiceResult<string>[] = []
  readonly #downloadQueue: MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>[] = []
  readonly #sendEmailQueue: MeInvoiceResult<MeInvoiceSendEmailResponse>[] = []
  #tokenExpiredHits = 0

  /** Enqueue a scripted FIFO result for subsequent getStatus calls. */
  enqueueGetStatusResult(result: MeInvoiceResult<MeInvoiceInvoiceStatus[]>): void {
    this.#getStatusQueue.push(result)
  }

  enqueuePreviewPublishedResult(result: MeInvoiceResult<string>): void {
    this.#previewPublishedQueue.push(result)
  }

  enqueueDownloadResult(result: MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>): void {
    this.#downloadQueue.push(result)
  }

  /** Enqueue a scripted FIFO result for subsequent sendEmail calls. */
  enqueueSendEmailResult(result: MeInvoiceResult<MeInvoiceSendEmailResponse>): void {
    this.#sendEmailQueue.push(result)
  }

  /** Enqueue official Product envelope acknowledgement (`data=""`). */
  enqueueSendEmailEnvelopeAcknowledgement(): void {
    this.enqueueSendEmailResult(MeInvoiceResult.ok(MeInvoiceSendEmailResponse.envelopeAcknowledgement()))
  }

  obtainAccessToken(_opts: { forceLogin?: boolean } = {}): Promise<MeInvoiceResult<MeInvoiceSessionToken>> {
    this.obtainAccessTokenCount++
    const early = this.#scenarioResult<MeInvoiceSessionToken>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok({ value: 'fake-token', expiresAt: new Date(Date.UTC(2099, 0, 1)) }))
  }

  listInvoiceTemplates(opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTemplate[]>> {
    this.listInvoiceTemplatesCount++
    this.lastListInvoiceWithCode.push(opts.invoiceWithCode)
    const early = this.#scenarioResult<MeInvoiceTemplate[]>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok([
      new MeInvoiceTemplate({
        ipTemplateId: 'tpl-fake-1',
        companyId: 1,
        templateName: 'Hoa don GTGT',
        invTemplateNo: '1',
        invSeries: '1C25TYY',
        orgInvSeries: '1C25TYY',
      }),
    ]))
  }

  listTicketTemplates(_opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTicket[]>> {
    this.listTicketTemplatesCount++
    const early = this.#scenarioResult<MeInvoiceTicket[]>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok([
      new MeInvoiceTicket({ ticketTemplateId: 'ticket-fake-1', templateName: 'Ve dien tu', invSeries: '5C25MMB' }),
    ]))
  }

  previewUnpublished(invoice: MeInvoiceInvoiceData): Promise<MeInvoiceResult<string>> {
    this.previewUnpublishedCount++
    this.lastPreviewInvoice = invoice
    const early = this.#scenarioResult<string>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok('https://meinvoice.vn/viewer/preview/unpublished'))
  }

  publish(request: MeInvoicePublishRequest): Promise<MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>> {
    this.publishCount++
    this.lastPublishRequest = request
    const early = this.#scenarioResult<MeInvoicePublishInvoiceResultItem[]>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: request.invoiceData[0]?.refId,
        transactionId: `tx-fake-${this.publishCount}`,
        invSeries: request.invoiceData[0]?.invSeries,
        invNo: '0000001',
      }),
    ]))
  }

  previewPublished(opts: {
    transactionIds: string[]
    companyTaxCode: string
    query?: MeInvoiceInvoiceQuery | null
  }): Promise<MeInvoiceResult<string>> {
    this.previewPublishedCount++
    this.lastTransactionIds = [...opts.transactionIds]
    this.lastCompanyTaxCode = opts.companyTaxCode
    this.lastPreviewPublishedQuery = opts.query ?? null
    const queued = this.#previewPublishedQueue.shift()
    if (queued) return Promise.resolve(queued)
    const early = this.#scenarioResult<string>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok('https://meinvoice.vn/viewer/preview/published'))
  }

  download(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    downloadDataType: MeInvoiceDownloadDataType
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>> {
    this.downloadCount++
    this.lastTransactionIds = [...opts.transactionIds]
    this.lastDownloadQuery = opts.query
    this.lastDownloadDataType = opts.downloadDataType
    const queued = this.#downloadQueue.shift()
    if (queued) return Promise.resolve(queued)
    const early = this.#scenarioResult<MeInvoiceInvoiceDataPublished[]>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok(
      opts.transactionIds.map((id) =>
        new MeInvoiceInvoiceDataPublished(id, 'JVBERi0xLjQ=', new TextEncoder().encode('%PDF-1.4 fake'))
      ),
    ))
  }

  getStatus(opts: {
    ids: string[]
    inputType: MeInvoiceStatusInputType
    query: MeInvoiceInvoiceQuery
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceStatus[]>> {
    this.getStatusCount++
    this.lastTransactionIds = [...opts.ids]
    this.lastStatusInputType = opts.inputType
    this.lastStatusQuery = opts.query
    const queued = this.#getStatusQueue.shift()
    if (queued) return Promise.resolve(queued)
    const early = this.#scenarioResult<MeInvoiceInvoiceStatus[]>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok(
      opts.ids.map((id) => new MeInvoiceInvoiceStatus({ transactionId: id, publishStatus: 1, invNo: '0000001' })),
    ))
  }

  sendEmail(request: MeInvoiceSendEmailRequest): Promise<MeInvoiceResult<MeInvoiceSendEmailResponse>> {
    this.sendEmailCount++
    this.lastSendEmailRequest = request
    const queued = this.#sendEmailQueue.shift()
    if (queued) return Promise.resolve(queued)
    const early = this.#scenarioResult<MeInvoiceSendEmailResponse>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok(
      MeInvoiceSendEmailResponse.itemized(
        request.sendEmailDatas.map((item) => new MeInvoiceSendEmailResultItem(item.transactionId, null, null, 3)),
      ),
    ))
  }

  convertToPaper(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    converter: string
    convertDate: string
  }): Promise<MeInvoiceResult<string>> {
    this.convertToPaperCount++
    this.lastTransactionIds = [...opts.transactionIds]
    const early = this.#scenarioResult<string>()
    if (early) return Promise.resolve(early)
    return Promise.resolve(MeInvoiceResult.ok('ZmFrZQ=='))
  }

  #scenarioResult<T>(): MeInvoiceResult<T> | null {
    switch (this.scenario) {
      case 'ok':
        return null
      case 'failed':
        return MeInvoiceResult.failed<T>('meinvoice_5xx')
      case 'rateLimited':
        return MeInvoiceResult.failed<T>('meinvoice_429_rate_limited', { rateLimited: true })
      case 'missingCredentials':
        return MeInvoiceResult.failed<T>('missing_MISA_MEINVOICE_APP_ID')
      case 'tokenExpiredThenOk':
        this.#tokenExpiredHits++
        if (this.#tokenExpiredHits === 1) return MeInvoiceResult.failed<T>('TokenExpiredCode')
        return null
    }
  }
}
