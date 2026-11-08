import { assertEquals, assertThrows } from 'jsr:@std/assert@1'
import {
  MeInvoiceInvoiceStatus,
  MeInvoiceResult,
} from '../../misa/mod.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import { classifyObservation } from './observation_classifier.ts'

Deno.test('MeInvoiceObservationClassifier uses UNKNOWN labels for unrecognized numeric states', () => {
  const outcome = classifyObservation({
    result: MeInvoiceResult.ok([
      new MeInvoiceInvoiceStatus({
        transactionId: 'tx-1',
        publishStatus: 99,
        eInvoiceStatus: 88,
      }),
    ]),
    providerInvoiceReference: 'tx-1',
    now: new Date(Date.UTC(2026, 7, 31, 9)),
  })

  assertEquals(outcome.kind, 'found')
  if (outcome.kind === 'found') {
    assertEquals(outcome.providerStateCode, 'PS_99_ES_88')
    assertEquals(outcome.safeDescription, 'UNKNOWN_99')
  }
})

Deno.test('MeInvoiceObservationClassifier maps only allow-listed state fields into details snapshot', () => {
  const outcome = classifyObservation({
    result: MeInvoiceResult.ok([
      new MeInvoiceInvoiceStatus({
        transactionId: 'tx-1',
        publishStatus: 1,
        eInvoiceStatus: 2,
        referenceType: 1,
        sendTaxStatus: 0,
        invoiceCode: 'OK',
        invNo: '00000001',
        invSeries: '1C25TYY',
        publishedTime: new Date(Date.UTC(2026, 7, 31, 8)),
      }),
    ]),
    providerInvoiceReference: 'tx-1',
    now: new Date(Date.UTC(2026, 7, 31, 9)),
  })

  assertEquals(outcome.kind, 'found')
  if (outcome.kind === 'found') {
    assertEquals(Object.keys(outcome.detailsSnapshot), [
      'publishStatus',
      'eInvoiceStatus',
      'referenceType',
      'sendTaxStatus',
      'invoiceCode',
      'invNo',
      'invSeries',
      'publishedTime',
      'transactionId',
    ])
    assertEquals(outcome.providerStateCode, 'PS_1_ES_2')
    assertEquals(outcome.safeDescription, 'PUBLISHED')
  }
})

Deno.test('MeInvoiceObservationClassifier empty status payload maps to NOT_FOUND provider fact', () => {
  const outcome = classifyObservation({
    result: MeInvoiceResult.ok([]),
    providerInvoiceReference: 'tx-1',
    now: new Date(Date.UTC(2026, 7, 31, 9)),
  })

  assertEquals(outcome.kind, 'notFound')
  if (outcome.kind === 'notFound') {
    assertEquals(outcome.providerStateCode, 'NOT_FOUND')
    assertEquals(outcome.safeDescription, 'PROVIDER_STATUS_NOT_FOUND')
    assertEquals(outcome.providerReference, 'tx-1')
  }
})

Deno.test('MeInvoiceObservationClassifier identity mismatch maps to MISMATCH provider fact', () => {
  const outcome = classifyObservation({
    result: MeInvoiceResult.ok([
      new MeInvoiceInvoiceStatus({
        transactionId: 'tx-other',
        publishStatus: 1,
      }),
    ]),
    providerInvoiceReference: 'tx-1',
    now: new Date(Date.UTC(2026, 7, 31, 9)),
  })

  assertEquals(outcome.kind, 'mismatch')
  if (outcome.kind === 'mismatch') {
    assertEquals(outcome.providerStateCode, 'MISMATCH')
    assertEquals(outcome.safeDescription, 'PROVIDER_IDENTITY_MISMATCH')
    assertEquals(outcome.providerReference, 'tx-1')
  }
})

Deno.test('MeInvoiceObservationClassifier transport failure throws ProviderCallAmbiguousException', () => {
  assertThrows(
    () =>
      classifyObservation({
        result: MeInvoiceResult.failed<MeInvoiceInvoiceStatus[]>('meinvoice_5xx'),
        providerInvoiceReference: 'tx-1',
        now: new Date(Date.UTC(2026, 7, 31, 9)),
      }),
    ProviderCallAmbiguousError,
  )
})

