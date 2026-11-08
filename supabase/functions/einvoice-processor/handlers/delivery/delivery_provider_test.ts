import { assertEquals } from 'jsr:@std/assert@1'
import {
  FakeMeInvoiceClient,
  MeInvoiceResult,
} from '../../misa/mod.ts'
import {
  type CredentialsReader,
  type CredentialsRow,
  TenantMisaClientFactory,
} from '../misa_client_factory.ts'
import {
  createDeliveryProvider,
  type DeliveryProvider,
} from './delivery_provider.ts'
import type { DeliveryProviderContext } from './outcomes.ts'

function context(over: Partial<DeliveryProviderContext> = {}): DeliveryProviderContext {
  return {
    tenantId: 'tenant-1',
    providerConnectionId: 'conn-1',
    providerTransactionId: 'tx-delivery-1',
    invoiceSeries: '1C25TYY',
    recipientEmail: 'buyer@example.com',
    recipientName: 'Buyer Name',
    ...over,
  }
}

function setup(opts: {
  credentials?: CredentialsRow | null
  client?: FakeMeInvoiceClient
} = {}): { provider: DeliveryProvider; fakeClient: FakeMeInvoiceClient } {
  const fakeClient = opts.client ?? new FakeMeInvoiceClient()
  const reader: CredentialsReader = {
    read: (_t) =>
      Promise.resolve(
        opts.credentials !== undefined
          ? opts.credentials
          : {
            tax_code: '0101234567',
            username: 'user',
            password: 'pass',
            base_url: 'https://testapi.meinvoice.vn/api/integration',
          },
      ),
  }
  const factory = new TenantMisaClientFactory(
    {
      appId: 'app-id',
      baseUrl: 'https://testapi.meinvoice.vn/api/integration',
      emailDeliveryEnabled: false,
    },
    reader,
    () => fakeClient,
  )
  const provider = createDeliveryProvider({
    clients: factory,
  })
  return { provider, fakeClient }
}

Deno.test(
  'MeInvoiceDeliveryProviderAdapter selects tenant client and maps transaction, receiver, and series flags',
  async () => {
    const { provider, fakeClient } = setup()

    const outcome = await provider.sendEmail(context())

    assertEquals(fakeClient.sendEmailCount, 1)
    const request = fakeClient.lastSendEmailRequest
    assertEquals(request !== null, true)
    assertEquals(request!.isInvoiceCode, true)
    assertEquals(request!.isInvoiceCalculatingMachine, false)
    assertEquals(request!.sendEmailDatas.length, 1)
    const data = request!.sendEmailDatas[0]
    assertEquals(data.transactionId, 'tx-delivery-1')
    assertEquals(data.receiverEmail, 'buyer@example.com')
    assertEquals(data.receiverName, 'Buyer Name')
    assertEquals(outcome.kind, 'succeeded')
    if (outcome.kind === 'succeeded') {
      assertEquals(outcome.providerReference, 'tx-delivery-1')
    }
  },
)

Deno.test('MeInvoiceDeliveryProviderAdapter derives calculating-machine flag from MTT invoice series', async () => {
  const { provider, fakeClient } = setup()

  await provider.sendEmail(context({ invoiceSeries: '2C26MYY' }))

  const request = fakeClient.lastSendEmailRequest!
  assertEquals(request.isInvoiceCode, true)
  assertEquals(request.isInvoiceCalculatingMachine, true)
})

Deno.test(
  'MeInvoiceDeliveryProviderAdapter malformed series maps to INVOICE_SERIES_INVALID without HTTP',
  async () => {
    const { provider, fakeClient } = setup()

    const outcome = await provider.sendEmail(
      context({ invoiceSeries: '1X26TYY' }),
    )

    assertEquals(fakeClient.sendEmailCount, 0)
    assertEquals(outcome.kind, 'definiteFailure')
    if (outcome.kind === 'definiteFailure') {
      assertEquals(outcome.safeErrorCode, 'INVOICE_SERIES_INVALID')
    }
  },
)

Deno.test(
  'MeInvoiceDeliveryProviderAdapter missing credentials maps to DefiniteFailure without provider call',
  async () => {
    const { provider, fakeClient } = setup({ credentials: null })

    const outcome = await provider.sendEmail(context())

    assertEquals(fakeClient.sendEmailCount, 0)
    assertEquals(outcome.kind, 'definiteFailure')
    if (outcome.kind === 'definiteFailure') {
      assertEquals(outcome.safeErrorCode, 'PROVIDER_AUTH_FAILED')
    }
  },
)

Deno.test(
  'MeInvoiceDeliveryProviderAdapter envelope acknowledgement maps to Succeeded with provider reference',
  async () => {
    const { provider, fakeClient } = setup()
    fakeClient.enqueueSendEmailEnvelopeAcknowledgement()

    const outcome = await provider.sendEmail(context())

    assertEquals(outcome.kind, 'succeeded')
    if (outcome.kind === 'succeeded') {
      assertEquals(outcome.providerReference, 'tx-delivery-1')
    }
  },
)

Deno.test('MeInvoiceDeliveryProviderAdapter does not leak raw provider message into outcomes', async () => {
  const { provider, fakeClient } = setup()
  fakeClient.enqueueSendEmailResult(
    MeInvoiceResult.failed(
      'InvalidData: RAW BODY buyer@example.com exception stack',
    ),
  )

  const outcome = await provider.sendEmail(context())

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    const code = outcome.safeErrorCode
    assertEquals(code, 'InvalidData')
    assertEquals(code.includes('RAW'), false)
    assertEquals(code.includes('@'), false)
    assertEquals(code.includes('exception'), false)
  }
})

Deno.test('MeInvoiceDeliveryProviderAdapter never calls getStatus', async () => {
  const { provider, fakeClient } = setup()

  await provider.sendEmail(context())

  assertEquals(fakeClient.getStatusCount, 0)
  assertEquals(fakeClient.sendEmailCount, 1)
})
