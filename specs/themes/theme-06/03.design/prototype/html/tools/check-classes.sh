#!/usr/bin/env bash
# In class có trong HTML do app/*.js sinh ra mà không có rule nào trong styles/*.css
cd "$(dirname "$0")/.."
grep -oh 'class="[^"]*"' app/*.js | sed 's/class="//; s/"$//' | tr ' ' '\n' | grep -E '^[a-z][a-z0-9_-]*$' | sort -u |
while read c; do grep -q "\.$c\b" styles/*.css shared/*.css || echo "KHÔNG CÓ RULE $c"; done
