import { assertEquals } from 'jsr:@std/assert@1'
import {
  MeInvoiceResult,
  MeInvoiceSendEmailResponse,
  MeInvoiceSendEmailResultItem,
} from '../../misa/mod.ts'
import { classifyDelivery } from './delivery_classifier.ts'

function itemizedOk(
  items: MeInvoiceSendEmailResultItem[],
): MeInvoiceResult<MeInvoiceSendEmailResponse> {
  return MeInvoiceResult.ok(MeInvoiceSendEmailResponse.itemized(items))
}

function item(
  transactionId: string | null = null,
  sendEmailStatus: number | null = null,
  errorCode: string | null = null,
): MeInvoiceSendEmailResultItem {
  return new MeInvoiceSendEmailResultItem(
    transactionId,
    null,
    null,
    sendEmailStatus,
    errorCode,
  )
}

Deno.test('MeInvoiceDeliveryClassifier envelope acknowledgement maps to Succeeded', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.ok(MeInvoiceSendEmailResponse.envelopeAcknowledgement()),
    'tx-1',
  )

  assertEquals(outcome.kind, 'succeeded')
  if (outcome.kind === 'succeeded') {
    assertEquals(outcome.providerReference, null)
  }
})

Deno.test('MeInvoiceDeliveryClassifier matched status 3 without error maps to Succeeded', () => {
  const outcome = classifyDelivery(
    itemizedOk([item('tx-1', 3)]),
    'tx-1',
  )

  assertEquals(outcome.kind, 'succeeded')
  if (outcome.kind === 'succeeded') {
    assertEquals(outcome.providerReference, null)
  }
})

for (const status of [0, 1, 2, 3, 4, 99, null]) {
  Deno.test(`MeInvoiceDeliveryClassifier status ${status} is classified without assuming acceptance is sent`, () => {
    const outcome = classifyDelivery(
      itemizedOk([item('tx-1', status)]),
      'tx-1',
    )
    const expectedKind = status === 3
      ? 'succeeded'
      : status === 2
      ? 'definiteFailure'
      : 'undetermined'
    assertEquals(outcome.kind, expectedKind)
  })
}

const ambiguousItemSets: { name: string; items: MeInvoiceSendEmailResultItem[] }[] = [
  { name: 'empty', items: [] },
  {
    name: 'wrong transaction',
    items: [item('wrong', 3)],
  },
  {
    name: 'status 3 with error',
    items: [item('tx-1', 3, 'InvalidData')],
  },
  {
    name: 'multiple items',
    items: [item('tx-1', 3), item('tx-1', 2)],
  },
]

for (const set of ambiguousItemSets) {
  Deno.test(`MeInvoiceDeliveryClassifier ambiguous per-invoice results are undetermined ${set.name}`, () => {
    const outcome = classifyDelivery(
      itemizedOk(set.items),
      'tx-1',
    )
    assertEquals(outcome.kind, 'undetermined')
  })
}

Deno.test('MeInvoiceDeliveryClassifier auth credential rejection maps to DefiniteFailure', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('missing_MISA_MEINVOICE_APP_ID'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.safeErrorCode, 'PROVIDER_AUTH_FAILED')
  }
})

Deno.test('MeInvoiceDeliveryClassifier TokenExpiredCode maps to DefiniteFailure', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('TokenExpiredCode'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.safeErrorCode, 'PROVIDER_AUTH_FAILED')
  }
})

Deno.test('MeInvoiceDeliveryClassifier validation business rejection maps to DefiniteFailure with safe code', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('InvalidData: raw vendor message with secrets'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.safeErrorCode, 'InvalidData')
  }
})

Deno.test('MeInvoiceDeliveryClassifier 429 rateLimited before acceptance maps to RetryableFailure', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_429_rate_limited', {
      rateLimited: true,
    }),
    'tx-1',
  )

  assertEquals(outcome.kind, 'retryableFailure')
  if (outcome.kind === 'retryableFailure') {
    assertEquals(outcome.safeErrorCode, 'meinvoice_429_rate_limited')
  }
})

Deno.test('MeInvoiceDeliveryClassifier timeout maps to Undetermined', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_network_timeout'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
})

Deno.test('MeInvoiceDeliveryClassifier connection loss maps to Undetermined', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_network: connection reset'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
})

Deno.test('MeInvoiceDeliveryClassifier 5xx maps to Undetermined', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_5xx'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
})

Deno.test('MeInvoiceDeliveryClassifier malformed response maps to Undetermined', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_invalid_response: not a json object'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
})

Deno.test('MeInvoiceDeliveryClassifier unknown provider codes default to Undetermined never definite', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('WeirdVendorCode: do not treat as definite'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.safeErrorCode, 'WeirdVendorCode')
  }
})

Deno.test('MeInvoiceDeliveryClassifier codes containing auth/forbidden but not on allowlist stay Undetermined', () => {
  for (const code of [
    'AuthorizationPending',
    'ForbiddenThing',
    'auth_soft_fail',
    'reauth_required_hint',
  ]) {
    const outcome = classifyDelivery(
      MeInvoiceResult.failed(code),
      'tx-1',
    )

    assertEquals(
      outcome.kind,
      'undetermined',
      `${code} must not become DefiniteFailure via substring`,
    )
  }
})

Deno.test('MeInvoiceDeliveryClassifier wrapped meinvoice_401: UnAuthorize maps via closed vendor-token allowlist', () => {
  const outcome = classifyDelivery(
    MeInvoiceResult.failed('meinvoice_401: UnAuthorize'),
    'tx-1',
  )

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.safeErrorCode, 'PROVIDER_AUTH_FAILED')
  }
})

Deno.test('MeInvoiceDeliveryClassifier success with unexpected data shape is Undetermined', () => {
  const outcome = classifyDelivery(
    itemizedOk([]),
    'tx-1',
  )

  assertEquals(outcome.kind, 'undetermined')
})
