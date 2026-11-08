import type { DocumentBucket } from './document_storage.ts'

export class FakeDocumentBucket implements DocumentBucket {
  readonly objects = new Map<string, Uint8Array>()
  lastPath: string | null = null
  lastContentType: string | null = null
  uploadCount = 0
  downloadCount = 0
  shouldThrowOnUpload: Error | null = null

  upload(
    path: string,
    bytes: Uint8Array,
    contentType: string,
  ): Promise<'created' | 'duplicate'> {
    this.uploadCount++
    this.lastPath = path
    this.lastContentType = contentType
    if (this.shouldThrowOnUpload) {
      return Promise.reject(this.shouldThrowOnUpload)
    }
    if (this.objects.has(path)) {
      return Promise.resolve('duplicate')
    }
    this.objects.set(path, bytes)
    return Promise.resolve('created')
  }

  download(path: string): Promise<Uint8Array> {
    this.downloadCount++
    const obj = this.objects.get(path)
    if (!obj) {
      return Promise.reject(new Error(`Not found: ${path}`))
    }
    return Promise.resolve(obj)
  }
}

