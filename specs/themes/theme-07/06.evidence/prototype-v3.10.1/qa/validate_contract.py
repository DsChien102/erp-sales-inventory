from pathlib import Path
import json, os, re, subprocess, sys

html_root = Path(__file__).resolve().parents[1]
prototype_root = html_root.parent
theme_root = prototype_root.parent
contracts_root = prototype_root / "contracts"
checks = []

def check(name, cond, detail=""):
    checks.append((name, bool(cond), detail))

def text(path):
    return path.read_text(encoding="utf-8")

def fn_body(source, name):
    m = re.search(rf"function\s+{re.escape(name)}\s*\([^)]*\)\s*\{{", source)
    if not m:
        return ""
    start = m.start()
    next_m = re.search(r"\nfunction\s+[A-Za-z0-9_]+\s*\(", source[m.end():])
    end = m.end() + next_m.start() if next_m else len(source)
    return source[start:end]

app = text(html_root / "app.js")
css = text(html_root / "styles.css")
index = text(html_root / "index.html")
manifest = json.loads(text(html_root / "manifest.json"))
workbench = json.loads(text(html_root / "workbench-data.json"))
flow = text(prototype_root / "flows/UIF-02-BJ-02.md")
usage_md = text(contracts_root / "component-usage/UIF-02-COMPONENT-USAGE.md")
usage_yaml = text(contracts_root / "component-usage/UIF-02-COMPONENT-USAGE.yaml")
registry = json.loads(text(contracts_root / "screen-registry.json"))
flow_registry = json.loads(text(prototype_root / "flows/ui-flow-registry.json"))
bj_ui_map = text(contracts_root / "bj-ui-flow-map.md")
screen_docs = {p.stem: text(p) for p in (contracts_root / "screens").glob("SCR-*.md")}

# --- Runtime / package identity ------------------------------------------------
check("manifest version 0.2.9", manifest.get("version") == "0.2.9")
check("manifest has 17 flows", manifest.get("flows") == 17)
check("manifest has 80 active workbench screens", manifest.get("screens") == 80)
check("manifest calibration is BJ-02/UIF-02", manifest.get("calibration", {}).get("bj") == "BJ-02" and manifest.get("calibration", {}).get("uif") == "UIF-02")
proc = subprocess.run(["node", "--check", str(html_root / "app.js")], capture_output=True, text=True)
check("app.js parses", proc.returncode == 0, proc.stderr.strip())
check("Harness bootstrap exists", 'const flowSelectorEl=document.getElementById("flow-selector")' in app and 'render();\nif (initialParams.get("inspect") === "1")' in app)
check("Inspect state declarations exist", all(s in app for s in ["let inspectEnabled = false;", "let inspectPinned = false;", "let inspectTarget = null;"]))
check("active UIF body scope is set", "document.body.dataset.activeUif = f.id;" in app)
check("mobile workbench label 402x874", "Mobile · 402 × 874" in index)
check("pilot badge is v0.2.9", "BJ-02 pilot v0.2.9 · end-user QA calibration" in index)

# --- Workbench / flow structure ------------------------------------------------
flow_obj = next((f for f in workbench.get("flows", []) if f.get("id") == "UIF-02"), None)
expected_bj02_screens = ["SCR-006", "SCR-007", "SCR-008", "SCR-009", "SCR-084", "SCR-010", "SCR-011", "SCR-012", "SCR-013"]
check("UIF-02 exists", flow_obj is not None)
check("UIF-02 screen order includes SCR-084", flow_obj is not None and flow_obj.get("screens") == expected_bj02_screens)
check("workbench contains 80 screen objects", len(workbench.get("screens", [])) == 80)
check("workbench contains SCR-084 exactly once", sum(1 for s in workbench.get("screens", []) if s.get("id") == "SCR-084") == 1)
check("flow documents Quick SCR-008 to SCR-009", "S008 -->|Đủ thông tin lần nhận| S009" in flow)
check("flow documents Document SCR-007 to SCR-009", "S007 -->|Chọn chứng từ| S009" in flow)
check("flow documents SCR-009 to SCR-084", "S009 -->|Chọn một mục hàng| S084" in flow)
check("flow documents Quick add item to SCR-084", "S009 -->|Quick: thêm sản phẩm| S084" in flow)
check("flow documents document not-received action", "Document: chưa nhận lần này" in flow)
check("flow declares one supplier", "Một Receipt có đúng **một Supplier**" in flow)
check("flow forbids master creation", "không tạo mới Supplier hoặc Product" in flow)
check("flow declares different UOM as separate lines", "Cùng Product + UOM khác → hai lines" in flow)
flow_registry_uif02 = next((f for f in flow_registry.get("flows", []) if f.get("id") == "UIF-02"), None)
check("machine flow registry has 9 BJ02 screens", flow_registry_uif02 is not None and flow_registry_uif02.get("screen_ids") == expected_bj02_screens)
check("machine flow registry has 21 BJ02 transitions", flow_registry_uif02 is not None and flow_registry_uif02.get("transition_count") == 21)
check("BJ UI map includes SCR-084", "BJ-02" in bj_ui_map and "SCR-084" in bj_ui_map)

