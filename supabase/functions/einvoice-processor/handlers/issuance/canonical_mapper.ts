import {
  MeInvoiceInvoiceData,
  MeInvoicePublishRequest,
  MeInvoiceSignType,
} from '../../misa/mod.ts'
import { classifyInvoiceSeries } from '../template_ref.ts'
import { CanonicalValidationFault } from './errors.ts'

const REQUIRED_STRING_FIELDS = ['invSeries', 'invDate'] as const
const BUYER_NAME_FIELDS = ['buyerFullName', 'buyerLegalName'] as const

const OPTION_USER_DEFINED = {
  MainCurrency: 'VND',
  QuantityDecimalDigits: '0',
  UnitPriceOCDecimalDigits: '0',
  UnitPriceDecimalDigits: '0',
  AmountOCDecimalDigits: '0',
  AmountDecimalDigits: '0',
  CoefficientDecimalDigits: '2',
  ExchangRateDecimalDigits: '0',
}

function readAmount(value: unknown): number | null {
  if (typeof value === 'number' && !Number.isNaN(value)) {
    return value
  }
  return null
}

function readLineItems(raw: unknown): Array<Record<string, unknown>> {
  if (!Array.isArray(raw)) return []
  return raw.filter((item): item is Record<string, unknown> => typeof item === 'object' && item !== null)
}

function validateLine(line: Record<string, unknown>, index: number): void {
  const itemName = line['itemName']
  if (typeof itemName !== 'string' || itemName.trim().length === 0) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_LINE_ITEM_NAME',
      `Line ${index} itemName is required`,
    )
  }

  const quantity = readAmount(line['quantity'])
  if (quantity == null || quantity <= 0) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_LINE_QUANTITY',
      `Line ${index} quantity must be positive`,
    )
  }

  const hasUnitPrice = readAmount(line['unitPrice']) != null
  const hasAmount = readAmount(line['amount'] ?? line['amountOc']) != null
  if (!hasUnitPrice && !hasAmount) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_LINE_AMOUNT',
      `Line ${index} must include unitPrice or amount`,
    )
  }
}

/** Validates provider-neutral canonical schema before publish or preview dispatch. */
export function validateCanonical(canonicalInvoice: Record<string, unknown>): void {
  for (const field of REQUIRED_STRING_FIELDS) {
    const value = canonicalInvoice[field]
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new CanonicalValidationFault(
        `CANONICAL_MISSING_${field}`,
        `Missing or blank canonical field: ${field}`,
      )
    }
  }

  const hasBuyerName = BUYER_NAME_FIELDS.some((field) => {
    const value = canonicalInvoice[field]
    return typeof value === 'string' && value.trim().length > 0
  })
  if (!hasBuyerName) {
    throw new CanonicalValidationFault(
      'CANONICAL_MISSING_BUYER_NAME',
      'Canonical must carry buyerFullName (person) or buyerLegalName (organization)',
    )
  }

  const signType = canonicalInvoice['signType']
  if (signType == null) {
    throw new CanonicalValidationFault(
      'CANONICAL_MISSING_SIGN_TYPE',
      'Canonical signType is required (2=HSM, 5=MTT)',
    )
  }
  if (
    typeof signType !== 'number' ||
    (signType !== MeInvoiceSignType.hsmWithCks.wireValue && signType !== MeInvoiceSignType.hsmNoCks.wireValue)
  ) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_SIGN_TYPE',
      'Invalid canonical signType wire value',
    )
  }

  const invSeries = (canonicalInvoice['invSeries'] as string).trim()
  const classification = classifyInvoiceSeries(invSeries)
  if (classification == null) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_INV_SERIES',
      'Canonical invSeries is malformed',
    )
  }
  if (classification.isMtt && signType !== 5) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_SIGN_TYPE',
      'MTT InvSeries requires SignType=5',
    )
  }
  if (!classification.isMtt && signType !== 2) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_SIGN_TYPE',
      'Non-MTT InvSeries requires SignType=2',
    )
  }

  const totalAmount = readAmount(canonicalInvoice['totalAmount'] ?? canonicalInvoice['totalAmountOc'])
  if (totalAmount == null || totalAmount <= 0) {
    throw new CanonicalValidationFault(
      'CANONICAL_INVALID_TOTAL_AMOUNT',
      'Canonical total amount must be positive',
    )
  }

  const lines = readLineItems(canonicalInvoice['originalInvoiceDetail'])
  if (lines.length === 0) {
    throw new CanonicalValidationFault(
      'CANONICAL_MISSING_LINES',
      'Canonical originalInvoiceDetail must contain line items',
    )
  }
  for (let i = 0; i < lines.length; i++) {
    validateLine(lines[i], i)
  }

  const taxRates = readLineItems(canonicalInvoice['taxRateInfo'])
  if (taxRates.length === 0) {
    throw new CanonicalValidationFault(
      'CANONICAL_MISSING_TAX_RATES',
      'Canonical taxRateInfo must contain at least one entry',
    )
  }
}

