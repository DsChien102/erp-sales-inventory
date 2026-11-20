import type { IssuanceResultEvidence } from './outcomes.ts'
import type { IssuanceResultGateway } from './gateways.ts'

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export interface RecordIssuanceResultInput {
  tenantId: string
  attemptId: string
  correlationId: string
  evidence: IssuanceResultEvidence
}

export function validateRecordIssuanceResult(input: RecordIssuanceResultInput): void {
  if (input.tenantId.trim().length === 0) {
    throw new Error('tenantId is required')
  }
  if (input.attemptId.trim().length === 0) {
    throw new Error('attemptId is required')
  }
  if (input.correlationId.trim().length === 0) {
    throw new Error('correlationId is required')
  }
  if (input.evidence.idempotencyKey.trim().length === 0) {
    throw new Error('idempotencyKey is required')
  }
  if (!UUID_REGEX.test(input.evidence.idempotencyKey.trim())) {
    throw new Error('idempotencyKey must be a canonical UUID')
  }
  if (input.evidence.payloadHash.trim().length === 0) {
    throw new Error('payloadHash is required')
  }

  switch (input.evidence.kind) {
    case 'success':
      if (input.evidence.invoiceNumber.trim().length === 0) {
        throw new Error('invoiceNumber is required for success evidence')
      }
      if (input.evidence.invoiceSeries.trim().length === 0) {
        throw new Error('invoiceSeries is required for success evidence')
      }
      break
    case 'definiteFailure':
      if (input.evidence.providerCode.trim().length === 0) {
        throw new Error('providerCode is required for failure evidence')
      }
      if (input.evidence.providerMessage.trim().length === 0) {
        throw new Error('providerMessage is required for failure evidence')
      }
      break
    case 'undetermined':
      if (input.evidence.reasonCode.trim().length === 0) {
        throw new Error('reasonCode is required for undetermined evidence')
      }
      break
    case 'retryableProviderRejection':
      throw new Error('retryable provider rejection must use publish retry gateway path')
    default: {
      const _exhaustive: never = input.evidence
      throw new Error(`Unsupported evidence kind: ${JSON.stringify(_exhaustive)}`)
    }
  }
}

export async function recordIssuanceResult(
  results: IssuanceResultGateway,
  input: RecordIssuanceResultInput,
): Promise<void> {
  validateRecordIssuanceResult(input)

  switch (input.evidence.kind) {
    case 'success':
      await results.recordSuccess(input.tenantId, input.attemptId, input.evidence)
      break
    case 'definiteFailure':
      await results.recordDefiniteFailure(input.tenantId, input.attemptId, input.evidence)
      break
    case 'undetermined':
      await results.recordUndetermined(input.tenantId, input.attemptId, input.evidence)
      break
    case 'retryableProviderRejection':
      throw new Error('retryable provider rejection must use publish retry gateway path')
  }
}