# --- BJ02 renderer screen contracts -------------------------------------------
r006, r007, r008, r009 = [fn_body(app, n) for n in ["render006", "render007", "render008", "render009"]]
r084, r010, r011, r012, r013 = [fn_body(app, n) for n in ["render084", "render010", "render011", "render012", "render013"]]
check("SCR-006 renderer exists", bool(r006))
check("SCR-006 has no badge", "vBadge(" not in r006)
check("SCR-006 uses neutral card icon tone", r006.count("VComponentTone.neutral") >= 4)
check("SCR-006 uses same nav chevron on both cards", r006.count("navChevron()") == 2)

check("SCR-007 renderer exists", bool(r007))
check("SCR-007 document fixture exposes two products", "2 sản phẩm đang chờ nhận" in r007)
check("SCR-007 avoids source quantity aggregate", "Còn nhận 120" not in r007 and "Còn nhận 34" not in r007)
check("SCR-007 uses one nav chevron contract", r007.count("navChevron()") == 1)
check("SCR-007 cards have no ready badge", "vBadge(" not in r007)
check("SCR-007 uses VSearchBar", 'data-ds-component="VSearchBar"' in r007 and "Tìm mã chứng từ hoặc nhà cung cấp" in r007)
check("SCR-007 FILTER_EMPTY uses VEmptyState with search retained", "document-filter-empty" in r007 and 'data-ds-component="VEmptyState"' in r007)

check("SCR-008 renderer exists", bool(r008))
check("SCR-008 is receipt-header-only", all(s in r008 for s in ["Nhà cung cấp", "Ngày nhận", "Căn cứ giao nhận", "Ghi chú"]))
check("SCR-008 has no Product editor", "Sản phẩm <span" not in r008 and "Lô hàng" not in r008 and "Số lượng thực nhận" not in r008)
check("SCR-008 supplier uses VCombobox", 'data-ds-component="VCombobox"' in r008)
check("SCR-008 supplier no-result has no create CTA", "Tạo nhà cung cấp" not in r008 and "data-bj02-action=\"create" not in r008)
check("SCR-008 routes to SCR-009", 'primaryFooter("Tiếp tục", \'data-next="SCR-009"\'' in r008)
check("SCR-008 requires existing exact supplier", "supplierCatalog.some" in r008)
check("SCR-008 optional note has no redundant optional copy", "Không bắt buộc" not in r008)
check("SCR-008 supplier result has code and phone", "supplier.code" in r008 and "supplier.phone" in r008)
check("SCR-008 requires selected supplier master ID", "supplier.id === bj02Header.supplierId" in r008)
check("SCR-008 unresolved supplier guidance is inline", "Chọn nhà cung cấp trong danh sách." in r008 and "supplier-selection-error" in r008)

check("SCR-009 renderer exists", bool(r009))
check("SCR-009 displays receipt progress", "receipt-overview-progress" in r009 and "đã xử lý" in r009)
check("SCR-009 Quick empty state", "Chưa có sản phẩm" in r009 and "Sản phẩm phải có sẵn trong danh mục" in r009)
check("SCR-009 Quick add product is secondary", 'data-bj02-action="add-line"' in r009 and 'VButtonVariant.secondary' in r009)
check("SCR-009 review waits until every item handled", "!allReceiptLinesHandled()" in r009)
check("SCR-009 opens line cards via shared helper", "receiptLineCards()" in r009)
check("SCR-009 EMPTY is actual VEmptyState", 'state === "EMPTY"' in r009 and 'data-ds-component="VEmptyState"' in r009)
check("SCR-009 read-only hides Quick add and review mutation", 'const locked = ["LOCKED", "READ_ONLY"].includes(state)' in r009 and 'flowMode === "quick" && !locked' in r009 and 'reviewDisabled = locked' in r009)
check("SCR-009 item summary has two-level hierarchy", "receipt-line-primary" in fn_body(app, "receiptLineCards") and "receipt-line-secondary" in fn_body(app, "receiptLineCards"))