export function resolveSignType(canonical: Record<string, unknown>): MeInvoiceSignType {
  const raw = canonical['signType']
  if (typeof raw !== 'number') {
    throw new CanonicalValidationFault(
      'CANONICAL_MISSING_SIGN_TYPE',
      'Canonical signType is required before publish',
    )
  }
  if (raw === MeInvoiceSignType.hsmWithCks.wireValue) {
    return MeInvoiceSignType.hsmWithCks
  }
  if (raw === MeInvoiceSignType.hsmNoCks.wireValue) {
    return MeInvoiceSignType.hsmNoCks
  }
  throw new CanonicalValidationFault(
    'CANONICAL_INVALID_SIGN_TYPE',
    'Unsupported canonical signType wire value',
  )
}

function mirrorAmount(map: Record<string, unknown>, from: string, to: string): void {
  if (readAmount(map[to]) != null) {
    return
  }
  const value = readAmount(map[from])
  if (value != null) {
    map[to] = value
  }
}

function normalizeBuyerTaxCode(input: Record<string, unknown>): void {
  const raw = input['buyerTaxCode']
  if (typeof raw !== 'string') return
  const compact = raw.replace(/\s+/g, '')
  input['buyerTaxCode'] = /^[0-9]{13}$/.test(compact)
    ? `${compact.slice(0, 10)}-${compact.slice(10)}`
    : compact
}

function normalizeLine(line: Record<string, unknown>): Record<string, unknown> {
  mirrorAmount(line, 'amount', 'amountOc')
  mirrorAmount(line, 'amountWithoutVat', 'amountWithoutVatOc')
  mirrorAmount(line, 'vatAmount', 'vatAmountOc')
  mirrorAmount(line, 'discountAmount', 'discountAmountOc')

  if (readAmount(line['amountWithoutVat']) == null && readAmount(line['amountWithoutVatOc']) == null) {
    const amount = readAmount(line['amount'] ?? line['amountOc'])
    if (amount != null) {
      line['amountWithoutVat'] = amount
      line['amountWithoutVatOc'] = amount
    }
  }

  const vatRateName = line['vatRateName']
  if (typeof vatRateName !== 'string' || vatRateName.trim().length === 0) {
    const vatRate = line['vatRate']
    if (typeof vatRate === 'number') {
      line['vatRateName'] = `${String(vatRate).replace(/\.0$/, '')}%`
    }
  }

  if (line['itemType'] === undefined) {
    line['itemType'] = 1
  }
  if (line['sortOrder'] == null && line['lineNumber'] != null) {
    line['sortOrder'] = line['lineNumber']
  }

  if (line['discountRate'] == null) {
    const gross = readAmount(line['amountOc'] ?? line['amount'])
    const discount = readAmount(line['discountAmountOc'] ?? line['discountAmount'])
    line['discountRate'] =
      gross != null && gross > 0 && discount != null && discount > 0
        ? Math.round((discount * 10000) / gross) / 100
        : 0
  }
  if (readAmount(line['discountAmountOc']) == null && readAmount(line['discountAmount']) == null) {
    line['discountAmountOc'] = 0
    line['discountAmount'] = 0
  }
  delete line['vatRate']
  return line
}

