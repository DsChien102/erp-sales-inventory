import { assertEquals } from 'jsr:@std/assert@1'
import { classifyIssuanceStatus } from './issuance_status_classifier.ts'
import {
  MeInvoiceInvoiceStatus,
  MeInvoiceResult,
} from '../../misa/mod.ts'

Deno.test('MeInvoiceIssuanceStatusClassifier provider issued status (PublishStatus == 1) becomes typed success', () => {
  const status = new MeInvoiceInvoiceStatus({
    refId: 'ref-1',
    transactionId: 'tx-1',
    invSeries: '1C26TVE',
    invNo: '00000123',
    publishStatus: 1,
    publishedTime: new Date(Date.UTC(2026, 7, 28, 10, 0)),
  })
  const outcome = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.ok([status]),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })

  assertEquals(outcome.kind, 'success')
  if (outcome.kind === 'success') {
    assertEquals(outcome.evidence.providerReference, 'tx-1')
    assertEquals(outcome.evidence.invoiceNumber, '00000123')
    assertEquals(outcome.evidence.invoiceSeries, '1C26TVE')
    assertEquals(outcome.evidence.idempotencyKey, 'ref-1')
    assertEquals(outcome.evidence.payloadHash, 'hash-1')
    assertEquals(outcome.evidence.issuedAt, new Date(Date.UTC(2026, 7, 28, 10, 0)))
  }
})

Deno.test('MeInvoiceIssuanceStatusClassifier provider processing/pending status (PublishStatus != 1 && no terminal rejection) remains pending', () => {
  const status = new MeInvoiceInvoiceStatus({
    refId: 'ref-1',
    transactionId: 'tx-1',
    publishStatus: 0,
  })
  const outcome = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.ok([status]),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })

  assertEquals(outcome.kind, 'pending')
})

Deno.test('MeInvoiceIssuanceStatusClassifier empty status data list becomes pending/undetermined', () => {
  const outcome = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.ok([]),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })

  assertEquals(outcome.kind, 'undetermined')
})

Deno.test('MeInvoiceIssuanceStatusClassifier transport error or timeout is undetermined, NEVER definite failure', () => {
  const outcomeTimeout = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.failed('meinvoice_network_timeout'),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })
  assertEquals(outcomeTimeout.kind, 'undetermined')

  const outcome5xx = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.failed('meinvoice_5xx'),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })
  assertEquals(outcome5xx.kind, 'undetermined')
})

Deno.test('MeInvoiceIssuanceStatusClassifier terminal rejection error code in result maps to definite failure', () => {
  const outcome = classifyIssuanceStatus({
    statusResult: MeInvoiceResult.failed('InvalidInvSeries: Invalid series'),
    idempotencyKey: 'ref-1',
    payloadHash: 'hash-1',
  })

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.evidence.providerCode, 'InvalidInvSeries')
    assertEquals(outcome.evidence.providerMessage, 'Invalid series')
  }
})