check("SCR-084 renderer exists", bool(r084))
check("SCR-084 has canonical title", 'title: "Chi tiết hàng thực nhận"' in r084)
check("SCR-084 primary action is Xong", 'primaryFooter("Xong"' in r084)
check("SCR-084 supports document not-received", "Chưa nhận lần này" in r084 and 'data-bj02-action="not-received"' in r084)
check("SCR-084 duplicate blocker exists", "Sản phẩm và đơn vị này đã có" in r084 and "Mở sản phẩm đã có" in r084)
check("SCR-084 duplicate blocker suppresses editor", 'if (duplicate) return appShell' in r084 and 'actions: ""' in r084)
check("SCR-084 document source expectation contextual", "Còn chờ nhận" in fn_body(app, "documentSourceContextHtml") and "Còn chờ nhận" in fn_body(app, "renderLotLineEditor") and "Theo chứng từ:" not in r084)
check("SCR-084 Quick existing item can be removed", 'data-bj02-action="remove-quick-line"' in r084 and "Xóa khỏi lần nhận" in r084)
check("SCR-084 true read-only hides mutation footer", "actions: locked ? """ in r084 and "lineEditorIsReadOnly" in r084)
check("SCR-084 document not-received remains available with existing data", 'data-bj02-action="not-received"' in r084 and "requestMarkLineNotReceived" in app and "VConfirmDialog" in fn_body(app, "requestMarkLineNotReceived"))
check("SCR-084 Back without edits preserves completed status", "let lineEditorDirty = false" in app and 'lineEditorDirty ? "PENDING" : (copy.status || "PENDING")' in app)

