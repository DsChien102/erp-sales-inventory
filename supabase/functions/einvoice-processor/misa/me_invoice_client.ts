import type { IMeInvoiceClient } from './i_me_invoice_client.ts'
import { MeInvoiceApiResponseParser } from './internal/api_response_parser.ts'
import { MeInvoiceAuth, MeInvoiceAuthException, MeInvoiceAuthToken } from './internal/me_invoice_auth.ts'
import { MeInvoiceHttp } from './internal/me_invoice_http.ts'
import type { FetchLike } from './internal/timeout.ts'
import { MeInvoiceViewUrlPolicy } from './me_invoice_view_url_policy.ts'
import {
  DEFAULT_REQUEST_TIMEOUT_MS,
  hasCredentials,
  type MeInvoiceConfig,
  missingCredentialError,
  RECOMMENDED_TOKEN_TTL_MS,
} from './models/me_invoice_config.ts'
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
import { encodeTransactionIdsBody } from './models/requests/transaction_ids_body.ts'
import type { MeInvoiceApiResponse } from './models/responses/api_response.ts'
import { MeInvoiceInvoiceDataPublished } from './models/responses/invoice_data_published.ts'
import type { MeInvoicePublishInvoiceResultItem } from './models/responses/publish_invoice_result.ts'
import { MeInvoiceSendEmailResponse, MeInvoiceSendEmailResultItem } from './models/responses/send_email_result.ts'

function dataTypeName(v: unknown): string {
  if (v === null || v === undefined) return 'Null'
  if (typeof v === 'string') return 'String'
  if (Array.isArray(v)) return 'List'
  if (typeof v === 'object') return 'Map'
  return typeof v
}

/** Real MISA meInvoice HTTP client. Missing credentials soft-fail (no network). */
export class MeInvoiceClient implements IMeInvoiceClient {
  static readonly maxTransactionIdsPerCall = 50

  readonly #config: MeInvoiceConfig
  #auth: MeInvoiceAuth | null = null
  #api: MeInvoiceHttp | null = null

