// Chạy bộ câu thử của trợ lý "Hỏi Mosaic Retail" (AI-0 mục 9, trừ 15–17 đang hoãn).
//
//   SUPABASE_URL=… SUPABASE_ANON_KEY=… AI_EVAL_TENANT_ID=… \
//   AI_EVAL_OWNER_EMAIL=… AI_EVAL_OWNER_PASSWORD=… \
//   AI_EVAL_CASHIER_EMAIL=… AI_EVAL_CASHIER_PASSWORD=… \
//   AI_EVAL_SAN_PHAM_A="…" AI_EVAL_MA_DON="…" \
//   deno run --allow-env --allow-net --allow-read scripts/ai/run_eval.ts [scripts/ai/eval_questions_ai4.json]
//
// Tham số dòng lệnh (tuỳ chọn): đường dẫn bộ câu thử; bỏ trống = eval_questions.json.
// Trường `truoc` (mảng câu hỏi): chạy trước trong cùng hội thoại để thử câu nối tiếp.
// `trang_thai` có thể liệt kê nhiều giá trị chấp nhận, ngăn bằng "|".

// Tự động chấm: khớp công cụ + trạng thái. Đúng số: người dùng đối chiếu tay (cột cuối).
import { createClient } from 'npm:@supabase/supabase-js@2'

type Question = {
  id: number
  nguoi_hoi: 'chu' | 'thu_ngan'
  cau_hoi: string
  truoc?: string[]
  cong_cu: string[]
  trang_thai: string
  doi_chieu: string
}

function env(name: string): string {
  const v = Deno.env.get(name)
  if (!v) {
    console.error(`Thiếu biến môi trường ${name}`)
    Deno.exit(1)
  }
  return v
}

const url = env('SUPABASE_URL')
const anonKey = env('SUPABASE_ANON_KEY')
const tenantId = env('AI_EVAL_TENANT_ID')
const sanPhamA = env('AI_EVAL_SAN_PHAM_A')
const maDon = env('AI_EVAL_MA_DON')

async function login(email: string, password: string): Promise<string> {
  const client = createClient(url, anonKey, {
    auth: { persistSession: false },
  })
  const { data, error } = await client.auth.signInWithPassword({
    email,
    password,
  })
  if (error || !data.session) {
    throw new Error(`Đăng nhập thất bại (${email}): ${error?.message}`)
  }
  return data.session.access_token
}

const tokens = {
  chu: await login(env('AI_EVAL_OWNER_EMAIL'), env('AI_EVAL_OWNER_PASSWORD')),
  thu_ngan: await login(
    env('AI_EVAL_CASHIER_EMAIL'),
    env('AI_EVAL_CASHIER_PASSWORD'),
  ),
}

const questionsPath = Deno.args[0]
const questions: Question[] = JSON.parse(
  await Deno.readTextFile(
    questionsPath ? questionsPath : new URL('./eval_questions.json', import.meta.url),
  ),
)

type History = { role: 'user' | 'assistant'; text: string }[]

function fill(text: string): string {
  return text.replaceAll('{san_pham_a}', sanPhamA).replaceAll('{ma_don}', maDon)
}

async function ask(
  token: string,
  question: string,
  history: History,
): Promise<{ tools: string[]; status: string; answer: string; ms: number }> {
  const t0 = Date.now()
  try {
    const res = await fetch(`${url}/functions/v1/ai-assistant`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        apikey: anonKey,
      },
      body: JSON.stringify({ tenant_id: tenantId, question, history }),
    })
    const body = await res.json()
    return {
      tools: Array.isArray(body.cong_cu) ? body.cong_cu : [],
      status: body.trang_thai ?? `http_${res.status}`,
      answer: String(body.cau_tra_loi ?? JSON.stringify(body)),
      ms: Date.now() - t0,
    }
  } catch (e) {
    return {
      tools: [],
      status: 'loi_goi',
      answer: e instanceof Error ? e.message : String(e),
      ms: Date.now() - t0,
    }
  }
}

const sameSet = (a: string[], b: string[]) => {
  const x = [...new Set(a)].sort().join(',')
  const y = [...new Set(b)].sort().join(',')
  return x === y
}

let passed = 0
const timings: { id: number; ms: number }[] = []
const rows: string[] = []

for (const q of questions) {
  const question = fill(q.cau_hoi)
  const history: History = []
  for (const prev of q.truoc ?? []) {
    const r = await ask(tokens[q.nguoi_hoi], fill(prev), history)
    history.push({ role: 'user', text: fill(prev) }, { role: 'assistant', text: r.answer })
    timings.push({ id: q.id, ms: r.ms })
    await new Promise((res) => setTimeout(res, 1000))
  }
  const { tools: actualTools, status: actualStatus, answer, ms } = await ask(
    tokens[q.nguoi_hoi],
    question,
    history,
  )

  timings.push({ id: q.id, ms })
  const ok = sameSet(actualTools, q.cong_cu) && q.trang_thai.split('|').includes(actualStatus)
  if (ok) passed++
  rows.push(
    [
      `#${q.id} ${ok ? '✅' : '❌'} (${q.nguoi_hoi}) ${ms} ms`,
      `  Câu hỏi : ${question}`,
      `  Công cụ : mong đợi [${q.cong_cu.join(', ')}] / thực tế [${actualTools.join(', ')}]`,
      `  Trạng thái: mong đợi ${q.trang_thai} / thực tế ${actualStatus}`,
      `  Trả lời : ${answer}`,
      `  Đối chiếu số (người kiểm tay): ${q.doi_chieu}`,
    ].join('\n'),
  )
  console.log(rows[rows.length - 1] + '\n')
  await new Promise((r) => setTimeout(r, 1000))
}

console.log(`Tự động đạt: ${passed}/${questions.length}`)
const slowest = timings.reduce((a, b) => (b.ms > a.ms ? b : a), timings[0])
const avg = Math.round(timings.reduce((s, t) => s + t.ms, 0) / timings.length)
console.log(`Thời gian: TB ${avg} ms, chậm nhất ${slowest.ms} ms (câu #${slowest.id})`)
