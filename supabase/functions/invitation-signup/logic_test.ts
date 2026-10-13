import { assertEquals } from 'jsr:@std/assert@1'
import {
  authCreateErrorOutcome,
  dbErrorOutcome,
  extractDbErrorCode,
  isPasswordValid,
  parseSignupRequest,
} from './logic.ts'

const valid = {
  token: ' k7p29xqm ',
  password: 'Password123@',
  given_name: ' Minh ',
  family_name: 'Tran',
  phone: ' 0900000000 ',
  idempotency_key: 'register-from-invitation-1',
}

Deno.test('parseSignupRequest normalizes a valid request', () => {
  const result = parseSignupRequest(valid)
  assertEquals(result, {
    ok: true,
    value: {
      token: 'K7P29XQM',
      password: 'Password123@',
      givenName: 'Minh',
      familyName: 'Tran',
      phone: '0900000000',
      idempotencyKey: 'register-from-invitation-1',
    },
  })
})

Deno.test('parseSignupRequest treats a missing phone as null', () => {
  const result = parseSignupRequest({ ...valid, phone: undefined })
  assertEquals(result.ok && result.value.phone, null)
})

Deno.test('parseSignupRequest rejects invalid input', () => {
  const cases: Record<string, unknown> = {
    'not an object': 'K7P29XQM',
    'null body': null,
    'token too short': { ...valid, token: 'K7P29XQ' },
    'token too long': { ...valid, token: 'K7P29XQM9' },
    'token missing': { ...valid, token: undefined },
    'blank given name': { ...valid, given_name: '   ' },
    'missing family name': { ...valid, family_name: undefined },
    'short password': { ...valid, password: 'Ab1@' },
    'password without digit': { ...valid, password: 'Password@@@' },
    'password without special': { ...valid, password: 'Password1234' },
    'password not a string': { ...valid, password: 12345678 },
    'blank idempotency key': { ...valid, idempotency_key: ' ' },
  }
  for (const [name, body] of Object.entries(cases)) {
    assertEquals(parseSignupRequest(body), { ok: false }, name)
  }
})

Deno.test('isPasswordValid follows the app PasswordPolicy', () => {
  assertEquals(isPasswordValid('Abcdef1!'), true)
  assertEquals(isPasswordValid('abcdefg1'), false)
  assertEquals(isPasswordValid('abcdefg!'), false)
  assertEquals(isPasswordValid('a1!'), false)
})

Deno.test('extractDbErrorCode reads the business code from the RPC message', () => {
  assertEquals(extractDbErrorCode('INVITATION_EXPIRED'), 'INVITATION_EXPIRED')
  assertEquals(extractDbErrorCode('INVITATION_ALREADY_USED: detail'), 'INVITATION_ALREADY_USED')
  assertEquals(extractDbErrorCode('permission denied for function accept_invitation'), 'SYSTEM_ERROR')
  assertEquals(extractDbErrorCode(''), 'SYSTEM_ERROR')
  assertEquals(extractDbErrorCode(null), 'SYSTEM_ERROR')
})

Deno.test('dbErrorOutcome is 400 for business codes and 500 otherwise', () => {
  assertEquals(dbErrorOutcome('INVITATION_TOKEN_INVALID'), { status: 400, code: 'INVITATION_TOKEN_INVALID' })
  assertEquals(dbErrorOutcome('permission denied'), { status: 500, code: 'SYSTEM_ERROR' })
})

Deno.test('authCreateErrorOutcome maps Auth admin errors', () => {
  assertEquals(authCreateErrorOutcome({ code: 'email_exists' }), { status: 409, code: 'ACCOUNT_EXISTS' })
  assertEquals(authCreateErrorOutcome({ code: 'user_already_exists' }), { status: 409, code: 'ACCOUNT_EXISTS' })
  assertEquals(authCreateErrorOutcome({ code: 'weak_password' }), { status: 400, code: 'WEAK_PASSWORD' })
  assertEquals(authCreateErrorOutcome({ code: 'unexpected_failure' }), { status: 500, code: 'SYSTEM_ERROR' })
  assertEquals(authCreateErrorOutcome(null), { status: 500, code: 'SYSTEM_ERROR' })
})
