import { assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { CanonicalValidationFault } from './errors.ts'
import {
  toPreviewInvoice,
  toPublishRequest,
  validateCanonical,
  vndAmountInWords,
} from './canonical_mapper.ts'
import { MeInvoiceSignType } from '../../misa/mod.ts'

function baseCanonical(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    invSeries: '1C26TAA',
    signType: 2,
    invDate: '2026-09-03',
    buyerLegalName: 'Công ty Test',
    buyerAddress: 'Hà Nội',
    totalAmount: 100000,
    totalSaleAmount: 100000,
    totalAmountWithoutVat: 100000,
    totalVatAmount: 0,
    originalInvoiceDetail: [
      {
        lineNumber: 1,
        itemName: 'SP',
        quantity: 1,
        unitPrice: 100000,
        amount: 100000,
      },
    ],
    taxRateInfo: [
      { vatRateName: 'KCT', turnover: 100000, vatAmount: 0 },
    ],
    ...overrides,
  }
}

// 8 tests from me_invoice_canonical_mapper_test.dart
Deno.test('MeInvoiceCanonicalMapper toPublishRequest encodes sample canonical', () => {
  const request = toPublishRequest({
    canonicalInvoice: {
      invSeries: '1C25TYY',
      signType: 2,
      invDate: '2026-08-01',
      buyerLegalName: 'ABC',
      buyerAddress: 'HN',
      totalAmount: 110000,
      originalInvoiceDetail: [
        { itemName: 'Svc', quantity: 1, unitPrice: 100000 },
      ],
      taxRateInfo: [
        { vatRateName: '10%' },
      ],
    },
    idempotencyKey: 'attempt-key-42',
  })

  assertEquals(request.invoiceData[0].refId, 'attempt-key-42')
  assertEquals(request.toJson()['InvoiceData'] != null, true)
})

Deno.test('MeInvoiceCanonicalMapper toPublishRequest sends OptionUserDefined decimal digits', () => {
  const request = toPublishRequest({
    canonicalInvoice: {
      invSeries: '2C26MMH',
      signType: 5,
      invDate: '2026-08-01',
      buyerFullName: 'Anh A',
      totalAmount: 100000,
      originalInvoiceDetail: [
        { itemName: 'Svc', quantity: 1, unitPrice: 100000 },
      ],
      taxRateInfo: [
        { vatRateName: 'KCT' },
      ],
    },
    idempotencyKey: 'attempt-key-43',
  })

  const invoice = (request.toJson()['InvoiceData'] as Array<Record<string, unknown>>)[0]
  assertEquals(invoice['OptionUserDefined'], {
    MainCurrency: 'VND',
    QuantityDecimalDigits: '0',
    UnitPriceOCDecimalDigits: '0',
    UnitPriceDecimalDigits: '0',
    AmountOCDecimalDigits: '0',
    AmountDecimalDigits: '0',
    CoefficientDecimalDigits: '2',
    ExchangRateDecimalDigits: '0',
  })
})

function wireLine(line: Record<string, unknown>): Record<string, unknown> {
  const request = toPublishRequest({
    canonicalInvoice: {
      invSeries: '2C26MMH',
      signType: 5,
      invDate: '2026-08-01',
      buyerFullName: 'Anh A',
      totalAmount: 100000,
      originalInvoiceDetail: [line],
      taxRateInfo: [{ vatRateName: 'KCT' }],
    },
    idempotencyKey: 'attempt-key-rate',
  })
  const invoice = (request.toJson()['InvoiceData'] as Array<Record<string, unknown>>)[0]
  return (invoice['OriginalInvoiceDetail'] as Array<Record<string, unknown>>)[0]
}

Deno.test('MeInvoiceCanonicalMapper DiscountRate is 0 without discount', () => {
  const line = wireLine({ itemName: 'A', quantity: 2, unitPrice: 85000, amount: 170000 })
  assertEquals(line['DiscountRate'], 0)
})

Deno.test('MeInvoiceCanonicalMapper DiscountRate is derived from discount / amount with 2 decimals', () => {
  const percent = wireLine({
    itemName: 'A',
    quantity: 2,
    unitPrice: 85000,
    amount: 170000,
    discountAmount: 25500,
    amountWithoutVat: 144500,
  })
  assertEquals(percent['DiscountRate'], 15.0)

  const amount = wireLine({
    itemName: 'A',
    quantity: 1,
    unitPrice: 85000,
    amount: 85000,
    discountAmount: 10000,
    amountWithoutVat: 75000,
  })
  assertEquals(amount['DiscountRate'], 11.76)
})

