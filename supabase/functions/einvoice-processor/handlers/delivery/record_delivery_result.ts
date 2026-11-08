import type {
  DeliveryGateway,
  DeliveryResultRecord,
} from './gateways.ts'

export function validateDeliveryResultRecord(record: DeliveryResultRecord): void {
  if (!record.tenantId || record.tenantId.trim().length === 0) {
    throw new Error('tenantId is required')
  }
  if (!record.deliveryId || record.deliveryId.trim().length === 0) {
    throw new Error('deliveryId is required')
  }
  if (
    typeof record.retryCount !== 'number' ||
    !Number.isInteger(record.retryCount) ||
    record.retryCount < 0 ||
    record.retryCount > 2
  ) {
    throw new Error('retryCount must be between 0 and 2')
  }
}

export async function recordDeliveryResult(
  gateway: DeliveryGateway,
  record: DeliveryResultRecord,
): Promise<void> {
  validateDeliveryResultRecord(record)
  await gateway.recordResult(record)
}