# Helpers forming SCR-084
picker = fn_body(app, "renderLineProductPicker")
nonlot = fn_body(app, "renderNonLotLineEditor")
lotline = fn_body(app, "renderLotLineEditor")
lotactive = fn_body(app, "renderActiveLotEditor")
exceptions = fn_body(app, "exceptionQuantitiesEditor")
valid = fn_body(app, "lineEditorValid")
select_product = fn_body(app, "selectLineProduct")
choose_uom = fn_body(app, "chooseLineUom")
duplicate = fn_body(app, "duplicateQuickLine")
check("Quick Product picker is VCombobox", 'data-ds-component="VCombobox"' in picker)
check("Product no-result has no create CTA", "Tạo sản phẩm" not in picker and "create-product" not in picker)
check("Product identity is compact read-only VCard", 'line-product-identity' in picker and 'card.readOnly' in picker)
check("UOM select appears only when >1 UOM", "uoms.length > 1" in picker and 'data-ds-component="VSelect"' in picker)
check("UOM selector is Quick-new-item only", 'flowMode === "quick" && !activeReceiptLineId' in picker and "needsUomChoice" in picker)
check("selected identity shows UOM once and hides selector", "needsUomChoice" in picker and "lineEditorDraft.uom || null" in picker)
check("Product search result compact metadata", "product.sku" in picker and "uomSummary" in picker and "trackingPolicy" not in picker)
check("single UOM auto-select", "product.uoms.length === 1" in select_product)
check("same Product+UOM duplicate guard", "line.productId === productId && line.uomId === uomId" in duplicate)
check("non-LOT asks total actual once", "Số lượng thực nhận" in nonlot and "data-bj02-line-total" in nonlot)
check("exception classification is progressive", "Có hàng cần phân loại khác?" in exceptions and all(x in exceptions for x in ["Cách ly", "Hỏng", "Từ chối nhận"]))
check("accepted is derived from total minus exceptions", "totals.totalReceived - totals.quarantine - totals.damaged - totals.rejected" in exceptions)
check("LOT section exists without LOT badge", "Lô hàng" in lotline and "vBadge(" not in lotline)
check("LOT supports add lot secondary", "Thêm lô" in lotline and "VButtonVariant.secondary" in lotline)
lotcompact = fn_body(app, "renderLotCompact")
add_lot = fn_body(app, "addEditorLot")
remove_lot = fn_body(app, "openRemoveLotDialog")
lot_feedback = fn_body(app, "lotIdentityFeedback")
check("LOT accordion can toggle manually", 'data-bj02-action="toggle-lot"' in lotcompact and "aria-expanded" in lotcompact)
check("LOT extra rows expose delete", 'data-bj02-action="remove-editor-lot"' in lotactive and "canRemove" in lotactive)
check("Add lot opens new lot", "activeLotDraftId = lot.id" in add_lot)
check("Lot removal uses VConfirmDialog for data", 'data-ds-component="VConfirmDialog"' in remove_lot and "lotHasData" in remove_lot)
check("Duplicate lot code blocked with open-existing CTA", "Lô này đã được thêm" in lot_feedback and "Mở lô đã có" in lot_feedback)
check("LOT requires code", "Mã lô" in lotactive and 'data-bj02-lot-field="code"' in lotactive)
check("LOT expiry required/optional by Product policy", "expiryRequired" in lotactive and 'data-ds-prop-required="${expiryRequired}"' in lotactive and "Không bắt buộc" not in lotactive)
check("LOT manufacture date progressive optional", "Thêm ngày sản xuất" in lotactive and "Ngày sản xuất" in lotactive)
check("LOT total is entered per lot", 'data-bj02-lot-total' in lotactive)
check("line validation blocks exception sum > total", "exceptionTotal <= totals.totalReceived" in valid and "(t.quarantine + t.damaged + t.rejected) <= t.totalReceived" in valid)
check("LOT validation requires all lot drafts", "lots.every" in valid and "!lots.length" in valid)
check("LOT validation requires expiry only when policy requires", "!lineEditorDraft.expiryRequired || lot.expiry.trim()" in valid)
check("LOT derived total summary exists", "Tổng thực nhận" in fn_body(app, "lineTotalSummaryHtml") and "data-bj02-editor-total-summary" in fn_body(app, "lineTotalSummaryHtml") and "lineTotalSummaryHtml(lineEditorDraft)" in lotline)
check("LOT delete is inside expanded content", "lot-delete-action-inline" in lotactive and "remove-editor-lot" in lotactive and "remove-editor-lot" not in fn_body(app, "renderLotCompact"))
check("existing classification exceptions auto-expand", "hasExceptions" in exceptions and "expandedFlag || hasExceptions" in exceptions)
variance = fn_body(app, "documentVarianceFeedback")
quantity_feedback = fn_body(app, "quantityFeedback")
live_feedback = fn_body(app, "updateBj02EditorLiveFeedback")
quick_delete_dialog = fn_body(app, "openRemoveQuickLineDialog")
check("Document under-source uses info feedback", 'vBanner("info", "Còn hàng chưa nhận"' in variance)
check("Document over-source uses warning feedback", 'vBanner("warning", "Số lượng giao vượt chứng từ"' in variance)
check("Document exact receipt suppresses redundant banner", "v.totalReceived === v.expected" in variance and 'return ""' in variance)
check("Cross-field exception overflow uses error feedback", 'vBanner("error", "Phân loại vượt số lượng thực nhận"' in quantity_feedback)
check("Live validation updates Xong button", "saveButton.disabled = !lineEditorValid()" in live_feedback)
check("Quick line delete uses VConfirmDialog", 'data-ds-component="VConfirmDialog"' in quick_delete_dialog)

