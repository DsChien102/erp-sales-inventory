export type FetchLike = (input: string | URL | Request, init?: RequestInit) => Promise<Response>

/** Port of Dart `TimeoutException`. */
export class TimeoutException extends Error {
  constructor() {
    super('Future not completed')
    this.name = 'TimeoutException'
  }
}

/**
 * Runs `run` with an AbortSignal and rejects with TimeoutException after `ms`.
 * The race guarantees the timeout even when the underlying fetch ignores the signal.
 */
export async function withTimeout<T>(ms: number, run: (signal: AbortSignal) => Promise<T>): Promise<T> {
  const controller = new AbortController()
  let timer: ReturnType<typeof setTimeout> | undefined
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      controller.abort()
      reject(new TimeoutException())
    }, ms)
  })
  try {
    return await Promise.race([run(controller.signal), timeout])
  } finally {
    clearTimeout(timer)
  }
}
