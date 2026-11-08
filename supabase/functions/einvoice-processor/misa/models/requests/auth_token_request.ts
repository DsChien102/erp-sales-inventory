/** POST `/auth/token` body (§2). */
export class MeInvoiceAuthTokenRequest {
  constructor(
    readonly appId: string,
    readonly taxCode: string,
    readonly username: string,
    readonly password: string,
  ) {}

  toJson(): Record<string, unknown> {
    return { appid: this.appId, taxcode: this.taxCode, username: this.username, password: this.password }
  }
}
