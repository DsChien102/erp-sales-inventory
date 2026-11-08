import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import { recordIssuanceResult } from './record_issuance_result.ts'
import { FakeIssuanceResultGateway } from './fake_gateways.ts'
import type { IssuanceResultEvidence } from './outcomes.ts'

const validUuid = '88d18970-380a-4138-bbce-e25049ca9e3c'

Deno.test('RecordIssuanceResultCommandHandler success evidence routes only to recordSuccess', async () => {
  const gateway = new FakeIssuanceResultGateway()
  const evidence: IssuanceResultEvidence = {
    kind: 'success',
    idempotencyKey: validUuid,
    payloadHash: 'hash-abc',
    providerReference: 'misa-1',
    invoiceNumber: '00000123',
    invoiceSeries: '1C26TVE',
    issuedAt: new Date(Date.UTC(2026, 7, 28)),
  }

  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence,
  })

  assertEquals(gateway.successCalls.length, 1)
  assertEquals(gateway.definiteFailureCalls.length, 0)
  assertEquals(gateway.undeterminedCalls.length, 0)
  assertEquals(gateway.successCalls[0].tenantId, 'tenant-1')
  assertEquals(gateway.successCalls[0].attemptId, 'attempt-1')
  assertEquals(gateway.successCalls[0].evidence.providerReference, 'misa-1')
})

Deno.test('RecordIssuanceResultCommandHandler definiteFailure evidence routes only to recordDefiniteFailure', async () => {
  const gateway = new FakeIssuanceResultGateway()
  const evidence: IssuanceResultEvidence = {
    kind: 'definiteFailure',
    idempotencyKey: validUuid,
    payloadHash: 'hash-abc',
    providerCode: 'InvalidInvSeries',
    providerMessage: 'Series invalid',
  }

  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence,
  })

  assertEquals(gateway.definiteFailureCalls.length, 1)
  assertEquals(gateway.successCalls.length, 0)
  assertEquals(gateway.undeterminedCalls.length, 0)
  assertEquals(gateway.definiteFailureCalls[0].tenantId, 'tenant-1')
  assertEquals(gateway.definiteFailureCalls[0].attemptId, 'attempt-1')
  assertEquals(gateway.definiteFailureCalls[0].evidence.providerCode, 'InvalidInvSeries')
})

Deno.test('RecordIssuanceResultCommandHandler undetermined evidence routes only to recordUndetermined', async () => {
  const gateway = new FakeIssuanceResultGateway()
  const evidence: IssuanceResultEvidence = {
    kind: 'undetermined',
    idempotencyKey: validUuid,
    payloadHash: 'hash-abc',
    reasonCode: 'PROVIDER_TIMEOUT',
  }

  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence,
  })

  assertEquals(gateway.undeterminedCalls.length, 1)
  assertEquals(gateway.successCalls.length, 0)
  assertEquals(gateway.definiteFailureCalls.length, 0)
  assertEquals(gateway.undeterminedCalls[0].tenantId, 'tenant-1')
  assertEquals(gateway.undeterminedCalls[0].attemptId, 'attempt-1')
  assertEquals(gateway.undeterminedCalls[0].evidence.reasonCode, 'PROVIDER_TIMEOUT')
})

Deno.test('RecordIssuanceResultCommandHandler valid success command passes validation', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence: {
      kind: 'success',
      idempotencyKey: validUuid,
      payloadHash: 'hash-abc',
      providerReference: 'misa-1',
      invoiceNumber: '00000123',
      invoiceSeries: '1C26TVE',
      issuedAt: new Date(Date.UTC(2026, 7, 28)),
    },
  })
  assertEquals(gateway.successCalls.length, 1)
})

Deno.test('RecordIssuanceResultCommandHandler valid definiteFailure command passes validation', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence: {
      kind: 'definiteFailure',
      idempotencyKey: validUuid,
      payloadHash: 'hash-abc',
      providerCode: 'InvalidInvSeries',
      providerMessage: 'Series invalid',
    },
  })
  assertEquals(gateway.definiteFailureCalls.length, 1)
})

Deno.test('RecordIssuanceResultCommandHandler valid undetermined command passes validation', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await recordIssuanceResult(gateway, {
    tenantId: 'tenant-1',
    attemptId: 'attempt-1',
    correlationId: 'corr-1',
    evidence: {
      kind: 'undetermined',
      idempotencyKey: validUuid,
      payloadHash: 'hash-abc',
      reasonCode: 'PROVIDER_TIMEOUT',
    },
  })
  assertEquals(gateway.undeterminedCalls.length, 1)
})

Deno.test('RecordIssuanceResultCommandHandler rejects empty tenantId', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: '   ',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          reasonCode: 'PROVIDER_TIMEOUT',
        },
      }),
    Error,
    'tenantId is required',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects empty attemptId', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: '',
        correlationId: 'corr-1',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          reasonCode: 'PROVIDER_TIMEOUT',
        },
      }),
    Error,
    'attemptId is required',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects empty correlationId', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: '  ',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: validUuid,
          payloadHash: 'hash-abc',
          reasonCode: 'PROVIDER_TIMEOUT',
        },
      }),
    Error,
    'correlationId is required',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects non-UUID idempotencyKey', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: 'not-a-uuid',
          payloadHash: 'hash-abc',
          reasonCode: 'PROVIDER_TIMEOUT',
        },
      }),
    Error,
    'idempotencyKey must be a canonical UUID',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects empty payloadHash', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: validUuid,
          payloadHash: '',
          reasonCode: 'PROVIDER_TIMEOUT',
        },
      }),
    Error,
    'payloadHash is required',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects success evidence with empty invoiceNumber or series', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'success',
          idempotencyKey: validUuid,
          payloadHash: 'hash-1',
          providerReference: 'ref-1',
          invoiceNumber: '',
          invoiceSeries: '1C26TVE',
          issuedAt: new Date(),
        },
      }),
    Error,
    'invoiceNumber is required for success evidence',
  )

  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'success',
          idempotencyKey: validUuid,
          payloadHash: 'hash-1',
          providerReference: 'ref-1',
          invoiceNumber: '0000001',
          invoiceSeries: '   ',
          issuedAt: new Date(),
        },
      }),
    Error,
    'invoiceSeries is required for success evidence',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects failure evidence with empty providerCode or message', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'definiteFailure',
          idempotencyKey: validUuid,
          payloadHash: 'hash-1',
          providerCode: '',
          providerMessage: 'msg',
        },
      }),
    Error,
    'providerCode is required for failure evidence',
  )

  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'definiteFailure',
          idempotencyKey: validUuid,
          payloadHash: 'hash-1',
          providerCode: 'CODE',
          providerMessage: '',
        },
      }),
    Error,
    'providerMessage is required for failure evidence',
  )
})

Deno.test('RecordIssuanceResultCommandHandler rejects undetermined evidence with empty reasonCode', async () => {
  const gateway = new FakeIssuanceResultGateway()
  await assertRejects(
    () =>
      recordIssuanceResult(gateway, {
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        correlationId: 'corr-1',
        evidence: {
          kind: 'undetermined',
          idempotencyKey: validUuid,
          payloadHash: 'hash-1',
          reasonCode: '',
        },
      }),
    Error,
    'reasonCode is required for undetermined evidence',
  )
})

