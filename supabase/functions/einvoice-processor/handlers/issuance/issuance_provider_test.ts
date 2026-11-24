import { assertEquals, assertRejects, assertThrows } from 'jsr:@std/assert@1'
import {
  createIssuanceProvider,
  safePreviewFailureDetail,
} from './issuance_provider.ts'
import { CanonicalValidationFault } from './errors.ts'
import {
  CredentialsReader,
  CredentialsRow,
  TenantMisaClientFactory,
} from '../misa_client_factory.ts'
import {
  FakeMeInvoiceClient,
  MeInvoiceConfig,
  MeInvoiceInvoiceData,
  MeInvoiceInvoiceStatus,
  MeInvoicePublishErrorCodes,
  MeInvoicePublishInvoiceResultItem,
  MeInvoicePublishRequest,
  MeInvoiceResult,
  MeInvoiceStatusInputType,
} from '../../misa/mod.ts'

const testEnv = {
  appId: 'test-app-id',
  baseUrl: 'https://meinvoice-test.misa.vn',
  emailDeliveryEnabled: false,
  publishEnabled: false,
}

class FakeCredentialsReader implements CredentialsReader {
  constructor(private row: CredentialsRow | null = null, private shouldThrow: Error | null = null) {}

  setRow(row: CredentialsRow | null) {
    this.row = row
  }

  setThrow(err: Error | null) {
    this.shouldThrow = err
  }

  read(_tenantId: string): Promise<CredentialsRow | null> {
    if (this.shouldThrow) return Promise.reject(this.shouldThrow)
    return Promise.resolve(this.row)
  }
}

class ScriptedClient extends FakeMeInvoiceClient {
  previewUnpublishedResult?: MeInvoiceResult<string>
  publishResult?: MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>

  constructor(opts: { getStatusQueue?: MeInvoiceResult<MeInvoiceInvoiceStatus[]>[] } = {}) {
    super(opts)
  }

  override previewUnpublished(invoice: MeInvoiceInvoiceData): Promise<MeInvoiceResult<string>> {
    this.previewUnpublishedCount++
    this.lastPreviewInvoice = invoice
    if (this.previewUnpublishedResult) return Promise.resolve(this.previewUnpublishedResult)
    return super.previewUnpublished(invoice)
  }

  override publish(request: MeInvoicePublishRequest): Promise<MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>> {
    this.publishCount++
    this.lastPublishRequest = request
    if (this.publishResult) return Promise.resolve(this.publishResult)
    return super.publish(request)
  }
}

function sampleCanonicalInvoice(): Record<string, unknown> {
  return {
    refId: 'ref-100',
    invSeries: '1C25TYY',
    signType: 2,
    invDate: '2026-08-01',
    buyerLegalName: 'Công ty ABC',
    buyerAddress: 'Hà Nội',
    totalSaleAmountOc: 100000,
    totalSaleAmount: 100000,
    totalAmountWithoutVatOc: 100000,
    totalAmountWithoutVat: 100000,
    totalVatAmountOc: 10000,
    totalVatAmount: 10000,
    totalDiscountAmountOc: 0,
    totalDiscountAmount: 0,
    totalAmountOc: 110000,
    totalAmount: 110000,
    totalAmountInWords: 'Một trăm mười nghìn đồng',
    originalInvoiceDetail: [
      {
        itemType: 1,
        lineNumber: 1,
        sortOrder: 1,
        itemName: 'Dịch vụ khám',
        quantity: 1,
        unitPrice: 100000,
        amountOc: 100000,
        amount: 100000,
        amountWithoutVatOc: 100000,
        amountWithoutVat: 100000,
        vatRateName: '10%',
        vatAmountOc: 10000,
        vatAmount: 10000,
      },
    ],
    taxRateInfo: [
      {
        vatRateName: '10%',
        amountWithoutVatOc: 100000,
        vatAmountOc: 10000,
      },
    ],
  }
}

