export function allocateOldestFirst(orders, amountMinor) {
  let left = amountMinor; const out = [];
  for (const o of orders) {
    if (left <= 0) break;
    const a = Math.min(left, o.outstandingMinor);
    if (a > 0) { out.push({ id: o.id, allocatedMinor: a, outstandingAfterMinor: o.outstandingMinor - a }); left -= a; }
  }
  return out;
}
export function planReturnSettlement({ entitled, sourceOutstanding, candidates, selectedIds }) {
  const reduceOwnDebt = Math.min(entitled, sourceOutstanding);
  const remaining = entitled - reduceOwnDebt;
  const chosen = candidates.filter((c) => selectedIds.includes(c.id));
  const alloc = allocateOldestFirst(chosen, remaining);
  const offsets = candidates.map((c) => ({ id: c.id, amountMinor: alloc.find((a) => a.id === c.id)?.allocatedMinor ?? 0 }));
  const refund = remaining - offsets.reduce((s, o) => s + o.amountMinor, 0);
  return { reduceOwnDebt, remaining, offsets, refund, showOffsetBlock: candidates.length > 0 && remaining > 0 };
}