check("SCR-010 renderer exists", bool(r010))
check("SCR-010 uses per-item review", "receiptLineCards({ review: true, includeLotDetails: true })" in r010)
check("SCR-010 no cross-UOM total quantity", "Tổng thực nhận" not in r010 and "Tăng tồn vật lý" not in r010)
check("SCR-010 Quick approval label", "Gửi phê duyệt" in r010)
check("SCR-010 no-approval label", "Xác nhận nhận hàng" in r010)
check("SCR-010 reviews actual LOT identity", "includeLotDetails: true" in r010 and "lineLotReviewDetails" in app)
check("SCR-010 Quick mandatory approval is info", 'vBanner(flowMode === "quick" ? "info" : "warning"' in r010)
check("SCR-010 suppresses duplicate APPROVAL_REQUIRED banner", '["PENDING_APPROVAL", "APPROVAL_REQUIRED"].includes(state)' in r010)
check("SCR-010 shows Quick note only when present", "bj02Header.note.trim()" in r010 and "noteRow" in r010)
check("SCR-010 price and approver blockers remain draft feedback", all(x in r010 for x in ["APPROVAL_PRICE_BASIS_REQUIRED", "APPROVER_CONFIGURATION_MISSING", "Hồ sơ vẫn ở Nháp"]))

check("SCR-011 renderer exists", bool(r011))
check("SCR-011 only approve/reject outcomes", "Duyệt" in r011 and "Từ chối" in r011 and "Yêu cầu bổ sung" not in r011)
check("SCR-011 uses per-item summary", "receiptLineCards({ review: true, includeLotDetails: true })" in r011)
check("SCR-011 supports financial masking", "FINANCIAL_MASKED" in r011 and "Không có quyền xem" in r011)
check("SCR-011 includes receiving context", all(x in r011 for x in ["Thông tin lần nhận", "Kho nhận", "Ngày nhận", "Căn cứ giao nhận"]))
check("SCR-011 reviews actual LOT identity", "includeLotDetails: true" in r011)
check("SCR-011 normal Quick approval reason is info", 'vBanner(flowMode === "quick" ? "info" : "warning"' in r011)
check("SCR-011 suppresses duplicate APPROVAL_REQUIRED banner", 'state === "APPROVAL_REQUIRED" ? "" : stateBanner(state)' in r011)

check("SCR-012 renderer exists", bool(r012))
check("SCR-012 has no receive mutation CTA", "Ghi nhận hàng" not in r012 and "ACT-02-RECEIVE" not in r012)
check("SCR-012 unknown tells user not to repeat", "Không thực hiện lại thao tác nhận hàng" in r012)
check("SCR-012 result is per-item", "receiptLineCards({ review: true, includeLotDetails: true })" in r012)
check("SCR-012 uses VEmptyState result", 'data-ds-component="VEmptyState"' in r012)
check("SCR-012 result group wording handles zero-receipt items", "Kết quả theo mục hàng" in r012)
check("SCR-012 result includes actual LOT identity", "includeLotDetails: true" in r012)
check("SCR-012 valuation banner is state-specific", 'state === "VALUATION_PENDING_RESULT"' in r012)

check("SCR-013 renderer exists", bool(r013))
check("SCR-013 same receipt recovery copy", "đúng lần nhận hiện tại" in r013 or "lần nhận này" in r013)
check("SCR-013 no blind retry CTA", "Thử lại" not in r013 and "Ghi lại" not in r013)
check("SCR-013 EMPTY uses VEmptyState", 'state === "EMPTY"' in r013 and "Chưa có kết quả mới" in r013 and 'data-ds-component="VEmptyState"' in r013)
check("SCR-013 PROCESSING_OR_UNKNOWN has no duplicate state warning", 'const stateNotice = stale ? stateBanner(state) : ""' in r013)
check("SCR-013 keeps at most one user-facing receipt reference", "Mã lần nhận REC-260817-04" in r013 and "APR-REC" not in r013 and "MOV-" not in r013 and "IO-" not in r013)

# --- User-facing copy gate ------------------------------------------------------
# Scan the dedicated BJ02 render path, not generic frozen renderers for other UIFs.
bj02_visible_source = "\n".join([r006, r007, r008, r009, r084, r010, r011, r012, r013, picker, nonlot, lotline, lotactive, exceptions])
for forbidden in ["Phase 1", "operation identity", "authoritative", "finality", "price basis", "tracking policy"]:
    check(f"product viewport avoids technical copy: {forbidden}", forbidden not in bj02_visible_source)
check("product viewport no English create-new CTA", "Create" not in bj02_visible_source and "Quick create" not in bj02_visible_source)