// 7 tests from me_invoice_provider_adapter_preview_test.dart
Deno.test('safePreviewFailureDetail extracts formatted message', () => {
  assertEquals(safePreviewFailureDetail(''), null)
  assertEquals(safePreviewFailureDetail('InvalidInvoiceData:'), null)
  assertEquals(safePreviewFailureDetail('InvalidInvoiceData: InvalidInvoiceData'), null)
  assertEquals(safePreviewFailureDetail('InvalidInvoiceData: Detail message'), 'Detail message')
  assertEquals(safePreviewFailureDetail('ErrorCode: Some detail'), 'Some detail')
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished successful preview returns viewerRef', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.previewUnpublishedResult = MeInvoiceResult.ok('https://meinvoice.vn/viewer/preview-uuid-12345')

  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(outcome.kind, 'success')
  if (outcome.kind === 'success') {
    assertEquals(outcome.viewerRef, 'https://meinvoice.vn/viewer/preview-uuid-12345')
  }
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished auth failure when credentials missing in database', async () => {
  const reader = new FakeCredentialsReader(null)
  const factory = new TenantMisaClientFactory(testEnv, reader)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(outcome.kind, 'authFailed')
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished auth failure when MISA auth/login fails', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'bad_user',
    password: 'bad_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.previewUnpublishedResult = MeInvoiceResult.failed('meinvoice_auth_rejected:InvalidCredentials')

  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(outcome.kind, 'authFailed')
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished provider unavailable on network/timeout error', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.previewUnpublishedResult = MeInvoiceResult.failed('meinvoice_network_timeout')

  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(outcome.kind, 'providerUnavailable')
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished rethrows mapped exception on RpcException', async () => {
  const reader = new FakeCredentialsReader(null, new Error('EINVOICE_PROVIDER_NOT_CONNECTED'))
  const factory = new TenantMisaClientFactory(testEnv, reader)
  const provider = createIssuanceProvider({ clients: factory })

  await assertRejects(
    () => provider.previewUnpublished('tenant-1', sampleCanonicalInvoice()),
    Error,
    'EINVOICE_PROVIDER_NOT_CONNECTED',
  )
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished logs a safe vendor reason when MISA rejects authentication', async () => {
  const logs: Array<{ event: string; data: Record<string, unknown> }> = []
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'secret_user',
    password: 'secret_password_123',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.previewUnpublishedResult = MeInvoiceResult.failed(
    'meinvoice_auth_rejected:InvalidCredentials: Wrong password',
  )

  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({
    clients: factory,
    log: (event: string, data: Record<string, unknown>) => logs.push({ event, data }),
  })

  const outcome = await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(outcome.kind, 'authFailed')
  assertEquals(logs.length, 1)
  assertEquals(logs[0].event, 'misa_preview_failed')
  assertEquals(logs[0].data.reason, 'InvalidCredentials')

  const serialized = JSON.stringify(logs)
  assertEquals(serialized.includes('secret_user'), false)
  assertEquals(serialized.includes('secret_password_123'), false)
})

Deno.test('MeInvoiceProviderAdapter.previewUnpublished uses new credentials when a connected tenant reconnects', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'user',
    password: 'old_password',
  })
  const createdConfigs: MeInvoiceConfig[] = []
  const factory = new TenantMisaClientFactory(testEnv, reader, (c) => {
    createdConfigs.push(c)
    const client = new ScriptedClient()
    client.previewUnpublishedResult = MeInvoiceResult.ok('https://meinvoice.vn/viewer/p1')
    return client
  })
  const provider = createIssuanceProvider({ clients: factory })

  await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(createdConfigs[0].password, 'old_password')

  // Reconnect with new password
  reader.setRow({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'user',
    password: 'new_password',
  })
  await provider.previewUnpublished('tenant-1', sampleCanonicalInvoice())
  assertEquals(createdConfigs.length, 2)
  assertEquals(createdConfigs[1].password, 'new_password')
})

// 11 tests from me_invoice_provider_adapter_publish_test.dart
Deno.test('MeInvoiceProviderAdapter.validateCanonical accepts a structurally valid canonical invoice', () => {
  const factory = new TenantMisaClientFactory(testEnv, new FakeCredentialsReader())
  const provider = createIssuanceProvider({ clients: factory })
  provider.validateCanonical(sampleCanonicalInvoice())
})

Deno.test('MeInvoiceProviderAdapter.validateCanonical throws when neither buyer name field is present', () => {
  const factory = new TenantMisaClientFactory(testEnv, new FakeCredentialsReader())
  const provider = createIssuanceProvider({ clients: factory })
  const invalid = sampleCanonicalInvoice()
  delete invalid.buyerLegalName
  delete invalid.buyerFullName

  const err = assertThrows(() => provider.validateCanonical(invalid), CanonicalValidationFault)
  assertEquals((err as CanonicalValidationFault).reasonCode, 'CANONICAL_MISSING_BUYER_NAME')
})

Deno.test('MeInvoiceProviderAdapter.publish throws CanonicalValidationFault on invalid canonical', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const factory = new TenantMisaClientFactory(testEnv, reader, () => new ScriptedClient())
  const provider = createIssuanceProvider({ clients: factory })
  const invalid = sampleCanonicalInvoice()
  delete invalid.buyerLegalName
  delete invalid.buyerFullName

  await assertRejects(
    () => provider.publish('tenant-1', invalid, 'attempt-key-42'),
    CanonicalValidationFault,
  )
})