  constructor(config: MeInvoiceConfig, fetchFn: FetchLike = (...a) => fetch(...a)) {
    this.#config = config
    if (hasCredentials(config)) {
      let initial: MeInvoiceAuthToken | null = null
      const bearer = config.accessToken?.trim()
      if (bearer) {
        initial = new MeInvoiceAuthToken(
          bearer,
          config.accessTokenExpiresAt ?? new Date(Date.now() + RECOMMENDED_TOKEN_TTL_MS),
        )
      }
      const timeout = config.requestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS
      this.#auth = new MeInvoiceAuth({
        baseUrl: config.baseUrl,
        appId: config.appId,
        taxCode: config.taxCode,
        username: config.username,
        password: config.password,
        fetchFn,
        initialToken: initial,
        defaultTtlMs: RECOMMENDED_TOKEN_TTL_MS,
        requestTimeoutMs: timeout,
      })
      this.#api = new MeInvoiceHttp({ auth: this.#auth, fetchFn, requestTimeoutMs: timeout })
    }
  }

  /** Login or return cached Bearer. Prefer rare calls; MISA may block IPs that hit /auth/token per invoice. */
  async obtainAccessToken(opts: { forceLogin?: boolean } = {}): Promise<MeInvoiceResult<MeInvoiceSessionToken>> {
    const gate = this.#guard<MeInvoiceSessionToken>()
    if (gate) return gate
    try {
      const token = await this.#auth!.getToken({ forceRefresh: opts.forceLogin ?? false })
      return MeInvoiceResult.ok({ value: token.value, expiresAt: token.expiresAt })
    } catch (e) {
      if (e instanceof MeInvoiceAuthException) return MeInvoiceResult.failed(e.message)
      throw e
    }
  }

  listInvoiceTemplates(opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTemplate[]>> {
    return this.#listTemplates(opts.invoiceWithCode, false, opts.year ?? null, MeInvoiceTemplate.fromJson)
  }

  listTicketTemplates(opts: { invoiceWithCode: boolean; year?: number | null }): Promise<MeInvoiceResult<MeInvoiceTicket[]>> {
    return this.#listTemplates(opts.invoiceWithCode, true, opts.year ?? null, MeInvoiceTicket.fromJson)
  }

  async #listTemplates<T>(
    invoiceWithCode: boolean,
    ticket: boolean,
    year: number | null,
    fromJson: (json: Record<string, unknown>) => T,
  ): Promise<MeInvoiceResult<T[]>> {
    const gate = this.#guard<T[]>()
    if (gate) return gate
    const query: Record<string, string> = {
      invoiceWithCode: String(invoiceWithCode),
      ticket: String(ticket),
    }
    if (year !== null) query['year'] = `${year}`
    const raw = await this.#api!.get('/invoice/templates', { query })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    return MeInvoiceResult.ok(MeInvoiceApiResponseParser.parseDataList(raw.data!.data, fromJson))
  }

  async previewUnpublished(invoice: MeInvoiceInvoiceData): Promise<MeInvoiceResult<string>> {
    const gate = this.#guard<string>()
    if (gate) return gate
    const raw = await this.#api!.postJson('/invoice/unpublishview', { body: invoice.toJson() })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    return this.#viewerUrl(raw.data!)
  }

  async publish(request: MeInvoicePublishRequest): Promise<MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>> {
    const gate = this.#guard<MeInvoicePublishInvoiceResultItem[]>()
    if (gate) return gate
    const raw = await this.#api!.postJson('/invoice', { body: request.toJson() })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    const items = raw.data!.publishInvoiceResult
    if (items === null || items.length === 0) {
      return MeInvoiceResult.failed('meinvoice_publish_empty_or_invalid_result')
    }
    return MeInvoiceResult.ok(items)
  }

  async previewPublished(opts: {
    transactionIds: string[]
    companyTaxCode: string
    query?: MeInvoiceInvoiceQuery | null
  }): Promise<MeInvoiceResult<string>> {
    const gate = this.#guard<string>()
    if (gate) return gate
    const idError = this.#validateTransactionIds(opts.transactionIds)
    if (idError !== null) return MeInvoiceResult.failed(idError)
    const raw = await this.#api!.postRaw('/invoice/publishview', {
      body: encodeTransactionIdsBody(opts.transactionIds),
      // Same classification flags as status/download: without `invoiceCalcu`
      // MISA resolves MTT invoices against the regular store.
      query: opts.query?.toQueryParameters() ?? null,
      extraHeaders: { CompanyTaxCode: opts.companyTaxCode },
    })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    return this.#viewerUrl(raw.data!)
  }

  #viewerUrl(envelope: MeInvoiceApiResponse): MeInvoiceResult<string> {
    const link = MeInvoiceApiResponseParser.parseDataString(envelope.data)
    if (link === null) {
      const data = envelope.data
      if (data !== null && typeof data !== 'string') {
        return MeInvoiceResult.failed('meinvoice_preview_invalid_data')
      }
      return MeInvoiceResult.failed('meinvoice_preview_empty_data')
    }
    const viewerUrl = MeInvoiceViewUrlPolicy.tryParse(link)
    if (viewerUrl === null) return MeInvoiceResult.failed('meinvoice_preview_invalid_url')
    return MeInvoiceResult.ok(viewerUrl)
  }

  async download(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    downloadDataType: MeInvoiceDownloadDataType
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceDataPublished[]>> {
    const gate = this.#guard<MeInvoiceInvoiceDataPublished[]>()
    if (gate) return gate
    const idError = this.#validateTransactionIds(opts.transactionIds)
    if (idError !== null) return MeInvoiceResult.failed(idError)
    const raw = await this.#api!.postRaw('/invoice/download', {
      body: encodeTransactionIdsBody(opts.transactionIds),
      query: opts.query.toQueryParameters({ downloadDataType: opts.downloadDataType }),
    })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    const items = MeInvoiceApiResponseParser.parseDataList(raw.data!.data, MeInvoiceInvoiceDataPublished.fromJson)
    if (items.length === 0) {
      return MeInvoiceResult.failed(`meinvoice_download_empty_data: ${MeInvoiceClient.#envelopeSummary(raw.data!)}`)
    }
    return MeInvoiceResult.ok(items)
  }

  /** Short provider envelope summary for diagnostics (no document bytes, no credentials). */
  static #envelopeSummary(response: MeInvoiceApiResponse): string {
    const clip = (value: unknown): string => {
      const text = `${value ?? ''}`.trim()
      return text.length <= 200 ? text : `${text.substring(0, 200)}…`
    }
    return `success=${response.success}` +
      ` errorCode=${clip(response.errorCode)}` +
      ` description=${clip(response.descriptionErrorCode)}` +
      ` errors=${clip(response.errors)}` +
      ` dataType=${dataTypeName(response.data)}`
  }

  async getStatus(opts: {
    ids: string[]
    inputType: MeInvoiceStatusInputType
    query: MeInvoiceInvoiceQuery
  }): Promise<MeInvoiceResult<MeInvoiceInvoiceStatus[]>> {
    const gate = this.#guard<MeInvoiceInvoiceStatus[]>()
    if (gate) return gate
    const idError = this.#validateTransactionIds(opts.ids)
    if (idError !== null) return MeInvoiceResult.failed(idError)
    const raw = await this.#api!.postRaw('/invoice/status', {
      body: encodeTransactionIdsBody(opts.ids),
      query: opts.query.toQueryParameters({ inputType: opts.inputType }),
    })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    const items = MeInvoiceApiResponseParser.parseDataList(raw.data!.data, MeInvoiceInvoiceStatus.fromJson)
    if (items.length === 0) return MeInvoiceResult.failed('meinvoice_status_empty_data')
    return MeInvoiceResult.ok(items)
  }

  async sendEmail(request: MeInvoiceSendEmailRequest): Promise<MeInvoiceResult<MeInvoiceSendEmailResponse>> {
    const gate = this.#guard<MeInvoiceSendEmailResponse>()
    if (gate) return gate
    const raw = await this.#api!.postJson('/invoice/sendemail', { body: request.toJson() })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    const invalid = () => MeInvoiceResult.failed<MeInvoiceSendEmailResponse>('meinvoice_send_email_invalid_response')
    try {
      const envelope = raw.data!
      const errors = envelope.errors
      const isEmptyObj = typeof errors === 'object' && errors !== null && !Array.isArray(errors) &&
        Object.keys(errors).length === 0
      if (
        errors !== null && errors !== '' && !(Array.isArray(errors) && errors.length === 0) && !isEmptyObj
      ) {
        return invalid()
      }
      const payload = envelope.data
      if (typeof payload === 'string' && payload.trim() === '') {
        return MeInvoiceResult.ok(MeInvoiceSendEmailResponse.envelopeAcknowledgement())
      }
      const decoded = typeof payload === 'string' ? JSON.parse(payload) : payload
      if (
        !Array.isArray(decoded) || decoded.length === 0 ||
        decoded.some((item) => typeof item !== 'object' || item === null || Array.isArray(item))
      ) {
        return invalid()
      }
      return MeInvoiceResult.ok(
        MeInvoiceSendEmailResponse.itemized(
          decoded.map((item) => MeInvoiceSendEmailResultItem.fromJson({ ...(item as Record<string, unknown>) })),
        ),
      )
    } catch {
      return invalid()
    }
  }

  async convertToPaper(opts: {
    transactionIds: string[]
    query: MeInvoiceInvoiceQuery
    converter: string
    convertDate: string
  }): Promise<MeInvoiceResult<string>> {
    const gate = this.#guard<string>()
    if (gate) return gate
    const idError = this.#validateTransactionIds(opts.transactionIds)
    if (idError !== null) return MeInvoiceResult.failed(idError)
    const raw = await this.#api!.postRaw('/invoice/voucher-paper', {
      body: encodeTransactionIdsBody(opts.transactionIds),
      query: opts.query.toQueryParameters({ converter: opts.converter, convertDate: opts.convertDate }),
    })
    if (!raw.isSuccess) return MeInvoiceResult.failed(raw.error!, { rateLimited: raw.rateLimited })
    const data = MeInvoiceApiResponseParser.parseDataString(raw.data!.data)
    if (data === null || data === '') return MeInvoiceResult.failed('meinvoice_voucher_paper_empty_data')
    return MeInvoiceResult.ok(data)
  }

  #validateTransactionIds(ids: string[]): string | null {
    if (ids.length === 0) return 'meinvoice_empty_transaction_ids'
    if (ids.length > MeInvoiceClient.maxTransactionIdsPerCall) return 'meinvoice_too_many_transaction_ids'
    return null
  }

  #guard<T>(): MeInvoiceResult<T> | null {
    const missing = missingCredentialError(this.#config)
    return missing !== null ? MeInvoiceResult.failed<T>(missing) : null
  }
}