function normalizeTaxRate(rate: Record<string, unknown>): Record<string, unknown> {
  mirrorAmount(rate, 'vatAmount', 'vatAmountOc')
  if (readAmount(rate['amountWithoutVatOc']) == null) {
    const turnover = readAmount(rate['turnover'])
    if (turnover != null) {
      rate['amountWithoutVatOc'] = turnover
    }
  }
  const vatRateName = rate['vatRateName']
  if (typeof vatRateName !== 'string' || vatRateName.trim().length === 0) {
    const vatRate = rate['vatRate']
    if (typeof vatRate === 'number') {
      rate['vatRateName'] = `${String(vatRate).replace(/\.0$/, '')}%`
    }
  }
  delete rate['vatRate']
  delete rate['turnover']
  return rate
}

function normalizeCanonicalAmounts(input: Record<string, unknown>): Record<string, unknown> {
  mirrorAmount(input, 'totalAmount', 'totalAmountOc')
  mirrorAmount(input, 'totalSaleAmount', 'totalSaleAmountOc')
  mirrorAmount(input, 'totalAmountWithoutVat', 'totalAmountWithoutVatOc')
  mirrorAmount(input, 'totalVatAmount', 'totalVatAmountOc')
  mirrorAmount(input, 'totalDiscountAmount', 'totalDiscountAmountOc')

  if (readAmount(input['totalDiscountAmount']) == null && readAmount(input['totalDiscountAmountOc']) == null) {
    input['totalDiscountAmount'] = 0
    input['totalDiscountAmountOc'] = 0
  }

  const words = input['totalAmountInWords']
  if (typeof words !== 'string' || words.trim().length === 0) {
    const total = readAmount(input['totalAmountOc'] ?? input['totalAmount'])
    if (total != null) {
      input['totalAmountInWords'] = vndAmountInWords(Math.round(total))
    }
  }

  const lines = input['originalInvoiceDetail']
  if (Array.isArray(lines)) {
    input['originalInvoiceDetail'] = lines.map((line) =>
      typeof line === 'object' && line !== null ? normalizeLine({ ...(line as Record<string, unknown>) }) : line
    )
  }

  const taxRates = input['taxRateInfo']
  if (Array.isArray(taxRates)) {
    input['taxRateInfo'] = taxRates.map((rate) =>
      typeof rate === 'object' && rate !== null ? normalizeTaxRate({ ...(rate as Record<string, unknown>) }) : rate
    )
  }

  return input
}

const PASCAL_CASE_OVERRIDES: Record<string, string> = {
  vatRateName: 'VATRateName',
  vatRate: 'VATRate',
  vatAmount: 'VATAmount',
  vatAmountOc: 'VATAmountOC',
  totalSaleAmount: 'TotalSaleAmount',
  totalSaleAmountOc: 'TotalSaleAmountOC',
  totalVatAmount: 'TotalVATAmount',
  totalVatAmountOc: 'TotalVATAmountOC',
  totalAmount: 'TotalAmount',
  totalAmountOc: 'TotalAmountOC',
  totalDiscountAmount: 'TotalDiscountAmount',
  totalDiscountAmountOc: 'TotalDiscountAmountOC',
  totalAmountWithoutVat: 'TotalAmountWithoutVAT',
  totalAmountWithoutVatOc: 'TotalAmountWithoutVATOC',
  amountWithoutVat: 'AmountWithoutVAT',
  amountWithoutVatOc: 'AmountWithoutVATOC',
  amountOc: 'AmountOC',
  discountAmountOc: 'DiscountAmountOC',
  refId: 'RefID',
  buyerIdNumber: 'BuyerIDNumber',
}

function toPascalCaseKey(key: string): string {
  if (key.length === 0) return key
  return PASCAL_CASE_OVERRIDES[key] ?? (key[0].toUpperCase() + key.slice(1))
}

function convertValue(value: unknown): unknown {
  if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
    const converted = convertKeys(value as Record<string, unknown>)
    if ('VATAmount' in converted && !('VATAmountOC' in converted)) {
      converted['VATAmountOC'] = converted['VATAmount']
    }
    if ('Turnover' in converted && !('AmountWithoutVATOC' in converted)) {
      converted['AmountWithoutVATOC'] = converted['Turnover']
    }
    return converted
  }
  if (Array.isArray(value)) {
    return value.map(convertValue)
  }
  return value
}

