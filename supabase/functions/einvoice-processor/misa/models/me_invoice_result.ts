/** Typed result for meInvoice client calls (ok / failed). */
export class MeInvoiceResult<T> {
  private constructor(
    readonly data: T | null,
    readonly error: string | null,
    readonly rateLimited: boolean,
  ) {}

  static ok<T>(data: T): MeInvoiceResult<T> {
    return new MeInvoiceResult<T>(data, null, false)
  }

  static failed<T>(error: string, opts: { rateLimited?: boolean } = {}): MeInvoiceResult<T> {
    return new MeInvoiceResult<T>(null, error, opts.rateLimited ?? false)
  }

  get isSuccess(): boolean {
    return this.data !== null && this.error === null
  }
}
