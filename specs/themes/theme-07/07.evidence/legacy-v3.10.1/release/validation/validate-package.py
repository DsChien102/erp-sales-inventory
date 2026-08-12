#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, re, sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = []
failures = []
def check(name, condition, detail=""):
    passed = bool(condition)
    checks.append({"name": name, "passed": passed, "detail": str(detail)})
    if not passed: failures.append(f"{name}: {detail}")
def load(rel): return json.loads((root / rel).read_text(encoding="utf-8"))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

required = [
 "README.md", "theme.manifest.yaml", "change-log.md", "know-how/decisions/decision-register.md",
 "srs/02-business-journeys/00-business-journey-map.md", "use-case-manifest.json", "srs/08-ui-ux.md",
 "prototype/contracts/screen-registry.json", "prototype/contracts/action-registry.json", "prototype/contracts/ui-traceability.json",
 "prototype/contracts/bj-ui-flow-map.md", "prototype/contracts/screen-catalog.json",
 "prototype/flows/README.md", "prototype/flows/ui-flow-registry.json", "prototype/flows/validation-report.json",
 "prototype/README.md", "prototype/index.html", "prototype/prototype.manifest.json", "prototype/scripts/validate-prototype.mjs",
 "harness/ui-trace-overlay-v4.3.0.json",
 "validation/validation-report.json", "validation/executive-handoff.md", "validation/run-report.md",
 "validation/representative-samples.md", "validation/residual-risk-register.md", "validation/artifact-index.md",
 "validation/package-manifest.json", "source-checksums.json", "CHECKSUMS.sha256",
 "migration/consolidation-v4.3.0/semantic-preservation-report.json",
 "migration/consolidation-v4.3.0/carry-forward-components.json",
 "migration/repackage-v4.3.0-to-v4.3.1/repackage-report.json",
 "migration/repackage-v4.3.0-to-v4.3.1/predecessor-package-checksums-v4.3.0.json",
]
for rel in required: check("required:" + rel, (root / rel).is_file())

json_files = list(root.rglob("*.json"))
for file in json_files:
    try: json.loads(file.read_text(encoding="utf-8")); check("json:" + file.relative_to(root).as_posix(), True)
    except Exception as exc: check("json:" + file.relative_to(root).as_posix(), False, exc)

link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
active_links = 0
broken_links = []
legacy_snapshot = root / "migration/ui-ux-v4.1.0-to-v4.2.0/legacy-ui-contracts-readme-v4.1.0.md"
prototype_screen_map = root / "prototype/screen-map.md"
for file in root.rglob("*.md"):
    rel = file.relative_to(root).as_posix()
    if rel.startswith(("harness/frozen-source/", "outbound/")) or file in {legacy_snapshot, prototype_screen_map}:
        continue
    fenced = False
    for number, line in enumerate(file.read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith(chr(96) * 3):
            fenced = not fenced
            continue
        if fenced:
            continue
        for href in link_pattern.findall(line):
            if href.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = href.split("#", 1)[0]
            if not target:
                continue
            active_links += 1
            if not (file.parent / target).resolve().exists():
                broken_links.append(f"{rel}:{number}:{href}")
check("links:active-relative", not broken_links, f"checked={active_links}; broken={broken_links[:10]}")
legacy_links = [href for href in link_pattern.findall(legacy_snapshot.read_text(encoding="utf-8")) if not href.startswith(("http://", "https://", "mailto:", "#"))]
check("links:legacy-snapshot-classified", len(legacy_links) == 17 and "Snapshot lịch sử v4.1.0" in legacy_snapshot.read_text(encoding="utf-8"), len(legacy_links))
prototype_legacy_links = [href for href in link_pattern.findall(prototype_screen_map.read_text(encoding="utf-8")) if not href.startswith(("http://", "https://", "mailto:", "#"))]
check("links:prototype-v4.1.0-legacy-classified", len(prototype_legacy_links) == 14 and all(href.startswith("../prototype/contracts/sg-") for href in prototype_legacy_links), len(prototype_legacy_links))

manifest = load("validation/package-manifest.json")
actual = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p != root / "validation/package-manifest.json")
recorded = sorted(item["path"] for item in manifest["files"])
check("manifest:identity", manifest["version"] == "4.3.1" and manifest["freeze_id"] == "T7-PACKAGE-FREEZE-v4.3.1")
check("manifest:inventory", actual == recorded, f"{len(recorded)}/{len(actual)}")
check("manifest:hashes", all((root/item["path"]).is_file() and (root/item["path"]).stat().st_size == item["bytes"] and sha(root/item["path"]) == item["sha256"] for item in manifest["files"]))

