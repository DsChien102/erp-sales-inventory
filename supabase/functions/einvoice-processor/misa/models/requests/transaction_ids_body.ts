/** Encodes a list of transaction IDs as JSON array body (§7/§8/§11/§12). */
export function encodeTransactionIdsBody(transactionIds: string[]): string {
  return JSON.stringify(transactionIds)
}
