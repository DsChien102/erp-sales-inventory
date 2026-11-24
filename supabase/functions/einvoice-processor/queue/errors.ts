/** Thrown by the publish handler (7-E2) when the series lease is held by another command. */
export class PublishSeriesLeaseBusyError extends Error {
  constructor(readonly retryAfterSeconds: number) {
    super('publish_series_lease_busy')
    this.name = 'PublishSeriesLeaseBusyError'
  }
}

/** MISA did not answer: the command is retried by retry_or_dead_letter_internal_command. */
export class ProviderUnavailableError extends Error {
  constructor() {
    super('provider_unavailable')
    this.name = 'ProviderUnavailableError'
  }
}
