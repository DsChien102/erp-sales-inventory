function parseRequiredString(
  payload: Record<string, unknown>,
  key: string,
): string {
  if (!Object.prototype.hasOwnProperty.call(payload, key)) {
    throw new Error(`Invalid or missing automation payload: ${key}`)
  }
  const value = payload[key]
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`Invalid or missing automation payload: ${key}`)
  }
  return value.trim()
}

function parseTenantId(
  payload: Record<string, unknown>,
  claimedTenantId: string,
): string {
  if (!Object.prototype.hasOwnProperty.call(payload, 'tenant_id')) {
    return claimedTenantId
  }
  const tenantId = parseRequiredString(payload, 'tenant_id')
  if (tenantId !== claimedTenantId) {
    throw new Error('Automation tenant does not match claimed tenant')
  }
  return tenantId
}

export function parseStartAutoIssuancePayload(
  p: Record<string, unknown>,
  claimedTenantId: string,
): { tenantId: string; salesOrderId: string; sourceVersion: string } {
  const tenantId = parseTenantId(p, claimedTenantId)
  const salesOrderId = parseRequiredString(p, 'sales_order_id')
  const sourceVersion = parseRequiredString(p, 'source_version')
  return { tenantId, salesOrderId, sourceVersion }
}

export function parseReevaluateAutoIssuancePayload(
  p: Record<string, unknown>,
  claimedTenantId: string,
): { tenantId: string; processId: string; sourceEventId: string } {
  const tenantId = parseTenantId(p, claimedTenantId)
  const processId = parseRequiredString(p, 'process_id')
  const sourceEventId = parseRequiredString(p, 'source_event_id')
  return { tenantId, processId, sourceEventId }
}

export function parseStartAutoDeliveryPayload(
  p: Record<string, unknown>,
  claimedTenantId: string,
): { tenantId: string; electronicInvoiceId: string } {
  const tenantId = parseTenantId(p, claimedTenantId)
  const electronicInvoiceId = parseRequiredString(p, 'electronic_invoice_id')
  return { tenantId, electronicInvoiceId }
}

