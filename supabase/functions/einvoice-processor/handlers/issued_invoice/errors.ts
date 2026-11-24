export class ProviderCallAmbiguousError extends Error {
  constructor(readonly safeErrorCode: string, message?: string) {
    super(message ?? safeErrorCode)
    this.name = 'ProviderCallAmbiguousError'
  }
}