# --- DS gates ------------------------------------------------------------------
check("mobile width 402", re.search(r"\.device-preview\s*\{[^}]*width:\s*402px;", css, re.S) is not None)
check("mobile height 874", re.search(r"\.device-preview\s*\{[^}]*height:\s*874px;", css, re.S) is not None)
check("BJ02 new CSS is UIF scoped", 'body[data-active-uif="UIF-02"] .receipt-line-card' in css and 'body[data-active-uif="UIF-02"] .active-lot-editor' in css)
check("v0.2.9 item hierarchy CSS is UIF scoped", 'body[data-active-uif="UIF-02"] .receipt-line-primary' in css and 'body[data-active-uif="UIF-02"] .receipt-lot-review' in css)
check("v0.2.9 quantity context CSS is UIF scoped", 'body[data-active-uif="UIF-02"] .quantity-source-context' in css and 'body[data-active-uif="UIF-02"] .derived-total-row' in css)
check("footer primary profile medium", 'data-ds-profile="button.primaryFooter"' in app and 'data-ds-prop-size="VButtonSize.medium"' in app)
check("permission uses VEmptyState", 'function deniedBody()' in app and 'data-ds-component="VEmptyState"' in fn_body(app, "deniedBody") and "vBanner(" not in fn_body(app, "deniedBody"))
check("success icon maps circle-check", 'checkCircle: "VIcons.success"' in app and '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>' in app)
check("circle-check-big geometry absent", "M21.801 10A10 10 0 1 1 17 3.335" not in app)
check("VToast leading VIconBox", 'class="toast-icon-box" data-ds-component="VIconBox"' in fn_body(app, "showToastBj02"))
check("VToast close uses plain VIcons.close", 'data-ds-internal="VToast.close"' in fn_body(app, "showToastBj02") and 'data-ds-icon="VIcons.close"' in fn_body(app, "showToastBj02"))
check("VToast close CSS no circular decoration", re.search(r"\.toast-close[^\{]*\{[^}]*border:\s*0\s*!important;[^}]*border-radius:\s*0\s*!important;", css, re.S) is not None)
check("VBanner warning semantic CSS", ".v-banner--warning" in css and "var(--v-color-warning-bg)" in css)
check("VBanner error semantic CSS", ".v-banner--error" in css and "var(--v-color-danger-bg)" in css)
check("reject overlay uses VBottomSheet", 'data-ds-component="VBottomSheet"' in app and "Lý do từ chối" in app)

# --- Screen contracts / component usage ---------------------------------------
for sid in expected_bj02_screens:
    check(f"{sid} v0.2.9 screen contract", "BJ02_PILOT_SCREEN_CONTRACT_v0.2.9" in screen_docs.get(sid, ""))
check("SCR-008 contract is header only", "Chỉ chứa thông tin cấp receipt" in screen_docs.get("SCR-008", ""))
check("SCR-009 contract shared Document+Quick", "Shared receipt-lines overview" in screen_docs.get("SCR-009", ""))
check("SCR-084 contract one item editor", "một Product + UOM" in screen_docs.get("SCR-084", "") and "one-receipt-item editor" in screen_docs.get("SCR-084", ""))
check("SCR-084 contract forbids quick create", "Không Product/Supplier quick-create" in screen_docs.get("SCR-084", ""))
check("SCR-084 contract forbids document UOM selector", "không render `VSelect` UOM" in screen_docs.get("SCR-084", ""))
check("SCR-084 contract defines LOT accordion/delete", "Mỗi LOT là accordion" in screen_docs.get("SCR-084", "") and "Xóa lô" in screen_docs.get("SCR-084", ""))
check("SCR-084 contract defines partial/over feedback", "actual < source expected" in screen_docs.get("SCR-084", "") and "VBanner.warning" in screen_docs.get("SCR-084", ""))
check("SCR-008 contract defines compact Supplier result", "mã NCC + SĐT" in screen_docs.get("SCR-008", ""))
check("SCR-007 contract defines document search", "VSearchBar" in screen_docs.get("SCR-007", "") and "mã chứng từ hoặc nhà cung cấp" in screen_docs.get("SCR-007", ""))
check("SCR-009 contract defines true read-only", "true read-only" in screen_docs.get("SCR-009", ""))
check("SCR-084 contract defines contextual source total", "Còn chờ nhận" in screen_docs.get("SCR-084", "") and "derived summary" in screen_docs.get("SCR-084", ""))
check("SCR-010 contract requires actual LOT review", "lot code" in screen_docs.get("SCR-010", "").lower())
check("SCR-011 contract requires receiving context", "Thông tin lần nhận" in screen_docs.get("SCR-011", ""))
check("SCR-012 contract uses result group title", "Kết quả theo mục hàng" in screen_docs.get("SCR-012", ""))
check("SCR-013 contract removes technical log", "technical log" in screen_docs.get("SCR-013", "").lower() or "technical-log" in screen_docs.get("SCR-013", "").lower() or "technical IDs" in screen_docs.get("SCR-013", ""))
check("component usage version 0.2.9", "version: 0.2.9" in usage_yaml)
check("component usage includes SCR-084", "SCR-084" in usage_yaml and "SCR-084" in usage_md)
check("component usage one supplier guard", "exactly_one_supplier_per_receipt" in usage_yaml)
check("component usage no master create", "createSupplierInBJ02: forbidden" in usage_yaml and "createProductInBJ02: forbidden" in usage_yaml)
check("component usage mixed UOM separate items", "sameProductDifferentUom: separate_lines_allowed" in usage_yaml)
check("component usage document zero receipt", "NOT_RECEIVED_THIS_TIME" in usage_yaml)
try:
    import yaml
    yaml.safe_load(usage_yaml)
    check("UIF-02 component usage YAML parses", True)