Deno.test('MeInvoiceProviderAdapter.publish maps correlated success to MeInvoicePublishSuccess', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.ok([
    new MeInvoicePublishInvoiceResultItem({
      refId: 'attempt-key-42',
      transactionId: 'tx-success-1',
      invSeries: '1C25TYY',
      invNo: '0000042',
    }),
  ])
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'success')
  if (outcome.kind === 'success') {
    assertEquals(outcome.providerReference, 'tx-success-1')
    assertEquals(outcome.invoiceNumber, '0000042')
    assertEquals(outcome.invoiceSeries, '1C25TYY')
    assertEquals(outcome.safeProviderEvidence.refId, 'attempt-key-42')
  }
})

Deno.test('MeInvoiceProviderAdapter.publish maps explicit proven no-side-effect rejection to definiteFailure', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.ok([
    new MeInvoicePublishInvoiceResultItem({
      refId: 'attempt-key-42',
      errorCode: 'InvalidInvSeries',
      descriptionErrorCode: 'Invalid invoice series',
    }),
  ])
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.providerCode, 'InvalidInvSeries')
    assertEquals(outcome.providerMessage, 'Invalid invoice series')
  }
})

Deno.test('MeInvoiceProviderAdapter.publish maps timeout/network errors to undetermined', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.failed('meinvoice_network_timeout')
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'PROVIDER_TIMEOUT')
  }
})

Deno.test('MeInvoiceProviderAdapter.publish maps malformed response to undetermined', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.failed('meinvoice_invalid_response: not a json object')
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'PROVIDER_MALFORMED_RESPONSE')
  }
})

Deno.test('MeInvoiceProviderAdapter.publish maps uncorrelated RefID to undetermined', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.ok([
    new MeInvoicePublishInvoiceResultItem({
      refId: 'different-ref',
      transactionId: 'tx-1',
      invSeries: '1C25TYY',
      invNo: '0000001',
    }),
  ])
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'PROVIDER_UNCORRELATED_RESPONSE')
  }
})

Deno.test('MeInvoiceProviderAdapter.publish DuplicateInvoiceRefID with embedded invoice number stays undetermined', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  fakeClient.publishResult = MeInvoiceResult.ok([
    new MeInvoicePublishInvoiceResultItem({
      refId: 'attempt-key-42',
      transactionId: 'tx-dup',
      invSeries: '1C25TYY',
      invNo: '0000999',
      errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
      descriptionErrorCode: 'RefID already exists',
    }),
  ])
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.publish('tenant-1', sampleCanonicalInvoice(), 'attempt-key-42')
  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'DUPLICATE_INVOICE_REF_ID')
    assertEquals(outcome.safeProviderEvidence.invoiceNumber, '0000999')
    assertEquals(outcome.safeProviderEvidence.refId, 'attempt-key-42')
  }
})

Deno.test('MeInvoiceProviderAdapter.getStatus queries status by transaction id and derives query from invoice series', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient({
    getStatusQueue: [
      MeInvoiceResult.ok([
        new MeInvoiceInvoiceStatus({
          transactionId: 'tx-42',
          publishStatus: 1,
          invNo: '0000042',
          invSeries: '2C26MYY',
        }),
      ]),
    ],
  })
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.getStatus({
    tenantId: 'tenant-1',
    statusLookupKey: 'tx-42',
    invoiceSeries: '2C26MYY',
    idempotencyKey: 'attempt-key-42',
    payloadHash: 'hash-42',
    statusLookup: 'providerTransactionId',
  })

  assertEquals(fakeClient.getStatusCount, 1)
  assertEquals(fakeClient.lastTransactionIds, ['tx-42'])
  assertEquals(fakeClient.lastStatusInputType, MeInvoiceStatusInputType.transactionId)
  assertEquals(fakeClient.lastStatusQuery?.invoiceWithCode, true)
  assertEquals(fakeClient.lastStatusQuery?.invoiceCalcu, true)
  assertEquals(outcome.kind, 'success')
})

Deno.test('MeInvoiceProviderAdapter.getStatus malformed series maps to INVOICE_SERIES_INVALID without HTTP', async () => {
  const reader = new FakeCredentialsReader({
    base_url: 'https://meinvoice-test.misa.vn',
    tax_code: '0100000000',
    username: 'misa_user',
    password: 'misa_password',
  })
  const fakeClient = new ScriptedClient()
  const factory = new TenantMisaClientFactory(testEnv, reader, () => fakeClient)
  const provider = createIssuanceProvider({ clients: factory })

  const outcome = await provider.getStatus({
    tenantId: 'tenant-1',
    statusLookupKey: 'tx-42',
    invoiceSeries: '3C26TYY',
    idempotencyKey: 'attempt-key-42',
    payloadHash: 'hash-42',
    statusLookup: 'providerTransactionId',
  })

  assertEquals(fakeClient.getStatusCount, 0)
  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'INVOICE_SERIES_INVALID')
  }
})

