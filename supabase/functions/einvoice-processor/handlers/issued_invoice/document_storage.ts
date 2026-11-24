import type { SupabaseClient } from 'npm:@supabase/supabase-js@2'
import { isZip, validateDocumentContent } from './document_content_policy.ts'
import type { DocumentType } from './outcomes.ts'

export interface DocumentBucket {
  upload(
    path: string,
    bytes: Uint8Array,
    contentType: string,
  ): Promise<'created' | 'duplicate'>
  download(path: string): Promise<Uint8Array>
}

export interface StoredDocument {
  storageReference: string
  checksum: string
  contentType: string
  fileName: string
  fileSize: number
}

export const DOCUMENT_BUCKET = 'einvoice-documents'

export async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const buffer = bytes.buffer.slice(
    bytes.byteOffset,
    bytes.byteOffset + bytes.byteLength,
  ) as ArrayBuffer
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
}

export function createDocumentStorage(bucket: DocumentBucket) {
  return {
    async store(i: {
      tenantId: string
      electronicInvoiceId: string
      documentType: DocumentType
      documentVersion: number
      bytes: Uint8Array
    }): Promise<StoredDocument> {
      const validationError = validateDocumentContent(i.documentType, i.bytes)
      if (validationError !== null) {
        throw new Error(`DOCUMENT_CONTENT_INVALID: ${validationError}`)
      }

      const checksum = await sha256Hex(i.bytes)
      const zip = isZip(i.bytes)
      const extension = i.documentType === 'PDF' ? 'pdf' : zip ? 'zip' : 'xml'
      const contentType = i.documentType === 'PDF'
        ? 'application/pdf'
        : zip
        ? 'application/zip'
        : 'application/xml'
      const fileName = `${checksum}.${extension}`
      const path =
        `${i.tenantId}/${i.electronicInvoiceId}/${i.documentType.toLowerCase()}/v${i.documentVersion}/${fileName}`

      const uploadResult = await bucket.upload(path, i.bytes, contentType)
      if (uploadResult === 'duplicate') {
        const existingBytes = await bucket.download(path)
        const existingChecksum = await sha256Hex(existingBytes)
        if (existingChecksum !== checksum) {
          throw new Error(
            `SYSTEM_ERROR: storage object checksum mismatch for ${path}`,
          )
        }
      }

      return {
        storageReference: path,
        checksum,
        contentType,
        fileName,
        fileSize: i.bytes.length,
      }
    },
  }
}

export function createSupabaseDocumentBucket(
  client: SupabaseClient,
  bucketName = DOCUMENT_BUCKET,
): DocumentBucket {
  const bucket = client.storage.from(bucketName)
  return {
    async upload(
      path: string,
      bytes: Uint8Array,
      contentType: string,
    ): Promise<'created' | 'duplicate'> {
      const { error } = await bucket.upload(path, bytes, {
        contentType,
        upsert: false,
      })
      if (!error) return 'created'

      const status = String(
        (error as { statusCode?: unknown; status?: unknown }).statusCode ??
          (error as { statusCode?: unknown; status?: unknown }).status ??
          '',
      )
      const msg = typeof error.message === 'string'
        ? error.message.toLowerCase()
        : ''
      if (
        status === '409' ||
        status === '400' ||
        msg.includes('duplicate') ||
        msg.includes('already exists')
      ) {
        return 'duplicate'
      }
      throw new Error('SYSTEM_ERROR: storage upload failed')
    },

    async download(path: string): Promise<Uint8Array> {
      const { data, error } = await bucket.download(path)
      if (error || !data) {
        throw new Error(
          `SYSTEM_ERROR: storage download failed for ${path}: ${
            error?.message ?? 'no data'
          }`,
        )
      }
      const buffer = await data.arrayBuffer()
      return new Uint8Array(buffer)
    },
  }
}
