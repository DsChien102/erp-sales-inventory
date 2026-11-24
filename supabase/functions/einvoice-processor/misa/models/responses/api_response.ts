import { MeInvoiceJsonHelpers as J } from '../../internal/json_helpers.ts'
import { MeInvoiceCreateInvoiceResultItem } from './create_invoice_result.ts'
import { MeInvoicePublishInvoiceResultItem } from './publish_invoice_result.ts'

function parseItems<T>(raw: unknown, fromJson: (m: Record<string, unknown>) => T): T[] | null {
  const list = J.asList(raw)
  if (list.length === 0) return null
  const out: T[] = []
  for (const item of list) {
    const m = J.asMap(item)
    if (m !== null) out.push(fromJson(m))
  }
  return out
}

/** MISA API response envelope (§1.3 / §1.4). */
export class MeInvoiceApiResponse {
  readonly success: boolean
  readonly errorCode: string | null
  readonly descriptionErrorCode: string | null
  readonly errors: unknown
  readonly data: unknown
  readonly customData: unknown
  readonly createInvoiceResult: MeInvoiceCreateInvoiceResultItem[] | null
  readonly publishInvoiceResult: MeInvoicePublishInvoiceResultItem[] | null

  constructor(init: {
    success: boolean
    errorCode?: string | null
    descriptionErrorCode?: string | null
    errors?: unknown
    data?: unknown
    customData?: unknown
    createInvoiceResult?: MeInvoiceCreateInvoiceResultItem[] | null
    publishInvoiceResult?: MeInvoicePublishInvoiceResultItem[] | null
  }) {
    this.success = init.success
    this.errorCode = init.errorCode ?? null
    this.descriptionErrorCode = init.descriptionErrorCode ?? null
    this.errors = init.errors ?? null
    this.data = init.data ?? null
    this.customData = init.customData ?? null
    this.createInvoiceResult = init.createInvoiceResult ?? null
    this.publishInvoiceResult = init.publishInvoiceResult ?? null
  }

  static fromJson(json: Record<string, unknown>): MeInvoiceApiResponse {
    return new MeInvoiceApiResponse({
      success: J.readSuccess(json) ?? false,
      errorCode: J.readErrorCode(json),
      descriptionErrorCode: J.readString(json, 'descriptionErrorCode'),
      errors: json['Errors'] ?? json['errors'],
      data: json['Data'] ?? json['data'],
      customData: json['CustomData'] ?? json['customData'],
      createInvoiceResult: parseItems(json['createInvoiceResult'], MeInvoiceCreateInvoiceResultItem.fromJson),
      publishInvoiceResult: parseItems(json['publishInvoiceResult'], MeInvoicePublishInvoiceResultItem.fromJson),
    })
  }
}
