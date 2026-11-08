import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { FormatException } from './internal/format_exception.ts'
import { MeInvoiceApiResponse } from './models/responses/api_response.ts'
import { MeInvoiceInvoiceData } from './models/misa/invoice_data.ts'
import { MeInvoiceTemplate } from './models/misa/template.ts'
import { MeInvoicePublishRequest } from './models/requests/invoice_publish_request.ts'
import { MeInvoiceInvoiceQuery } from './models/requests/invoice_query.ts'
import { MeInvoiceSignType } from './models/me_invoice_sign_type.ts'

/** Round-trip tests using MISA curl fixture shapes (§4, §6). */
Deno.test('MeInvoiceInvoiceData round-trip parses and re-emits MISA keys from §4 unpublishview example', () => {
  const json: Record<string, unknown> = {
    RefID: '337f1acd-cac3-45bd-bb78-924b5d018853',
    InvSeries: '1C25MLT',
    InvDate: '2025-11-18',
    CurrencyCode: 'VND',
    ExchangeRate: 1.0,
    PaymentMethodName: 'TM/CK',
    IsInvoiceCalculatingMachine: true,
    BuyerLegalName: 'Cong ty co phan MISA',
    BuyerTaxCode: '0101243150',
    BuyerAddress: 'Ha Noi',
    BuyerCode: 'MS001',
    TotalAmountWithoutVATOC: 5000000.0,
    TotalVATAmountOC: 500000.0,
    TotalDiscountAmountOC: 0,
    TotalAmountOC: 5500000.0,
    TotalAmountInWords: 'Nam trieu nam tram nghin dong.',
    OriginalInvoiceDetail: [{
      ItemType: 1,
      LineNumber: 1,
      ItemCode: 'AOSM01',
      ItemName: 'M2',
      UnitName: 'Chiec',
      Quantity: 10.0,
      UnitPrice: 500000.0,
      DiscountRate: 0,
      DiscountAmountOC: 0,
      AmountOC: 5000000.0,
      AmountWithoutVATOC: 5000000.0,
      VATRateName: '10%',
    }],
    TaxRateInfo: [{ VATRateName: '10%', AmountWithoutVATOC: 5000000.0, VATAmountOC: 500000.0 }],
  }

  const parsed = MeInvoiceInvoiceData.fromJson(json)
  assertEquals(parsed.refId, '337f1acd-cac3-45bd-bb78-924b5d018853')
  assertEquals(parsed.buyerLegalName, 'Cong ty co phan MISA')
  assertEquals(parsed.originalInvoiceDetail?.length, 1)
  assertEquals(parsed.taxRateInfo?.length, 1)

  const wire = parsed.toJson()
  assertEquals(wire['RefID'], json['RefID'])
  assertEquals(wire['BuyerLegalName'], json['BuyerLegalName'])
  assert(Array.isArray(wire['OriginalInvoiceDetail']))
  assertEquals((wire['OriginalInvoiceDetail'] as Record<string, unknown>[])[0]['VATRateName'], '10%')
})

Deno.test('MeInvoiceTemplate round-trip maps §13.1 fields', () => {
  const json = {
    IPTemplateID: 'tpl-1',
    CompanyID: 15388,
    TemplateName: 'GTGT',
    InvTemplateNo: '1',
    InvSeries: '1C25TYY',
    OrgInvSeries: '1KTYY',
    CreatedDate: '2024-01-15',
    Inactive: false,
    IsSendSummary: true,
  }
  const parsed = MeInvoiceTemplate.fromJson(json)
  assertEquals(parsed.ipTemplateId, 'tpl-1')
  assertEquals(parsed.isSendSummary, true)
  const wire = parsed.toJson()
  assertEquals(wire['IPTemplateID'], 'tpl-1')
  assertEquals(wire['IsSendSummary'], true)
})

Deno.test('MeInvoicePublishRequest emits HSM envelope', () => {
  const request = new MeInvoicePublishRequest(MeInvoiceSignType.hsmNoCks, [
    new MeInvoiceInvoiceData({ refId: 'r1', invSeries: '5C25MMB' }),
  ])
  const wire = request.toJson()
  assertEquals(wire['SignType'], 5)
  assertEquals(wire['PublishInvoiceData'], null)
  assert(Array.isArray(wire['InvoiceData']))
})

Deno.test('MeInvoiceInvoiceQuery fromInvSeries derives flags per MISA §1.6', () => {
  const withCode = MeInvoiceInvoiceQuery.fromInvSeries('1C26TYY')
  assertEquals(withCode.invoiceWithCode, true)
  assertEquals(withCode.invoiceCalcu, false)
  const mtt = MeInvoiceInvoiceQuery.fromInvSeries('2C26MYY')
  assertEquals(mtt.invoiceWithCode, true)
  assertEquals(mtt.invoiceCalcu, true)
  const noCode = MeInvoiceInvoiceQuery.fromInvSeries('1K26TYY')
  assertEquals(noCode.invoiceWithCode, false)
})

Deno.test('MeInvoiceInvoiceQuery fromInvSeries throws FormatException for malformed series', () => {
  for (const invSeries of ['', '1C2', '3C26TYY', '1X26TYY', '1C26XYY']) {
    assertThrows(() => MeInvoiceInvoiceQuery.fromInvSeries(invSeries), FormatException, undefined,
      `expected malformed InvSeries: ${invSeries}`)
  }
})

Deno.test('MeInvoiceInvoiceQuery tryFromInvSeries returns null for malformed series', () => {
  assertEquals(MeInvoiceInvoiceQuery.tryFromInvSeries('3C26TYY'), null)
  assertEquals(MeInvoiceInvoiceQuery.tryFromInvSeries('1X26TYY'), null)
  assertEquals(MeInvoiceInvoiceQuery.tryFromInvSeries('1C26XYY'), null)
})

Deno.test('MeInvoiceApiResponse parses publishInvoiceResult envelope', () => {
  const body = JSON.stringify({ success: true, publishInvoiceResult: [{ TransactionID: 'tx-1', InvNo: '0000001' }] })
  const envelope = MeInvoiceApiResponse.fromJson(JSON.parse(body))
  assertEquals(envelope.success, true)
  assertEquals(envelope.publishInvoiceResult?.length, 1)
  assertEquals(envelope.publishInvoiceResult![0].transactionId, 'tx-1')
})
