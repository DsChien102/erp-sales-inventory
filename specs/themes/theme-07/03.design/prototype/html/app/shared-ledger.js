/* Sổ kho chung (G3-4): một chỗ ghi biến động kho cho cả BJ-01 (tồn) và BJ-15 (thẻ kho).
 *
 * Nguồn gốc dữ liệu: BJ15_MOVES (bj15.js) là sổ biến động, bj01Products (bj01.js) là tồn theo sản phẩm / lô. Các BJ ghi kho (BJ-02, 05, 06, 07, 08, 09, 10, 11)
 * gọi t7Ledger.post đúng lúc GHI NHẬN (sau duyệt / xác nhận, không phải lúc gửi duyệt); post cộng vào tồn BJ-01 và thêm một dòng vào thẻ kho, rồi kiểm
 * cuối kỳ thẻ kho = tồn BJ-01 của sản phẩm (sai thì ném lỗi bất đồng bộ để golden đếm vào "lỗi JS").
 * Chỉ dựng cho các thao tác có trong SC_journey_* / SC_demo (plan G3 mục Q1): không đảo biến động khi từ chối / hủy, không nhiều kho.
 * Nạp sau bj01.js; BJ15_* chỉ được đọc lúc gọi (bj15.js nạp sau).
 */

const t7Ledger = (() => {
  const STATE_LABEL = { SELLABLE: "Bán được", QUARANTINE: "Cách ly", DAMAGED: "Hỏng", EXPIRED: "Hết hạn" };
  const posted = new Set();
  const stockFields = (p) => ({ physical: p.physical, eligible: p.eligible, reserved: p.reserved, available: p.available, eligibilityBreakdown: p.eligibilityBreakdown, latestPhysicalMovement: p.latestPhysicalMovement, lots: p.lots });
  const baseStock = new Map(bj01Products.map((p) => [p.id, structuredClone(stockFields(p))]));
  let baseMoves = null;

  const productOf = (ref) => bj01Products.find((p) => p.id === ref || p.code === ref || p.name === ref) || null;
  const labelOf = (state) => STATE_LABEL[state] || state;
  const addBreakdown = (p, reason, quantity) => {
    if (!quantity) return;
    const list = p.eligibilityBreakdown || (p.eligibilityBreakdown = []);
    const row = list.find((x) => x.reason === reason);
    if (row) row.quantity += quantity; else list.push({ reason, quantity });
    p.eligibilityBreakdown = list.filter((x) => x.quantity > 0);
  };

  // Một biến động: delta = đổi tồn vật lý; eligibleDelta = phần vào / ra khả dụng (mặc định: bằng delta nếu tình trạng "Bán được", ngược lại 0);
  // reservedDelta = đổi số đang giữ cho đơn (bàn giao đơn đã giữ thì giảm theo); notEligible = [{ reason, quantity }] đổi phần không bán được
  // (mặc định: phần delta không vào khả dụng, ghi theo tình trạng). key: khoá chống ghi hai lần cùng một thao tác.
  function post({ key = "", productId, lot = "", kind, doc, delta, state = "Bán được", eligibleDelta, reservedDelta = 0, notEligible, sourceFlow = "", opId = "", actor, note = "", at }) {
    if (key && posted.has(key)) return null;
    const p = productOf(productId);
    if (!p) return null;
    if (key) posted.add(key);
    baseMoves ??= BJ15_MOVES.length;
    const sellable = state === "Bán được";
    let dEligible = eligibleDelta ?? (sellable ? delta : 0);
    // Phần không bán được lấy ra mà BJ-01 không có đủ (fixture của BJ nguồn dựng riêng): phần thiếu lấy từ khả dụng để tồn không âm / không lệch.
    const outs = (notEligible ?? (delta - dEligible ? [{ reason: state, quantity: delta - dEligible }] : [])).map((x) => {
      if (x.quantity >= 0) return x;
      const have = (p.eligibilityBreakdown || []).find((b) => b.reason === x.reason)?.quantity || 0;
      if (have >= -x.quantity) return x;
      dEligible += x.quantity + have;
      return { ...x, quantity: -have };
    });
    p.physical += delta; p.eligible += dEligible;
    p.reserved = Math.max(0, p.reserved + reservedDelta);
    p.available = Math.max(0, p.eligible - p.reserved);
    outs.forEach((x) => addBreakdown(p, x.reason, x.quantity));
    if (p.tracking === "LOT" && lot) {
      const l = (p.lots || (p.lots = [])).find((x) => x.code === lot);
      if (l) { l.physical += delta; l.eligible += dEligible; if (l.physical <= 0) p.lots.splice(p.lots.indexOf(l), 1); }
      else if (delta > 0) p.lots.push({ code: lot, expiryDisplay: at?.expiry || "", expiryPrecision: "DAY", physical: delta, eligible: dEligible, stockState: "SELLABLE", expiryIndicator: "NONE", nearExpiryAction: null });
    }
    const n = posted.size;
    const hh = "20", mm = String(40 + (n % 19)).padStart(2, "0");
    const dm = BJ15_TODAY.slice(8, 10) + "/" + BJ15_TODAY.slice(5, 7);
    let id = `${doc}/${p.code}`, k = 1;
    while (BJ15_MOVES.some((m) => m.id === id)) id = `${doc}/${p.code}~${++k}`;
    BJ15_MOVES.push({
      id, seq: BJ15_MOVES.length, productId: p.id, lot: p.tracking === "LOT" ? lot : "", kind, doc, actor: actor || BJ15_AN, delta, state, sourceFlow, opId, note,
      business: `${dm}/2026`, recorded: `${dm}/2026 · ${hh}:${mm}`, bIso: BJ15_TODAY, rIso: BJ15_TODAY, rKey: `${BJ15_TODAY} ${hh}:${mm}`,
    });
    check(p);
    return id;
  }

  // Cuối kỳ thẻ kho tới hôm nay phải bằng tồn vật lý BJ-01 (sai: ném lỗi ở lượt sau để golden thấy).
  function check(p) {
    const end = bj15Ledger(p.id, { from: BJ15_DATA_START, to: BJ15_TODAY }).closing;
    if (end !== p.physical) { const msg = `t7Ledger: ${p.name} thẻ kho cuối kỳ ${end} ≠ tồn BJ-01 ${p.physical}`; console.error(msg); setTimeout(() => { throw new Error(msg); }, 0); return false; }
    if (p.eligible > p.physical || p.available > p.eligible || p.physical < 0 || p.eligible < 0) { const msg = `t7Ledger: ${p.name} tồn không hợp lệ (vật lý ${p.physical}, khả dụng ${p.eligible})`; console.error(msg); setTimeout(() => { throw new Error(msg); }, 0); return false; }
    return true;
  }

  // Về sổ gốc (golden / harness dựng lại ca mở thẳng): bỏ mọi biến động đã ghi và trả tồn BJ-01 về số gốc.
  function reset() {
    if (baseMoves != null) BJ15_MOVES.length = baseMoves;
    posted.clear();
    bj01Products.forEach((p) => Object.assign(p, structuredClone(baseStock.get(p.id))));
  }

  return { post, check, reset, productOf, labelOf, STATE_LABEL, posted };
})();

Object.assign(window.__VET45_QA__, { resetLedger: t7Ledger.reset, checkLedger: () => bj01Products.every((p) => t7Ledger.check(p)) });
