#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_DIR="${ROOT_DIR}/assets/data"
TARGET_FILE="${TARGET_DIR}/vn_administrative_units.json"
SOURCE_URL="https://raw.githubusercontent.com/thanglequoc/vietnamese-provinces-database/master/json/vn_only_simplified_json_generated_data_vn_units.json"

mkdir -p "${TARGET_DIR}"

echo "Downloading Vietnamese administrative units from ThangLeQuoc/vietnamese-provinces-database..."
curl -fsSL "${SOURCE_URL}" -o "${TARGET_FILE}"

python3 - <<'PY' "${TARGET_FILE}"
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)

if not isinstance(data, list):
    raise SystemExit("Expected top-level JSON array")

province_count = len(data)
ward_count = sum(len(p.get("Wards", [])) for p in data)
sample = data[0]

for key in ("Code", "FullName", "Wards"):
    if key not in sample:
        raise SystemExit(f"Missing province field: {key}")

ward = sample["Wards"][0]
for key in ("Code", "FullName", "ProvinceCode"):
    if key not in ward:
        raise SystemExit(f"Missing ward field: {key}")

print(f"OK: {province_count} provinces, {ward_count} wards -> {path}")
PY

echo "Done."