checksum_excluded = {root / "CHECKSUMS.sha256", root / "source-checksums.json", root / "validation/package-manifest.json"}
checksum_actual = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p not in checksum_excluded)
checksum_rows = []
for line in (root / "CHECKSUMS.sha256").read_text(encoding="utf-8").splitlines():
    match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
    if match: checksum_rows.append((match.group(2), match.group(1)))
checksum_recorded = sorted(path for path, _ in checksum_rows)
check("checksums-sha256:inventory", checksum_actual == checksum_recorded, f"{len(checksum_recorded)}/{len(checksum_actual)}")
check("checksums-sha256:hashes", all((root/path).is_file() and sha(root/path) == digest for path, digest in checksum_rows))

source_registry = load("source-checksums.json")
source_actual = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p not in {root / "source-checksums.json", root / "validation/package-manifest.json"})
source_recorded = sorted(item["path"] for item in source_registry["files"])
check("source-registry:identity", source_registry["package_version"] == "4.3.1" and source_registry["freeze_id"] == "T7-PACKAGE-FREEZE-v4.3.1")
check("source-registry:inventory", source_actual == source_recorded, f"{len(source_recorded)}/{len(source_actual)}")
check("source-registry:hashes", all((root/item["path"]).is_file() and (root/item["path"]).stat().st_size == item["size"] and sha(root/item["path"]) == item["sha256"] for item in source_registry["files"]))

theme_manifest = (root / "theme.manifest.yaml").read_text(encoding="utf-8")
check("theme:version", "version: 4.3.1" in theme_manifest and "T7-PACKAGE-FREEZE-v4.3.1" in theme_manifest)

decision = (root / "know-how/decisions/decision-register.md").read_text(encoding="utf-8")
check("decision:groups", len(re.findall(r"(?m)^## 3\.\d+ G(?:0[1-9]|1[0-4]): ", decision)) == 14)
check("decision:ids", len(re.findall(r'(?m)^\| <a id="t7-dr-\d{3}"></a>\*\*`T7-DR-\d{3}`', decision)) == 102)
check("decision:requirements", len(set(re.findall(r"T7-DR-\d{3}#REQ-\d{2}", decision))) == 78)

bjs = list((root / "srs/02-business-journeys").glob("[0-9][0-9]-BJ-*.md"))
ucm = load("use-case-manifest.json")
check("bj:17", len(bjs) == 17, len(bjs))
check("uc:70", ucm.get("count") == 70 and len(ucm.get("files", {})) == 70)
check("uc:files", all((root / rel).is_file() for rel in ucm["files"].values()))

registry = load("prototype/contracts/screen-registry.json")
screens = registry["screens"]
actions = load("prototype/contracts/action-registry.json")["actions"]
check("ui:83-screens", len(screens) == 83)
check("ui:screen-ids", [s["id"] for s in screens] == [f"SCR-{i:03d}" for i in range(1,84)])
check("ui:479-states", sum(len(s["states"]) for s in screens) == 479)
check("ui:33-actions", len(actions) == 33)
check("ui:no-active-sg", not list((root / "prototype/contracts").glob("sg-*")))
trace = load("prototype/contracts/ui-traceability.json")["rows"]
check("ui:70-uc-trace", len({r["use_case_id"] for r in trace}) == 70)
check("ui:screen-trace-valid", all(r["screen_id"] in {s["id"] for s in screens} for r in trace))

flow_registry = load("prototype/flows/ui-flow-registry.json")
flows = flow_registry["flows"]
check("ui-flows:17", len(flows) == 17)
check("ui-flows:70-uc", len({uc for flow in flows for uc in flow["use_case_ids"]}) == 70)
check("ui-flows:201-transitions", sum(flow["transition_count"] for flow in flows) == 201)
check("ui-flows:files", all((root / "prototype/flows" / flow["file"]).is_file() for flow in flows))
flow_docs = [root / "prototype/flows" / flow["file"] for flow in flows]
check("ui-flows:mermaid", all("```mermaid" in path.read_text(encoding="utf-8") and "flowchart TD" in path.read_text(encoding="utf-8") for path in flow_docs))
check("ui-flows:transition-contract", all("## 3. Transition Contract" in path.read_text(encoding="utf-8") for path in flow_docs))

