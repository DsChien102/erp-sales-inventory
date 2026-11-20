export class CanonicalInvoiceIntegrityError extends Error {
  constructor(
    readonly attemptId: string,
    readonly reasonCode = 'COMMAND_INTEGRITY',
    message?: string,
  ) {
    super(message ?? reasonCode)
    this.name = 'CanonicalInvoiceIntegrityError'
  }
}

export class CanonicalValidationFault extends Error {
  constructor(
    readonly reasonCode: string,
    message?: string,
  ) {
    super(message ?? reasonCode)
    this.name = 'CanonicalValidationFault'
  }
}