except Exception as e:
    check("UIF-02 component usage YAML parses", False, str(e))

# --- Business docs / back propagation -----------------------------------------
bj = text(theme_root / "srs/02-business-journeys/02-BJ-02-nhan-hang-mua.md")
uc1 = text(theme_root / "srs/05-use-cases/BJ-02-nhan-hang-mua/UC-02-01-chuan-bi-nhan-theo-chung-tu.md")
uc2 = text(theme_root / "srs/05-use-cases/BJ-02-nhan-hang-mua/UC-02-02-chuan-bi-nhap-hang-nhanh.md")
uc3 = text(theme_root / "srs/05-use-cases/BJ-02-nhan-hang-mua/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md")
shared = text(theme_root / "srs/06-shared-behavioral-contracts.md")
data_entities = text(theme_root / "srs/04-data-entities.md")
decisions = text(theme_root / "know-how/decisions/decision-register.md")
glossary = text(theme_root / "know-how/glossary/glossary.md")
wiki = text(theme_root / "know-how/wiki/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md")
check("BJ02 amendment v0.2.8", "BJ-02 pilot amendment:** `v0.2.8`" in bj)
check("BJ02 locks one supplier", "Một receipt có đúng một Supplier" in bj)
check("BJ02 forbids Product/Supplier creation", "BJ-02 không tạo mới" in bj)
check("BJ02 defines multi-product", "Multi-product" in bj or "Multi-product" in bj.replace("multi-product", "Multi-product") or "nhiều sản phẩm" in bj)
check("BJ02 defines receipt item/UOM", "mục hàng = một Product + một transaction UOM" in bj)
check("BJ02 defines technical-line expansion", "materialize thành nhiều `InventoryOperationLine`" in bj)
check("BJ02 defines not received this time", "`Chưa nhận lần này`" in bj)
check("UC02-01 maps SCR-084", "SCR-084" in uc1)
check("UC02-01 contains multi-product source acceptance", "nhiều" in uc1 and "Chưa nhận lần này" in uc1)
check("UC02-01 defines valid partial receipt", "AS-UC-02-01-08" in uc1 and "partial receipt" in uc1)
check("UC02-01 defines over-source warning", "AS-UC-02-01-09" in uc1 and "cảnh báo ngay" in uc1)
check("UC02-02 maps SCR-009 and SCR-084", "SCR-009" in uc2 and "SCR-084" in uc2)
check("UC02-02 no create Product/Supplier", "không tạo" in uc2.lower() and "Supplier" in uc2 and "Product" in uc2)
check("UC02-02 mixed UOM separate item", "UOM khác" in uc2 or "khác UOM" in uc2)
check("UC02-03 pilot clarification v0.2.8", "Pilot clarification BJ02 v0.2.8" in uc3)
check("UC02-03 no supplement outcome", "<li>Yêu cầu bổ sung:" not in uc3)
check("shared behavior carries supplier/item grouping", "receipt_item" in shared or "receipt item" in shared.lower())
check("data entity has supplier_id", "`supplier_id`" in data_entities)
check("data entity has supplier_version_id", "`supplier_version_id`" in data_entities)
check("data entity has receipt_item_ref", "`receipt_item_ref`" in data_entities)
check("data entity clarifies item vs technical line", "Receipt item vs technical line" in data_entities)
for did in ["T7-DR-103", "T7-DR-104", "T7-DR-105"]:
    check(f"decision register contains {did}", did in decisions)