function wireTaxCode(taxCode: unknown): string | null {
  const request = toPublishRequest({
    canonicalInvoice: {
      invSeries: '2C26MYY',
      signType: 5,
      invDate: '2026-09-30',
      buyerLegalName: 'Mắt Môi Tay Chân',
      buyerAddress: 'Xã Hát Môn',
      buyerTaxCode: taxCode,
      totalAmount: 100000,
      originalInvoiceDetail: [
        { itemName: 'Svc', quantity: 1, unitPrice: 100000 },
      ],
      taxRateInfo: [{ vatRateName: 'KCT' }],
    },
    idempotencyKey: 'attempt-key-tax',
  })
  return request.invoiceData[0].buyerTaxCode
}

Deno.test('MeInvoiceCanonicalMapper BuyerTaxCode: 13 contiguous digits are sent as 10-3', () => {
  assertEquals(wireTaxCode('6868686868773'), '6868686868-773')
})

Deno.test('MeInvoiceCanonicalMapper BuyerTaxCode: whitespace is stripped before formatting', () => {
  assertEquals(wireTaxCode(' 6868686868 773 '), '6868686868-773')
})

Deno.test('MeInvoiceCanonicalMapper BuyerTaxCode: 10 digits, 12 digits and 10-3 are sent unchanged', () => {
  assertEquals(wireTaxCode('0101234567'), '0101234567')
  assertEquals(wireTaxCode('001099012345'), '001099012345')
  assertEquals(wireTaxCode('0101234567-001'), '0101234567-001')
})

Deno.test('MeInvoiceCanonicalMapper BuyerTaxCode: missing tax code stays absent', () => {
  assertEquals(wireTaxCode(null), null)
})

// 6 tests from me_invoice_canonical_mapper_preview_test.dart
const validCanonical = {
  invSeries: '1C26TAA',
  signType: 2,
  invDate: '2026-09-03',
  buyerLegalName: 'Nguyễn Văn Kiểm Thử',
  buyerAddress: 'Số 123 Đường Kiểm Thử, TP. Hồ Chí Minh',
  totalAmount: 1100000,
  totalSaleAmount: 1000000,
  totalAmountWithoutVat: 1000000,
  totalVatAmount: 100000,
  originalInvoiceDetail: [
    {
      lineNumber: 1,
      itemCode: 'SP-01',
      itemName: 'Dịch vụ kiểm thử',
      unitName: 'Lần',
      quantity: 1,
      unitPrice: 1000000,
      amount: 1000000,
      vatRate: 10,
      vatAmount: 100000,
    },
  ],
  taxRateInfo: [
    {
      vatRateName: '10%',
      vatRate: 10,
      turnover: 1000000,
      vatAmount: 100000,
    },
  ],
}

Deno.test('MeInvoiceCanonicalMapper preview mapping maps lowerCamel canonical payload to PascalCase MeInvoiceInvoiceData for preview', () => {
  const invoice = toPreviewInvoice(validCanonical)

  assertEquals(invoice.invSeries, '1C26TAA')
  assertEquals(invoice.invDate, '2026-09-03')
  assertEquals(invoice.buyerLegalName, 'Nguyễn Văn Kiểm Thử')
  assertEquals(invoice.buyerAddress, 'Số 123 Đường Kiểm Thử, TP. Hồ Chí Minh')
  assertEquals(invoice.totalAmount, 1100000)
  assertEquals(invoice.originalInvoiceDetail != null, true)
  assertEquals(invoice.originalInvoiceDetail!.length, 1)
  assertEquals(invoice.originalInvoiceDetail![0].itemName, 'Dịch vụ kiểm thử')
  assertEquals(invoice.originalInvoiceDetail![0].quantity, 1)
  assertEquals(invoice.originalInvoiceDetail![0].unitPrice, 1000000)
  assertEquals(invoice.taxRateInfo != null, true)
  assertEquals(invoice.taxRateInfo!.length, 1)
  assertEquals(invoice.taxRateInfo![0].vatRateName, '10%')
})

