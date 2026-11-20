import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { createPublishInvoiceHandler } from './publish_invoice.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './fake_gateways.ts'
import { CanonicalInvoiceIntegrityError } from './errors.ts'
import { PublishSeriesLeaseBusyError } from '../../queue/errors.ts'
import type { CommandContext } from '../../queue/types.ts'

const sampleInvoice = {
  invSeries: '1C25TYY',
  signType: 2,
  invDate: '2026-08-01',
  buyerLegalName: 'ABC',
  buyerAddress: 'HN',
  totalAmount: 110000,
  originalInvoiceDetail: [
    { itemName: 'Svc', quantity: 1, unitPrice: 100000 },
  ],
  taxRateInfo: [{ vatRateName: '10%' }],
}

function makeContext(payload: Record<string, unknown>, commandId = 'cmd-pub-1'): CommandContext {
  return {
    tenantId: 'tenant-1',
    attemptNumber: 1,
    command: {
      commandId,
      commandType: 'einvoice.publish_invoice',
      payload,
      sourceEventId: null,
      enqueuedAt: '2026-11-08T00:00:00Z',
      claimToken: 'tok-pub-1',
      retryCount: 0,
    },
  }
}

function sampleContext(overrides: Record<string, unknown> = {}): CommandContext {
  return makeContext({
    tenant_id: 'tenant-1',
    attempt_id: 'att-1',
    canonical_invoice: sampleInvoice,
    payload_hash: 'hash-1',
    idempotency_key: 'attempt-key-42',
    ...overrides,
  })
}

Deno.test('PublishInvoiceCommandHandler provider call timestamp is written only immediately before HTTP', async () => {
  const callOrder: string[] = []
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  const origMark = gateways.results.markProviderCallStarted.bind(gateways.results)
  gateways.results.markProviderCallStarted = (t, a) => {
    callOrder.push('markStarted')
    return origMark(t, a)
  }
  const origPublish = provider.publish.bind(provider)
  provider.publish = (t, c, k) => {
    callOrder.push('providerPublish')
    return origPublish(t, c, k)
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(callOrder, ['markStarted', 'providerPublish'])
})

Deno.test('PublishInvoiceCommandHandler failure to mark provider-call start never calls HTTP', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.results.markProviderCallStarted = () => Promise.reject(new Error('db write error'))

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await assertRejects(() => handler(sampleContext()), Error, 'db write error')

  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler callProvider invokes provider once and records typed success', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'success',
    providerReference: 'tx-1',
    invoiceNumber: '0000001',
    invoiceSeries: '1C25TYY',
    issuedAt: new Date(Date.UTC(2026, 7, 1)),
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.publishCalls.length, 1)
  assertEquals(gateways.results.successCalls.length, 1)
  const success = gateways.results.successCalls[0]
  assertEquals(success.tenantId, 'tenant-1')
  assertEquals(success.attemptId, 'att-1')
  assertEquals(success.evidence.providerReference, 'tx-1')
  assertEquals(success.evidence.invoiceNumber, '0000001')
  assertEquals(success.evidence.invoiceSeries, '1C25TYY')
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler reconcileOnly skips provider and records DISPATCH_STATE_UNCERTAIN', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.results.preparationAction = 'RECONCILE_ONLY'

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.results.undeterminedCalls.length, 1)
  assertEquals(gateways.results.undeterminedCalls[0].evidence.reasonCode, 'DISPATCH_STATE_UNCERTAIN')
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler skip returns without provider or result gateway mutations', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.results.preparationAction = 'SKIP'

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.results.successCalls.length, 0)
  assertEquals(gateways.results.undeterminedCalls.length, 0)
  assertEquals(gateways.results.definiteFailureCalls.length, 0)
  assertEquals(gateways.results.retryableRejectionCalls.length, 0)
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler busy lease throws before preparePublish and does not release acquired lease', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.lease.leaseOutcome = { kind: 'busy', retryAfterSeconds: 15 }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  const err = await assertRejects(() => handler(sampleContext()), PublishSeriesLeaseBusyError)
  assertEquals((err as PublishSeriesLeaseBusyError).retryAfterSeconds, 15)

  assertEquals(gateways.results.prepareCalls.length, 0)
  assertEquals(gateways.lease.releaseCalls.length, 0)
})

Deno.test('PublishInvoiceCommandHandler validateCanonical failure throws CanonicalInvoiceIntegrityException before lease acquire', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.throwOnValidate = true

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await assertRejects(() => handler(sampleContext()), CanonicalInvoiceIntegrityError)

  assertEquals(gateways.lease.acquireCalls.length, 0)
  assertEquals(gateways.lease.releaseCalls.length, 0)
})

Deno.test('PublishInvoiceCommandHandler timeout outcome records undetermined and completes normally', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'undetermined',
    reasonCode: 'PROVIDER_TIMEOUT',
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.results.undeterminedCalls.length, 1)
  assertEquals(gateways.results.undeterminedCalls[0].evidence.reasonCode, 'PROVIDER_TIMEOUT')
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler InvoiceNumberNotCotinuous records retryable provider rejection', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'retryableRejection',
    providerCode: 'InvoiceNumberNotCotinuous',
    providerMessage: 'gap in series',
    retryAfterSeconds: 5,
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.results.retryableRejectionCalls.length, 1)
  const rej = gateways.results.retryableRejectionCalls[0]
  assertEquals(rej.evidence.providerCode, 'InvoiceNumberNotCotinuous')
  assertEquals(rej.sourceCommandId, 'cmd-pub-1')
  assertEquals(rej.retryAfterSeconds, 5)
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler duplicate RefID records undetermined, never definite failure', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'undetermined',
    reasonCode: 'DUPLICATE_INVOICE_REF_ID',
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.results.undeterminedCalls.length, 1)
  assertEquals(gateways.results.undeterminedCalls[0].evidence.reasonCode, 'DUPLICATE_INVOICE_REF_ID')
  assertEquals(gateways.results.definiteFailureCalls.length, 0)
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler definite failure records typed failure evidence', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'definiteFailure',
    providerCode: 'InvalidInvSeries',
    providerMessage: 'Bad series',
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.results.definiteFailureCalls.length, 1)
  assertEquals(gateways.results.definiteFailureCalls[0].evidence.providerCode, 'InvalidInvSeries')
  assertEquals(gateways.lease.releaseCalls.length, 1)
})

Deno.test('PublishInvoiceCommandHandler does not dispatch RecordIssuanceResultCommand (dormant until S3b)', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.publishOutcome = {
    kind: 'definiteFailure',
    providerCode: 'InvalidInvSeries',
    providerMessage: 'Bad series',
    safeProviderEvidence: { refId: 'attempt-key-42' },
  }

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.results.successCalls.length, 0)
})

Deno.test('PublishInvoiceCommandHandler parses SQL payload and fails on missing required keys', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  const handler = createPublishInvoiceHandler({ provider, gateways })

  await assertRejects(
    () => handler(makeContext({ attempt_id: 'att-1' })),
    Error,
    'missing',
  )
})

Deno.test('PublishInvoiceCommandHandler releases the lease when the provider call throws', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  provider.throwOnPublish = new Error('catastrophic MISA client crash')

  const handler = createPublishInvoiceHandler({ provider, gateways })
  await assertRejects(() => handler(sampleContext()), Error, 'catastrophic MISA client crash')

  assertEquals(gateways.lease.releaseCalls.length, 1)
  assertEquals(gateways.lease.releaseCalls[0].leaseVersion, 1)
})