function convertKeys(input: Record<string, unknown>): Record<string, unknown> {
  const output: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(input)) {
    const newKey = toPascalCaseKey(key)
    output[newKey] = convertValue(value)
  }
  return output
}

function toWireJsonBody(canonicalInvoice: Record<string, unknown>): Record<string, unknown> {
  const normalized = normalizeCanonicalAmounts(structuredClone(canonicalInvoice))
  normalizeBuyerTaxCode(normalized)
  const wire = convertKeys(normalized)
  wire['OptionUserDefined'] = OPTION_USER_DEFINED
  return wire
}

function toWireJson(canonicalInvoice: Record<string, unknown>, idempotencyKey: string): Record<string, unknown> {
  const wire = toWireJsonBody(canonicalInvoice)
  wire['RefID'] = idempotencyKey
  return wire
}

/** Builds a MISA preview invoice data object from provider-neutral canonical schema. */
export function toPreviewInvoice(canonicalInvoice: Record<string, unknown>): MeInvoiceInvoiceData {
  validateCanonical(canonicalInvoice)
  const wireJson = toWireJsonBody(canonicalInvoice)
  return MeInvoiceInvoiceData.fromJson(wireJson)
}

/** Builds a MISA publish request with idempotencyKey as correlation RefID. */
export function toPublishRequest(options: {
  canonicalInvoice: Record<string, unknown>
  idempotencyKey: string
}): MeInvoicePublishRequest {
  validateCanonical(options.canonicalInvoice)
  const wireJson = toWireJson(options.canonicalInvoice, options.idempotencyKey)
  const invoice = MeInvoiceInvoiceData.fromJson(wireJson)
  const signType = resolveSignType(options.canonicalInvoice)
  return new MeInvoicePublishRequest(signType, [invoice])
}

/** Minimal VND amount-in-words for positive integers (MISA TotalAmountInWords). */
export function vndAmountInWords(amount: number): string {
  if (amount < 0) {
    throw new RangeError(`must be non-negative: ${amount}`)
  }
  if (amount === 0) {
    return 'Không đồng'
  }

  const digits = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín']

  function threeDigits(n: number, full: boolean): string {
    const tram = Math.floor(n / 100)
    const chuc = Math.floor((n % 100) / 10)
    const donvi = n % 10
    const parts: string[] = []

    if (tram > 0 || full) {
      if (tram > 0) {
        parts.push(`${digits[tram]} trăm`)
      } else if (full && (chuc > 0 || donvi > 0)) {
        parts.push('không trăm')
      }
    }

    if (chuc > 1) {
      parts.push(`${digits[chuc]} mươi`)
      if (donvi === 1) {
        parts.push('mốt')
      } else if (donvi === 5) {
        parts.push('lăm')
      } else if (donvi > 0) {
        parts.push(digits[donvi])
      }
    } else if (chuc === 1) {
      parts.push('mười')
      if (donvi === 1) {
        parts.push('một')
      } else if (donvi === 5) {
        parts.push('lăm')
      } else if (donvi > 0) {
        parts.push(digits[donvi])
      }
    } else if (donvi > 0) {
      if (full || tram > 0) {
        parts.push(`lẻ ${digits[donvi]}`)
      } else {
        parts.push(digits[donvi])
      }
    }

    return parts.join(' ')
  }

  const ty = Math.floor(amount / 1000000000)
  const trieu = Math.floor((amount % 1000000000) / 1000000)
  const nghin = Math.floor((amount % 1000000) / 1000)
  const donvi = amount % 1000

  const parts: string[] = []
  if (ty > 0) {
    parts.push(`${threeDigits(ty, false)} tỷ`)
  }
  if (trieu > 0) {
    parts.push(`${threeDigits(trieu, ty > 0)} triệu`)
  }
  if (nghin > 0) {
    parts.push(`${threeDigits(nghin, ty > 0 || trieu > 0)} nghìn`)
  }
  if (donvi > 0) {
    parts.push(threeDigits(donvi, ty > 0 || trieu > 0 || nghin > 0))
  }

  const words = parts.join(' ').trim()
  const capitalized = words.length === 0 ? 'Không' : `${words[0].toUpperCase()}${words.slice(1)}`
  return `${capitalized} đồng`
}

