import { assertEquals, assertRejects } from 'jsr:@std/assert@1'
import {
  createDocumentStorage,
  sha256Hex,
} from './document_storage.ts'
import { FakeDocumentBucket } from './fake_bucket.ts'

function pdfBytes(): Uint8Array {
  return new TextEncoder().encode('%PDF-1.4 test')
}

Deno.test('SupabaseInvoiceDocumentStoragePort uploads to deterministic path with checksum and MIME mapping', async () => {
  const fake = new FakeDocumentBucket()
  const storage = createDocumentStorage(fake)
  const bytes = pdfBytes()
  const checksum = await sha256Hex(bytes)
  assertEquals(
    checksum,
    'd663640088750cf16276d623c2588d7233f2b84b45f4b2e20832f47b16aa5618',
  )

  const stored = await storage.store({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'invoice-1',
    documentType: 'PDF',
    documentVersion: 2,
    bytes,
  })

  assertEquals(fake.lastPath, `tenant-1/invoice-1/pdf/v2/${checksum}.pdf`)
  assertEquals(fake.lastContentType, 'application/pdf')
  assertEquals(stored.storageReference, fake.lastPath)
  assertEquals(stored.checksum, checksum)
  assertEquals(stored.fileName, `${checksum}.pdf`)
  assertEquals(stored.fileSize, bytes.length)
  assertEquals(stored.contentType, 'application/pdf')
})

Deno.test('SupabaseInvoiceDocumentStoragePort reuses existing object when deterministic path already exists', async () => {
  const fake = new FakeDocumentBucket()
  const storage = createDocumentStorage(fake)
  const bytes = pdfBytes()

  const first = await storage.store({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'invoice-1',
    documentType: 'PDF',
    documentVersion: 1,
    bytes,
  })
  const second = await storage.store({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'invoice-1',
    documentType: 'PDF',
    documentVersion: 1,
    bytes,
  })

  assertEquals(second.storageReference, first.storageReference)
  assertEquals(second.checksum, first.checksum)
  assertEquals(fake.uploadCount, 2)
  assertEquals(fake.downloadCount, 1)
})

Deno.test('SupabaseInvoiceDocumentStoragePort rejects invalid content before upload', async () => {
  const fake = new FakeDocumentBucket()
  const storage = createDocumentStorage(fake)

  await assertRejects(
    () =>
      storage.store({
        tenantId: 'tenant-1',
        electronicInvoiceId: 'invoice-1',
        documentType: 'PDF',
        documentVersion: 1,
        bytes: new Uint8Array([1, 2, 3]),
      }),
    Error,
    'DOCUMENT_CONTENT_INVALID',
  )
  assertEquals(fake.lastPath, null)
  assertEquals(fake.uploadCount, 0)
})

Deno.test('stores zipped XML with zip extension and application/zip', async () => {
  const fake = new FakeDocumentBucket()
  const storage = createDocumentStorage(fake)
  const zipBytes = new Uint8Array([0x50, 0x4B, 0x03, 0x04, 0x14, 0x00, 0x08])
  const checksum = await sha256Hex(zipBytes)

  const stored = await storage.store({
    tenantId: 'tenant-1',
    electronicInvoiceId: 'invoice-1',
    documentType: 'XML',
    documentVersion: 1,
    bytes: zipBytes,
  })

  assertEquals(fake.lastPath, `tenant-1/invoice-1/xml/v1/${checksum}.zip`)
  assertEquals(fake.lastContentType, 'application/zip')
  assertEquals(stored.contentType, 'application/zip')
  assertEquals(stored.fileName, `${checksum}.zip`)
})

Deno.test('throws checksum mismatch when existing object differs', async () => {
  const fake = new FakeDocumentBucket()
  const bytes = pdfBytes()
  const checksum = await sha256Hex(bytes)
  const path = `tenant-1/invoice-1/pdf/v1/${checksum}.pdf`
  // Pre-seed bucket with different bytes at the exact deterministic path
  fake.objects.set(path, new TextEncoder().encode('%PDF-1.4 different-bytes'))

  const storage = createDocumentStorage(fake)

  await assertRejects(
    () =>
      storage.store({
        tenantId: 'tenant-1',
        electronicInvoiceId: 'invoice-1',
        documentType: 'PDF',
        documentVersion: 1,
        bytes,
      }),
    Error,
    `SYSTEM_ERROR: storage object checksum mismatch for ${path}`,
  )
})
