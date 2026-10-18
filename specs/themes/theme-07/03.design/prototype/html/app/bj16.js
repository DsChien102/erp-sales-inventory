/* BJ-16 — Điều tra và đối soát sai lệch (UIF-16). Màn: SCR-078, SCR-079, SCR-080, SCR-081, SCR-082, SCR-083.
 *
 * Đích viết lại khi T7-P làm BJ-16: chuyển fixture + hàm dựng CUỐI CÙNG của các màn trên ra file này,
 * xoá các bản bị đè trong app/core.js, gộp bước sửa sau dựng (legacy) của BJ vào hàm dựng, rồi kiểm
 * `node tools/golden.mjs capture … UIF-16`. Trong lúc chờ, runtime của BJ nằm trong app/core.js.
 *
 * Hàm dựng hiện được định nghĩa ở: v310-audit-control-cluster.js, v350-flow-logic-correction.js.
 * Màn bị định nghĩa nhiều lần: SCR-079, SCR-080, SCR-081, SCR-082, SCR-083.
 */
