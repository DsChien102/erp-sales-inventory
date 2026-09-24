---
id: EVD-FINAL-STRUCTURAL-VALIDATION-v3.10.1
type: evidence
theme: theme-07
title: "Final structural validation — template alignment with prototype runtime"
owner: HARNESS
status: FROZEN
---
# EVD-FINAL-STRUCTURAL-VALIDATION-v3.10.1 — Final structural validation

## 1. Đối tượng được kiểm tra

`VET45-Theme7-Harness-v3.10.1-template-aligned`.

## 2. Phạm vi

Kiểm định cấu trúc, trace/link, ID, frontmatter/YAML, source accounting và frozen HTML runtime v3.10.1 tại `03.design/prototype/html/`. Đây **không phải** vòng thay đổi hay tái phê duyệt business semantics.

## 3. Kết quả

| Check | Expected | Actual | Kết quả |
|---|---|---|---|
| `canonical_and_generated_links` | 0 broken | 0 | **PASS** |
| `frontmatter_parse` | 0 errors | 0 | **PASS** |
| `duplicate_ids` | 0 duplicates | 0 | **PASS** |
| `yaml_parse` | 0 errors | 0 | **PASS** |
| `prototype_runtime_present` | 2928 frozen runtime files under 03.design/prototype/html | 2928 | **PASS** |
| `runtime_index_sha256` | 9c2452f27e8df4ac5bd85684f22c06367e30050e390e513e1ec7be6c80c48ec3 | 9c2452f27e8df4ac5bd85684f22c06367e30050e390e513e1ec7be6c80c48ec3 | **PASS** |
| `runtime_manifest_sha256` | d180ea0cd3e35b8753c4e85137f159abbebdc36a5962ed691ae149d1bc060dca | d180ea0cd3e35b8753c4e85137f159abbebdc36a5962ed691ae149d1bc060dca | **PASS** |
| `runtime_index_local_dependencies` | 0 missing | 0 | **PASS** |
| `legacy_root_prototype` | False | False | **PASS** |
| `source_accounting` | 0 unmapped | 0 | **PASS** |
| `bj_count` | 17 | 17 | **PASS** |
| `uc_count` | 70 | 70 | **PASS** |
| `screen_count` | 89 | 89 | **PASS** |
| `entity_count` | 33 | 33 | **PASS** |

## 4. Prototype runtime

- Frozen runtime files: **2928**.
- Vị trí: `03.design/prototype/html/`.
- `index.html` SHA-256: `9c2452f27e8df4ac5bd85684f22c06367e30050e390e513e1ec7be6c80c48ec3`.
- `manifest.json` SHA-256: `d180ea0cd3e35b8753c4e85137f159abbebdc36a5962ed691ae149d1bc060dca`.
- Direct local dependency missing từ `index.html`: **0**.
- Folder legacy root `prototype/`: **không tồn tại**.

## 5. Inventory canonical

- Business Journey: **17**
- Use Case: **70**
- Behavioral Contract/supporting behavior files: **48**
- Domain Foundation: **4**
- Entity: **33**
- Screen Contract: **89**
- Aggregate: **16**
- Read Model: **10**
- SA / BE / FE Slice: **28 / 70 / 89**

## 6. Kết luận

**PASS** cho structural/template-alignment + prototype-runtime gate.
