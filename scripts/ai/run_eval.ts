// Chạy bộ câu thử của trợ lý "Hỏi VET45" (AI-0 mục 9, trừ 15–17 đang hoãn).
//
//   SUPABASE_URL=… SUPABASE_ANON_KEY=… AI_EVAL_TENANT_ID=… \
//   AI_EVAL_OWNER_EMAIL=… AI_EVAL_OWNER_PASSWORD=… \
//   AI_EVAL_CASHIER_EMAIL=… AI_EVAL_CASHIER_PASSWORD=… \
//   AI_EVAL_SAN_PHAM_A="…" AI_EVAL_MA_DON="…" \
//   deno run --allow-env --allow-net --allow-read scripts/ai/run_eval.ts
//
// Tự động chấm: khớp công cụ + trạng thái. Đúng số: người dùng đối chiếu tay (cột cuối).
import { createClient } from 'npm:@supabase/supabase-js@2'

type Question = {
  id: number
  nguoi_hoi: 'chu' | 'thu_ngan'
  cau_hoi: string
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

const questions: Question[] = JSON.parse(
  await Deno.readTextFile(new URL('./eval_questions.json', import.meta.url)),
)

const sameSet = (a: string[], b: string[]) => {
  const x = [...new Set(a)].sort().join(',')
  const y = [...new Set(b)].sort().join(',')
  return x === y
}

let passed = 0
const rows: string[] = []

for (const q of questions) {
  const question = q.cau_hoi.replaceAll('{san_pham_a}', sanPhamA).replaceAll(
    '{ma_don}',
    maDon,
  )
  let actualTools: string[] = []
  let actualStatus = 'loi_goi'
  let answer = ''
  try {
    const res = await fetch(`${url}/functions/v1/ai-assistant`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokens[q.nguoi_hoi]}`,
        apikey: anonKey,
      },
      body: JSON.stringify({ tenant_id: tenantId, question }),
    })
    const body = await res.json()
    actualTools = Array.isArray(body.cong_cu) ? body.cong_cu : []
    actualStatus = body.trang_thai ?? `http_${res.status}`
    answer = String(body.cau_tra_loi ?? JSON.stringify(body))
  } catch (e) {
    answer = e instanceof Error ? e.message : String(e)
  }

  const ok = sameSet(actualTools, q.cong_cu) && actualStatus === q.trang_thai
  if (ok) passed++
  rows.push(
    [
      `#${q.id} ${ok ? '✅' : '❌'} (${q.nguoi_hoi})`,
      `  Câu hỏi : ${question}`,
      `  Công cụ : mong đợi [${q.cong_cu.join(', ')}] / thực tế [${actualTools.join(', ')}]`,
      `  Trạng thái: mong đợi ${q.trang_thai} / thực tế ${actualStatus}`,
      `  Trả lời : ${answer}`,
      `  Đối chiếu số (người kiểm tay): ${q.doi_chieu}`,
    ].join('\n'),
  )
  console.log(rows[rows.length - 1] + '\n')
  await new Promise((r) => setTimeout(r, 5000)) // tránh chạm hạn mức theo phút của Gemini
}

console.log(`Tự động đạt: ${passed}/${questions.length}`)