Deno.test('MeInvoiceCanonicalMapper preview mapping mirrors *Oc / AmountOC fields for seed-shaped VND payloads', () => {
  const invoice = toPreviewInvoice(validCanonical)
  const wire = invoice.toJson()

  assertEquals(wire['TotalAmountOC'], 1100000)
  assertEquals(wire['TotalAmount'], 1100000)
  assertEquals(wire['TotalSaleAmountOC'], 1000000)
  assertEquals(wire['TotalAmountWithoutVATOC'], 1000000)
  assertEquals(wire['TotalVATAmountOC'], 100000)
  assertEquals(wire['TotalDiscountAmountOC'], 0)
  assertEquals(typeof wire['TotalAmountInWords'], 'string')
  assertEquals((wire['TotalAmountInWords'] as string).toLowerCase().includes('đồng'), true)

  const line = (wire['OriginalInvoiceDetail'] as Array<Record<string, unknown>>)[0]
  assertEquals(line['AmountOC'], 1000000)
  assertEquals(line['AmountWithoutVATOC'], 1000000)
  assertEquals(line['VATAmountOC'], 100000)
  assertEquals(line['VATRateName'], '10%')
  assertEquals('VATRate' in line, false)
  assertEquals(line['ItemType'], 1)
  assertEquals(line['DiscountRate'], 0)
  assertEquals(line['DiscountAmountOC'], 0)

  const tax = (wire['TaxRateInfo'] as Array<Record<string, unknown>>)[0]
  assertEquals(tax['AmountWithoutVATOC'], 1000000)
  assertEquals(tax['VATAmountOC'], 100000)
  assertEquals(tax['VATRateName'], '10%')
  assertEquals('VATRate' in tax, false)
  assertEquals('Turnover' in tax, false)
})

Deno.test('MeInvoiceCanonicalMapper preview mapping vndAmountInWords covers acceptance fixture total', () => {
  assertEquals(vndAmountInWords(1100000), 'Một triệu một trăm nghìn đồng')
})

Deno.test('MeInvoiceCanonicalMapper preview mapping throws CanonicalValidationFault when invSeries is missing', () => {
  const invalid = { ...validCanonical }
  delete (invalid as Record<string, unknown>).invSeries
  assertThrows(() => toPreviewInvoice(invalid), CanonicalValidationFault)
})

Deno.test('MeInvoiceCanonicalMapper preview mapping throws CanonicalValidationFault when totalAmount is non-positive or missing', () => {
  const invalid = { ...validCanonical, totalAmount: 0 }
  assertThrows(() => toPreviewInvoice(invalid), CanonicalValidationFault)
})

Deno.test('MeInvoiceCanonicalMapper preview mapping throws CanonicalValidationFault when originalInvoiceDetail is empty', () => {
  const invalid = { ...validCanonical, originalInvoiceDetail: [] }
  assertThrows(() => toPreviewInvoice(invalid), CanonicalValidationFault)
})

// 5 tests from th08_hardening_resolve_sign_type_test.dart
Deno.test('th08_hardening_resolve — SignType fail-closed missing signType is rejected', () => {
  const canonical = baseCanonical()
  delete canonical.signType
  const err = assertThrows(() => validateCanonical(canonical), CanonicalValidationFault)
  assertEquals((err as CanonicalValidationFault).reasonCode, 'CANONICAL_MISSING_SIGN_TYPE')
})

Deno.test('th08_hardening_resolve — SignType fail-closed MTT series with SignType 2 is rejected', () => {
  const canonical = baseCanonical({ signType: 2, invSeries: '2C26MYY' })
  const err = assertThrows(() => validateCanonical(canonical), CanonicalValidationFault)
  assertEquals((err as CanonicalValidationFault).reasonCode, 'CANONICAL_INVALID_SIGN_TYPE')
})

Deno.test('th08_hardening_resolve — SignType fail-closed non-MTT series with SignType 5 is rejected', () => {
  const canonical = baseCanonical({ signType: 5, invSeries: '1C26TAA' })
  const err = assertThrows(() => validateCanonical(canonical), CanonicalValidationFault)
  assertEquals((err as CanonicalValidationFault).reasonCode, 'CANONICAL_INVALID_SIGN_TYPE')
})

Deno.test('th08_hardening_resolve — SignType fail-closed publish uses resolved SignType 2 without fallback', () => {
  const request = toPublishRequest({
    canonicalInvoice: baseCanonical({ signType: 2 }),
    idempotencyKey: 'ref-1',
  })
  assertEquals(request.signType, MeInvoiceSignType.hsmWithCks)
  assertEquals(request.toJson()['SignType'], 2)
})

Deno.test('th08_hardening_resolve — SignType fail-closed publish uses SignType 5 for MTT', () => {
  const request = toPublishRequest({
    canonicalInvoice: baseCanonical({ signType: 5, invSeries: '2C26MYY' }),
    idempotencyKey: 'ref-2',
  })
  assertEquals(request.signType, MeInvoiceSignType.hsmNoCks)
  assertEquals(request.toJson()['SignType'], 5)
})

