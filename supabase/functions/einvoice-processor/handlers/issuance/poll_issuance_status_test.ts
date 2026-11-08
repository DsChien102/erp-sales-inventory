import { assertEquals } from 'jsr:@std/assert@1'
import { createPollIssuanceStatusHandler } from './poll_issuance_status.ts'
import { FakeIssuanceGateways, FakeIssuanceProvider } from './fake_gateways.ts'
import {
  MISA_PUBLISH_PROVIDER_CODES,
  PUBLISH_UNDETERMINED_REASON,
} from './outcomes.ts'
import type { CommandContext } from '../../queue/types.ts'

function makeContext(payload: Record<string, unknown>, commandId = 'cmd-poll-1'): CommandContext {
  return {
    tenantId: 'tenant-1',
    attemptNumber: 1,
    command: {
      commandId,
      commandType: 'einvoice.poll_issuance_status',
      payload,
      sourceEventId: null,
      enqueuedAt: '2026-11-08T00:00:00Z',
      claimToken: 'tok-poll-1',
      retryCount: 0,
    },
  }
}

function sampleContext(): CommandContext {
  return makeContext({
    tenant_id: 'tenant-1',
    case_id: 'case-1',
    attempt_id: 'attempt-1',
    correlation_id: 'corr-1',
  })
}

Deno.test('PollIssuanceStatusCommandHandler lost claim safely returns without polling or executing commands', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()
  gateways.reconciliation.claimContext = null

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(gateways.reconciliation.claimCalls.length, 1)
  assertEquals(provider.getStatusCalls.length, 0)
  assertEquals(gateways.results.successCalls.length, 0)
  assertEquals(provider.publishCalls.length, 0)
})

Deno.test('PollIssuanceStatusCommandHandler success outcome dispatches RecordIssuanceResultCommand with success evidence and NEVER calls publish', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1C26TYY',
    providerReference: 'tx-1',
    reconciliationReasonCode: null,
    checkSequence: 1,
    maxChecks: 5,
  }

  provider.statusOutcome = {
    kind: 'success',
    evidence: {
      kind: 'success',
      idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
      payloadHash: 'hash-1',
      providerReference: 'tx-1',
      invoiceNumber: '00000123',
      invoiceSeries: '1C26TVE',
      issuedAt: new Date(Date.UTC(2026, 7, 28)),
    },
  }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.getStatusCalls[0].statusLookupKey, 'tx-1')
  assertEquals(provider.getStatusCalls[0].invoiceSeries, '1C26TYY')
  assertEquals(provider.publishCalls.length, 0)

  assertEquals(gateways.results.successCalls.length, 1)
  assertEquals(gateways.results.successCalls[0].tenantId, 'tenant-1')
  assertEquals(gateways.results.successCalls[0].attemptId, 'attempt-1')

  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'SUCCESS')
  assertEquals(gateways.reconciliation.resolveCalls[0].evidence, {
    provider_reference: 'tx-1',
    invoice_number: '00000123',
    invoice_series: '1C26TVE',
    issued_at: '2026-08-28T00:00:00.000Z',
  })
})

Deno.test('PollIssuanceStatusCommandHandler definite failure outcome dispatches RecordIssuanceResultCommand with failure evidence and NEVER calls publish', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1C26TYY',
    providerReference: 'tx-1',
    reconciliationReasonCode: null,
    checkSequence: 1,
    maxChecks: 5,
  }

  provider.statusOutcome = {
    kind: 'definiteFailure',
    evidence: {
      kind: 'definiteFailure',
      idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
      payloadHash: 'hash-1',
      providerCode: 'InvalidInvSeries',
      providerMessage: 'Series invalid',
    },
  }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.getStatusCalls[0].statusLookupKey, 'tx-1')
  assertEquals(provider.getStatusCalls[0].invoiceSeries, '1C26TYY')
  assertEquals(provider.publishCalls.length, 0)

  assertEquals(gateways.results.definiteFailureCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'FAILURE')
  assertEquals(gateways.reconciliation.resolveCalls[0].evidence, {
    provider_code: 'InvalidInvSeries',
    provider_message: 'Series invalid',
  })
})

Deno.test('PollIssuanceStatusCommandHandler pending outcome at check 1 records pending check with delay of check 2 (2 minutes)', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1K26TYY',
    providerReference: 'tx-1',
    reconciliationReasonCode: null,
    checkSequence: 1,
    maxChecks: 5,
  }
  provider.statusOutcome = { kind: 'pending' }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.reconciliation.pendingCheckCalls.length, 1)
  assertEquals(gateways.reconciliation.pendingCheckCalls[0].nextDelaySeconds, 120)
  assertEquals(gateways.reconciliation.pendingCheckCalls[0].checkSequence, 2)
  assertEquals(gateways.reconciliation.resolveCalls.length, 0)
})

