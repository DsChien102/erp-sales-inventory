import { assertEquals } from 'jsr:@std/assert@1'
import { classifyInvoiceSeries, mergeAndDedupe, tryCreateTemplateRef } from './template_ref.ts'

Deno.test('th08_hardening_capability — InvoiceSeriesClassification classifies có mã, không mã và MTT from InvSeries', () => {
  assertEquals(classifyInvoiceSeries('1C26TYY'), { invoiceWithCode: true, isMtt: false })
  assertEquals(classifyInvoiceSeries('1K26TYY'), { invoiceWithCode: false, isMtt: false })
  assertEquals(classifyInvoiceSeries('2C26MYY'), { invoiceWithCode: true, isMtt: true })
})

Deno.test('th08_hardening_capability — InvoiceSeriesClassification rejects malformed InvSeries at each classified position', () => {
  for (const invSeries of ['', '1C2', '3C26TYY', '1X26TYY', '1C26XYY']) {
    assertEquals(classifyInvoiceSeries(invSeries), null, `expected malformed InvSeries: ${invSeries}`)
  }
})

Deno.test('th08_hardening_capability — ProviderTemplateRef create derives invoiceWithCode/isMtt and keeps isSendSummary', () => {
  const ref = tryCreateTemplateRef({
    templateId: 'tpl-mtt',
    name: 'MTT',
    invoiceSeries: '2C26MYY',
    isSendSummary: true,
    serial: '1',
  })!
  assertEquals(ref.invoiceSeries, '2C26MYY')
  assertEquals(ref.invoiceWithCode, true)
  assertEquals(ref.isMtt, true)
  assertEquals(ref.isSendSummary, true)
})

Deno.test('th08_hardening_capability — ProviderTemplateRef create returns null on malformed InvSeries', () => {
  assertEquals(tryCreateTemplateRef({ templateId: 'bad', name: 'Bad', invoiceSeries: 'BAD', isSendSummary: false }), null)
})

Deno.test('th08_hardening_capability — ProviderTemplateRef mergeAndDedupe keeps both code modes and drops duplicate series', () => {
  const mk = (templateId: string, name: string, invoiceSeries: string, isSendSummary: boolean) =>
    tryCreateTemplateRef({ templateId, name, invoiceSeries, isSendSummary })!
  const merged = mergeAndDedupe([
    mk('tpl-c', 'Có mã', '1C26TYY', false),
    mk('tpl-k', 'Không mã', '1K26TYY', true),
    mk('tpl-c-dup', 'Dup series', '1C26TYY', false),
  ])
  assertEquals(merged.length, 2)
  assertEquals(new Set(merged.map((t) => t.invoiceSeries)), new Set(['1C26TYY', '1K26TYY']))
  assertEquals(merged.find((t) => t.invoiceSeries === '1K26TYY')!.isSendSummary, true)
})
