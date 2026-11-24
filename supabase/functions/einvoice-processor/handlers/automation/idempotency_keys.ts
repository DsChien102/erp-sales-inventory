export const SALES_ORDER_FINALIZED_EVENT_TYPE = 'sales_order_finalized.v1'
export const AUTO_ISSUANCE_NAMESPACE = '6ba7b811-9dad-11d1-80b4-00c04fd430c8'
export const AUTO_DELIVERY_NAMESPACE = '9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275'

function parseUuidBytes(uuid: string): Uint8Array {
  const clean = uuid.replace(/-/g, '')
  if (clean.length !== 32) {
    throw new Error(`Invalid UUID: ${uuid}`)
  }
  const bytes = new Uint8Array(16)
  for (let i = 0; i < 16; i++) {
    bytes[i] = parseInt(clean.substring(i * 2, i * 2 + 2), 16)
  }
  return bytes
}

export async function uuidV5(namespace: string, name: string): Promise<string> {
  const nsBytes = parseUuidBytes(namespace)
  const nameBytes = new TextEncoder().encode(name)
  const data = new Uint8Array(nsBytes.length + nameBytes.length)
  data.set(nsBytes, 0)
  data.set(nameBytes, nsBytes.length)

  const digestBuffer = await crypto.subtle.digest('SHA-1', data)
  const bytes = new Uint8Array(digestBuffer, 0, 16)

  // RFC 4122 §4.3: version 5
  bytes[6] = (bytes[6] & 0x0f) | 0x50
  // RFC 4122 §4.3: variant
  bytes[8] = (bytes[8] & 0x3f) | 0x80

  const hex: string[] = []
  for (let i = 0; i < 16; i++) {
    hex.push(bytes[i].toString(16).padStart(2, '0'))
  }

  return (
    hex.slice(0, 4).join('') + '-' +
    hex.slice(4, 6).join('') + '-' +
    hex.slice(6, 8).join('') + '-' +
    hex.slice(8, 10).join('') + '-' +
    hex.slice(10, 16).join('')
  )
}

export function autoIssuanceTriggerKey(i: {
  eventType: string
  eventId: string
  salesOrderId: string
  sourceVersion: string
}): string {
  return `${i.eventType}:${i.eventId}:${i.salesOrderId}:${i.sourceVersion}`
}

export function autoIssuanceIdempotencyKey(i: {
  tenantId: string
  salesOrderId: string
  sourceVersion: string
}): Promise<string> {
  const seed = `einvoice:auto_issue:${i.tenantId}:${i.salesOrderId}:${i.sourceVersion}`
  return uuidV5(AUTO_ISSUANCE_NAMESPACE, seed)
}

export function autoDeliveryIdempotencyKey(i: {
  tenantId: string
  electronicInvoiceId: string
}): Promise<string> {
  const seed = `${i.tenantId}|${i.electronicInvoiceId}|auto_initial`
  return uuidV5(AUTO_DELIVERY_NAMESPACE, seed)
}

