#!/usr/bin/env bash
# Verifies platform messaging discovery migration is applied (service_role RPC + view).
# Usage: SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... ./verify_supabase.sh
set -euo pipefail

: "${SUPABASE_URL:?Set SUPABASE_URL}"
: "${SUPABASE_SERVICE_ROLE_KEY:?Set SUPABASE_SERVICE_ROLE_KEY}"

echo "Checking platform.list_tenants_with_pending_messaging (service_role)..."
rpc_status=$(curl -s -o /tmp/v45_rpc_body.json -w "%{http_code}" \
  -X POST "${SUPABASE_URL}/rest/v1/rpc/list_tenants_with_pending_messaging" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept-Profile: platform" \
  -H "Content-Profile: platform" \
  -d '{"p_limit":1}')

if [[ "$rpc_status" != "200" ]]; then
  echo "FAIL: RPC returned HTTP ${rpc_status}"
  cat /tmp/v45_rpc_body.json
  exit 1
fi
echo "OK: RPC HTTP 200"

echo "Checking platform.messaging_backlog_stats view..."
view_status=$(curl -s -o /tmp/v45_view_body.json -w "%{http_code}" \
  "${SUPABASE_URL}/rest/v1/messaging_backlog_stats?select=module_schema&limit=1" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Accept-Profile: platform" \
  -H "Content-Profile: platform")

if [[ "$view_status" != "200" ]]; then
  echo "FAIL: view returned HTTP ${view_status}"
  cat /tmp/v45_view_body.json
  exit 1
fi
echo "OK: messaging_backlog_stats HTTP 200"
echo "Migration verify passed."
