import { assertEquals } from 'jsr:@std/assert@1'
import { classifyPublish } from './publish_classifier.ts'
import {
  PUBLISH_UNDETERMINED_REASON,
} from './outcomes.ts'
import {
  MeInvoiceClient,
  MeInvoiceInvoiceData,
  MeInvoicePublishErrorCodes,
  MeInvoicePublishInvoiceResultItem,
  MeInvoicePublishRequest,
  MeInvoiceResult,
  MeInvoiceSignType,
} from '../../misa/mod.ts'
import { jsonResponse, mockFetch } from '../../misa/test_support.ts'

// 9 tests from me_invoice_publish_classifier_test.dart
Deno.test('MeInvoicePublishClassifier classifies InvalidInvSeries as definiteFailure', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-1',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-1',
        errorCode: 'InvalidInvSeries',
        descriptionErrorCode: 'bad series',
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'definiteFailure')
})

Deno.test('MeInvoicePublishClassifier classifies DuplicateInvoiceRefID as undetermined', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-1',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-1',
        transactionId: 'tx-1',
        invNo: '0000001',
        errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'DUPLICATE_INVOICE_REF_ID')
  }
})

Deno.test('MeInvoicePublishClassifier classifies HTTP client InvalidInvSeries response', async () => {
  const fetch = mockFetch((req) => {
    if (req.url.pathname.endsWith('/auth/token')) {
      return jsonResponse({ Success: true, Data: 'tok' })
    }
    return jsonResponse({
      success: true,
      publishInvoiceResult: [
        {
          RefID: 'key-1',
          ErrorCode: 'InvalidInvSeries',
          DescriptionErrorCode: 'bad series',
        },
      ],
    })
  })

  const client = new MeInvoiceClient(
    {
      baseUrl: 'https://meinvoice-test.misa.vn',
      appId: 'app',
      taxCode: '0100000000',
      username: 'user',
      password: 'secret',
    },
    fetch,
  )

  const result = await client.publish(
    new MeInvoicePublishRequest(MeInvoiceSignType.hsmWithCks, [
      new MeInvoiceInvoiceData({ refId: 'key-1', invSeries: '1C25TYY' }),
    ]),
  )

  const outcome = classifyPublish({
    idempotencyKey: 'key-1',
    result,
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(result.isSuccess, true)
  assertEquals(outcome.kind, 'definiteFailure')
})

function classifyItem(errorCode: string) {
  return classifyPublish({
    idempotencyKey: 'key-1',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-1',
        errorCode,
        descriptionErrorCode: 'desc',
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })
}

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA item là definiteFailure', () => {
  const codes = [
    'InvalidInvoiceData',
    'TaxRateInfo_VATRateName',
    'BuyerTaxCode_TaxCodeInvalid',
    'InvalidTaxCode',
    'InvalidInvoiceDate',
    'InvalidXMLContainEmoji',
    'InvoiceTemplateNotExist',
    'DeclarationNotExist',
    'InvalidDeclaration',
    'ExistDeclarationNotReceive',
    'InvoiceTemplateNotValidInDeclaration',
    'LicenseInfo_NotBuy',
    'LicenseInfo_OutOfInvoice',
    'LicenseInfo_Expired',
    'CallSignServiceFail',
  ]
  for (const code of codes) {
    const outcome = classifyItem(code)
    assertEquals(outcome.kind, 'definiteFailure', `expected definiteFailure for ${code}`)
    if (outcome.kind === 'definiteFailure') {
      assertEquals(outcome.providerCode, code)
    }
  }
})

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA item mã theo tiền tố là definiteFailure', () => {
  const codes = [
    'InvoiceDetail_ItemName',
    'RequireError_BuyerLegalName',
    'StockInTaxCode_NotInfo_1_StockInLegalName',
    'Invalid_[Invoice.TaxRateInfo]',
  ]
  for (const code of codes) {
    const outcome = classifyItem(code)
    assertEquals(outcome.kind, 'definiteFailure', `expected definiteFailure for ${code}`)
  }
})

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA item mã không rõ vẫn là undetermined', () => {
  const codes = [
    'Exception',
    'SignEsignHSMError',
    'SignSoftDream78Exception',
    'CreateInvoiceDataError',
    'DuplicateRefID',
    'SomeUnknownCode',
  ]
  for (const code of codes) {
    const outcome = classifyItem(code)
    assertEquals(outcome.kind, 'undetermined', `expected undetermined for ${code}`)
  }
})

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA envelope lỗi dữ liệu theo tiền tố là definiteFailure', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-1',
    result: MeInvoiceResult.failed('InvoiceDetail_Quantity: Số lượng không hợp lệ'),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'definiteFailure')
  if (outcome.kind === 'definiteFailure') {
    assertEquals(outcome.providerCode, 'InvoiceDetail_Quantity')
    assertEquals(outcome.providerMessage, 'Số lượng không hợp lệ')
  }
})

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA envelope LicenseInfo_Expired là definiteFailure', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-1',
    result: MeInvoiceResult.failed('LicenseInfo_Expired: hết hạn'),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'definiteFailure')
})

Deno.test('MeInvoicePublishClassifier — mã từ chối theo tài liệu MISA mã từ chối phát hành không lan sang isDefiniteFailure chung', () => {
  assertEquals(MeInvoicePublishErrorCodes.isDefiniteFailure('LicenseInfo_Expired'), false)
  assertEquals(MeInvoicePublishErrorCodes.isPublishRejection('LicenseInfo_Expired'), true)
})

// 4 tests from me_invoice_publish_classifier_th08_retry_test.dart
Deno.test('th08_hardening_retry — MeInvoicePublishClassifier InvoiceNumberNotCotinuous is retryable provider rejection', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-continuous',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-continuous',
        errorCode: MeInvoicePublishErrorCodes.invoiceNumberNotContinuous,
        descriptionErrorCode: 'gap in series',
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'retryableRejection')
  if (outcome.kind === 'retryableRejection') {
    assertEquals(outcome.providerCode, MeInvoicePublishErrorCodes.invoiceNumberNotContinuous)
    assertEquals(outcome.retryAfterSeconds, 5)
  }
})

Deno.test('th08_hardening_retry — MeInvoicePublishClassifier InvoiceDuplicated is reconcile-first undetermined', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-dup',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-dup',
        errorCode: MeInvoicePublishErrorCodes.invoiceDuplicated,
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, PUBLISH_UNDETERMINED_REASON.invoiceDuplicatedReconcileFirst)
  }
})

Deno.test('th08_hardening_retry — MeInvoicePublishClassifier DuplicateInvoiceRefID stays reconciliation-only undetermined', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-ref',
    result: MeInvoiceResult.ok([
      new MeInvoicePublishInvoiceResultItem({
        refId: 'key-ref',
        transactionId: 'tx-1',
        invNo: '0000001',
        errorCode: MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
      }),
    ]),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, PUBLISH_UNDETERMINED_REASON.duplicateInvoiceRefId)
  }
})

Deno.test('th08_hardening_retry — MeInvoicePublishClassifier transport timeout stays undetermined not retryable rejection', () => {
  const outcome = classifyPublish({
    idempotencyKey: 'key-timeout',
    result: MeInvoiceResult.failed('meinvoice_network_timeout'),
    canonicalInvoice: { invDate: '2026-08-01' },
  })

  assertEquals(outcome.kind, 'undetermined')
  if (outcome.kind === 'undetermined') {
    assertEquals(outcome.reasonCode, 'PROVIDER_TIMEOUT')
  }
})