prototype_manifest = load("prototype/prototype.manifest.json")
check("prototype:component-v4.1.0", prototype_manifest["version"] == "4.1.0")
check("prototype:coverage", prototype_manifest["coverage"] == {"screen_groups": 14, "screens": 83, "states": 479, "actions": 33})
check("prototype:html-present", (root / "prototype/index.html").is_file())
carry = load("migration/consolidation-v4.3.0/carry-forward-components.json")
carried_files = carry["prototype"]["files"]
check("prototype:carry-forward-mode", carry["prototype"]["carry_forward_mode"] == "BYTE_FOR_BYTE_UNCHANGED" and carry["prototype"]["alignment_to_ui_flow_v4_2_0_rc1"] == "NOT_UPGRADED")
check("prototype:source-equivalence", len(carried_files) == 6 and all((root / "prototype" / item["path"]).is_file() and (root / "prototype" / item["path"]).stat().st_size == item["bytes"] and sha(root / "prototype" / item["path"]) == item["sha256"] for item in carried_files))
check("prototype:compatibility-catalog", sha(root / "prototype/contracts/screen-catalog.json") == sha(root / "migration/ui-ux-v4.1.0-to-v4.2.0/legacy-screen-catalog-v4.1.0.json"))

repackage = load("migration/repackage-v4.3.0-to-v4.3.1/repackage-report.json")
check("repackage:identity", repackage["release"] == "4.3.1" and repackage["freeze_id"] == "T7-PACKAGE-FREEZE-v4.3.1" and repackage["predecessor"] == "4.3.0")
check("repackage:no-semantic-change", repackage["semantic_changes"] == 0 and repackage["unchanged_non_release_files_status"] == "PASS")
check("repackage:source-zip", repackage["source_integrity"]["source_zip_sha256"] == "1bc1b75d61e6a977c94e3e6712cdf7af6d195c5bbf5dcf856ad1b7eba40d1203")

semantic = load("migration/consolidation-v4.3.0/semantic-preservation-report.json")
check("semantic:no-change", semantic["semantic_changes"] == 0 and semantic["status"] == "PASS")
check("semantic:prototype-status-only", semantic["integration_status_metadata_files_changed"] == ["srs/08-ui-ux.md", "srs/09-traceability-quality.md"] and "no business rule" in semantic["integration_status_metadata_change"])
nav = load("migration/consolidation-v4.3.0/navigation-link-audit.json")
check("navigation:no-legacy", nav["summary"]["legacy_fragments_remaining"] == 0 and nav["summary"]["unresolved_navigation_links"] == 0)
check("navigation:14-groups", nav["summary"]["groups_referenced"] == 14)

overlay = load("harness/ui-trace-overlay-v4.3.0.json")
check("harness:overlay", overlay["counts"]["canonical_use_cases"] == 70 and overlay["counts"]["supporting_slices"] == 7 and overlay["counts"]["trace_rows"] == 70 and overlay["counts"]["unique_screens"] == 83)
check("harness:prototype-honesty", overlay["prototype_status"] == "NOT_RENDERED" and overlay["prototype_carry_forward_component"] == "v4.1.0" and "NOT_UPGRADED" in overlay["prototype_alignment_note"])
tests = load("harness/test-catalog.json")["tests"]
check("harness:607-tests", len(tests) == 607)
check("harness:repo-blocked", all(t.get("status") == "BLOCKED_BY_REPO_ADAPTER" for t in tests))

report = load("validation/validation-report.json")
check("verdict:honest", report["verdict"] == "CONDITIONALLY_READY" and report["highest_evidence_level"] == "STATIC_VALIDATED")
check("handoff:complete", all(token in (root / "validation/executive-handoff.md").read_text(encoding="utf-8") for token in ["Verdict", "Mức bằng chứng", "Hành động quan trọng nhất", "Rủi ro", "Repository execution", "Prototype carry-forward"]))

result = {"status": "STATIC_VALIDATED" if not failures else "FAIL", "verdict": "CONDITIONALLY_READY" if not failures else "BLOCKED", "highest_evidence_level": "STATIC_VALIDATED" if not failures else "GENERATED", "checks": len(checks), "passed": sum(c["passed"] for c in checks), "failed": len(failures), "blocked": ["REPOSITORY_EXECUTION", "PROTOTYPE_UPGRADE_BROWSER_RUNTIME", "GITLAB_PREVIEW"], "failures": failures}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(1 if failures else 0)
