import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import {
  FakeMeInvoiceClient,
  MeInvoiceDownloadDataType,
  MeInvoiceInvoiceDataPublished,
  MeInvoiceResult,
} from '../../misa/mod.ts'
import {
  CredentialsReader,
  CredentialsRow,
  TenantMisaClientFactory,
} from '../misa_client_factory.ts'
import { ProviderCallAmbiguousError } from './errors.ts'
import {
  createIssuedInvoiceProvider,
  IssuedInvoiceProvider,
} from './issued_invoice_provider.ts'
import { ProviderContext } from './outcomes.ts'

function context(over: Partial<ProviderContext> = {}): ProviderContext {
  return {
    tenantId: 't-1',
    providerConnectionId: 'pc-1',
    electronicInvoiceId: 'ei-1',
    providerInvoiceReference: 'tx-1',
    invoiceSeries: '1C26TYY',
    operationId: 'op-1',
    ...over,
  }
}

function setup(opts: {
  credentials?: CredentialsRow | null
  client?: FakeMeInvoiceClient
  now?: Date
} = {}): { provider: IssuedInvoiceProvider; fakeClient: FakeMeInvoiceClient } {
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
      appId: 'app',
      baseUrl: 'https://testapi.meinvoice.vn/api/integration',
      emailDeliveryEnabled: false,
      publishEnabled: false,
    },
    reader,
    () => fakeClient,
  )
  const provider = createIssuedInvoiceProvider({
    clients: factory,
    now: () => opts.now ?? new Date(Date.UTC(2026, 7, 31, 9)),
  })
  return { provider, fakeClient }
}

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter previewPublished receives transaction id and company tax code', async () => {
  const { provider, fakeClient } = setup()

  const outcome = await provider.fetchOfficialView(context())

  assertEquals(fakeClient.previewPublishedCount, 1)
  assertEquals(fakeClient.lastTransactionIds, ['tx-1'])
  assertEquals(fakeClient.lastCompanyTaxCode, '0101234567')
  assertEquals(outcome.kind, 'success')
  if (outcome.kind === 'success') {
    assertEquals(outcome.viewerUrl.includes('https://'), true)
    assertEquals(outcome.expiresAt, new Date(Date.UTC(2026, 7, 31, 9, 5)))
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter previewPublished sends MTT classification derived from invoice series', async () => {
  const { provider, fakeClient } = setup()

  await provider.fetchOfficialView(context({ invoiceSeries: '2C26MYY' }))

  assertEquals(fakeClient.lastPreviewPublishedQuery?.invoiceWithCode, true)
  assertEquals(fakeClient.lastPreviewPublishedQuery?.invoiceCalcu, true)
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter previewPublished sends non-MTT classification for regular series', async () => {
  const { provider, fakeClient } = setup()

  await provider.fetchOfficialView(context())

  assertEquals(fakeClient.lastPreviewPublishedQuery?.invoiceWithCode, true)
  assertEquals(fakeClient.lastPreviewPublishedQuery?.invoiceCalcu, false)
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter previewPublished is not called for malformed invoice series', async () => {
  const { provider, fakeClient } = setup()

  const outcome = await provider.fetchOfficialView(context({ invoiceSeries: '1C26XYY' }))

  assertEquals(fakeClient.previewPublishedCount, 0)
  assertEquals(outcome.kind, 'checkRequired')
  if (outcome.kind === 'checkRequired') {
    assertEquals(outcome.safeErrorCode, 'INVOICE_SERIES_INVALID')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter download receives transaction id, series query and PDF type', async () => {
  const { provider, fakeClient } = setup()

  const outcome = await provider.downloadDocument(context(), 'PDF')

  assertEquals(fakeClient.downloadCount, 1)
  assertEquals(fakeClient.lastTransactionIds, ['tx-1'])
  assertEquals(fakeClient.lastDownloadDataType, MeInvoiceDownloadDataType.pdf)
  assertEquals(fakeClient.lastDownloadQuery?.invoiceWithCode, true)
  assertEquals(fakeClient.lastDownloadQuery?.invoiceCalcu, false)
  assertEquals(outcome.kind, 'success')
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter download uses XML type when requested', async () => {
  const { provider, fakeClient } = setup()

  await provider.downloadDocument(context(), 'XML')

  assertEquals(fakeClient.lastDownloadDataType, MeInvoiceDownloadDataType.xml)
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter malformed series maps download to INVOICE_SERIES_INVALID without HTTP', async () => {
  const { provider, fakeClient } = setup()

  const outcome = await provider.downloadDocument(context({ invoiceSeries: '3C26TYY' }), 'PDF')

  assertEquals(fakeClient.downloadCount, 0)
  assertEquals(outcome.kind, 'checkRequired')
  if (outcome.kind === 'checkRequired') {
    assertEquals(outcome.safeErrorCode, 'INVOICE_SERIES_INVALID')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter malformed series maps observation to INVOICE_SERIES_INVALID without HTTP', async () => {
  const { provider, fakeClient } = setup()

  const outcome = await provider.observe(context({ invoiceSeries: '1C26XYY' }))

  assertEquals(fakeClient.getStatusCount, 0)
  assertEquals(outcome.kind, 'ambiguous')
  if (outcome.kind === 'ambiguous') {
    assertEquals(outcome.safeErrorCode, 'INVOICE_SERIES_INVALID')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter empty provider document maps to DOCUMENT_UNAVAILABLE', async () => {
  const fakeClient = new FakeMeInvoiceClient()
  fakeClient.enqueueDownloadResult(
    MeInvoiceResult.failed('meinvoice_download_empty_data'),
  )
  const { provider } = setup({ client: fakeClient })

  const outcome = await provider.downloadDocument(context(), 'PDF')

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.failureCode, 'DOCUMENT_UNAVAILABLE')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter malformed document bytes map to CHECK_REQUIRED', async () => {
  const fakeClient = new FakeMeInvoiceClient()
  fakeClient.enqueueDownloadResult(
    MeInvoiceResult.ok([
      new MeInvoiceInvoiceDataPublished(
        'tx-1',
        null,
        new Uint8Array([1, 2, 3]),
      ),
    ]),
  )
  const { provider } = setup({ client: fakeClient })

  const outcome = await provider.downloadDocument(context(), 'PDF')

  assertEquals(outcome.kind, 'checkRequired')
  if (outcome.kind === 'checkRequired') {
    assertEquals(outcome.safeErrorCode, 'DOCUMENT_CONTENT_INVALID')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter provider auth rejection maps to CHECK_REQUIRED', async () => {
  const fakeClient = new FakeMeInvoiceClient()
  fakeClient.enqueuePreviewPublishedResult(
    MeInvoiceResult.failed('missing_MISA_MEINVOICE_APP_ID'),
  )
  const { provider } = setup({ client: fakeClient })

  const outcome = await provider.fetchOfficialView(context())

  assertEquals(outcome.kind, 'checkRequired')
  if (outcome.kind === 'checkRequired') {
    assertEquals(outcome.safeErrorCode, 'PROVIDER_AUTH_FAILED')
  }
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter transport failure throws ProviderCallAmbiguousException', async () => {
  const fakeClient = new FakeMeInvoiceClient()
  fakeClient.enqueuePreviewPublishedResult(
    MeInvoiceResult.failed('meinvoice_5xx'),
  )
  const { provider } = setup({ client: fakeClient })

  await assertRejects(
    () => provider.fetchOfficialView(context()),
    ProviderCallAmbiguousError,
  )
})

Deno.test('MeInvoiceElectronicInvoiceProviderAdapter missing tax code maps to CHECK_REQUIRED without provider call', async () => {
  const { provider, fakeClient } = setup({
    credentials: {
      tax_code: '',
      username: 'user',
      password: 'pass',
      base_url: 'https://testapi.meinvoice.vn/api/integration',
    },
  })

  const outcome = await provider.fetchOfficialView(context())

  assertEquals(fakeClient.previewPublishedCount, 0)
  assertEquals(outcome.kind, 'checkRequired')
  if (outcome.kind === 'checkRequired') {
    assertEquals(outcome.safeErrorCode, 'PROVIDER_TAX_CODE_MISSING')
  }
})