Deno.test('PollIssuanceStatusCommandHandler pending outcome at check 5 marks unresolved and stops polling', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1K26TYY',
    providerReference: 'tx-1',
    checkSequence: 5,
    maxChecks: 5,
    reconciliationReasonCode: null,
  }
  provider.statusOutcome = { kind: 'pending' }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.reconciliation.pendingCheckCalls.length, 0)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'UNRESOLVED')
  assertEquals(gateways.reconciliation.resolveCalls[0].evidence?.['reason_code'], 'POLL_MAX_CHECKS_EXCEEDED')
})

Deno.test('PollIssuanceStatusCommandHandler undetermined outcome at check 5 marks unresolved and stops polling', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1K26TYY',
    providerReference: 'tx-1',
    checkSequence: 5,
    maxChecks: 5,
    reconciliationReasonCode: null,
  }
  provider.statusOutcome = { kind: 'undetermined', reasonCode: 'PROVIDER_TIMEOUT' }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.reconciliation.pendingCheckCalls.length, 0)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'UNRESOLVED')
  assertEquals(gateways.reconciliation.resolveCalls[0].evidence?.['reason_code'], 'POLL_MAX_CHECKS_EXCEEDED')
})

Deno.test('PollIssuanceStatusCommandHandler InvoiceDuplicated reconcile-first polls status by RefID without provider transaction id', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1C26TYY',
    providerReference: null,
    reconciliationReasonCode: PUBLISH_UNDETERMINED_REASON.invoiceDuplicatedReconcileFirst,
    checkSequence: 1,
    maxChecks: 5,
  }

  provider.statusOutcome = {
    kind: 'success',
    evidence: {
      kind: 'success',
      idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
      payloadHash: 'hash-1',
      providerReference: 'tx-from-ref',
      invoiceNumber: '00000123',
      invoiceSeries: '1C26TVE',
      issuedAt: new Date(Date.UTC(2026, 7, 28)),
    },
  }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.getStatusCalls[0].statusLookupKey, '88d18970-380a-4138-bbce-e25049ca9e3c')
  assertEquals(provider.getStatusCalls[0].statusLookup, 'refId')
  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.results.successCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'SUCCESS')
})

Deno.test('PollIssuanceStatusCommandHandler InvoiceDuplicated definitive-not-found after max checks schedules durable publish retry', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1C26TYY',
    providerReference: null,
    reconciliationReasonCode: PUBLISH_UNDETERMINED_REASON.invoiceDuplicatedReconcileFirst,
    checkSequence: 5,
    maxChecks: 5,
  }
  provider.statusOutcome = {
    kind: 'undetermined',
    reasonCode: 'STATUS_EMPTY_DATA',
  }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 1)
  assertEquals(provider.publishCalls.length, 0)
  assertEquals(gateways.results.retryableRejectionCalls.length, 1)
  assertEquals(gateways.results.retryableRejectionCalls[0].sourceCommandId, 'cmd-poll-1')
  assertEquals(gateways.results.retryableRejectionCalls[0].evidence.providerCode, MISA_PUBLISH_PROVIDER_CODES.invoiceDuplicated)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'PUBLISH_RETRY_SCHEDULED')
})

Deno.test('PollIssuanceStatusCommandHandler missing provider transaction id marks unresolved without status polling', async () => {
  const gateways = new FakeIssuanceGateways()
  const provider = new FakeIssuanceProvider()

  gateways.reconciliation.claimContext = {
    caseId: 'case-1',
    attemptId: 'attempt-1',
    claimToken: 'token-1',
    idempotencyKey: '88d18970-380a-4138-bbce-e25049ca9e3c',
    payloadHash: 'hash-1',
    invoiceSeries: '1C26TYY',
    providerReference: null,
    checkSequence: 1,
    maxChecks: 5,
    reconciliationReasonCode: null,
  }

  const handler = createPollIssuanceStatusHandler({ provider, gateways })
  await handler(sampleContext())

  assertEquals(provider.getStatusCalls.length, 0)
  assertEquals(gateways.reconciliation.resolveCalls.length, 1)
  assertEquals(gateways.reconciliation.resolveCalls[0].outcome, 'UNRESOLVED')
  assertEquals(gateways.reconciliation.resolveCalls[0].evidence?.['reason_code'], 'MISSING_PROVIDER_TRANSACTION_ID')
})