check("decision 103 one supplier/no-create", "Một nhà cung cấp trên một lần nhận" in decisions and "không tạo mới Supplier, Product" in decisions)
check("decision 104 multi-product/UOM", "Mục hàng, đơn vị giao dịch và nhiều sản phẩm" in decisions)
check("decision 105 complete source-item handling", "Chưa nhận lần này" in decisions)
check("glossary defines Receipt item", "Mục hàng nhận" in glossary and "Receipt item" in glossary)
check("wiki references new decisions", all(d in wiki for d in ["T7-DR-103", "T7-DR-104", "T7-DR-105"]))
check("wiki no legacy supplement decision", "Từ chối hoặc yêu cầu bổ sung" not in wiki)

# --- Registry ------------------------------------------------------------------
reg_screens = registry.get("screens", [])
check("screen registry has 84 entries", len(reg_screens) == 84)
check("screen registry IDs unique", len({s.get("screen_id") or s.get("id") for s in reg_screens}) == len(reg_screens))
reg84 = next((s for s in reg_screens if (s.get("screen_id") or s.get("id")) == "SCR-084"), None)
check("screen registry contains SCR-084", reg84 is not None)
check("screen registry version marks BJ02 pilot", "BJ02-pilot-v0.2.9" in registry.get("version", ""))

# --- Optional direct Flutter source verification -------------------------------
ds_root_env = os.environ.get("VET45_FLUTTER_DS_ROOT")
if ds_root_env:
    ds_root = Path(ds_root_env)
    try:
        vbanner = text(ds_root / "lib/src/components/v_banner.dart")
        vtoast = text(ds_root / "lib/src/components/v_toast.dart")
        vbottom = text(ds_root / "lib/src/components/v_bottom_sheet.dart")
        vappbar = text(ds_root / "lib/src/components/v_app_bar.dart")
        vicons = text(ds_root / "lib/src/foundations/icons/v_icons.dart")
        check("Flutter source VBanner warning semantic", "VBannerStatus.warning" in vbanner and "warningBg" in vbanner and "colors.warning" in vbanner)
        check("Flutter source VToast close icon", "VIcons.close" in vtoast and "size: 20" in vtoast)
        check("Flutter source VBottomSheet handle 36x4", "width: 36" in vbottom and "height: 4" in vbottom)
        check("Flutter source VAppBar title uses headingH3", "headingH3" in vappbar)
        check("Flutter source VIcons success exists", "VIcons.success" in vicons)
    except Exception as e:
        check("Flutter source readable", False, str(e))

passed = sum(1 for _, ok, _ in checks if ok)
failed = [(n, d) for n, ok, d in checks if not ok]
lines = [
    "# BJ-02 / UIF-02 HTML v0.2.9 — QA Conformance",
    "",
    f"- Checks: **{len(checks)}**",
    f"- Passed: **{passed}**",
    f"- Failed: **{len(failed)}**",
    "",
    "## Result",
    "",
    "**PASS**" if not failed else "**FAIL**",
    "",
    "## Checks",
    "",
]
for name, ok, detail in checks:
    lines.append(f'- [{"x" if ok else " "}] {name}' + (f" — {detail}" if detail else ""))
lines += [
    "",
    "## QA boundary",
    "",
    "- Scope is BJ-02/UIF-02 redesign plus the shared source-of-truth documents intentionally amended by BJ-02 decisions.",
    "- Non-BJ02 UIF flow/component/screen artifacts are validated separately by the isolation report.",
    "- Static renderer/business/contract/DS-source conformance is automated here.",
    "- Browser visual regression is a separate gate; this report does not claim pixel parity solely from static checks.",
]
(html_root / "qa/CONFORMANCE-REPORT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"{passed}/{len(checks)} passed")
for name, detail in failed:
    print("FAIL", name, detail)
sys.exit(1 if failed else 0)
