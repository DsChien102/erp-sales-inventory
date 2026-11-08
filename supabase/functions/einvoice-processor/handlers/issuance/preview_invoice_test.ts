import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { createPreviewInvoiceHandler } from './preview_invoice.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './fake_gateways.ts'
import { ProviderUnavailableError } from '../../queue/errors.ts'
import type { CommandContext } from '../../queue/types.ts'

const sampleInvoice = {
  invSeries: '1C25TYY',
  signType: 2,
  totalAmount: 110000,
}

function makeContext(payload: Record<string, unknown>): CommandContext {
  return {
    tenantId: 'tenant-1',
    attemptNumber: 1,
    command: {
      commandId: 'cmd-1',
      commandType: 'einvoice.preview_invoice',
      payload,
      sourceEventId: null,
      enqueuedAt: '2026-11-08T00:00:00Z',
      claimToken: 'tok-1',
      retryCount: 0,
    },
  }
}

function sampleContext(canonical = sampleInvoice): CommandContext {
  return makeContext({
    tenant_id: 'tenant-1',
    sales_order_id: 'order-1',
    preview_request_id: 'req-1',
    provider_connection_id: 'conn-1',
    order_version: 1,
    canonical_invoice: canonical,
  })
}

Deno.test('PreviewInvoiceCommandHandler stores READY with the viewer ref', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.previewOutcome = {
    kind: 'success',
    viewerRef: 'https://viewer/1',
  }

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.preview.stored.length, 1)
  assertEquals(gateways.preview.stored[0].status, 'READY')
  assertEquals(gateways.preview.stored[0].viewerRef, 'https://viewer/1')
  assertEquals(gateways.preview.stored[0].requestId, 'req-1')
  assertEquals(gateways.preview.stored[0].salesOrderId, 'order-1')
})

Deno.test('PreviewInvoiceCommandHandler records a data rejection as FAILED and does not retry', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.previewOutcome = {
    kind: 'invalidData',
    detail: 'Invalid_[Invoice.TaxRateInfo]',
  }

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.preview.stored.length, 1)
  assertEquals(gateways.preview.stored[0].status, 'FAILED')
  assertEquals(gateways.preview.stored[0].failureCode, 'PROVIDER_REJECTED_INVOICE_DATA')
  assertEquals(gateways.preview.stored[0].failureSource, 'PROVIDER')
  assertEquals(gateways.preview.stored[0].failureMessage, 'Invalid_[Invoice.TaxRateInfo]')
})

Deno.test('PreviewInvoiceCommandHandler records an auth failure as FAILED', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.previewOutcome = { kind: 'authFailed' }

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.preview.stored.length, 1)
  assertEquals(gateways.preview.stored[0].status, 'FAILED')
  assertEquals(gateways.preview.stored[0].failureCode, 'PROVIDER_AUTH_FAILED')
  assertEquals(gateways.preview.stored[0].failureSource, 'PROVIDER')
})

Deno.test('PreviewInvoiceCommandHandler leaves the row pending when MISA is unavailable', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.previewOutcome = { kind: 'providerUnavailable' }

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await assertRejects(() => handler(sampleContext()), ProviderUnavailableError)
  assertEquals(gateways.preview.stored.length, 0)
})

Deno.test('PreviewInvoiceCommandHandler leaves the row pending when the call throws', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.throwOnPreview = new Error('misa network error')

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await assertRejects(() => handler(sampleContext()), Error, 'misa network error')
  assertEquals(gateways.preview.stored.length, 0)
})

Deno.test('PreviewInvoiceCommandHandler adds refId from the preview request id', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.previewOutcome = {
    kind: 'success',
    viewerRef: 'https://viewer/1',
  }

  const handler = createPreviewInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.lastCanonical?.['refId'], 'req-1')
})

Deno.test('PreviewInvoiceCommandHandler parses SQL payload and fails on missing required keys', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  const handler = createPreviewInvoiceHandler({ provider, gateways })

  await assertRejects(
    () => handler(makeContext({ sales_order_id: 'order-1' })),
    Error,
    'missing',
  )
})

