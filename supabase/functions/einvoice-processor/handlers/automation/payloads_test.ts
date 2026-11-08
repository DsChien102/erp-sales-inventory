import { assertThrows } from 'jsr:@std/assert@1'
import {
  parseStartAutoIssuancePayload,
  parseStartAutoDeliveryPayload,
} from './payloads.ts'

Deno.test('automation payload rejects missing required key', () => {
  assertThrows(
    () => {
      parseStartAutoIssuancePayload(
        { tenant_id: 't', sales_order_id: ' ', source_version: '1' },
        't',
      )
    },
    Error,
    'Invalid or missing automation payload: sales_order_id',
  )
})

Deno.test('automation payload rejects tenant mismatch', () => {
  assertThrows(
    () => {
      parseStartAutoDeliveryPayload(
        { tenant_id: 'tenant-2', electronic_invoice_id: 'ei-1' },
        'tenant-1',
      )
    },
    Error,
    'Automation tenant does not match claimed tenant',
  )
})
