#!/usr/bin/env python3
"""Validate a VET45 Harness readiness pack and emit gate-level evidence."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

VERSION = "1.4.0"
EVIDENCE_ORDER = ["GENERATED", "STATIC_VALIDATED", "SIMULATED", "REPO_EXECUTED", "PRODUCTION_OBSERVED"]
REQUIRED_FILES = [
    "harness-execution-profile.yaml",
    "contract-registry.json",
    "trace-index.json",
    "validation-rules.yaml",
    "test-catalog.json",
    "fixture-registry.json",
    "coverage-matrix.csv",
    "implementation-questions.json",
    "source-checksums.json",
    "srs-inventory.json",
    "validation-report.json",
    "validation-report.md",
    "executive-handoff.md",
    "run-report.md",
    "representative-samples.md",
    "residual-risk-register.md",
    "artifact-index.md",
    "run-manifest.json",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def gate(gate_id: str, name: str, hard: bool, failures: list[str], evidence_refs: list[str], summary: str, blocked: bool = False) -> dict:
    status = "BLOCKED" if blocked else ("FAIL" if failures else "PASS")
    return {
        "gate_id": gate_id,
        "name": name,
        "hard_gate": hard,
        "status": status,
        "evidence_level": "STATIC_VALIDATED" if status in {"PASS", "FAIL"} else "GENERATED",
        "summary": summary,
        "evidence_refs": evidence_refs,
        "failures": failures,
    }


def duplicate_values(records: list[dict], field: str) -> list[str]:
    counts = Counter(record.get(field) for record in records)
    return sorted(str(value) for value, count in counts.items() if value is not None and count > 1)


def update_manifest(pack: Path, manifest: dict) -> None:
    files = []
    for path in sorted(pack.iterdir()):
        if not path.is_file() or path.name == "run-manifest.json":
            continue
        files.append({"path": path.name, "bytes": path.stat().st_size, "sha256": sha256(path)})
    manifest["files"] = files
    manifest["validated_at"] = datetime.now(timezone.utc).isoformat()
    manifest["validator"] = f"validate_harness_pack.py/{VERSION}"
    manifest["highest_evidence_level"] = "STATIC_VALIDATED"
    manifest["verdict"] = "CONDITIONALLY_READY"
    (pack / "run-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def validate(pack: Path) -> tuple[dict, int]:
    gates: list[dict] = []

    missing = [name for name in REQUIRED_FILES if not (pack / name).is_file()]
    gates.append(gate("G00_REQUIRED_FILES", "Required artifact set", True, [f"Missing {name}" for name in missing], REQUIRED_FILES, f"{len(REQUIRED_FILES) - len(missing)}/{len(REQUIRED_FILES)} required files present."))
    if missing:
        report = {
            "schema_version": "1.0",
            "validator": f"validate_harness_pack.py/{VERSION}",
            "validated_at": datetime.now(timezone.utc).isoformat(),
            "verdict": "BLOCKED",
            "highest_evidence_level": "GENERATED",
            "gates": gates,
        }
        return report, 1

    json_names = [
        "contract-registry.json",
        "trace-index.json",
        "test-catalog.json",
        "fixture-registry.json",
        "implementation-questions.json",
        "source-checksums.json",
        "srs-inventory.json",
        "run-manifest.json",
    ]
    data = {}
    parse_failures = []
    for name in json_names:
        try:
            data[name] = load_json(pack / name)
        except Exception as exc:  # pragma: no cover - exercised by malformed forward test
            parse_failures.append(f"{name}: {exc}")
    for name in ["harness-execution-profile.yaml", "validation-rules.yaml"]:
        text = (pack / name).read_text(encoding="utf-8")
        if not text.startswith("schema_version:") or "\t" in text:
            parse_failures.append(f"{name}: missing schema_version or contains tab indentation")
    gates.append(gate("G01_SOURCE_INTEGRITY", "Parse and source checksum integrity", True, parse_failures, json_names + ["harness-execution-profile.yaml", "validation-rules.yaml"], "All machine-readable artifacts parse and source files retain their recorded checksums."))
    if parse_failures:
        report = {
            "schema_version": "1.0",
            "validator": f"validate_harness_pack.py/{VERSION}",
            "validated_at": datetime.now(timezone.utc).isoformat(),
            "verdict": "BLOCKED",
            "highest_evidence_level": "GENERATED",
            "gates": gates,
        }
        return report, 1

    inventory = data["srs-inventory.json"]
    checksums = data["source-checksums.json"]
    contracts = data["contract-registry.json"]["contracts"]
    trace = data["trace-index.json"]
    tests = data["test-catalog.json"]["tests"]
    fixtures = data["fixture-registry.json"]["fixtures"]
    questions = data["implementation-questions.json"]["questions"]
    manifest = data["run-manifest.json"]

    profile_text = (pack / "harness-execution-profile.yaml").read_text(encoding="utf-8")
    profile_freeze_match = re.search(r'^freeze_id:\s+"([^"]+)"\s*$', profile_text, re.M)
    declared_freeze = profile_freeze_match.group(1) if profile_freeze_match else None

    checksum_failures = []
    source_root = Path(checksums["source_root"])
    for record in checksums["files"]:
        path = source_root / record["path"]
        if not path.is_file():
            checksum_failures.append(f"Missing source {record['path']}")
        elif path.stat().st_size != record["bytes"] or sha256(path) != record["sha256"]:
            checksum_failures.append(f"Checksum drift: {record['path']}")
    if not declared_freeze:
        checksum_failures.append("Execution profile lacks freeze_id")
    for label, value in [
        ("source-checksums", checksums.get("freeze_id")),
        ("trace-index", trace.get("freeze_id")),
        ("run-manifest", manifest.get("freeze_id")),
    ]:
        if value != declared_freeze:
            checksum_failures.append(f"Freeze ID mismatch: profile={declared_freeze}, {label}={value}")
    source_markdown = {record["path"]: (source_root / record["path"]).read_text(encoding="utf-8") for record in checksums["files"] if (source_root / record["path"]).is_file()}
    decision_candidates = [text for name, text in source_markdown.items() if "Decision-Log" in name or "Decision Log" in text[:120]]
    manifest_candidates = [text for name, text in source_markdown.items() if "Freeze-Manifest" in name or "Freeze Manifest" in text[:160]]
    exact_freeze_token = f"`{declared_freeze}`" if declared_freeze else ""
    if not decision_candidates or not any(exact_freeze_token in text[:500] for text in decision_candidates):
        checksum_failures.append("No canonical Decision Log declares the execution-profile freeze ID")
    if not manifest_candidates or not any(exact_freeze_token in text[:500] for text in manifest_candidates):
        checksum_failures.append("No canonical Freeze Manifest declares the execution-profile freeze ID")
    gates.append(gate("G02_FREEZE_INTEGRITY", "Frozen source and freeze-ID integrity", True, checksum_failures, ["source-checksums.json", "harness-execution-profile.yaml", "trace-index.json", "run-manifest.json"], f"{len(checksums['files'])} frozen source files checked; freeze identity must match profile, Decision Log, Trace Matrix and Freeze Manifest."))

    package_checksum_failures = []
    for record in manifest.get("files", []):
        path = pack / record["path"]
        if not path.is_file():
            package_checksum_failures.append(f"Manifest file missing: {record['path']}")
        elif path.stat().st_size != record["bytes"] or sha256(path) != record["sha256"]:
            package_checksum_failures.append(f"Pre-validation package drift: {record['path']}")
    for key in ["owned_entities", "projections", "invariants", "stories", "api_operations", "events", "permission_intents", "reason_codes", "p0_contracts"]:
        if inventory["counts"].get(key, 0) <= 0:
            package_checksum_failures.append(f"Inventory dimension is empty: {key}")
    if manifest.get("package_version") != VERSION:
        package_checksum_failures.append(f"Package version {manifest.get('package_version')} != validator/generator version {VERSION}")
    gates.append(gate("G03_INVENTORY_COVERAGE", "Semantic inventory and package manifest", True, package_checksum_failures, ["srs-inventory.json", "run-manifest.json"], f"Inventory declares {inventory['counts'].get('owned_entities', 0)} entities, {inventory['counts'].get('projections', 0)} projections, {inventory['counts'].get('invariants', 0)} invariants, {inventory['counts'].get('stories', 0)} stories and {inventory['counts'].get('p0_contracts', 0)} P0 contracts."))

    duplicate_failures = []
    for label, records in [("contract", contracts), ("test", tests), ("fixture", fixtures)]:
        dupes = duplicate_values(records, "id")
        duplicate_failures.extend(f"Duplicate {label} ID: {item}" for item in dupes)
    gates.append(gate("G04_STABLE_ID_UNIQUENESS", "Stable-ID uniqueness", True, duplicate_failures, ["contract-registry.json", "test-catalog.json", "fixture-registry.json"], f"Checked {len(contracts)} contracts, {len(tests)} tests and {len(fixtures)} fixtures."))

    coverage_rows = []
    coverage_failures = []
    expected_header = ["source_ref", "source_kind", "story", "contract_id", "test_id", "fixture_id", "gate_id", "status", "evidence_level", "notes"]
    with (pack / "coverage-matrix.csv").open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != expected_header:
            coverage_failures.append(f"Coverage header mismatch: {reader.fieldnames}")
        coverage_rows = list(reader)
    requirement_ids = {requirement["id"] for story in inventory["stories"] for requirement in story["requirements"]}
    covered_requirement_ids = {row["source_ref"] for row in coverage_rows if row["source_kind"] in {"FR", "AC", "EC", "SC"}}
    missing_requirements = sorted(requirement_ids - covered_requirement_ids)
    extra_requirements = sorted(covered_requirement_ids - requirement_ids)
    coverage_failures.extend(f"Requirement not covered: {item}" for item in missing_requirements[:50])
    coverage_failures.extend(f"Coverage source does not resolve: {item}" for item in extra_requirements[:50])
    trace_story_ids = {item["story"] for item in trace["stories"]}
    inventory_story_ids = set(inventory["ids"]["stories"])
    for item in sorted(inventory_story_ids - trace_story_ids):
        coverage_failures.append(f"Story missing from trace index: {item}")
    for item in sorted(trace_story_ids - inventory_story_ids):
        coverage_failures.append(f"Trace story does not resolve: {item}")
    event_ids = {item["id"] for item in inventory["events"]}
    permission_names = {item["name"] for item in inventory["permissions"]}
    reason_ids = {item["id"] for item in inventory["reason_codes"]}
    invariant_ids = {item["id"] for item in inventory.get("invariants", [])}
    operation_names = {item["name"] for item in inventory["operations"]}
    covered_events = {row["source_ref"] for row in coverage_rows if row["source_kind"] == "EVENT_OR_EVIDENCE"}
    covered_permissions = {row["source_ref"] for row in coverage_rows if row["source_kind"] == "PERMISSION_INTENT"}
    covered_reasons = {row["source_ref"] for row in coverage_rows if row["source_kind"] == "REASON_CODE"}
    covered_invariants = {row["source_ref"] for row in coverage_rows if row["source_kind"] == "INVARIANT"}
    covered_operations = {row["source_ref"] for row in coverage_rows if row["source_kind"] == "API_OPERATION"}
    for label, expected, actual in [
        ("event/evidence", event_ids, covered_events),
        ("permission", permission_names, covered_permissions),
        ("reason", reason_ids, covered_reasons),
        ("invariant", invariant_ids, covered_invariants),
        ("API operation", operation_names, covered_operations),
    ]:
        for item in sorted(expected - actual):
            coverage_failures.append(f"{label} contract not covered: {item}")
        for item in sorted(actual - expected):
            coverage_failures.append(f"{label} coverage source does not resolve: {item}")
    test_ids = {item["id"] for item in tests}
    test_by_id = {item["id"]: item for item in tests}
    fixture_by_id = {item["id"]: item for item in fixtures}
    known_contract_ids = {item["id"] for item in contracts}
    requirement_by_id = {
        requirement["id"]: requirement
        for story in inventory["stories"]
        for requirement in story["requirements"]
    }
    requirement_row_counts = Counter(
        row["source_ref"] for row in coverage_rows if row["source_kind"] in {"FR", "AC", "EC", "SC"}
    )
    for requirement_id in sorted(requirement_ids):
        if requirement_row_counts[requirement_id] != 1:
            coverage_failures.append(f"Requirement must have exactly one atomic coverage row: {requirement_id} -> {requirement_row_counts[requirement_id]}")
    for row_number, row in enumerate(coverage_rows, 2):
        if ";" in row["contract_id"]:
            coverage_failures.append(f"Coverage row {row_number} has multiple values in singular contract_id")
        if row["contract_id"] not in known_contract_ids:
            coverage_failures.append(f"Coverage row {row_number} contract does not resolve: {row['contract_id']}")
        test = test_by_id.get(row["test_id"])
        fixture = fixture_by_id.get(row["fixture_id"])
        if not test:
            coverage_failures.append(f"Coverage row {row_number} test does not resolve: {row['test_id']}")
        elif test.get("contract_ids") != [row["contract_id"]]:
            coverage_failures.append(f"Coverage row {row_number} is not atomic with test {row['test_id']}")
        if not fixture:
            coverage_failures.append(f"Coverage row {row_number} fixture does not resolve: {row['fixture_id']}")
        elif row["fixture_id"] not in (test or {}).get("fixture_ids", []):
            coverage_failures.append(f"Coverage row {row_number} fixture is not linked by test {row['test_id']}")
        if row["source_kind"] in {"FR", "AC", "EC", "SC"} and test and fixture:
            requirement = requirement_by_id.get(row["source_ref"])
            if not requirement:
                continue
            observed = " ".join(test.get("expected", []) + [test.get("action", "")])
            if requirement["text"] not in observed:
                coverage_failures.append(f"Requirement assertion is absent from action/expected: {row['source_ref']}")
            if fixture.get("source_assertion") != requirement["text"]:
                coverage_failures.append(f"Requirement fixture does not preserve exact assertion: {row['source_ref']}")
            if not fixture.get("expected_result"):
                coverage_failures.append(f"Requirement fixture lacks expected_result: {row['source_ref']}")
            mapping_basis = test.get("mapping_basis", "")
            score_match = re.search(r"total_score=(-?\d+)", mapping_basis)
            if not ({"SEMANTIC_AUTO_REVIEW", "STORY_PRIMARY_REVIEWED", "CURATED_MANUAL_REVIEW"} & set(mapping_basis.split(";", 1)[0].split())) or not score_match or int(score_match.group(1)) < 4:
                coverage_failures.append(f"Requirement mapping needs semantic review: {row['source_ref']} -> {row['contract_id']} ({mapping_basis})")
    entity_names = {item["name"] for item in inventory.get("entities", []) + inventory.get("projections", [])}
    for story_record in trace["stories"]:
        if not story_record.get("tests"):
            coverage_failures.append(f"Trace story lacks test mappings: {story_record['story']}")
        for test_id in story_record.get("tests", []):
            if test_id not in test_ids:
                coverage_failures.append(f"Trace test does not resolve: {story_record['story']} -> {test_id}")
        for entity in story_record.get("entities", []):
            if entity not in entity_names:
                coverage_failures.append(f"Trace entity does not resolve: {story_record['story']} -> {entity}")
    gates.append(gate("G05_TRACE_CLOSURE", "Atomic source-to-contract-to-test trace closure", True, coverage_failures, ["trace-index.json", "coverage-matrix.csv"], f"{len(covered_requirement_ids)}/{len(requirement_ids)} requirements, {len(covered_operations)}/{len(operation_names)} API operations, {len(covered_events)}/{len(event_ids)} events, {len(covered_permissions)}/{len(permission_names)} permissions, {len(covered_reasons)}/{len(reason_ids)} reasons and {len(covered_invariants)}/{len(invariant_ids)} invariants mapped."))

    semantic_failures = []
    for contract in contracts:
        for field in ["id", "kind", "name", "version", "owner", "source_refs", "finality_semantics", "safe_failure", "evidence_level"]:
            if field not in contract or contract[field] in (None, "", []):
                semantic_failures.append(f"Contract {contract.get('id')} missing {field}")
        if not contract.get("stories") and not contract.get("story_independent_reason"):
            semantic_failures.append(f"Story-independent contract lacks reason: {contract.get('id')}")
        if contract["kind"] == "P0_CONTRACT" and contract.get("owner") in {"CROSS_DOMAIN_OWNER_CHAIN", "CONTRACT_OWNER", "REFERENCED_OWNER"}:
            semantic_failures.append(f"P0 contract uses generic owner: {contract['id']}")
        if contract["kind"] == "REASON_CODE" and contract.get("owner") == "CONTRACT_OWNER":
            semantic_failures.append(f"Reason contract uses generic owner: {contract['id']}")
        if contract["kind"] == "EVENT_OR_EVIDENCE" and contract.get("owner") in {"IN", "REFERENCED_OWNER"}:
            semantic_failures.append(f"Inbound event uses unresolved owner: {contract['id']}")
    forbidden_finality = [
        contract["id"]
        for contract in contracts
        if contract["kind"] == "PERMISSION_INTENT" and "never creates" not in contract["finality_semantics"].lower()
    ]
    semantic_failures.extend(f"Permission contract lacks no-finality assertion: {item}" for item in forbidden_finality)
    gates.append(gate("G06_AUTHORITY_FINALITY", "Authority and finality contract shape", True, semantic_failures, ["contract-registry.json"], "Every contract declares owner, source, finality semantics, safe failure and evidence level."))

    p0_failures = []
    p0_ids = inventory["ids"]["p0_contracts"]
    p0_contract_sources = {ref for contract in contracts if contract["kind"] == "P0_CONTRACT" for ref in contract["source_refs"]}
    tests_by_p0: dict[str, list[dict]] = defaultdict(list)
    for test in tests:
        for ref in test.get("source_refs", []):
            if ref in p0_ids:
                tests_by_p0[ref].append(test)
    required_dimensions = {"HAPPY", "DUPLICATE", "IDEMPOTENCY_CONFLICT", "STALE_VERSION", "CONCURRENCY", "UNKNOWN", "CAUSAL_MISMATCH", "REVERSAL"}
    for p0_id in p0_ids:
        if p0_id not in p0_contract_sources:
            p0_failures.append(f"Missing P0 contract record: {p0_id}")
        dimension_tokens = {test["id"].split(f"{p0_id.replace('-', '')}-", 1)[-1] for test in tests_by_p0[p0_id] if f"{p0_id.replace('-', '')}-" in test["id"]}
        missing_dimensions = required_dimensions - dimension_tokens
        if missing_dimensions:
            p0_failures.append(f"{p0_id} missing fence tests: {', '.join(sorted(missing_dimensions))}")
    for dimension in sorted(required_dimensions):
        dimension_tests = [
            test for p0_id in p0_ids for test in tests_by_p0[p0_id]
            if test["id"].endswith(f"-{dimension}")
        ]
        semantic_signatures = {json.dumps({"action": test.get("action"), "expected": test.get("expected")}, ensure_ascii=False, sort_keys=True) for test in dimension_tests}
        if len(semantic_signatures) != len(p0_ids):
            p0_failures.append(f"P0-specific semantics are not distinct for dimension {dimension}")
    p0_fixture_records = [fixture for fixture in fixtures if fixture.get("kind") == "P0_FENCE"]
    if len({json.dumps(fixture.get("p0_specific_payload"), sort_keys=True) for fixture in p0_fixture_records}) != len(p0_ids):
        p0_failures.append("P0 fixtures do not have distinct owner-specific payloads")
    for fixture in p0_fixture_records:
        if len(fixture.get("expected_result", {})) != len(required_dimensions):
            p0_failures.append(f"P0 fixture lacks dimension-specific expected results: {fixture.get('id')}")
    gates.append(gate("G07_P0_COVERAGE", "P0 fence coverage", True, p0_failures, ["contract-registry.json", "test-catalog.json"], f"{len(p0_ids)} P0 contracts checked for {len(required_dimensions)} fence dimensions each."))

    safe_failures = []
    unknown_tests = [test for test in tests if test["test_type"] == "P0_E2E" and test["id"].endswith("-UNKNOWN")]
    for test in unknown_tests:
        text = " ".join(test["expected"] + [test["action"]]).lower()
        if "same" not in text and "identity" not in text:
            safe_failures.append(f"UNKNOWN test lacks same-identity semantics: {test['id']}")
    reason_contracts = [contract for contract in contracts if contract["kind"] == "REASON_CODE"]
    if len(reason_contracts) != inventory["counts"].get("reason_codes", 0):
        safe_failures.append(f"Reason contract count {len(reason_contracts)} != source {inventory['counts'].get('reason_codes', 0)}")
    gates.append(gate("G08_SAFE_FAILURE", "Idempotency, UNKNOWN and reason-code safety", True, safe_failures, ["test-catalog.json", "contract-registry.json"], f"{len(unknown_tests)} P0 UNKNOWN tests and {len(reason_contracts)} reason-code contracts checked."))

    linkage_failures = []
    fixture_ids = {item["id"] for item in fixtures}
    fixture_by_id = {item["id"]: item for item in fixtures}
    contract_ids = {item["id"] for item in contracts}
    for test in tests:
        for field in ["id", "title", "source_refs", "contract_ids", "test_type", "priority", "fixture_ids", "preconditions", "action", "expected", "gate_ids", "required_evidence_level", "status"]:
            if field not in test or test[field] in (None, "", []):
                linkage_failures.append(f"Test {test.get('id')} missing {field}")
        for fixture_id in test.get("fixture_ids", []):
            if fixture_id not in fixture_ids:
                linkage_failures.append(f"Test {test['id']} missing fixture {fixture_id}")
            elif not fixture_by_id[fixture_id].get("expected_result"):
                linkage_failures.append(f"Fixture lacks expected_result: {fixture_id}")
        for contract_id in test.get("contract_ids", []):
            if contract_id not in contract_ids:
                linkage_failures.append(f"Test {test['id']} missing contract {contract_id}")
        if test.get("status", "").startswith("BLOCKED") and not test.get("blocker"):
            linkage_failures.append(f"Blocked test lacks blocker: {test['id']}")
        if test.get("test_type") in {"FUNCTIONAL_CONTRACT", "ACCEPTANCE", "EDGE_CASE", "SCENARIO"}:
            if len(test.get("source_refs", [])) != 1 or len(test.get("contract_ids", [])) != 1 or len(test.get("fixture_ids", [])) != 1:
                linkage_failures.append(f"Story requirement test is not atomic: {test['id']}")
    tested_contract_ids = {contract_id for test in tests for contract_id in test.get("contract_ids", [])}
    for contract_id in sorted(contract_ids - tested_contract_ids):
        linkage_failures.append(f"Contract has no test mapping: {contract_id}")
    gates.append(gate("G09_TEST_FIXTURE_LINKAGE", "Test, fixture and gate linkage", True, linkage_failures, ["test-catalog.json", "fixture-registry.json"], f"{len(tests)} tests linked to {len(fixtures)} fixtures and declared gates."))

    placeholder_failures = []
    placeholder_re = re.compile(r"\b(TBD|TODO|TBC|FIXME)\b|<[^>\n]{1,80}>", re.I)
    for path in sorted(pack.iterdir()):
        if not path.is_file() or path.suffix not in {".md", ".json", ".yaml", ".csv"}:
            continue
        if path.name == "validation-rules.yaml":
            continue
        for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if placeholder_re.search(line):
                placeholder_failures.append(f"{path.name}:{line_no}: unresolved placeholder")
    gates.append(gate("G10_NO_PLACEHOLDERS", "No unresolved placeholders", True, placeholder_failures, [path.name for path in pack.iterdir() if path.is_file()], "Scanned text artifacts for unresolved placeholder patterns."))

    evidence_failures = []
    if manifest.get("verdict") == "READY" and manifest.get("highest_evidence_level") not in {"REPO_EXECUTED", "PRODUCTION_OBSERVED"}:
        evidence_failures.append("READY verdict without REPO_EXECUTED evidence")
    if any(test["status"] == "PASSED" for test in tests) and not any(test.get("evidence_refs") for test in tests if test["status"] == "PASSED"):
        evidence_failures.append("Passed tests lack execution evidence")
    gates.append(gate("G11_EVIDENCE_VERDICT_HONESTY", "Evidence-level and verdict honesty", True, evidence_failures, ["run-manifest.json", "executive-handoff.md", "test-catalog.json"], "Package-only evidence is reported as CONDITIONALLY_READY; repo-dependent tests remain blocked."))

    handoff = (pack / "executive-handoff.md").read_text(encoding="utf-8")
    handoff_failures = []
    required_handoff_terms = [
        "## Verdict",
        "## Scope and actual execution",
        "## Coverage and gates",
        "## Important findings and repairs",
        "## Representative depth",
        "## Residual risks",
        "## Artifact navigation",
        "CONDITIONALLY_READY",
        "STATIC_VALIDATED",
        "Repo-executed",
        "| Notes |",
        "Complete Package Archive",
    ]
    for term in required_handoff_terms:
        if term not in handoff:
            handoff_failures.append(f"Executive handoff missing: {term}")
    for name in ["run-report.md", "coverage-matrix.csv", "validation-report.md", "representative-samples.md", "residual-risk-register.md", "artifact-index.md"]:
        if name not in handoff:
            handoff_failures.append(f"Executive handoff does not navigate to {name}")
    gates.append(gate("G12_HUMAN_HANDOFF", "Human handoff completeness", True, handoff_failures, ["executive-handoff.md", "representative-samples.md", "residual-risk-register.md", "artifact-index.md"], "Executive handoff includes verdict, evidence ceiling, execution scope, findings, coverage, samples, risks and navigation."))

    question_failures = []
    for item in questions:
        if item.get("classification") not in {"BLOCKING", "SLICE_GATED", "DEFERRED"}:
            question_failures.append(f"Question {item.get('id')} has invalid classification")
        if not item.get("owner") or not item.get("decision_gate"):
            question_failures.append(f"Question {item.get('id')} lacks owner/decision gate")
        if len(item.get("question", "")) < 35 or "?" not in item.get("question", ""):
            question_failures.append(f"Question {item.get('id')} appears truncated")
    gates.append(gate("G13_IMPLEMENTATION_QUESTIONS", "Implementation-question classification", False, question_failures, ["implementation-questions.json"], f"{len(questions)} open questions retained with owner, classification and decision gate."))

    repo_tests = [test for test in tests if test.get("status") == "PASSED" and test.get("actual_evidence_level") in {"REPO_EXECUTED", "PRODUCTION_OBSERVED"}]
    repo_blocked = not repo_tests
    gates.append(gate("G14_REPOSITORY_EXECUTION", "Actual repository execution", False, [], ["test-catalog.json", "run-report.md"], f"{len(repo_tests)} tests have repository execution evidence; repo adapter required for the selected pilots.", blocked=repo_blocked))

    hard_failures = [item for item in gates if item["hard_gate"] and item["status"] != "PASS"]
    verdict = "BLOCKED" if hard_failures else "CONDITIONALLY_READY"
    report = {
        "schema_version": "1.0",
        "validator": f"validate_harness_pack.py/{VERSION}",
        "validated_at": datetime.now(timezone.utc).isoformat(),
        "verdict": verdict,
        "highest_evidence_level": "STATIC_VALIDATED",
        "inventory_summary": inventory["counts"],
        "coverage_summary": {
            "requirements": len(requirement_ids),
            "covered_requirements": len(covered_requirement_ids),
            "coverage_rows": len(coverage_rows),
            "contracts": len(contracts),
            "tests": len(tests),
            "fixtures": len(fixtures),
            "blocked_repo_tests": sum(test.get("status", "").startswith("BLOCKED") for test in tests),
        },
        "gates": gates,
        "hard_failures": [item["gate_id"] for item in hard_failures],
        "blocked_checks": [item["gate_id"] for item in gates if item["status"] == "BLOCKED"],
        "blocked_check_details": [
            {
                "gate_id": item["gate_id"],
                "owner": "Engineering / QA" if item["gate_id"] == "G14_REPOSITORY_EXECUTION" else "Declared gate owner",
                "unblock_action": "Implement the actual repository adapter and execute the selected pilot with recorded commands, exits and logs." if item["gate_id"] == "G14_REPOSITORY_EXECUTION" else "Resolve the gate failures and rerun strict validation.",
            }
            for item in gates
            if item["status"] == "BLOCKED"
        ],
        "skipped_checks": [],
        "source_checksum_status": "PASS" if not checksum_failures else "FAIL",
        "package_checksum_status": "PASS" if not package_checksum_failures else "FAIL",
    }
    return report, 1 if hard_failures else 0


def write_reports(pack: Path, report: dict) -> None:
    (pack / "validation-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Validation Report",
        "",
        f"**Verdict:** `{report['verdict']}` · **Highest evidence:** `{report['highest_evidence_level']}` · **Validator:** `{report['validator']}`",
        "",
        "| Gate | Hard | Result | Evidence | Summary |",
        "|---|---:|---|---|---|",
    ]
    for item in report["gates"]:
        lines.append(f"| `{item['gate_id']}` — {item['name']} | {'Yes' if item['hard_gate'] else 'No'} | {item['status']} | {item['evidence_level']} | {item['summary']} |")
    failures = [failure for item in report["gates"] for failure in item["failures"]]
    lines.extend(["", "## Failures", ""])
    if failures:
        lines.extend(f"- {failure}" for failure in failures)
    else:
        lines.append("- No hard-gate failure.")
    lines.extend(["", "## Blocked checks", ""])
    if report["blocked_checks"]:
        lines.extend(f"- `{item}` — requires the actual repository or external adapter evidence." for item in report["blocked_checks"])
    else:
        lines.append("- None.")
    (pack / "validation-report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    run_report_path = pack / "run-report.md"
    run_report = run_report_path.read_text(encoding="utf-8")
    marker = "## Iteration 2 — Deterministic validation"
    if marker not in run_report:
        validation_command = f"python3 validate_harness_pack.py {pack} --strict"
        run_report += (
            f"\n{marker}\n\n"
            f"- Command: `{validation_command}`\n"
            f"- Timestamp: `{report['validated_at']}`\n"
            f"- Exit result: `{'0' if not report['hard_failures'] else '1'}`\n"
            f"- Validator: `{report['validator']}`\n"
            f"- Result: `{report['verdict']}` with `{report['highest_evidence_level']}` evidence.\n"
            f"- Hard failures: {len(report['hard_failures'])}.\n"
            f"- Blocked checks: {', '.join(report['blocked_checks']) if report['blocked_checks'] else 'none'}.\n"
            "- Repair rule: any future failure must be recorded with the fix and a new validation run; repository execution evidence must update the catalog instead of overwriting this package-only result.\n"
        )
        run_report_path.write_text(run_report, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pack", type=Path)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    pack = args.pack.resolve()
    if not pack.is_dir():
        raise SystemExit(f"Pack directory not found: {pack}")
    report, exit_code = validate(pack)
    write_reports(pack, report)
    if (pack / "run-manifest.json").is_file():
        manifest = load_json(pack / "run-manifest.json")
        manifest["verdict"] = report["verdict"]
        manifest["highest_evidence_level"] = report["highest_evidence_level"]
        update_manifest(pack, manifest)
    print(json.dumps({"verdict": report["verdict"], "hard_failures": report["hard_failures"], "blocked_checks": report["blocked_checks"], "gates": Counter(item["status"] for item in report["gates"])}, ensure_ascii=False, default=dict, sort_keys=True))
    if args.strict and exit_code:
        raise SystemExit(exit_code)


if __name__ == "__main__":
    main()
