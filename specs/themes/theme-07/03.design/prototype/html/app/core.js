/* VET45 Theme 7 prototype — runtime (T7-P0, v5.0.0).
 *
 * Khung chung (đã sạch, sửa thẳng ở đây):
 *   - Phần "app.js" bên dưới: trạng thái (activeFlowId, activeScreenId, stateByScreen, flowMode…), bảng renderers,
 *     helper DS (appShell, ds24*, vBanner, primaryFooter, icon…), harness.
 *   - Mỗi hàm khung có MỘT định nghĩa: renderAppScreen (điều phối), renderInspector, renderFlowSelector,
 *     renderNavigation, syncReviewUrl, previousScreen. Chế độ "Toàn Theme 7" + Hub Kho nằm ở app/hub.js (ThemeApp).
 *   - renderAppScreen(): màn gốc chế độ theme → ThemeApp.renderRoot(); còn lại → renderFlowScreen() rồi ThemeApp.afterFlowRender().
 *
 * Legacy (xoá dần theo BJ ở T7-P — xem chú thích đầu app/bjNN.js):
 *   - Các khối có tiêu đề "===== vNNN-… =====" và "===== legacy-… =====" sau phần app.js là lớp vá cũ của từng BJ: gán lại renderers['SCR-…'],
 *     bọc renderFlowScreen / renderFlowInspector / navigate để sửa DOM sau dựng. Khi viết lại một BJ, chuyển hàm dựng cuối
 *     sang app/bjNN.js và xoá phần tương ứng ở đây; không thêm lớp vá mới.
 */
/* ===== figma-ds-runtime-map.js ===== */
window.VET45_FIGMA_DS_MAP = {"schemaVersion":2,"release":"2.2.0-candidate","source":{"parent":"2.1.2","figmaFileKey":"QVJolM5tAdFKkhP7RIwe3y","designSystemVersion":"2.0.3","componentPageId":"505:5890","patternTemplatePageId":"505:5891","foundationPageId":"505:5889","authority":"Figma DS","phase":"LIVE_EXISTING_COMPONENT_FIRST_CORRECTION","scope":"Canonical Figma DS mapping used by the cumulative Theme 7 runtime. UIF-01, UIF-02 and UIF-08 have structurally migrated Product implementations; other UIFs remain legacy until their own migration gate passes."},"statusSemantics":{"EXACT":"Exact canonical Figma target identity. This is source/mapping exactness only; it is NOT proof that the current legacy DOM anatomy is migrated.","EXACT_PATTERN":"Exact canonical Figma pattern target identity. This is source/mapping exactness only; it is NOT proof of current Product implementation.","LEGACY_ALIAS":"legacy HTML name resolves to canonical Figma asset","OWNED_SLOT":"not standalone; owned by canonical parent asset","EXACT_FOUNDATION":"Exact canonical Figma foundation/style/token target responsibility; current legacy UIF usage remains transitional until migrated.","CONTEXTUAL":"requires screen context but no custom convention may be invented","CONTEXTUAL_PATTERN":"pattern selected by interaction context","CONTEXTUAL_CARD":"generic legacy card must be decomposed/replaced contextually","MIGRATION_TARGET":"canonical target identified; visual composition change deferred to Phase 3/4","COMPOSITION":"allowed composition from canonical lower layers; not a new DS component","OPEN_DS_GAP":"recurring construct not represented by one canonical live asset","IMPLEMENTATION_DETAIL":"renderer/workbench implementation detail, not Product UI"},"precedence":["themeComponent","dsInternal","component+profile","component"],"componentMappings":{"VButton":{"layer":"COMPONENT","status":"EXACT","name":"VButton","nodeId":"521:529","assetType":"COMPONENT_SET","section":"01. Actions","note":"","variantPolicy":{}},"VTextField":{"layer":"COMPONENT","status":"EXACT","name":"VTextField","nodeId":"522:7186","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VTextarea":{"layer":"COMPONENT","status":"EXACT","name":"VTextarea","nodeId":"522:7212","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VMoneyField":{"layer":"COMPONENT","status":"EXACT","name":"VMoneyField","nodeId":"522:7322","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VCheckbox":{"layer":"COMPONENT","status":"EXACT","name":"VCheckbox","nodeId":"522:7397","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VRadio":{"layer":"COMPONENT","status":"EXACT","name":"VRadio","nodeId":"522:7410","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VSwitch":{"layer":"COMPONENT","status":"EXACT","name":"VSwitch","nodeId":"522:7427","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VSelect":{"layer":"COMPONENT","status":"EXACT","name":"VSelect","nodeId":"522:7291","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VSearchBar":{"layer":"COMPONENT","status":"EXACT","name":"VSearchBar","nodeId":"522:7245","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VDatePicker":{"layer":"COMPONENT","status":"EXACT","name":"VDatePicker","nodeId":"522:7368","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VFileDropZone":{"layer":"COMPONENT","status":"EXACT","name":"VFileDropZone","nodeId":"522:7507","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"","variantPolicy":{}},"VAppBar":{"layer":"COMPONENT","status":"EXACT","name":"VAppBar","nodeId":"547:1594","assetType":"COMPONENT_SET","section":"03. Navigation","note":"","variantPolicy":{}},"VBadge":{"layer":"COMPONENT","status":"EXACT","name":"VBadge","nodeId":"525:309","assetType":"COMPONENT_SET","section":"04. Data Display","note":"","variantPolicy":{}},"VChip":{"layer":"COMPONENT","status":"EXACT","name":"VChip","nodeId":"522:7449","assetType":"COMPONENT_SET","section":"04. Data Display","note":"","variantPolicy":{}},"VBanner":{"layer":"COMPONENT","status":"EXACT","name":"VBanner","nodeId":"526:4215","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Live master: Info/Default is content-driven; Compact is 72px; Success/Warning/Danger Default is 96px. Do not place multi-line copy in Compact.","variantPolicy":{"infoDefaultHeight":"HUG_CONTENT","compactHeight":"72","semanticDefaultHeight":"96","defaultPadding":"16","compactPaddingY":"12","gap":"12","iconSize":"20"}},"VToast":{"layer":"COMPONENT","status":"EXACT","name":"VToast","nodeId":"526:4305","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"","variantPolicy":{}},"VEmptyState":{"layer":"COMPONENT","status":"EXACT","name":"VEmptyState","nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"","variantPolicy":{}},"VLoading":{"layer":"COMPONENT","status":"EXACT","name":"VLoading","nodeId":"526:4373","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"","variantPolicy":{}},"VProgress":{"layer":"COMPONENT","status":"EXACT","name":"VProgress","nodeId":"526:4386","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"","variantPolicy":{}},"VSkeleton":{"layer":"COMPONENT","status":"EXACT","name":"VSkeleton","nodeId":"526:4380","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"","variantPolicy":{}},"VSegmentedControl":{"layer":"COMPONENT","status":"EXACT","name":"VSegmentedControl ","nodeId":"1049:9619","assetType":"COMPONENT_SET","section":"03. Navigation","note":"","variantPolicy":{}},"VModal":{"layer":"COMPONENT","status":"EXACT","name":"VModal","nodeId":"550:1275","assetType":"COMPONENT_SET","section":"06. Overlays","note":"","variantPolicy":{}},"VNumericKeypadSheet":{"layer":"COMPONENT","status":"EXACT","name":"VNumericKeypadSheet","nodeId":"1829:16196","assetType":"COMPONENT_SET","section":"06. Overlays","note":"","variantPolicy":{}},"VText":{"layer":"FOUNDATION","status":"EXACT_FOUNDATION","name":"VET45 v2 Typography styles","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Resolve to the canonical text style by semantic role; legacy VText is a primitive, not a Components-page master.","variantPolicy":{}},"VIcon":{"layer":"FOUNDATION","status":"EXACT_FOUNDATION","name":"VET45 approved Icon Library","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Use the canonical icon registry / Lucide-backed VET45 icon instances; icon size and touch target remain independent.","variantPolicy":{}},"VPagePadding":{"layer":"FOUNDATION","status":"EXACT_FOUNDATION","name":"Layout/Mobile edge = 16","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Page body/footer horizontal padding is foundation layout responsibility.","variantPolicy":{}},"VPageScaffold":{"layer":"TEMPLATE","status":"CONTEXTUAL","name":"Mobile / Detail","nodeId":"551:1396","assetType":"COMPONENT","section":"09. Page Templates","note":"Legacy scaffold has no 1:1 template. Phase 3/4 selects Root List / Nested List / Detail / Form / Wizard / Search & Select / State from screen task and entry architecture.","variantPolicy":{}},"VTextFormField":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"VTextField","nodeId":"522:7186","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"Single-line legacy fields map to VTextField; multiline instances map to VTextarea via runtime resolver.","variantPolicy":{}},"VNumberField":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"VTextField","nodeId":"522:7186","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"Numeric input uses VTextField semantics. Numeric keypad overlay, where required, uses VNumericKeypadSheet.","variantPolicy":{}},"VDatePickerField":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"VDatePicker","nodeId":"522:7368","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"Legacy field alias resolves to canonical VDatePicker.","variantPolicy":{}},"VConfirmDialog":{"layer":"PATTERN","status":"LEGACY_ALIAS","name":"DS v2 / Confirmation Sheet","nodeId":"550:1058","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns","note":"Destructive confirmation is a pattern responsibility, not a custom dialog.","variantPolicy":{}},"VBottomSheet":{"layer":"COMPONENT","status":"EXACT","name":"VBottomSheet","nodeId":"4695:6353","assetType":"COMPONENT","section":"06. Overlays","note":"Live canonical VBottomSheet master verified 2026-09-09. Prefer directly over custom Product sheet shells when only generic bottom-sheet structure is required.","variantPolicy":{}},"VCombobox":{"layer":"PATTERN","status":"CONTEXTUAL_PATTERN","name":"DS v2 / Search Results Dropdown","nodeId":"1280:6272","assetType":"COMPONENT_SET","section":"05. List Patterns","note":"Combobox behavior decomposes to canonical field/search + Search Results Dropdown; product semantics choose Product or Entity result pattern.","variantPolicy":{}},"VChoiceList":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Choice group from VRadio / VCheckbox","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"No standalone ChoiceList master in live DS; compose canonical selection controls.","variantPolicy":{}},"VQuantitySelector":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"VTextField","nodeId":"522:7186","assetType":"COMPONENT_SET","section":"02. Inputs & Selection","note":"Phase 4: historical plain quantity annotations are normalized to canonical VTextField; no active Theme 7 Product render uses VQuantitySelector.","variantPolicy":{}},"VSection":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Section layout","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Semantic section/layout wrapper; uses foundation spacing and typography rather than inventing a reusable visual component.","variantPolicy":{}},"VCard":{"layer":"COMPOSITION","status":"CONTEXTUAL_CARD","name":"Contextual data-display surface","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Legacy generic card key is retained for trace only. Phase 4 active Product renders must not resolve to VCard; use a canonical data-display asset or justified VSection composition.","variantPolicy":{}},"VCardTitle":{"layer":"FOUNDATION","status":"OWNED_SLOT","name":"VET45 v2 Typography styles","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Owned content slot; resolve text style by card family/context.","variantPolicy":{}},"VCardIcon":{"layer":"FOUNDATION","status":"OWNED_SLOT","name":"VET45 approved Icon Library","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Owned content slot; resolve icon tone/size through semantic icon variables.","variantPolicy":{}},"VIconBox":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Icon presentation container","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Non-interactive icon container is a composition. Interactive icon-only actions must use DS v2 / Icon Button.","variantPolicy":{}},"VEmptyMedia":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VEmptyState","nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Media slot of VEmptyState; not a separate component master.","variantPolicy":{}},"VEmptyTitle":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VEmptyState","nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Title slot of VEmptyState; not a separate component master.","variantPolicy":{}},"VEmptyDescription":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VEmptyState","nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Description slot of VEmptyState; not a separate component master.","variantPolicy":{}},"VAppBarTitle":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VAppBar","nodeId":"547:1594","assetType":"COMPONENT_SET","section":"03. Navigation","note":"Title slot of VAppBar.","variantPolicy":{}},"VAppBarSubtitle":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VAppBar","nodeId":"547:1594","assetType":"COMPONENT_SET","section":"03. Navigation","note":"Subtitle/context slot of VAppBar.","variantPolicy":{}},"VSegmentedControlItem":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VSegmentedControl ","nodeId":"1049:9619","assetType":"COMPONENT_SET","section":"03. Navigation","note":"Segment item is owned by the canonical control.","variantPolicy":{}},"VSegmentedButton":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"VSegmentedControl ","nodeId":"1049:9619","assetType":"COMPONENT_SET","section":"03. Navigation","note":"Legacy segmented button/group must normalize to VSegmentedControl.","variantPolicy":{}}},"profileMappings":{"VButton|button.primaryFooter":{"layer":"PATTERN","status":"EXACT_PATTERN","name":"DS v2 / Sticky Footer","nodeId":"549:927","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns","note":"Footer composition is governed by Sticky Footer and contains canonical VButton.","variantPolicy":{}},"VButton|button.secondary":{"layer":"COMPONENT","status":"EXACT","name":"VButton","nodeId":"521:529","assetType":"COMPONENT_SET","section":"01. Actions","note":"Secondary hierarchy normalized at runtime.","variantPolicy":{}},"VButton|button.destructiveSecondary":{"layer":"COMPONENT","status":"EXACT","name":"VButton","nodeId":"521:529","assetType":"COMPONENT_SET","section":"01. Actions","note":"Destructive action normalizes to Danger hierarchy; no custom destructive-secondary component.","variantPolicy":{}},"VSearchBar|search.standard":{"layer":"PATTERN","status":"CONTEXTUAL_PATTERN","name":"DS v2 / Search & Filter Header","nodeId":"547:2306","assetType":"COMPONENT_SET","section":"05. List Patterns","note":"When search and filter participate in list discovery, use Search & Filter Header; search-only remains VSearchBar.","variantPolicy":{}},"VPagePadding|screen.body.standard":{"layer":"FOUNDATION","status":"EXACT_FOUNDATION","name":"Layout/Mobile edge = 16","nodeId":null,"assetType":"FOUNDATION","section":"DS v2 — 01 Foundations & Icons","note":"Canonical mobile body gutter.","variantPolicy":{}},"VPageScaffold|screen.shell.standard":{"layer":"TEMPLATE","status":"CONTEXTUAL","name":"Mobile / Detail","nodeId":"551:1396","assetType":"COMPONENT","section":"09. Page Templates","note":"Screen template chosen by task/surface in Phase 3/4; scaffold itself is not a canonical component.","variantPolicy":{}},"VCard|card.readOnly":{"layer":"COMPOSITION","status":"CONTEXTUAL_CARD","name":"Read-only data display","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Legacy trace only. Phase 4 active Product UI must resolve read-only data to Summary Card / Info Row / Key-value Row / Record Card or justified composition.","variantPolicy":{}},"VCard|card.interactive":{"layer":"COMPOSITION","status":"CONTEXTUAL_CARD","name":"Interactive record/list item","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Legacy trace only. Phase 4 active Product UI must resolve interactive records to DS v2 / List Row / Record Card or justified composition.","variantPolicy":{}},"VBottomSheet|approval.reject":{"layer":"PATTERN","status":"EXACT_PATTERN","name":"DS v2 / Confirmation Sheet","nodeId":"550:1058","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns","note":"Approval rejection with reason is confirmation/form-sheet composition; no custom bottom-sheet convention.","variantPolicy":{}}},"themeComponentMappings":{"PermissionDeniedState":{"layer":"COMPONENT","status":"EXACT","name":"VEmptyState","nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Use Type=No Permission.","variantPolicy":{}},"Theme7InventoryProductRow":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / List Row","nodeId":"525:519","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"Theme7InventoryLotRow":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / List Row","nodeId":"525:519","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"Theme7InventoryProvenanceEntry":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / List Row","nodeId":"525:519","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"InventoryOperationItemRow":{"layer":"COMPONENT","status":"LEGACY_ALIAS","name":"DS v2 / List Row","nodeId":"525:519","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: legacy annotation is bypassed in all active UIFs; active operational rows render canonical DS v2 / List Row.","variantPolicy":{}},"Theme7InventoryFilterRow":{"layer":"PATTERN","status":"EXACT_PATTERN","name":"DS v2 / Search & Filter Header","nodeId":"547:2306","assetType":"COMPONENT_SET","section":"05. List Patterns","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"InventoryTaskFilterRow":{"layer":"PATTERN","status":"LEGACY_ALIAS","name":"DS v2 / Search & Filter Header","nodeId":"547:2306","assetType":"COMPONENT_SET","section":"05. List Patterns","note":"Phase 4: legacy filter-row key is retained for trace only; active list discovery composes canonical VSearchBar/VChip under Figma list-pattern responsibility.","variantPolicy":{}},"Theme7InventoryQuantityRow":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / Info Row","nodeId":"525:351","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"Theme7InventorySummaryCard":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / Summary Card","nodeId":"525:552","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset.","variantPolicy":{}},"Theme7InventoryRecordList":{"layer":"COMPOSITION","status":"COMPOSITION","name":"List container of DS v2 / List Row","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: layout-only container composed from canonical DS v2 / List Row children.","variantPolicy":{}},"Theme7InventoryEvidenceRows":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Evidence fact rows from DS v2 / Info Row","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: evidence container is layout-only; each fact row uses canonical DS v2 / Info Row.","variantPolicy":{}},"OperationEvidenceTimeline":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / Timeline Item","nodeId":"525:587","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: repeated operation evidence events use canonical DS v2 / Timeline Item.","variantPolicy":{}},"Theme7EvidenceTimeline":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Timeline from DS v2 / Timeline Item","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: timeline container is layout-only; events use canonical Timeline Item responsibility.","variantPolicy":{}},"ReceivingProductSummary":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / Summary Card","nodeId":"525:552","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: selected-product summary uses canonical DS v2 / Summary Card.","variantPolicy":{}},"ReceivingBalanceSummary":{"layer":"COMPONENT","status":"EXACT","name":"DS v2 / Summary Card","nodeId":"525:552","assetType":"COMPONENT_SET","section":"04. Data Display","note":"Phase 4: receiving balance summary uses DS v2 / Summary Card responsibility.","variantPolicy":{}},"Theme7QuickReceiptProductSearch":{"layer":"PATTERN","status":"EXACT_PATTERN","name":"DS v2 / Search Results Dropdown","nodeId":"1280:6272","assetType":"COMPONENT_SET","section":"05. List Patterns","note":"Phase 4: quick product lookup uses canonical Search Results Dropdown/Product responsibility with VSearchBar.","variantPolicy":{}},"ReceivingLotEditor":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Form composition under Mobile / Form","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: nested LOT editor follows Mobile / Form anatomy using canonical fields; it is not itself a page-template instance.","variantPolicy":{}},"LotAllocationSection":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Allocation section from canonical rows/fields","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: allocation editor is a screen-local composition from canonical form fields, date input and actions; no custom DS master is introduced.","variantPolicy":{}},"Theme7OperationResult":{"layer":"TEMPLATE","status":"EXACT_PATTERN","name":"Mobile / State","nodeId":"551:1746","assetType":"COMPONENT","section":"09. Page Templates","note":"Phase 4: authoritative operation results use Mobile / State responsibility with VEmptyState/result facts; behavior remains business-defined.","variantPolicy":{}},"Theme7InlineSingleChoice":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Selection group from DS v2 / List Row","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: full-row mobile choice uses canonical DS v2 / List Row Type=Selection rather than a feature-specific card.","variantPolicy":{}},"PickLotAllocation":{"layer":"COMPOSITION","status":"COMPOSITION","name":"LOT allocation from List Row + quantity input","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: LOT allocation is a business composition from canonical list/fact/form primitives; no standalone DS component is invented.","variantPolicy":{}},"ReturnLotMismatchReasons":{"layer":"COMPOSITION","status":"COMPOSITION","name":"Single-choice group from VRadio","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Phase 4: audited mismatch reasons are a single-choice group composed from canonical VRadio semantics.","variantPolicy":{}}},"internalMappings":{"VAppBar.leading":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VAppBar","nodeId":"547:1594","assetType":"COMPONENT_SET","section":"03. Navigation","note":"Leading navigation slot owned by VAppBar.","variantPolicy":{}},"VBanner.icon":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VBanner","nodeId":"526:4215","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Icon slot owned by VBanner.","variantPolicy":{}},"VBanner.copy":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VBanner","nodeId":"526:4215","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Copy slot owned by VBanner.","variantPolicy":{}},"VLoading.CircularProgressIndicator":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VLoading","nodeId":"526:4373","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Internal loading indicator owned by VLoading.","variantPolicy":{}},"VBottomSheet.handle":{"layer":"COMPOSITION","status":"OWNED_SLOT","name":"Bottom-sheet pattern handle","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Pattern-internal presentation; not a standalone Product component.","variantPolicy":{}},"VBottomSheet.title":{"layer":"COMPOSITION","status":"OWNED_SLOT","name":"Bottom-sheet pattern title","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Pattern-internal title slot.","variantPolicy":{}},"VBottomSheet.divider":{"layer":"COMPOSITION","status":"OWNED_SLOT","name":"Bottom-sheet pattern divider","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Pattern-internal separator.","variantPolicy":{}},"showVBottomSheet.SafeArea":{"layer":"COMPOSITION","status":"IMPLEMENTATION_DETAIL","name":"Bottom-sheet safe-area behavior","nodeId":null,"assetType":"COMPOSITION","section":null,"note":"Pattern implementation detail; never exposed as Product component.","variantPolicy":{}},"VToast.message":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VToast","nodeId":"526:4305","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Message slot owned by VToast.","variantPolicy":{}},"VToast.close":{"layer":"COMPONENT","status":"OWNED_SLOT","name":"VToast","nodeId":"526:4305","assetType":"COMPONENT_SET","section":"05. Feedback & Status","note":"Close affordance owned by VToast.","variantPolicy":{}}},"screenTemplatePolicy":{"list":"Root List or Nested List — decide from entry architecture/back hierarchy in Phase 3","form":"Mobile / Form unless a true multi-step task requires Mobile / Wizard","detail":"Mobile / Detail","review":"Mobile / Detail or Mobile / Form according to whether user edits before commit; calibrate in Phase 3","result":"Mobile / State","timeline":"Mobile / Detail","dashboard":"Mobile / Detail","overlay":"Canonical overlay pattern, not a page template","choice":"Mobile / Form or State by task; calibrate","status / entry":"Mobile / State","validation result":"Mobile / State","approval review":"Mobile / Detail / Form according to editable decision inputs"},"variantNormalization":{"VButton":{"Hierarchy":"tone=danger => Danger; else variant primary/secondary/tertiary => Primary/Secondary/Tertiary","State":"disabled => Disabled; loading marker => Loading; else Default","Size":"small => Small; medium/default => Default; large => Large"},"VBadge":{"Tone":"success/warning/danger/info => Success/Warning/Danger/Info; else Neutral","Style":"Soft unless a screen contract explicitly requires Strong"},"VBanner":{"Tone":"error legacy value normalizes to Danger; info/success/warning preserve semantic tone","Density":"Default unless compact is explicitly contracted"},"VAppBar":{"Type":"back+subtitle => Context; back => Back; root+subtitle => Root context; root => Root"},"VEmptyState":{"Type":"PermissionDeniedState => No Permission; filtered no-result => No Result; error/blocked/empty by business state"},"VText":"data-ds-prop-variant or semantic element role maps to live VET45 v2 Text Style; legacy bodyMedium maps to Body / Default until a distinct style exists"},"governance":{"reuseOrder":["Component","Pattern","Template","Composition"],"noPrefixBoundary":true,"noSilentCustomConvention":true,"genericCardPolicy":"VCard is migration debt, not a canonical Figma component.","productBehaviorFrozen":true,"screenCompositionChangedInThisRelease":false},"assetIndex":{"DS v2 / Collapsible Note":{"nodeId":"1062:8765","assetType":"COMPONENT_SET","section":"07. Interaction"},"DS v2 / Financial Disclosure/Collapsed":{"nodeId":"2144:9874","assetType":"COMPONENT","section":"07. Interaction"},"DS v2 / Financial Disclosure/Expanded":{"nodeId":"2144:9886","assetType":"COMPONENT","section":"07. Interaction"},"VSwipeActionRecord":{"nodeId":"1001:7250","assetType":"COMPONENT_SET","section":"07. Interaction"},"VButton":{"nodeId":"521:529","assetType":"COMPONENT_SET","section":"01. Actions"},"DS v2 / FAB/Default/Default":{"nodeId":"521:663","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / FAB/Default/Pressed":{"nodeId":"521:669","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / FAB/Default/Disabled":{"nodeId":"521:674","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / FAB/Small/Default":{"nodeId":"521:679","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / FAB/Small/Pressed":{"nodeId":"521:684","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / FAB/Small/Disabled":{"nodeId":"521:689","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / Icon Button":{"nodeId":"4431:10317","assetType":"COMPONENT_SET","section":"01. Actions"},"DS v2 / Link":{"nodeId":"4431:10396","assetType":"COMPONENT_SET","section":"01. Actions"},"DS v2 / Action Row/Default":{"nodeId":"521:695","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / Action Row/Danger":{"nodeId":"521:708","assetType":"COMPONENT","section":"01. Actions"},"DS v2 / Action Row/Disabled":{"nodeId":"521:720","assetType":"COMPONENT","section":"01. Actions"},"VTextField":{"nodeId":"522:7186","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VTextarea":{"nodeId":"522:7212","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VMoneyField":{"nodeId":"522:7322","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VCheckbox":{"nodeId":"522:7397","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VRadio":{"nodeId":"522:7410","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VSwitch":{"nodeId":"522:7427","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VSelect":{"nodeId":"522:7291","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VSearchBar":{"nodeId":"522:7245","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VDatePicker":{"nodeId":"522:7368","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VFileDropZone":{"nodeId":"522:7507","assetType":"COMPONENT_SET","section":"02. Inputs & Selection"},"VAppBar":{"nodeId":"547:1594","assetType":"COMPONENT_SET","section":"03. Navigation"},"VTabs (Có Disabled)":{"nodeId":"522:7478","assetType":"COMPONENT_SET","section":"03. Navigation"},"VTabs":{"nodeId":"547:2501","assetType":"COMPONENT_SET","section":"03. Navigation"},"VSegmentedControl ":{"nodeId":"1049:9619","assetType":"COMPONENT_SET","section":"03. Navigation"},"VSteps":{"nodeId":"526:4417","assetType":"COMPONENT_SET","section":"03. Navigation"},"VBottomNavigationBar / Tenant":{"nodeId":"570:164","assetType":"COMPONENT_SET","section":"03. Navigation"},"VBottomNavigationBar / Platform":{"nodeId":"547:2463","assetType":"COMPONENT_SET","section":"03. Navigation"},"VStepProgress":{"nodeId":"547:2618","assetType":"COMPONENT_SET","section":"03. Navigation"},"DS v2 / Context Header":{"nodeId":"1713:9357","assetType":"COMPONENT","section":"03. Navigation"},"DS v2 / List Top Bar":{"nodeId":"547:2223","assetType":"COMPONENT_SET","section":"03. Navigation"},"VAvatar":{"nodeId":"525:284","assetType":"COMPONENT_SET","section":"04. Data Display"},"VBadge":{"nodeId":"525:309","assetType":"COMPONENT_SET","section":"04. Data Display"},"VChip":{"nodeId":"522:7449","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Metric Card":{"nodeId":"525:382","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Entity Card":{"nodeId":"525:539","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Summary Card":{"nodeId":"525:552","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Media Card":{"nodeId":"567:557","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Record Card":{"nodeId":"1001:7201","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Info Row":{"nodeId":"525:351","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Key-value Row":{"nodeId":"525:358","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / List Row":{"nodeId":"525:519","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Timeline Item":{"nodeId":"525:587","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Audit Item":{"nodeId":"525:621","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Avata Card":{"nodeId":"791:24159","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Product Result Card":{"nodeId":"1234:6260","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Order Line Row":{"nodeId":"1683:5847","assetType":"COMPONENT_SET","section":"04. Data Display"},"DS v2 / Payment & Receivable Summary Row/Default":{"nodeId":"2099:5459","assetType":"COMPONENT","section":"04. Data Display"},"DS v2 / Payment & Receivable Summary Row/Outstanding":{"nodeId":"2099:5469","assetType":"COMPONENT","section":"04. Data Display"},"DS v2 / Payment & Receivable Summary Row/Muted":{"nodeId":"2099:5479","assetType":"COMPONENT","section":"04. Data Display"},"VBanner":{"nodeId":"526:4215","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VToast":{"nodeId":"526:4305","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VEmptyState":{"nodeId":"526:4352","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VLoading":{"nodeId":"526:4373","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VProgress":{"nodeId":"526:4386","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VSkeleton":{"nodeId":"526:4380","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"DS v2 / Readiness Item":{"nodeId":"526:4442","assetType":"COMPONENT_SET","section":"05. Feedback & Status"},"VModal":{"nodeId":"550:1275","assetType":"COMPONENT_SET","section":"06. Overlays"},"VNumericKeypadSheet":{"nodeId":"1829:16196","assetType":"COMPONENT_SET","section":"06. Overlays"},"DS v2 / Sticky Footer":{"nodeId":"549:927","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / FAB Placement":{"nodeId":"549:958","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Keyboard-safe Action Bar":{"nodeId":"549:1007","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Action Sheet":{"nodeId":"550:999","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Confirmation Sheet":{"nodeId":"550:1058","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Select Sheet":{"nodeId":"550:1148","assetType":"COMPONENT","section":"04. Interaction & Overlay Patterns"},"DS v2 / Filter Sheet":{"nodeId":"1149:6895","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Toast Layer":{"nodeId":"550:1347","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"Loading Overlay":{"nodeId":"550:1298","assetType":"COMPONENT_SET","section":"04. Interaction & Overlay Patterns"},"DS v2 / Search & Filter Header":{"nodeId":"547:2306","assetType":"COMPONENT_SET","section":"05. List Patterns"},"DS v2 / Search Results Dropdown/Product/Results":{"nodeId":"1280:6203","assetType":"COMPONENT","section":"05. List Patterns"},"DS v2 / Search Results Dropdown/Entity/Results":{"nodeId":"1280:6136","assetType":"COMPONENT","section":"05. List Patterns"},"DS v2 / Search Results Dropdown":{"nodeId":"1280:6272","assetType":"COMPONENT_SET","section":"05. List Patterns"},"DS v2 / Form Sheet":{"nodeId":"1353:6355","assetType":"COMPONENT","section":"06. Form Patterns"},"Mobile / Root List":{"nodeId":"551:549","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Nested List":{"nodeId":"551:1277","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Detail":{"nodeId":"551:1396","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Form":{"nodeId":"551:1452","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Wizard":{"nodeId":"551:1530","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Search & Select":{"nodeId":"551:1621","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / State":{"nodeId":"551:1746","assetType":"COMPONENT","section":"09. Page Templates"},"Mobile / Identity":{"nodeId":"551:1777","assetType":"COMPONENT","section":"09. Page Templates"}},"dynamicResolution":{"VButton.link":"Legacy VButtonVariant.link resolves to canonical DS v2 / Link instead of VButton.","VTextFormField.multiline":"A legacy VTextFormField containing textarea resolves to canonical VTextarea.","VPageScaffold.template":"Explicit base template follows the business screen archetype; true centered VEmptyState surfaces dynamically resolve to Mobile / State.","VEmptyState.type":"No Permission / No Result / Error / Blocked / Empty is inferred from the rendered business state and content for Inspect only."},"phase3":{"scope":["UIF-02","UIF-05","UIF-08","UIF-10","UIF-15","UIF-17"],"rule":"Representative Product surfaces may use direct live Figma asset names; generic VCard/VQuantitySelector debt is removed from calibrated renders; explicit template mapping is authoritative for calibrated screens."},"phase4":{"status":"FULL_ROLLOUT_CANDIDATE","parent":"2.0.2","flows":17,"canonicalActiveScreens":73,"activeStateRenders":497,"policy":"Active Product renders must resolve to live Figma Components/Patterns/Templates or justified COMPOSITION; no MIGRATION_TARGET, OPEN_DS_GAP, or CONTEXTUAL_CARD annotations."},"phase5":{"status":"FINAL_CONFORMANCE_CANDIDATE","parent":"2.1.0","flows":17,"canonicalActiveScreens":73,"activeStateRenders":497,"policy":"Result/status/validation business surfaces use Detail by default; Mobile / State is reserved for actual full-content Empty/Error/No Permission/Blocked/No Result. Success result anatomy is VSection composition, not a synthetic VEmptyState variant. Exact Info Row, VTextarea and VMoneyField responsibilities are enforced globally."},"implementationSemantics":{"sourceReadiness":"MAPPING_EXACT_RUNTIME_GATES_OPEN","productImplementation":"MIXED_BY_UIF_SEE_UIF_MIGRATION_STATUS","proofRule":"A screen/component is migrated only after structure + variants/states + exact canonical responsibility + visual + behavior gates pass. Current migrated scope is UIF-01/UIF-02/UIF-08; data-figma-node alone is insufficient."},"readiness":{"release":"2.2.0-candidate","sourceLock":"FIGMA-DS-SOURCE-LOCK.json","livePreflight":"../../html/qa/FIGMA-DS-LIVE-PREFLIGHT-v2.2.0.json","approvedIconLibrary":"figma-approved-icon-library.json","iconDemand":"../../html/qa/FIGMA-DS-ICON-DEMAND-v2.2.0.json","overlayRegister":"FIGMA-DS-OVERLAY-MIGRATION-REGISTER-v2.2.0.json","uifStatus":"UIF-MIGRATION-STATUS.json"},"componentSelectionPriority":["V_COMPONENT_IF_SEMANTICALLY_VALID","EXISTING_NON_V_COMPONENT","EXISTING_PATTERN_OR_TEMPLATE","LAYOUT_COMPOSITION_OF_EXISTING_DS_ASSETS","NEW_COMPONENT_ONLY_AFTER_PROVEN_REUSABLE_GAP"],"runtimeRelease":"2.5.1"};

/* ===== app.js ===== */
const HARNESS = window.VET45_HARNESS_DATA || { flows: [], screens: [], runOrder: [] };
const FIGMA_DS_MAP = window.VET45_FIGMA_DS_MAP || { componentMappings:{}, profileMappings:{}, themeComponentMappings:{}, internalMappings:{} };
// v4.6.1 review fixtures. These are runtime inputs, not business decisions.
window.__VET45_MONEY_CURRENCY_CATALOG__ = window.__VET45_MONEY_CURRENCY_CATALOG__ || [{id:"VND",label:"VND"},{id:"USD",label:"USD"}];
window.__VET45_FX_SOURCE_FIXTURE__ = window.__VET45_FX_SOURCE_FIXTURE__ || {VND:{rate:1,version:"LOCAL-VND"},USD:{rate:24450,version:"FX-DEMO-USD-202609"}};
window.__VET45_TAX_TREATMENT_POLICY__ = window.__VET45_TAX_TREATMENT_POLICY__ || {version:"TAX-HKD-DEMO-v1",recoverableRate:0};
window.__VET45_TENANT_COST_POLICY__ = window.__VET45_TENANT_COST_POLICY__ || {version:"COST-POLICY-DEMO-v1",method:"PERIODIC",label:"Bình quân cuối kỳ",periodCloseScopes:[{id:"ALL_PRODUCTS",label:"Toàn bộ sản phẩm"},{id:"DIRTY_PRODUCTS_ONLY",label:"Sản phẩm cần tính lại"}],fixture:true};
// v2.7.1 — live Figma DS correction: List Row density/affordance, grouped Info Row surfaces, VToast, and Key-value Row fidelity; BJ05 business behavior unchanged.
// Figma DS v2.0.3 is UI authority; business authority remains in BJ/UC/decision/contracts.
const FIGMA_MIGRATED_FLOWS = new Set([
  "UIF-01","UIF-02","UIF-03","UIF-04","UIF-05","UIF-06","UIF-07","UIF-08","UIF-09",
  "UIF-10","UIF-11","UIF-12","UIF-13","UIF-14","UIF-15","UIF-16","UIF-17","CAP-01"
]);
const FIGMA_TEMPLATE_NODES = {
  "Mobile / Root List":"551:549", "Mobile / Nested List":"551:1277", "Mobile / Detail":"551:1396",
  "Mobile / Form":"551:1452", "Mobile / Wizard":"551:1530", "Mobile / Search & Select":"551:1621", "Mobile / State":"551:1746"
};
const FIGMA_TEMPLATE_BY_FLOW_SCREEN = {
  "UIF-01":{"SCR-001":"Mobile / Root List","SCR-003":"Mobile / Detail"},
  "UIF-02":{"SCR-006":"Mobile / Nested List","SCR-007":"Mobile / Nested List","SCR-008":"Mobile / Form","SCR-009":"Mobile / Nested List","SCR-084":"Mobile / Form","SCR-010":"Mobile / Detail","SCR-011":"Mobile / Detail","SCR-012":"Mobile / Detail","SCR-013":"Mobile / Detail"},
  "UIF-03":{"SCR-014":"Mobile / Root List","SCR-015":"Mobile / Form","SCR-017":"Mobile / Detail","SCR-019":"Mobile / Detail"},
  "UIF-04":{"SCR-021":"Mobile / Detail"},
  "UIF-05":{"SCR-025":"Mobile / Root List","SCR-026":"Mobile / Detail","SCR-027":"Mobile / Form","SCR-028":"Mobile / Detail","SCR-029":"Mobile / Detail"},
  "UIF-06":{"SCR-030":"Mobile / Root List","SCR-031":"Mobile / Detail","SCR-032":"Mobile / Form","SCR-034":"Mobile / Detail","SCR-033":"Mobile / Form","SCR-035":"Mobile / Detail"},
  "UIF-07":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-039":"Mobile / Detail","SCR-041":"Mobile / Detail"},
  "UIF-08":{"SCR-042":"Mobile / Nested List","SCR-043":"Mobile / Form","SCR-044":"Mobile / Form","SCR-045":"Mobile / Form","SCR-046":"Mobile / Detail","SCR-047":"Mobile / Detail"},
  "UIF-09":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-038":"Mobile / Form","SCR-041":"Mobile / Detail","SCR-056":"Mobile / Detail"},
  "UIF-10":{"SCR-036":"Mobile / Root List","SCR-037":"Mobile / Detail","SCR-040":"Mobile / Form","SCR-041":"Mobile / Detail"},
  "UIF-11":{"SCR-048":"Mobile / Root List","SCR-049":"Mobile / Detail","SCR-052":"Mobile / Form","SCR-050":"Mobile / Form","SCR-053":"Mobile / Detail","SCR-051":"Mobile / Detail"},
  "UIF-12":{"SCR-066":"Mobile / Detail","SCR-067":"Mobile / Form","SCR-068":"Mobile / Detail","SCR-069":"Mobile / Detail","SCR-070":"Mobile / Detail","SCR-071":"Mobile / Detail"},
  "UIF-13":{"SCR-085":"Mobile / Root List","SCR-086":"Mobile / Form","SCR-087":"Mobile / Form","SCR-088":"Mobile / Detail","SCR-089":"Mobile / Detail"},
  "UIF-14":{"SCR-072":"Mobile / Root List","SCR-073":"Mobile / Form","SCR-074":"Mobile / Detail","SCR-076":"Mobile / Detail","SCR-077":"Mobile / Detail"},
  "UIF-15":{"SCR-054":"Mobile / Form","SCR-055":"Mobile / Detail","SCR-056":"Mobile / Detail","SCR-057":"Mobile / Detail","SCR-058":"Mobile / Detail","SCR-059":"Mobile / Detail"},
  "UIF-16":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-080":"Mobile / Form","SCR-081":"Mobile / Detail","SCR-082":"Mobile / Detail","SCR-083":"Mobile / Detail"},
  "UIF-17":{"SCR-078":"Mobile / Root List","SCR-079":"Mobile / Detail","SCR-080":"Mobile / Form","SCR-082":"Mobile / Detail","SCR-083":"Mobile / Detail"},
  "CAP-01":{"SCR-062":"Mobile / Form","SCR-063":"Mobile / Form","SCR-064":"Mobile / Detail","SCR-065":"Mobile / Detail"}
};
function figmaScreenTemplate(){ return FIGMA_TEMPLATE_BY_FLOW_SCREEN[activeFlowId]?.[activeScreenId] || null; }
const screens = HARNESS.screens;
const flowCatalog = HARNESS.flows;
let activeFlowId = new URLSearchParams(window.location.search).get("uif") || "UIF-02";
if (!flowCatalog.some((f) => f.id === activeFlowId)) activeFlowId = "UIF-02";
const groups = ["Screens"];
const FLOW_GROUPS = [
  { id: "inventory-operations", label: "Inventory operations", bjs: ["BJ-01", "BJ-02", "BJ-04", "BJ-05", "BJ-06", "BJ-07"] },
  { id: "inventory-valuation", label: "Inventory valuation", bjs: ["BJ-03", "BJ-13", "BJ-14"] },
  { id: "inventory-audit-control", label: "Inventory audit & control", bjs: ["BJ-08", "BJ-09", "BJ-10", "BJ-11", "BJ-12", "BJ-15", "BJ-16", "BJ-17"] },
  { id: "supporting", label: "Supporting capability", bjs: ["CAP-01"] },
];

function flowGroupLabel(flow) {
  const match = FLOW_GROUPS.find((group) => group.bjs.includes(flow.bj));
  return match ? match.label : "Other";
}

const stateByScreen = Object.fromEntries(screens.map((screen) => [screen.id, screen.defaultState]));

const initialParams = new URLSearchParams(window.location.search);
const initialFlow = flowCatalog.find((f) => f.id === activeFlowId);
const entryMode = initialParams.get("entry") || "module";
let activeScreenId = screens.some((s) => s.id === initialParams.get("screen") && initialFlow?.screens.includes(s.id)) ? initialParams.get("screen") : (initialFlow?.screens[0] || "SCR-006");
let viewport = initialParams.get("viewport") === "wide" ? "wide" : "mobile";
let flowMode = initialParams.get("flow") === "quick" ? "quick" : "document";
if (!initialParams.get("screen")) {
  if (activeFlowId === "UIF-01" && entryMode === "product-context") activeScreenId = "SCR-003";
  else if (activeFlowId === "UIF-02" && entryMode === "document-context") { flowMode = "document"; activeScreenId = "SCR-009"; }
  else if (activeFlowId === "UIF-02" && entryMode === "approver") activeScreenId = "SCR-011";
  else if (activeFlowId === "UIF-03" && entryMode === "receipt-task") activeScreenId = "SCR-015";
  else if (activeFlowId === "UIF-04" && entryMode === "order-context") activeScreenId = "SCR-021";
  else if (activeFlowId === "UIF-05" && entryMode === "order-task") activeScreenId = "SCR-026";
  else if (activeFlowId === "UIF-06" && entryMode === "return-task") activeScreenId = "SCR-031";
  else if (activeFlowId === "UIF-06" && entryMode === "approver") activeScreenId = "SCR-034";
  else if (activeFlowId === "UIF-07" && entryMode === "return-task") activeScreenId = "SCR-037";
  else if (activeFlowId === "UIF-13" && entryMode === "source-task") activeScreenId = "SCR-086";
  else if (activeFlowId === "UIF-11" && entryMode === "operation-context") activeScreenId = "SCR-049";
  else if (activeFlowId === "UIF-11" && entryMode === "approver") activeScreenId = "SCR-051";
  else if (activeFlowId === "UIF-16" && entryMode === "case-context") activeScreenId = "SCR-079";
  else if (activeFlowId === "UIF-17" && entryMode === "unknown-context") activeScreenId = "SCR-079";
  else if (activeFlowId === "UIF-12" && entryMode === "approver") activeScreenId = "SCR-070";
}
const initialState = initialParams.get("state");
if (initialState && screens.find((s) => s.id === activeScreenId)?.states.includes(initialState)) stateByScreen[activeScreenId] = initialState;
let toastTimer = null;




// ============================================================================
// UIF-03 / BJ-03 v1.4.4 — Inventory Valuation foundation correction.
// Preview is non-mutating; final commit is owned by BC-IV-01/API-C-20.
// ============================================================================
const val03Receipts = [
  {id:"VAL03-R1",receipt:"PN-260816-04",supplier:"Minh Dũng",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:3,ageDays:19,waitingOwner:"",groups:[
    {id:"VAL03-G1",name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",tracking:"LOT",officialCostStatus:"EXISTS",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3","CK dòng · PO-2608-041 v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v1",unitPrice:83000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v1","CK dòng · theo PO v3","CK phiếu · phân bổ theo giá trị dòng","Chi phí đã có · CTCP-2608-12 v1"]}
    ],selectedSource:"PO",reason:"",slices:[
      {id:"VAL03-S1",scopeKey:"ROL-401|LOT-DH2507|SELLABLE",scopeVersion:1,lineId:"ROL-401",lot:"DH2507",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:50,selected:false,selectedQty:50,partialOpen:false,availabilityDelta:50,availabilityNote:"Sẽ tăng khả dụng"},
      {id:"VAL03-S2",scopeKey:"ROL-402|LOT-DH2509|SELLABLE",scopeVersion:1,lineId:"ROL-402",lot:"DH2509",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:46,selected:false,selectedQty:46,partialOpen:false,availabilityDelta:0,availabilityNote:"Chưa tăng khả dụng · còn vướng kiểm soát chất lượng"},
      {id:"VAL03-S3",scopeKey:"ROL-403|LOT-DH2509|QUARANTINE",scopeVersion:1,lineId:"ROL-403",lot:"DH2509",physicalState:"QUARANTINE",stateLabel:"Cách ly",pendingQty:4,selected:false,selectedQty:4,partialOpen:false,availabilityDelta:0,availabilityNote:"Giữ cách ly"}
    ]},
    {id:"VAL03-G2",name:"Amoxicillin LA",code:"SP-00088",uom:"chai",tracking:"NONE",officialCostStatus:"NONE",sources:[
      {id:"PO",label:"Đơn mua PO-2608-041",version:"v3",unitPrice:120000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2608-041 v3"]},
      {id:"SUP",label:"Xác nhận nhà cung cấp 02/09",version:"v2",unitPrice:121000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 02/09 v2"]}
    ],selectedSource:"",reason:"",slices:[{id:"VAL03-S4",scopeKey:"ROL-404|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-404",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:24,selected:false,selectedQty:24,partialOpen:false,availabilityDelta:24,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R2",receipt:"PN-260816-02",supplier:"An Việt",warehouse:"Kho chính",receivedAt:"16/08/2026",sourceVersion:1,ageDays:19,waitingOwner:"Chờ chứng từ mua",groups:[
    {id:"VAL03-G3",name:"Găng tay khám Nitrile",code:"SP-00310",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S5",scopeKey:"ROL-405|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-405",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:50,selected:false,selectedQty:50,partialOpen:false,availabilityDelta:50,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R3",receipt:"PN-260901-03",supplier:"Phương Nam",warehouse:"Kho chính",receivedAt:"01/09/2026",sourceVersion:2,ageDays:3,waitingOwner:"",groups:[
    {id:"VAL03-G4",name:"Vaccine Canine X",code:"SP-00421",uom:"lọ",tracking:"LOT",officialCostStatus:"NONE",sources:[
      {id:"SUP",label:"Xác nhận nhà cung cấp 01/09",version:"v2",unitPrice:4.1,currency:"USD",fxRate:24450,fxLabel:"FX authoritative",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · Xác nhận NCC 01/09","FX authoritative · provenance kỹ thuật"]}
    ],selectedSource:"SUP",reason:"",slices:[{id:"VAL03-S6",scopeKey:"ROL-406|LOT-CX2609|SELLABLE",scopeVersion:1,lineId:"ROL-406",lot:"CX2609",physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:10,selected:false,selectedQty:10,partialOpen:false,availabilityDelta:10,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]},
  {id:"VAL03-R4",receipt:"PN-260902-07",supplier:"VietVet",warehouse:"Kho chính",receivedAt:"02/09/2026",sourceVersion:1,ageDays:2,waitingOwner:"",groups:[
    {id:"VAL03-G5",name:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",tracking:"NONE",officialCostStatus:"EXISTS",sources:[{id:"PO",label:"Đơn mua PO-2609-008",version:"v1",unitPrice:46000,currency:"VND",fxRate:1,fxLabel:"VND",unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:0,provenance:["Giá mua · PO-2609-008 v1"]}],selectedSource:"PO",reason:"",slices:[{id:"VAL03-S7",scopeKey:"ROL-407|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-407",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:12,selected:false,selectedQty:12,partialOpen:false,availabilityDelta:12,availabilityNote:"Sẽ tăng khả dụng"}]},
    {id:"VAL03-G6",name:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",tracking:"NONE",officialCostStatus:"EXISTS",sources:[],selectedSource:"",reason:"",slices:[{id:"VAL03-S8",scopeKey:"ROL-408|NOLOT|SELLABLE",scopeVersion:1,lineId:"ROL-408",lot:null,physicalState:"SELLABLE",stateLabel:"Đủ điều kiện bán",pendingQty:8,selected:false,selectedQty:8,partialOpen:false,availabilityDelta:8,availabilityNote:"Sẽ tăng khả dụng"}]}
  ]}
];
let val03SelectedReceiptId="VAL03-R1", val03Query="", val03Filter="ALL", val03ReviewSourceVersion=null, val03LastResult=null, val03LastSourceChange=null, val03OperationSeq=1, val03EvidenceSheetOpen=false, val03EvidenceSheetMode="scope";
function val03Current(){return val03Receipts.find(r=>r.id===val03SelectedReceiptId)||val03Receipts[0];}
function val03PendingSlices(r=val03Current()){return r.groups.flatMap(g=>g.slices.map(s=>({group:g,slice:s}))).filter(x=>x.slice.pendingQty>0);}
function val03EvidenceState(group){if(!group.sources.length)return "MISSING";const sig=new Set(group.sources.map(s=>`${s.currency}:${s.unitPrice}:${s.fxRate}`));return sig.size>1?"CONFLICT":"READY";}
function val03ActionablePairs(r=val03Current()){return val03PendingSlices(r).filter(x=>val03EvidenceState(x.group)!=="MISSING");}
function val03WaitingPairs(r=val03Current()){return val03PendingSlices(r).filter(x=>val03EvidenceState(x.group)==="MISSING");}
function val03ReceiptState(r){const a=val03ActionablePairs(r);if(!a.length)return "WAITING";return a.some(x=>val03EvidenceState(x.group)==="CONFLICT")?"CONFLICT":"READY";}
function val03SelectedSlices(r=val03Current()){return val03PendingSlices(r).filter(x=>x.slice.selected&&Number(x.slice.selectedQty)>0);}
function val03Source(group){return group.sources.find(s=>s.id===group.selectedSource)||null;}
function val03GroupSelectedQty(group){return group.slices.filter(s=>s.selected&&s.pendingQty>0).reduce((n,s)=>n+Math.min(Number(s.selectedQty)||0,s.pendingQty),0);}
function val03GroupReady(group){if(val03GroupSelectedQty(group)<=0)return true;const st=val03EvidenceState(group);if(st==="MISSING")return false;if(st==="CONFLICT"&&(!group.selectedSource||!group.reason.trim()))return false;return Boolean(val03Source(group));}
function val03HasSelectedConflict(r=val03Current()){return r.groups.some(g=>val03GroupSelectedQty(g)>0&&val03EvidenceState(g)==="CONFLICT"&&!val03GroupReady(g));}
function val03ScopeReady(r=val03Current()){const sel=val03SelectedSlices(r);return sel.length>0&&r.groups.every(val03GroupReady);}
function val03FmtMoney(n){return `${Math.round(Number(n)||0).toLocaleString("vi-VN")} đ`;}
function val03Calc(group){const src=val03Source(group);const qty=val03GroupSelectedQty(group);if(!src||qty<=0)return null;const baseVnd=src.unitPrice*src.fxRate;const unitActual=baseVnd-(src.unitLineDiscount||0)-(src.unitDocDiscount||0)+(src.unitKnownCost||0)+(src.unitNonDeductibleVat||0);return {qty,baseVnd,unitActual,value:Math.round(unitActual*qty),src};}
function val03SourceDetail(group){const src=val03Source(group);return src?src.label:"Chưa chọn";}
function val03SourcePriceText(src,uom){return src.currency==="VND"?`${val03FmtMoney(src.unitPrice)}/${uom}`:`${src.unitPrice.toLocaleString("vi-VN")} ${src.currency}/${uom}`;}
function val03ScopeLabel(g,s){return g.tracking==="LOT"?`Lô ${s.lot}`:"Không theo lô";}
function val03TotalValue(r=val03Current()){return r.groups.reduce((n,g)=>n+(val03Calc(g)?.value||0),0);}
function val03SelectedGroupCount(r=val03Current()){return r.groups.filter(g=>val03GroupSelectedQty(g)>0).length;}
function val03FilterMatch(r){const st=val03ReceiptState(r);if(val03Filter==="READY")return st!=="WAITING";if(val03Filter==="WAITING")return st==="WAITING";return true;}
function val03ReceiptBadge(r){const st=val03ReceiptState(r);return st==="WAITING"?["Chờ căn cứ","neutral"]:st==="CONFLICT"?["Cần đối chiếu","warning"]:["Có thể xử lý","success"];}
function val03ApplySourceUpdate(groupId,newPrice){const r=val03Current(),g=r.groups.find(x=>x.id===groupId);if(!g||!g.sources.length)return false;const src=g.sources[0],before=val03SourcePriceText(src,g.uom);r.sourceVersion+=1;src.unitPrice=newPrice;src.version=`v${Number(String(src.version).replace(/\D/g,"")||0)+1}`;val03LastSourceChange={name:g.name,source:src.label,from:before,to:val03SourcePriceText(src,g.uom)};if(val03EvidenceState(g)==="CONFLICT"){g.selectedSource="";g.reason="";}return true;}
function val03SelectedAvailability(g,s){const q=Math.min(Number(s.selectedQty)||0,s.pendingQty);const ratio=s.pendingQty?Math.min(1,q/s.pendingQty):0;return Math.round((s.availabilityDelta||0)*ratio*1000)/1000;}
function val03Commit(){const r=val03Current();const selected=val03SelectedSlices(r);const groups=r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{const c=val03Calc(g);return {name:g.name,code:g.code,uom:g.uom,tracking:g.tracking,qty:c.qty,value:c.value,unitActual:c.unitActual,source:val03SourceDetail(g),officialCostInitialized:g.officialCostStatus==="NONE",slices:g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:Math.min(Number(s.selectedQty)||0,s.pendingQty),availabilityDelta:val03SelectedAvailability(g,s),availabilityNote:s.availabilityNote}))};});val03LastResult={operationId:`VAL-260904-${String(val03OperationSeq++).padStart(3,"0")}`,receipt:r.receipt,supplier:r.supplier,groups,totalValue:groups.reduce((n,g)=>n+g.value,0)};for(const {group,slice} of selected){const q=Math.min(Number(slice.selectedQty)||0,slice.pendingQty);slice.pendingQty-=q;slice.scopeVersion+=1;slice.selected=false;slice.partialOpen=false;slice.selectedQty=slice.pendingQty;if(group.officialCostStatus==="NONE")group.officialCostStatus="EXISTS";}val03ReviewSourceVersion=null;return val03LastResult;}
function val03ResultSnapshot(){return val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0};}
function valuationDsTone(tone){const t=String(tone||"Neutral").toLowerCase();return ({success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"})[t]||"Neutral";}
function valuationProductHeader({name,code,uom,status="",tone="Neutral",value="",meta=""}){
  const trailing=value?`<span class="valuation-product-value"><small>Giá trị</small><strong>${esc(value)}</strong></span>`:(status?ds24Badge(status,valuationDsTone(tone)):"");
  const subtitle=`${code} · ${uom}${meta?` · ${meta}`:""}`;
  return ds24ListRow({title:name,subtitle,trailing,leading:"package",attrs:'data-layout-role="valuation-product-header" data-ds-role="valuation-product-summary"',type:"Status",density:"Compact",interactive:false});
}
function valuationReadOnlyChild({title,subtitle,trailing=""}){
  return `<div class="valuation-readonly-child" data-composed-from="VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-child-copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span>${trailing?`<span class="valuation-child-trailing">${trailing}</span>`:""}</div>`;
}
function val03ScopeGroupsHtml(r){
  const content=r.groups.filter(g=>g.slices.some(s=>s.pendingQty>0)).map(g=>{
    const st=val03EvidenceState(g);const badge=st==="MISSING"?["Chờ căn cứ","Neutral"]:st==="CONFLICT"?["Cần đối chiếu","Warning"]:["Đủ căn cứ","Success"];
    const rows=g.slices.filter(s=>s.pendingQty>0).map(s=>{
      const disabled=st==="MISSING",qty=Math.min(Number(s.selectedQty)||0,s.pendingQty);
      const selectedClass=s.selected?' is-selected':'';
      const disabledClass=disabled?' is-disabled':'';
      const partial=s.selected?`<div class="val03-partial-controls"><button class="val03-partial-link" type="button" data-val03-partial="${s.id}" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${s.partialOpen?'Dùng toàn bộ':'Xác nhận một phần'}</button>${s.partialOpen?`<label class="val03-qty" data-ds-component="VTextField" data-figma-node="522:7186"><span>Số lượng lần này</span><input type="number" min="1" max="${s.pendingQty}" value="${qty}" data-val03-qty="${s.id}"/><small>Tối đa ${s.pendingQty} ${esc(g.uom)}</small></label>`:""}</div>`:"";
      return `<div class="valuation-child-item val03-scope-item${selectedClass}${disabledClass}"><button type="button" class="valuation-child-row val03-check" data-val03-slice="${s.id}" aria-pressed="${s.selected}" ${disabled?'disabled aria-disabled="true"':''} data-composed-from="VCheckbox,VText" data-ds-migration-state="COMPOSED_FROM_CANONICAL_PRIMITIVES"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-selection-control val03-check-mark" aria-hidden="true" data-ds-component="VCheckbox" data-ds-prop-state="${disabled?'Disabled':s.selected?'Checked':'Unchecked'}">${s.selected?icon("check","icon--xs"):""}</span><span class="valuation-child-copy"><strong>${esc(val03ScopeLabel(g,s))}</strong><small>${esc(s.stateLabel)} · Chờ giá ${s.pendingQty} ${esc(g.uom)}</small></span></button>${partial}</div>`;
    }).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,status:badge[0],tone:badge[1]})}<div class="valuation-child-list">${rows}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection val03-product-collection","DS v2 / Icon,VBadge,VCheckbox,VText,VTextField");
}
function val03CalculationGroupsHtml(r){
  return r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{
    const st=val03EvidenceState(g);let sourceUI="";
    if(st==="CONFLICT"){
      sourceUI=`${vBanner("warning","Căn cứ giá đang mâu thuẫn","Hệ thống không tự chọn. Chọn căn cứ có thẩm quyền và ghi lý do.")}<div class="valuation-source-list" data-composed-from="DS v2 / List Row,VRadio">${g.sources.map(src=>`<button type="button" class="val03-source-option ${g.selectedSource===src.id?'is-selected':''}" data-val03-source="${g.id}" data-val03-source-id="${src.id}" aria-pressed="${g.selectedSource===src.id}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Selection" data-ds-prop-density="Default"><span class="valuation-radio-control" aria-hidden="true"><span></span></span><span><strong>${esc(src.label)}</strong><small>${esc(val03SourcePriceText(src,g.uom))}</small></span></button>`).join("")}</div><label class="val03-reason" data-ds-component="VTextarea" data-figma-node="522:7212"><span>Lý do chọn nguồn <b>*</b></span><textarea rows="3" data-val03-reason="${g.id}" placeholder="Nêu căn cứ để truy vết">${esc(g.reason||"")}</textarea></label>`;
    }else if(st==="MISSING"){
      sourceUI=vBanner("warning","Chưa đủ căn cứ","Phần này đang chờ căn cứ có thẩm quyền; không nhập giá tạm để đi tiếp.");
    }else{
      const src=g.sources[0];g.selectedSource=g.selectedSource||src.id;
      sourceUI=`${ds24InfoGroup("Căn cứ",ds24InfoRow("Nguồn giá",src.label),"valuation-info-group valuation-info-group--wrap")}${src.provenance?.length?`<div class="valuation-provenance" data-composed-from="VText"><strong>Thành phần nguồn</strong>${src.provenance.map(x=>`<p>${esc(String(x).replace(/\s+v\d+\b/gi,"").replace(/\bFX\b/g,"Tỷ giá"))}</p>`).join("")}</div>`:""}`;
    }
    const c=val03Calc(g);
    const breakdown=c?`<div class="valuation-kv-stack" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nguồn quy đổi",`${val03FmtMoney(c.baseVnd)}/${g.uom}`)}${c.src.unitLineDiscount?ds24KeyValueRow("Chiết khấu dòng",`− ${val03FmtMoney(c.src.unitLineDiscount)}/${g.uom}`):""}${c.src.unitDocDiscount?ds24KeyValueRow("Chiết khấu phiếu",`− ${val03FmtMoney(c.src.unitDocDiscount)}/${g.uom}`):""}${c.src.unitKnownCost?ds24KeyValueRow("Chi phí mua đã có",`+ ${val03FmtMoney(c.src.unitKnownCost)}/${g.uom}`):""}${c.src.unitNonDeductibleVat?ds24KeyValueRow("Thuế không khấu trừ",`+ ${val03FmtMoney(c.src.unitNonDeductibleVat)}/${g.uom}`):""}${ds24KeyValueRow("Giá nhập thực tế",`${val03FmtMoney(c.unitActual)}/${g.uom}`,true)}${ds24KeyValueRow("Giá trị dự kiến",val03FmtMoney(c.value),true)}</div>`:"";
    return `<section class="valuation-evidence-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom})}<div class="valuation-evidence-body">${sourceUI}${breakdown}</div></section>`;
  }).join("");
}
function val03EvidenceSheet(r=val03Current()){
  if(!val03EvidenceSheetOpen)return "";
  const invalid=!val03ScopeReady(r),title=val03HasSelectedConflict(r)?"Đối chiếu căn cứ":"Căn cứ và cách tính";
  const feedback=val03LastSourceChange?vBanner("warning","Căn cứ vừa thay đổi",`${val03LastSourceChange.name}: ${val03LastSourceChange.from} → ${val03LastSourceChange.to}`):invalid&&val03HasSelectedConflict(r)?vBanner("error","Cần hoàn tất căn cứ","Chọn nguồn có thẩm quyền và ghi lý do cho phần đang mâu thuẫn."):"";
  const calculation=val03CalculationGroupsHtml(r);
  const sheetBody=calculation||ioEmpty("Chưa có phạm vi để xem căn cứ","Chọn ít nhất một lô hoặc phạm vi hàng trước khi xem căn cứ và cách tính.");
  const doneLabel=val03HasSelectedConflict(r)?"Xong":"Đóng";
  return `<div class="sheet-backdrop valuation-sheet-backdrop" data-val03-action="close-evidence-sheet"><section class="bottom-sheet val03-evidence-sheet valuation-evidence-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${feedback}${sheetBody}<div class="sheet-actions"><button class="button button--primary" type="button" data-val03-action="close-evidence-sheet" ${val03HasSelectedConflict(r)&&!val03ScopeReady(r)?"disabled":""} data-ds-component="VButton" data-figma-node="521:529">${esc(doneLabel)}</button></div></div></section></div>`;
}
function val03ReviewGroupsHtml(r){
  const content=r.groups.filter(g=>val03GroupSelectedQty(g)>0).map(g=>{
    const c=val03Calc(g);
    const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nhập thực tế",c?`${val03FmtMoney(c.unitActual)}/${g.uom}`:"—")}${ds24KeyValueRow("Nguồn",val03SourceDetail(g))}${g.officialCostStatus==="NONE"?ds24KeyValueRow("Đơn giá chính thức",`Sẽ khởi tạo sau xác nhận`):""}</div>`;
    const slices=g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>{const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),ad=val03SelectedAvailability(g,s);const effect=ad>0?`+${ad} ${g.uom}`:s.availabilityNote;return valuationReadOnlyChild({title:val03ScopeLabel(g,s),subtitle:`${s.stateLabel} · ${q} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(effect)}</strong></span>`});}).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:c?val03FmtMoney(c.value):"—"})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection valuation-review-collection","DS v2 / Icon,DS v2 / Key-value Row,VText");
}
function val03ResultGroupsHtml(res){
  const content=(res.groups||[]).map(g=>{
    const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Giá nhập thực tế",`${val03FmtMoney(g.unitActual)}/${g.uom}`)}${g.officialCostInitialized?ds24KeyValueRow("Đơn giá chính thức","Đã khởi tạo"):""}</div>`;
    const slices=g.slices.map(s=>valuationReadOnlyChild({title:s.lot?`Lô ${s.lot}`:"Không theo lô",subtitle:`${s.state} · ${s.qty} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(s.availabilityDelta>0?`+${s.availabilityDelta} ${g.uom}`:s.availabilityNote)}</strong></span>`})).join("");
    return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:val03FmtMoney(g.value)})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
  }).join("");
  return ds24GroupedCollection(content,"valuation-product-collection valuation-result-collection","DS v2 / Icon,DS v2 / Key-value Row,VText");
}
function render014IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-014"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Hàng chờ xác nhận giá nhập",body:deniedBody(),centered:true,back:false});
  const rows=val03Receipts.filter(r=>val03PendingSlices(r).length&&val03FilterMatch(r)&&ioMatchesSearch(val03Query,`${r.receipt} ${r.supplier}`));
  const list=rows.map(r=>{const st=val03ReceiptState(r),[label,tone]=val03ReceiptBadge(r),products=new Set(val03PendingSlices(r).map(x=>`${x.group.code}|${x.group.uom}`)).size;const subtitle=`${r.supplier} · ${products} dòng hàng · Chờ ${r.ageDays} ngày`;return ds24ListRow({title:r.receipt,subtitle,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val03-receipt="${r.id}"`,type:"Navigation",state:st==="WAITING"?"Disabled":"Default",disabled:st==="WAITING",density:"Default"});}).join("");
  const body=`${ds24Search(val03Query,'data-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc công việc">${[["ALL","Tất cả"],["READY","Có thể xử lý"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,val03Filter===k,'data-val03-filter')).join("")}</div>${rows.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${list}</section>`:ioEmpty("Không tìm thấy phiếu phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.")}`;
  return appShell({title:"Hàng chờ xác nhận giá nhập",body,back:false});
}

function render015IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-015"),state);
  const r=val03Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Chọn hàng cần xác nhận giá",body:deniedBody(),centered:true});
  const selected=val03SelectedSlices(r),hasConflict=val03HasSelectedConflict(r),[statusLabel,statusTone]=val03ReceiptBadge(r);
  const notice=state==="ALREADY_CONFIRMED"?vBanner("info","Đã ghi một phần","Chỉ phần còn chờ giá được hiển thị."):"";
  const waiting=val03WaitingPairs(r).length?vBanner("info","Có phần đang chờ căn cứ","Bạn vẫn có thể xử lý phần đã đủ căn cứ."):"";
  const context=ds24ContextStatusRow({title:r.receipt,subtitle:`${r.supplier} · ${r.warehouse} · Nhận ${r.receivedAt}`,label:statusLabel,tone:valuationDsTone(statusTone),leading:null});
  const body=`${context}${notice}${waiting}${ds24SectionTitle("Hàng cần xác nhận giá",`${val03PendingSlices(r).length} phạm vi đang chờ`)}${val03ScopeGroupsHtml(r)}${selected.length?`<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${hasConflict?"Đối chiếu căn cứ":"Xem căn cứ và cách tính"}</button>`:""}${val03EvidenceSheet(r)}`;
  return appShell({title:"Chọn hàng cần xác nhận giá",body,actions:primaryFooter(hasConflict?"Đối chiếu căn cứ":"Rà soát xác nhận",hasConflict?'data-val03-action="open-evidence-sheet"':'data-val03-action="open-review"',selected.length===0)});
}

function render016IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-016"),state);
  const r=val03Current();
  const body=`${vBanner("info","Nội dung hỗ trợ","Căn cứ và cách tính được mở ngay trong màn đang làm việc, không còn là một bước điều hướng riêng.")}${val03CalculationGroupsHtml(r)}`;
  return appShell({title:"Căn cứ và cách tính",body,actions:primaryFooter("Về hàng cần xác nhận",'data-val03-action="retired-to-scope"')});
}

function render017IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-017"),state);
  const r=val03Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát xác nhận giá",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||(val03ReviewSourceVersion!=null&&Number(val03ReviewSourceVersion)!==Number(r.sourceVersion));
  const summary=`${ds24ContextStatusRow({title:r.receipt,subtitle:`${r.supplier} · ${val03SelectedGroupCount(r)} dòng hàng`,label:"Sẵn sàng",tone:"Success",leading:null})}<div class="valuation-total-strip" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow("Tổng giá trị sẽ ghi",val03FmtMoney(val03TotalValue(r)),true)}</div>`;
  if(stale){val03EvidenceSheetOpen=true;return appShell({title:"Rà soát xác nhận giá",body:`${vBanner("warning","Căn cứ giá đã thay đổi","Không thể xác nhận trên dữ liệu cũ. Đối chiếu căn cứ hiện hành trước khi tiếp tục.")}${summary}${ds24SectionTitle("Nội dung sẽ xác nhận",`${val03SelectedGroupCount(r)} dòng hàng`)}${val03ReviewGroupsHtml(r)}${val03EvidenceSheet(r)}`});}
  const body=`${summary}${ds24SectionTitle("Nội dung sẽ xác nhận",`${val03SelectedGroupCount(r)} dòng hàng`)}${val03ReviewGroupsHtml(r)}<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Xem căn cứ và cách tính</button>${val03EvidenceSheet(r)}`;
  return appShell({title:"Rà soát xác nhận giá",body,actions:primaryFooter("Xác nhận giá trị",'data-val03-action="confirm-value"',!val03ScopeReady(r))});
}

function render019IV03(state){
  if(activeFlowId!=="UIF-03")return renderGeneric(screens.find(s=>s.id==="SCR-019"),state);
  const res=val03ResultSnapshot();
  if(state==="PROCESSING")return appShell({title:"Kết quả xác nhận giá",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định thao tác đã ghi hay chưa","Không gửi lại xác nhận. Công việc tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Phiếu nhận",res.receipt],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về danh sách",'data-val03-action="result-to-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả xác nhận giá",body:ioResult("Chưa ghi nhận giá trị","Không có thay đổi. Kiểm tra lại phạm vi và căn cứ hiện hành.",[["Phiếu nhận",res.receipt],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem lại hàng cần xác nhận",'data-val03-action="result-to-scope"')});
  const actionable=val03ActionablePairs(val03Current()).length,waiting=val03WaitingPairs(val03Current()).length;
  const waitingNote=waiting&&!actionable?vBanner("info","Phần còn lại đang chờ căn cứ","Bạn đã hoàn tất phần có thể xử lý."):"";
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Phiếu nhận",res.receipt)}${ds24KeyValueRow("Giá trị đã ghi",val03FmtMoney(res.totalValue),true)}`,"valuation-info-group valuation-result-overview");
  const body=`<div class="io-result val03-result">${resultHero("Đã xác nhận giá","Giá trị đã được ghi cho đúng phạm vi đã chọn.")}${overview}${ds24SectionTitle("Phạm vi đã ghi")}${val03ResultGroupsHtml(res)}${waitingNote}</div>`;
  return appShell({title:"Kết quả xác nhận giá",body,centered:true,back:false,actions:primaryFooter(actionable?"Tiếp tục xác nhận":"Về danh sách",actionable?'data-val03-action="continue-remaining"':'data-val03-action="result-to-queue"')});
}

// ============================================================================
// UIF-13 / BJ-13 v1.4.5 — Late landed cost deep Product correction.
// Allocation-method labels below are runtime fixtures returned by the preview
// model. They are not a canonical business enum; BC-IV-06/API-Q-12 owns the
// authoritative allowed set and calculation in production.
// ============================================================================
const val13Tasks = [
  {id:"LC13-001",sourceRef:"Hóa đơn vận chuyển VC-8842 · dòng 1",sourceVersion:2,evidence:"VC-8842.pdf",supplier:"Vận tải An Phát",component:"Chi phí vận chuyển",sourceAmount:1200000,currency:"VND",normalizedAmount:1200000,fxLabel:"VND",ageDays:4,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"08/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T1",receipt:"PN-260816-04",lineId:"ROL-401",product:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",lot:"DH2507",qty:50,receivedValue:4085000,selected:true},
    {id:"LC13-T2",receipt:"PN-260816-04",lineId:"ROL-404",product:"Amoxicillin LA",code:"SP-00088",uom:"chai",lot:null,qty:24,receivedValue:2880000,selected:true},
    {id:"LC13-T3",receipt:"PN-260821-03",lineId:"ROL-512",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2608",qty:40,receivedValue:4010000,selected:true}
  ]},
  {id:"LC13-002",sourceRef:"Phí bảo hiểm INS-2609-17 · dòng 2",sourceVersion:1,evidence:"INS-2609-17.pdf",supplier:"Bảo hiểm Minh Thành",component:"Phí bảo hiểm hàng mua",sourceAmount:250,currency:"USD",normalizedAmount:6125000,fxRate:24500,fxLabel:"Tỷ giá kế toán 24.500 VND/USD",ageDays:2,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T4",receipt:"PN-260901-03",lineId:"ROL-601",product:"Vaccine Canine X",code:"SP-00421",uom:"lọ",lot:"CX2609",qty:10,receivedValue:1002450,selected:true},
    {id:"LC13-T5",receipt:"PN-260901-08",lineId:"ROL-633",product:"Doxycycline 100mg",code:"SP-00611",uom:"hộp",lot:null,qty:60,receivedValue:7200000,selected:true}
  ]},
  {id:"LC13-003",sourceRef:"Hóa đơn vận chuyển VC-8890 · dòng 1",sourceVersion:1,evidence:"VC-8890.pdf",supplier:"Logistics Đông Dương",component:"Chi phí vận chuyển",sourceAmount:180,currency:"USD",normalizedAmount:null,fxLabel:"",ageDays:6,status:"WAITING",waitingOwner:"Chờ nguồn hoàn tất quy đổi giá trị",originalPeriod:"08/2026",postingPeriod:"",periodReason:"",policyVersion:"",allowedMethods:[],selectedMethod:"",targets:[]},
  {id:"LC13-004",sourceRef:"Điều chỉnh chiết khấu CK-2609-06 · dòng 1",sourceVersion:3,evidence:"CK-2609-06.pdf",supplier:"Minh Dũng",component:"Điều chỉnh chiết khấu mua",sourceAmount:-350000,currency:"VND",normalizedAmount:-350000,fxLabel:"VND",ageDays:1,status:"ACTIONABLE",waitingOwner:"",originalPeriod:"09/2026",postingPeriod:"09/2026",periodReason:"Kỳ gốc đang mở",policyVersion:"ALC-POL-v5",allowedMethods:[{id:"FIXTURE_VALUE",label:"Theo giá trị nhập ban đầu"}],selectedMethod:"FIXTURE_VALUE",targets:[
    {id:"LC13-T6",receipt:"PN-260902-07",lineId:"ROL-407",product:"Dung dịch sát khuẩn",code:"SP-00510",uom:"chai",lot:null,qty:12,receivedValue:552000,selected:true},
    {id:"LC13-T7",receipt:"PN-260902-07",lineId:"ROL-408",product:"Bơm tiêm 5ml",code:"SP-00511",uom:"hộp",lot:null,qty:8,receivedValue:640000,selected:true}
  ]}
];
let val13SelectedTaskId="LC13-001", val13Query="", val13Filter="ALL", val13ReviewSourceVersion=null, val13PreviewHash=null, val13LastSourceChange=null, val13LastResult=null, val13OperationSeq=1;
function val13Current(){return val13Tasks.find(t=>t.id===val13SelectedTaskId)||val13Tasks[0];}
function val13FmtMoney(value){const n=Number(value||0);return `${new Intl.NumberFormat('vi-VN').format(n)} đ`;}
function val13FmtSourceAmount(t){const amount=new Intl.NumberFormat('vi-VN',{maximumFractionDigits:2}).format(Number(t.sourceAmount||0));return `${amount} ${t.currency}`;}
function val13SelectedTargets(t=val13Current()){return (t.targets||[]).filter(x=>x.selected);}
function val13TaskSearchText(t){return ioNormalizeSearch(`${t.id} ${t.sourceRef} ${t.supplier} ${t.component}`);}
function val13QueueTitle(t){return String(t.sourceRef||"").replace(/^(Hóa đơn vận chuyển|Phí bảo hiểm|Điều chỉnh chiết khấu)\s+/i,"");}
function val13AllocationWeight(target,method){return method==="FIXTURE_QTY"?Math.max(0,Number(target.qty)||0):Math.max(0,Number(target.receivedValue)||0);}
function val13Preview(t=val13Current()){
  const targets=val13SelectedTargets(t);const total=Number(t.normalizedAmount||0);if(!targets.length||t.normalizedAmount==null)return [];
  const weights=targets.map(x=>val13AllocationWeight(x,t.selectedMethod));const weightTotal=weights.reduce((a,b)=>a+b,0)||targets.length;
  let used=0;return targets.map((target,index)=>{let amount;if(index===targets.length-1)amount=total-used;else{const weight=weightTotal?weights[index]:1;amount=Math.round(total*(weight/weightTotal));used+=amount;}return {...target,allocatedAmount:amount,roundingAdjustment:index===targets.length-1?total-used-amount:0};});
}
function val13PreviewHashOf(t=val13Current()){return `${t.id}|v${t.sourceVersion}|${t.selectedMethod}|${val13SelectedTargets(t).map(x=>x.id).sort().join(',')}|${t.normalizedAmount}`;}
function val13CanOpenAllocation(t=val13Current()){return t.status==="ACTIONABLE"&&t.normalizedAmount!=null&&val13SelectedTargets(t).length>0;}
function val13CanPreview(t=val13Current()){return val13CanOpenAllocation(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod);}
function val13StatusMeta(t){if(t.status==="WAITING")return [t.waitingOwner||"Đang chờ","neutral"];return ["Có thể xử lý","success"];}
function val13ResetTaskDraft(t){for(const target of (t.targets||[]))target.selected=true;t.selectedMethod=t.allowedMethods?.length===1?t.allowedMethods[0].id:"";val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;}
function val13SourceCard(t){
  const [rawLabel,rawTone]=val13StatusMeta(t);const label=t.status==="WAITING"?"Đang chờ":rawLabel;
  const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label,tone:valuationDsTone(rawTone),leading:null});
  const facts=`${ds24InfoRow("Giá trị nguồn",val13FmtSourceAmount(t))}${t.currency!=="VND"&&t.fxLabel?ds24InfoRow("Tỷ giá",t.fxLabel):""}${t.normalizedAmount!=null?ds24KeyValueRow("Sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true):""}${ds24InfoRow("Lần cập nhật nguồn",`Lần ${t.sourceVersion}`)}${ds24InfoRow("Bằng chứng",t.evidence)}`;
  return `${context}${ds24InfoGroup("Chi tiết nguồn",facts,"valuation-info-group valuation-info-group--wrap val13-source-card")}`;
}
function val13TargetHtml(t){
  return (t.targets||[]).map(target=>`<button type="button" class="val13-target-row ${target.selected?'is-selected':''}" data-val13-target="${target.id}" aria-pressed="${target.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${target.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(target.product)}</strong><small>${esc(target.receipt)} · ${esc(target.code)} · ${target.qty} ${esc(target.uom)}${target.lot?` · Lô ${esc(target.lot)}`:""}</small></span></button>`).join('');
}
function val13AllocationRows(t=val13Current()){
  const rows=val13Preview(t);return rows.map(row=>`<div class="val13-allocation-row valuation-allocation-row" data-composed-from="VText"><span><strong>${esc(row.product)}</strong><small>${esc(row.receipt)} · ${row.qty} ${esc(row.uom)}${row.lot?` · Lô ${esc(row.lot)}`:""}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(row.allocatedAmount))}</strong></div>`).join('');
}
function val13DirtyScope(t=val13Current()){return [...new Map(val13Preview(t).map(x=>[`${x.product}|${x.uom}`,`${x.product} · ${x.uom}`])).values()];}
function val13PeriodCard(t){
  const differs=t.originalPeriod&&t.postingPeriod&&t.originalPeriod!==t.postingPeriod;
  return `${differs?vBanner("info","Ghi nhận ở kỳ mở hiện tại",t.periodReason||"Kỳ gốc đã khóa; điều chỉnh vẫn liên kết về kỳ gốc."):""}${ds24InfoGroup("Kỳ ghi nhận",`${ds24InfoRow("Kỳ gốc",t.originalPeriod||"—")}${ds24InfoRow("Kỳ ghi nhận",t.postingPeriod||"—")}`,"valuation-info-group")}`;
}
function val13ReviewBody(t){
  const allocations=val13Preview(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||"—",total=allocations.reduce((sum,x)=>sum+x.allocatedAmount,0);
  const allocation=`${ds24SectionTitle("Phân bổ sẽ ghi",`${allocations.length} dòng đích`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow("Tổng phân bổ",val13FmtMoney(total),true)}</div>`,"valuation-allocation-collection val13-review-group","VText,DS v2 / Key-value Row")}`;
  const methodInfo=ds24InfoGroup("Căn cứ phân bổ",`${ds24KeyValueRow("Giá trị sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow("Phương pháp",method)}`,"valuation-info-group");
  const effects=ds24InfoGroup("Tác động sau ghi",`${ds24InfoRow("Số lượng tồn kho","Không thay đổi")}${ds24InfoRow("Giá vốn chính thức","Chưa tự công bố lại")}${ds24InfoRow("Cần tính lại",val13DirtyScope(t).join("; ")||"—")}`,"valuation-info-group valuation-info-group--wrap");
  return `${val13SourceCard(t)}${methodInfo}${allocation}${val13PeriodCard(t)}${effects}`;
}
function val13Commit(){const t=val13Current();const allocations=val13Preview(t);val13LastResult={operationId:`LC13-OP-${String(val13OperationSeq++).padStart(3,'0')}`,taskId:t.id,sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,postingPeriod:t.postingPeriod,originalPeriod:t.originalPeriod,allocations:allocations.map(x=>({...x})),dirtyScope:val13DirtyScope(t)};t.status="COMPLETED";return val13LastResult;}
function val13Result(){return val13LastResult||{operationId:"LC13-OP-PREVIEW",taskId:val13Current().id,sourceRef:val13Current().sourceRef,component:val13Current().component,normalizedAmount:val13Current().normalizedAmount,postingPeriod:val13Current().postingPeriod,originalPeriod:val13Current().originalPeriod,allocations:val13Preview(),dirtyScope:val13DirtyScope()};}
function val13ApplySourceUpdate(){const t=val13Current();if(t.status!=="ACTIONABLE")return;t.sourceVersion+=1;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==="SCR-088")stateByScreen["SCR-088"]="SOURCE_CHANGED";render();}
window.val13ApplySourceUpdate=val13ApplySourceUpdate;

function render085IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-085"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi phí mua bổ sung",body:deniedBody(),centered:true,back:false});
  const all=val13Tasks.filter(t=>t.status!=="COMPLETED");const filtered=all.filter(t=>{const filterOk=val13Filter==="ALL"||(val13Filter==="ACTIONABLE"&&t.status==="ACTIONABLE")||(val13Filter==="WAITING"&&t.status==="WAITING");const queryOk=!val13Query||val13TaskSearchText(t).includes(ioNormalizeSearch(val13Query));return filterOk&&queryOk;});
  if(state==="EMPTY"&&!all.length)return appShell({title:"Chi phí mua bổ sung",body:ioEmpty("Không có chi phí mua bổ sung","Các chứng từ cần xử lý sẽ xuất hiện tại đây."),centered:true,back:false});
  const rows=filtered.map(t=>{const [label,tone]=val13StatusMeta(t),subtitle=`${t.component} · ${t.supplier} · Chờ ${t.ageDays} ngày`;return ds24ListRow({title:val13QueueTitle(t),subtitle,trailing:ds24Badge(t.status==="WAITING"?"Đang chờ":label,valuationDsTone(tone)),leading:null,attrs:`data-val13-task="${t.id}"`,type:"Navigation",state:t.status==="WAITING"?"Disabled":"Default",disabled:t.status==="WAITING"});}).join('');
  const empty=filtered.length?"":ioEmpty("Không tìm thấy công việc phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.");
  const body=`${ds24Search(val13Query,'data-val13-search','Chứng từ chi phí hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc chi phí mua bổ sung">${[["ALL","Tất cả"],["ACTIONABLE","Có thể xử lý"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,val13Filter===k,'data-val13-filter')).join("")}</div>${filtered.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:empty}`;
  return appShell({title:"Chi phí mua bổ sung",body,back:false});
}

function render086IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-086"),state);const t=val13Current();
  if(state==="LOADING")return appShell({title:"Nguồn và phạm vi chi phí",body:loadingBody(),centered:true});
  if(state==="PERMISSION_DENIED")return appShell({title:"Nguồn và phạm vi chi phí",body:deniedBody(),centered:true});
  if(t.status==="WAITING")return appShell({title:"Nguồn và phạm vi chi phí",body:`${vBanner("info","Chưa thể xử lý",t.waitingOwner||"Đang chờ căn cứ cần thiết.")}${val13SourceCard(t)}`});
  const changed=state==="SOURCE_CHANGED"||Boolean(val13LastSourceChange),selected=val13SelectedTargets(t).length;
  const body=`${changed?vBanner("warning","Nguồn chi phí vừa thay đổi",val13LastSourceChange?`Giá trị chuẩn hóa ${val13LastSourceChange.from} → ${val13LastSourceChange.to}. Chọn lại phạm vi trước khi tiếp tục.`:"Tải lại nguồn hiện hành trước khi tiếp tục."):""}${val13SourceCard(t)}${ds24SectionTitle("Phạm vi liên quan",`${selected}/${t.targets.length} dòng đã chọn`)}${ds24GroupedCollection(val13TargetHtml(t),"valuation-selection-collection val13-target-list","VCheckbox,VText")}`;
  return appShell({title:"Nguồn và phạm vi chi phí",body,actions:primaryFooter("Tiếp tục phân bổ",'data-val13-action="scope-to-allocation"',selected===0)});
}

function render087IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-087"),state);const t=val13Current();
  if(state==="LOADING")return appShell({title:"Phân bổ chi phí",body:loadingBody(),centered:true});
  if(state==="PERMISSION_DENIED")return appShell({title:"Phân bổ chi phí",body:deniedBody(),centered:true});
  if(state==="SOURCE_CHANGED")return appShell({title:"Phân bổ chi phí",body:`${vBanner("warning","Nguồn chi phí đã thay đổi","Phân bổ cũ không còn hợp lệ.")}${val13SourceCard(t)}`,actions:primaryFooter("Kiểm tra lại phạm vi",'data-val13-action="back-scope"')});
  const preview=val13Preview(t),total=preview.reduce((sum,x)=>sum+x.allocatedAmount,0),methodOptions=`<option value="">Chọn căn cứ phân bổ</option>`+t.allowedMethods.map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');
  const normalizedRows=`${ds24InfoRow("Giá trị nguồn",val13FmtSourceAmount(t))}${t.currency!=="VND"?ds24InfoRow("Tỷ giá",t.fxLabel):""}${ds24KeyValueRow("Sau chuẩn hóa",val13FmtMoney(t.normalizedAmount),true)}`;
  const normalized=ds24InfoGroup("Chi phí cần phân bổ",normalizedRows,"valuation-info-group");
  const allocationBody=val13CanPreview(t)?`${ds24SectionTitle("Kết quả phân bổ",`${preview.length} dòng đích`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow("Tổng phân bổ",val13FmtMoney(total),true)}</div>`,"valuation-allocation-collection val13-allocation-list","VText,DS v2 / Key-value Row")}${val13PeriodCard(t)}`:vBanner("info","Chọn căn cứ phân bổ","Chọn một căn cứ được phép để xem phân bổ trước khi rà soát.","", "Compact");
  const body=`${normalized}${ds24SectionTitle("Căn cứ phân bổ")}<label class="val13-select-field valuation-field" data-ds-component="VField"><span>Căn cứ phân bổ</span><select data-val13-method data-ds-component="VSelect" data-figma-node="522:7291">${methodOptions}</select><small>Áp dụng chính sách phân bổ hiện hành</small></label>${allocationBody}`;
  return appShell({title:"Phân bổ chi phí",body,actions:primaryFooter("Rà soát ghi chi phí",'data-val13-action="open-review"',!val13CanPreview(t))});
}

function render088IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-088"),state);const t=val13Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát ghi chi phí",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||val13ReviewSourceVersion==null||Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t);
  if(stale){const delta=val13LastSourceChange?ds24InfoGroup("Giá trị nguồn",`${ds24InfoRow("Trước thay đổi",val13LastSourceChange.from)}${ds24InfoRow("Hiện hành",val13LastSourceChange.to)}`,"valuation-info-group"):"";return appShell({title:"Rà soát ghi chi phí",body:`${vBanner("warning","Nguồn hoặc phân bổ đã thay đổi","Tạo lại phân bổ trước khi ghi chi phí.")}${val13SourceCard(t)}${delta}`,actions:primaryFooter("Tạo lại phân bổ",'data-val13-action="back-allocation"')});}
  const body=`${val13ReviewBody(t)}<button type="button" class="io-text-action valuation-text-action" data-val13-action="back-allocation" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Chỉnh sửa phân bổ</button>`;
  return appShell({title:"Rà soát ghi chi phí",body,actions:primaryFooter("Ghi chi phí mua bổ sung",'data-val13-action="confirm-late-cost"')});
}

function render089IV13(state){
  if(activeFlowId!=="UIF-13")return renderGeneric(screens.find(s=>s.id==="SCR-089"),state);const res=val13Result();
  if(state==="PROCESSING")return appShell({title:"Kết quả ghi chi phí",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định thao tác đã ghi hay chưa","Không gửi lại chi phí. Công việc tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Chứng từ chi phí",res.sourceRef],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả ghi chi phí",body:ioResult("Chưa ghi chi phí mua bổ sung","Không có thay đổi. Kiểm tra lại phân bổ hiện hành.",[["Chứng từ chi phí",res.sourceRef],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Xem lại phân bổ",'data-val13-action="back-allocation"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả ghi chi phí",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
  const allocationSummary=(res.allocations||[]).map(x=>`<div class="val13-result-line valuation-allocation-row"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:""}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Chứng từ",res.sourceRef)}${ds24KeyValueRow("Chi phí đã ghi",val13FmtMoney(res.normalizedAmount),true)}${ds24InfoRow("Kỳ ghi nhận",res.postingPeriod)}${ds24InfoRow("Giá vốn","Cần tính lại")}`,"valuation-info-group valuation-info-group--wrap");
  const body=`<div class="io-result val13-result">${resultHero("Đã ghi chi phí mua bổ sung","Chi phí đã được ghi theo phạm vi phân bổ đã xác nhận.")}${overview}${ds24SectionTitle("Phân bổ đã ghi")}${ds24GroupedCollection(allocationSummary,"valuation-allocation-collection val13-result-lines","VText")}</div>`;
  return appShell({title:"Kết quả ghi chi phí",body,centered:true,back:false,actions:primaryFooter("Về chi phí mua bổ sung",'data-val13-action="result-to-queue"')});
}

// ============================================================================
// UIF-14 / BJ-14 v1.5.0 — Cost run calculation and publication.
// Run is immutable once created; blockers/calculating are states of SCR-074.
// ============================================================================
const val14Runs=[
  {id:"COST-0826",label:"Tháng 08/2026",kind:"PERIOD_CLOSE",status:"READY_FOR_REVIEW",period:"08/2026",scope:"184 sản phẩm",cutoff:"31/08/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:1242800000,cogs:488120000},periodic:{inventory:1245920000,cogs:486300000},cogsTrueUp:-1820000,endingAdjustment:3120000,effectiveAt:"01/09/2026 · 00:00",blockers:[],inputVersion:7,runVersion:3,supersedes:null},
  {id:"COST-0903",label:"Cập nhật 03/09/2026",kind:"AD_HOC",status:"DIRTY",period:"09/2026",scope:"3 sản phẩm",cutoff:"04/09/2026 · 10:00",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:{inventory:186400000,cogs:52700000},periodic:{inventory:186180000,cogs:52920000},cogsTrueUp:220000,endingAdjustment:-220000,effectiveAt:"04/09/2026 · 10:00",blockers:[],inputVersion:4,runVersion:0,supersedes:"COST-0902"},
  {id:"COST-0901-B",label:"Tháng 09/2026",kind:"PERIOD_CLOSE",status:"BLOCKED",period:"09/2026",scope:"Toàn bộ sản phẩm",cutoff:"30/09/2026 · 23:59",policyMethod:"PERIODIC",policyLabel:"Bình quân cuối kỳ",policyVersion:"Chính sách giá vốn",moving:null,periodic:null,cogsTrueUp:0,endingAdjustment:0,effectiveAt:"01/10/2026 · 00:00",blockers:[{title:"2 dòng hàng còn chờ xác nhận giá",owner:"Định giá tồn kho"},{title:"1 đối soát chưa có kết quả cuối",owner:"Kiểm soát tồn kho"}],inputVersion:2,runVersion:1,supersedes:null}
];
let val14SelectedRunId="COST-0826",val14SetupKind="PERIOD_CLOSE",val14SetupPeriod="08/2026",val14SetupScope="Toàn bộ sản phẩm",val14SuccessorOf=null,val14PublishReviewVersion=null,val14LastResult=null,val14CalcTimer=null;
function val14Current(){return val14Runs.find(r=>r.id===val14SelectedRunId)||val14Runs[0];}
function val14Money(n){const v=Math.round(Number(n)||0);return `${v<0?"− ":""}${Math.abs(v).toLocaleString("vi-VN")} đ`;}
function val14StatusMeta(r){if(r.status==="READY_FOR_REVIEW")return ["Sẵn sàng công bố","success"];if(r.status==="BLOCKED")return ["Bị chặn","warning"];if(r.status==="DIRTY")return ["Cần tính lại","warning"];if(r.status==="CALCULATING")return ["Đang tính","info"];if(r.status==="PUBLISHED")return ["Đã công bố","success"];return ["Chưa tính","neutral"];}
function val14MethodCard(r){
  const selected=r.policyMethod;
  const rows=[["MOVING","Bình quân liên hoàn",r.moving],["PERIODIC","Bình quân cuối kỳ",r.periodic]].map(([id,label,x])=>`<div class="val14-method-row ${selected===id?'is-policy':''}" data-composed-from="VText,VBadge"><span class="val14-method-copy"><strong>${esc(label)}</strong><small>${selected===id?'Dùng để công bố theo chính sách':'Giữ để đối chiếu'}</small>${selected===id?`<span class="val14-policy-badge">${ds24Badge("Theo chính sách","Success")}</span>`:""}</span><span class="val14-method-values"><strong>${x?esc(val14Money(x.inventory)):"—"}</strong><small>Giá trị tồn cuối</small><small>Giá vốn xuất ${x?esc(val14Money(x.cogs)):"—"}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-method-collection val14-method-card","VText,VBadge");
}
function val14Blockers(r){
  const rows=r.blockers.map(b=>`<div class="val14-blocker-row" data-composed-from="DS v2 / Icon,VText"><span class="val14-blocker-icon">${icon("alertTriangle","icon--sm")}</span><span><strong>${esc(b.title)}</strong><small>Đang chờ: ${esc(b.owner)}</small></span></div>`).join("");
  return ds24GroupedCollection(rows,"valuation-blocker-collection val14-blocker-card","DS v2 / Icon,VText");
}
function val14RunSummary(r){
  const [label,tone]=val14StatusMeta(r);
  const context=ds24ContextStatusRow({title:r.label,subtitle:`Kỳ ${r.period} · ${r.scope}`,label,tone:valuationDsTone(tone),leading:null});
  const facts=ds24InfoGroup("Thông tin lần tính",`${ds24InfoRow("Thời điểm chốt",r.cutoff)}${ds24InfoRow("Phương pháp công bố",r.policyLabel)}${ds24InfoRow("Chính sách",r.policyVersion)}`,"valuation-info-group valuation-info-group--wrap val14-summary");
  return `${context}${facts}`;
}
function val14AdjustmentCard(r,title="Điều chỉnh dự kiến"){
  return ds24InfoGroup(title,`${ds24KeyValueRow("Giá vốn xuất",val14Money(r.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(r.endingAdjustment),true)}${ds24InfoRow("Hiệu lực",r.effectiveAt)}`,"valuation-info-group val14-adjustment");
}
function val14KindChoices(){
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const row=(kind,title,desc,selected)=>`<button type="button" class="val14-choice-row${selected?' is-selected':''}" data-val14-kind="${kind}" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${selected?'On':'Off'}" aria-pressed="${selected}"><span class="val14-radio-control" aria-hidden="true"><span></span></span><span class="val14-choice-copy"><strong>${esc(title)}</strong><small>${esc(desc)}</small></span></button>`;
  return `<div class="val14-choice-list" data-composed-from="VRadio">${row("PERIOD_CLOSE","Chốt kỳ","Tính toàn kỳ theo thời điểm chốt kế toán",periodClose)}${row("AD_HOC","Cập nhật trong kỳ","Chỉ tính phạm vi cần cập nhật",!periodClose)}</div>`;
}
function val14CreateRun(){const id=`COST-${Date.now()}`;const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;const run={id,label:val14SetupKind==="PERIOD_CLOSE"?`Tháng ${val14SetupPeriod}`:`Cập nhật ${new Date().toLocaleDateString("vi-VN")}`,kind:val14SetupKind,status:"CALCULATING",period:val14SetupPeriod,scope:val14SetupScope,cutoff:val14SetupKind==="PERIOD_CLOSE"?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30",policyMethod:base?.policyMethod||"PERIODIC",policyLabel:base?.policyLabel||"Bình quân cuối kỳ",policyVersion:base?.policyVersion||"Chính sách giá vốn",moving:{inventory:1243100000,cogs:488000000},periodic:{inventory:1246150000,cogs:486150000},cogsTrueUp:-1850000,endingAdjustment:3050000,effectiveAt:val14SetupKind==="PERIOD_CLOSE"?"01/09/2026 · 00:00":"04/09/2026 · 14:30",blockers:[],inputVersion:(base?.inputVersion||7)+1,runVersion:1,supersedes:base?.id||val14SuccessorOf};val14Runs.unshift(run);val14SelectedRunId=id;val14PublishReviewVersion=null;if(val14CalcTimer)clearTimeout(val14CalcTimer);val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120);return run;}
function val14Commit(){const r=val14Current();r.status="PUBLISHED";r.runVersion+=1;val14LastResult={period:r.period,scope:r.scope,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};return val14LastResult;}
function val14ApplyInputChange(){const r=val14Current();r.inputVersion+=1;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.inputVersion;}
function render072IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-072"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Giá vốn",body:deniedBody(),centered:true,back:false});
  const active=val14Runs.filter(r=>r.status!=="PUBLISHED");
  const rows=active.map(r=>{const [label,tone]=val14StatusMeta(r);return ds24ListRow({title:r.label,subtitle:`${r.scope} · ${r.policyLabel}`,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val14-run="${r.id}"`,type:"Navigation"});}).join("");
  const body=`${rows?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty("Chưa có lần tính giá vốn","Tạo một lần tính để bắt đầu.")}`;
  return appShell({title:"Giá vốn",body,back:false,actions:primaryFooter("Tạo lần tính",'data-val14-action="new-run"')});
}
function render073IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-073"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Thiết lập lần tính",body:deniedBody(),centered:true});
  const periodClose=val14SetupKind==="PERIOD_CLOSE";
  const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30")}${ds24InfoRow("Phương pháp công bố","Bình quân cuối kỳ")}${ds24InfoRow("Chính sách","Chính sách giá vốn")}`,"valuation-info-group");
  const body=`${val14SuccessorOf?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới sẽ thay thế lần trước; lần tính cũ được giữ nguyên để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label><label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>${setupFacts}`;
  return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
}
function render074IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-074"),state);const r=val14Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả lần tính",body:deniedBody(),centered:true});
  if(state==="INPUT_CHANGED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Lần tính hiện tại được giữ nguyên và không còn đủ điều kiện công bố.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
  if(r.status==="CALCULATING"||state==="PROCESSING")return appShell({title:"Kết quả lần tính",body:ioResult("Đang tính giá vốn","Có thể rời màn hình; kết quả sẽ được lưu trong cùng lần tính.",[["Kỳ",r.period],["Phạm vi",r.scope]],"info"),centered:true});
  if(r.status==="BLOCKED"||state==="BLOCKED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Chưa thể công bố","Các vấn đề dưới đây cần được xử lý trước khi tạo lần tính mới.")}${val14RunSummary(r)}${ds24SectionTitle("Đang bị chặn",`${r.blockers.length} vấn đề`)}${val14Blockers(r)}`});
  const body=`${val14RunSummary(r)}${ds24SectionTitle("Đối chiếu hai phương pháp")}${val14MethodCard(r)}${val14AdjustmentCard(r)}`;
  return appShell({title:"Kết quả lần tính",body,actions:primaryFooter("Rà soát công bố",'data-val14-action="review-publish"',r.status!=="READY_FOR_REVIEW")});
}
function render075IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-075"),state);
  return appShell({title:"Trạng thái lần tính",body:vBanner("info","Đã gộp vào kết quả lần tính","Blocker và trạng thái xử lý được hiển thị trực tiếp tại Kết quả lần tính."),actions:primaryFooter("Về kết quả lần tính",'data-val14-action="retired-to-result"')});
}
function render076IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-076"),state);const r=val14Current();
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát công bố",body:deniedBody(),centered:true});
  const stale=state==="SOURCE_CHANGED"||val14PublishReviewVersion==null||Number(val14PublishReviewVersion)!==Number(r.inputVersion);
  if(stale)return appShell({title:"Rà soát công bố",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố lần tính cũ. Tạo một lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
  const after=ds24InfoGroup("Sau công bố",`${ds24InfoRow("Phiên bản giá vốn","Tạo phiên bản mới")}${ds24InfoRow("Giá bán","Không thay đổi")}`,"valuation-info-group");
  const body=`${val14RunSummary(r)}${val14AdjustmentCard(r,"Tác động khi công bố")}${after}`;
  return appShell({title:"Rà soát công bố",body,actions:primaryFooter("Công bố giá vốn",'data-val14-action="publish"',r.status!=="READY_FOR_REVIEW")});
}
function render077IV14(state){
  if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-077"),state);const r=val14Current(),res=val14LastResult||{period:r.period,scope:r.scope,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};
  if(state==="PROCESSING")return appShell({title:"Kết quả công bố",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định giá vốn đã được công bố hay chưa","Không gửi lại lệnh công bố. Lần tính tạm thời không thể thao tác lại cho đến khi có kết quả.",[["Kỳ",res.period],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả công bố",body:ioResult("Chưa công bố giá vốn","Không có điều chỉnh hoặc phiên bản giá vốn mới.",[["Kỳ",res.period],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về kết quả lần tính",'data-val14-action="result-to-run"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả công bố",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Kỳ",res.period)}${ds24InfoRow("Phương pháp",res.method)}${ds24InfoRow("Hiệu lực",res.effectiveAt)}${ds24KeyValueRow("Giá vốn xuất",val14Money(res.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(res.endingAdjustment),true)}${ds24InfoRow("Giá bán","Không thay đổi")}`,"valuation-info-group valuation-info-group--wrap");
  const body=`<div class="io-result val14-result">${resultHero("Đã công bố giá vốn","Giá vốn và các điều chỉnh liên quan đã được ghi cho phạm vi đã rà soát.")}${overview}</div>`;
  return appShell({title:"Kết quả công bố",body,centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
}

const icons = {
  arrowLeft: '<path d="m15 18-6-6 6-6"/><path d="M9 12h10"/>',
  chevronLeft: '<path d="m15 18-6-6 6-6"/>',
  close: '<path d="m18 6-12 12"/><path d="m6 6 12 12"/>',
  arrowRight: '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
  chevronRight: '<path d="m9 18 6-6-6-6"/>',
  chevronDown: '<path d="m6 9 6 6 6-6"/>',
  fileText: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M8 13h8"/><path d="M8 17h6"/>',
  cloudUpload: '<path d="M12 13v8"/><path d="m16 16-4-4-4 4"/><path d="M4.393 15.269A5 5 0 0 1 6.5 5.5a7 7 0 0 1 13.33 3.4A4.5 4.5 0 0 1 18.5 17H17"/>',
  zap: '<path d="M13 2 3 14h9l-1 8 10-12h-9z"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  alert: '<path d="M10.3 2.9 1.8 17a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 2.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>',
  filter: '<path d="M4 5h16"/><path d="M7 12h10"/><path d="M10 19h4"/>',
  warehouse: '<path d="M3 21V8l9-5 9 5v13"/><path d="M7 21v-8h10v8"/><path d="M7 17h10"/>',
  calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/>',
  save: '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/>',
  package: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  layers: '<path d="m12.83 2.18 8 4a2 2 0 0 1 0 3.58l-8 4a2 2 0 0 1-1.66 0l-8-4a2 2 0 0 1 0-3.58l8-4a2 2 0 0 1 1.66 0Z"/><path d="m22 12.5-9.17 4.59a2 2 0 0 1-1.66 0L2 12.5"/><path d="m22 17.5-9.17 4.59a2 2 0 0 1-1.66 0L2 17.5"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  checkCircle: '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  xCircle: '<circle cx="12" cy="12" r="10"/><path d="M12 8v4"/><path d="M12 16h.01"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V5l8-3 8 3z"/><path d="m9 12 2 2 4-4"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  history: '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 3v6h6"/><path d="M12 7v5l3 2"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/>',
  rotate: '<path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M8 16H3v5"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  inbox: '<path d="M4 4h16v16H4z"/><path d="M4 14h4l2 3h4l2-3h4"/>',
  listCheck: '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8"/><path d="M13 12h8"/><path d="M13 18h8"/>',
  more: '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
};

const dsIconMap = {
  arrowLeft: "VIcons.arrowLeft", arrowRight: "VIcons.arrowRight", chevronLeft: "VIcons.chevronLeft", chevronRight: "VIcons.chevronRight", chevronDown: "VIcons.arrowDropDown",
  fileText: "VIcons.description", cloudUpload: "li:cloud-upload", zap: "VIcons.bolt", info: "VIcons.info", alert: "VIcons.warning", search: "VIcons.search",
  filter: "VIcons.tune", warehouse: "VIcons.warehouse", calendar: "VIcons.calendar", save: "VIcons.save", package: "VIcons.inventory",
  layers: "VIcons.inventory", check: "VIcons.check", checkCircle: "VIcons.success", xCircle: "VIcons.error", close: "VIcons.close",
  shield: "VIcons.shield", user: "VIcons.person", clock: "VIcons.clock", rotate: "VIcons.refresh", lock: "VIcons.lock", inbox: "VIcons.inbox",
  listCheck: "VIcons.checkList", more: "VIcons.moreHoriz", history: "VIcons.history", edit: "VIcons.edit"
};
function icon(name, className = "") {
  const semantic = dsIconMap[name] || "VIcons.info";
  return `<svg class="icon ${className}" data-ds-component="VIcon" data-ds-icon="${semantic}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] || icons.info}</svg>`;
}
function navChevron() {
  return icon("chevronRight", "icon--sm nav-action-chevron");
}




function currentScreen() {
  return screens.find((screen) => screen.id === activeScreenId);
}

function activeFlow() { return flowCatalog.find((f) => f.id === activeFlowId) || flowCatalog[0]; }
function flowScreens() { const f=activeFlow(); return (f?.screens || []).map((id)=>screens.find((s)=>s.id===id)).filter(Boolean); }
function renderFlowSelector() {
  if (typeof ThemeApp !== "undefined") ThemeApp.updateModeTabs();
  if (typeof ThemeApp !== "undefined" && ThemeApp.inTheme()) return ThemeApp.renderFlowSelector();
  document.body.dataset.workbenchMode = "bj";
  const sel=document.getElementById("flow-selector"); if(!sel) return;
  const grouped = FLOW_GROUPS.map((group) => ({
    label: group.label,
    flows: flowCatalog.filter((flow) => group.bjs.includes(flow.bj)),
  })).filter((group) => group.flows.length > 0);
  const ungrouped = flowCatalog.filter((flow) => !FLOW_GROUPS.some((group) => group.bjs.includes(flow.bj)));
  if (ungrouped.length) grouped.push({ label: "Other", flows: ungrouped });
  sel.innerHTML = grouped.map((group) => `
    <optgroup label="${group.label}">
      ${group.flows.map((f) => `<option value="${f.id}" ${f.id===activeFlowId?"selected":""}>${f.id} · ${f.bj} · ${f.name}</option>`).join("")}
    </optgroup>
  `).join("");
  const f=activeFlow();
  document.body.dataset.activeUif = f.id;
  document.getElementById("sidebar-flow-title").textContent=`${f.id} · ${f.name}`;
  document.getElementById("sidebar-flow-intent").textContent=f.intent || "";
  document.getElementById("workbench-title").textContent=`${f.bj} · ${f.name}`;
  document.getElementById("workbench-count").textContent=`${f.screens.length} màn · ${f.id}`;
}
function renderNavigation() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.inTheme()) return ThemeApp.renderNavigation();
  const navigation=document.getElementById("screen-navigation");
  navigation.innerHTML=`<div class="nav-group"><span class="nav-group-label">Screens</span>${flowScreens().map((screen)=>`<button class="screen-nav-item ${screen.id===activeScreenId?"is-active":""}" data-screen="${screen.id}" type="button"><span class="screen-nav-number">${screen.short}</span><span class="screen-nav-copy"><strong>${screen.name}</strong><span>${screen.surface}</span></span><span class="nav-chevron">›</span></button>`).join("")}</div>`;
}
function renderInspector() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.isRoot()) return ThemeApp.renderRootInspector();
  renderFlowInspector();
  if (typeof ThemeApp !== "undefined") ThemeApp.afterFlowInspector();
}
function renderFlowInspector() {
  const screen=currentScreen(); const state=stateByScreen[screen.id]; const f=activeFlow();
  document.getElementById("current-screen-id").textContent=`${screen.id} · ${screen.surface}`;
  document.getElementById("current-screen-name").textContent=screen.name;
  document.getElementById("state-switcher").innerHTML=screen.states.map((item)=>`<button class="state-chip ${item===state?"is-active":""}" data-state="${item}" type="button">${item}</button>`).join("");
  const actions=(screen.actions||[]).map((a)=>a.id).join(" · ") || (screen.traceActions?.length ? `System: ${screen.traceActions.join(" · ")}` : "Navigation / query");
  const figmaMigrationLabel = ({
    "UIF-01":"v3.0.1 · BJ01 migrated + DS hard-gated",
    "UIF-02":"v3.0.1 · BJ02 migrated + DS hard-gated",
    "UIF-03":"v3.0.1 · BJ03 valuation hierarchy + evidence",
    "UIF-13":"v3.0.1 · BJ13 late-cost allocation + review",
    "UIF-14":"v3.0.1 · BJ14 costing run + publish",
    "UIF-04":"v3.0.1 · BJ04 migrated + DS hard-gated",
    "UIF-05":"v3.0.1 · BJ05 migrated + VBottomSheet corrected",
    "UIF-06":"v3.0.1 · BJ06 UX/navigation corrected",
    "UIF-07":"v3.0.1 · BJ07 danh sách gọn + phân cấp sản phẩm/lô",
    "UIF-08":"v3.2.0 · BJ08 kiểm kê + DS aligned",
    "UIF-09":"v3.2.0 · BJ09 tình trạng hàng + audit history",
    "UIF-10":"v3.2.0 · BJ10 tiêu hủy + controlled completion",
    "UIF-11":"v3.2.0 · BJ11 hủy/sửa sai + DS aligned",
    "UIF-12":"v3.2.0 · BJ12 số dư đầu kỳ + control foundation",
    "UIF-15":"v3.2.0 · BJ15 báo cáo/thẻ kho + DS aligned",
    "UIF-16":"v3.2.0 · BJ16 đối soát sai lệch + evidence",
    "UIF-17":"v3.2.0 · BJ17 xác minh kết quả + recovery",
    "CAP-01":"v3.6.0 · Figma DS primitives · HTML Theme 7 design"
  })[activeFlowId] || "Calibrated shell · structural migration pending";
  document.getElementById("traceability").innerHTML=`<div class="trace-row"><span>BJ / UIF</span><strong>${f.bj} · ${f.id}</strong></div><div class="trace-row"><span>UC</span><strong>${(screen.uc||[]).join(" · ")||"—"}</strong></div><div class="trace-row"><span>Purpose</span><strong>${screen.purpose||"—"}</strong></div><div class="trace-row"><span>Action</span><strong>${actions}</strong></div><div class="trace-row"><span>Figma DS</span><strong>${figmaMigrationLabel}</strong></div><div class="trace-row"><span>DS annotations</span><strong>VPageScaffold → VAppBar · ${(screen.components||[]).join(" · ")}</strong></div><div class="trace-row"><span>Composition</span><strong>${screen.themeComposition||"—"}</strong></div>`;
  document.getElementById("design-rationale").textContent=f.intent || screen.purpose;
}

function statusBar() {
  if (FIGMA_MIGRATED_FLOWS.has(activeFlowId)) {
    return `<div class="app-statusbar" data-figma-slot="Status Bar"><span>9:41</span><span>LTE&nbsp;&nbsp;100%</span></div>`;
  }
  return `
    <div class="app-statusbar">
      <span>09:45</span>
      <span class="app-status-icons">
        <span class="signal-bars"><i></i><i></i><i></i><i></i></span>
        <span>5G</span>
        <span class="battery"></span>
      </span>
    </div>`;
}

function progress(step) {
  if (!step) return "";
  return `<div class="progress-track" aria-label="Tiến độ ${step} trên 5">${[1, 2, 3, 4, 5]
    .map((item) => `<span class="${item < step ? "is-done" : item === step ? "is-current" : ""}"></span>`)
    .join("")}</div>`;
}

function appShell({ title, subtitle = null, body, actions = "", centered = false, back = true, backAction = "" }) {
  const hasSubtitle = Boolean(subtitle);
  const baseFigmaTemplate = FIGMA_MIGRATED_FLOWS.has(activeFlowId) ? figmaScreenTemplate() : null;
  // Mobile / State is reserved for actual full-content empty/error/permission/blocked/no-result surfaces.
  // Result screens keep their business-detail archetype instead of mechanically becoming State pages.
  const isFullContentState = centered && /data-ds-component=["']VEmptyState["']/.test(String(body || ""));
  const figmaTemplate = isFullContentState ? "Mobile / State" : baseFigmaTemplate;
  const shellAttrs = `data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-subtitle="${subtitle == null ? 'null' : escapeAttribute(subtitle)}" data-ds-prop-show-back-button="${back}" data-ds-prop-center-title="false" data-ds-prop-actions="null"${figmaTemplate ? ` data-figma-template="${figmaTemplate}" data-figma-template-node="${FIGMA_TEMPLATE_NODES[figmaTemplate]}" data-figma-migrated="true"` : ''}`;
  return `
    <div class="v-page-scaffold ${figmaTemplate ? 'figma-calibrated-shell' : ''}" data-mobile-product data-product-app data-inspectable="true" ${shellAttrs}>
      ${statusBar()}
      <header class="app-header">
        <div class="app-appbar ${back ? 'has-back' : 'no-back'} ${hasSubtitle ? 'has-subtitle' : ''}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="${back}">
          ${back ? `<button class="app-icon-button app-back-button" ${backAction ? `data-action="${backAction}"` : "data-back"} type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon("chevronLeft", "icon--24")}</button>` : ``}
          <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${title}</h3>${hasSubtitle ? `<span data-ds-component="VAppBarSubtitle">${subtitle}</span>` : ""}</div>
        </div>
      </header>
      <div class="app-content ${centered ? "app-content--centered" : ""}" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard" data-ds-prop-horizontal="null" data-ds-prop-vertical="null" data-ds-prop-apply-bottom-safe-area="false"><div class="body-stack">${body}</div></div>
      ${actions}
    </div>`;
}

function vBanner(status, title, description, extraClass = "", density = "Default") {
  const tone = status === "error" ? "Danger" : status === "success" ? "Success" : status === "warning" ? "Warning" : "Info";
  const iconName = status === "error" ? "xCircle" : status === "success" ? "checkCircle" : status === "warning" ? "alert" : "info";
  const semanticIcon = status === "error" ? "VIcons.error" : status === "success" ? "VIcons.success" : status === "warning" ? "VIcons.warning" : "VIcons.info";
  return `<div class="v-banner v-banner--${status} ${extraClass}" data-ds-component="VBanner" data-figma-node="526:4215" data-ds-prop-tone="${tone}" data-ds-prop-density="${density}" data-ds-default-icon="${semanticIcon}">
    <span class="v-banner-icon" data-ds-internal="VBanner.icon">${icon(iconName)}</span>
    <div class="v-banner-copy" data-ds-internal="VBanner.copy"><strong>${title}</strong>${description ? `<span>${description}</span>` : ""}</div>
  </div>`;
}

function vBadge(label, status = "info", extraClass = "") {
  return `<span class="status-badge status-badge--${status} ${extraClass}" data-ds-component="VBadge" data-ds-prop-status="VBadgeStatus.${status}">${label}</span>`;
}

function stateBanner(state) {
  const mapping = {
    CONFLICT: ["warning", "Dữ liệu vừa thay đổi", "Tải phiên bản hiện hành trước khi tiếp tục; hệ thống không ghi đè im lặng."],
    LOCKED: ["warning", "Kho đang được khóa", "Chỉ có thể xem dữ liệu. Mở công việc đang giữ khóa để biết thêm chi tiết."],
    VALIDATION_ERROR: ["error", "Cần kiểm tra dữ liệu", "Dữ liệu đã nhập được giữ lại. Sửa trường được đánh dấu trước khi tiếp tục."],
    VALIDATION_FAILED: ["error", "Kiểm tra dữ liệu chưa đạt", "Không có dữ liệu nào được ghi nhận; sửa lỗi theo từng dòng hàng."],
    LOT_CONFLICT: ["error", "Thông tin lô không khớp", "Mã lô ND2408 đã tồn tại với hạn dùng khác. Hãy đối chiếu nhãn nhà sản xuất."],
    SOURCE_VERSION_STALE: ["warning", "Chứng từ nguồn đã đổi", "Lượng còn được phép nhận vừa thay đổi. Mở phiên bản hiện hành để đối chiếu."],
    PARTIAL_RECEIPT: ["info", "Có chứng từ đã nhận một phần", "Số còn lại vẫn bám theo chứng từ nguồn và được kiểm tra lũy kế."],
    APPROVAL_REQUIRED: ["warning", "Cần phê duyệt", "Yêu cầu chưa tạo tác động tồn vật lý cho đến khi có quyết định hợp lệ."],
    PENDING_APPROVAL: ["info", "Đã gửi cho người duyệt", "Bạn có thể rời màn hình này. Tồn kho chưa thay đổi; yêu cầu sẽ tự cập nhật khi có quyết định."],
    SELF_APPROVAL_NOT_ALLOWED: ["error", "Không được tự phê duyệt", "Người lập không thể đồng thời là người quyết định yêu cầu này."],
    APPROVAL_ALREADY_DECIDED: ["info", "Yêu cầu đã có quyết định", "Quyết định hợp lệ đầu tiên có hiệu lực; các thao tác quyết định đã được khóa."],
    STALE: ["warning", "Dữ liệu có thể đã cũ", "Làm mới lịch sử trước khi dựa vào trạng thái hiện tại."],
    PROCESSING_OR_UNKNOWN: ["warning", "Kết quả chưa xác định", "Không cần tạo lần nhận mới. Hệ thống tiếp tục xác minh cùng lần nhận hiện tại."],
    TERMINAL: ["success", "Đã xác lập kết quả", "Kết quả đã rõ; hệ thống sẽ đưa bạn về màn kết quả."],
    READ_ONLY: ["info", "Chế độ chỉ xem", "Dữ liệu vẫn hiển thị nhưng mọi thao tác thay đổi đã bị khóa."],
  };
  if (!mapping[state]) return "";
  const [status, title, message] = mapping[state];
  return vBanner(status, title, message);
}

function loadingBody() {
  return `<div class="skeleton-stack" data-ds-component="VSkeleton"><div class="skeleton skeleton--heading"></div><div class="skeleton skeleton--text"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--card"></div><div class="skeleton skeleton--text"></div></div>`;
}

function deniedBody() {
  return `<div class="empty-state permission-denied-state" data-ds-component="VEmptyState" data-theme-component="PermissionDeniedState" data-composed-from="VEmptyState,VEmptyMedia,VText"><div class="icon-box icon-box--danger" data-ds-component="VEmptyMedia" data-ds-prop-tone="VComponentTone.danger">${icon("lock", "icon--empty-media")}</div><h3 data-ds-component="VEmptyTitle">Không có quyền truy cập</h3><p data-ds-component="VEmptyDescription">Dữ liệu nghiệp vụ không được tải vào màn hình này. Liên hệ quản trị viên nếu cần cấp quyền.</p></div>`;
}

function emptyBody(filtered = false) {
  return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${filtered ? "Không có kết quả phù hợp" : "Không có chứng từ đang chờ nhận"}</h3><p data-ds-component="VEmptyDescription">${filtered ? "Xóa bớt điều kiện tìm kiếm để xem thêm kết quả." : "Quay lại để chọn cách nhận hàng khác nếu phù hợp."}</p></div>`;
}

function primaryFooter(label, actionAttr, disabled = false, tone = "primary") {
  const calibrated = FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  return `<footer class="app-actions${calibrated ? ' figma-sticky-footer' : ''}" data-ds-component="${calibrated ? 'DS v2 / Sticky Footer' : 'VPagePadding'}" ${calibrated ? 'data-ds-prop-layout="Single" data-ds-prop-tone="Default" data-figma-node="549:927"' : 'data-ds-slot="VPageScaffold.bottomBar"'}><button class="button button--primary" ${actionAttr} data-ds-component="VButton" data-ds-profile="button.primaryFooter" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-full-width="true" data-ds-prop-tone="VComponentTone.${tone}" type="button" ${disabled ? "disabled" : ""}>${label}</button></footer>`;
}






function escapeAttribute(value) {
  return String(value).replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}








function esc(v){return String(v??"").replace(/[&<>\"]/g,(m)=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));}
function dsIconForSurface(surface){return {list:"listCheck",form:"edit",detail:"fileText",review:"shield",result:"checkCircle",timeline:"history",dashboard:"layers",choice:"listCheck"}[surface]||"info";}
function genericFieldRows(screen){
  const rows=(screen.dataRows?.length?screen.dataRows:(screen.fields||[]).map((x)=>({label:x[0],example:x[1],ownership:"DERIVED"})));
  if(!rows.length) return "";
  if(screen.surface==="form") return `<section class="generic-form-section v-section" data-ds-component="VSection">${rows.map((r,i)=>{const comp=(r.component||(/(ngày|hạn|cut-off|kỳ)/i.test(r.label)?"VDatePicker":/(số tiền|giá trị|giá trước)/i.test(r.label)?"VMoneyField":/(số lượng|lượng |ngưỡng|mức tồn|số ngày)/i.test(r.label)?"VNumberField":/(trạng thái|loại|hành động|lý do|nguồn|phạm vi|định dạng|kho)/i.test(r.label)?"VSelect":"VTextFormField")); return `<label class="generic-field" data-ds-component="${comp}" data-ds-prop-label="${esc(r.label)}"><span>${esc(r.label)}</span><div class="generic-input">${esc(r.example||"Nhập dữ liệu")}</div></label>`}).join("")}</section>`;
  return `<div class="generic-kv-card" data-ds-component="VSection" data-composed-from="DS v2 / Info Row">${rows.map((r)=>`<div class="generic-kv-row" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span data-ds-component="VText">${esc(r.label)}</span><strong data-ds-component="VText">${esc(r.example||"—")}</strong></div>`).join("")}</div>`;
}
function genericCards(screen){
  const cards=screen.cards||[]; if(!cards.length) return "";
  if(screen.surface==="timeline") return `<div class="generic-timeline" data-theme-component="Theme7EvidenceTimeline" data-composed-from="VCard,VIconBox,VText,VBadge">${cards.map((c,i)=>`<div class="timeline-event"><span class="timeline-dot" data-ds-component="VIconBox">${icon(i===cards.length-1?"checkCircle":"fileText","icon--sm")}</span><div class="timeline-copy"><strong data-ds-component="VText">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span>${c[2]?vBadge(esc(c[2]),i===cards.length-1?"success":"info"):""}</div></div>`).join("")}</div>`;
  return `<div class="generic-card-list">${cards.map((c)=>`<article class="generic-data-card" data-ds-component="${screen.surface==="list"?"DS v2 / List Row":"VSection"}" ${screen.surface==="list"?'data-figma-node="525:519" data-ds-prop-type="Navigation"':'data-composed-from="DS v2 / Info Row,VBadge"'}><div class="generic-card-icon" data-ds-component="VCardIcon">${icon(dsIconForSurface(screen.surface),"icon--sm")}</div><div class="generic-card-copy"><strong data-ds-component="VCardTitle">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span></div>${c[2]?vBadge(esc(c[2]),/lỗi|block|thiếu|unknown|hết/i.test(c[2])?"warning":"info"):""}${screen.surface==="list"?icon("chevronRight","icon--sm"):""}</article>`).join("")}</div>`;
}
function genericPrimaryActions(screen,state){
  if(state==="PERMISSION_DENIED") return "";
  const acts=screen.actions||[]; if(!acts.length){
    if(screen.surface==="result") return primaryFooter("Xong",'data-generic-next',false);
    return "";
  }
  const primary=acts[0]; return primaryFooter(esc(primary.label),'data-generic-action="'+esc(primary.id)+'"',false,primary.tone==="danger"?"danger":"primary");
}
function genericStateContent(screen,state){
  if(state==="PERMISSION_DENIED") return deniedBody();
  if(state==="LOADING"||state==="CALCULATING"||state==="REBUILDING"||state==="PREPARING"||state==="PROCESSING"){
    if(screen.surface==="result") return `<div class="generic-result-center" data-theme-component="Theme7OperationResult"><div class="generic-spinner" data-ds-component="VLoading"></div><h3 data-ds-component="VText">Đang xử lý</h3><p data-ds-component="VText">Giữ nguyên ngữ cảnh. Bạn không cần gửi lại thao tác.</p></div>`;
    return loadingBody();
  }
  if(state.includes("EMPTY")) return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">Chưa có dữ liệu</h3><p data-ds-component="VEmptyDescription">Không có mục phù hợp trong phạm vi hiện tại.</p></div>`;
  if(screen.surface==="result" && /(COMPLETED|PUBLISHED|RESOLVED|ACTIVE_RECONCILED)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult" data-ds-component="VSection" data-composed-from="VIcon,VText,DS v2 / Info Row,VBanner">${resultHero("Đã xác lập kết quả","Kết quả chính thức đã sẵn sàng.")}${genericFieldRows(screen)}${genericCards(screen)}</div>`;
  if(screen.surface==="result" && /(UNKNOWN|COMMIT_UNKNOWN)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult">${vBanner("warning","Kết quả chưa xác định","Hệ thống tiếp tục xác minh chính lần xử lý này; không tạo thao tác mới.")}${genericFieldRows(screen)}</div>`;
  let notice=screen.notice? vBanner("info","Lưu ý",esc(screen.notice)):"";
  let stateNote="";
  if(/ERROR|FAILED|CONFLICT|BLOCK|LOCKED|STALE|MISSING|EXPIRED/.test(state)) stateNote=stateBanner(state)||vBanner("warning","Cần kiểm tra",`Cần xử lý điều kiện hiện tại trước khi tiếp tục.`);
  if(/APPROVAL/.test(state)) stateNote=stateBanner(state)||vBanner("info","Đang chờ phê duyệt","Chưa có tác động cuối cho đến khi có quyết định hợp lệ.");
  const intro=`<section class="v-section generic-intro" data-ds-component="VSection"><span class="eyebrow">${esc(activeFlowId)} · ${esc(screen.surface)}</span><h2 data-ds-component="VText">${esc(screen.name)}</h2><p data-ds-component="VText">${esc(screen.purpose)}</p></section>`;
  return intro+stateNote+notice+genericCards(screen)+genericFieldRows(screen);
}
function renderGeneric(screen,state){
  let body=genericStateContent(screen,state);
  if(screen.id==="SCR-044") body=`${vBanner("info","Đếm mù đang bật","Số lượng sổ sách không được tải vào DOM trước khi bạn gửi lần đếm đầu tiên.")}${body}`;
  return appShell({title:screen.name,body,actions:genericPrimaryActions(screen,state),back:!activeFlow()?.entry.includes(screen.id),centered:state==="PERMISSION_DENIED"});
}

function ds24Badge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t}" data-ds-component="VBadge" data-figma-node="525:309" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
// VBadge có chấm 8px: chấm đặc = cảnh báo, chấm rỗng = nguy hiểm (CSS .ds24-badge--dot), để màu không là tín hiệu duy nhất.
function ds24DotBadge(label,tone="Neutral") {
  const t=String(tone).toLowerCase();
  return `<span class="ds24-badge ds24-badge--${t} ds24-badge--dot" data-ds-component="VBadge" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${esc(label)}</span>`;
}
function ds24Chip(key,label,selected,attrName) {
  return `<button class="ds24-chip${selected?' is-selected':''}" type="button" ${attrName}="${escapeAttribute(key)}" data-ds-component="VChip" data-figma-node="522:7449" data-ds-prop-state="Default" data-ds-prop-tone="${selected?'Brand':'Neutral'}">${esc(label)}</button>`;
}
function ds24Search(value,attrs,placeholder="Tìm kiếm") {
  return `<div class="ds24-search-header" data-ds-component="DS v2 / Search & Filter Header" data-figma-node="547:2306" data-ds-prop-layout="Search"><label class="ds24-search" data-ds-component="VSearchBar" data-figma-node="522:7245" data-ds-prop-state="Default">${icon("search")}<input ${attrs} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}"></label></div>`;
}
function ds24ListRow({title,subtitle="",trailing="",leading="package",attrs="",type="Navigation",theme="",state="Default",density="Default",interactive=null,disabled=false,extraClass=""}) {
  const isInteractive=interactive==null ? type!=="Status" : Boolean(interactive);
  const tag=isInteractive?"button":"div";
  const effectiveState=disabled||state==="Disabled"?"Disabled":state;
  const disabledAttrs=effectiveState==="Disabled" ? (isInteractive?' disabled aria-disabled="true"':' aria-disabled="true"') : "";
  const buttonType=isInteractive?' type="button"':'';
  const hasLeading=Boolean(leading);
  const leadingHtml=hasLeading?icon(leading,"ds24-list-row__leading"):"";
  return `<${tag} class="ds24-list-row${hasLeading?'':' ds24-list-row--no-leading'}${extraClass?` ${extraClass}`:''}"${buttonType} ${attrs}${disabledAttrs} data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="${type}" data-ds-prop-state="${effectiveState}" data-ds-prop-density="${density}" data-ds-prop-leading="${hasLeading?'Visible':'Hidden'}" ${theme?`data-theme-component="${theme}"`:''}>${leadingHtml}<span class="ds24-list-row__copy"><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></span><span class="ds24-list-row__trailing">${trailing}${type==="Navigation"?icon("chevronRight","icon--sm"):''}</span></${tag}>`;
}
function ds24ContextStatusRow({title,subtitle="",label,tone="Neutral",leading="package",attrs=""}) {
  return ds24ListRow({title,subtitle,trailing:ds24Badge(label,tone),leading,attrs,type:"Status",density:"Compact",state:"Default",interactive:false});
}
function ds24InfoRow(label,value,extra="") {
  return `<div class="ds24-info-row ${extra}" data-ds-component="DS v2 / Info Row" data-figma-node="525:351"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
}
function ds24KeyValueRow(label,value,emphasis=false,valueAttrs="") {
  return `<div class="ds24-key-value-row${emphasis?' ds24-key-value-row--emphasis':''}" data-ds-component="DS v2 / Key-value Row" data-figma-node="525:358" data-ds-prop-state="${emphasis?'Emphasis':'Default'}"><span>${esc(label)}</span><strong ${valueAttrs}>${esc(value)}</strong></div>`;
}
function ds24InfoGroup(title,rows,extraClass="") {
  return `<section class="ds24-info-group ${extraClass}" data-composed-from="DS v2 / Info Row">${title?`<h2 class="ds24-info-group__title">${esc(title)}</h2>`:""}<div class="ds24-info-group__rows">${rows}</div></section>`;
}
function ds24GroupedCollection(content,extraClass="",composedFrom="") {
  const from=composedFrom||"DS v2 / List Row";
  return `<section class="ds24-grouped-collection ${extraClass}" data-layout-pattern="Grouped surface" data-figma-reference="4518:1545" data-composed-from="${escapeAttribute(from)}">${content}</section>`;
}
function ds24SummaryCard(title,body,extra="") {
  return `<section class="ds24-summary-card" data-ds-component="DS v2 / Summary Card" data-figma-node="525:552" data-ds-prop-tone="Neutral" ${extra}><h2 class="ds24-summary-card__title">${esc(title)}</h2><p class="ds24-summary-card__body">${esc(body)}</p></section>`;
}
function ds24SectionTitle(title,meta="") { return `<div class="ds24-section-title"><h2 class="vet45-text-style-5">${esc(title)}</h2>${meta?`<span class="vet45-text-style-11">${esc(meta)}</span>`:''}</div>`; }
function ds24Sheet({title,body,attrs=""}) {
  return `<div class="sheet-backdrop ds24-overlay" ${attrs}><section class="ds24-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" data-ds-prop-show-title="true" data-ds-prop-title="${escapeAttribute(title)}" role="dialog" aria-modal="true"><div class="ds24-sheet__handle" data-ds-internal="VBottomSheet.handle"></div><h3 class="vet45-text-style-4" data-ds-internal="VBottomSheet.title">${esc(title)}</h3><div class="ds24-sheet__body" data-ds-internal="VBottomSheet.content">${body}</div></section></div>`;
}


// ============================================================================
const io07Requests=[
  {id:"RTV-260827-02",supplier:"Minh Dũng",source:"YCTN-260827-02",sourceVersion:3,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G1",name:"Nobivac DHPPi",code:"SP-00142",uom:"hộp",tracking:"LOT",allocations:[
      {id:"RTV-A1",lot:"DH2507",expiry:"30/11/2026",qty:4,verified:false,physicalMismatch:false,affectedByChange:false},
      {id:"RTV-A2",lot:"DH2511",expiry:"31/03/2027",qty:2,verified:false,physicalMismatch:false,affectedByChange:false}
    ]},
    {id:"RTV-G2",name:"Nobivac DHPPi",code:"SP-00142",uom:"lọ",tracking:"LOT",allocations:[
      {id:"RTV-A3",lot:"DH2507",expiry:"30/11/2026",qty:6,verified:false,physicalMismatch:false,affectedByChange:false}
    ]},
    {id:"RTV-G3",name:"Găng tay khám Nitrile",code:"SP-00618",uom:"hộp",tracking:"NONE",allocations:[
      {id:"RTV-A4",lot:null,expiry:null,qty:5,verified:false,physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260827-04",supplier:"An Việt",source:"YCTN-260827-04",sourceVersion:5,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:true,sourceChanges:["Găng tay khám Nitrile · hộp: 8 → 5; 3 hộp được bỏ khỏi lượng chờ trả."],groups:[
    {id:"RTV-G4",name:"Găng tay khám Nitrile",code:"SP-00618",uom:"hộp",tracking:"NONE",allocations:[
      {id:"RTV-A5",lot:null,expiry:null,qty:5,previousQty:8,verified:false,physicalMismatch:false,affectedByChange:true}
    ]},
    {id:"RTV-G5",name:"Băng cuộn y tế",code:"SP-00307",uom:"cuộn",tracking:"NONE",allocations:[
      {id:"RTV-A6",lot:null,expiry:null,qty:2,verified:true,verifyMethod:"VISUAL",physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-03",supplier:"Thú Y Hoàng Gia",source:"YCTN-260903-03",sourceVersion:2,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"ACTIONABLE",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G6",name:"Amox 500",code:"SP-00205",uom:"hộp",tracking:"LOT",allocations:[
      {id:"RTV-A7",lot:"AM2505",expiry:"31/05/2027",qty:2,verified:true,verifyMethod:"VISUAL",physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-05",supplier:"Phú Nông",source:"YCTN-260903-05",sourceVersion:1,warehouse:"Kho chính",lifecycle:"Chờ bàn giao",queue:"WAITING",waitingReason:"Bộ phận Mua hàng đang cập nhật yêu cầu trả. Kho chỉ xem, chưa tiếp tục chuẩn bị.",changed:false,sourceChanges:[],groups:[
    {id:"RTV-G7",name:"Vitamin ADE",code:"SP-00511",uom:"chai",tracking:"LOT",allocations:[
      {id:"RTV-A8",lot:"VA2508",expiry:"31/08/2027",qty:3,verified:false,physicalMismatch:false,affectedByChange:false}
    ]}
  ]},
  {id:"RTV-260903-06",supplier:"Nam Việt",source:"YCTN-260903-06",sourceVersion:4,warehouse:"Kho chính",lifecycle:"Đã hủy từ nguồn",queue:"CLOSED",sourceCancelled:true,closed:true,changed:true,sourceChanges:["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."],groups:[]}
];
let io07Selected="RTV-260827-02", io07Query="", io07QueueFilter="ALL", io07ActiveAllocationId="", io07VerifySheetOpen=false, io07ScanLot="", io07LastResult=null, io07OperationSeq=1;
function io07Current(){return io07Requests.find(r=>r.id===io07Selected)||io07Requests.find(r=>!r.closed&&!r.completed)||io07Requests[0];}
function io07ActiveRequests(){return io07Requests.filter(r=>!r.closed&&!r.completed&&!r.sourceCancelled);}
function io07Allocations(req=io07Current()){return (req.groups||[]).flatMap(group=>(group.allocations||[]).map(allocation=>({group,allocation})));}
function io07FindAllocation(id,req=io07Current()){return io07Allocations(req).find(x=>x.allocation.id===id)||null;}
function io07AllVerified(req=io07Current()){const lines=io07Allocations(req);return lines.length>0&&lines.every(({allocation})=>allocation.verified&&!allocation.physicalMismatch);}
function io07HasMismatch(req=io07Current()){return io07Allocations(req).some(({allocation})=>allocation.physicalMismatch);}
function io07VerifiedCount(req=io07Current()){return io07Allocations(req).filter(({allocation})=>allocation.verified&&!allocation.physicalMismatch).length;}
function io07Stage(req){if(req.queue==="WAITING")return "WAITING";return io07AllVerified(req)?"READY":"ACTIONABLE";}
function io07StageMeta(req){const stage=io07Stage(req);if(stage==="WAITING")return ["Chờ cập nhật","info"];if(stage==="READY")return ["Sẵn sàng","success"];if(req.changed)return ["Cần kiểm lại","warning"];return ["Cần chuẩn bị","warning"];}
function io07MatchesQueue(req){return io07QueueFilter==="ALL"||io07Stage(req)===io07QueueFilter;}
function io07AllocationLabel(group,a){return group.tracking==="LOT"?`Lô ${a.lot}`:"Không theo lô";}
function io07AllocationSecondary(group,a){
  if(a.previousQty!=null&&a.affectedByChange)return `Cần kiểm lại · Trước ${a.previousQty} → nay ${a.qty} ${group.uom}`;
  const status=a.physicalMismatch?"Không khớp":a.verified?"Đã kiểm":"Cần trả";
  const bits=[status,`${a.qty} ${group.uom}`];
  if(a.expiry)bits.push(`HSD ${a.expiry}`);
  return bits.join(" · ");
}
function io07AllocationStatus(a){if(a.physicalMismatch)return ["Không khớp","Danger"];if(a.verified)return ["Đã kiểm","Success"];if(a.affectedByChange)return ["Cần kiểm lại","Warning"];return ["Chưa kiểm","Neutral"];}
function io07ProductProgress(group){
  const all=group.allocations||[], verified=all.filter(a=>a.verified&&!a.physicalMismatch).length;
  const mismatch=all.some(a=>a.physicalMismatch), changed=all.some(a=>a.affectedByChange);
  return {verified,total:all.length,label:`${verified}/${all.length}`,tone:mismatch?"Danger":changed?"Warning":verified===all.length&&all.length?"Success":"Neutral"};
}
function io07QueueList(requests){
  const rows=(requests||[]).map(r=>{
    const stage=io07Stage(r);
    const meta=io07StageMeta(r);
    const tone=meta[1]==="success"?"Success":meta[1]==="warning"?"Warning":meta[1]==="danger"?"Danger":meta[1]==="info"?"Info":"Neutral";
    const label=r.changed&&stage==="ACTIONABLE"?"Cần kiểm lại":meta[0];
    const search=`data-io07-search-text="${escapeAttribute(ioNormalizeSearch(`${r.id} ${r.supplier} ${r.source}`))}"`;
    const attrs=`data-io07-request="${escapeAttribute(r.id)}" ${search}`;
    const waiting=stage==="WAITING";
    return ds24ListRow({
      title:r.id,
      subtitle:`${r.supplier} · ${r.source}`,
      trailing:ds24Badge(label,tone),
      leading:null,
      attrs,
      type:"Navigation",
      state:waiting?"Disabled":"Default",
      density:"Default",
      interactive:true,
      disabled:waiting
    });
  }).join("");
  return rows?`<section class="ds24-list-stack io07-queue" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:"";
}
function io07ProductGroupHeader(group,{label="",tone="Neutral",role="rtv-product-summary"}={}){
  const subtitle=`${group.code||""}${group.code?" · ":""}${group.uom||""}`;
  return ds24ListRow({
    title:group.name,
    subtitle,
    trailing:label?ds24Badge(label,tone):"",
    leading:"package",
    attrs:`data-layout-role="${escapeAttribute(role)}" data-ds-role="rtv-product-group-header"`,
    type:"Status",
    density:"Compact",
    interactive:false
  });
}
function io07AllocationActionRow(group,a){
  const status=a.physicalMismatch?"Không khớp":a.affectedByChange?"Cần kiểm lại":a.verified?"Đã kiểm":"";
  let subtitle=`${a.qty} ${group.uom}`;
  if(a.expiry) subtitle+=` · HSD ${a.expiry}`;
  if(status) subtitle+=` · ${status}`;
  if(a.previousQty!=null&&a.affectedByChange) subtitle+=` · trước ${a.previousQty} ${group.uom}`;
  return ds24ListRow({
    title:io07AllocationLabel(group,a),
    subtitle,
    leading:null,
    attrs:`data-io07-allocation="${escapeAttribute(a.id)}" data-layout-role="rtv-allocation-row"`,
    type:"Navigation",
    density:"Default"
  });
}
function io07PreparationGroups(req){
  return (req.groups||[]).map(group=>{
    const progress=io07ProductProgress(group);
    const heading=io07ProductGroupHeader(group,{label:`${progress.verified}/${progress.total} đã kiểm`,tone:progress.tone,role:"rtv-product-summary"});
    const rows=(group.allocations||[]).map(a=>io07AllocationActionRow(group,a)).join("");
    return `<div class="io07-product-group ds24-grouped-subgroup" data-layout-role="product-allocation-subgroup" data-composed-from="DS v2 / List Row,VBadge">${heading}<div class="io07-allocation-list">${rows}</div></div>`;
  }).join("");
}
function io07ReviewGroups(reqOrLines,{statusLabel="Đã kiểm",statusTone="Success"}={}){
  let groups=[];
  if(Array.isArray(reqOrLines)){
    const map=new Map();
    for(const line of reqOrLines||[]){const key=`${line.name}|${line.code||""}|${line.uom}`;if(!map.has(key))map.set(key,{name:line.name,code:line.code||"",uom:line.uom,tracking:line.lot?"LOT":"NONE",allocations:[]});map.get(key).allocations.push({lot:line.lot,expiry:line.expiry,qty:line.qty});}
    groups=[...map.values()];
  } else groups=(reqOrLines?.groups||[]);
  const subgroups=groups.map(group=>{
    const allocations=group.allocations||[];
    const heading=io07ProductGroupHeader(group,{label:statusLabel,tone:statusTone,role:"rtv-review-product"});
    const rows=allocations.map(a=>{
      const left=a.lot?`Lô ${a.lot}${a.expiry?` · HSD ${a.expiry}`:""}`:"Không theo lô";
      return ds24KeyValueRow(left,`${a.qty} ${group.uom}`);
    }).join("");
    return `<div class="io07-review-product ds24-grouped-subgroup" data-layout-role="product-fact-subgroup" data-composed-from="VIcon,VText,VBadge,DS v2 / Key-value Row">${heading}<div class="io07-review-kv">${rows}</div></div>`;
  }).join("");
  return ds24GroupedCollection(subgroups,"io07-review-products io07-grouped-collection io07-grouped-collection--facts","DS v2 / List Row,DS v2 / Key-value Row");
}
function io07SourceDelta(req){
  const affected=io07Allocations(req).some(({allocation})=>allocation.affectedByChange);
  return affected?vBanner("warning","Yêu cầu đã thay đổi","Phần bị ảnh hưởng cần kiểm lại theo phiên bản mới.","","Compact"):"";
}
function io07VerificationSheet(req){
  if(!io07VerifySheetOpen)return "";const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return "";const {group,allocation:a}=found;
  const expectedLot=group.tracking==="LOT"?String(a.lot||""):"";const mismatch=Boolean(expectedLot&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expectedLot.toLocaleUpperCase("vi"));
  const product=ds24ContextStatusRow({title:group.name,subtitle:`${group.code} · ${group.uom}`,label:a.verified?"Đã kiểm":"Cần kiểm",tone:a.verified?"Success":"Neutral",leading:"package",attrs:'data-layout-role="rtv-verify-product"'});
  const facts=ds24InfoGroup("",`${ds24InfoRow("Cần chuẩn bị",`${a.qty} ${group.uom}`)}${group.tracking==="LOT"?ds24InfoRow("Lô cần khớp",a.lot):""}${a.expiry?ds24InfoRow("Hạn dùng",a.expiry):""}`,"ds24-info-group--untitled io07-sheet-facts");
  const lotInput=group.tracking==="LOT"?`${ds24TextField("Lô thực tế (không bắt buộc)",io07ScanLot,'data-io07-scan-lot autocomplete="off"',"Chỉ đối chiếu, không thay lô.")}<div data-io07-scan-feedback>${mismatch?vBanner("error","Lô không khớp",`Cần lô ${expectedLot}. Kho không thay lô tại đây.`,"","Compact"):""}</div>`:"";
  return `<div class="sheet-backdrop io07-verify-backdrop" data-io07-verify-backdrop><section class="bottom-sheet io-bottom-sheet io07-verification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Kiểm hàng thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Kiểm hàng thực tế</h3></div><div class="io07-verification-content">${product}${facts}${lotInput}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="mark-mismatch" type="button">Không khớp</button><button class="button button--primary" data-io07-action="confirm-allocation" type="button" ${mismatch?'disabled':''}>Đúng hàng</button></div></div></section></div>`;
}
function io07OpenVerification(id){io07ActiveAllocationId=id;io07ScanLot="";io07VerifySheetOpen=true;}
function io07ApplySourceUpdate(reqId,changes=[]){const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed||req.closed)return false;req.sourceVersion=Number(req.sourceVersion||0)+1;req.changed=true;const notes=[];for(const change of changes){if(change.type==="QTY"){const f=io07FindAllocation(change.allocationId,req);if(!f)continue;f.allocation.previousQty=f.allocation.qty;f.allocation.qty=change.newQty;f.allocation.verified=false;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=true;notes.push(change.note||`${f.group.name} · ${f.group.uom}: ${f.allocation.previousQty} → ${change.newQty}.`);}else if(change.type==="LOT"){const f=io07FindAllocation(change.allocationId,req);if(!f)continue;f.allocation.previousLot=f.allocation.lot;f.allocation.lot=change.newLot;f.allocation.verified=false;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=true;notes.push(change.note||`${f.group.name} · ${f.group.uom}: Lô ${f.allocation.previousLot} → ${change.newLot}.`);}else if(change.type==="REMOVE"){for(const group of req.groups||[]){const idx=(group.allocations||[]).findIndex(a=>a.id===change.allocationId);if(idx>=0){const old=group.allocations[idx];group.allocations.splice(idx,1);notes.push(change.note||`${group.name} · ${group.uom}${old.lot?` · Lô ${old.lot}`:""}: bỏ khỏi yêu cầu; lượng chờ trả được hệ thống giải phóng.`);break;}}req.groups=req.groups.filter(g=>(g.allocations||[]).length);}else if(change.type==="ADD"){let group=req.groups.find(g=>g.id===change.groupId);if(!group&&change.group){group={...change.group,allocations:[]};req.groups.push(group);}if(!group)continue;const allocation={...change.allocation,verified:false,physicalMismatch:false,affectedByChange:true};group.allocations.push(allocation);notes.push(change.note||`${group.name} · ${group.uom}${allocation.lot?` · Lô ${allocation.lot}`:""}: thêm ${allocation.qty} ${group.uom} cần kiểm.`);}}
  if(notes.length)req.sourceChanges=[...notes];req.queue="ACTIONABLE";return true;}
function io07CancelSource(reqId){const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed)return false;req.sourceVersion=Number(req.sourceVersion||0)+1;req.sourceCancelled=true;req.closed=true;req.queue="CLOSED";req.lifecycle="Đã hủy từ nguồn";req.changed=true;req.sourceChanges=["Bộ phận Mua hàng đã hủy yêu cầu trước bàn giao; lượng chờ trả được hệ thống giải phóng."];return true;}
function io07CreateResult(req){const op=`IO-RTV-260903-${String(io07OperationSeq++).padStart(3,"0")}`;const lines=io07Allocations(req).map(({group,allocation:a})=>({groupId:group.id,name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}));io07LastResult={operationId:op,requestId:req.id,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,lines};return io07LastResult;}
function io07ResultSnapshot(){if(io07LastResult)return io07LastResult;const req=io07Current();return {operationId:"IO-RTV-ĐANG-XỬ-LÝ",requestId:req.id,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,lines:io07Allocations(req).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty}))};}

function ioSearchBar(placeholder,attr,value=""){return `<div class="search-box io-search" data-ds-component="VSearchBar" data-ds-profile="search.standard" data-ds-prop-variant="VSearchBarVariant.outlined" data-ds-prop-tone="VComponentTone.neutral" data-ds-prop-hint-text="${escapeAttribute(placeholder)}"><span class="search-leading">${icon("search","icon--sm")}</span><input ${attr} value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" aria-label="${escapeAttribute(placeholder)}"/><span></span></div>`;}
function ioNormalizeSearch(value){return String(value||"").trim().toLocaleLowerCase("vi");}
function ioMatchesSearch(query,text){const q=ioNormalizeSearch(query);return !q||ioNormalizeSearch(text).includes(q);}
function ioFilterRows(scope,query){
  const q=ioNormalizeSearch(query); let visible=0;
  document.querySelectorAll(`[data-${scope}-search-text]`).forEach((row)=>{const show=!q||String(row.dataset[`${scope}SearchText`]||"").includes(q);row.hidden=!show;if(show)visible+=1;});
  const empty=document.querySelector(`[data-${scope}-filter-empty]`); if(empty)empty.hidden=visible!==0;
}
function ioSectionTitle(title,meta=""){return `<div class="io-section-title" data-ds-component="VSection"><h2 data-ds-component="VText">${title}</h2>${meta?`<span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${meta}</span>`:""}</div>`;}
function ioMetaText(v){return String(v??"").replace(/<[^>]*>/g,"").replace(/&[a-zA-Z0-9#]+;/g," ").trim();}
function ioMetaDetail(label,value,strong=false){return `<div class="io-meta-detail" data-composed-from="VText"><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'p'} data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${value}</${strong?'strong':'p'}></div>`;}
function ioMetaRow(label,value,strong=false){
  const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);
  const labelText=ioMetaText(label), valueText=ioMetaText(value);
  const needsMultiline=calibrated && (labelText.length>22 || valueText.length>30 || (labelText.length+valueText.length)>44);
  if(needsMultiline) return ioMetaDetail(label,value,strong);
  return `<div class="io-meta-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351" data-ds-prop-state="Default"':'data-ds-component="VSection"'}><span data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${label}</span><${strong?'strong':'span'} data-ds-component="VText">${value}</${strong?'strong':'span'}></div>`;
}
function ioProductRow({name,code,primary,secondary="",badge="",badgeStatus="info",attr="",interactive=true}){const tag=interactive?"button":"div";const typeAttr=interactive?' type="button"':"";const composed=interactive?"VText,VBadge,VIcon":"VText,VBadge";return `<${tag} class="io-product-row ${interactive?"":"is-readonly"}" ${attr}${typeAttr} data-theme-component="InventoryOperationItemRow" data-ds-migration-state="LEGACY_COMPOSITE_NOT_LIST_ROW" data-composed-from="${composed}"><span class="io-product-copy"><strong data-ds-component="VText">${name}</strong><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${code}${secondary?` · ${secondary}`:""}</small>${badge?vBadge(badge,badgeStatus):""}</span><span class="io-product-value"><strong data-ds-component="VText">${primary}</strong>${interactive?icon("chevronRight","icon--sm"):""}</span></${tag}>`;}
function ioReadCard(body,extra=""){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card io-read-card ${extra}" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${body}</div></section>`;}
function ioSecondary(label,attr){return `<button class="button button--secondary button--full" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" type="button">${label}</button>`;}
function ioEmpty(title,desc){return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">${title}</h3><p data-ds-component="VEmptyDescription">${desc}</p></div>`;}
function resultHero(title,desc,kind="success"){const iconName=kind==="success"?"checkCircle":kind==="danger"?"xCircle":"clock";const toneClass=kind==="success"?"icon-box--success":kind==="danger"?"icon-box--danger":"icon-box--warning";return `<div class="result-hero result-hero--${kind}" data-ds-component="VSection" data-composed-from="VIcon,VText"><div class="icon-box ${toneClass}" data-ds-component="VIcon">${icon(iconName,"icon--empty-media")}</div><h2 data-ds-component="VText" data-ds-prop-variant="VTextVariant.headingH3">${title}</h2><p data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodyDefault">${desc}</p></div>`;}
function ioResult(title,desc,rows,kind="success",button=""){return `<div class="io-result">${resultHero(title,desc,kind)}${ioReadCard(rows.map(r=>ioMetaRow(r[0],r[1],true)).join(''))}${button}</div>`;}
function ioFilterChips(active,items,attr){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<div class="filter-row io-task-filters" ${calibrated?'data-ds-component="VSection"':'data-theme-component="InventoryTaskFilterRow"'} data-composed-from="VChip">${items.map(([key,label])=>`<button type="button" class="filter-chip ${active===key?'is-active':''}" ${attr}="${key}" data-ds-component="VChip" data-ds-prop-selected="${active===key}">${label}</button>`).join('')}</div>`;}
function ac321CanonicalChips(active,items,attr){return `<div class="ac321-chip-wrap" data-composed-from="VChip" aria-label="Bộ lọc">${items.map(([key,label])=>ds24Chip(key,label,active===key,attr)).join('')}</div>`;}

// v1.6.0 — Inventory Audit & Control Product correction (UIF-08/UIF-09/UIF-10)
let ic09Filter="ALL";
let ic09Query="";
let ic09Selected="amox";
let ic09Destination="QUARANTINE";
let ic10Selected="amox-l2407";
let ic08ConfirmKind=null;
let ic08Scope="ALL";
let ic08ScopeTarget="";
let ic08ScopeSheetOpen=false;
let ic08ProductSheetOpen=false;
let ic08CutoffDate="2026-09-09";
let ic08CutoffTime="08:00";
let ic08Reason="Kiểm kê định kỳ";
let ic08AssignedCounter="Nguyễn An";
let ic08CancelReason="";
let ic08ReviewReason="";
let ic08KeypadTarget=null;
let ic08KeypadDraft="";
let ic08Counts={amox:"18",glove:"7"};
let ic08Recounts={amox:"18",glove:"7"};
let ic08Evidence={amox:"Kiểm lại kệ, thiếu 2 hộp",glove:"Phát hiện 1 hộp chưa ghi nhận"};
let ic08UnexpectedLine=null;
const ic09Items=[
  {id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",qty:18,uom:"hộp",state:"SELLABLE",label:"Bán được",expiry:"30/11/2026"},
  {id:"găng",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",qty:6,uom:"hộp",state:"QUARANTINE",label:"Cách ly",expiry:"—"},
  {id:"vitc",name:"Vitamin C",code:"SP-00231",lot:"L2310-C",qty:4,uom:"hộp",state:"EXPIRED",label:"Hết hạn",expiry:"31/08/2026"},
  {id:"dungthu",name:"Dầu sát khuẩn",code:"SP-00606",lot:"L2406-T",qty:2,uom:"chai",state:"DEMO",label:"Dùng thử",expiry:"31/12/2027"}
];
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
function icChoice(value,label,detail,checked=false){return `<label class="v364-radio-option" data-ds-component="VRadio" data-figma-node="522:7410" data-ds-prop-state="${checked?'On':'Off'}"><input type="radio" name="ic-state" value="${escapeAttribute(value)}" data-ic09-destination ${checked?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:''}</span></label>`;}
function icHeaderRows(rows){return ioReadCard(rows.map(([a,b,strong])=>ioMetaRow(a,b,!!strong)).join(''));}
function icSecondary(label,action,tone="secondary"){const c=tone==='danger'?'button button--danger button--full':'button button--secondary button--full';return `<button class="${c}" type="button" ${action}>${label}</button>`;}
function icApprovalButtons(prefix){return `<div class="ic-action-stack">${icSecondary("Từ chối",`data-${prefix}-action="reject"`,'danger')}${primaryFooter("Duyệt",`data-${prefix}-action="approve"`)}</div>`;}

function ic08Section(title,body,extra="") { return `<section class="ds24-section ${extra}" data-theme-component="Theme7StockCountSection">${ds24SectionTitle(title)}${body}</section>`; }
function ds24SelectField(label,value,options,attr="") {
  return `<label class="ds24-field" data-ds-component="VSelect" data-figma-node="522:7291"><span class="vet45-text-style-8">${esc(label)}</span><select ${attr} class="ds24-field__control vet45-text-style-6">${options.map(([v,l])=>`<option value="${v}" ${v===value?'selected':''}>${esc(l)}</option>`).join('')}</select></label>`;
}
function ds24TextField(label,value,attrs="",helper="") {
  return `<label class="ds24-field" data-ds-component="VTextField" data-figma-node="522:7186"><span class="vet45-text-style-8">${esc(label)}</span><input class="ds24-field__control vet45-text-style-6" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:''}</label>`;
}
function ic08QuantityTrigger(label,value,target,unit,disabled=false) {
  return `<div class="ds24-field" data-theme-component="Theme7QuantityEntry" data-composed-from="VText,VNumericKeypadSheet"><span class="vet45-text-style-8">${esc(label)}</span><button type="button" class="ds24-field__control ds24-quantity-trigger" data-ic08-keypad-open="${target}" data-unit="${escapeAttribute(unit)}" ${disabled?'disabled':''}><span class="vet45-text-style-6">${esc(value||'0')}</span><small class="vet45-text-style-11">${esc(unit)}</small></button></div>`;
}
function ic08ContextRows(rows) { return ds24InfoGroup('',rows.map(([k,v])=>ds24InfoRow(k,v)).join(''),'ds24-info-group--untitled ic08-info-group'); }
function ic08ProductInputGroup({keyId,code,name,lot,uom,value,label="Số lượng thực tế",targetPrefix="count",badge="",badgeTone="Neutral",unexpected=false,disabled=false,facts=""}) {
  const meta=`${code?`${code} · `:""}${lot?`Lô ${lot} · `:""}${uom}`;
  const head=ds24ListRow({title:name,subtitle:meta,trailing:badge?ds24Badge(badge,badgeTone):"",leading:"package",type:"Status",density:"Compact",interactive:false,attrs:`data-layout-role="stock-count-product" ${unexpected?'data-product-flag="is_unexpected_key"':''}`});
  const qty=ic08QuantityTrigger(label,value,`${targetPrefix}:${unexpected?'unexpected':keyId}`,uom,disabled);
  return `<div class="ac321-product-input-group" data-layout-pattern="Sectioned form composition" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VTextField">${head}${facts?`<div class="ac321-product-facts">${facts}</div>`:""}<div class="ac321-product-field">${qty}</div></div>`;
}
function ic08CountRow({id,name,lot,uom,value,unexpected=false,disabled=false}) {
  const code=id==='amox'?'SP-00128':id==='glove'?'SP-00410':unexpected?'':'';
  // v3.4.0: counting is already the screen task; do not repeat a generic "Cần đếm" badge on every product.
  return ic08ProductInputGroup({keyId:id,code,name,lot,uom,value,unexpected,disabled,badge:unexpected?'Bổ sung thực tế':'',badgeTone:'Info',targetPrefix:'count'});
}
function ic08RecountRow({id,name,lot,uom,book,first,variance,value,disabled=false}) {
  const code=id==='amox'?'SP-00128':'SP-00410';
  // v3.4.0: variance is a product fact, not a status badge. Keep the identity row quiet and put all numeric evidence in one aligned fact region.
  const facts=`${ds24KeyValueRow('Theo sổ',`${book} ${uom}`)}${ds24KeyValueRow('Lần đếm đầu',`${first} ${uom}`)}${ds24KeyValueRow('Chênh lệch',`${variance} ${uom}`)}`;
  return ic08ProductInputGroup({keyId:id,code,name,lot,uom,value,label:'Số lượng đếm lại',targetPrefix:'recount',disabled,facts});
}
function ic08NumericSheet() {
  if(!ic08KeypadTarget)return ""; const [mode,id]=ic08KeypadTarget.split(':'); const unit=id==='unexpected'?(ic08UnexpectedLine?.uom||'hộp'):'hộp'; const title=mode==='recount'?'Nhập số lượng đếm lại':'Nhập số lượng'; const keys=['1','2','3','4','5','6','7','8','9','.','0','⌫'];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="keypad-cancel"><section class="ds24-keypad" data-ds-component="VNumericKeypadSheet" data-figma-node="1829:6657" data-ds-prop-mode="Quantity" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-keypad__handle"></div><header><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-7">Đơn vị: ${esc(unit)}</p></header><div class="ds24-keypad__value vet45-text-style-2">${esc(ic08KeypadDraft||'0')}</div><div class="ds24-keypad__grid">${keys.map(k=>`<button type="button" data-ic08-key="${escapeAttribute(k)}" aria-label="${k==='⌫'?'Xóa một số':k}" class="vet45-text-style-3">${k}</button>`).join('')}</div><div class="ds24-keypad__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="keypad-cancel" data-ds-component="VButton" data-figma-node="521:529">Hủy</button><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="keypad-save" data-ds-component="VButton" data-figma-node="521:529">Lưu</button></div></section></div>`;
}
function ic08ConfirmationSheet() {
  if(!ic08ConfirmKind)return "";
  const cfg={
    'open-session':['Mở phiên kiểm kê?','Phạm vi sẽ được khóa theo thời điểm chốt của phiên.','Mở phiên','default',false],
    'submit-first':['Nộp lần đếm đầu?','Sau khi nộp, hệ thống mới hiển thị số sổ và chênh lệch.','Nộp kết quả','default',false],
    'submit-recount':['Gửi kết quả kiểm kê?','Kết quả đếm lại sẽ được chuyển sang công việc duyệt độc lập.','Gửi chờ duyệt','default',false],
    'approve':['Duyệt và điều chỉnh?','Hệ thống sẽ ghi điều chỉnh tồn kho và hoàn tất phiên nếu các guard vẫn hợp lệ.','Duyệt và điều chỉnh','default',false],
    'request-review':['Yêu cầu xem lại?','Phiên giữ nguyên khóa và quay lại bước đếm lại. Lý do được lưu cùng quyết định.','Yêu cầu xem lại','default',true],
    'cancel':['Hủy phiên kiểm kê?','Không tạo điều chỉnh. Lịch sử kiểm đếm được giữ và phạm vi được mở khóa.','Hủy phiên','danger',true]
  }[ic08ConfirmKind]; if(!cfg)return "";
  const [title,desc,action,tone,needsReason]=cfg; const val=ic08ConfirmKind==='cancel'?ic08CancelReason:ic08ReviewReason; const attr=ic08ConfirmKind==='cancel'?'data-ic08-cancel-reason':'data-ic08-review-reason';
  const reason=needsReason?ds24TextField('Lý do',val,attr,'Lý do được lưu trong lịch sử quản trị.'):'';
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="confirm-close"><section class="ds24-confirmation ds24-confirmation--${tone}" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="${needsReason?'Reason':'Plain'}" data-ds-prop-tone="${tone==='danger'?'Danger':'Default'}" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${reason}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="confirm-close" data-ds-component="VButton">Quay lại</button><button class="ds24-button ${tone==='danger'?'ds24-button--danger':'ds24-button--primary'}" type="button" data-ic08-action="confirm-${ic08ConfirmKind}" data-ds-component="VButton" ${needsReason&&!val.trim()?'disabled':''}>${esc(action)}</button></div></section></div>`;
}
function ic08SelectSheet() {
  if(!ic08ScopeSheetOpen&&!ic08ProductSheetOpen)return ""; const productMode=ic08ProductSheetOpen;
  const rows=productMode?[["vitc","Vitamin C","SP-00231 · Lô L2501-C · hộp"],["amox-new","Amox 500","SP-00128 · Lô L2501-A · hộp"]]:ic08Scope==='PRODUCT'?[["amox","Amox 500","SP-00128"],["glove","Găng tay M","SP-00410"]]:ic08Scope==='GROUP'?[["group-vaccine","Nhóm vaccine","Nhóm sản phẩm"],["group-medicine","Nhóm thuốc","Nhóm sản phẩm"]]:[["lot-l2407","Lô L2407-A","Amox 500"],["lot-l2405","Lô L2405-M","Găng tay M"]];
  return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="select-close"><section class="ds24-select-sheet" data-ds-pattern="Select Sheet" data-theme-component="Theme7SearchSelectSheet" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-sheet__handle"></div><h3 class="vet45-text-style-4">${productMode?'Thêm hàng thực tế':'Chọn phạm vi'}</h3>${ds24Search('','','Tìm kiếm')}<div class="ds24-list-stack">${rows.map(([id,name,meta])=>ds24ListRow({title:name,subtitle:meta,attrs:`data-ic08-${productMode?'product':'scope-target'}="${id}" data-name="${escapeAttribute(name)}" data-meta="${escapeAttribute(meta)}"`,theme:productMode?'Theme7UnexpectedItemResult':'Theme7ScopeResult'})).join('')}</div><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="select-close" data-ds-component="VButton">Đóng</button></section></div>`;
}
function ic08Overlays(){return `${ic08NumericSheet()}${ic08ConfirmationSheet()}${ic08SelectSheet()}`;}
function ic08SessionRow() {
  return `<section class="ds24-session-block" data-theme-component="Theme7StockCountSession"><div class="ds24-session-main">${ds24ListRow({title:'KK-0709-03',subtitle:'Kho trung tâm · Toàn kho',trailing:`${ds24Badge('Đang đếm','Info')}<small class="vet45-text-style-11">12/38</small>`,attrs:'data-ic08-action="resume"',leading:'listCheck',theme:'Theme7StockCountSessionRow'})}</div><button class="ds24-button ds24-button--danger ds24-session-cancel" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-figma-node="521:529">Hủy phiên</button></section>`;
}
function render042IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm kê kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Kiểm kê kho",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Kiểm kê kho",body:`${bj01Empty(false)}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
  if(state==="FILTER_EMPTY")return appShell({title:"Kiểm kê kho",body:`${ds24Search('','','Tìm phiên kiểm kê')}${bj01Empty(true)}${ic08Overlays()}`,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Kiểm kê kho",body:`${vBanner('info','Đã gửi chờ duyệt','Bạn đã hoàn tất phần việc của mình. Quyết định duyệt nằm trong công việc riêng của người duyệt.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Phạm vi','Kho trung tâm'],['Trạng thái','Chờ duyệt']])}`,back:false});
  const chips=ac321CanonicalChips('ALL',[["ALL","Tất cả"],["COUNTING","Đang đếm"],["APPROVAL","Chờ duyệt"]],'data-ic08-filter');
  return appShell({title:"Kiểm kê kho",body:`${ds24Search('','','Tìm phiên kiểm kê')}${chips}${ic08SessionRow()}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false});
}
function render043IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Tạo phiên kiểm kê",body:deniedBody(),centered:true});
  if(["CONFLICT","LOCKED"].includes(state))return appShell({title:"Tạo phiên kiểm kê",body:`${vBanner('warning','Phạm vi đang được kiểm kê','Không thể mở thêm phiên chồng lên phạm vi đang khóa.')}${ic08ContextRows([['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00']])}`});
  const validation=state==="VALIDATION_ERROR"?vBanner('error','Chưa đủ thông tin','Chọn phạm vi và nhập lý do kiểm kê trước khi mở phiên.'):'';
  const scopeOptions=[["ALL","Toàn kho"],["PRODUCT","Sản phẩm"],["GROUP","Nhóm sản phẩm"],["LOT","Lô"]];
  const target=ic08Scope!=="ALL"?`<div class="ds24-field" data-theme-component="Theme7ScopeTarget" data-composed-from="VText,Search & Select"><span class="vet45-text-style-8">${ic08Scope==='PRODUCT'?'Sản phẩm':ic08Scope==='GROUP'?'Nhóm sản phẩm':'Lô'}</span><button type="button" class="ds24-field__control ds24-select-trigger" data-ic08-action="scope-select-open"><span>${esc(ic08ScopeTarget||'Chọn phạm vi')}</span>${icon('chevronRight','icon--sm')}</button></div>`:'';
  const body=`${validation}${ic08ContextRows([['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00'],['Người đếm','Nguyễn An']])}${ds24SectionTitle('Thiết lập phiên')}${ds24SelectField('Phạm vi',ic08Scope,scopeOptions,'data-ic08-scope')}${target}${ds24TextField('Lý do kiểm kê',ic08Reason,'data-ic08-reason','Thông tin này được gửi cùng yêu cầu mở phiên.')}${vBanner('info','Phạm vi sẽ được khóa','Sau khi mở phiên, phạm vi và thời điểm chốt không tự thay đổi theo dữ liệu mới.')}${ic08Overlays()}`;
  return appShell({title:"Tạo phiên kiểm kê",body,actions:primaryFooter("Mở phiên kiểm kê",'data-ic08-action="open-session"',ic08Scope!=="ALL"&&!ic08ScopeTarget)});
}
function render044IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Đếm mù",body:deniedBody(),centered:true});
  if(state==="NO_RESULT")return appShell({title:"Đếm mù",body:bj01Empty(false),actions:primaryFooter("Về danh sách",'data-ic08-action="to-list"')});
  const lost=state==="LOCK_LOST"; const error=state==="VALIDATION_ERROR"?vBanner('error','Chưa nhập đủ kết quả','Nhập số đếm thực tế cho tất cả dòng trước khi nộp.'):'';
  const notice=lost?vBanner('warning','Phiên không còn giữ khóa','Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái authoritative trước khi tiếp tục.'):'';
  const unexpected=ic08UnexpectedLine?ic08CountRow({id:'unexpected',name:ic08UnexpectedLine.name,lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}):'';
  const body=`${error}${notice}${vBanner('info','Đếm mù đang bật','Chỉ ghi nhận số lượng thực tế. Số sổ và chênh lệch không có trong DOM trước lần nộp đầu.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Kho','Kho trung tâm'],['Thời điểm chốt','09/09/2026 · 08:00']])}<div class="ac321-list-meta">2 dòng cần đếm</div><div class="ds24-count-list ac321-count-collection">${ic08CountRow({id:'amox',name:'Amox 500',lot:'L2407-A',uom:'hộp',value:ic08Counts.amox,disabled:lost})}${ic08CountRow({id:'glove',name:'Găng tay M',lot:'L2405-M',uom:'hộp',value:ic08Counts.glove,disabled:lost})}${unexpected}</div>${!lost?`<button class="ds24-button ds24-button--secondary ds24-inline-action" type="button" data-ic08-action="add-actual-open" data-theme-component="Theme7UnexpectedPhysicalItemAction">${icon('package','icon--sm')}Thêm hàng thực tế</button>`:''}${ic08Overlays()}`;
  return appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')});
}
function render045IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Chênh lệch và đếm lại",body:deniedBody(),centered:true});
  const locked=state==="LOCKED", price=state==="PRICE_BASIS_REQUIRED", evidence=state==="EVIDENCE_REQUIRED", validation=state==="VALIDATION_ERROR";
  const notice=locked?vBanner('warning','Phiên đang chỉ đọc','Không thể sửa kết quả đếm trong trạng thái hiện hành.'):price?vBanner('error','Chưa đủ căn cứ giá','Dòng thừa chưa có căn cứ giá hợp lệ. Phiên tiếp tục giữ khóa; không nhập giá tạm để đi tiếp.'):evidence?vBanner('warning','Chưa đủ bằng chứng','Bằng chứng authoritative chưa đủ để gửi duyệt. Phiên tiếp tục giữ khóa.'):validation?vBanner('error','Kết quả đếm lại chưa hợp lệ','Kiểm tra các số lượng đếm lại trước khi gửi.'):'';
  const evidenceStatus=`<section class="ds24-section" data-theme-component="Theme7CountEvidenceStatus">${ds24SectionTitle('Căn cứ và bằng chứng')}${ic08ContextRows([['Amox 500','Đã có bằng chứng'],['Găng tay M',price?'Thiếu căn cứ giá':'Đã có căn cứ']])}${price||evidence?vBanner('warning','Chưa thể gửi duyệt','Hệ thống chỉ cho gửi khi nguồn có thẩm quyền xác nhận đủ căn cứ.'):''}</section>`;
  const body=`${notice}${vBanner('info','Chỉ xử lý dòng có chênh lệch','Số sổ được lộ sau lần đếm đầu. Người đếm chỉ nhập lại số thực tế của các dòng lệch.')}<div class="ds24-count-list ac321-count-collection">${ic08RecountRow({id:'amox',name:'Amox 500',lot:'L2407-A',uom:'hộp',book:20,first:18,variance:'−2 hộp',value:ic08Recounts.amox,disabled:locked})}${ic08RecountRow({id:'glove',name:'Găng tay M',lot:'L2405-M',uom:'hộp',book:6,first:7,variance:'+1 hộp',value:ic08Recounts.glove,disabled:locked})}</div>${evidenceStatus}${ic08Overlays()}`;
  let actions=''; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="ds24-button ds24-button--danger" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton">Hủy phiên</button>`:''}</footer>`;
  return appShell({title:"Chênh lệch và đếm lại",body,actions});
}
function render046IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt kết quả kiểm kê",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner('warning','Không thể tự duyệt','Người thực hiện kiểm kê không được duyệt chính kết quả của mình.'),back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner('info','Công việc đã có quyết định','Mở kết quả kiểm kê để xem trạng thái authoritative.'),actions:primaryFooter("Xem kết quả",'data-ic08-action="approval-result"'),back:false});
  const body=`${vBanner('info','Cần quyết định độc lập','Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.')}${ic08ContextRows([['Phiên','KK-0709-03'],['Người thực hiện','Nguyễn An'],['Kho','Kho trung tâm'],['Tổng dòng lệch','2 dòng']])}${ic08Section('Amox 500 · L2407-A',`${ic08ContextRows([['Chênh lệch','−2 hộp'],['Đếm lại','18 hộp'],['Bằng chứng','Đã đủ']])}`)}${ic08Section('Găng tay M · L2405-M',`${ic08ContextRows([['Chênh lệch','+1 hộp'],['Đếm lại','7 hộp'],['Căn cứ giá','Đã đủ'],['Bằng chứng','Đã đủ']])}`)}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-ic08-action="approve" data-action-contract="ACT-09-APPROVE" data-decision-role="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="request-review" data-action-contract="ACT-09-APPROVE" data-decision-role="request-review" data-ds-component="VButton">Yêu cầu xem lại</button></footer>`;
  return appShell({title:"Duyệt kết quả kiểm kê",body,actions,back:false});
}
function ds24Result(title,description,rows,tone='success') {
  const iconName=tone==='success'?'checkCircle':tone==='danger'?'xCircle':'alert';
  return `<section class="ds24-result" data-theme-component="Theme7OperationResult" data-composed-from="VIcon,VText,DS v2 / Info Row,State Pattern"><div class="ds24-result__icon ds24-result__icon--${tone}">${icon(iconName)}</div><h2 class="vet45-text-style-3">${esc(title)}</h2><p class="vet45-text-style-6">${esc(description)}</p><div class="ds24-info-stack">${rows.map(([k,v])=>ds24InfoRow(k,v)).join('')}</div></section>`;
}
function render047IC08(state) {
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả kiểm kê",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả kiểm kê",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đang xác minh kết quả','Không gửi lại điều chỉnh. Hệ thống đang xác minh đúng lần xử lý này.',[['Phiên','KK-0709-03'],['Định danh xử lý','Giữ nguyên'],['Tồn kho','Chưa kết luận']],'warning'),actions:primaryFooter("Tiếp tục xác minh",'data-ic08-action="verify-result"'),centered:true,back:false});
  if(state==="CANCELLED")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đã hủy phiên','Không tạo điều chỉnh; lịch sử kiểm đếm được giữ và phạm vi đã mở khóa.',[['Phiên','KK-0709-03'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở']],'warning'),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả kiểm kê",body:ds24Result('Điều chỉnh chưa được thực thi','Guard nghiệp vụ không đạt; không có tác động tồn kho.',[['Phiên','KK-0709-03'],['Tác động','Không ghi nhận'],['Khóa phạm vi','Theo trạng thái phiên']],'warning'),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả kiểm kê",body:ds24Result('Đã hoàn tất kiểm kê','Điều chỉnh tồn kho đã được ghi theo quyết định duyệt và phạm vi đã mở khóa.',[['Phiên','KK-0709-03'],['Điều chỉnh','ADJ-0709-03'],['Đã điều chỉnh','2 dòng'],['Khóa phạm vi','Đã mở']]),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
}

function ic09StatusTone(s){return s==="EXPIRED"||s==="DAMAGED"?"danger":s==="QUARANTINE"?"warning":s==="DEMO"?"info":"success";}
function ic09Current(){return ic09Items.find(x=>x.id===ic09Selected)||ic09Items[0];}
function render036IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Tình trạng hàng",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Tình trạng hàng",body:loadingBody(),back:false});
  const labels=[["ALL","Tất cả"],["SELLABLE","Bán được"],["QUARANTINE","Cách ly"],["DAMAGED","Hỏng"],["DEMO","Dùng thử"],["EXPIRED","Hết hạn"]];
  const q=ic09Query.trim().toLowerCase();
  const items=ic09Items.filter(x=>(ic09Filter==="ALL"||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
  if(state==="EMPTY")return appShell({title:"Tình trạng hàng",body:ioEmpty("Chưa có hàng trong kho","Khi có tồn kho, tình trạng hàng sẽ xuất hiện tại đây."),back:false});
  const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:x.label,badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
  const statusChips=`<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>`;
  const body=`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}${statusChips}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${rows}</div></div>`:ioEmpty("Không có hàng phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
  return appShell({title:"Tình trạng hàng",body,back:false});
}
function render037IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết tình trạng hàng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết tình trạng hàng",body:loadingBody()});
  const x=ic09Current(); const expired=state==="EXPIRED"||x.state==="EXPIRED";
  const locked=state==="LOCKED";
  const notice=expired?vBanner("warning","Lô đã hết hạn","Hạn dùng đã qua theo ngày nghiệp vụ. Hệ thống tự loại phần này khỏi khả dụng bán; không cần thao tác đánh dấu."):locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):"";
  const body=`${notice}${icHeaderRows([["Sản phẩm",x.name,true],["Mã",x.code],["Lô",x.lot],["Hạn dùng",x.expiry],["Tình trạng",expired?"Hết hạn":x.label],["Tồn vật lý",`${x.qty} ${x.uom}`],["Khả dụng bán",expired?`0 ${x.uom}`:(x.state==="SELLABLE"?`${x.qty} ${x.uom}`:`0 ${x.uom}`)]])}${ioSectionTitle("Tác động")}<p class="io-footnote">Thay đổi tình trạng chỉ phân loại lại cùng lượng hàng; tổng tồn vật lý và giá trị không đổi.</p>${icSecondary("Xem lịch sử",'data-ic09-action="history"')}`;
  return appShell({title:"Chi tiết tình trạng hàng",body,actions:locked||expired?"":primaryFooter("Thay đổi tình trạng",'data-ic09-action="change"')});
}
function render038IC09(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chuyển tình trạng hàng",body:deniedBody(),centered:true,back:false});
  const x=ic09Current();
  if(state==="LOCKED")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đang thuộc phạm vi kiểm kê","Không thể thay đổi tình trạng trong khi phạm vi đang khóa.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Tình trạng hiện tại",x.label]])}`,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc của mình. Người duyệt nhận một công việc riêng; hàng chưa đổi tình trạng cho đến khi quyết định được ghi nhận.")}${icHeaderRows([["Sản phẩm",x.name,true],["Từ",x.label],["Sang",ic09Destination==="QUARANTINE"?"Cách ly":ic09Destination==="DAMAGED"?"Hỏng":ic09Destination==="DEMO"?"Dùng thử":"Bán được"]])}`,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Chuyển tình trạng hàng",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu này."),back:false});
  if(state==="APPROVAL_REVIEW"){
    const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định. Việc duyệt chỉ thay đổi phân loại; tổng tồn vật lý và giá trị không đổi.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Từ",x.label],["Sang",ic09Destination==="QUARANTINE"?"Cách ly":"Hỏng"],["Số lượng",`${x.qty} ${x.uom}`],["Lý do","Bao bì có dấu hiệu bất thường"]])}`;
    return appShell({title:"Duyệt thay đổi tình trạng",body,actions:icApprovalButtons("ic09"),back:false});
  }
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng đích và nhập lý do phù hợp."):"";
  const choices=[icChoice("QUARANTINE","Cách ly","Tạm thời không bán",ic09Destination==="QUARANTINE"),icChoice("DAMAGED","Hỏng","Không còn đủ điều kiện bán",ic09Destination==="DAMAGED"),icChoice("DEMO","Dùng thử","Chuyển sang mục đích dùng thử",ic09Destination==="DEMO")];
  if(x.state!=="SELLABLE")choices.push(icChoice("SELLABLE","Bán được","Chỉ khi hàng đủ điều kiện trở lại bán",ic09Destination==="SELLABLE"));
  const body=`${error}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Hiện tại",x.label],["Số lượng",`${x.qty} ${x.uom}`]])}${ioSectionTitle("Tình trạng mới")}<div class="choice-list">${choices.join('')}</div>${icTextarea("Lý do","Bao bì có dấu hiệu bất thường",'data-ic09-reason')}`;
  return appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-ic09-action="submit"')});
}
function render041IC09(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả thay đổi",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả thay đổi",body:ioResult("Đang xác minh kết quả","Không gửi một yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.",[["Sản phẩm",ic09Current().name],["Tình trạng","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic09-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả thay đổi",body:ioResult("Yêu cầu không được thực hiện","Tình trạng và tồn kho không thay đổi.",[["Sản phẩm",ic09Current().name],["Tồn vật lý","Không đổi"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  if(state==="EXPIRED")return appShell({title:"Tình trạng hàng",body:ioResult("Lô đã hết hạn","Hệ thống đã loại lượng hàng này khỏi khả dụng bán theo hạn dùng; tồn vật lý vẫn được giữ để tiếp tục xử lý.",[["Tồn vật lý","4 hộp"],["Khả dụng bán","0 hộp"]],"warning"),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả thay đổi",body:ioResult("Đã cập nhật tình trạng","Cùng lượng hàng đã được phân loại lại; tổng tồn vật lý và giá trị không thay đổi.",[["Sản phẩm",ic09Current().name],["Tình trạng mới",ic09Destination==="QUARANTINE"?"Cách ly":ic09Destination==="DAMAGED"?"Hỏng":ic09Destination==="DEMO"?"Dùng thử":"Bán được"],["Tồn vật lý",`${ic09Current().qty} ${ic09Current().uom} · không đổi`]]),actions:primaryFooter("Về tình trạng hàng",'data-ic09-action="to-list"'),centered:true,back:false});
}
function render056IC09(state){
  if(activeFlowId!=="UIF-09") return renderGeneric(screens.find(s=>s.id==="SCR-056"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Lịch sử tình trạng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Lịch sử tình trạng",body:loadingBody()});
  const x=ic09Current();
  const body=`${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot]])}<div class="timeline"><div class="timeline-card">${ioMetaRow("07/09/2026 · 09:14","Bán được → Cách ly",true)}<small>Nguyễn An · Bao bì có dấu hiệu bất thường</small></div><div class="timeline-card">${ioMetaRow("01/09/2026 · 08:00","Nhận vào kho",true)}<small>Tình trạng ban đầu: Bán được</small></div></div>`;
  return appShell({title:"Lịch sử tình trạng",body});
}

function render036IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Hàng có thể xử lý",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Hàng có thể xử lý",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Hàng có thể xử lý",body:ioEmpty("Chưa có hàng cần xử lý","Chỉ hàng không bán được và thuộc quyền sở hữu của tổ chức mới xuất hiện tại đây."),back:false});
  const body=`${vBanner("info","Chỉ hiển thị hàng đủ điều kiện","Hàng đang bán được cần đổi tình trạng trước khi có thể lập yêu cầu tiêu hủy.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${ioProductRow({name:"Amox 500",code:"SP-00128",primary:"6 hộp",secondary:"Lô L2407-A",badge:"Cách ly",badgeStatus:"warning",attr:'data-ic10-item="amox-l2407"'})}${ioProductRow({name:"Vitamin C",code:"SP-00231",primary:"4 hộp",secondary:"Lô L2310-C",badge:"Hết hạn",badgeStatus:"danger",attr:'data-ic10-item="vitc-l2310"'})}</div></div>`;
  return appShell({title:"Hàng có thể xử lý",body,back:false});
}
function render037IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết hàng",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Chi tiết hàng",body:`${vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc.")}${icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"]])}`});
  const body=`${icHeaderRows([["Sản phẩm","Amox 500",true],["Mã","SP-00128"],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Tồn vật lý","6 hộp"],["Quyền sở hữu","Hàng của tổ chức"]])}${ioSectionTitle("Xử lý")}<p class="io-footnote">Phê duyệt yêu cầu không làm giảm tồn. Chỉ xác nhận đã tiêu hủy thực tế mới cho phép ghi giảm.</p>`;
  return appShell({title:"Chi tiết hàng",body,actions:primaryFooter("Đề nghị tiêu hủy",'data-ic10-action="request"')});
}
function render040IC10(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Yêu cầu tiêu hủy",body:deniedBody(),centered:true,back:false});
  const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
  if(state==="PRICE_BASIS_REQUIRED")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu vì chưa xác định được căn cứ giá chính thức cho lượng hàng này. Không nhập giá thủ công để bỏ qua kiểm soát.")}${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}`,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"',true)});
  if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc lập yêu cầu. Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Tác động tồn kho","Chưa có"]])}`,back:false});
  if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế. Tồn vật lý chưa giảm ở bước này.")}${base}${icHeaderRows([["Số lượng đề nghị","6 hộp",true],["Căn cứ giá","Giá vốn hiện hành"],["Lý do","Hàng không còn đủ điều kiện sử dụng"]])}`,actions:icApprovalButtons("ic10"),back:false});
  if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Yêu cầu đã được duyệt nhưng tồn kho vẫn giữ nguyên. Công việc xác nhận tiêu hủy sẽ được giao cho người thực hiện phù hợp.")}${base}${icHeaderRows([["Đã duyệt","6 hộp",true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false});
  if(state==="COMPLETION_QTY_BLOCKED")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("error","Số lượng thực tế vượt phạm vi được duyệt","Không thể ghi giảm. Cần lập yêu cầu và phê duyệt mới cho phần vượt chính sách.")}${base}${icField("Đã tiêu hủy thực tế","7",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',true,"danger"),back:false});
  if(state==="COMPLETION")return appShell({title:"Xác nhận đã tiêu hủy",body:`${vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng ở đây là lượng thực tế đã tiêu hủy và sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế","6",'data-ic10-actual','number')}${icTextarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-ic10-action="complete"',false,"danger"),back:false});
  const body=`${base}${icField("Số lượng đề nghị","6",'data-ic10-qty','number')}${icTextarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}${icTextarea("Bằng chứng","Ảnh hiện trạng và biên bản kiểm tra",'data-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
  return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-ic10-action="submit"')});
}
function render041IC10(state){
  if(state==="PROCESSING")return appShell({title:"Kết quả tiêu hủy",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đang xác minh kết quả","Không tạo lần tiêu hủy mới. Hệ thống đang kiểm tra chính lần xác nhận này.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Chưa kết luận"]],"warning"),actions:primaryFooter("Kiểm tra kết quả",'data-ic10-action="verify"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Chưa ghi giảm","Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.",[["Yêu cầu","TH-0709-04"],["Tồn vật lý","Không thay đổi"]],"warning"),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
}

function render036IO07(state){
  if(activeFlowId==="UIF-09") return render036IC09(state);
  if(activeFlowId==="UIF-10") return render036IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-036"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Hàng chờ trả nhà cung cấp",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING") return appShell({title:"Hàng chờ trả nhà cung cấp",body:loadingBody(),back:false});
  const all=io07ActiveRequests().filter(r=>io07MatchesQueue(r));
  const candidates=all.filter(r=>ioMatchesSearch(io07Query,`${r.id} ${r.supplier} ${r.source}`));
  const search=ds24Search(io07Query,"data-io07-search", "Tìm mã yêu cầu hoặc nhà cung cấp");
  const filters=`<div class="io07-chip-scroll" data-composed-from="VChip">${[["ALL","Tất cả"],["ACTIONABLE","Cần chuẩn bị"],["READY","Sẵn sàng"],["WAITING","Đang chờ"]].map(([k,l])=>ds24Chip(k,l,io07QueueFilter===k,"data-io07-filter")).join("")}</div>`;
  if(state==="EMPTY") return appShell({title:"Hàng chờ trả nhà cung cấp",body:`${search}${filters}${ioEmpty("Chưa có hàng chờ trả","Khi có yêu cầu trả đang hiệu lực, công việc sẽ xuất hiện tại đây.")}`,back:false});
  const queue=io07QueueList(candidates);
  const empty=`<div data-io07-filter-empty ${candidates.length?'hidden':''}>${ioEmpty("Không tìm thấy yêu cầu phù hợp","Đổi từ khóa hoặc bộ lọc để xem công việc khác.")}</div>`;
  return appShell({title:"Hàng chờ trả nhà cung cấp",body:`${search}${filters}${queue}${empty}`,back:false});
}
function render037IO07(state){
  if(activeFlowId==="UIF-09") return render037IC09(state);
  if(activeFlowId==="UIF-10") return render037IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-037"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Chuẩn bị hàng trả",body:deniedBody(),centered:true});
  if(state==="LOADING") return appShell({title:"Chuẩn bị hàng trả",body:loadingBody()});
  const req=io07Current();
  const total=io07Allocations(req).length,verified=io07VerifiedCount(req);
  const requestContext=ds24ContextStatusRow({title:req.id,subtitle:`${req.supplier} · ${req.source}`,label:`${verified}/${total}`,tone:io07HasMismatch(req)?"Danger":verified===total&&total?"Success":"Neutral",leading:null,attrs:'data-layout-role="rtv-request-context"'});
  if(req.sourceCancelled||req.closed)return appShell({title:"Chuẩn bị hàng trả",body:`${requestContext}${vBanner("info","Yêu cầu đã được hủy","Phần chờ trả đã được hệ thống giải phóng; Kho không cần thao tác thêm.","","Compact")}`,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  const mismatch=io07HasMismatch(req)||state==="PHYSICAL_MISMATCH";
  const mismatchBanner=mismatch?vBanner("warning","Chờ cập nhật yêu cầu","Hàng thực tế không khớp. Kho không sửa số lượng hoặc lô tại đây.","","Compact"):"";
  const groups=io07PreparationGroups(req);
  const collection=ds24GroupedCollection(groups,"io07-product-list io07-grouped-collection io07-grouped-collection--preparation","Product group header,Nested navigation row");
  const body=`${requestContext}${io07SourceDelta(req)}${mismatchBanner}${ds24SectionTitle("Hàng cần chuẩn bị",`${req.groups.length} nhóm sản phẩm`)}${collection}${io07VerificationSheet(req)}`;
  return appShell({title:"Chuẩn bị hàng trả",body,actions:primaryFooter("Rà soát bàn giao",'data-io07-action="review-handover"',!io07AllVerified(req)||mismatch)});
}
function render039IO07(state){
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-039"),state);
  if(state==="PERMISSION_DENIED") return appShell({title:"Bàn giao trả nhà cung cấp",body:deniedBody(),centered:true});
  const req=io07Current();const sourceChanged=state==="SOURCE_CHANGED"||Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion);const mismatch=io07HasMismatch(req)||state==="PHYSICAL_MISMATCH";const ready=io07AllVerified(req)&&!sourceChanged&&!mismatch;
  const context=ds24InfoGroup("Thông tin bàn giao",`${ds24InfoRow("Nhà cung cấp",req.supplier)}${ds24InfoRow("Yêu cầu trả",req.id)}${ds24InfoRow("Kho",req.warehouse)}`,"io07-handover-context");
  const review=`${ds24SectionTitle("Hàng sẽ bàn giao",`${req.groups.length} nhóm sản phẩm`)}${io07ReviewGroups(req,{statusLabel:"Đã kiểm",statusTone:"Success"})}`;
  if(!ready){const why=sourceChanged?"Yêu cầu đã thay đổi sau khi mở rà soát. Kiểm lại phần bị ảnh hưởng.":"Có phần hàng chưa khớp yêu cầu hiện hành.";return appShell({title:"Bàn giao trả nhà cung cấp",body:`${context}${vBanner("warning","Cần kiểm lại trước khi bàn giao",why,"","Compact")}${review}`,actions:primaryFooter("Kiểm lại hàng",'data-io07-action="back-to-preparation"')});}
  return appShell({title:"Bàn giao trả nhà cung cấp",body:`${context}${review}`,actions:primaryFooter("Xác nhận đã bàn giao",'data-io07-action="confirm-handover"')});
}
function render041IO07(state){
  if(activeFlowId==="UIF-09") return render041IC09(state);
  if(activeFlowId==="UIF-10") return render041IC10(state);
  if(activeFlowId!=="UIF-07") return renderGeneric(screens.find(s=>s.id==="SCR-041"),state);
  const result=io07ResultSnapshot();const req=io07Requests.find(r=>r.id===result.requestId)||io07Current();
  if(state==="PROCESSING")return appShell({title:"Kết quả trả nhà cung cấp",body:loadingBody(),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Đang xác minh kết quả","Không gửi lại bàn giao. Hệ thống đang kiểm tra chính lần xác nhận này.",[["Yêu cầu",result.requestId],["Tồn vật lý","Chưa kết luận"]],"warning"),centered:true,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Chưa ghi nhận bàn giao","Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.",[["Yêu cầu",result.requestId],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter(req&&!req.closed&&!req.completed?"Xem yêu cầu hiện tại":"Về hàng chờ trả",req&&!req.closed&&!req.completed?'data-io07-action="back-to-rtv-request"':'data-io07-action="result-to-rtv-queue"')});
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả trả nhà cung cấp",body:ioResult("Không có quyền thực hiện","Tồn kho không thay đổi. Chi tiết nghiệp vụ được giới hạn theo quyền hiện hành.",[["Kết quả","Không ghi nhận bàn giao"],["Tồn kho","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
  const resultGroupCount=new Set((result.lines||[]).map(line=>`${line.name}|${line.code||""}|${line.uom}`)).size;
  const context=ds24InfoGroup("Thông tin trả hàng",`${ds24InfoRow("Nhà cung cấp",result.supplier)}${ds24InfoRow("Yêu cầu trả",result.requestId)}`,"io07-result-context");
  const body=`<div class="io-result io07-result">${resultHero("Đã bàn giao cho nhà cung cấp","Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.")}${context}${ds24SectionTitle("Hàng đã bàn giao",`${resultGroupCount} nhóm sản phẩm`)}${io07ReviewGroups(result.lines||[],{statusLabel:"Đã bàn giao",statusTone:"Success"})}</div>`;
  return appShell({title:"Kết quả trả nhà cung cấp",body,centered:false,back:false,actions:primaryFooter("Về hàng chờ trả",'data-io07-action="result-to-rtv-queue"')});
}

// ============================================================================
// v1.7.0 — Correction & Recovery Product correction (UIF-11/UIF-16/UIF-17)
// Product UI exposes business facts, decisions and authoritative finality only.
// Technical identifiers/replay/rebuild/hash/polling remain contracts/Inspect concerns.
// ============================================================================
let cr11Filter="ALL";
let cr11Query="";
let cr11SelectedId="IO-260901-014";
let cr11Strategy="DELTA";
let cr11CorrectQty=118;
let cr11CorrectionReason="Ghi nhận thừa 2 hộp khi nhận hàng";
let cr11CancelReason="";
let cr11ApprovalRejectOpen=false;
let cr11ApprovalRejectReason="";
const cr11Operations=[
  {id:"IO-260906-022",type:"Thay đổi tình trạng hàng",source:"ST-260906-04",status:"READY",statusLabel:"Có thể hủy",route:"CANCEL",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:12,uom:"hộp",impact:"Chưa phát sinh thay đổi tồn kho"},
  {id:"IO-260901-014",type:"Nhận hàng",source:"PN-260901-07",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Nobivac DHPPi · Lô DH2507",qty:120,uom:"hộp",correctQty:118,impact:"Đã tăng tồn 120 hộp"},
  {id:"IO-260906-031",type:"Tiêu hủy",source:"DSP-260906-02",status:"UNKNOWN",statusLabel:"Đang xác minh",route:"UNKNOWN",warehouse:"Kho trung tâm",product:"Vitamin C · Lô L2310-C",qty:5,uom:"hộp",impact:"Chưa thể kết luận tác động tồn kho"},
  {id:"IO-260902-005",type:"Xuất bán",source:"SO-260902-19",status:"COMPLETED",statusLabel:"Cần xử lý đúng luồng",route:"PHYSICAL_RETURN_BLOCKED",warehouse:"Kho trung tâm",product:"Oxytetracycline LA",qty:3,uom:"chai",impact:"Hàng đã bàn giao thực tế cho khách"}
];
function cr11Current(){return cr11Operations.find(x=>x.id===cr11SelectedId)||cr11Operations[1];}
function cr11StateFor(op){if(op.route==="CANCEL")return "CANCELABLE";if(op.route==="UNKNOWN")return "UNKNOWN";if(op.route==="PHYSICAL_RETURN_BLOCKED")return "BLOCKED_PHYSICAL_HANDOVER";return "CORRECTABLE";}
function crChoice(name,value,label,detail,checked,attr){return `<label class="cr-choice" data-ds-component="VRadio"><input type="radio" name="${name}" value="${value}" ${attr} ${checked?'checked':''}><span><strong data-ds-component="VText">${label}</strong><small data-ds-component="VText" data-ds-prop-variant="VTextVariant.bodySmall">${detail}</small></span></label>`;}
function crFactCard(title,rows,badge="",tone="info"){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-fact-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,VBadge,DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong data-ds-component="VText">${title}</strong>${badge?vBadge(badge,tone):""}</div><div class="review-card-body">${rows.map(r=>ioMetaRow(r[0],r[1],!!r[2])).join("")}</div></section>`;}
function crTextAction(label,attr){return `<button type="button" class="button button--secondary button--full" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary">${label}</button>`;}
function crSwitchFlow(flowId,screenId,state){activeFlowId=flowId;activeScreenId=screenId;if(state&&stateByScreen[screenId]!==undefined)stateByScreen[screenId]=state;syncReviewUrl();render();}
function cr11ListRows(){
  const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
  const rows=cr11Operations.filter(op=>cr11Filter==="ALL"||op.route===cr11Filter).filter(op=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`));
  const list=rows.map(op=>ioProductRow({name:op.type,code:`${op.id} · ${op.source}`,primary:`${op.qty} ${op.uom}`,secondary:op.product,badge:op.statusLabel,badgeStatus:op.route==="UNKNOWN"?"warning":op.route==="PHYSICAL_RETURN_BLOCKED"?"warning":"info",attr:`data-cr11-operation="${op.id}"`})).join("");
  return `${ioSearchBar("Tìm mã nghiệp vụ, chứng từ hoặc hàng",'data-cr11-search',cr11Query)}${ac321CanonicalChips(cr11Filter,Object.entries(labels),'data-cr11-filter')}${list?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list">${list}</div></div>`:ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}
function render048CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-048"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm soát nghiệp vụ kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Kiểm soát nghiệp vụ kho",body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title:"Kiểm soát nghiệp vụ kho",body:ioEmpty("Chưa có nghiệp vụ cần kiểm soát","Các nghiệp vụ đủ điều kiện sẽ xuất hiện tại đây."),back:false});
  return appShell({title:"Kiểm soát nghiệp vụ kho",body:cr11ListRows(),back:false});
}
function render049CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-049"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết nghiệp vụ kho",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết nghiệp vụ kho",body:loadingBody()});
  const op=cr11Current();const routeState=state==="READY"?cr11StateFor(op):state;
  const context=crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Chứng từ nguồn",op.source],["Kho",op.warehouse],["Hàng",op.product],["Số lượng",`${op.qty} ${op.uom}`],["Tác động",op.impact]],op.statusLabel,routeState==="UNKNOWN"?"warning":"info");
  if(routeState==="UNKNOWN")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Kết quả chưa xác định","Chưa được hủy, đảo hoặc tạo sửa sai cho tới khi kết quả của đúng lần xử lý này được xác lập.")}${context}`,actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"')});
  if(routeState==="BLOCKED_PHYSICAL_HANDOVER")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Không sửa bằng cách đưa hàng về kho","Hàng đã được bàn giao thực tế. Nếu khách trả hàng, phải ghi nhận đúng nghiệp vụ Hàng khách trả; sửa sai không thay thế việc nhận hàng thực tế.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')});
  if(routeState==="TERMINAL")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("info","Không còn tác động để đảo","Nghiệp vụ đã bị hủy hoặc từ chối trước khi thực thi. Không có thay đổi tồn kho cần sửa.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')});
  if(routeState==="CANCELABLE")return appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}<p class="cr-footnote" data-ds-component="VText">Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.</p>`,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="open-cancel"',false,"danger")});
  return appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}${ioSectionTitle("Dấu vết liên quan")}${crFactCard("Nghiệp vụ gốc",[["Ngày nghiệp vụ","01/09/2026"],["Trạng thái","Đã hoàn tất"],["Sửa sai trước đó","Không"]])}`,actions:primaryFooter("Sửa sai",'data-cr11-action="open-correction"')});
}
function render052CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-052"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kiểm soát nghiệp vụ",body:deniedBody(),centered:true});
  const op=cr11Current();
  if(state==="DEPENDENCY_BLOCKED")return appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa thể sửa sai","Có nghiệp vụ phía sau đang phụ thuộc. Hãy xử lý nghiệp vụ đó trước.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Hàng",op.product],["Tác động hiện tại",op.impact]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')});
  if(state==="PERIOD_POLICY_VIOLATION")return appShell({title:"Chọn cách sửa",body:`${vBanner("warning","Chưa có kỳ mở để ghi nhận sửa sai","Cần có kỳ ghi nhận hiện hành hợp lệ trước khi tiếp tục.")}${crFactCard(op.id,[["Ngày nghiệp vụ gốc","01/09/2026"],["Kỳ gốc","Đã khóa"]])}`,actions:primaryFooter("Về chi tiết",'data-cr11-action="back-detail"')});
  const cancelMode=state==="CANCEL_UNEXECUTED"||op.route==="CANCEL";
  if(cancelMode){
    const err=state==="VALIDATION_ERROR"&&!cr11CancelReason.trim()?vBanner("error","Cần nhập lý do hủy","Lý do giúp truy vết vì sao yêu cầu dừng trước khi thực thi."):"";
    const body=`${err}${vBanner("info","Hủy trước khi thực thi","Nghiệp vụ sẽ chuyển sang Đã hủy; tồn kho và giá trị không thay đổi.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Chứng từ nguồn",op.source],["Tác động tồn kho","Không thay đổi"]])}${icTextarea("Lý do hủy",cr11CancelReason,'data-cr11-cancel-reason','Nhập lý do hủy')}`;
    return appShell({title:"Hủy yêu cầu kho",body,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="confirm-cancel"',!cr11CancelReason.trim(),"danger")});
  }
  const body=`${vBanner("info","Nghiệp vụ gốc luôn được giữ nguyên","Hệ thống sẽ tạo một nghiệp vụ sửa sai có liên kết; không sửa hoặc xóa lịch sử đã hoàn tất.")}${crFactCard(op.id,[["Nghiệp vụ",op.type,true],["Đã ghi nhận",`${op.qty} ${op.uom}`],["Kỳ gốc","Đã khóa · tác động sửa sai ghi ở kỳ mở hiện hành"]])}${ioSectionTitle("Chọn cách sửa")}<div class="cr-choice-list">${crChoice("cr11-strategy","DELTA","Sửa phần sai","Dùng khi phần sai có thể điều chỉnh độc lập và vẫn giữ đúng ý nghĩa chứng từ.",cr11Strategy==="DELTA",'data-cr11-strategy')}${crChoice("cr11-strategy","FULL","Hoàn nguyên và ghi lại đúng","Dùng khi toàn bộ nghiệp vụ không còn đúng hoặc phải xác lập lại nguyên khối.",cr11Strategy==="FULL",'data-cr11-strategy')}</div>`;
  return appShell({title:"Chọn cách sửa",body,actions:primaryFooter("Tiếp tục",'data-cr11-action="edit-correction"')});
}
function render050CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-050"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Nội dung sửa sai",body:deniedBody(),centered:true});
  const op=cr11Current();const delta=Number(cr11CorrectQty)-Number(op.qty);
  const validation=state==="VALIDATION_ERROR"?vBanner("error","Kiểm tra nội dung sửa sai","Số đúng phải lớn hơn hoặc bằng 0 và cần có lý do."):state==="SOURCE_VERSION_STALE"?vBanner("warning","Nghiệp vụ nguồn đã thay đổi","Hãy quay lại chi tiết để đối chiếu dữ liệu hiện hành trước khi gửi."):state==="CONFLICT"?vBanner("warning","Đã có yêu cầu sửa sai khác","Không tạo yêu cầu sửa sai song song. Mở yêu cầu đang hoạt động để tiếp tục."):"";
  const body=`${validation}${crFactCard("Trước và sau",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="form-field" data-ds-component="VNumberField"><label>Số đúng <span class="required">*</span></label><div class="input-shell"><input type="number" min="0" inputmode="decimal" value="${cr11CorrectQty}" data-cr11-correct-qty></div></div>${crFactCard("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${icTextarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason','Mô tả ngắn điều đã sai và căn cứ sửa')}`;
  const disabled=Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()||state==="SOURCE_VERSION_STALE"||state==="CONFLICT";
  return appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',disabled)});
}
function render051CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-051"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt sửa sai",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt sửa sai",body:`${vBanner("warning","Bạn không thể tự duyệt yêu cầu này","Người lập và người duyệt phải độc lập theo chính sách kiểm soát.")}`,back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt sửa sai",body:vBanner("info","Yêu cầu đã có quyết định","Mở kết quả sửa sai để xem trạng thái hiện hành."),actions:primaryFooter("Xem kết quả",'data-cr11-action="approval-result"'),back:false});
  const op=cr11Operations[1];const delta=Number(cr11CorrectQty)-Number(op.qty);
  const rejectError=state==="VALIDATION_ERROR"&&cr11ApprovalRejectOpen&&!cr11ApprovalRejectReason.trim()?vBanner("error","Cần nhập lý do từ chối","Lý do được lưu cùng quyết định phê duyệt."):"";
  const sheet=cr11ApprovalRejectOpen?`<div class="sheet-backdrop"><section class="bottom-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối sửa sai</h3></div><div class="sheet-content">${rejectError}${icTextarea("Lý do từ chối",cr11ApprovalRejectReason,'data-cr11-approval-reason','Nhập lý do')}<div class="sheet-actions">${crTextAction("Đóng",'data-cr11-action="reject-close"')}<button class="button button--danger" type="button" data-cr11-action="reject-confirm" ${cr11ApprovalRejectReason.trim()?'':'disabled'}>Từ chối</button></div></div></section></div>`:"";
  const body=`${vBanner("info","Công việc phê duyệt độc lập","Quyết định chỉ duyệt phương án. Sau khi duyệt, hệ thống tự ghi nhận phần sửa sai nếu điều kiện vẫn hợp lệ.")}${crFactCard("Yêu cầu sửa sai",[["Nghiệp vụ gốc",op.id,true],["Người lập","Nguyễn An"],["Lý do",cr11CorrectionReason]])}${ioSectionTitle("Trước / sau")}${crFactCard("Số lượng",[["Trước",`${op.qty} ${op.uom}`],["Sau",`${cr11CorrectQty} ${op.uom}`],["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${sheet}`;
  const actions=`<div class="cr-two-actions">${crTextAction("Từ chối",'data-cr11-action="reject-open"')}<button class="button button--primary button--full" type="button" data-cr11-action="approve" data-ds-component="VButton">Duyệt</button></div>`;
  return appShell({title:"Duyệt sửa sai",body,actions,back:false});
}
function render053CR11(state){
  if(activeFlowId!=="UIF-11")return renderGeneric(screens.find(s=>s.id==="SCR-053"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả sửa sai",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả sửa sai",body:`${loadingBody()}${vBanner("info","Đang ghi nhận sửa sai","Hệ thống đang kiểm lại điều kiện và ghi nhận phần sửa sai theo quyết định đã duyệt.")}`,centered:true,back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Kết quả sửa sai",body:ioResult("Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc của mình. Người có quyền duyệt sẽ nhận một công việc riêng.",[["Nghiệp vụ gốc",cr11Current().id],["Tác động tồn kho","Chưa thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="CANCELLED")return appShell({title:"Kết quả kiểm soát",body:ioResult("Đã hủy yêu cầu","Yêu cầu dừng trước khi thực thi; không phát sinh biến động kho hoặc thay đổi giá trị tồn kho.",[["Nghiệp vụ",cr11Current().id],["Tồn kho","Không thay đổi"]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="REJECTED")return appShell({title:"Kết quả sửa sai",body:ioResult("Yêu cầu không được duyệt","Nghiệp vụ gốc được giữ nguyên và không có tác động tồn kho mới.",[["Nghiệp vụ gốc","IO-260901-014"],["Tồn kho","Không thay đổi"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  if(state==="UNKNOWN")return appShell({title:"Kết quả sửa sai",body:ioResult("Đang xác minh kết quả","Không tạo hoặc gửi lại yêu cầu sửa sai. Hệ thống đang xác minh đúng lần xử lý này.",[["Nghiệp vụ gốc","IO-260901-014"],["Kết quả","Chưa xác định"]],"warning"),actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"'),centered:true,back:false});
  if(state==="BLOCKED")return appShell({title:"Kết quả sửa sai",body:ioResult("Chưa thể ghi sửa sai","Điều kiện hiện hành không còn phù hợp. Nghiệp vụ gốc chưa bị thay đổi.",[["Nghiệp vụ gốc","IO-260901-014"],["Tác động mới","Không có"]],"warning"),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả sửa sai",body:ioResult("Đã hoàn tất sửa sai","Nghiệp vụ gốc được giữ nguyên; bản ghi sửa sai mới đã ghi phần điều chỉnh và liên kết đầy đủ.",[["Nghiệp vụ gốc","IO-260901-014"],["Bản ghi sửa sai","IO-260907-109"],["Điều chỉnh",`${Number(cr11CorrectQty)-120} hộp`]]),actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"'),centered:true,back:false});
}

let crControlQuery="";
let cr16Filter="ALL";
let cr17Filter="ALL";
let cr16SelectedId="REC-260907-03";
let cr17SelectedId="REC-UNKNOWN-01";
let cr17ResolutionMode="";
const cr16Cases=[
  {id:"REC-260907-03",title:"Số liệu hiển thị lệch sổ kho",scope:"Nobivac DHPPi · Lô DH2507",severity:"Cần xử lý",tone:"warning",route:"PROJECTION",owner:"Kiểm soát kho"},
  {id:"REC-260907-04",title:"Cần sửa nghiệp vụ nguồn",scope:"Amox 500 · Lô L2407-A",severity:"Đang chờ",tone:"info",route:"CORRECTION",owner:"Kiểm soát kho"},
  {id:"REC-260907-05",title:"Chênh lệch do thời điểm ghi nhận",scope:"Găng tay M",severity:"Có thể đóng",tone:"info",route:"NO_REAL",owner:"Kiểm soát kho"},
  {id:"REC-260907-06",title:"Cần kiểm tra toàn vẹn sổ kho",scope:"Kho trung tâm · SP-00606",severity:"Ưu tiên cao",tone:"warning",route:"LEDGER",owner:"Vận hành nền tảng"},
  {id:"REC-260907-07",title:"Thông tin chứng từ nguồn chưa khớp",scope:"PN-260906-12",severity:"Đang chờ",tone:"info",route:"SOURCE",owner:"Nghiệp vụ nguồn"}
];
const cr17Cases=[
  {id:"REC-UNKNOWN-01",operation:"IO-260906-031",title:"Có bằng chứng đã phát sinh tác động",scope:"Vitamin C · Lô L2310-C · 5 hộp",evidence:"COMMITTED",severity:"Ưu tiên cao",tone:"warning",owner:"Kiểm soát kho"},
  {id:"REC-UNKNOWN-02",operation:"IO-260906-044",title:"Chưa phát hiện tác động tồn kho",scope:"Amox 500 · Lô L2407-A · 2 hộp",evidence:"NO_COMMIT",severity:"Cần xử lý",tone:"info",owner:"Kiểm soát kho"},
  {id:"REC-UNKNOWN-03",operation:"IO-260906-052",title:"Chưa đủ bằng chứng kết luận",scope:"Kho trung tâm · 1 lần xử lý",evidence:"INSUFFICIENT",severity:"Cần chuyên sâu",tone:"warning",owner:"Vận hành nền tảng"}
];
function cr16Current(){return cr16Cases.find(x=>x.id===cr16SelectedId)||cr16Cases[0];}
function cr17Current(){return cr17Cases.find(x=>x.id===cr17SelectedId)||cr17Cases[0];}
function cr079StateFor16(c){return c.route==="PROJECTION"?"PROJECTION_MISMATCH":c.route==="CORRECTION"?"CORRECTION_REQUIRED":c.route==="NO_REAL"?"NO_REAL_DIFFERENCE":c.route==="LEDGER"?"LEDGER_INTEGRITY_RISK":"SOURCE_MISMATCH";}
function cr079StateFor17(c){return c.evidence==="COMMITTED"?"UNKNOWN_EVIDENCE":c.evidence==="NO_COMMIT"?"UNKNOWN_EVIDENCE":"INSUFFICIENT_EVIDENCE";}
function crCaseList(active){
  const is17=activeFlowId==="UIF-17";const cases=is17?cr17Cases:cr16Cases;const filter=is17?cr17Filter:cr16Filter;
  const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
  const filtered=cases.filter(c=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return ["SOURCE"].includes(c.route);if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter(c=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  const rows=filtered.map(c=>ioProductRow({name:c.title,code:is17?(c.operation||""):c.id,primary:is17?"":"",secondary:c.scope,badge:c.severity,badgeStatus:c.tone,attr:`data-cr-case="${c.id}"`})).join("");
  return `${ioSearchBar(is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ",'data-cr-control-search',crControlQuery)}${ac321CanonicalChips(filter,chipItems,is17?'data-cr17-filter':'data-cr16-filter')}${rows?`<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row,VBadge"><div class="io-product-list cr-case-list">${rows}</div></div>`:ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
}
function render078CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-078"),state);
  const title=activeFlowId==="UIF-17"?"Nghiệp vụ cần xác minh":"Đối soát sai lệch";
  if(state==="PERMISSION_DENIED")return appShell({title,body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title,body:loadingBody(),back:false});
  if(state==="EMPTY")return appShell({title,body:ioEmpty(activeFlowId==="UIF-17"?"Không có nghiệp vụ cần xác minh":"Không có hồ sơ đối soát","Danh sách sẽ cập nhật khi có tín hiệu cần kiểm tra."),back:false});
  return appShell({title,body:crCaseList(),back:false});
}
function cr16EvidenceRows(c){
  if(c.route==="PROJECTION")return [["Nguồn nghiệp vụ","118 hộp · đã xác nhận"],["Sổ kho","118 hộp · khớp nguồn"],["Số liệu hiển thị","116 hộp · lệch −2"]];
  if(c.route==="CORRECTION")return [["Nguồn nghiệp vụ","120 hộp"],["Sổ kho","120 hộp"],["Kiểm tra thực tế","118 hộp · cần sửa nghiệp vụ"]];
  if(c.route==="NO_REAL")return [["Nguồn nghiệp vụ","118 hộp"],["Sổ kho","118 hộp"],["Báo cáo tại thời điểm cũ","116 hộp · khác do mốc thời gian"]];
  if(c.route==="LEDGER")return [["Nguồn nghiệp vụ","Có chứng từ"],["Sổ kho","Có dấu hiệu không nhất quán"],["Số liệu hiển thị","Không dùng để dựng lại sổ kho"]];
  return [["Chứng từ nguồn","Chưa khớp dữ liệu kho"],["Sổ kho","Chưa kết luận"],["Trạng thái","Đang chờ nghiệp vụ nguồn xác minh"]];
}
function cr17EvidenceRows(c){
  if(c.evidence==="COMMITTED")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Đã tìm thấy đúng phạm vi"],["Nghiệp vụ nguồn","Vẫn đang chờ kết quả"]];
  if(c.evidence==="NO_COMMIT")return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa phát hiện"],["Tác động dở dang","Không phát hiện"]];
  return [["Yêu cầu","Đã được tiếp nhận"],["Tác động tồn kho","Chưa đủ bằng chứng"],["Bằng chứng còn thiếu","Kết quả ghi nhận cuối cùng"]];
}
function crEvidenceCard(rows){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-evidence" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-body">${rows.map(r=>`<div class="cr-evidence-row" ${calibrated?'data-ds-component="DS v2 / Info Row" data-figma-node="525:351"':''}><span data-ds-component="VText">${r[0]}</span><strong data-ds-component="VText">${r[1]}</strong></div>`).join("")}</div></section>`;}
function render079CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-079"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Bằng chứng & kết luận",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Bằng chứng & kết luận",body:loadingBody()});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();const actualState=state==="READY"?cr079StateFor17(c):state;let banner="",actions="";
    if(actualState==="INSUFFICIENT_EVIDENCE"){banner=vBanner("warning","Chưa đủ bằng chứng để kết luận","Nghiệp vụ vẫn ở trạng thái chưa xác định, phạm vi tiếp tục được bảo vệ và hồ sơ đã chuyển người có trách nhiệm xử lý.");actions=primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"');}
    else if(c.evidence==="COMMITTED"){banner=vBanner("info","Có bằng chứng nghiệp vụ đã hoàn tất","Tác động tồn kho đã tồn tại. Bước tiếp theo chỉ xác lập kết quả; không ghi lại tác động lần hai.");actions=primaryFooter("Xem phương án xác lập",'data-cr17-action="open-plan"');}
    else{banner=vBanner("info","Có bằng chứng chưa ghi nhận tác động","Không phát hiện tác động tồn kho hoặc phần tác động dở dang. Có thể tiếp tục đúng lần xử lý này, giữ nguyên định danh và nội dung đã xác nhận.");actions=primaryFooter("Xem phương án tiếp tục",'data-cr17-action="open-plan"');}
    const body=`${banner}${crFactCard("Phạm vi cần xác minh",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Người xử lý",c.owner]])}${ioSectionTitle("Bằng chứng")}${crEvidenceCard(cr17EvidenceRows(c))}`;
    return appShell({title:"Bằng chứng kết quả",body,actions});
  }
  const c=cr16Current();const actualState=state==="READY"?cr079StateFor16(c):state;let banner="",actions="";
  if(actualState==="PROJECTION_MISMATCH"){banner=vBanner("info","Sổ kho đúng, số liệu hiển thị sai","Chỉ dữ liệu dẫn xuất cần được khôi phục. Không thay đổi sổ kho hoặc nghiệp vụ nguồn.");actions=primaryFooter("Khôi phục số liệu hiển thị",'data-cr16-action="open-plan"');}
  else if(actualState==="CORRECTION_REQUIRED"){banner=vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn. Hệ thống không chỉnh số dư trực tiếp để làm cho số liệu khớp.");actions=primaryFooter("Mở yêu cầu sửa sai",'data-cr16-action="handoff-correction"');}
  else if(actualState==="NO_REAL_DIFFERENCE"){banner=vBanner("info","Không có sai lệch tồn kho thực","Khác biệt đến từ thời điểm lấy số liệu. Có thể rà soát để đóng hồ sơ.");actions=primaryFooter("Rà soát đóng hồ sơ",'data-cr16-action="review-close"');}
  else if(actualState==="LEDGER_INTEGRITY_RISK"){banner=vBanner("warning","Cần kiểm tra toàn vẹn sổ kho","Tạm dừng khôi phục tự động và sửa sai. Không dùng báo cáo hoặc chứng từ nguồn để dựng lại sổ kho.");actions=primaryFooter("Xem trạng thái chuyển xử lý",'data-cr16-action="show-escalated"');}
  else if(actualState==="SOURCE_MISMATCH"){banner=vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Hồ sơ được giữ mở. Phân hệ kho không tự sửa dữ liệu nguồn hoặc sổ kho.");}
  else if(actualState==="INSUFFICIENT_EVIDENCE"){banner=vBanner("warning","Chưa đủ bằng chứng kết luận","Giữ hồ sơ mở và tiếp tục thu thập bằng chứng; không khôi phục hoặc sửa sai khi chưa xác định nguyên nhân.");}
  const body=`${banner}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý",c.owner],["Bảo vệ phạm vi",c.route==="NO_REAL"?"Không cần khóa":"Đang áp dụng đúng phạm vi"]])}${ioSectionTitle("Đối chiếu")}${crEvidenceCard(cr16EvidenceRows(c))}`;
  return appShell({title:"Bằng chứng & kết luận",body,actions});
}
function render080CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-080"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Phương án xử lý",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Phương án xử lý",body:vBanner("warning","Phạm vi đang do hồ sơ khác bảo vệ","Không xử lý song song cùng phạm vi. Mở hồ sơ đang bảo vệ để tiếp tục.")});
  if(state==="CONFLICT")return appShell({title:"Phương án xử lý",body:vBanner("warning","Kết luận đã thay đổi","Bằng chứng mới làm thay đổi phương án. Quay lại bước bằng chứng để rà soát.")});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(c.evidence==="INSUFFICIENT"||state==="INSUFFICIENT_EVIDENCE")return appShell({title:"Phương án xử lý",body:`${vBanner("warning","Chưa có phương án xử lý an toàn","Giữ nguyên trạng thái chưa xác định và phạm vi được bảo vệ; hồ sơ đã chuyển người có trách nhiệm.")}${crFactCard("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Người xử lý",c.owner],["Định danh","Giữ nguyên"]])}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')});
    const committed=c.evidence==="COMMITTED";const title=committed?"Xác lập đã hoàn tất":"Tiếp tục lần xử lý này";
    const desc=committed?"Dùng tác động đã tồn tại để xác lập kết quả. Không ghi lại biến động kho, số dư hoặc tác động liên quan lần hai.":"Chỉ tiếp tục sau khi đã chứng minh chưa có tác động bán phần. Giữ nguyên nghiệp vụ và nội dung đã xác nhận.";
    const body=`${vBanner("info",title,desc)}${crFactCard("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Định danh","Giữ nguyên"]])}${crFactCard("Sẽ không thực hiện",[["Tạo nghiệp vụ mới","Không"],["Tự hoàn nguyên","Không"],["Thay đổi nội dung đã xác nhận","Không"]])}`;
    return appShell({title:"Phương án xử lý",body,actions:primaryFooter(title,`data-cr17-action="execute-plan"`)});
  }
  const c=cr16Current();const body=`${vBanner("info","Khôi phục số liệu hiển thị","Bằng chứng đã xác nhận sổ kho đúng và dữ liệu hiển thị sai. Hệ thống chỉ khôi phục phần dữ liệu dẫn xuất trong phạm vi này.")}${crFactCard("Phạm vi",[["Hồ sơ",c.id,true],["Hàng",c.scope],["Bảo vệ phạm vi","Đang áp dụng"]])}${crFactCard("Tác động",[["Sổ kho","Không thay đổi"],["Nghiệp vụ nguồn","Không thay đổi"],["Số liệu hiển thị","Được khôi phục theo sổ kho đã xác nhận"]])}`;
  return appShell({title:"Phương án xử lý",body,actions:primaryFooter("Bắt đầu khôi phục",'data-cr16-action="start-recovery"')});
}
function render081CR(state){
  if(activeFlowId!=="UIF-16")return renderGeneric(screens.find(s=>s.id==="SCR-081"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Khôi phục số liệu",body:deniedBody(),centered:true});
  const c=cr16Current();
  if(state==="VALIDATION_FAILED"||state==="CONFLICT")return appShell({title:"Khôi phục số liệu",body:`${vBanner("warning","Chưa thể hoàn tất khôi phục","Bằng chứng hoặc phạm vi đã thay đổi. Hồ sơ vẫn được giữ mở và sổ kho không bị sửa.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"]])}`});
  if(state==="READY")return appShell({title:"Khôi phục số liệu",body:`${vBanner("success","Đã khôi phục số liệu hiển thị","Kết quả đã sẵn sàng để rà soát trước khi đóng hồ sơ và mở khóa.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"],["Số liệu hiển thị","Đã cập nhật"]])}`,actions:primaryFooter("Rà soát kết quả",'data-cr16-action="review-result"')});
  return appShell({title:"Đang khôi phục số liệu",body:`${loadingBody()}${vBanner("info","Hệ thống đang xử lý","Bạn có thể rời màn hình. Hồ sơ sẽ cập nhật khi dữ liệu hiển thị đã được khôi phục.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Sổ kho","Không thay đổi"]])}`});
}
function render082CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-082"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát kết quả",body:deniedBody(),centered:true});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();const committed=(cr17ResolutionMode||c.evidence)==="COMMITTED";const continued=(cr17ResolutionMode||"")==="CONTINUED";
    const rows=committed?[["Nghiệp vụ",c.operation,true],["Kết quả","Đã hoàn tất"],["Tác động tồn kho","Giữ nguyên tác động đã có"],["Định danh","Không thay đổi"]]:[["Nghiệp vụ",c.operation,true],["Kết quả",continued?"Đã hoàn tất":"Đã có kết quả mới"],["Định danh","Không thay đổi"],["Nghiệp vụ mới","Không tạo"]];
    const body=`${vBanner("info","Kết quả đã được xác lập","Hệ thống đã giữ đúng nghiệp vụ ban đầu và không tạo tác động trùng.")}${crFactCard("Rà soát kết quả cuối",rows)}`;
    return appShell({title:"Rà soát kết quả",body,actions:primaryFooter("Hoàn tất xác minh",'data-cr17-action="finish-review"')});
  }
  const c=cr16Current();
  if(state==="MISMATCH_REMAINS")return appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ. Không đóng hồ sơ cho tới khi có đủ bằng chứng xác nhận kết quả.")}${crFactCard(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`});
  const noReal=c.route==="NO_REAL";const body=`${vBanner("info",noReal?"Không có sai lệch thực":"Số liệu đã khớp",noReal?"Khác biệt trước đó được giải thích bằng mốc thời gian và đã có đủ bằng chứng để đóng hồ sơ.":"Kết quả hiển thị hiện khớp với sổ kho đã được xác nhận.")}${crFactCard(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","118 hộp"],["Chênh lệch","0 hộp",true],["Phạm vi",noReal?"Không khóa":"Sẵn sàng mở khóa"]])}`;
  return appShell({title:"Rà soát kết quả",body,actions:primaryFooter("Đóng hồ sơ & mở khóa",'data-cr16-action="close-case"')});
}
function render083CR(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId))return renderGeneric(screens.find(s=>s.id==="SCR-083"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả xử lý",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả xử lý",body:loadingBody(),centered:true,back:false});
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(state==="UNKNOWN"||state==="ESCALATED")return appShell({title:"Kết quả xác minh",body:ioResult("Chưa xác định — đã chuyển xử lý","Hệ thống chưa đoán kết quả. Phạm vi tiếp tục được bảo vệ và người có trách nhiệm đã nhận hồ sơ.",[["Nghiệp vụ",c.operation],["Người xử lý",c.owner],["Phạm vi","Tiếp tục được bảo vệ"]],"warning"),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false});
    return appShell({title:"Kết quả xác minh",body:ioResult("Đã xác lập kết quả nghiệp vụ","Kết quả chính thức đã được ghi cho đúng nghiệp vụ; không tạo nghiệp vụ mới hoặc ghi tác động trùng.",[["Nghiệp vụ",c.operation],["Định danh","Giữ nguyên"],["Trạng thái","Đã hoàn tất"]]),actions:primaryFooter("Về danh sách xác minh",'data-cr17-action="to-list"'),centered:true,back:false});
  }
  const c=cr16Current();
  if(state==="UNKNOWN"||state==="ESCALATED")return appShell({title:"Kết quả đối soát",body:ioResult("Đã chuyển xử lý chuyên sâu","Hồ sơ vẫn mở; phạm vi rủi ro tiếp tục được bảo vệ cho tới khi có bằng chứng mới.",[["Hồ sơ",c.id],["Người xử lý",c.owner],["Phạm vi","Chưa mở khóa"]],"warning"),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false});
  return appShell({title:"Kết quả đối soát",body:ioResult("Đã xử lý sai lệch","Hồ sơ được đóng bằng bằng chứng và phạm vi liên quan đã được mở khóa.",[["Hồ sơ",c.id],["Kết luận",c.route==="NO_REAL"?"Không có sai lệch thực":"Số liệu đã khớp"],["Phạm vi","Đã mở khóa"]]),actions:primaryFooter("Về danh sách đối soát",'data-cr16-action="to-list"'),centered:true,back:false});
}


// v1.8.0 — Control Foundation & Inquiry · BJ12 / UIF12 + BJ15 / UIF15
// Product UI keeps migration controls and read-only inquiry separate from architecture/recovery mechanics.
let cf12FileName = "ton-kho-dau-ky-2026.xlsx";
let cf12Cutoff = "2026-08-31";
let cf12ControlQty = "4820";
let cf12ControlValue = "386240000";
let cf12RejectOpen = false;
let cf12RejectReason = "";
const cf12Summary = { rows: 82, products: 36, parsedQty: 4820, parsedValue: 386240000, sellableRows: 74, nonSellableRows: 8 };
const cfMoney = (n) => `${Number(n || 0).toLocaleString("vi-VN")} ₫`;
const cfMoneyInput = (n) => n === "" || n == null ? "" : Number(String(n).replace(/[^0-9-]/g, "") || 0).toLocaleString("vi-VN");
const cfNumber = (n) => Number(n || 0).toLocaleString("vi-VN");
function cfDateVN(value){const v=String(value||"");const m=v.match(/^(\d{4})-(\d{2})-(\d{2})$/);return m?`${m[3]}/${m[2]}/${m[1]}`:v;}
function cfDateKey(value){const v=String(value||"");const m=v.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);return m?`${m[3]}-${m[2]}-${m[1]}`:v;}
function cfField(label,value,attr,type="text",hint=""){
  const isDate=type==="date", isMoney=type==="money", htmlType=(isDate||isMoney)?"text":type, shown=isDate?cfDateVN(value):isMoney?cfMoneyInput(value):value;
  const extra=isDate?' inputmode="numeric" placeholder="dd/mm/yyyy"':isMoney?' inputmode="numeric"':"";
  const component=isDate?"VDatePickerField":isMoney?"VMoneyField":type==="number"?"VNumberField":"VTextField";
  const figmaNode=isMoney?' data-figma-node="522:7322"':'';
  const stateAttr=isMoney?` data-ds-prop-state="${shown!==""?"Filled":"Default"}"`:"";
  const moneySuffix=isMoney?'<span class="money-suffix" aria-hidden="true">₫</span>':"";
  return `<div class="form-field cf-field" data-ds-component="${component}"${figmaNode}${stateAttr}><label>${label}</label><div class="input-shell"><input type="${htmlType}" value="${escapeAttribute(shown)}" ${attr}${extra}>${moneySuffix}</div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSelect(label,value,options,attr,hint=""){
  return `<div class="form-field cf-field" data-ds-component="VSelect"><label>${label}</label><div class="input-shell"><select ${attr}>${options.map(([v,l])=>`<option value="${escapeAttribute(v)}" ${String(v)===String(value)?"selected":""}>${l}</option>`).join("")}</select><span>${icon("chevronDown","icon--sm")}</span></div>${hint?`<small class="field-help">${hint}</small>`:""}</div>`;
}
function cfSummaryGrid(items){return `<div class="cf-summary-grid">${items.map(([l,v])=>`<div class="cf-summary-tile"><small>${l}</small><strong>${v}</strong></div>`).join("")}</div>`;}
function cfSecondary(label,attr,tone="neutral"){return `<button class="button button--secondary cf-secondary" type="button" ${attr} data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-size="VButtonSize.medium" data-ds-prop-tone="VComponentTone.${tone}">${label}</button>`;}
function cf12ReviewCard(){
  return `${crFactCard("Phạm vi khởi tạo",[["Kho","Kho trung tâm",true],["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Dòng dữ liệu",`${cfNumber(cf12Summary.rows)} dòng`]])}${crFactCard("Số kiểm soát",[["Tổng số lượng",cfNumber(cf12ControlQty),true],["Tổng giá trị",cfMoney(cf12ControlValue),true],["Đối chiếu tệp","Khớp số kiểm soát"]])}`;
}
function render066CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Khởi tạo tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="LOADING")return appShell({title:"Khởi tạo tồn kho",body:loadingBody(),back:false});
  if(state==="PREPARING")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chuẩn bị số dư đầu kỳ","Tệp và số kiểm soát đã được giữ lại. Tiếp tục rà soát dữ liệu trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Tiếp tục chuẩn bị",'data-cf12-action="continue-prepare"'),back:false});
  if(state==="PENDING_APPROVAL")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa được khởi tạo ở bước này.")}${cf12ReviewCard()}`,back:false});
  if(state==="REJECTED")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Cần sửa trước khi gửi lại","Người duyệt đã từ chối số dư đầu kỳ. Tồn kho chưa được khởi tạo.")}${crFactCard("Lý do",[["Nội dung","Đối chiếu lại số lượng của nhóm Vaccine",true],["Tác động tồn kho","Chưa có"]])}`,actions:primaryFooter("Sửa dữ liệu",'data-cf12-action="fix-rejected"'),back:false});
  if(state==="UNKNOWN")return appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Đang xác minh kết quả","Không tạo một lần khởi tạo khác. Hệ thống đang xác minh đúng lần xử lý hiện tại trước khi mở nghiệp vụ kho bình thường.")}${crFactCard("Trạng thái",[["Ngày chốt số dư",cfDateVN(cf12Cutoff),true],["Khởi tạo mới","Bị khóa cho đến khi có kết luận"]])}`,back:false});
  if(state==="ACTIVE_RECONCILED")return appShell({title:"Khởi tạo tồn kho",body:ioResult("Tồn kho đầu kỳ đã sẵn sàng","Số dư đầu kỳ đã được ghi nhận và đối chiếu. Nghiệp vụ kho bình thường có thể bắt đầu.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false});
  const body=`${crFactCard("Khởi tạo lần đầu",[["Kho","Kho trung tâm",true],["Trạng thái","Chưa thiết lập"],["Quy tắc","Chỉ có một số dư đầu kỳ chính thức"]])}<p class="io-footnote">Sau khi hoàn tất, mọi sửa sai phát sinh được xử lý bằng nghiệp vụ điều chỉnh có kiểm soát; không mở lại số dư đầu kỳ.</p>`;
  return appShell({title:"Khởi tạo tồn kho",body,actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false});
}
function render067CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:deniedBody(),centered:true});
  if(state==="LOCKED")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("info","Dữ liệu đang được xử lý","Tệp nguồn và số kiểm soát hiện chỉ đọc.")}${cf12ReviewCard()}`});
  if(state==="CONFLICT")return appShell({title:"Dữ liệu tồn kho đầu kỳ",body:`${vBanner("warning","Phạm vi vừa thay đổi","Không tiếp tục trên dữ liệu cũ. Tải lại thông tin hiện hành trước khi kiểm tra tệp.")}${cf12ReviewCard()}`});
  const invalid=state==="VALIDATION_ERROR";
  const body=`${invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Chọn tệp, ngày chốt và nhập cả tổng số lượng lẫn tổng giá trị độc lập trước khi kiểm tra."):""}<section class="review-card cf-file-card" data-ds-component="VFileDropZone"><div class="review-card-body"><div class="cf-file-icon">${icon("fileText")}</div><div class="cf-file-copy"><strong>Tệp số dư đầu kỳ</strong><small>${esc(cf12FileName||"Chưa chọn tệp")}</small></div>${cfSecondary("Chọn tệp",'data-cf12-action="choose-file"')}</div></section><div class="form-stack">${cfField("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff','date','Dùng đúng ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.')}${cfField("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty','number','Nhập từ nguồn kiểm soát độc lập với tệp chi tiết.')}${cfField("Tổng giá trị kiểm soát",cf12ControlValue,'data-cf12-control-value','money','Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.')}</div>`;
  const disabled=!cf12FileName||!cf12Cutoff||!(Number(cf12ControlQty)>=0)||!(Number(cf12ControlValue)>=0);
  return appShell({title:"Dữ liệu tồn kho đầu kỳ",body,actions:primaryFooter("Kiểm tra dữ liệu",'data-cf12-action="check"',disabled)});
}
function render068CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả kiểm tra dữ liệu",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Kết quả kiểm tra dữ liệu",body:loadingBody()});
  if(state==="CONFLICT")return appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("warning","Nguồn dữ liệu đã thay đổi","Kết quả kiểm tra cũ không còn hiệu lực. Chọn lại tệp hoặc tải lại phạm vi.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  if(state==="VALIDATION_FAILED"){
    const body=`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa các dòng lỗi trong nguồn rồi kiểm tra lại.")}${cfSummaryGrid([["Dòng đọc được",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Lỗi cần sửa","3"]])}${crFactCard("Dòng 18 · Vaccine Newcastle",[["Vấn đề","Chưa xác định sản phẩm trong VET45",true],["Cách xử lý","Sửa dữ liệu nguồn; không tạo sản phẩm trong luồng này"]])}${crFactCard("Dòng 44 · Amox 500",[["Vấn đề","Trùng cùng sản phẩm + kho + tình trạng + lô",true],["Cách xử lý","Giữ một dòng dữ liệu chính thức; không tự cộng gộp"]])}${crFactCard("Dòng 61 · Nobivac DHPPi",[["Vấn đề","Thiếu hạn dùng bắt buộc của lô",true],["Cách xử lý","Bổ sung hạn dùng đúng theo nhãn lô"]])}`;
    return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')});
  }
  if(state==="CONTROL_TOTAL_MISMATCH"){
    const body=`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi số trong tệp khớp nguồn kiểm soát độc lập.")}${crFactCard("Đối chiếu số lượng",[["Theo tệp",cfNumber(cf12Summary.parsedQty),true],["Số kiểm soát",cfNumber(Number(cf12ControlQty)+12),true],["Chênh lệch","−12"]])}${crFactCard("Đối chiếu giá trị",[["Theo tệp",cfMoney(cf12Summary.parsedValue),true],["Số kiểm soát",cfMoney(cf12ControlValue),true]])}`;
    return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  }
  const body=`${vBanner("success","Dữ liệu đã qua kiểm tra","Tệp chi tiết khớp số kiểm soát và không còn blocker dữ liệu trong phạm vi này.")}${cfSummaryGrid([["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)]])}${crFactCard("Kiểm tra chính",[["Số âm","Không có"],["Dòng trùng khóa nghiệp vụ","Không có"],["Lô / hạn dùng","Hợp lệ"],["Số kiểm soát","Đã khớp",true]])}`;
  return appShell({title:"Kết quả kiểm tra dữ liệu",body,actions:primaryFooter("Rà soát số dư",'data-cf12-action="review"')});
}
function render069CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát số dư đầu kỳ",body:deniedBody(),centered:true});
  if(state==="CONFLICT")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("warning","Dữ liệu vừa thay đổi","Quay lại kiểm tra nguồn hiện hành trước khi gửi phê duyệt.")}${cf12ReviewCard()}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')});
  if(state==="VALIDATION_ERROR")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("error","Chưa thể gửi phê duyệt","Dữ liệu không còn thỏa điều kiện đã kiểm tra. Quay lại bước kiểm tra.")}${cf12ReviewCard()}`,actions:primaryFooter("Kiểm tra lại",'data-cf12-action="back-check"')});
  if(state==="PENDING_APPROVAL")return appShell({title:"Rà soát số dư đầu kỳ",body:`${vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần việc chuẩn bị. Tồn kho chưa thay đổi.")}${cf12ReviewCard()}`});
  const body=`${cf12ReviewCard()}${crFactCard("Phân bố dữ liệu",[["Bán được",`${cfNumber(cf12Summary.sellableRows)} dòng`,true],["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng`],["Lô / hạn dùng","Giữ theo dữ liệu sản phẩm"]])}`;
  return appShell({title:"Rà soát số dư đầu kỳ",body,actions:primaryFooter("Gửi phê duyệt",'data-cf12-action="send-approval"')});
}
function cf12ApprovalFooter(){return `<div class="ic-action-stack cf12-approval-actions">${cfSecondary("Từ chối",'data-cf12-action="open-reject"',"danger")}${primaryFooter("Duyệt",'data-cf12-action="approve"')}</div>`;}
function cf12RejectSheet(){
  if(!cf12RejectOpen)return "";
  return `<div class="sheet-backdrop" data-cf12-action="close-reject"><section class="bottom-sheet cf12-reject-sheet" role="dialog" aria-modal="true" aria-label="Từ chối số dư đầu kỳ" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối số dư đầu kỳ</h3></div><div class="sheet-divider"></div><div class="sheet-content">${icTextarea("Lý do từ chối",cf12RejectReason,'data-cf12-reject-reason','Nhập nội dung người lập cần sửa')}<div class="sheet-actions">${cfSecondary("Hủy",'data-cf12-action="close-reject"')}<button class="button button--primary" type="button" data-cf12-action="confirm-reject" data-ds-component="VButton" ${cf12RejectReason.trim()?"":"disabled"}>Xác nhận từ chối</button></div></div></section></div>`;
}
function render070CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Duyệt số dư đầu kỳ",body:deniedBody(),centered:true,back:false});
  if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("warning","Không thể tự duyệt","Người chuẩn bị số dư đầu kỳ không được đồng thời là người quyết định.")}${cf12ReviewCard()}`,back:false});
  if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("info","Công việc đã có quyết định","Quyết định hợp lệ đầu tiên có hiệu lực. Màn này chỉ còn để xem bằng chứng đã dùng.")}${cf12ReviewCard()}`,back:false});
  if(state==="VALIDATION_ERROR")return appShell({title:"Duyệt số dư đầu kỳ",body:`${vBanner("error","Không thể quyết định","Dữ liệu nền không còn hợp lệ. Không ghi nhận số dư từ bằng chứng đã thay đổi.")}${cf12ReviewCard()}`,back:false});
  const body=`${vBanner("info","Kiểm tra trước khi duyệt","Đối chiếu ngày chốt, số kiểm soát và phạm vi. Nếu duyệt, hệ thống sẽ ghi nhận số dư sau khi kiểm tra lại điều kiện.")}${crFactCard("Người chuẩn bị",[["Người lập","Nguyễn An",true],["Ngày gửi","07/09/2026 · 10:32"]])}${cf12ReviewCard()}${cf12RejectSheet()}`;
  return appShell({title:"Duyệt số dư đầu kỳ",body,actions:cf12ApprovalFooter(),back:false});
}
function render071CF12(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả khởi tạo tồn kho",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả khởi tạo tồn kho",body:`${loadingBody()}${vBanner("info","Đang ghi nhận và đối soát","Hệ thống đang xử lý số dư được duyệt. Không cần thực hiện thêm thao tác.")}`,centered:true,back:false});
  if(state==="UNKNOWN"||state==="COMMIT_UNKNOWN")return appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Đang xác minh kết quả","Chưa thể kết luận lần khởi tạo đã được ghi nhận hay chưa. Không tạo lần mới hoặc nhập lại số dư.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Khởi tạo mới","Đang bị khóa"]],"warning"),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả khởi tạo tồn kho",body:ioResult("Chưa khởi tạo tồn kho","Yêu cầu không được thực hiện. Không có số dư đầu kỳ nào được ghi nhận.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Tác động tồn kho","Không có"]],"warning"),actions:primaryFooter("Về trạng thái khởi tạo",'data-cf12-action="result-home"'),centered:true,back:false});
  const body=ioResult("Đã khởi tạo tồn kho đầu kỳ","Số dư đã được ghi nhận nguyên khối và đối soát thành công. Mọi sửa sai tiếp theo đi qua nghiệp vụ điều chỉnh có kiểm soát.",[["Ngày chốt số dư",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Tổng giá trị",cfMoney(cf12Summary.parsedValue)],["Đối soát","Đã khớp"]]);
  return appShell({title:"Kết quả khởi tạo tồn kho",body,actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false});
}

let cf15ReportType = "INVENTORY";
let cf15DateMode = "BUSINESS";
let cf15Warehouse = "MAIN";
let cf15Product = "ALL";
let cf15From = "2026-09-01";
let cf15To = "2026-09-07";
let cf15SelectedProduct = "P-NOB";
let cf15SelectedMovement = "M-RECEIPT";
let cf15ProductSheetOpen = false;
let cf15ExportFrom = "REPORT";
let cf15FinanceIncluded = true;
const cf15Products = [
 {id:"P-NOB",name:"Nobivac DHPPi",code:"SP-00418",qty:118,uom:"hộp",available:106,value:10030000,tracking:"LOT",lots:[{lot:"N2407-01",qty:70,state:"Bán được"},{lot:"N2408-02",qty:36,state:"Bán được"},{lot:"N2407-Q",qty:12,state:"Cách ly"}]},
 {id:"P-AMX",name:"Amox 500",code:"SP-00128",qty:24,uom:"hộp",available:18,value:3480000,tracking:"LOT",lots:[{lot:"L2407-A",qty:18,state:"Bán được"},{lot:"L2407-Q",qty:6,state:"Cách ly"}]},
 {id:"P-GLV",name:"Găng tay M",code:"SP-00602",qty:34,uom:"hộp",available:34,value:2550000,tracking:"NONE",lots:[]}
];
const cf15Movements = [
 {id:"M-RECEIPT",time:"07/09/2026 · 09:14",business:"07/09/2026",recorded:"07/09/2026 · 09:16",label:"Nhận hàng",source:"Phiếu nhận PN-260907-04",delta:20,before:98,after:118,uom:"hộp",lot:"N2408-02",state:"Bán được",actor:"Nguyễn An",value:1700000},
 {id:"M-SALE",time:"06/09/2026 · 15:40",business:"06/09/2026",recorded:"06/09/2026 · 15:42",label:"Bán hàng",source:"Đơn bán DH-260906-118",delta:-4,before:102,after:98,uom:"hộp",lot:"N2407-01",state:"Bán được",actor:"Trần Minh",value:-340000},
 {id:"M-STATUS",time:"05/09/2026 · 10:05",business:"05/09/2026",recorded:"05/09/2026 · 10:05",label:"Chuyển tình trạng",source:"Yêu cầu trạng thái TT-260905-03",delta:0,before:102,after:102,uom:"hộp",lot:"N2407-Q",state:"Cách ly",actor:"Lê Hoa",value:0}
];
function cf15ProductById(id){return cf15Products.find(x=>x.id===id)||cf15Products[0];}
function cf15Movement(){return cf15Movements.find(x=>x.id===cf15SelectedMovement)||cf15Movements[0];}
function cf15DateLabel(mode=cf15DateMode){return mode==="RECORDED"?"Ngày ghi nhận":"Ngày nghiệp vụ";}
function cf15Segmented(value,items,attr){return `<div class="cf-segmented" data-ds-component="VSegmentedControl">${items.map(([v,l])=>`<button type="button" class="cf-segment ${value===v?"is-selected":""}" ${attr}="${v}" data-ds-component="VSegmentedControlItem">${l}</button>`).join("")}</div>`;}
function render054CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-054"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Tra cứu kho",body:deniedBody(),centered:true,back:false});
  if(state==="CONFLICT")return appShell({title:"Tra cứu kho",body:vBanner("warning","Phạm vi vừa thay đổi","Tải lại phạm vi tra cứu trước khi xem báo cáo."),back:false});
  const invalid=state==="VALIDATION_ERROR";
  const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map(x=>[x.id,`${x.name} · ${x.code}`])];
  const body=`${invalid?vBanner("error","Chưa đủ điều kiện tra cứu",cf15ReportType==="STOCK_CARD"?"Chọn một sản phẩm cụ thể để xem thẻ kho.":"Kiểm tra lại phạm vi và kỳ báo cáo."):""}${ioSectionTitle("Loại tra cứu")}${cf15Segmented(cf15ReportType,[["INVENTORY","Tồn kho"],["STOCK_CARD","Thẻ kho"]],"data-cf15-report-type")}${ioSectionTitle("Phạm vi")}<div class="form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","Nếu tổ chức chỉ có một kho hợp lệ, hệ thống giữ sẵn kho đó.")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"Có thể để tất cả khi xem báo cáo tồn.")}</div>${ioSectionTitle("Cách hiểu thời gian")}${cf15Segmented(cf15DateMode,[["BUSINESS","Ngày nghiệp vụ"],["RECORDED","Ngày ghi nhận"]],"data-cf15-date-mode")}<p class="io-footnote">Hai mốc thời gian có ý nghĩa khác nhau và không được trộn âm thầm trong cùng một kết quả.</p><div class="form-stack cf-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
  return appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false});
}
function cf15ContextBanner(state,mode){
  const stale=state==="STALE"?vBanner("warning","Dữ liệu đang cập nhật","Dùng mốc dữ liệu bên dưới; không sửa tồn kho từ số liệu chưa cập nhật."):"";
  return `${stale}<div class="cf-context-row"><span>${cf15DateLabel(mode)} · ${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}</span><strong>Đến 07/09/2026 · 11:00</strong></div>`;
}
function cf15ProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen)return "";
  const stateRows=[...new Set(product.lots.map(x=>x.state))].map(st=>[st,`${cfNumber(product.lots.filter(x=>x.state===st).reduce((a,x)=>a+x.qty,0))} ${product.uom}`]);
  const lotBlock=product.tracking==="LOT"?`${ioSectionTitle("Theo lô")}<div class="cf-sheet-list">${product.lots.map(x=>ioMetaRow(`Lô ${x.lot}`,`${cfNumber(x.qty)} ${product.uom} · ${x.state}`,true)).join("")}</div>`:"";
  const stateBlock=stateRows.length?`${ioSectionTitle("Theo tình trạng")}<div class="cf-sheet-list">${stateRows.map(r=>ioMetaRow(r[0],r[1],true)).join("")}</div>`:"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet cf15-sheet" role="dialog" aria-modal="true" aria-label="Chi tiết ${product.name}" onclick="event.stopPropagation()" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="sheet-handle"></div><div class="sheet-title"><h3>${product.name}</h3><small>${product.code}</small></div><div class="sheet-divider"></div><div class="sheet-content">${crFactCard("Số lượng",[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])])}${stateBlock}${lotBlock}${product.tracking!=="LOT"?'<p class="io-footnote">Sản phẩm không quản lý theo lô; báo cáo không tạo một “lô mặc định” giả.</p>':""}<div class="sheet-actions">${cfSecondary("Đóng",'data-cf15-action="close-product-sheet"')}<button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}" data-ds-component="VButton">Xem thẻ kho</button></div></div></section></div>`;
}
function cf15InventoryResult(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const rows=cf15Products.map(p=>ioProductRow({name:p.name,code:p.code,primary:`${cfNumber(p.qty)} ${p.uom}`,secondary:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,attr:`data-cf15-product-row="${p.id}"`})).join("");
  const totalValue=cf15Products.reduce((a,x)=>a+x.value,0);
  return `${cf15ContextBanner(state,mode)}${cfSummaryGrid([["Sản phẩm",cf15Products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ioSectionTitle("Sản phẩm")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${rows}</div></div><p class="io-footnote">Không cộng các số lượng khác đơn vị thành một tổng giả.</p><div class="cf-inline-actions">${cfSecondary("Xuất báo cáo",'data-cf15-action="export"')}</div>${cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
}
function cf15StockCardResult(state,mode){
  const financeAllowed=state!=="FINANCIAL_RESTRICTED"; const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
  const movRows=cf15Movements.map(m=>`<button class="cf-movement-row" type="button" data-cf15-movement="${m.id}" data-ds-component="DS v2 / List Row" data-figma-node="525:519" data-ds-prop-type="Navigation" data-ds-prop-density="Default" data-ds-prop-state="Default"><span><strong>${m.label}</strong><small>${mode==="RECORDED"?m.recorded:m.business} · ${m.source}</small></span><span class="cf-movement-values"><strong>${m.delta>0?"+":""}${m.delta} ${m.uom}</strong><small>Còn ${m.after} ${m.uom}</small></span>${navChevron()}</button>`).join("");
  return `${cf15ContextBanner(state,mode)}${crFactCard(p.name,[["Mã",p.code,true],["Tồn hiện tại",`${cfNumber(p.qty)} ${p.uom}`],["Khả dụng bán",`${cfNumber(p.available)} ${p.uom}`],...(financeAllowed?[["Giá trị tồn",cfMoney(p.value)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ trong phạm vi quyền.")}${ioSectionTitle("Biến động")}<div class="cf-movement-list">${movRows}</div><div class="cf-inline-actions">${cfSecondary("Xuất thẻ kho",'data-cf15-action="export"')}</div>`;
}
function render055CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-055"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả tra cứu",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Kết quả tra cứu",body:loadingBody()});
  if(state==="EMPTY"||state==="FILTER_EMPTY")return appShell({title:"Kết quả tra cứu",body:ioEmpty(state==="FILTER_EMPTY"?"Không có dữ liệu phù hợp":"Chưa có dữ liệu tồn kho","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")});
  const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
  const body=cf15ReportType==="STOCK_CARD"?cf15StockCardResult(state,mode):cf15InventoryResult(state,mode);
  return appShell({title:cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body});
}
function render056CF15(state){
  if(activeFlowId!=="UIF-15")return render056IC09(state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Chi tiết biến động",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Chi tiết biến động",body:loadingBody()});
  if(state==="CONFLICT")return appShell({title:"Chi tiết biến động",body:vBanner("warning","Nguồn nghiệp vụ vừa thay đổi","Tải lại dữ liệu trước khi dựa vào chi tiết đang xem.")});
  const m=cf15Movement(); const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const body=`${crFactCard(m.label,[["Nguồn",m.source,true],["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${crFactCard("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",`${m.delta>0?"+":""}${m.delta} ${m.uom}`,true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?crFactCard("Giá trị",[["Tác động",cfMoney(m.value),true],["Nguồn giá","Giá trị chính thức của giao dịch"]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn có thể truy vết nguồn và số lượng nhưng không xem giá trị.")}${cfSecondary("Xem nguồn",'data-cf15-action="source"')}`;
  return appShell({title:"Chi tiết biến động",body});
}
function render057CF15(state){
  if(activeFlowId!=="UIF-15")return renderGeneric(screens.find(s=>s.id==="SCR-057"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Nguồn nghiệp vụ",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Nguồn nghiệp vụ",body:loadingBody()});
  if(state==="EMPTY")return appShell({title:"Nguồn nghiệp vụ",body:ioEmpty("Chưa có bằng chứng nguồn","Không có chuỗi nguồn phù hợp với biến động đang xem.")});
  const m=cf15Movement(); const stale=state==="STALE"?vBanner("warning","Dữ liệu nguồn đang cập nhật","Giữ mốc hiển thị hiện tại; không dùng dữ liệu chưa cập nhật làm căn cứ để thay đổi tồn kho."):"";
  const body=`${stale}${crFactCard("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",`${m.delta>0?"+":""}${m.delta} ${m.uom}`]])}${ioSectionTitle("Dòng thời gian nghiệp vụ")}<div class="timeline cf-business-timeline"><div class="timeline-card"><strong>${m.source}</strong><small>Giao dịch nguồn được hoàn tất</small></div><div class="timeline-card"><strong>Đã ghi nhận kho</strong><small>${m.recorded}</small></div><div class="timeline-card"><strong>${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}</strong><small>Số dư sau biến động: ${m.after} ${m.uom}</small></div></div><div class="cf-inline-actions">${cfSecondary("Xuất bằng chứng",'data-cf15-action="export-source"')}</div>`;
  return appShell({title:"Nguồn nghiệp vụ",body});
}
function render058CF15(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Xuất báo cáo",body:deniedBody(),centered:true,back:false});
  if(state==="EXPORT_RUNNING")return appShell({title:"Xuất báo cáo",body:loadingBody(),centered:true,back:false});
  if(state==="VALIDATION_ERROR")return appShell({title:"Xuất báo cáo",body:vBanner("error","Chưa thể xuất","Phạm vi hoặc mốc dữ liệu không còn hợp lệ. Quay lại kết quả tra cứu để kiểm tra."),backAction:"cf15-back-export"});
  if(state==="STALE")return appShell({title:"Xuất báo cáo",body:`${vBanner("warning","Kết quả đang cập nhật","Không xuất một file được hiểu nhầm là số liệu mới hơn mốc đang hiển thị.")}${crFactCard("Mốc dữ liệu",[["Đến","07/09/2026 · 11:00",true],["Cách hiểu thời gian",cf15DateLabel()]])}`,backAction:"cf15-back-export"});
  const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
  const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ cùng phạm vi, quyền và mốc dữ liệu với kết quả đang xem.</p>`;
  return appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"});
}
function render059CF15(state){
  if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả xuất báo cáo",body:deniedBody(),centered:true,back:false});
  if(state==="PROCESSING")return appShell({title:"Kết quả xuất báo cáo",body:loadingBody(),centered:true,back:false});
  if(state==="SOURCE_STALE")return appShell({title:"Kết quả xuất báo cáo",body:ioResult("Nguồn dữ liệu đã thay đổi","Không tạo tệp từ kết quả chưa cập nhật. Quay lại báo cáo và tải mốc hiện hành trước khi xuất lại.",[["Tệp","Chưa tạo"],["Dữ liệu","Không bị thay đổi"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false});
  if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả xuất báo cáo",body:ioResult("Chưa tạo được tệp","Chưa tạo được tệp nhưng dữ liệu tồn kho không thay đổi.",[["Dữ liệu kho","Không thay đổi"],["Có thể thử lại","Từ cùng báo cáo hiện hành"]],"warning"),actions:primaryFooter("Quay lại báo cáo",'data-cf15-action="done-export"'),centered:true,back:false});
  const filename=cf15ExportFrom==="SOURCE"?"bang-chung-bien-dong-07092026.csv":cf15ReportType==="STOCK_CARD"?"the-kho-07092026.csv":"bao-cao-ton-kho-07092026.csv";
  const body=ioResult("Đã tạo tệp báo cáo","Tệp giữ đúng phạm vi, quyền và mốc dữ liệu của kết quả đã xem.",[["Tệp",filename],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]]);
  return appShell({title:"Kết quả xuất báo cáo",body,actions:primaryFooter("Xong",'data-cf15-action="done-export"'),centered:true,back:false});
}

const renderers = {"SCR-048":render048CR11,"SCR-049":render049CR11,"SCR-050":render050CR11,"SCR-051":render051CR11,"SCR-052":render052CR11,"SCR-053":render053CR11,"SCR-078":render078CR,"SCR-079":render079CR,"SCR-080":render080CR,"SCR-081":render081CR,"SCR-082":render082CR,"SCR-083":render083CR,"SCR-014":render014IV03,"SCR-015":render015IV03,"SCR-016":render016IV03,"SCR-017":render017IV03,"SCR-019":render019IV03,"SCR-036":render036IO07,"SCR-037":render037IO07,"SCR-039":render039IO07,"SCR-041":render041IO07,"SCR-038":render038IC09,"SCR-040":render040IC10,"SCR-042":render042IC08,"SCR-043":render043IC08,"SCR-044":render044IC08,"SCR-045":render045IC08,"SCR-046":render046IC08,"SCR-047":render047IC08,"SCR-054":render054CF15,"SCR-055":render055CF15,"SCR-056":render056CF15,"SCR-057":render057CF15,"SCR-058":render058CF15,"SCR-059":render059CF15,"SCR-066":render066CF12,"SCR-067":render067CF12,"SCR-068":render068CF12,"SCR-069":render069CF12,"SCR-070":render070CF12,"SCR-071":render071CF12,"SCR-085":render085IV13,"SCR-086":render086IV13,"SCR-087":render087IV13,"SCR-088":render088IV13,"SCR-089":render089IV13,"SCR-072":render072IV14,"SCR-073":render073IV14,"SCR-074":render074IV14,"SCR-075":render075IV14,"SCR-076":render076IV14,"SCR-077":render077IV14};
for (const screen of screens) if (!renderers[screen.id]) renderers[screen.id]=(state)=>renderGeneric(screen,state);





// Một điểm vào duy nhất. Màn gốc của chế độ theme (Thêm, Hub Kho) do app/hub.js dựng; mọi màn BJ qua
// renderFlowScreen. Các bước sửa sau dựng còn lại (legacy) bọc renderFlowScreen và được xoá dần theo BJ ở T7-P.
// Luồng đã viết lại sạch trong app/bjNN.js tự đăng ký vào đây: màn của chúng dựng thẳng bằng renderers[...],
// không qua các bước sửa sau dựng legacy bọc renderFlowScreen.
const ownedFlows = new Set();
function renderAppScreen() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.isRoot()) return ThemeApp.renderRoot();
  if (ownedFlows.has(activeFlowId)) document.getElementById("app-screen").innerHTML = renderers[activeScreenId](stateByScreen[activeScreenId]);
  else renderFlowScreen();
  if (typeof ThemeApp !== "undefined") ThemeApp.afterFlowRender();
}
function renderFlowScreen() {
  const state = stateByScreen[activeScreenId];
  const effectiveRenderer = renderers[activeScreenId] || ((st) => appShell({title: screens.find(x=>x.id===activeScreenId)?.name || "Theme 7", body: ioEmpty("Đang hoàn thiện prototype","Màn hình này sẽ được tải khi lớp completion được khởi tạo."), back:false}));
  document.getElementById("app-screen").innerHTML = effectiveRenderer(state);
}

function render() {
  renderFlowSelector();
  renderNavigation();
  renderInspector();
  renderAppScreen();
  if (inspectEnabled) resetInspectSelection();
  requestAnimationFrame(fitReviewDeviceToViewport);
}

function syncReviewUrl() {
  const url = new URL(window.location.href);
  url.searchParams.set("uif", activeFlowId);
  url.searchParams.set("screen", activeScreenId);
  url.searchParams.set("state", stateByScreen[activeScreenId]);
  url.searchParams.set("flow", flowMode);
  url.searchParams.set("viewport", viewport);
  if (typeof ThemeApp !== "undefined") ThemeApp.decorateUrl(url);
  history.replaceState(null, "", url);
}

// Móc chạy khi điều hướng vào một màn (khoá "UIF-NN:SCR-NNN"), thay cho việc bọc navigate.
const onScreenEnter = {};

// Móc nút quay lại (data-back) theo luồng, thay cho nhánh của từng BJ trong previousScreen.
const onPrevious = {};

function navigate(screenId) {
  if (!renderers[screenId]) return;
  onScreenEnter[`${activeFlowId}:${screenId}`]?.();
  activeScreenId = screenId;
  syncReviewUrl();
  render();
}

function previousScreen() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.handlePrevious()) return;
  if (onPrevious[activeFlowId]) return onPrevious[activeFlowId]();
  const list = activeFlow()?.screens || [];
  const idx = list.indexOf(activeScreenId);
  if (idx > 0) return navigate(list[idx - 1]);
}

function normalizeToastType(type = "success") {
  const raw=String(type||"success");
  const aliases={xCircle:"danger",error:"danger",danger:"danger",alert:"warning",warning:"warning",info:"info",rotate:"info",arrowLeft:"info",arrowRight:"info",shield:"info",layers:"info",checkCircle:"success",success:"success"};
  return aliases[raw]||"success";
}
function showToastCanonical(message, type = "success") {
  const screen=document.getElementById("app-screen");
  const oldToast=screen.querySelector(".toast");
  if(oldToast)oldToast.remove();
  const toastType=normalizeToastType(type);
  const iconName=toastType==="danger"?"xCircle":toastType==="warning"?"alert":toastType==="info"?"info":"checkCircle";
  const semanticIcon=toastType==="danger"?"VIcons.error":toastType==="warning"?"VIcons.warning":toastType==="info"?"VIcons.info":"VIcons.success";
  const toast=document.createElement("div");
  toast.className="toast";
  toast.dataset.dsComponent="VToast";
  toast.dataset.figmaNode="526:4305";
  toast.dataset.dsPropType=`VToastType.${toastType}`;
  toast.dataset.dsPropMessage=message;
  toast.innerHTML=`<span class="toast-icon-box" data-ds-component="VIconBox" data-ds-prop-is-circular="true" data-ds-prop-size="24" data-ds-prop-icon-size="14" data-ds-prop-icon="${semanticIcon}">${icon(iconName,"icon--sm")}</span><span class="toast-message" data-ds-internal="VToast.message">${esc(message)}</span><button class="toast-close" data-action="close-toast" type="button" aria-label="Đóng thông báo" data-ds-internal="VToast.close" data-ds-icon="VIcons.close">${icon("close","icon--sm")}</button>`;
  screen.appendChild(toast);
  window.clearTimeout(toastTimer);
  toastTimer=window.setTimeout(()=>toast.remove(),2600);
  return toast;
}
function showToast(message,type="success"){return showToastCanonical(message,type);}
function showToastLegacy(message,type="success"){return showToastCanonical(message,type);}

// Review-only Inspect state. Kept outside product UI.
let inspectEnabled = false;
let inspectPinned = false;
let inspectTarget = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function inspectableFrom(target) {
  if (!(target instanceof Element)) return null;
  const hit = target.closest('[data-ds-component], [data-theme-component], [data-ds-internal]');
  return hit && hit.closest('#app-screen') ? hit : null;
}

function numberPx(style, property) {
  const value = Number.parseFloat(style.getPropertyValue(property));
  return Number.isFinite(value) ? value : 0;
}

function boxRect(rect, top, right, bottom, left, mode = "expand") {
  if (mode === "expand") {
    return { left: rect.left - left, top: rect.top - top, width: rect.width + left + right, height: rect.height + top + bottom };
  }
  return { left: rect.left + left, top: rect.top + top, width: Math.max(0, rect.width - left - right), height: Math.max(0, rect.height - top - bottom) };
}

function setInspectBox(node, box) {
  Object.assign(node.style, {
    left: `${box.left}px`, top: `${box.top}px`, width: `${box.width}px`, height: `${box.height}px`,
  });
}

function figmaAssetTarget(name, layer = "COMPONENT", status = "EXACT", note = "") {
  const asset = FIGMA_DS_MAP.assetIndex?.[name] || {};
  return { name, nodeId: asset.nodeId || null, assetType: asset.assetType || null, section: asset.section || null, layer, status, note };
}

function resolveFigmaMapping(element) {
  const ds = element.dataset.dsComponent || "";
  const theme = element.dataset.themeComponent || "";
  const internal = element.dataset.dsInternal || "";
  const profile = element.dataset.dsProfile || "";
  let source = "";
  let mapping = null;
  if (theme && FIGMA_DS_MAP.themeComponentMappings?.[theme]) { source = `theme:${theme}`; mapping = FIGMA_DS_MAP.themeComponentMappings[theme]; }
  else if (internal && FIGMA_DS_MAP.internalMappings?.[internal]) { source = `internal:${internal}`; mapping = FIGMA_DS_MAP.internalMappings[internal]; }
  else if (ds) {
    const base = FIGMA_DS_MAP.componentMappings?.[ds] || null;
    const contextual = profile ? (FIGMA_DS_MAP.profileMappings?.[`${ds}|${profile}`] || null) : null;
    if (base && contextual && ["PATTERN","TEMPLATE","FOUNDATION"].includes(contextual.layer) && ["EXACT","LEGACY_ALIAS","EXACT_FOUNDATION"].includes(base.status)) {
      source = `component:${ds}`; mapping = { ...base, contextMapping: contextual };
    } else if (contextual) { source = `profile:${ds}|${profile}`; mapping = contextual; }
    else if (base) { source = `component:${ds}`; mapping = base; }
    else if (FIGMA_DS_MAP.assetIndex?.[ds]) {
      const asset=FIGMA_DS_MAP.assetIndex[ds];
      const section=String(asset.section||"");
      const layer=section.includes("Patterns")||section.includes("Form Patterns")?"PATTERN":section.includes("Page Templates")?"TEMPLATE":"COMPONENT";
      source=`asset:${ds}`; mapping=figmaAssetTarget(ds,layer,"EXACT","Direct live Figma DS asset used by Phase 4 rollout.");
    }
  }

  // Dynamic legacy aliases that depend on actual rendered anatomy.
  if (ds === "VButton" && String(element.dataset.dsPropVariant || "").toLowerCase().includes("link")) {
    source = "dynamic:VButton.link"; mapping = figmaAssetTarget("DS v2 / Link", "COMPONENT", "LEGACY_ALIAS", "Legacy link-style button resolves to canonical Link component.");
  }
  if (ds === "VTextFormField" && element.querySelector("textarea")) {
    source = "dynamic:VTextFormField.multiline"; mapping = FIGMA_DS_MAP.componentMappings?.VTextarea || mapping;
  }
  if (ds === "VPageScaffold") {
    const explicitTemplate = element.dataset.figmaTemplate || "";
    if (explicitTemplate) {
      source = `phase5:template:${activeFlowId}:${activeScreenId}`;
      mapping = figmaAssetTarget(explicitTemplate, "TEMPLATE", "EXACT", "Phase 5 Theme 7 screen uses the explicit task-appropriate Figma page template.");
      return { ...mapping, source, legacy: { ds, theme, internal, profile } };
    }
    const surface = currentScreen()?.surface || "";
    let name = null;
    if (["result", "status / entry", "validation result"].includes(surface)) name = "Mobile / Detail";
    else if (surface === "form" || surface === "choice" || surface === "approval review") name = "Mobile / Form";
    else if (surface === "list") name = element.dataset.dsPropShowBackButton === "false" ? "Mobile / Root List" : "Mobile / Nested List";
    else if (["detail", "review", "timeline", "dashboard"].includes(surface)) name = "Mobile / Detail";
    if (name) { source = `dynamic:template:${surface}`; mapping = figmaAssetTarget(name, "TEMPLATE", "MIGRATION_TARGET", "Fallback template candidate derived from current task/surface; explicit Phase 5 mappings are authoritative."); }
  }
  if (!mapping) mapping = { name: ds || theme || internal || element.tagName.toLowerCase(), nodeId: null, assetType: null, section: null, layer: "UNMAPPED", status: "UNMAPPED", note: "No Phase 2 mapping rule." };
  return { ...mapping, source, legacy: { ds, theme, internal, profile } };
}

function figmaTextStyleFor(element) {
  const v = String(element.dataset.dsPropVariant || "");
  if (v.includes("headingH1")) return "VET45 v2 / Heading / H1";
  if (v.includes("headingH2")) return "VET45 v2 / Heading / H2";
  if (v.includes("headingH3")) return "VET45 v2 / Heading / H3";
  if (v.includes("headingH4")) return "VET45 v2 / Heading / H4";
  if (v.includes("bodySmall")) return "VET45 v2/Body/Small";
  if (v.includes("bodyDefault") || v.includes("bodyMedium")) return "VET45 v2 / Body / Default";
  if (element.matches("h1")) return "VET45 v2 / Heading / H1";
  if (element.matches("h2")) return "VET45 v2 / Heading / H3";
  if (element.matches("h3")) return "VET45 v2 / Heading / H4";
  if (element.matches("small")) return "VET45 v2/Body/Small";
  if (element.matches("strong")) return "VET45 v2 / Label / Default";
  return "VET45 v2 / Body / Default";
}

function canonicalFigmaProps(element, mapping) {
  const ds = element.dataset.dsComponent || "";
  const out = [];
  if (ds === "VButton") {
    const variant = String(element.dataset.dsPropVariant || "").toLowerCase();
    const tone = String(element.dataset.dsPropTone || "").toLowerCase();
    if (mapping.name === "DS v2 / Link") {
      out.push(["Tone", tone.includes("danger") ? "Danger" : "Default"]);
      out.push(["State", element.disabled ? "Disabled" : "Default"]);
    } else {
      let hierarchy = tone.includes("danger") ? "Danger" : variant.includes("secondary") ? "Secondary" : variant.includes("tertiary") ? "Tertiary" : "Primary";
      const size = String(element.dataset.dsPropSize || "").toLowerCase();
      out.push(["Hierarchy", hierarchy]);
      out.push(["State", element.disabled ? "Disabled" : element.classList.contains("is-loading") ? "Loading" : "Default"]);
      out.push(["Size", size.includes("small") ? "Small" : size.includes("large") ? "Large" : "Default"]);
    }
  } else if (ds === "VBadge") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : status.includes("info") ? "Info" : "Neutral";
    out.push(["Tone", tone], ["Style", "Soft"]);
  } else if (ds === "VBanner") {
    const status = String(element.dataset.dsPropStatus || element.className || "").toLowerCase();
    const tone = status.includes("success") ? "Success" : status.includes("warning") ? "Warning" : status.includes("danger") || status.includes("error") ? "Danger" : "Info";
    out.push(["Tone", tone], ["Density", "Default"]);
  } else if (ds === "VChip") {
    const selected = element.dataset.dsPropSelected === "true" || element.classList.contains("is-active");
    out.push(["Tone", selected ? "Brand" : "Neutral"], ["State", element.disabled ? "Disabled" : "Default"]);
  } else if (ds === "VAppBar") {
    const back = element.querySelector('[data-ds-internal="VAppBar.leading"]') !== null;
    const subtitle = element.querySelector('[data-ds-component="VAppBarSubtitle"]') !== null;
    out.push(["Type", back && subtitle ? "Context" : back ? "Back" : subtitle ? "Root context" : "Root"]);
  } else if (ds === "VEmptyState") {
    const text = element.textContent || "";
    let type = element.dataset.themeComponent === "PermissionDeniedState" ? "No Permission" : /không có kết quả/i.test(text) ? "No Result" : /bị chặn|không thể tiếp tục/i.test(text) ? "Blocked" : /lỗi|không tải/i.test(text) ? "Error" : "Empty";
    out.push(["Type", type]);
  } else if (ds === "VSearchBar") {
    const input = element.querySelector("input");
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (["VTextField","VTextFormField","VNumberField","VDatePicker","VDatePickerField","VSelect"].includes(ds)) {
    const input = element.querySelector("input,textarea,select") || (element.matches("input,textarea,select") ? element : null);
    out.push(["State", element.matches(":focus-within") ? "Focused" : input?.disabled ? "Disabled" : input?.value ? "Filled" : "Default"]);
  } else if (ds === "VRadio") {
    const input = element.querySelector('input[type="radio"]');
    out.push(["State", input?.disabled ? (input.checked ? "Disabled On" : "Disabled Off") : input?.checked || element.classList.contains("is-selected") ? "On" : "Off"]);
  } else if (ds === "VSegmentedControl") {
    const items = [...element.querySelectorAll("button")];
    const selected = items.findIndex((x)=>x.classList.contains("is-selected") || x.getAttribute("aria-pressed") === "true");
    if (selected >= 0) out.push(["Selected", String(selected + 1)]);
  } else if (ds === "VText") {
    out.push(["Text style", figmaTextStyleFor(element)]);
  } else if (ds === "VIcon") {
    out.push(["Registry", "VET45 approved Icon Library"]);
    if (element.dataset.dsPropIcon) out.push(["Icon", element.dataset.dsPropIcon.replace(/^VIcons\./, "")]);
  }
  return out;
}

function inspectLabel(element) {
  const mapping = resolveFigmaMapping(element);
  return mapping.name || element.dataset.dsComponent || element.dataset.themeComponent || element.dataset.dsInternal || element.tagName.toLowerCase();
}

function collectInspectProps(element) {
  const props = [];
  for (const attr of element.attributes) {
    if (attr.name.startsWith('data-ds-prop-')) props.push([attr.name.slice('data-ds-prop-'.length), attr.value]);
  }
  if (element.dataset.dsProfile) props.unshift(['profile', element.dataset.dsProfile]);
  if (element.dataset.dsSlot) props.push(['slot', element.dataset.dsSlot]);
  if (element.dataset.dsDefaultIcon) props.push(['defaultIcon', element.dataset.dsDefaultIcon]);
  if (element.dataset.dsIcon) props.push(['icon', element.dataset.dsIcon]);
  if (element.dataset.composedFrom) props.push(['composedFrom', element.dataset.composedFrom]);
  if (element.dataset.dsGap) props.push(['DS gap', element.dataset.dsGap]);
  return props;
}

function inspectBoxValues(element) {
  const style = getComputedStyle(element);
  const rect = element.getBoundingClientRect();
  const margin = [numberPx(style,'margin-top'), numberPx(style,'margin-right'), numberPx(style,'margin-bottom'), numberPx(style,'margin-left')];
  const border = [numberPx(style,'border-top-width'), numberPx(style,'border-right-width'), numberPx(style,'border-bottom-width'), numberPx(style,'border-left-width')];
  const padding = [numberPx(style,'padding-top'), numberPx(style,'padding-right'), numberPx(style,'padding-bottom'), numberPx(style,'padding-left')];
  const marginRect = boxRect(rect, ...margin, 'expand');
  const paddingRect = boxRect(rect, ...border, 'shrink');
  const contentRect = boxRect(paddingRect, ...padding, 'shrink');
  return { style, rect, margin, border, padding, marginRect, borderRect: rect, paddingRect, contentRect };
}

function fourSides(values) {
  return `${Math.round(values[0] * 10) / 10} · ${Math.round(values[1] * 10) / 10} · ${Math.round(values[2] * 10) / 10} · ${Math.round(values[3] * 10) / 10}`;
}

function renderInspectDetails(element, boxes) {
  const panel = document.getElementById('inspect-details');
  const mapping = resolveFigmaMapping(element);
  const legacyProps = collectInspectProps(element);
  const figmaProps = canonicalFigmaProps(element, mapping);
  const figmaPropsHtml = figmaProps.length
    ? figmaProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có variant/state canonical bổ sung cho node này.</div>';
  const legacyPropsHtml = legacyProps.length
    ? legacyProps.map(([k,v]) => `<div class="inspect-prop"><span>${escapeHtml(k)}</span><code>${escapeHtml(v)}</code></div>`).join('')
    : '<div class="inspect-muted">Không có legacy prop override.</div>';
  const legacyLabel = [mapping.legacy?.theme && `Theme7.${mapping.legacy.theme}`, mapping.legacy?.ds, mapping.legacy?.internal].filter(Boolean).join(' · ') || '—';
  panel.innerHTML = `
    <div class="inspect-component-name">${escapeHtml(mapping.name)}</div>
    <div class="inspect-meta-grid">
      <span>Figma node</span><strong>${escapeHtml(mapping.nodeId || '—')}</strong>
      <span>Layer</span><strong>${escapeHtml(mapping.layer || '—')}</strong>
      <span>Mapping</span><strong>${escapeHtml(mapping.status || '—')}</strong>
      <span>Section</span><strong>${escapeHtml(mapping.section || '—')}</strong>
      <span>Authority</span><strong>Figma DS v2.0.3</strong>
      <span>Legacy</span><strong>${escapeHtml(legacyLabel)}</strong>
      <span>Element</span><strong>${escapeHtml(element.tagName.toLowerCase())}</strong>
      ${mapping.contextMapping ? `<span>Context</span><strong>${escapeHtml(mapping.contextMapping.name)}${mapping.contextMapping.nodeId ? ` · ${escapeHtml(mapping.contextMapping.nodeId)}` : ''}</strong>` : ''}
    </div>
    ${mapping.note ? `<div class="inspect-mapping-note">${escapeHtml(mapping.note)}</div>` : ''}
    <div class="inspect-subtitle">Figma props / variant</div>
    <div class="inspect-props">${figmaPropsHtml}</div>
    <div class="inspect-subtitle">Legacy annotation / trace</div>
    <div class="inspect-props">${legacyPropsHtml}</div>
    <div class="inspect-subtitle">Box model · T/R/B/L (px)</div>
    <div class="box-model-readout">
      <div class="box-line box-line--margin"><span>margin</span><code>${fourSides(boxes.margin)}</code></div>
      <div class="box-line box-line--border"><span>border</span><code>${fourSides(boxes.border)}</code></div>
      <div class="box-line box-line--padding"><span>padding</span><code>${fourSides(boxes.padding)}</code></div>
      <div class="box-line box-line--content"><span>content</span><code>${Math.round(boxes.contentRect.width * 10) / 10} × ${Math.round(boxes.contentRect.height * 10) / 10}</code></div>
    </div>`;
}

function showInspectOverlay(element) {
  if (!inspectEnabled || !element || !element.isConnected) return;
  inspectTarget = element;
  const overlay = document.getElementById('inspect-overlay');
  const boxes = inspectBoxValues(element);
  overlay.hidden = false;
  setInspectBox(overlay.querySelector('.inspect-box--margin'), boxes.marginRect);
  setInspectBox(overlay.querySelector('.inspect-box--border'), boxes.borderRect);
  setInspectBox(overlay.querySelector('.inspect-box--padding'), boxes.paddingRect);
  setInspectBox(overlay.querySelector('.inspect-box--content'), boxes.contentRect);
  const tag = overlay.querySelector('.inspect-tag');
  tag.textContent = inspectLabel(element);
  const tagTop = Math.max(4, boxes.borderRect.top - 25);
  const tagLeft = Math.max(4, Math.min(boxes.borderRect.left, window.innerWidth - 280));
  tag.style.top = `${tagTop}px`;
  tag.style.left = `${tagLeft}px`;
  renderInspectDetails(element, boxes);
}

function hideInspectOverlay() {
  const overlay = document.getElementById('inspect-overlay');
  if (overlay) overlay.hidden = true;
}

function resetInspectSelection() {
  inspectPinned = false;
  inspectTarget = null;
  hideInspectOverlay();
  const status = document.getElementById('inspect-pin-status');
  if (status) status.textContent = inspectEnabled ? 'Hover component' : 'Inspect off';
  const details = document.getElementById('inspect-details');
  if (details && inspectEnabled) details.textContent = 'Rê chuột lên component; click để ghim. Esc để bỏ ghim.';
}

function toggleInspect(force) {
  inspectEnabled = typeof force === 'boolean' ? force : !inspectEnabled;
  document.body.classList.toggle('inspect-mode', inspectEnabled);
  const toggle = document.getElementById('inspect-toggle');
  toggle.classList.toggle('is-active', inspectEnabled);
  toggle.setAttribute('aria-pressed', String(inspectEnabled));
  toggle.textContent = inspectEnabled ? 'Inspect · On' : 'Inspect';
  document.getElementById('inspect-section').hidden = !inspectEnabled;
  const url = new URL(window.location.href);
  if (inspectEnabled) url.searchParams.set('inspect', '1'); else url.searchParams.delete('inspect');
  history.replaceState(null, '', url);
  resetInspectSelection();
}

document.getElementById('inspect-toggle')?.addEventListener('click', () => toggleInspect());
document.getElementById('app-screen')?.addEventListener('pointermove', (event) => {
  if (!inspectEnabled || inspectPinned) return;
  const target = inspectableFrom(event.target);
  if (target) showInspectOverlay(target); else hideInspectOverlay();
});
document.getElementById('app-screen')?.addEventListener('pointerleave', () => {
  if (inspectEnabled && !inspectPinned) hideInspectOverlay();
});

// Capture click inside product viewport while Inspect is on so prototype actions
// never fire accidentally. A click pins the selected component instead.
document.addEventListener('click', (event) => {
  if (!inspectEnabled || !event.target.closest?.('#app-screen')) return;
  const target = inspectableFrom(event.target);
  if (!target) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  inspectPinned = true;
  showInspectOverlay(target);
  document.getElementById('inspect-pin-status').textContent = 'Pinned · Esc để bỏ ghim';
}, true);

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape' || !inspectEnabled) return;
  resetInspectSelection();
});
window.addEventListener('resize', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); });
document.getElementById('app-screen')?.addEventListener('scroll', () => { if (inspectEnabled && inspectTarget) showInspectOverlay(inspectTarget); }, true);

document.addEventListener("click", (event) => {
  const screenButton = event.target.closest("[data-screen]");
  if (screenButton) return navigate(screenButton.dataset.screen);

  const stateButton = event.target.closest("[data-state]");
  if (stateButton) {
    stateByScreen[activeScreenId] = stateButton.dataset.state;
    syncReviewUrl();
    return render();
  }

  const viewportButton = event.target.closest("[data-viewport]");
  if (viewportButton) {
    viewport = viewportButton.dataset.viewport;
    syncReviewUrl();
    document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button === viewportButton));
    document.getElementById("device-preview").className = `device-preview is-${viewport}`;
    return;
  }

  const nextButton = event.target.closest("[data-next]");
  if (nextButton) return navigate(nextButton.dataset.next);

  if (event.target.closest("[data-back]")) return previousScreen();

  const actionButton = event.target.closest("[data-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.action;
  if (action === "close-toast") { actionButton.closest(".toast")?.remove(); return; }
});

document.getElementById("device-preview").className = `device-preview is-${viewport}`;
document.querySelectorAll(".viewport-button").forEach((button) => button.classList.toggle("is-active", button.dataset.viewport === viewport));
syncReviewUrl();


// Inventory Valuation interactions — UIF-03 v1.4.4.


// v1.7.0 Correction & Recovery interactions
 document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-11"){
    if(event.target.matches("[data-cr11-search]")){cr11Query=event.target.value;return renderAppScreen();}
    if(event.target.matches("[data-cr11-correct-qty]")){cr11CorrectQty=Math.max(0,Number(event.target.value)||0);return renderAppScreen();}
    if(event.target.matches("[data-cr11-correction-reason]")){cr11CorrectionReason=event.target.value;return;}
    if(event.target.matches("[data-cr11-cancel-reason]")){cr11CancelReason=event.target.value;const btn=document.querySelector('[data-cr11-action="confirm-cancel"]');if(btn)btn.disabled=!cr11CancelReason.trim();return;}
    if(event.target.matches("[data-cr11-approval-reason]")){cr11ApprovalRejectReason=event.target.value;const btn=document.querySelector('[data-cr11-action="reject-confirm"]');if(btn)btn.disabled=!cr11ApprovalRejectReason.trim();return;}
  }
  if(["UIF-16","UIF-17"].includes(activeFlowId)&&event.target.matches("[data-cr-control-search]")){crControlQuery=event.target.value;return renderAppScreen();}
 },true);
 document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-11"&&event.target.matches("[data-cr11-strategy]")){cr11Strategy=event.target.value;return renderAppScreen();}
 },true);
 document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-11"){
    const filter=event.target.closest("[data-cr11-filter]");if(filter){event.preventDefault();cr11Filter=filter.dataset.cr11Filter;return renderAppScreen();}
    const row=event.target.closest("[data-cr11-operation]");if(row){event.preventDefault();cr11SelectedId=row.dataset.cr11Operation;const op=cr11Current();stateByScreen["SCR-049"]=cr11StateFor(op);return navigate("SCR-049");}
    const a=event.target.closest("[data-cr11-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr11Action;
      if(k==="to-list"){cr11Query="";stateByScreen["SCR-048"]="READY";return navigate("SCR-048");}
      if(k==="back-detail")return navigate("SCR-049");
      if(k==="open-cancel"){stateByScreen["SCR-052"]="CANCEL_UNEXECUTED";cr11CancelReason="";return navigate("SCR-052");}
      if(k==="confirm-cancel"){if(!cr11CancelReason.trim()){stateByScreen["SCR-052"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-053"]="CANCELLED";return navigate("SCR-053");}
      if(k==="open-correction"){stateByScreen["SCR-052"]="CORRECTION_ROUTE";return navigate("SCR-052");}
      if(k==="edit-correction"){cr11CorrectQty=cr11Current().correctQty||cr11Current().qty;stateByScreen["SCR-050"]="READY";return navigate("SCR-050");}
      if(k==="submit-correction"){if(Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim()){stateByScreen["SCR-050"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-053"]="PENDING_APPROVAL";return navigate("SCR-053");}
      if(k==="reject-open"){cr11ApprovalRejectOpen=true;cr11ApprovalRejectReason="";return renderAppScreen();}
      if(k==="reject-close"){cr11ApprovalRejectOpen=false;return renderAppScreen();}
      if(k==="reject-confirm"){if(!cr11ApprovalRejectReason.trim()){stateByScreen["SCR-051"]="VALIDATION_ERROR";return renderAppScreen();}cr11ApprovalRejectOpen=false;stateByScreen["SCR-053"]="REJECTED";return navigate("SCR-053");}
      if(k==="approve"){stateByScreen["SCR-053"]="PROCESSING";navigate("SCR-053");setTimeout(()=>{if(activeFlowId==="UIF-11"&&activeScreenId==="SCR-053"&&stateByScreen["SCR-053"]==="PROCESSING"){stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();}},650);return;}
      if(k==="approval-result"){return navigate("SCR-053");}
      if(k==="handoff-unknown"){cr17SelectedId="REC-UNKNOWN-01";stateByScreen["SCR-079"]="UNKNOWN_EVIDENCE";return crSwitchFlow("UIF-17","SCR-079","UNKNOWN_EVIDENCE");}
    }
  }
  if(activeFlowId==="UIF-16"){
    const f=event.target.closest("[data-cr16-filter]");if(f){event.preventDefault();cr16Filter=f.dataset.cr16Filter;return renderAppScreen();}
  }
  if(activeFlowId==="UIF-17"){
    const f=event.target.closest("[data-cr17-filter]");if(f){event.preventDefault();cr17Filter=f.dataset.cr17Filter;return renderAppScreen();}
  }
  if(["UIF-16","UIF-17"].includes(activeFlowId)){
    const row=event.target.closest("[data-cr-case]");if(row){event.preventDefault();if(activeFlowId==="UIF-16"){cr16SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());}else{cr17SelectedId=row.dataset.crCase;stateByScreen["SCR-079"]=cr079StateFor17(cr17Current());}return navigate("SCR-079");}
  }
  if(activeFlowId==="UIF-16"){
    const a=event.target.closest("[data-cr16-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr16Action;
      if(k==="open-plan"){stateByScreen["SCR-080"]="READY";return navigate("SCR-080");}
      if(k==="start-recovery"){stateByScreen["SCR-081"]="REBUILDING";navigate("SCR-081");setTimeout(()=>{if(activeFlowId==="UIF-16"&&activeScreenId==="SCR-081"&&stateByScreen["SCR-081"]==="REBUILDING"){stateByScreen["SCR-081"]="READY";syncReviewUrl();render();}},750);return;}
      if(k==="review-result"){stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="review-close"){stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="close-case"){stateByScreen["SCR-083"]="RESOLVED";return navigate("SCR-083");}
      if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      if(k==="handoff-correction"){cr11SelectedId="IO-260901-014";stateByScreen["SCR-049"]="CORRECTABLE";return crSwitchFlow("UIF-11","SCR-049","CORRECTABLE");}
      if(k==="to-list"){crControlQuery="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
    }
  }
  if(activeFlowId==="UIF-17"){
    const a=event.target.closest("[data-cr17-action]");if(a&&!a.disabled){event.preventDefault();const k=a.dataset.cr17Action;
      if(k==="open-plan"){stateByScreen["SCR-080"]=cr17Current().evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"READY";return navigate("SCR-080");}
      if(k==="execute-plan"){cr17ResolutionMode=cr17Current().evidence==="COMMITTED"?"COMMITTED":"CONTINUED";stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
      if(k==="finish-review"){stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");}
      if(k==="show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
      if(k==="to-list"){crControlQuery="";cr17ResolutionMode="";stateByScreen["SCR-078"]="READY";return navigate("SCR-078");}
    }
  }
 },true);

// v2.4.1 Inventory Audit & Control interactions — BJ08 Product + DS correction; UIF09/10 carried forward.
 document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-08"){
    if(event.target.matches("[data-ic08-reason]")){ic08Reason=event.target.value;return;}
    if(event.target.matches("[data-ic08-cancel-reason]")){ic08CancelReason=event.target.value;const b=document.querySelector('[data-ic08-action="confirm-cancel"]');if(b)b.disabled=!ic08CancelReason.trim();return;}
    if(event.target.matches("[data-ic08-review-reason]")){ic08ReviewReason=event.target.value;const b=document.querySelector('[data-ic08-action="confirm-request-review"]');if(b)b.disabled=!ic08ReviewReason.trim();return;}
  }
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-search]")){ic09Query=event.target.value;return renderAppScreen();}
 });
 document.addEventListener("change",(event)=>{
  if(activeFlowId==="UIF-08"){
    if(event.target.matches("[data-ic08-scope]")){ic08Scope=event.target.value;ic08ScopeTarget="";ic08ScopeSheetOpen=false;return renderAppScreen();}
  }
  if(activeFlowId==="UIF-09"&&event.target.matches("[data-ic09-destination]")){ic09Destination=event.target.value;return renderAppScreen();}
 });
 document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-08"){
    const key=event.target.closest("[data-ic08-key]");
    if(key){event.preventDefault();const k=key.dataset.ic08Key;if(k==="⌫")ic08KeypadDraft=ic08KeypadDraft.slice(0,-1);else if(k==="."){if(!ic08KeypadDraft.includes("."))ic08KeypadDraft=(ic08KeypadDraft||"0")+".";}else{ic08KeypadDraft=(ic08KeypadDraft==="0"?"":ic08KeypadDraft)+k;}return renderAppScreen();}
    const qty=event.target.closest("[data-ic08-keypad-open]");
    if(qty&&!qty.disabled){event.preventDefault();ic08KeypadTarget=qty.dataset.ic08KeypadOpen;const [mode,id]=ic08KeypadTarget.split(":");ic08KeypadDraft=mode==="recount"?(ic08Recounts[id]||"0"):(id==="unexpected"?(ic08UnexpectedLine?.value||"0"):(ic08Counts[id]||"0"));return renderAppScreen();}
    const scopeTarget=event.target.closest("[data-ic08-scope-target]");
    if(scopeTarget){event.preventDefault();ic08ScopeTarget=scopeTarget.dataset.name||scopeTarget.textContent.trim();ic08ScopeSheetOpen=false;return renderAppScreen();}
    const product=event.target.closest("[data-ic08-product]");
    if(product){event.preventDefault();const id=product.dataset.ic08Product;ic08UnexpectedLine=id==="vitc"?{id:"unexpected",name:"Vitamin C",lot:"L2501-C",uom:"hộp",value:"0"}:{id:"unexpected",name:"Amox 500",lot:"L2501-A",uom:"hộp",value:"0"};ic08ProductSheetOpen=false;return renderAppScreen();}
    const a=event.target.closest("[data-ic08-action]");
    if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic08Action;
      if(k==="create")return navigate("SCR-043");
      if(k==="resume"){stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
      if(k==="scope-select-open"){ic08ScopeSheetOpen=true;ic08ProductSheetOpen=false;return renderAppScreen();}
      if(k==="add-actual-open"){ic08ProductSheetOpen=true;ic08ScopeSheetOpen=false;return renderAppScreen();}
      if(k==="select-close"){ic08ProductSheetOpen=false;ic08ScopeSheetOpen=false;return renderAppScreen();}
      if(k==="open-session"){ic08ConfirmKind="open-session";return renderAppScreen();}
      if(k==="confirm-open-session"){ic08ConfirmKind=null;stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
      if(k==="submit-first"){ic08ConfirmKind="submit-first";return renderAppScreen();}
      if(k==="confirm-submit-first"){ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      if(k==="submit-recount"){ic08ConfirmKind="submit-recount";return renderAppScreen();}
      if(k==="confirm-submit-recount"){ic08ConfirmKind=null;stateByScreen["SCR-042"]="PENDING_APPROVAL";return navigate("SCR-042");}
      if(k==="cancel-open"){ic08CancelReason="";ic08ConfirmKind="cancel";return renderAppScreen();}
      if(k==="confirm-cancel"){if(!ic08CancelReason.trim())return;ic08ConfirmKind=null;stateByScreen["SCR-047"]="CANCELLED";return navigate("SCR-047");}
      if(k==="confirm-close"){ic08ConfirmKind=null;return renderAppScreen();}
      if(k==="keypad-cancel"){ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();}
      if(k==="keypad-save"){
        const [mode,id]=(ic08KeypadTarget||":").split(":");const v=ic08KeypadDraft||"0";
        if(mode==="recount"&&id)ic08Recounts[id]=v;else if(mode==="count"&&id==="unexpected"&&ic08UnexpectedLine)ic08UnexpectedLine.value=v;else if(mode==="count"&&id)ic08Counts[id]=v;
        ic08KeypadTarget=null;ic08KeypadDraft="";return renderAppScreen();
      }
      if(k==="approve"){ic08ConfirmKind="approve";return renderAppScreen();}
      if(k==="confirm-approve"){ic08ConfirmKind=null;stateByScreen["SCR-047"]="COMPLETED";return navigate("SCR-047");}
      if(k==="request-review"){ic08ReviewReason="";ic08ConfirmKind="request-review";return renderAppScreen();}
      if(k==="confirm-request-review"){if(!ic08ReviewReason.trim())return;ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      if(k==="approval-result"){return navigate("SCR-047");}
      if(k==="verify-result")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-042"]="READY";return navigate("SCR-042");}
    }
  }
  if(activeFlowId==="UIF-09"){
    const f=event.target.closest("[data-ic09-filter]"); if(f){event.preventDefault();ic09Filter=f.dataset.ic09Filter;return renderAppScreen();}
    const item=event.target.closest("[data-ic09-item]"); if(item){event.preventDefault();ic09Selected=item.dataset.ic09Item;stateByScreen["SCR-037"]=ic09Current().state==="EXPIRED"?"EXPIRED":"READY";return navigate("SCR-037");}
    const a=event.target.closest("[data-ic09-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic09Action;
      if(k==="change"){stateByScreen["SCR-038"]="READY";return navigate("SCR-038");} if(k==="history")return navigate("SCR-056");
      if(k==="submit"){stateByScreen["SCR-038"]="PENDING_APPROVAL";return render();} if(k==="approve"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
      if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
    }
  }
  if(activeFlowId==="UIF-10"){
    const item=event.target.closest("[data-ic10-item]"); if(item){event.preventDefault();ic10Selected=item.dataset.ic10Item;stateByScreen["SCR-037"]="READY";return navigate("SCR-037");}
    const a=event.target.closest("[data-ic10-action]"); if(a&&!a.disabled){event.preventDefault();const k=a.dataset.ic10Action;
      if(k==="request"){stateByScreen["SCR-040"]="READY";return navigate("SCR-040");} if(k==="submit"){stateByScreen["SCR-040"]="PENDING_APPROVAL";return render();}
      if(k==="approve"){stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return render();} if(k==="reject"){stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
      if(k==="complete"){stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");} if(k==="verify")return renderAppScreen();
      if(k==="to-list"){stateByScreen["SCR-036"]="READY";return navigate("SCR-036");}
    }
  }
 },true);

document.addEventListener("input",(event)=>{if(activeFlowId!=="UIF-03")return;if(event.target.matches("[data-val03-search]")){val03Query=event.target.value;return renderAppScreen();}if(event.target.matches("[data-val03-qty]")){const id=event.target.dataset.val03Qty;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.selectedQty=Math.max(1,Math.min(Number(event.target.value)||1,sl.pendingQty));break;}}return;}if(event.target.matches("[data-val03-reason]")){const g=val03Current().groups.find(x=>x.id===event.target.dataset.val03Reason);if(g)g.reason=event.target.value;const reviewBtn=document.querySelector('[data-val03-action="open-review"]');if(reviewBtn)reviewBtn.disabled=!val03ScopeReady();const doneBtn=document.querySelector('.button--primary[data-val03-action="close-evidence-sheet"]');if(doneBtn)doneBtn.disabled=val03HasSelectedConflict()&&!val03ScopeReady();return;}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-03")return;const filter=event.target.closest("[data-val03-filter]");if(filter){event.preventDefault();val03Filter=filter.dataset.val03Filter;return renderAppScreen();}const receipt=event.target.closest("[data-val03-receipt]");if(receipt){event.preventDefault();val03SelectedReceiptId=receipt.dataset.val03Receipt;val03LastSourceChange=null;val03EvidenceSheetOpen=false;return navigate("SCR-015");}const sliceBtn=event.target.closest("[data-val03-slice]");if(sliceBtn&&!sliceBtn.disabled){event.preventDefault();const id=sliceBtn.dataset.val03Slice;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.selected=!sl.selected;sl.selectedQty=sl.pendingQty;sl.partialOpen=false;break;}}return renderAppScreen();}const partial=event.target.closest("[data-val03-partial]");if(partial){event.preventDefault();const id=partial.dataset.val03Partial;for(const g of val03Current().groups){const sl=g.slices.find(x=>x.id===id);if(sl){sl.partialOpen=!sl.partialOpen;sl.selectedQty=sl.pendingQty;break;}}return renderAppScreen();}const source=event.target.closest("[data-val03-source]");if(source){event.preventDefault();const g=val03Current().groups.find(x=>x.id===source.dataset.val03Source);if(g){g.selectedSource=source.dataset.val03SourceId;g.reason="";}return renderAppScreen();}const action=event.target.closest("[data-val03-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val03Action;if(k==="open-evidence-sheet"){val03EvidenceSheetOpen=true;return renderAppScreen();}if(k==="close-evidence-sheet"){val03EvidenceSheetOpen=false;if(activeScreenId==="SCR-017")val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen[activeScreenId]="READY";return renderAppScreen();}if(k==="open-review"){if(!val03ScopeReady()){val03EvidenceSheetOpen=true;return renderAppScreen();}val03EvidenceSheetOpen=false;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen["SCR-017"]="READY";return navigate("SCR-017");}if(k==="retired-to-scope"){val03EvidenceSheetOpen=false;return navigate("SCR-015");}if(k==="confirm-value"){if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen["SCR-017"]="SOURCE_CHANGED";val03EvidenceSheetOpen=true;return renderAppScreen();}if(!val03ScopeReady())return;val03Commit();val03EvidenceSheetOpen=false;stateByScreen["SCR-019"]="COMPLETED";return navigate("SCR-019");}if(k==="continue-remaining"){stateByScreen["SCR-015"]="ALREADY_CONFIRMED";return navigate("SCR-015");}if(k==="result-to-scope"){stateByScreen["SCR-015"]="READY";return navigate("SCR-015");}if(k==="result-to-queue"){val03Query="";val03Filter="ALL";val03LastSourceChange=null;val03EvidenceSheetOpen=false;return navigate("SCR-014");}},true);


// Inventory Valuation late-cost interactions — UIF-13 v1.4.5.
document.addEventListener("input",(event)=>{if(activeFlowId!=="UIF-13")return;if(event.target.matches("[data-val13-search]")){val13Query=event.target.value;return renderAppScreen();}});
document.addEventListener("change",(event)=>{if(activeFlowId!=="UIF-13")return;if(event.target.matches("[data-val13-method]")){const t=val13Current();if(t.allowedMethods.some(m=>m.id===event.target.value)){t.selectedMethod=event.target.value;val13PreviewHash=null;}stateByScreen["SCR-087"]="READY";return renderAppScreen();}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-13")return;const filter=event.target.closest("[data-val13-filter]");if(filter){event.preventDefault();val13Filter=filter.dataset.val13Filter;return renderAppScreen();}const task=event.target.closest("[data-val13-task]");if(task){event.preventDefault();val13SelectedTaskId=task.dataset.val13Task;val13ResetTaskDraft(val13Current());stateByScreen["SCR-086"]="READY";return navigate("SCR-086");}const target=event.target.closest("[data-val13-target]");if(target){event.preventDefault();const t=val13Current(),line=t.targets.find(x=>x.id===target.dataset.val13Target);if(line)line.selected=!line.selected;val13PreviewHash=null;stateByScreen["SCR-086"]="READY";return renderAppScreen();}const action=event.target.closest("[data-val13-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val13Action;if(k==="scope-to-allocation"){if(!val13CanOpenAllocation()){stateByScreen["SCR-086"]="VALIDATION_ERROR";return renderAppScreen();}val13LastSourceChange=null;stateByScreen["SCR-087"]="READY";return navigate("SCR-087");}if(k==="open-review"){if(!val13CanPreview()){stateByScreen["SCR-087"]="VALIDATION_ERROR";return renderAppScreen();}val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();stateByScreen["SCR-088"]="READY";return navigate("SCR-088");}if(k==="back-scope"){stateByScreen["SCR-086"]="READY";return navigate("SCR-086");}if(k==="back-allocation"){stateByScreen["SCR-087"]="READY";return navigate("SCR-087");}if(k==="confirm-late-cost"){const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen["SCR-088"]="SOURCE_CHANGED";return renderAppScreen();}val13Commit();stateByScreen["SCR-089"]="COMPLETED";return navigate("SCR-089");}if(k==="result-to-queue"){val13Query="";val13Filter="ALL";val13LastSourceChange=null;stateByScreen["SCR-085"]="READY";return navigate("SCR-085");}},true);

document.addEventListener("change",(event)=>{if(activeFlowId!=="UIF-14")return;if(event.target.matches("[data-val14-period]")){val14SetupPeriod=event.target.value;return renderAppScreen();}if(event.target.matches("[data-val14-scope]")){val14SetupScope=event.target.value;return renderAppScreen();}});
document.addEventListener("click",(event)=>{if(activeFlowId!=="UIF-14")return;const runBtn=event.target.closest("[data-val14-run]");if(runBtn){event.preventDefault();val14SelectedRunId=runBtn.dataset.val14Run;const r=val14Current();if(r.status==="DIRTY"){val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope="Sản phẩm cần tính lại";val14SuccessorOf=r.id;return navigate("SCR-073");}stateByScreen["SCR-074"]=r.status==="BLOCKED"?"BLOCKED":"READY";return navigate("SCR-074");}const kind=event.target.closest("[data-val14-kind]");if(kind){event.preventDefault();val14SetupKind=kind.dataset.val14Kind;val14SetupScope=val14SetupKind==="PERIOD_CLOSE"?"Toàn bộ sản phẩm":"Sản phẩm cần tính lại";return renderAppScreen();}const action=event.target.closest("[data-val14-action]");if(!action||action.disabled)return;event.preventDefault();const k=action.dataset.val14Action;if(k==="new-run"){val14SuccessorOf=null;val14SetupKind="PERIOD_CLOSE";val14SetupScope="Toàn bộ sản phẩm";return navigate("SCR-073");}if(k==="calculate"){val14CreateRun();stateByScreen["SCR-074"]="READY";return navigate("SCR-074");}if(k==="review-publish"){const r=val14Current();if(r.status!=="READY_FOR_REVIEW")return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);stateByScreen["SCR-076"]="READY";return navigate("SCR-076");}if(k==="successor"){const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scope.includes("sản phẩm")?"Sản phẩm cần tính lại":"Toàn bộ sản phẩm";return navigate("SCR-073");}if(k==="publish"){const r=val14Current();if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){stateByScreen["SCR-076"]="SOURCE_CHANGED";return renderAppScreen();}val14Commit();stateByScreen["SCR-077"]="COMPLETED";return navigate("SCR-077");}if(k==="result-to-list"){return navigate("SCR-072");}if(k==="result-to-run"||k==="retired-to-result"){stateByScreen["SCR-074"]="READY";return navigate("SCR-074");}},true);


// Inventory Operations interactions — UIF-07 (BJ-06 ở app/bj06.js).
document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-07" && event.target.matches("[data-io07-search]")){io07Query=event.target.value;ioFilterRows("io07",io07Query);return;}
  if(activeFlowId==="UIF-07" && event.target.matches("[data-io07-scan-lot]")){io07ScanLot=event.target.value;const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;const expected=f.group.tracking==="LOT"?String(f.allocation.lot||""):"";const mismatch=Boolean(expected&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expected.toLocaleUpperCase("vi"));const feedback=document.querySelector("[data-io07-scan-feedback]");if(feedback)feedback.innerHTML=mismatch?vBanner("error","Lô không khớp",`Cần lô ${expected}. Kho không thay lô tại đây.`,"","Compact"):"";const b=document.querySelector('[data-io07-action="confirm-allocation"]');if(b)b.disabled=mismatch;return;}
});
document.addEventListener("click",(event)=>{
  if(activeFlowId!=="UIF-07") return;

  const f7=event.target.closest("[data-io07-filter]");if(f7){event.preventDefault();io07QueueFilter=f7.dataset.io07Filter;return renderAppScreen();}
  const r7=event.target.closest("[data-io07-request]");if(r7){event.preventDefault();io07Selected=r7.dataset.io07Request;const req=io07Current();if(req.queue==="WAITING"||req.closed||req.completed)return;io07VerifySheetOpen=false;io07ActiveAllocationId="";stateByScreen["SCR-037"]=req.changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}
  const allocation7=event.target.closest("[data-io07-allocation]");if(allocation7){event.preventDefault();io07OpenVerification(allocation7.dataset.io07Allocation);return renderAppScreen();}
  if(event.target.matches("[data-io07-verify-backdrop]")){event.preventDefault();io07VerifySheetOpen=false;io07ScanLot="";return renderAppScreen();}

  const a=event.target.closest("[data-io07-action]");if(!a)return;
  event.preventDefault();event.stopPropagation();
  const k=a.dataset.io07Action;
  if(k==="review-handover"){const req=io07Current();if(!io07AllVerified(req)||io07HasMismatch(req))return;req.reviewSourceVersion=req.sourceVersion;stateByScreen["SCR-039"]="READY";return navigate("SCR-039");}
  if(k==="close-verification"){io07VerifySheetOpen=false;io07ScanLot="";return renderAppScreen();}
  if(k==="confirm-allocation"){const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;const expected=f.group.tracking==="LOT"?String(f.allocation.lot||""):"";if(expected&&io07ScanLot.trim()&&io07ScanLot.trim().toLocaleUpperCase("vi")!==expected.toLocaleUpperCase("vi"))return;f.allocation.verified=true;f.allocation.physicalMismatch=false;f.allocation.affectedByChange=false;f.allocation.verifyMethod=io07ScanLot.trim()?"SCAN_OR_TYPED_MATCH":"VISUAL";io07VerifySheetOpen=false;io07ScanLot="";stateByScreen["SCR-037"]="READY";return renderAppScreen();}
  if(k==="mark-mismatch"){const f=io07FindAllocation(io07ActiveAllocationId);if(!f)return;f.allocation.verified=false;f.allocation.physicalMismatch=true;io07VerifySheetOpen=false;io07ScanLot="";stateByScreen["SCR-037"]="PHYSICAL_MISMATCH";return renderAppScreen();}
  if(k==="back-to-preparation"){io07VerifySheetOpen=false;stateByScreen["SCR-037"]=io07Current().changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}
  if(k==="confirm-handover"){const req=io07Current();if(Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion)){stateByScreen["SCR-039"]="SOURCE_CHANGED";return renderAppScreen();}if(!io07AllVerified(req)||io07HasMismatch(req))return;io07CreateResult(req);req.completed=true;req.queue="CLOSED";stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
  if(k==="result-to-rtv-queue"){io07QueueFilter="ALL";io07Query="";io07VerifySheetOpen=false;return navigate("SCR-036");}
  if(k==="back-to-rtv-request"){const req=io07Current();if(req.closed||req.completed)return navigate("SCR-036");stateByScreen["SCR-037"]=req.changed?"SOURCE_UPDATED":"READY";return navigate("SCR-037");}

},true);


// v1.8.0 — targeted interactions for UIF12 / UIF15. No backend calls are simulated.
document.addEventListener("input",(event)=>{
  if(activeFlowId==="UIF-12"){
    if(event.target.matches("[data-cf12-cutoff]")){cf12Cutoff=event.target.value;return;}
    if(event.target.matches("[data-cf12-control-qty]")){cf12ControlQty=event.target.value;return;}
    if(event.target.matches("[data-cf12-control-value]")){cf12ControlValue=String(event.target.value||"").replace(/[^0-9-]/g,"");return;}
    if(event.target.matches("[data-cf12-reject-reason]")){
      cf12RejectReason=event.target.value;
      const b=document.querySelector('[data-cf12-action="confirm-reject"]'); if(b)b.disabled=!cf12RejectReason.trim();
      return;
    }
  }
  if(activeFlowId==="UIF-15"){
    if(event.target.matches("[data-cf15-from]")){cf15From=event.target.value;return;}
    if(event.target.matches("[data-cf15-to]")){cf15To=event.target.value;return;}
  }
},true);

document.addEventListener("change",(event)=>{
  if(activeFlowId!=="UIF-15")return;
  if(event.target.matches("[data-cf15-warehouse]")){cf15Warehouse=event.target.value;return;}
  if(event.target.matches("[data-cf15-product]")){cf15Product=event.target.value;if(cf15Product!=="ALL")cf15SelectedProduct=cf15Product;return;}
},true);

document.addEventListener("click",(event)=>{
  if(activeFlowId==="UIF-12"){
    const a=event.target.closest("[data-cf12-action]"); if(!a||a.disabled)return;
    event.preventDefault(); event.stopPropagation(); const k=a.dataset.cf12Action;
    if(k==="start"||k==="continue-prepare"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="choose-file"){cf12FileName="ton-kho-dau-ky-2026.xlsx";stateByScreen["SCR-067"]="READY";return renderAppScreen();}
    if(k==="check"){
      const valid=Boolean(cf12FileName&&cf12Cutoff&&cf12ControlQty!==""&&cf12ControlValue!==""&&Number(cf12ControlQty)>=0&&Number(cf12ControlValue)>=0);
      if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-068"]="READY";return navigate("SCR-068");
    }
    if(k==="back-file"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="review"){stateByScreen["SCR-069"]="READY";return navigate("SCR-069");}
    if(k==="back-check"){stateByScreen["SCR-068"]="READY";return navigate("SCR-068");}
    if(k==="send-approval"){stateByScreen["SCR-069"]="PENDING_APPROVAL";stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
    if(k==="fix-rejected"){stateByScreen["SCR-067"]="READY";return navigate("SCR-067");}
    if(k==="open-reject"){cf12RejectOpen=true;cf12RejectReason="";return renderAppScreen();}
    if(k==="close-reject"){cf12RejectOpen=false;cf12RejectReason="";return renderAppScreen();}
    if(k==="confirm-reject"){
      if(!cf12RejectReason.trim())return;
      cf12RejectOpen=false;stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";return renderAppScreen();
    }
    if(k==="approve"){
      cf12RejectOpen=false;stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");
      window.setTimeout(()=>{if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";render();}},420);
      return;
    }
    if(k==="result-home"){return navigate("SCR-066");}
    if(k==="see-inventory"){
      activeFlowId="UIF-01";activeScreenId="SCR-001";stateByScreen["SCR-001"]="READY";syncReviewUrl();return render();
    }
  }
  if(activeFlowId==="UIF-15"){
    const rt=event.target.closest("[data-cf15-report-type]"); if(rt){event.preventDefault();cf15ReportType=rt.dataset.cf15ReportType;if(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL"){cf15Product=cf15SelectedProduct;}stateByScreen["SCR-054"]="READY";return renderAppScreen();}
    const dm=event.target.closest("[data-cf15-date-mode]"); if(dm){event.preventDefault();cf15DateMode=dm.dataset.cf15DateMode;stateByScreen["SCR-054"]="READY";return renderAppScreen();}
    const pr=event.target.closest("[data-cf15-product-row]"); if(pr){event.preventDefault();cf15SelectedProduct=pr.dataset.cf15ProductRow;cf15ProductSheetOpen=true;return renderAppScreen();}
    const mv=event.target.closest("[data-cf15-movement]"); if(mv){event.preventDefault();cf15SelectedMovement=mv.dataset.cf15Movement;stateByScreen["SCR-056"]="READY";return navigate("SCR-056");}
    const action=event.target.closest("[data-cf15-action]"); if(!action||action.disabled)return;
    event.preventDefault();event.stopPropagation();const k=action.dataset.cf15Action;
    if(k==="query"){
      if(!cf15From||!cf15To||cfDateKey(cf15From)>cfDateKey(cf15To)||(cf15ReportType==="STOCK_CARD"&&cf15Product==="ALL")){stateByScreen["SCR-054"]="VALIDATION_ERROR";return renderAppScreen();}
      cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return navigate("SCR-055");
    }
    if(k==="close-product-sheet"){cf15ProductSheetOpen=false;return renderAppScreen();}
    if(k==="product-stock-card"){
      const id=action.dataset.cf15ProductId||cf15SelectedProduct;cf15ReportType="STOCK_CARD";cf15Product=id;cf15SelectedProduct=id;cf15ProductSheetOpen=false;stateByScreen["SCR-055"]="READY";return renderAppScreen();
    }
    if(k==="source"){stateByScreen["SCR-057"]="READY";return navigate("SCR-057");}
    if(k==="export"||k==="export-source"){
      cf15ExportFrom=k==="export-source"?"SOURCE":"REPORT";cf15FinanceIncluded=stateByScreen[activeScreenId]!=="FINANCIAL_RESTRICTED";stateByScreen["SCR-058"]="READY";return navigate("SCR-058");
    }
    if(k==="confirm-export"){
      stateByScreen["SCR-059"]="PROCESSING";navigate("SCR-059");window.setTimeout(()=>{if(activeFlowId==="UIF-15"&&activeScreenId==="SCR-059"&&stateByScreen["SCR-059"]==="PROCESSING"){stateByScreen["SCR-059"]="COMPLETED";render();}},320);return;
    }
    if(k==="done-export"){stateByScreen[cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055"]="READY";return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
  }
  const customBack=event.target.closest('[data-action="cf15-back-export"]');
  if(customBack&&activeFlowId==="UIF-15"){event.preventDefault();event.stopPropagation();return navigate(cf15ExportFrom==="SOURCE"?"SCR-057":"SCR-055");}
},true);

const flowSelectorEl=document.getElementById("flow-selector");
flowSelectorEl?.addEventListener("change",(e)=>{activeFlowId=e.target.value; const f=activeFlow(); activeScreenId=f.screens[0]; syncReviewUrl(); render();});
document.addEventListener("click",(e)=>{
  const next=e.target.closest("[data-generic-next]"); if(next){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); else showToast("Đã hoàn thành flow demo", "checkCircle"); }
  const act=e.target.closest("[data-generic-action]"); if(act){ showToast(`${act.textContent.trim()} · prototype không gọi backend`, "checkCircle"); }
  const card=e.target.closest(".generic-data-card[data-ds-profile='card.interactive']"); if(card&&!inspectEnabled){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); }
});
render();

function fitReviewDeviceToViewport() {
  const device = document.getElementById("device-preview");
  const canvas = document.querySelector(".stage-canvas");
  if (!device || !canvas) return;
  if (window.innerWidth <= 840 || device.classList.contains("is-wide")) {
    device.style.setProperty("--vet45-review-scale", "1");
    return;
  }
  const canvasRect = canvas.getBoundingClientRect();
  const canvasStyle = getComputedStyle(canvas);
  const padTop = parseFloat(canvasStyle.paddingTop) || 0;
  const padLeft = parseFloat(canvasStyle.paddingLeft) || 0;
  const padRight = parseFloat(canvasStyle.paddingRight) || 0;
  const deviceTop = canvasRect.top + padTop;
  const availableHeight = Math.max(360, window.innerHeight - deviceTop - 8);
  const availableWidth = Math.max(240, canvas.clientWidth - padLeft - padRight);
  const scale = Math.min(1, availableHeight / 890, availableWidth / 418);
  device.style.setProperty("--vet45-review-scale", String(scale));
}
window.addEventListener("resize", fitReviewDeviceToViewport);
requestAnimationFrame(fitReviewDeviceToViewport);

window.__VET45_PROTOTYPE__ = {
  productKind: "mobile_app",
  version: "3.6.0",
  defaultViewport: { width: 402, height: 874 },
  offline: true,
  uiFlows: flowCatalog.map((f) => f.id),
  screens: screens.map((s) => s.id),
  roles: [...new Set(screens.flatMap((s) => s.actors || []))],
  states: [...new Set(screens.flatMap((s) => s.states || []))],
  scenarios: ["canonical", "document-receipt", "quick-receipt", "source-waiting", "stale-recovery", "partial-handover", "permission-denied"],
  devicePresets: [{ id: "iphone-402", kind: "mobile", width: 402, height: 874 }],
  inspect: { enabled: true, selectable: true }
};
if (initialParams.get("inspect") === "1") toggleInspect(true);

/* ===== v310-audit-control-cluster.js ===== */
/* VET45 Theme 7 v3.1.0 — Inventory Audit & Control cluster
 * Scope: BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17.
 * Figma DS is UI authority. Existing app.js remains business/state authority.
 * This patch only replaces presentation renderers and preserves existing handlers/data.
 */

const AC310_SCREEN_IDS = [
  "SCR-036","SCR-037","SCR-038","SCR-040","SCR-041","SCR-042","SCR-043","SCR-044","SCR-045","SCR-046","SCR-047",
  "SCR-048","SCR-049","SCR-050","SCR-051","SCR-052","SCR-053",
  "SCR-054","SCR-055","SCR-056","SCR-057","SCR-058","SCR-059",
  "SCR-066","SCR-067","SCR-068","SCR-069","SCR-070","SCR-071",
  "SCR-078","SCR-079","SCR-080","SCR-081","SCR-082","SCR-083"
];
const ac310BaseRenderers = Object.fromEntries(AC310_SCREEN_IDS.map((id)=>[id, renderers[id]]));

function ac310Tone(tone="Neutral") {
  const map={success:"Success",warning:"Warning",danger:"Danger",error:"Danger",info:"Info",neutral:"Neutral",brand:"Brand"};
  return map[String(tone).toLowerCase()] || tone;
}
function ac310CleanText(text) {
  let out=String(text??"");
  const replacements=[
    [/\bauthoritative\b/gi,"chính thức"],
    [/\bDOM\b/g,"giao diện"],
    [/\bguard\b/gi,"điều kiện kiểm soát"],
    [/\bledger\b/gi,"sổ kho"],
    [/\brecovery\b/gi,"khôi phục"],
    [/\bcommit\b/gi,"ghi nhận"],
    [/\bUNKNOWN\b/g,"chưa xác định"],
    [/\bCut[- ]?off\b/gi,"Thời điểm chốt"],
    [/\bLOT\b/g,"Lô"],
    [/\bUOM\b/g,"Đơn vị"],
    [/\bblocker\b/gi,"điều kiện chưa đạt"],
    [/\bdependency\b/gi,"nghiệp vụ phụ thuộc"],
    [/\bprojection\b/gi,"số liệu hiển thị"],
    [/\bfinality\b/gi,"kết quả chính thức"]
  ];
  replacements.forEach(([re,val])=>{out=out.replace(re,val);});
  return out;
}
function ac310SanitizeMarkup(html) {
  const template=document.createElement("template");
  template.innerHTML=String(html||"");
  const walker=document.createTreeWalker(template.content,NodeFilter.SHOW_TEXT);
  const nodes=[]; while(walker.nextNode()) nodes.push(walker.currentNode);
  nodes.forEach((node)=>{node.nodeValue=ac310CleanText(node.nodeValue);});
  return template.innerHTML;
}
function ac310Base(id,state){
  const fn=ac310BaseRenderers[id];
  return ac310SanitizeMarkup(fn?fn(state):renderGeneric(screens.find((s)=>s.id===id),state));
}
function ac310Return(html){return ac310SanitizeMarkup(html);}
function ac310SectionTitle(title,meta=""){
  return `<div class="ac310-section-title" data-ds-component="VText"><h2>${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:""}</div>`;
}
function ac310InfoSurface(title,rows,{extraClass="",badge="",badgeTone="Neutral"}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2>${badge?ds24Badge(badge,ac310Tone(badgeTone)):""}</div>`:"";
  const body=(rows||[]).map((r)=>ds24InfoRow(r[0],r[1],r[2]?"ac310-info-row--emphasis":"")).join("");
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Info Row${badge?',VBadge':''}">${head}<div class="ac310-info-rows">${body}</div></section>`;
}
function ac310KeyValueSurface(title,rows,{extraClass=""}={}){
  const head=title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:"";
  return `<section class="ac310-surface ${extraClass}" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / Key-value Row">${head}<div class="ac310-key-value-stack">${(rows||[]).map((r)=>ds24KeyValueRow(r[0],r[1],!!r[2])).join("")}</div></section>`;
}
function ac310RecordRow({title,subtitle="",badge="",tone="Neutral",attrs="",leading=null,status=false,disabled=false,extraClass=""}){
  return ds24ListRow({title,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading,attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,disabled,extraClass:`ac310-record-row ${extraClass}`.trim()});
}
function ac310ProductRow({name,code,meta="",badge="",tone="Neutral",attrs="",status=false}){
  const subtitle=[code,meta].filter(Boolean).join(" · ");
  return ds24ListRow({title:name,subtitle,trailing:badge?ds24Badge(badge,ac310Tone(tone)):"",leading:"package",attrs,type:status?"Status":"Navigation",density:status?"Compact":"Default",interactive:!status,extraClass:"ac310-product-row"});
}
function ac310ListSurface(rows,extra=""){
  return ds24GroupedCollection(`<div class="ac310-list-stack">${rows}</div>`,`ac310-list-surface ${extra}`,"DS v2 / List Row,VBadge");
}
function ac310RadioChoice({value,label,detail="",checked=false,attrs="",disabled=false}){
  return `<label class="ac310-radio-row${disabled?' is-disabled':''}" data-ds-component="VRadio" data-figma-node="522:7410"><input type="radio" value="${escapeAttribute(value)}" ${attrs} ${checked?'checked':''} ${disabled?'disabled':''}><span class="ac310-radio-control" aria-hidden="true"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong>${detail?`<small>${esc(detail)}</small>`:""}</span></label>`;
}
function ac310RadioSurface(title,choices){
  return `<section class="ac310-surface ac310-radio-surface" data-composed-from="VText,VRadio">${title?`<div class="ac310-surface__head"><h2>${esc(title)}</h2></div>`:""}<div class="ac310-radio-list">${choices.join("")}</div></section>`;
}
function ac310AuditItem(type,title,meta){
  const t=String(type||"System");
  const iconName=t==="Create"?"checkCircle":t==="Update"?"edit":t==="Delete"?"alert":"info";
  return `<div class="ac310-audit-item ac310-audit-item--${t.toLowerCase()}" data-ds-component="DS v2 / Audit Item" data-figma-node="525:621" data-ds-prop-type="${t}">${icon(iconName,"ac310-audit-item__icon")}<span class="ac310-audit-item__copy"><strong>${esc(title)}</strong><small>${esc(meta)}</small></span></div>`;
}
function ac310AuditSurface(title,items){
  return `<section class="ac310-audit-surface" data-composed-from="DS v2 / Audit Item">${title?ac310SectionTitle(title):""}<div class="ac310-audit-list">${items.join("")}</div></section>`;
}
function ac310Field(label,value,attrs="",helper="",type="text"){
  const component=type==="number"?"VNumberField":type==="date"?"VDateField":"VTextField";
  return `<label class="ac310-field" data-ds-component="${component}"><span>${esc(label)}</span><input type="${type}" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function ac310Textarea(label,value,attrs="",helper=""){
  return `<label class="ac310-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}</span><textarea ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:""}</label>`;
}
function ac310FileDrop(title,fileName,attrs=""){
  return `<section class="ac310-file-drop" data-ds-component="VFileDropZone"><div class="ac310-file-drop__icon">${icon("fileText")}</div><div class="ac310-file-drop__copy"><strong>${esc(title)}</strong><small>${esc(fileName||"Chưa chọn tệp")}</small></div><button type="button" class="button button--secondary" ${attrs} data-ds-component="VButton">Chọn tệp</button></section>`;
}
function ac310ApprovalFooter(rejectAttr,approveAttr,approveLabel="Duyệt"){
  return `<footer class="app-actions figma-sticky-footer ac310-two-actions" data-ds-pattern="Sticky Footer"><button class="button button--secondary" type="button" ${rejectAttr} data-ds-component="VButton">Từ chối</button><button class="button button--primary" type="button" ${approveAttr} data-ds-component="VButton">${esc(approveLabel)}</button></footer>`;
}
function ac310SummaryMetrics(items){
  return `<section class="ac310-metrics" data-composed-from="DS v2 / Metric Card">${items.map(([label,value])=>`<div class="ac310-metric" data-ds-component="DS v2 / Metric Card" data-figma-node="525:382"><span>${esc(label)}</span><strong>${esc(String(value))}</strong></div>`).join("")}</section>`;
}
function ac310Result(title,desc,rows,tone="success"){
  return ioResult(title,desc,rows,tone);
}

/* ------------------------------ BJ08 ----------------------------------- */
function ac310Render042(state){
  if(!["READY","PENDING_APPROVAL"].includes(state)) return ac310Base("SCR-042",state);
  if(state==="PENDING_APPROVAL"){
    return ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("info","Đã gửi chờ duyệt","Kết quả đếm lại đã được gửi sang công việc duyệt độc lập. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Chờ duyệt"]])}`,back:false}));
  }
  const chips=`<div class="ds24-chip-scroll">${ds24Chip("ALL","Tất cả",true,"data-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",false,"data-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",false,"data-ic08-filter")}</div>`;
  const row=ac310RecordRow({title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",attrs:'data-ic08-action="resume"',leading:null});
  const session=`${ac310ListSurface(row,"ac310-count-session-list")}<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`;
  return ac310Return(appShell({title:"Kiểm kê kho",body:`${ds24Search("","","Tìm phiên kiểm kê")}${chips}${ac310SectionTitle("Phiên đang thực hiện","1 phiên")}${session}${ic08Overlays()}`,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
}
function ac310Render043(state){
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-043",state);
  const validation=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn phạm vi và nhập lý do kiểm kê trước khi mở phiên."):"";
  const scopeOptions=[["ALL","Toàn kho"],["PRODUCT","Sản phẩm"],["GROUP","Nhóm sản phẩm"],["LOT","Lô"]];
  const target=ic08Scope!=="ALL"?`<div class="ds24-field"><span class="vet45-text-style-8">${ic08Scope==="PRODUCT"?"Sản phẩm":ic08Scope==="GROUP"?"Nhóm sản phẩm":"Lô"}</span><button type="button" class="ds24-field__control ds24-select-trigger" data-ic08-action="scope-select-open"><span>${esc(ic08ScopeTarget||"Chọn phạm vi")}</span>${icon("chevronRight","icon--sm")}</button></div>`:"";
  const body=`${validation}${ac310InfoSurface("Thông tin phiên",[["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"],["Người đếm",ic08AssignedCounter]])}<div class="ac310-form-stack">${ds24SelectField("Phạm vi",ic08Scope,scopeOptions,"data-ic08-scope")}${target}${ds24TextField("Lý do kiểm kê",ic08Reason,"data-ic08-reason","")}</div>${vBanner("info","Phạm vi sẽ được khóa","Sau khi mở phiên, phạm vi và thời điểm chốt được giữ nguyên cho lần kiểm kê này.")}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Tạo phiên kiểm kê",body,actions:primaryFooter("Mở phiên kiểm kê",'data-ic08-action="open-session"',ic08Scope!=="ALL"&&!ic08ScopeTarget)}));
}
function ac310CountGroup({id,name,code,lot,uom,value,unexpected=false,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`${lot?`Lô ${lot} · `:""}${uom}`,badge:unexpected?"Bổ sung thực tế":"Cần đếm",tone:unexpected?"Info":"Neutral",status:true});
  return `<section class="ac310-product-control-group" data-composed-from="DS v2 / List Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ic08QuantityTrigger("Số lượng thực tế",value,`count:${id}`,uom,disabled)}</div></section>`;
}
function ac310RecountGroup({id,name,code,lot,uom,book,first,variance,value,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`Lô ${lot} · ${uom}`,badge:variance,tone:"Warning",status:true});
  return `<section class="ac310-product-control-group" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ac310KeyValueSurface("",[["Theo sổ",`${book} ${uom}`],["Lần đếm đầu",`${first} ${uom}`],["Chênh lệch",variance,true]],{extraClass:"ac310-inline-surface"})}${ic08QuantityTrigger("Số lượng đếm lại",value,`recount:${id}`,uom,disabled)}</div></section>`;
}
function ac310Render044(state){
  if(!["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac310Base("SCR-044",state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}${ac310SectionTitle("Hàng cần đếm",`${groups.length} dòng`)}<div class="ac310-product-control-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}
function ac310Render045(state){
  if(!["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-045",state);
  const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
  const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ. Phiên vẫn được giữ khóa."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Kiểm tra số lượng đếm lại trước khi gửi."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
  const groups=[ac310RecountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",book:20,first:18,variance:"−2 hộp",value:ic08Recounts.amox,disabled:locked}),ac310RecountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",book:6,first:7,variance:"+1 hộp",value:ic08Recounts.glove,disabled:locked})];
  const evidenceRows=[["Amox 500","Đã có bằng chứng"],["Găng tay M",price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã có căn cứ"]];
  const body=`${notice}<div class="ac310-product-control-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${(price||evidence)?vBanner("warning","Chưa thể gửi duyệt","Chỉ có thể gửi khi tất cả căn cứ bắt buộc đã hợp lệ."):""}${ic08Overlays()}`;
  let actions=""; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`:""}</footer>`;
  return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
}
function ac310Render046(state){
  if(!["READY","APPROVAL_REVIEW"].includes(state)) return ac310Base("SCR-046",state);
  const body=`${vBanner("info","Cần quyết định độc lập","Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng chênh lệch","2 dòng"]])}${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · hộp",badge:"−2 hộp",tone:"Warning",status:true})}${ac310KeyValueSurface("",[["Đếm lại","18 hộp"],["Bằng chứng","Đã đủ"]],{extraClass:"ac310-approval-detail"})}${ac310ProductRow({name:"Găng tay M",code:"SP-00410",meta:"Lô L2405-M · hộp",badge:"+1 hộp",tone:"Warning",status:true})}${ac310KeyValueSurface("",[["Đếm lại","7 hộp"],["Căn cứ giá","Đã đủ"],["Bằng chứng","Đã đủ"]],{extraClass:"ac310-approval-detail"})}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-ic08-action="request-review" data-ds-component="VButton">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-ic08-action="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button></footer>`;
  return ac310Return(appShell({title:"Duyệt kết quả kiểm kê",body,actions,back:false}));
}

/* ------------------------------ BJ09 ----------------------------------- */
function ac310Render036(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","FILTER_EMPTY"].includes(state)) return ac310Base("SCR-036",state);
    const labels=[["ALL","Tất cả"],["SELLABLE","Bán được"],["QUARANTINE","Cách ly"],["DAMAGED","Hỏng"],["DEMO","Dùng thử"],["EXPIRED","Hết hạn"]];
    const q=ic09Query.trim().toLowerCase();
    const items=ic09Items.filter((x)=>(ic09Filter==="ALL"||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
    const rows=items.map((x)=>ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:x.label,tone:ic09StatusTone(x.state),attrs:`data-ic09-item="${x.id}"`})).join("");
    const body=`${ds24Search(ic09Query,"data-ic09-search","Tìm sản phẩm hoặc lô")}<div class="ds24-chip-scroll">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,"data-ic09-filter")).join("")}</div>${rows?ac310ListSurface(rows):ioEmpty("Không có hàng phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
    return ac310Return(appShell({title:"Tình trạng hàng",body,back:false}));
  }
  if(activeFlowId==="UIF-10"){
    if(state!=="READY") return ac310Base("SCR-036",state);
    const rows=`${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",attrs:'data-ic10-item="amox-l2407"'})}${ac310ProductRow({name:"Vitamin C",code:"SP-00231",meta:"Lô L2310-C · 4 hộp",badge:"Hết hạn",tone:"Danger",attrs:'data-ic10-item="vitc-l2310"'})}`;
    return ac310Return(appShell({title:"Hàng có thể xử lý",body:`${vBanner("info","Chỉ hiển thị hàng đủ điều kiện","Hàng đang bán được cần đổi tình trạng trước khi có thể đề nghị tiêu hủy.")}${ac310ListSurface(rows)}`,back:false}));
  }
  return ac310Base("SCR-036",state);
}
function ac310Render037(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","EXPIRED","LOCKED"].includes(state)) return ac310Base("SCR-037",state);
    const x=ic09Current(),expired=state==="EXPIRED"||x.state==="EXPIRED",locked=state==="LOCKED";
    const notice=expired?vBanner("warning","Lô đã hết hạn","Lượng hàng này tự động không còn khả dụng bán theo hạn dùng."):locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):"";
    const body=`${notice}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:expired?"Hết hạn":x.label,tone:ic09StatusTone(expired?"EXPIRED":x.state),status:true})}${ac310KeyValueSurface("Thông tin",[["Hạn dùng",x.expiry],["Tồn vật lý",`${x.qty} ${x.uom}`],["Khả dụng bán",expired||x.state!=="SELLABLE"?`0 ${x.uom}`:`${x.qty} ${x.uom}`]])}<p class="ac310-note">Thay đổi tình trạng chỉ phân loại lại cùng lượng hàng; tổng tồn vật lý và giá trị không đổi.</p><button class="button button--secondary ac310-inline-button" type="button" data-ic09-action="history" data-ds-component="VButton">Xem lịch sử</button>`;
    return ac310Return(appShell({title:"Chi tiết tình trạng hàng",body,actions:locked||expired?"":primaryFooter("Thay đổi tình trạng",'data-ic09-action="change"')}));
  }
  if(activeFlowId==="UIF-10"){
    if(!["READY","LOCKED"].includes(state)) return ac310Base("SCR-037",state);
    const locked=state==="LOCKED";
    const body=`${locked?vBanner("info","Đang thuộc phạm vi kiểm kê","Thông tin chỉ đọc cho đến khi phiên kiểm kê kết thúc."):""}${ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",status:true})}${ac310KeyValueSurface("Thông tin",[["Tồn vật lý","6 hộp"],["Quyền sở hữu","Hàng của tổ chức"],["Có thể xử lý","6 hộp"]])}<p class="ac310-note">Duyệt yêu cầu chưa làm giảm tồn. Tồn chỉ giảm sau khi xác nhận lượng đã tiêu hủy thực tế.</p>`;
    return ac310Return(appShell({title:"Chi tiết hàng",body,actions:locked?"":primaryFooter("Đề nghị tiêu hủy",'data-ic10-action="request"')}));
  }
  return ac310Base("SCR-037",state);
}
function ac310StateLabel(value){return value==="QUARANTINE"?"Cách ly":value==="DAMAGED"?"Hỏng":value==="DEMO"?"Dùng thử":"Bán được";}
function ac310Render038(state){
  if(activeFlowId!=="UIF-09") return ac310Base("SCR-038",state);
  if(state==="APPROVAL_REVIEW"){
    const x=ic09Current();
    const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định.")}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:`${x.label} → ${ac310StateLabel(ic09Destination)}`,tone:"Info",status:true})}${ac310InfoSurface("Nội dung yêu cầu",[["Tình trạng hiện tại",x.label],["Tình trạng mới",ac310StateLabel(ic09Destination)],["Lý do","Bao bì có dấu hiệu bất thường"]])}`;
    return ac310Return(appShell({title:"Duyệt thay đổi tình trạng",body,actions:ac310ApprovalFooter('data-ic09-action="reject"','data-ic09-action="approve"'),back:false}));
  }
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-038",state);
  const x=ic09Current();
  const choices=[ac310RadioChoice({value:"QUARANTINE",label:"Cách ly",detail:"Tạm thời không bán",checked:ic09Destination==="QUARANTINE",attrs:'name="ic-state" data-ic09-destination'}),ac310RadioChoice({value:"DAMAGED",label:"Hỏng",detail:"Không còn đủ điều kiện bán",checked:ic09Destination==="DAMAGED",attrs:'name="ic-state" data-ic09-destination'}),ac310RadioChoice({value:"DEMO",label:"Dùng thử",detail:"Chuyển sang mục đích dùng thử",checked:ic09Destination==="DEMO",attrs:'name="ic-state" data-ic09-destination'})];
  if(x.state!=="SELLABLE") choices.push(ac310RadioChoice({value:"SELLABLE",label:"Bán được",detail:"Chỉ khi hàng đủ điều kiện trở lại bán",checked:ic09Destination==="SELLABLE",attrs:'name="ic-state" data-ic09-destination'}));
  const body=`${state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng mới và nhập lý do phù hợp."):""}${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot} · ${x.qty} ${x.uom}`,badge:x.label,tone:ic09StatusTone(x.state),status:true})}${ac310RadioSurface("Tình trạng mới",choices)}${ac310Textarea("Lý do","Bao bì có dấu hiệu bất thường",'data-ic09-reason',"")}`;
  return ac310Return(appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-ic09-action="submit"')}));
}
function ac310Render041(state){
  if(activeFlowId==="UIF-09"||activeFlowId==="UIF-10") return ac310Base("SCR-041",state);
  return ac310Base("SCR-041",state);
}
function ac310Render056(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","LOADING","PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-056",state);
    if(state!=="READY") return ac310Base("SCR-056",state);
    const x=ic09Current();
    const body=`${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot}`,badge:x.label,tone:ic09StatusTone(x.state),status:true})}${ac310AuditSurface("Lịch sử",[ac310AuditItem("Update","Bán được → Cách ly","07/09/2026 · 09:14 · Nguyễn An · Bao bì có dấu hiệu bất thường"),ac310AuditItem("Create","Nhận vào kho","01/09/2026 · 08:00 · Tình trạng ban đầu: Bán được")])}`;
    return ac310Return(appShell({title:"Lịch sử tình trạng",body}));
  }
  if(activeFlowId==="UIF-15") return ac310Render056CF15(state);
  return ac310Base("SCR-056",state);
}

/* ------------------------------ BJ10 ----------------------------------- */
function ac310Render040(state){
  if(activeFlowId!=="UIF-10") return ac310Base("SCR-040",state);
  if(["PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-040",state);
  const product=ac310ProductRow({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · 6 hộp",badge:"Cách ly",tone:"Warning",status:true});
  if(state==="PENDING_APPROVAL") return ac310Return(appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Tồn kho chưa thay đổi. Người duyệt nhận một công việc riêng.")}${product}${ac310InfoSurface("Yêu cầu",[["Số lượng đề nghị","6 hộp",true],["Tác động tồn kho","Chưa có"]])}`,back:false}));
  if(state==="APPROVAL_REVIEW") return ac310Return(appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển sang chờ xử lý thực tế. Tồn vật lý chưa giảm.")}${product}${ac310InfoSurface("Nội dung yêu cầu",[["Số lượng đề nghị","6 hộp",true],["Căn cứ giá","Giá vốn hiện hành"],["Lý do","Hàng không còn đủ điều kiện sử dụng"]])}`,actions:ac310ApprovalFooter('data-ic10-action="reject"','data-ic10-action="approve"'),back:false}));
  if(state==="APPROVED_PENDING_DISPOSAL") return ac310Return(appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Tồn kho vẫn giữ nguyên cho tới khi có xác nhận đã tiêu hủy.")}${product}${ac310InfoSurface("Trạng thái",[["Đã duyệt","6 hộp",true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false}));
  const completion=state==="COMPLETION"||state==="COMPLETION_QTY_BLOCKED";
  const priceBlocked=state==="PRICE_BASIS_REQUIRED";
  const banner=completion?(state==="COMPLETION_QTY_BLOCKED"?vBanner("error","Số lượng thực tế vượt phạm vi được duyệt","Không thể ghi giảm phần vượt."):vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng xác nhận sẽ là căn cứ ghi giảm tồn.")):priceBlocked?vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu cho tới khi có căn cứ giá chính thức."):"";
  const fields=completion?`${ac310Field("Đã tiêu hủy thực tế",state==="COMPLETION_QTY_BLOCKED"?"7":"6",'data-ic10-actual','',"number")}${ac310Textarea("Bằng chứng","Biên bản tiêu hủy #TH-0709",'data-ic10-proof')}`:`${ac310Field("Số lượng đề nghị","6",'data-ic10-qty','',"number")}${ac310Textarea("Lý do","Hàng không còn đủ điều kiện sử dụng",'data-ic10-reason')}${!priceBlocked?ac310Textarea("Bằng chứng","Ảnh hiện trạng và biên bản kiểm tra",'data-ic10-evidence'):""}`;
  const body=`${banner}${product}${ac310InfoSurface("Thông tin xử lý",[["Có thể xử lý","6 hộp"],["Căn cứ giá",priceBlocked?"Chưa đủ":"Giá vốn hiện hành"]])}<div class="ac310-form-stack">${fields}</div>`;
  return ac310Return(appShell({title:completion?"Xác nhận đã tiêu hủy":"Yêu cầu tiêu hủy",body,actions:primaryFooter(completion?"Xác nhận đã tiêu hủy":"Gửi yêu cầu tiêu hủy",completion?'data-ic10-action="complete"':'data-ic10-action="submit"',priceBlocked||state==="COMPLETION_QTY_BLOCKED",completion?"danger":undefined),back:false}));
}

/* ------------------------------ BJ11 ----------------------------------- */
function ac310Render048(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-048",state);
  if(state!=="READY") return ac310Base("SCR-048",state);
  const labels={ALL:"Tất cả",CANCEL:"Có thể hủy",CORRECT:"Có thể sửa",UNKNOWN:"Đang xác minh"};
  const rows=cr11Operations.filter((op)=>cr11Filter==="ALL"||op.route===cr11Filter).filter((op)=>ioMatchesSearch(cr11Query,`${op.id} ${op.type} ${op.source} ${op.product}`)).map((op)=>ac310RecordRow({title:op.type,subtitle:`${op.id} · ${op.source} · ${op.product}`,badge:op.route==="PHYSICAL_RETURN_BLOCKED"?"Luồng trả hàng":op.statusLabel,tone:op.route==="UNKNOWN"||op.route==="PHYSICAL_RETURN_BLOCKED"?"Warning":"Info",attrs:`data-cr11-operation="${op.id}"`,leading:null})).join("");
  const chips=`<div class="ds24-chip-scroll">${Object.entries(labels).map(([k,l])=>ds24Chip(k,l,cr11Filter===k,"data-cr11-filter")).join("")}</div>`;
  return ac310Return(appShell({title:"Kiểm soát nghiệp vụ kho",body:`${ds24Search(cr11Query,"data-cr11-search","Tìm mã nghiệp vụ hoặc chứng từ")}${chips}${rows?ac310ListSurface(rows):ioEmpty("Không có nghiệp vụ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`,back:false}));
}
function ac310Render049(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-049",state);
  if(!["READY","CORRECTABLE","CANCELABLE","UNKNOWN","BLOCKED_PHYSICAL_HANDOVER","TERMINAL"].includes(state)) return ac310Base("SCR-049",state);
  const op=cr11Current(),routeState=state==="READY"?cr11StateFor(op):state;
  const context=`${ac310RecordRow({title:op.id,subtitle:`${op.type} · ${op.source}`,badge:op.statusLabel,tone:routeState==="UNKNOWN"?"Warning":"Info",status:true,leading:null})}${ac310InfoSurface("Thông tin nghiệp vụ",[["Kho",op.warehouse],["Hàng",op.product],["Số lượng",`${op.qty} ${op.uom}`],["Tác động",op.impact]])}`;
  if(routeState==="UNKNOWN") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Kết quả chưa xác định","Chưa hủy hoặc tạo sửa sai cho tới khi xác lập kết quả của đúng lần xử lý này.")}${context}`,actions:primaryFooter("Xác minh kết quả",'data-cr11-action="handoff-unknown"')}));
  if(routeState==="BLOCKED_PHYSICAL_HANDOVER") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("warning","Hàng đã được bàn giao thực tế","Khách trả hàng phải qua nghiệp vụ Hàng khách trả; không xử lý bằng sửa sai.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
  if(routeState==="TERMINAL") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${vBanner("info","Không còn tác động cần sửa","Nghiệp vụ đã dừng trước khi thực thi.")}${context}`,actions:primaryFooter("Về danh sách",'data-cr11-action="to-list"')}));
  if(routeState==="CANCELABLE") return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}<p class="ac310-note">Nghiệp vụ chưa thực thi nên có thể hủy mà không tạo biến động tồn kho.</p>`,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="open-cancel"',false,"danger")}));
  return ac310Return(appShell({title:"Chi tiết nghiệp vụ kho",body:`${context}${ac310AuditSurface("Dấu vết",[ac310AuditItem("Create","Nghiệp vụ gốc đã hoàn tất","01/09/2026 · Chưa có sửa sai trước đó")])}`,actions:primaryFooter("Sửa sai",'data-cr11-action="open-correction"')}));
}
function ac310Render052(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-052",state);
  if(["DEPENDENCY_BLOCKED","PERIOD_POLICY_VIOLATION","PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-052",state);
  const op=cr11Current(); const cancelMode=state==="CANCEL_UNEXECUTED"||op.route==="CANCEL";
  if(cancelMode){
    const body=`${state==="VALIDATION_ERROR"&&!cr11CancelReason.trim()?vBanner("error","Cần nhập lý do hủy","Lý do được lưu trong lịch sử kiểm soát."):""}${vBanner("info","Hủy trước khi thực thi","Tồn kho và giá trị không thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Nghiệp vụ",op.id,true],["Loại",op.type],["Chứng từ nguồn",op.source]])}${ac310Textarea("Lý do hủy",cr11CancelReason,'data-cr11-cancel-reason')}`;
    return ac310Return(appShell({title:"Hủy yêu cầu kho",body,actions:primaryFooter("Hủy yêu cầu",'data-cr11-action="confirm-cancel"',!cr11CancelReason.trim(),"danger")}));
  }
  const choices=[ac310RadioChoice({value:"DELTA",label:"Sửa phần sai",detail:"Điều chỉnh riêng phần sai và giữ nguyên phần đúng.",checked:cr11Strategy==="DELTA",attrs:'name="cr11-strategy" data-cr11-strategy'}),ac310RadioChoice({value:"FULL",label:"Hoàn nguyên và ghi lại đúng",detail:"Dùng khi toàn bộ nghiệp vụ phải được xác lập lại.",checked:cr11Strategy==="FULL",attrs:'name="cr11-strategy" data-cr11-strategy'})];
  const body=`${vBanner("info","Nghiệp vụ gốc luôn được giữ nguyên","Hệ thống tạo bản ghi sửa sai có liên kết; không xóa lịch sử đã hoàn tất.")}${ac310InfoSurface("Nghiệp vụ gốc",[["Mã",op.id,true],["Đã ghi nhận",`${op.qty} ${op.uom}`],["Kỳ gốc","Đã khóa"]])}${ac310RadioSurface("Cách sửa",choices)}`;
  return ac310Return(appShell({title:"Chọn cách sửa",body,actions:primaryFooter("Tiếp tục",'data-cr11-action="edit-correction"')}));
}
function ac310Render050(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-050",state);
  if(["PERMISSION_DENIED","SOURCE_VERSION_STALE","CONFLICT"].includes(state)) return ac310Base("SCR-050",state);
  const op=cr11Current(),delta=Number(cr11CorrectQty)-Number(op.qty);
  const body=`${state==="VALIDATION_ERROR"?vBanner("error","Kiểm tra nội dung sửa sai","Số đúng phải lớn hơn hoặc bằng 0 và cần có lý do."):""}${ac310InfoSurface("Trước khi sửa",[["Nghiệp vụ gốc",op.id,true],["Số đã ghi nhận",`${op.qty} ${op.uom}`],["Cách sửa",cr11Strategy==="DELTA"?"Sửa phần sai":"Hoàn nguyên và ghi lại đúng"]])}<div class="ac310-form-stack">${ac310Field("Số đúng",cr11CorrectQty,'data-cr11-correct-qty min="0" inputmode="decimal"','',"number")}${ac310Textarea("Lý do sửa sai",cr11CorrectionReason,'data-cr11-correction-reason')}</div>${ac310KeyValueSurface("Hệ thống tự tính",[["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}`;
  return ac310Return(appShell({title:"Nội dung sửa sai",body,actions:primaryFooter("Gửi phê duyệt",'data-cr11-action="submit-correction"',Number(cr11CorrectQty)<0||!cr11CorrectionReason.trim())}));
}
function ac310Render051(state){
  if(activeFlowId!=="UIF-11") return ac310Base("SCR-051",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-051",state);
  const op=cr11Operations[1],delta=Number(cr11CorrectQty)-Number(op.qty);
  const sheet=cr11ApprovalRejectOpen?`<div class="sheet-backdrop"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true"><div class="sheet-handle"></div><div class="sheet-title"><h3>Từ chối sửa sai</h3></div><div class="sheet-content">${state==="VALIDATION_ERROR"&&!cr11ApprovalRejectReason.trim()?vBanner("error","Cần nhập lý do từ chối","Lý do được lưu cùng quyết định."):""}${ac310Textarea("Lý do từ chối",cr11ApprovalRejectReason,'data-cr11-approval-reason')}<div class="sheet-actions"><button class="button button--secondary" type="button" data-cr11-action="reject-close">Đóng</button><button class="button button--danger" type="button" data-cr11-action="reject-confirm" ${cr11ApprovalRejectReason.trim()?"":"disabled"}>Từ chối</button></div></div></section></div>`:"";
  const body=`${vBanner("info","Công việc phê duyệt độc lập","Quyết định chỉ duyệt phương án; hệ thống tự ghi nhận sửa sai sau khi kiểm tra lại điều kiện.")}${ac310InfoSurface("Yêu cầu sửa sai",[["Nghiệp vụ gốc",op.id,true],["Người lập","Nguyễn An"],["Lý do",cr11CorrectionReason]])}${ac310KeyValueSurface("Trước và sau",[["Trước",`${op.qty} ${op.uom}`],["Sau",`${cr11CorrectQty} ${op.uom}`],["Điều chỉnh",`${delta>0?"+":""}${delta} ${op.uom}`,true]])}${sheet}`;
  return ac310Return(appShell({title:"Duyệt sửa sai",body,actions:ac310ApprovalFooter('data-cr11-action="reject-open"','data-cr11-action="approve"'),back:false}));
}

/* ------------------------------ BJ12 ----------------------------------- */
function ac310Cf12Review(){
  return ac310InfoSurface("Số dư đầu kỳ",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff),true],["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)],["Tổng giá trị",cfMoney(cf12Summary.parsedValue),true]]);
}
function ac310Render066(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-066",state);
  if(!["READY","PENDING_APPROVAL","REJECTED","ACTIVE_RECONCILED"].includes(state)) return ac310Base("SCR-066",state);
  if(state==="ACTIVE_RECONCILED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:ac310Result("Tồn kho đầu kỳ đã sẵn sàng","Số dư đầu kỳ đã được ghi nhận và đối chiếu.",[["Ngày chốt",cfDateVN(cf12Cutoff)],["Sản phẩm",`${cfNumber(cf12Summary.products)} sản phẩm`],["Đối soát","Đã khớp"]]),actions:primaryFooter("Xem tồn kho",'data-cf12-action="see-inventory"'),centered:true,back:false}));
  if(state==="PENDING_APPROVAL") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("info","Đang chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Chờ duyệt"]])}`,back:false}));
  if(state==="REJECTED") return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${vBanner("warning","Yêu cầu cần chỉnh sửa","Người duyệt đã trả lại dữ liệu. Tồn kho chưa thay đổi.")}${ac310InfoSurface("Yêu cầu",[["Kho","Kho trung tâm"],["Ngày chốt",cfDateVN(cf12Cutoff)],["Trạng thái","Cần chỉnh sửa"]])}`,actions:primaryFooter("Chỉnh dữ liệu",'data-cf12-action="fix-rejected"'),back:false}));
  return ac310Return(appShell({title:"Khởi tạo tồn kho",body:`${ac310InfoSurface("Khởi tạo lần đầu",[["Kho","Kho trung tâm",true],["Trạng thái","Chưa thiết lập"],["Nguyên tắc","Chỉ có một số dư đầu kỳ chính thức"]])}<p class="ac310-note">Sau khi hoàn tất, mọi sửa sai được thực hiện bằng nghiệp vụ điều chỉnh có kiểm soát.</p>`,actions:primaryFooter("Bắt đầu",'data-cf12-action="start"'),back:false}));
}
function ac310Render067(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-067",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-067",state);
  const invalid=state==="VALIDATION_ERROR";
  const body=`${invalid?vBanner("error","Chưa đủ dữ liệu kiểm soát","Chọn tệp, ngày chốt và nhập đủ hai số kiểm soát trước khi kiểm tra."):""}${ac310FileDrop("Tệp số dư đầu kỳ",cf12FileName,'data-cf12-action="choose-file"')}<div class="ac310-form-stack">${ac310Field("Ngày chốt số dư",cf12Cutoff,'data-cf12-cutoff','Ngày nghiệp vụ mà số dư đầu kỳ có hiệu lực.',"date")}${ac310Field("Tổng số lượng kiểm soát",cf12ControlQty,'data-cf12-control-qty','Nhập từ nguồn kiểm soát độc lập.',"number")}${ac310Field("Tổng giá trị kiểm soát",cf12ControlValue,'data-cf12-control-value','Giá trị tồn kho đầu kỳ theo nguồn kiểm soát.',"text")}</div>`;
  const disabled=!cf12FileName||!cf12Cutoff||!(Number(cf12ControlQty)>=0)||!(Number(cf12ControlValue)>=0);
  return ac310Return(appShell({title:"Dữ liệu tồn kho đầu kỳ",body,actions:primaryFooter("Kiểm tra dữ liệu",'data-cf12-action="check"',disabled)}));
}
function ac310IssueRow(title,detail){return ac310RecordRow({title,subtitle:detail,badge:"Cần sửa",tone:"Warning",status:true,leading:null});}
function ac310Render068(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-068",state);
  if(!["READY","VALIDATION_FAILED","CONTROL_TOTAL_MISMATCH"].includes(state)) return ac310Base("SCR-068",state);
  if(state==="VALIDATION_FAILED"){
    const issues=ac310ListSurface(`${ac310IssueRow("Dòng 18 · Vaccine Newcastle","Chưa xác định sản phẩm")}${ac310IssueRow("Dòng 44 · Amox 500","Trùng cùng sản phẩm + kho + tình trạng + lô")}${ac310IssueRow("Dòng 61 · Nobivac DHPPi","Thiếu hạn dùng bắt buộc")}`,"ac310-validation-list");
    return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("error","Còn dòng chưa hợp lệ","Không có dữ liệu nào được ghi nhận. Sửa dữ liệu nguồn rồi kiểm tra lại.")}${ac310SummaryMetrics([["Dòng đọc được",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Lỗi cần sửa","3"]])}${ac310SectionTitle("Dòng cần sửa")}${issues}`,actions:primaryFooter("Chọn lại tệp",'data-cf12-action="back-file"')}));
  }
  if(state==="CONTROL_TOTAL_MISMATCH") return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("warning","Số kiểm soát không khớp","Chưa thể gửi phê duyệt.")}${ac310KeyValueSurface("Đối chiếu",[["Theo tệp",cfNumber(cf12Summary.parsedQty)],["Số kiểm soát",cfNumber(Number(cf12ControlQty)+12)],["Chênh lệch","−12",true],["Giá trị theo tệp",cfMoney(cf12Summary.parsedValue)],["Giá trị kiểm soát",cfMoney(cf12ControlValue)]])}`,actions:primaryFooter("Quay lại dữ liệu",'data-cf12-action="back-file"')}));
  return ac310Return(appShell({title:"Kết quả kiểm tra dữ liệu",body:`${vBanner("success","Dữ liệu đã qua kiểm tra","Tệp chi tiết khớp số kiểm soát và không còn lỗi bắt buộc.")}${ac310SummaryMetrics([["Dòng dữ liệu",cfNumber(cf12Summary.rows)],["Sản phẩm",cfNumber(cf12Summary.products)],["Tổng số lượng",cfNumber(cf12Summary.parsedQty)]])}${ac310InfoSurface("Kiểm tra chính",[["Số âm","Không có"],["Dòng trùng","Không có"],["Lô / hạn dùng","Hợp lệ"],["Số kiểm soát","Đã khớp",true]])}`,actions:primaryFooter("Rà soát số dư",'data-cf12-action="review"')}));
}
function ac310Render069(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-069",state);
  if(!["READY","PENDING_APPROVAL"].includes(state)) return ac310Base("SCR-069",state);
  const pending=state==="PENDING_APPROVAL"?vBanner("info","Đã gửi chờ duyệt","Bạn đã hoàn tất phần chuẩn bị. Tồn kho chưa thay đổi."):"";
  const body=`${pending}${ac310Cf12Review()}${ac310InfoSurface("Phân bố dữ liệu",[["Bán được",`${cfNumber(cf12Summary.sellableRows)} dòng`,true],["Không bán được",`${cfNumber(cf12Summary.nonSellableRows)} dòng`],["Lô / hạn dùng","Giữ theo cấu hình sản phẩm"]])}`;
  return ac310Return(appShell({title:"Rà soát số dư đầu kỳ",body,actions:state==="READY"?primaryFooter("Gửi phê duyệt",'data-cf12-action="send-approval"'):""}));
}
function ac310Render070(state){
  if(activeFlowId!=="UIF-12") return ac310Base("SCR-070",state);
  if(state!=="READY") return ac310Base("SCR-070",state);
  const reject=cf12RejectSheet();
  const body=`${vBanner("info","Kiểm tra trước khi duyệt","Đối chiếu ngày chốt, số kiểm soát và phạm vi trước khi quyết định.")}${ac310InfoSurface("Người chuẩn bị",[["Người lập","Nguyễn An",true],["Ngày gửi","07/09/2026 · 10:32"]])}${ac310Cf12Review()}${reject}`;
  return ac310Return(appShell({title:"Duyệt số dư đầu kỳ",body,actions:ac310ApprovalFooter('data-cf12-action="open-reject"','data-cf12-action="approve"'),back:false}));
}

/* ------------------------------ BJ15 ----------------------------------- */
function ac310ModeChoice(value,label,detail,current,attr){
  return `<button type="button" class="ac310-mode-row${current===value?' is-selected':''}" ${attr}="${value}" data-ds-component="VRadio" data-figma-node="522:7410"><span class="ac310-radio-control"></span><span class="ac310-radio-copy"><strong>${esc(label)}</strong><small>${esc(detail)}</small></span></button>`;
}
function ac310Render054(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-054",state);
  if(!["READY","VALIDATION_ERROR"].includes(state)) return ac310Base("SCR-054",state);
  const invalid=state==="VALIDATION_ERROR";
  const productOptions=[["ALL","Tất cả sản phẩm"],...cf15Products.map((x)=>[x.id,`${x.name} · ${x.code}`])];
  const modes=`${ac310ModeChoice("INVENTORY","Tồn kho","Xem số lượng và giá trị theo phạm vi",cf15ReportType,"data-cf15-report-type")}${ac310ModeChoice("STOCK_CARD","Thẻ kho","Xem biến động của một sản phẩm",cf15ReportType,"data-cf15-report-type")}`;
  const dates=`${ac310ModeChoice("BUSINESS","Ngày nghiệp vụ","Theo ngày nghiệp vụ phát sinh",cf15DateMode,"data-cf15-date-mode")}${ac310ModeChoice("RECORDED","Ngày ghi nhận","Theo thời điểm hệ thống ghi nhận",cf15DateMode,"data-cf15-date-mode")}`;
  const body=`${invalid?vBanner("error","Chưa đủ điều kiện tra cứu",cf15ReportType==="STOCK_CARD"?"Chọn một sản phẩm cụ thể để xem thẻ kho.":"Kiểm tra lại phạm vi và kỳ báo cáo."):""}${ac310RadioSurface("Loại tra cứu",[modes])}<div class="ac310-form-stack">${cfSelect("Kho",cf15Warehouse,[["MAIN","Kho trung tâm"]],"data-cf15-warehouse","")}${cfSelect("Sản phẩm",cf15Product,productOptions,"data-cf15-product",cf15ReportType==="STOCK_CARD"?"Bắt buộc khi xem thẻ kho.":"")}</div>${ac310RadioSurface("Cách hiểu thời gian",[dates])}<div class="ac310-form-stack ac310-date-grid">${cfField("Từ ngày",cf15From,'data-cf15-from','date')}${cfField("Đến ngày",cf15To,'data-cf15-to','date')}</div>`;
  return ac310Return(appShell({title:"Tra cứu kho",body,actions:primaryFooter("Xem báo cáo",'data-cf15-action="query"'),back:false}));
}
function ac310Cf15ProductSheet(product,financeAllowed){
  if(!cf15ProductSheetOpen||!product) return "";
  const rows=[["Tồn vật lý",`${cfNumber(product.qty)} ${product.uom}`,true],["Khả dụng bán",`${cfNumber(product.available)} ${product.uom}`,true],...(financeAllowed?[["Giá trị tồn",cfMoney(product.value)]]:[])];
  const lots=product.tracking==="LOT"?product.lots.map((l)=>ac310RecordRow({title:`Lô ${l.lot}`,subtitle:`${l.qty} ${product.uom}`,badge:l.state,tone:l.state==="Bán được"?"Success":"Warning",status:true,leading:null})).join(""):"";
  return `<div class="sheet-backdrop" data-cf15-action="close-product-sheet"><section class="bottom-sheet ac310-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(product.name)}</h3><small>${esc(product.code)}</small></div><div class="sheet-content">${ac310KeyValueSurface("",rows,{extraClass:"ac310-sheet-surface"})}${product.tracking==="LOT"?`${ac310SectionTitle("Theo lô")}${ac310ListSurface(lots,"ac310-sheet-list")}`:`<p class="ac310-note">Sản phẩm không quản lý theo lô.</p>`}<div class="sheet-actions"><button class="button button--secondary" type="button" data-cf15-action="close-product-sheet">Đóng</button><button class="button button--primary" type="button" data-cf15-action="product-stock-card" data-cf15-product-id="${product.id}">Xem thẻ kho</button></div></div></section></div>`;
}
function ac310Render055(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-055",state);
  if(!["READY","RECORDED_DATE_VIEW","BUSINESS_DATE_VIEW","FINANCIAL_RESTRICTED"].includes(state)) return ac310Base("SCR-055",state);
  const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
  const financeAllowed=state!=="FINANCIAL_RESTRICTED";
  if(cf15ReportType==="INVENTORY"){
    const rows=cf15Products.map((p)=>ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom} · Khả dụng ${cfNumber(p.available)} ${p.uom}`,attrs:`data-cf15-product-row="${p.id}"`})).join("");
    const body=`${cf15ContextBanner(state,mode)}${ac310SummaryMetrics([["Sản phẩm",cf15Products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(cf15Products.reduce((a,x)=>a+x.value,0))]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ac310SectionTitle("Sản phẩm")}${ac310ListSurface(rows)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất báo cáo</button>${ac310Cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
    return ac310Return(appShell({title:"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
  }
  const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
  const movements=cf15Movements.map((m)=>ac310RecordRow({title:m.label,subtitle:`${mode==="RECORDED"?m.recorded:m.business} · ${m.source}`,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",attrs:`data-cf15-movement="${m.id}"`,leading:null})).join("");
  const body=`${cf15ContextBanner(state,mode)}${ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom}`,badge:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,tone:"Success",status:true})}${financeAllowed?ac310KeyValueSurface("",[["Giá trị tồn",cfMoney(p.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ.")}${ac310SectionTitle("Biến động")}${ac310ListSurface(movements)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất thẻ kho</button>`;
  return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body}));
}
function ac310Render056CF15(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-056",state);
  if(!["READY","FINANCIAL_RESTRICTED","LOCKED"].includes(state)) return ac310Base("SCR-056",state);
  const m=cf15Movement(),financeAllowed=state!=="FINANCIAL_RESTRICTED";
  const lockedNotice=state==="LOCKED"?vBanner("info","Dữ liệu đang ở chế độ chỉ đọc","Bạn có thể xem nguồn và truy vết; màn này không thay đổi dữ liệu."):"";
  const body=`${lockedNotice}${ac310RecordRow({title:m.label,subtitle:m.source,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",status:true,leading:null})}${ac310InfoSurface("Thời gian và người thực hiện",[["Ngày nghiệp vụ",m.business],["Ngày ghi nhận",m.recorded],["Người thực hiện",m.actor]])}${ac310KeyValueSurface("Số lượng",[["Trước",`${m.before} ${m.uom}`],["Biến động",`${m.delta>0?"+":""}${m.delta} ${m.uom}`,true],["Sau",`${m.after} ${m.uom}`],["Lô",m.lot],["Tình trạng",m.state]])}${financeAllowed?ac310KeyValueSurface("Giá trị",[["Tác động",cfMoney(m.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể truy vết nguồn và số lượng.")}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="source">Xem nguồn</button>`;
  return ac310Return(appShell({title:"Chi tiết biến động",body}));
}
function ac310Render057(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-057",state);
  if(state!=="READY"&&state!=="STALE") return ac310Base("SCR-057",state);
  const m=cf15Movement();
  const items=[ac310AuditItem("Create",m.source,`Nghiệp vụ nguồn hoàn tất · ${m.business}`),ac310AuditItem("System","Đã ghi nhận kho",m.recorded),ac310AuditItem("Update",`${m.delta>=0?"Tồn tăng":"Tồn giảm"} ${Math.abs(m.delta)} ${m.uom}`,`Số dư sau biến động: ${m.after} ${m.uom}`)];
  const body=`${state==="STALE"?vBanner("warning","Dữ liệu nguồn đang cập nhật","Giữ mốc hiển thị hiện tại cho tới khi tải lại dữ liệu."):""}${ac310InfoSurface("Biến động đang xem",[["Nguồn",m.source,true],["Sản phẩm",cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product).name],["Số lượng",`${m.delta>0?"+":""}${m.delta} ${m.uom}`]])}${ac310AuditSurface("Dòng thời gian nghiệp vụ",items)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export-source">Xuất bằng chứng</button>`;
  return ac310Return(appShell({title:"Nguồn nghiệp vụ",body}));
}
function ac310Render058(state){
  if(activeFlowId!=="UIF-15") return ac310Base("SCR-058",state);
  if(state!=="READY") return ac310Base("SCR-058",state);
  const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
  const body=`${ac310InfoSurface("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Dữ liệu đến","07/09/2026 · 11:00"],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${ac310InfoSurface("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ như màn đang xem"]])}`;
  return ac310Return(appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"}));
}

/* --------------------------- BJ16 / BJ17 ------------------------------- */
function ac310CaseRows(is17){
  const cases=is17?cr17Cases:cr16Cases,filter=is17?cr17Filter:cr16Filter;
  const filtered=cases.filter((c)=>{if(filter==="ALL")return true;if(is17)return c.evidence===filter;if(filter==="ACTION")return ["PROJECTION","CORRECTION"].includes(c.route);if(filter==="WAITING")return c.route==="SOURCE";if(filter==="HIGH")return c.route==="LEDGER";return true;}).filter((c)=>ioMatchesSearch(crControlQuery,`${c.id} ${c.title} ${c.scope} ${c.operation||""}`));
  return filtered.map((c)=>ac310RecordRow({title:is17?(c.operation||c.id):c.id,subtitle:`${c.title} · ${c.scope}`,badge:c.severity,tone:c.tone,attrs:`data-cr-case="${c.id}"`,leading:null})).join("");
}
function ac310Render078(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-078",state);
  if(state!=="READY") return ac310Base("SCR-078",state);
  const is17=activeFlowId==="UIF-17",filter=is17?cr17Filter:cr16Filter;
  const chipItems=is17?[["ALL","Tất cả"],["COMMITTED","Đã có tác động"],["NO_COMMIT","Chưa có tác động"],["INSUFFICIENT","Cần chuyên sâu"]]:[["ALL","Tất cả"],["ACTION","Cần xử lý"],["WAITING","Đang chờ"],["HIGH","Ưu tiên cao"]];
  const rows=ac310CaseRows(is17);
  const body=`${ds24Search(crControlQuery,"data-cr-control-search",is17?"Tìm mã nghiệp vụ hoặc hàng":"Tìm hồ sơ, sản phẩm hoặc chứng từ")}<div class="ds24-chip-scroll">${chipItems.map(([k,l])=>ds24Chip(k,l,filter===k,is17?"data-cr17-filter":"data-cr16-filter")).join("")}</div>${rows?ac310ListSurface(rows):ioEmpty("Không có hồ sơ phù hợp","Thử đổi bộ lọc hoặc từ khóa tìm kiếm.")}`;
  return ac310Return(appShell({title:is17?"Nghiệp vụ cần xác minh":"Đối soát sai lệch",body,back:false}));
}
function ac310EvidenceRows(rows){return ac310InfoSurface("Bằng chứng",rows.map((r)=>[r[0],r[1],String(r[1]).includes("lệch")||String(r[1]).includes("không nhất quán")]));}
function ac310Render079(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-079",state);
  if(["PERMISSION_DENIED","LOADING"].includes(state)) return ac310Base("SCR-079",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current(),actual=state==="READY"?cr079StateFor17(c):state;
    if(actual==="INSUFFICIENT_EVIDENCE") return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${vBanner("warning","Chưa đủ bằng chứng để kết luận","Nghiệp vụ vẫn chưa xác định và phạm vi tiếp tục được bảo vệ.")}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${ac310EvidenceRows(cr17EvidenceRows(c))}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')}));
    const committed=c.evidence==="COMMITTED";
    const banner=committed?vBanner("info","Đã tìm thấy tác động của nghiệp vụ","Bước tiếp theo chỉ xác lập kết quả; không ghi lại tác động lần hai."):vBanner("info","Chưa phát hiện tác động tồn kho","Có thể tiếp tục đúng lần xử lý này, giữ nguyên định danh và nội dung đã xác nhận.");
    return ac310Return(appShell({title:"Bằng chứng kết quả",body:`${banner}${ac310RecordRow({title:c.operation,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Định danh nghiệp vụ","Giữ nguyên"]])}${ac310EvidenceRows(cr17EvidenceRows(c))}`,actions:primaryFooter(committed?"Xem phương án xác lập":"Xem phương án tiếp tục",'data-cr17-action="open-plan"')}));
  }
  const c=cr16Current(),actual=state==="READY"?cr079StateFor16(c):state; let banner="",actions="";
  if(actual==="PROJECTION_MISMATCH"){banner=vBanner("info","Sổ kho đúng, số liệu hiển thị sai","Chỉ số liệu hiển thị cần được khôi phục.");actions=primaryFooter("Khôi phục số liệu hiển thị",'data-cr16-action="open-plan"');}
  else if(actual==="CORRECTION_REQUIRED"){banner=vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn; không chỉnh số dư trực tiếp để làm khớp.");actions=primaryFooter("Mở yêu cầu sửa sai",'data-cr16-action="handoff-correction"');}
  else if(actual==="NO_REAL_DIFFERENCE"){banner=vBanner("info","Không có sai lệch tồn kho thực","Khác biệt đến từ thời điểm lấy số liệu.");actions=primaryFooter("Rà soát đóng hồ sơ",'data-cr16-action="review-close"');}
  else if(actual==="LEDGER_INTEGRITY_RISK"){banner=vBanner("warning","Cần kiểm tra toàn vẹn sổ kho","Tạm dừng khôi phục tự động và sửa sai.");actions=primaryFooter("Xem trạng thái chuyển xử lý",'data-cr16-action="show-escalated"');}
  else if(actual==="SOURCE_MISMATCH") banner=vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Hồ sơ được giữ mở; kho không tự sửa dữ liệu nguồn hoặc sổ kho.");
  else banner=vBanner("warning","Chưa đủ bằng chứng kết luận","Giữ hồ sơ mở cho tới khi xác định được nguyên nhân.");
  return ac310Return(appShell({title:"Bằng chứng & kết luận",body:`${banner}${ac310RecordRow({title:c.id,subtitle:c.scope,badge:c.severity,tone:c.tone,status:true,leading:null})}${ac310InfoSurface("Hồ sơ",[["Người xử lý",c.owner],["Bảo vệ phạm vi",c.route==="NO_REAL"?"Không cần":"Đang áp dụng"]])}${ac310EvidenceRows(cr16EvidenceRows(c))}`,actions}));
}
function ac310Render080(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-080",state);
  if(["PERMISSION_DENIED","LOCKED","CONFLICT"].includes(state)) return ac310Base("SCR-080",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current();
    if(c.evidence==="INSUFFICIENT"||state==="INSUFFICIENT_EVIDENCE") return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("warning","Chưa có phương án xử lý an toàn","Giữ trạng thái chưa xác định và bảo vệ phạm vi cho tới khi có thêm bằng chứng.")}${ac310InfoSurface("Phạm vi xử lý",[["Nghiệp vụ",c.operation,true],["Người xử lý",c.owner],["Định danh","Giữ nguyên"]])}`,actions:primaryFooter("Xem trạng thái xử lý",'data-cr17-action="show-escalated"')}));
    const committed=c.evidence==="COMMITTED",title=committed?"Xác lập đã hoàn tất":"Tiếp tục lần xử lý này";
    return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info",title,committed?"Dùng tác động đã tồn tại để xác lập kết quả; không ghi lại biến động lần hai.":"Tiếp tục cùng định danh sau khi đã xác nhận chưa có tác động bán phần.")}${ac310InfoSurface("Phạm vi",[["Nghiệp vụ",c.operation,true],["Phạm vi",c.scope],["Định danh","Giữ nguyên"]])}${ac310InfoSurface("Không thực hiện",[["Tạo nghiệp vụ mới","Không"],["Tự hoàn nguyên","Không"],["Đổi nội dung đã xác nhận","Không"]])}`,actions:primaryFooter(title,'data-cr17-action="execute-plan"')}));
  }
  const c=cr16Current();
  return ac310Return(appShell({title:"Phương án xử lý",body:`${vBanner("info","Khôi phục số liệu hiển thị","Sổ kho đã đúng; chỉ khôi phục dữ liệu hiển thị trong phạm vi này.")}${ac310InfoSurface("Phạm vi",[["Hồ sơ",c.id,true],["Hàng",c.scope],["Bảo vệ phạm vi","Đang áp dụng"]])}${ac310InfoSurface("Tác động",[["Sổ kho","Không thay đổi"],["Nghiệp vụ nguồn","Không thay đổi"],["Số liệu hiển thị","Khôi phục theo sổ kho"]])}`,actions:primaryFooter("Bắt đầu khôi phục",'data-cr16-action="start-recovery"')}));
}
function ac310Render081(state){
  if(activeFlowId!=="UIF-16") return ac310Base("SCR-081",state);
  if(!["REBUILDING","READY"].includes(state)) return ac310Base("SCR-081",state);
  const c=cr16Current();
  if(state==="READY") return ac310Return(appShell({title:"Khôi phục số liệu",body:`${vBanner("success","Đã khôi phục số liệu hiển thị","Kết quả sẵn sàng để rà soát trước khi đóng hồ sơ.")}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"],["Số liệu hiển thị","Đã cập nhật"]])}`,actions:primaryFooter("Rà soát kết quả",'data-cr16-action="review-result"')}));
  const progress=`<section class="ac310-progress-block"><div class="ac310-progress" data-ds-component="VProgress"><div class="ac310-progress__bar"><span style="width:68%"></span></div></div><strong>Đang khôi phục số liệu hiển thị</strong><small>Bạn có thể rời màn hình; hồ sơ tự cập nhật khi hoàn tất.</small></section>`;
  return ac310Return(appShell({title:"Đang khôi phục số liệu",body:`${progress}${ac310InfoSurface("Hồ sơ",[["Mã",c.id,true],["Phạm vi",c.scope],["Sổ kho","Không thay đổi"]])}`}));
}
function ac310Render082(state){
  if(!["UIF-16","UIF-17"].includes(activeFlowId)) return ac310Base("SCR-082",state);
  if(state==="PERMISSION_DENIED") return ac310Base("SCR-082",state);
  if(activeFlowId==="UIF-17"){
    const c=cr17Current(),committed=(cr17ResolutionMode||c.evidence)==="COMMITTED",continued=(cr17ResolutionMode||"")==="CONTINUED";
    const rows=committed?[["Nghiệp vụ",c.operation,true],["Kết quả","Đã hoàn tất"],["Tác động tồn kho","Giữ tác động đã có"],["Định danh","Không thay đổi"]]:[["Nghiệp vụ",c.operation,true],["Kết quả",continued?"Đã hoàn tất":"Đã có kết quả mới"],["Định danh","Không thay đổi"],["Nghiệp vụ mới","Không tạo"]];
    return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info","Kết quả đã được xác lập","Hệ thống giữ đúng nghiệp vụ ban đầu và không tạo tác động trùng.")}${ac310InfoSurface("Kết quả cuối",rows)}`,actions:primaryFooter("Hoàn tất xác minh",'data-cr17-action="finish-review"')}));
  }
  const c=cr16Current();
  if(state==="MISMATCH_REMAINS") return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ.")}${ac310KeyValueSurface(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`}));
  const noReal=c.route==="NO_REAL";
  return ac310Return(appShell({title:"Rà soát kết quả",body:`${vBanner("info",noReal?"Không có sai lệch thực":"Số liệu đã khớp",noReal?"Khác biệt trước đó được giải thích bằng mốc thời gian.":"Số liệu hiển thị hiện khớp với sổ kho.")}${ac310KeyValueSurface(c.id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","118 hộp"],["Chênh lệch","0 hộp",true],["Phạm vi",noReal?"Không khóa":"Sẵn sàng mở khóa"]])}`,actions:primaryFooter("Đóng hồ sơ & mở khóa",'data-cr16-action="close-case"')}));
}

/* Bind v3.1.0 renderers. Shared screen IDs preserve non Audit & Control flows. */
renderers["SCR-042"]=ac310Render042;
renderers["SCR-043"]=ac310Render043;
renderers["SCR-044"]=ac310Render044;
renderers["SCR-045"]=ac310Render045;
renderers["SCR-046"]=ac310Render046;
renderers["SCR-047"]=(state)=>activeFlowId==="UIF-08"?ac310Base("SCR-047",state):ac310Base("SCR-047",state);
renderers["SCR-036"]=ac310Render036;
renderers["SCR-037"]=ac310Render037;
renderers["SCR-038"]=ac310Render038;
renderers["SCR-040"]=ac310Render040;
renderers["SCR-041"]=ac310Render041;
renderers["SCR-048"]=ac310Render048;
renderers["SCR-049"]=ac310Render049;
renderers["SCR-052"]=ac310Render052;
renderers["SCR-050"]=ac310Render050;
renderers["SCR-051"]=ac310Render051;
renderers["SCR-053"]=(state)=>activeFlowId==="UIF-11"?ac310Base("SCR-053",state):ac310Base("SCR-053",state);
renderers["SCR-066"]=ac310Render066;
renderers["SCR-067"]=ac310Render067;
renderers["SCR-068"]=ac310Render068;
renderers["SCR-069"]=ac310Render069;
renderers["SCR-070"]=ac310Render070;
renderers["SCR-071"]=(state)=>activeFlowId==="UIF-12"?ac310Base("SCR-071",state):ac310Base("SCR-071",state);
renderers["SCR-054"]=ac310Render054;
renderers["SCR-055"]=ac310Render055;
renderers["SCR-056"]=ac310Render056;
renderers["SCR-057"]=ac310Render057;
renderers["SCR-058"]=ac310Render058;
renderers["SCR-059"]=(state)=>activeFlowId==="UIF-15"?ac310Base("SCR-059",state):ac310Base("SCR-059",state);
renderers["SCR-078"]=ac310Render078;
renderers["SCR-079"]=ac310Render079;
renderers["SCR-080"]=ac310Render080;
renderers["SCR-081"]=ac310Render081;
renderers["SCR-082"]=ac310Render082;
renderers["SCR-083"]=(state)=>["UIF-16","UIF-17"].includes(activeFlowId)?ac310Base("SCR-083",state):ac310Base("SCR-083",state);

// Re-render once so a deep-linked Audit & Control screen immediately uses v3.1.0.
if (["UIF-08","UIF-09","UIF-10","UIF-11","UIF-12","UIF-15","UIF-16","UIF-17"].includes(activeFlowId)) render();

/* ===== v320-audit-control-ui-correction.js ===== */
/* VET45 Theme 7 v3.2.0 — Audit & Control UI correction
 * Parent: v3.1.0
 * Scope: BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17.
 * Purpose: remove redundant list headings, remove destructive CTAs from browse/list surfaces,
 * and tighten dense filter/list presentation while preserving all business states and handlers.
 */

const AC320_SCOPE = ["UIF-08","UIF-09","UIF-10","UIF-11","UIF-12","UIF-15","UIF-16","UIF-17"];
const ac320Base = {
  "SCR-042": renderers["SCR-042"],
  "SCR-044": renderers["SCR-044"],
  "SCR-055": renderers["SCR-055"],
  "SCR-056": renderers["SCR-056"],
  "SCR-057": renderers["SCR-057"]
};

function ac320ListCount(count,label="mục") {
  return `<div class="ac320-list-meta" data-ds-component="DS v2 / List Top Bar" data-figma-node="547:2223" data-ds-prop-type="Count"><span>${esc(`${count} ${label}`)}</span></div>`;
}

function ac320SessionRow(){
  return `<div class="ac320-session-record" data-ds-pattern="Session record" data-composed-from="DS v2 / List Row,VBadge">
    ${ac310RecordRow({title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",attrs:'data-ic08-action="resume"',leading:null})}
  </div>`;
}

function ac320Render042(state){
  if(activeFlowId!=="UIF-08" || !["READY","PENDING_APPROVAL"].includes(state)) return ac320Base["SCR-042"](state);
  if(state==="PENDING_APPROVAL") return ac320Base["SCR-042"](state);
  const chips=`<div class="ds24-chip-scroll ac320-chip-row" aria-label="Lọc phiên kiểm kê">${ds24Chip("ALL","Tất cả",true,"data-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",false,"data-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",false,"data-ic08-filter")}</div>`;
  const body=`${ds24Search("","","Tìm phiên kiểm kê")}${chips}${ac320SessionRow()}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Kiểm kê kho",body,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
}

function ac320Render044(state){
  if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac320Base["SCR-044"](state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}${ac320ListCount(groups.length,"dòng cần đếm")}<div class="ac310-product-control-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}

function ac320Render055(state){
  if(activeFlowId!=="UIF-15") return ac320Base["SCR-055"](state);
  const html=ac320Base["SCR-055"](state);
  if(typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const title=[...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].find(x=>x.textContent.trim()==="Sản phẩm");
  if(title) title.remove();
  return t.innerHTML;
}

function ac320Render056(state){
  const html=ac320Base["SCR-056"](state);
  if(!AC320_SCOPE.includes(activeFlowId) || typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const shell=t.content.querySelector('.v-page-scaffold');
  const pageTitle=shell?.dataset.dsPropTitle||"";
  if(pageTitle==="Lịch sử tình trạng"){
    [...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].filter(x=>x.textContent.trim()==="Lịch sử").forEach(x=>x.remove());
  }
  return t.innerHTML;
}

function ac320Render057(state){
  const html=ac320Base["SCR-057"](state);
  if(activeFlowId!=="UIF-15" || typeof html!=="string") return html;
  const t=document.createElement("template"); t.innerHTML=html;
  const shell=t.content.querySelector('.v-page-scaffold');
  const pageTitle=shell?.dataset.dsPropTitle||"";
  if(pageTitle==="Nguồn nghiệp vụ"){
    [...t.content.querySelectorAll(".ac310-section-title,.ds24-section-title,.io-section-title")].filter(x=>x.textContent.trim()==="Dòng thời gian nghiệp vụ").forEach(x=>x.remove());
  }
  return t.innerHTML;
}

renderers["SCR-042"]=ac320Render042;
renderers["SCR-044"]=ac320Render044;
renderers["SCR-055"]=ac320Render055;
renderers["SCR-056"]=ac320Render056;
renderers["SCR-057"]=ac320Render057;

if (AC320_SCOPE.includes(activeFlowId)) render();

/* ===== v340-professional-composition.js ===== */
/* VET45 Theme 7 v3.4.0 — professional composition correction
 * Parent: v3.3.0
 * Scope: cumulative product/context hierarchy cleanup, with targeted renderer changes in BJ08.
 * No business/state/action contract is changed.
 */

// Keep product identity quiet during counting: the screen already communicates the task.
ac310CountGroup = function({id,name,code,lot,uom,value,unexpected=false,disabled=false}){
  const parent=ac310ProductRow({
    name, code,
    meta:`${lot?`Lô ${lot} · `:""}${uom}`,
    badge:unexpected?"Bổ sung thực tế":"",
    tone:unexpected?"Info":"Neutral",
    status:true
  });
  return `<section class="ac310-product-control-group ac340-product-task" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${ic08QuantityTrigger("Số lượng thực tế",value,`count:${id}`,uom,disabled)}</div></section>`;
};

// Variance is evidence, not a status badge. Put all numeric comparison facts in one aligned region.
ac310RecountGroup = function({id,name,code,lot,uom,book,first,variance,value,disabled=false}){
  const parent=ac310ProductRow({name,code,meta:`Lô ${lot} · ${uom}`,badge:"",tone:"Neutral",status:true});
  const facts=ac310KeyValueSurface("",[
    ["Theo sổ",`${book} ${uom}`],
    ["Lần đếm đầu",`${first} ${uom}`],
    ["Chênh lệch",variance]
  ],{extraClass:"ac310-inline-surface ac340-recount-facts"});
  return `<section class="ac310-product-control-group ac340-product-task ac340-recount-task" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row,VNumericKeypadSheet">${parent}<div class="ac310-control-indent">${facts}${ic08QuantityTrigger("Số lượng đếm lại",value,`recount:${id}`,uom,disabled)}</div></section>`;
};

function ac340ReviewProduct({name,code,meta,variance,rows}){
  const product=ac310ProductRow({name,code,meta,badge:"",tone:"Neutral",status:true});
  const details=ac310KeyValueSurface("",[["Chênh lệch",variance],...rows],{extraClass:"ac310-approval-detail ac340-review-facts"});
  return `<section class="ac340-review-group" data-layout-pattern="Grouped surface" data-composed-from="DS v2 / List Row,DS v2 / Key-value Row">${product}${details}</section>`;
}

const ac340Base044=renderers["SCR-044"];
const ac340Base045=renderers["SCR-045"];
const ac340Base046=renderers["SCR-046"];

function ac340Render044(state){
  if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac340Base044(state);
  const lost=state==="LOCK_LOST";
  const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
  const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Quay về phiên kiểm kê để tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
  const groups=[
    ac310CountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",value:ic08Counts.amox,disabled:lost}),
    ac310CountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",value:ic08Counts.glove,disabled:lost})
  ];
  if(ic08UnexpectedLine) groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
  const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
  return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
}

function ac340Render045(state){
  if(activeFlowId!=="UIF-08" || !["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state)) return ac340Base045(state);
  const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
  const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ. Phiên vẫn được giữ khóa."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Kiểm tra số lượng đếm lại trước khi gửi."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
  const groups=[
    ac310RecountGroup({id:"amox",name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp",book:20,first:18,variance:"−2 hộp",value:ic08Recounts.amox,disabled:locked}),
    ac310RecountGroup({id:"glove",name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp",book:6,first:7,variance:"+1 hộp",value:ic08Recounts.glove,disabled:locked})
  ];
  const evidenceRows=[["Amox 500","Đã có bằng chứng"],["Găng tay M",price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã có căn cứ"]];
  const body=`${notice}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${(price||evidence)?vBanner("warning","Chưa thể gửi duyệt","Chỉ có thể gửi khi tất cả căn cứ bắt buộc đã hợp lệ."):""}${ic08Overlays()}`;
  let actions=""; if(!locked) actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" data-ds-component="VButton" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open" data-ds-component="VButton">Hủy phiên</button>`:""}</footer>`;
  return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
}

function ac340Render046(state){
  if(activeFlowId!=="UIF-08" || !["READY","APPROVAL_REVIEW"].includes(state)) return ac340Base046(state);
  const products=`<div class="ac340-review-list">${ac340ReviewProduct({name:"Amox 500",code:"SP-00128",meta:"Lô L2407-A · hộp",variance:"−2 hộp",rows:[["Đếm lại","18 hộp"],["Bằng chứng","Đã đủ"]]})}${ac340ReviewProduct({name:"Găng tay M",code:"SP-00410",meta:"Lô L2405-M · hộp",variance:"+1 hộp",rows:[["Đếm lại","7 hộp"],["Căn cứ giá","Đã đủ"],["Bằng chứng","Đã đủ"]]})}</div>`;
  const body=`${vBanner("info","Cần quyết định độc lập","Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng chênh lệch","2 dòng"]])}${products}${ic08Overlays()}`;
  const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-ic08-action="request-review" data-ds-component="VButton">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-ic08-action="approve" data-ds-component="VButton">Duyệt và điều chỉnh</button></footer>`;
  return ac310Return(appShell({title:"Duyệt kiểm kê",body,actions}));
}

renderers["SCR-044"]=ac340Render044;
renderers["SCR-045"]=ac340Render045;
renderers["SCR-046"]=ac340Render046;

if(activeFlowId==="UIF-08") render();

/* ===== v350-flow-logic-correction.js ===== */
/* VET45 Theme 7 v3.5.0 — full flow/logic correction
 * Parent: v3.4.0
 * Scope: executable state transitions, stale-source guards, UNKNOWN recovery,
 * actor handoff, reporting scope, costing lineage, and UI behavior regressions.
 * UI remains composed from the existing Figma DS components/patterns.
 */
(() => {
  const VERSION = "3.5.0";
  const num = (v) => Number(v ?? 0);
  const nonBlank = (v) => String(v ?? "").trim().length > 0;
  const same = (a,b) => String(a ?? "") === String(b ?? "");
  const escAttr = (v) => (typeof escapeAttribute === "function" ? escapeAttribute(v) : String(v).replace(/"/g,"&quot;"));

  // Reachable states introduced/activated by v3.5.0 must be declared, not only
  // reachable through imperative handlers. This keeps Inspector/state coverage
  // aligned with the executable state machine.
  const v350DeclaredStates = {
    "SCR-040":["VALIDATION_ERROR","SELF_APPROVAL_NOT_ALLOWED"],
    "SCR-046":["APPROVAL_REVIEW"]
  };
  Object.entries(v350DeclaredStates).forEach(([sid,extra])=>{
    const sc=screens.find(x=>x.id===sid);
    if(sc){ sc.states=[...new Set([...(sc.states||[]),...extra])]; }
  });

  // -------------------------------------------------------------------------
  // Entry architecture / actor boundary
  // -------------------------------------------------------------------------
  const v350EntryTargets = {
    "UIF-08": {"assigned-counter":["SCR-044","BLIND_COUNT"], "approver":["SCR-046","APPROVAL_REVIEW"]},
    "UIF-09": {"product-context":["SCR-037","READY"], "approver":["SCR-038","APPROVAL_REVIEW"]},
    "UIF-10": {"product-context":["SCR-037","READY"], "approver":["SCR-040","APPROVAL_REVIEW"], "completion-operator":["SCR-040","COMPLETION"]},
    "UIF-14": {"dirty-scope":["SCR-073","READY"]}
  };
  function v350ApplyEntry(flowId, mode, shouldRender=false) {
    const target = v350EntryTargets[flowId]?.[mode];
    if (!target) return false;
    activeFlowId = flowId;
    activeScreenId = target[0];
    if (stateByScreen[activeScreenId] !== undefined) stateByScreen[activeScreenId] = target[1];
    if (flowId === "UIF-14" && mode === "dirty-scope") {
      const dirty = val14Runs.find(r => r.status === "DIRTY");
      if (dirty) {
        val14SelectedRunId = dirty.id;
        val14SetupKind = dirty.kind;
        val14SetupPeriod = dirty.period;
        val14SetupScope = "Sản phẩm cần tính lại";
        val14SuccessorOf = dirty.id;
      }
    }
    if (shouldRender) { syncReviewUrl(); render(); }
    return true;
  }
  if (!initialParams.get("screen")) v350ApplyEntry(activeFlowId, entryMode, false);
  let v350ActorMode = entryMode;
  const isApproverEntry = () => v350ActorMode === "approver";
  const isCompletionEntry = () => v350ActorMode === "completion-operator";

  // -------------------------------------------------------------------------
  // Common safety / recovery helpers
  // -------------------------------------------------------------------------
  function v350LockSourceForUnknown(flowId) {
    if (flowId === "UIF-05") { const o=io05CurrentOrder(); if(o)o.unknownLocked=true; }
    if (flowId === "UIF-06") { const r=io06CurrentRequest(); if(r){r.unknownLocked=true;r.queue="WAITING";r.status="Đang xác minh kết quả";} }
    if (flowId === "UIF-07") { const r=io07Current(); if(r){r.unknownLocked=true;r.queue="WAITING";r.lifecycle="Đang xác minh kết quả";} }
  }
  function v350RecoveryCase({sourceFlow,operation,scope,title,evidence="INSUFFICIENT",owner="Kiểm soát kho"}) {
    const op = operation || `${sourceFlow}-UNKNOWN`;
    let c = cr17Cases.find(x => x.operation === op && x.sourceFlow === sourceFlow);
    if (!c) {
      c = {
        id:`REC-${sourceFlow.replace("UIF-","")}-${op.replace(/[^A-Za-z0-9]/g,"").slice(-12)}`,
        operation:op,
        title:title || "Cần xác minh kết quả nghiệp vụ",
        scope:scope || "Phạm vi của lần xử lý hiện tại",
        evidence,
        severity:evidence==="INSUFFICIENT"?"Cần chuyên sâu":"Cần xử lý",
        tone:evidence==="INSUFFICIENT"?"warning":"info",
        owner,
        sourceFlow,
        evidenceVersion:1,
        protected:true
      };
      cr17Cases.unshift(c);
    }
    return c;
  }
  function v350HandoffUnknown(meta) {
    v350LockSourceForUnknown(meta.sourceFlow);
    const c=v350RecoveryCase(meta);
    cr17SelectedId=c.id;
    cr17ResolutionMode="";
    stateByScreen["SCR-079"]=c.evidence==="INSUFFICIENT"?"INSUFFICIENT_EVIDENCE":"UNKNOWN_EVIDENCE";
    return crSwitchFlow("UIF-17","SCR-079",stateByScreen["SCR-079"]);
  }
  function v350UnknownResult({title="Kết quả chưa xác định",description="Không gửi lại thao tác. Chuyển đúng lần xử lý này sang xác minh kết quả.",operation,scope,sourceFlow}) {
    const body=ioResult(title,description,[["Nghiệp vụ",operation],["Phạm vi",scope],["Trạng thái","Chưa kết luận"]],"warning");
    const attrs=`data-v350-action="handoff-unknown" data-source-flow="${escAttr(sourceFlow)}" data-operation="${escAttr(operation)}" data-scope="${escAttr(scope)}"`;
    return appShell({title:"Xác minh kết quả",body,actions:primaryFooter("Chuyển sang xác minh",attrs),centered:true,back:false});
  }

  // Source queues must not expose an operation that is still UNKNOWN.
  io07Requests.forEach(r=>{r.unknownLocked ??= false;});
  const v350BaseIO07Active = io07ActiveRequests;
  io07ActiveRequests = function(){ return v350BaseIO07Active().filter(r=>!r.unknownLocked); };

  // Capture source version when entering a review/receipt context.
  const v350Navigate = navigate;
  navigate = function(screenId){
    return v350Navigate(screenId);
  };


  // -------------------------------------------------------------------------
  // BJ08 — blind count / recount / approval
  // -------------------------------------------------------------------------
  ic08Counts={amox:"",glove:""};
  ic08Recounts={amox:"",glove:""};
  let v350Ic08DiscrepancyIds=[];
  let v350Ic08AdjustedCount=0;
  const v350Ic08Book={amox:20,glove:6};
  const v350Ic08Meta={
    amox:{name:"Amox 500",code:"SP-00128",lot:"L2407-A",uom:"hộp"},
    glove:{name:"Găng tay M",code:"SP-00410",lot:"L2405-M",uom:"hộp"}
  };
  function v350Ic08FirstValid(){return ["amox","glove"].every(id=>nonBlank(ic08Counts[id])&&Number.isFinite(Number(ic08Counts[id]))&&Number(ic08Counts[id])>=0);}
  function v350Ic08Recompute(){v350Ic08DiscrepancyIds=["amox","glove"].filter(id=>num(ic08Counts[id])!==v350Ic08Book[id]);return v350Ic08DiscrepancyIds;}
  function v350Ic08RecountValid(){return v350Ic08DiscrepancyIds.every(id=>nonBlank(ic08Recounts[id])&&Number.isFinite(Number(ic08Recounts[id]))&&Number(ic08Recounts[id])>=0);}
  function v350Ic08Variance(id,value){const d=num(value)-v350Ic08Book[id];return `${d>0?"+":""}${d} ${v350Ic08Meta[id].uom}`;}
  ic08QuantityTrigger = function(label,value,target,unit,disabled=false) {
    const display=nonBlank(value)?String(value):"—";
    return `<div class="ds24-field" data-theme-component="Theme7QuantityEntry" data-composed-from="VText,VNumericKeypadSheet"><span class="vet45-text-style-8">${esc(label)}</span><button type="button" class="ds24-field__control ds24-quantity-trigger" data-ic08-keypad-open="${target}" data-unit="${escAttr(unit)}" ${disabled?'disabled':''}><span class="vet45-text-style-6">${esc(display)}</span><small class="vet45-text-style-11">${esc(unit)}</small></button></div>`;
  };
  ic08ConfirmationSheet = function(){
    if(!ic08ConfirmKind)return "";
    const cfg={
      'open-session':['Mở phiên kiểm kê?','Phạm vi sẽ được khóa theo thời điểm chốt của phiên.','Mở phiên','default',false],
      'submit-first':['Nộp lần đếm đầu?','Sau khi nộp, hệ thống mới hiển thị số sổ và chênh lệch.','Nộp kết quả','default',false],
      'submit-recount':['Gửi kết quả kiểm kê?','Kết quả đếm lại sẽ được chuyển sang công việc duyệt độc lập.','Gửi chờ duyệt','default',false],
      'approve':['Duyệt và điều chỉnh?','Hệ thống chỉ ghi điều chỉnh sau khi kiểm tra lại điều kiện và phạm vi.','Duyệt và điều chỉnh','default',false],
      'request-review':['Yêu cầu xem lại?','Phiên giữ nguyên khóa và quay lại bước đếm lại.','Yêu cầu xem lại','default',true],
      'cancel':['Hủy phiên kiểm kê?','Không tạo điều chỉnh. Lịch sử kiểm đếm được giữ.','Hủy phiên','danger',true]
    }[ic08ConfirmKind]; if(!cfg)return "";
    const [title,desc,action,tone,needsReason]=cfg;
    const val=ic08ConfirmKind==='cancel'?ic08CancelReason:ic08ReviewReason;
    const attr=ic08ConfirmKind==='cancel'?'data-ic08-cancel-reason':'data-ic08-review-reason';
    const reason=needsReason?ds24TextField('Lý do',val,attr,'Lý do được lưu trong lịch sử quản trị.'):'';
    return `<div class="sheet-backdrop ds24-overlay" data-ic08-action="confirm-close"><section class="ds24-confirmation ds24-confirmation--${tone}" data-ds-component="DS v2 / Confirmation Sheet" role="dialog" aria-modal="true" onclick="event.stopPropagation()"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${reason}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="confirm-close">Quay lại</button><button class="ds24-button ${tone==='danger'?'ds24-button--danger':'ds24-button--primary'}" type="button" data-v350-action="ic08-confirm-${ic08ConfirmKind}" ${needsReason&&!nonBlank(val)?'disabled':''}>${esc(action)}</button></div></section></div>`;
  };
  function v350Render044(state){
    if(activeFlowId!=="UIF-08") return ac340Base044(state);
    if(!["BLIND_COUNT","READY","VALIDATION_ERROR","LOCK_LOST"].includes(state)) return ac340Base044(state);
    const lost=state==="LOCK_LOST";
    const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa nhập đủ kết quả","Nhập số đếm thực tế cho tất cả dòng trước khi nộp."):"";
    const notice=lost?vBanner("warning","Phiên không còn giữ khóa","Số đã nhập được giữ trên thiết bị. Tải lại trạng thái hiện hành trước khi tiếp tục."):vBanner("info","Đang đếm mù","Chỉ nhập số thực tế. Số theo sổ và chênh lệch chỉ hiển thị sau lần nộp đầu.");
    const groups=["amox","glove"].map(id=>{const m=v350Ic08Meta[id];return ac310CountGroup({id,name:m.name,code:m.code,lot:m.lot,uom:m.uom,value:ic08Counts[id],disabled:lost});});
    if(ic08UnexpectedLine)groups.push(ac310CountGroup({id:"unexpected",name:ic08UnexpectedLine.name,code:"Hàng thực tế bổ sung",lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,value:ic08UnexpectedLine.value,unexpected:true,disabled:lost}));
    const body=`${error}${notice}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Kho","Kho trung tâm"],["Thời điểm chốt","09/09/2026 · 08:00"]])}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${!lost?`<button class="button button--secondary ac310-inline-button" type="button" data-ic08-action="add-actual-open" data-ds-component="VButton">Thêm hàng thực tế</button>`:""}${ic08Overlays()}`;
    return ac310Return(appShell({title:"Đếm mù",body,actions:lost?primaryFooter("Về phiên kiểm kê",'data-ic08-action="to-list"'):primaryFooter("Nộp kết quả đếm",'data-ic08-action="submit-first"')}));
  }
  function v350Render045(state){
    if(activeFlowId!=="UIF-08")return ac340Base045(state);
    if(!["RECOUNT_REQUIRED","READY","LOCKED","PRICE_BASIS_REQUIRED","EVIDENCE_REQUIRED","VALIDATION_ERROR"].includes(state))return ac340Base045(state);
    if(!v350Ic08DiscrepancyIds.length)v350Ic08Recompute();
    if(!v350Ic08DiscrepancyIds.length) v350Ic08DiscrepancyIds=["amox","glove"]; // direct Inspector fixture only
    const locked=state==="LOCKED",price=state==="PRICE_BASIS_REQUIRED",evidence=state==="EVIDENCE_REQUIRED";
    const notice=locked?vBanner("warning","Phiên đang chỉ đọc","Không thể sửa kết quả đếm trong trạng thái hiện hành."):price?vBanner("error","Chưa đủ căn cứ giá","Dòng thừa chưa có căn cứ giá hợp lệ."):evidence?vBanner("warning","Chưa đủ bằng chứng","Bổ sung bằng chứng cần thiết trước khi gửi duyệt."):state==="VALIDATION_ERROR"?vBanner("error","Kết quả đếm lại chưa hợp lệ","Nhập số lượng đếm lại cho tất cả dòng chênh lệch."):vBanner("info","Chỉ đếm lại dòng có chênh lệch","Số theo sổ đã được hiển thị sau lần đếm đầu.");
    const groups=v350Ic08DiscrepancyIds.map(id=>{const m=v350Ic08Meta[id],first=nonBlank(ic08Counts[id])?num(ic08Counts[id]):(id==="amox"?18:7);return ac310RecountGroup({id,name:m.name,code:m.code,lot:m.lot,uom:m.uom,book:v350Ic08Book[id],first,variance:v350Ic08Variance(id,first),value:ic08Recounts[id],disabled:locked});});
    const evidenceRows=v350Ic08DiscrepancyIds.map(id=>[v350Ic08Meta[id].name,price?"Thiếu căn cứ giá":evidence?"Thiếu bằng chứng":"Đã đủ căn cứ"]);
    const body=`${notice}<div class="ac310-product-control-list ac340-product-task-list">${groups.join("")}</div>${ac310InfoSurface("Căn cứ và bằng chứng",evidenceRows)}${ic08Overlays()}`;
    let actions="";if(!locked)actions=`<footer class="app-actions figma-sticky-footer ac310-footer-stack"><button class="button button--primary" type="button" data-ic08-action="submit-recount" ${price||evidence?'disabled':''}>Gửi chờ duyệt</button>${price||evidence?`<button class="button button--secondary ac310-danger-text" type="button" data-ic08-action="cancel-open">Hủy phiên</button>`:""}</footer>`;
    return ac310Return(appShell({title:"Chênh lệch và đếm lại",body,actions}));
  }
  function v350Render046(state){
    if(activeFlowId!=="UIF-08")return ac340Base046(state);
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner("warning","Không thể tự duyệt","Người thực hiện kiểm kê không được duyệt chính kết quả của mình."),back:false});
    if(state==="APPROVAL_ALREADY_DECIDED")return appShell({title:"Duyệt kết quả kiểm kê",body:vBanner("info","Công việc đã có quyết định","Mở kết quả kiểm kê để xem trạng thái hiện hành."),actions:primaryFooter("Xem kết quả",'data-v350-action="ic08-approval-result"'),back:false});
    if(!["READY","APPROVAL_REVIEW"].includes(state))return ac340Base046(state);
    const ids=v350Ic08DiscrepancyIds.length?v350Ic08DiscrepancyIds:["amox","glove"];
    const groups=ids.map(id=>{const m=v350Ic08Meta[id],first=nonBlank(ic08Counts[id])?num(ic08Counts[id]):(id==="amox"?18:7),final=nonBlank(ic08Recounts[id])?num(ic08Recounts[id]):first;return ac340ReviewProduct({name:m.name,code:m.code,meta:`Lô ${m.lot} · ${m.uom}`,variance:v350Ic08Variance(id,final),rows:[["Kết quả cuối",`${final} ${m.uom}`],["Bằng chứng","Đã đủ"]]});}).join("");
    const noDiff=ids.every(id=>{const v=nonBlank(ic08Recounts[id])?num(ic08Recounts[id]):num(ic08Counts[id]||v350Ic08Book[id]);return v===v350Ic08Book[id];});
    const body=`${vBanner("info","Cần quyết định độc lập",noDiff?"Kết quả cuối không còn chênh lệch. Người duyệt xác nhận để hoàn tất phiên.":"Người duyệt chỉ rà soát bằng chứng và quyết định; không sửa số đếm.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03"],["Người thực hiện","Nguyễn An"],["Kho","Kho trung tâm"],["Dòng cần quyết định",`${ids.length} dòng`]])}<div class="ac340-review-list">${groups}</div>${ic08Overlays()}`;
    const actions=`<footer class="app-actions figma-sticky-footer ac310-two-actions"><button class="button button--secondary" type="button" data-v350-action="ic08-request-review">Yêu cầu xem lại</button><button class="button button--primary" type="button" data-v350-action="ic08-approve">Duyệt${noDiff?"":" và điều chỉnh"}</button></footer>`;
    return ac310Return(appShell({title:"Duyệt kiểm kê",body,actions,back:false}));
  }
  renderers["SCR-044"]=v350Render044;
  renderers["SCR-045"]=v350Render045;
  renderers["SCR-046"]=v350Render046;
  const v350Render047Base=renderers["SCR-047"];
  renderers["SCR-047"]=function(state){
    if(activeFlowId!=="UIF-08"||state!=="COMPLETED")return v350Render047Base(state);
    const title=v350Ic08AdjustedCount?"Đã hoàn tất kiểm kê":"Đã hoàn tất kiểm kê — không cần điều chỉnh";
    const desc=v350Ic08AdjustedCount?"Điều chỉnh tồn kho đã được ghi theo quyết định duyệt và phạm vi đã mở khóa.":"Kết quả kiểm đếm khớp số sổ. Phiên hoàn tất mà không tạo bút toán điều chỉnh.";
    const rows=[["Phiên","KK-0709-03"],["Điều chỉnh",v350Ic08AdjustedCount?"ADJ-0709-03":"Không tạo"],["Số dòng điều chỉnh",String(v350Ic08AdjustedCount)],["Khóa phạm vi","Đã mở"]];
    return appShell({title:"Kết quả kiểm kê",body:ds24Result(title,desc,rows),actions:primaryFooter("Về kiểm kê",'data-ic08-action="to-list"'),centered:true,back:false});
  };

  // -------------------------------------------------------------------------
  // BJ09 — state-change reason must be an actual request field.
  // -------------------------------------------------------------------------
  let v350Ic09Reason="";
  let v350Ic09Request=null;
  const v350Render038Base=renderers["SCR-038"];
  renderers["SCR-038"]=function(state){
    if(activeFlowId!=="UIF-09")return v350Render038Base(state);
    const x=ic09Current();const req=v350Ic09Request;const requestDest=req?.destination||ic09Destination;const requestReason=req?.reason||v350Ic09Reason;const dest=requestDest==="QUARANTINE"?"Cách ly":requestDest==="DAMAGED"?"Hỏng":requestDest==="DEMO"?"Dùng thử":"Bán được";
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt thay đổi tình trạng",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu này."),back:false});
    if(state==="APPROVAL_REVIEW"){
      const body=`${vBanner("info","Yêu cầu thay đổi tình trạng","Kiểm tra lý do và phạm vi trước khi quyết định.")}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Từ",x.label],["Sang",dest],["Số lượng",`${x.qty} ${x.uom}`],["Lý do",requestReason||"—"]])}`;
      return appShell({title:"Duyệt thay đổi tình trạng",body,actions:`<div class="ic-action-stack">${icSecondary("Từ chối",'data-v350-action="ic09-reject"','danger')}${primaryFooter("Duyệt",'data-v350-action="ic09-approve"')}</div>`,back:false});
    }
    if(state==="PENDING_APPROVAL")return appShell({title:"Chuyển tình trạng hàng",body:`${vBanner("info","Đã gửi chờ duyệt","Người duyệt nhận một công việc riêng; hàng chưa đổi tình trạng.")}${icHeaderRows([["Sản phẩm",x.name,true],["Từ",x.label],["Sang",dest],["Lý do",requestReason||"—"]])}`,back:false});
    if(["PERMISSION_DENIED","LOCKED"].includes(state))return v350Render038Base(state);
    const error=state==="VALIDATION_ERROR"?vBanner("error","Chưa đủ thông tin","Chọn tình trạng đích và nhập lý do."):"";
    const choices=[icChoice("QUARANTINE","Cách ly","Tạm thời không bán",ic09Destination==="QUARANTINE"),icChoice("DAMAGED","Hỏng","Không còn đủ điều kiện bán",ic09Destination==="DAMAGED"),icChoice("DEMO","Dùng thử","Chuyển sang mục đích dùng thử",ic09Destination==="DEMO")];if(x.state!=="SELLABLE")choices.push(icChoice("SELLABLE","Bán được","Chỉ khi hàng đủ điều kiện trở lại bán",ic09Destination==="SELLABLE"));
    const body=`${error}${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot],["Hiện tại",x.label],["Số lượng",`${x.qty} ${x.uom}`]])}${ioSectionTitle("Tình trạng mới")}<div class="choice-list">${choices.join("")}</div>${icTextarea("Lý do",v350Ic09Reason,'data-v350-ic09-reason','Nhập lý do')}`;
    return appShell({title:"Chuyển tình trạng hàng",body,actions:primaryFooter("Gửi xử lý",'data-v350-action="ic09-submit"')});
  };

  // -------------------------------------------------------------------------
  // BJ10 — disposal request/approval/completion use one bound model.
  // -------------------------------------------------------------------------
  let v350Ic10RequestQty="",v350Ic10Reason="",v350Ic10Evidence="",v350Ic10ApprovedQty=0,v350Ic10ActualQty="",v350Ic10Proof="",v350Ic10CompletedQty=0;
  function v350Ic10RequestValid(){const q=num(v350Ic10RequestQty);return q>0&&q<=6&&nonBlank(v350Ic10Reason)&&nonBlank(v350Ic10Evidence);}
  function v350Ic10CompletionValid(){const q=num(v350Ic10ActualQty);return q>0&&q<=num(v350Ic10ApprovedQty)&&nonBlank(v350Ic10Proof);}
  const v350Render040Base=renderers["SCR-040"];
  renderers["SCR-040"]=function(state){
    if(activeFlowId!=="UIF-10")return v350Render040Base(state);
    if(state==="PERMISSION_DENIED")return v350Render040Base(state);
    const base=icHeaderRows([["Sản phẩm","Amox 500",true],["Lô","L2407-A"],["Tình trạng","Cách ly"],["Có thể xử lý","6 hộp"]]);
    if(state==="SELF_APPROVAL_NOT_ALLOWED")return appShell({title:"Duyệt tiêu hủy",body:vBanner("warning","Không thể tự duyệt","Người lập yêu cầu không được tự duyệt yêu cầu tiêu hủy."),back:false});
    if(state==="PENDING_APPROVAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("info","Đã gửi chờ duyệt","Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.")}${base}${icHeaderRows([["Số lượng đề nghị",`${v350Ic10RequestQty} hộp`,true],["Lý do",v350Ic10Reason],["Bằng chứng",v350Ic10Evidence],["Tác động tồn kho","Chưa có"]])}`,back:false});
    if(state==="APPROVAL_REVIEW")return appShell({title:"Duyệt tiêu hủy",body:`${vBanner("info","Phê duyệt chưa phải tiêu hủy","Duyệt chỉ cho phép chuyển yêu cầu sang chờ xử lý thực tế; tồn vật lý chưa giảm.")}${base}${icHeaderRows([["Số lượng đề nghị",`${v350Ic10RequestQty} hộp`,true],["Lý do",v350Ic10Reason||"—"],["Bằng chứng",v350Ic10Evidence||"—"],["Căn cứ giá","Giá vốn hiện hành"]])}`,actions:`<div class="ic-action-stack">${icSecondary("Từ chối",'data-v350-action="ic10-reject"','danger')}${primaryFooter("Duyệt",'data-v350-action="ic10-approve"')}</div>`,back:false});
    if(state==="APPROVED_PENDING_DISPOSAL")return appShell({title:"Yêu cầu tiêu hủy",body:`${vBanner("success","Đã duyệt — chờ xử lý thực tế","Tồn kho vẫn giữ nguyên cho đến khi người thực hiện xác nhận xử lý thực tế.")}${base}${icHeaderRows([["Đã duyệt",`${v350Ic10ApprovedQty} hộp`,true],["Tồn vật lý hiện tại","6 hộp · chưa giảm"]])}`,back:false});
    if(state==="COMPLETION"||state==="COMPLETION_QTY_BLOCKED"){
      const blocked=state==="COMPLETION_QTY_BLOCKED";
      const body=`${blocked?vBanner("error","Số lượng thực tế vượt phạm vi được duyệt",`Tối đa ${v350Ic10ApprovedQty} hộp. Không thể ghi giảm phần vượt.`):vBanner("warning","Chỉ xác nhận sau khi đã xử lý thực tế","Số lượng thực tế sẽ là căn cứ ghi giảm tồn.")}${base}${icField("Đã tiêu hủy thực tế",v350Ic10ActualQty,'data-v350-ic10-actual','number')}${icTextarea("Bằng chứng",v350Ic10Proof,'data-v350-ic10-proof','Nhập số biên bản hoặc bằng chứng')}`;
      return appShell({title:"Xác nhận đã tiêu hủy",body,actions:primaryFooter("Xác nhận đã tiêu hủy",'data-v350-action="ic10-complete"',false,"danger"),back:false});
    }
    const invalid=state==="VALIDATION_ERROR";const price=state==="PRICE_BASIS_REQUIRED";
    const body=`${invalid?vBanner("error","Chưa đủ thông tin","Số lượng phải từ 1 đến 6 hộp; lý do và bằng chứng là bắt buộc."):""}${price?vBanner("error","Chưa có căn cứ giá hợp lệ","Không thể gửi yêu cầu cho đến khi có căn cứ giá chính thức."):""}${base}${icField("Số lượng đề nghị",v350Ic10RequestQty,'data-v350-ic10-qty','number')}${icTextarea("Lý do",v350Ic10Reason,'data-v350-ic10-reason')}${icTextarea("Bằng chứng",v350Ic10Evidence,'data-v350-ic10-evidence')}${icHeaderRows([["Căn cứ giá","Giá vốn hiện hành"]])}`;
    return appShell({title:"Yêu cầu tiêu hủy",body,actions:primaryFooter("Gửi yêu cầu tiêu hủy",'data-v350-action="ic10-submit"',price)});
  };
  const v350Render041Base=renderers["SCR-041"];
  renderers["SCR-041"]=function(state){
    if(activeFlowId==="UIF-10" && state==="COMPLETED")return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy",`${v350Ic10CompletedQty||v350Ic10ApprovedQty} hộp`],["Tồn vật lý còn lại",`${Math.max(0,6-(v350Ic10CompletedQty||v350Ic10ApprovedQty))} hộp`]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
    return v350Render041Base(state);
  };

  // -------------------------------------------------------------------------
  // BJ12 — independent control total and approval snapshot.
  // -------------------------------------------------------------------------
  let v350Cf12ApprovalHash=null;
  const v350Cf12Hash=()=>[cf12FileName,cf12Cutoff,cf12ControlQty,cf12ControlValue,cf12Summary.rows,cf12Summary.parsedQty,cf12Summary.parsedValue].join("|");
  const v350Cf12Matches=()=>num(cf12ControlQty)===num(cf12Summary.parsedQty)&&num(cf12ControlValue)===num(cf12Summary.parsedValue);
  const v350Render067Base=renderers["SCR-067"];
  renderers["SCR-067"]=(state)=>activeFlowId==="UIF-12"?v350Render067Base(state).replace(/data-cf12-action="check"/g,'data-v350-action="cf12-check"'):v350Render067Base(state);
  const v350Render069Base=renderers["SCR-069"];
  renderers["SCR-069"]=(state)=>activeFlowId==="UIF-12"?v350Render069Base(state).replace(/data-cf12-action="send-approval"/g,'data-v350-action="cf12-send-approval"'):v350Render069Base(state);
  const v350Render070Base=renderers["SCR-070"];
  renderers["SCR-070"]=(state)=>activeFlowId==="UIF-12"?v350Render070Base(state).replace(/data-cf12-action="approve"/g,'data-v350-action="cf12-approve"'):v350Render070Base(state);
  const v350Render068Base=renderers["SCR-068"];
  renderers["SCR-068"]=function(state){
    if(activeFlowId!=="UIF-12")return v350Render068Base(state);
    if(state!=="CONTROL_TOTAL_MISMATCH")return v350Render068Base(state);
    const dq=num(cf12ControlQty)-num(cf12Summary.parsedQty),dv=num(cf12ControlValue)-num(cf12Summary.parsedValue);
    const body=`${vBanner("warning","Số kiểm soát không khớp","Không gửi phê duyệt cho đến khi tệp chi tiết khớp nguồn kiểm soát độc lập.")}${crFactCard("Đối chiếu số lượng",[["Theo tệp",cfNumber(cf12Summary.parsedQty),true],["Số kiểm soát",cfNumber(cf12ControlQty),true],["Chênh lệch",`${dq>0?"+":""}${cfNumber(dq)}`]])}${crFactCard("Đối chiếu giá trị",[["Theo tệp",cfMoney(cf12Summary.parsedValue),true],["Số kiểm soát",cfMoney(cf12ControlValue),true],["Chênh lệch",cfMoney(dv)]])}`;
    return appShell({title:"Kiểm tra dữ liệu",body,actions:primaryFooter("Sửa số kiểm soát",'data-cf12-action="back-file"')});
  };

  // -------------------------------------------------------------------------
  // BJ14 — successor must preserve immediate predecessor and policy method.
  // -------------------------------------------------------------------------
  const v350Render073Base=renderers["SCR-073"];
  renderers["SCR-073"]=function(state){
    if(activeFlowId!=="UIF-14")return v350Render073Base(state);
    if(state==="PERMISSION_DENIED")return v350Render073Base(state);
    const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;
    const periodClose=val14SetupKind==="PERIOD_CLOSE";
    const method=base?.policyLabel||"Bình quân cuối kỳ",policy=base?.policyVersion||"Chính sách giá vốn";
    const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:"04/09/2026 · 14:30")}${ds24InfoRow("Phương pháp công bố",method)}${ds24InfoRow("Chính sách",policy)}`,"valuation-info-group");
    const body=`${base?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới kế thừa đúng phương pháp và thay thế trực tiếp lần tính này; lần cũ được giữ để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label><label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>${setupFacts}`;
    return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
  };

  // -------------------------------------------------------------------------
  // BJ15 — report filters constrain actual datasets and export scope.
  // -------------------------------------------------------------------------
  cf15Movements.forEach(m=>{m.productId ||= "P-NOB";});
  if(!cf15Movements.some(m=>m.productId==="P-AMX"))cf15Movements.push({id:"MV-AMX-01",productId:"P-AMX",label:"Nhận hàng",source:"PN-260907-11",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:12,delta:6,after:18,uom:"hộp",lot:"L2407-A",state:"Bán được",value:720000});
  if(!cf15Movements.some(m=>m.productId==="P-GLV"))cf15Movements.push({id:"MV-GLV-01",productId:"P-GLV",label:"Kiểm kê",source:"KK-0709-03",business:"07/09/2026",recorded:"07/09/2026",actor:"Nguyễn An",before:5,delta:1,after:6,uom:"hộp",lot:"L2405-M",state:"Bán được",value:0});
  function v350DateIso(v){const m=String(v||"").match(/^(\d{2})\/(\d{2})\/(\d{4})/);return m?`${m[3]}-${m[2]}-${m[1]}`:String(v||"").slice(0,10);}
  function v350Cf15Products(){return cf15Product==="ALL"?cf15Products:cf15Products.filter(p=>p.id===cf15Product);}
  function v350Cf15Movements(mode=cf15DateMode){const pid=cf15Product==="ALL"?cf15SelectedProduct:cf15Product;return cf15Movements.filter(m=>(!pid||m.productId===pid)).filter(m=>{const d=v350DateIso(mode==="RECORDED"?m.recorded:m.business);return (!cf15From||d>=cf15From)&&(!cf15To||d<=cf15To);});}
  cf15InventoryResult=function(state,mode){
    const financeAllowed=state!=="FINANCIAL_RESTRICTED",products=v350Cf15Products();
    if(!products.length)return `${cf15ContextBanner(state,mode)}${ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}`;
    const rows=products.map(p=>ioProductRow({name:p.name,code:p.code,primary:`${cfNumber(p.qty)} ${p.uom}`,secondary:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,attr:`data-cf15-product-row="${p.id}"`})).join("");
    const totalValue=products.reduce((a,x)=>a+x.value,0);
    return `${cf15ContextBanner(state,mode)}${cfSummaryGrid([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}<div class="io-list-card" data-ds-component="VSection" data-composed-from="DS v2 / List Row"><div class="io-product-list">${rows}</div></div><p class="io-footnote">Không cộng các số lượng khác đơn vị thành một tổng giả.</p><div class="cf-inline-actions">${cfSecondary("Xuất báo cáo",'data-cf15-action="export"')}</div>${cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
  };
  cf15StockCardResult=function(state,mode){
    const financeAllowed=state!=="FINANCIAL_RESTRICTED";const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);const movements=v350Cf15Movements(mode);
    const movRows=movements.map(m=>`<button class="cf-movement-row" type="button" data-cf15-movement="${m.id}" data-ds-component="DS v2 / List Row"><span><strong>${m.label}</strong><small>${mode==="RECORDED"?m.recorded:m.business} · ${m.source}</small></span><span class="cf-movement-values"><strong>${m.delta>0?"+":""}${m.delta} ${m.uom}</strong><small>Còn ${m.after} ${m.uom}</small></span>${navChevron()}</button>`).join("");
    return `${cf15ContextBanner(state,mode)}${crFactCard(p.name,[["Mã",p.code,true],["Tồn hiện tại",`${cfNumber(p.qty)} ${p.uom}`],["Khả dụng bán",`${cfNumber(p.available)} ${p.uom}`],...(financeAllowed?[["Giá trị tồn",cfMoney(p.value)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ trong phạm vi quyền.")}${movements.length?`<div class="cf-movement-list">${movRows}</div>`:ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}<div class="cf-inline-actions">${cfSecondary("Xuất thẻ kho",'data-cf15-action="export"')}</div>`;
  };
  const v350Render055Base=renderers["SCR-055"];
  renderers["SCR-055"]=function(state){
    if(activeFlowId!=="UIF-15")return v350Render055Base(state);
    if(!["READY","RECORDED_DATE_VIEW","BUSINESS_DATE_VIEW","FINANCIAL_RESTRICTED","FILTER_EMPTY","EMPTY","LOADING","PERMISSION_DENIED"].includes(state))return v350Render055Base(state);
    if(["FILTER_EMPTY","EMPTY","LOADING","PERMISSION_DENIED"].includes(state))return v350Render055Base(state);
    const mode=state==="RECORDED_DATE_VIEW"?"RECORDED":state==="BUSINESS_DATE_VIEW"?"BUSINESS":cf15DateMode;
    const financeAllowed=state!=="FINANCIAL_RESTRICTED";
    if(cf15ReportType==="INVENTORY"){
      const products=v350Cf15Products();
      if(!products.length)return ac310Return(appShell({title:"Báo cáo tồn kho",body:ioEmpty("Không có dữ liệu phù hợp","Đổi phạm vi hoặc kỳ báo cáo để kiểm tra lại.")}));
      const rows=products.map((p)=>ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom} · Khả dụng ${cfNumber(p.available)} ${p.uom}`,attrs:`data-cf15-product-row="${p.id}"`})).join("");
      const totalValue=products.reduce((a,x)=>a+x.value,0);
      const body=`${cf15ContextBanner(state,mode)}${ac310SummaryMetrics([["Sản phẩm",products.length],["Kho","Kho trung tâm"],...(financeAllowed?[["Tổng giá trị",cfMoney(totalValue)]]:[])])}${financeAllowed?"":vBanner("info","Giá trị tài chính đã được ẩn","Bạn vẫn có thể xem số lượng trong phạm vi được cấp quyền.")}${ac310ListSurface(rows)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất báo cáo</button>${ac310Cf15ProductSheet(cf15ProductById(cf15SelectedProduct),financeAllowed)}`;
      return ac310Return(appShell({title:"Báo cáo tồn kho",subtitle:`Kho trung tâm · ${cf15DateLabel(mode)}`,body}));
    }
    const p=cf15ProductById(cf15Product==="ALL"?cf15SelectedProduct:cf15Product);
    const filtered=v350Cf15Movements(mode);
    if(!filtered.length)return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body:`${cf15ContextBanner(state,mode)}${ioEmpty("Không có biến động trong kỳ","Đổi khoảng ngày hoặc sản phẩm để xem dữ liệu khác.")}`}));
    const movements=filtered.map((m)=>ac310RecordRow({title:m.label,subtitle:`${mode==="RECORDED"?m.recorded:m.business} · ${m.source}`,badge:`${m.delta>0?"+":""}${m.delta} ${m.uom}`,tone:"Neutral",attrs:`data-cf15-movement="${m.id}"`,leading:null})).join("");
    const body=`${cf15ContextBanner(state,mode)}${ac310ProductRow({name:p.name,code:p.code,meta:`${cfNumber(p.qty)} ${p.uom}`,badge:`Khả dụng ${cfNumber(p.available)} ${p.uom}`,tone:"Success",status:true})}${financeAllowed?ac310KeyValueSurface("",[["Giá trị tồn",cfMoney(p.value),true]]):vBanner("info","Giá trị tài chính đã được ẩn","Thẻ kho vẫn hiển thị số lượng và nguồn nghiệp vụ.")}${ac310SectionTitle("Biến động")}${ac310ListSurface(movements)}<button class="button button--secondary ac310-inline-button" type="button" data-cf15-action="export">Xuất thẻ kho</button>`;
    return ac310Return(appShell({title:"Thẻ kho",subtitle:`${p.name} · ${cf15DateLabel(mode)}`,body}));
  };
  const v350Render058Base=renderers["SCR-058"];
  renderers["SCR-058"]=function(state){
    if(activeFlowId!=="UIF-15"||state!=="READY")return v350Render058Base(state);
    const sourceLabel=cf15ExportFrom==="SOURCE"?"Bằng chứng biến động":cf15ReportType==="STOCK_CARD"?"Thẻ kho":"Báo cáo tồn kho";
    const productLabel=cf15Product==="ALL"?"Tất cả sản phẩm":cf15ProductById(cf15Product).name;
    const count=cf15ReportType==="STOCK_CARD"?v350Cf15Movements(cf15DateMode).length:v350Cf15Products().length;
    const body=`${crFactCard("Phạm vi xuất",[["Nội dung",sourceLabel,true],["Kho","Kho trung tâm"],["Sản phẩm",productLabel],["Kỳ",`${cfDateVN(cf15From)} → ${cfDateVN(cf15To)}`],["Cách hiểu thời gian",cf15DateLabel()],["Số dòng trong phạm vi",String(count)],["Giá trị tài chính",cf15FinanceIncluded?"Có":"Không"]])}${crFactCard("Định dạng",[["Tệp","CSV",true],["Quyền dữ liệu","Giữ đúng như màn đang xem"]])}<p class="io-footnote">Tệp xuất giữ đúng bộ lọc, khoảng ngày, quyền và mốc dữ liệu của kết quả đang xem.</p>`;
    return appShell({title:"Xuất báo cáo",body,actions:primaryFooter("Xuất báo cáo",'data-cf15-action="confirm-export"'),backAction:"cf15-back-export"});
  };

  // -------------------------------------------------------------------------
  // BJ16 / BJ17 — context integrity + evidence freshness + safe finality.
  // -------------------------------------------------------------------------
  cr16Cases.forEach((c,i)=>{c.evidenceVersion ??= 1;c.planEvidenceVersion ??= null;c.recoveryEvidenceVersion ??= null;c.closed ??= false;if(c.id==="REC-260907-04")c.correctionOperationId="IO-260904-021";});
  if(!cr11Operations.some(o=>o.id==="IO-260904-021"))cr11Operations.splice(2,0,{id:"IO-260904-021",type:"Nhận hàng",source:"PN-260904-08",status:"COMPLETED",statusLabel:"Có thể sửa",route:"CORRECT",warehouse:"Kho trung tâm",product:"Amox 500 · Lô L2407-A",qty:20,uom:"hộp",correctQty:18,impact:"Đã tăng tồn 20 hộp"});
  cr17Cases.forEach(c=>{c.evidenceVersion ??= 1;c.planEvidenceVersion ??= null;c.resolutionRecord ??= null;c.sourceFlow ??= "UIF-17";});
  const v350Render079Base=renderers["SCR-079"],v350Render080Base=renderers["SCR-080"],v350Render081Base=renderers["SCR-081"],v350Render082Base=renderers["SCR-082"],v350Render083Base=renderers["SCR-083"];
  renderers["SCR-079"]=function(state){
    if(activeFlowId!=="UIF-16")return v350Render079Base(state);
    const c=cr16Current();const actual=state==="READY"?cr079StateFor16(c):state;
    if(actual==="SOURCE_MISMATCH")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("info","Đang chờ nghiệp vụ nguồn xác minh","Kho không tự sửa dữ liệu nguồn. Chuyển đúng hồ sơ và phạm vi cho phân hệ sở hữu nguồn.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý hiện tại",c.owner],["Bảo vệ phạm vi","Đang áp dụng"]])}${crEvidenceCard(cr16EvidenceRows(c))}`,actions:primaryFooter("Chuyển cho nghiệp vụ nguồn",'data-v350-action="cr16-source-handoff"')});
    if(actual==="CORRECTION_REQUIRED")return appShell({title:"Bằng chứng & kết luận",body:`${vBanner("warning","Cần sửa nghiệp vụ đã hoàn tất","Sai lệch nằm ở nghiệp vụ nguồn. Không chỉnh số dư trực tiếp.")}${crFactCard(c.id,[["Phạm vi",c.scope,true],["Người xử lý",c.owner]])}${crEvidenceCard(cr16EvidenceRows(c))}`,actions:primaryFooter("Mở yêu cầu sửa sai",'data-v350-action="cr16-correction-handoff"')});
    const html=v350Render079Base(state);return html.replace(/data-cr16-action="open-plan"/g,'data-v350-action="cr16-open-plan"').replace(/data-cr16-action="review-close"/g,'data-v350-action="cr16-review-close"');
  };
  renderers["SCR-080"]=function(state){
    const html=v350Render080Base(state);
    if(activeFlowId==="UIF-16")return html.replace(/data-cr16-action="start-recovery"/g,'data-v350-action="cr16-start-recovery"');
    if(activeFlowId==="UIF-17")return html.replace(/data-cr17-action="execute-plan"/g,'data-v350-action="cr17-execute-plan"').replace(/data-cr17-action="show-escalated"/g,'data-v350-action="cr17-show-escalated"');
    return html;
  };
  renderers["SCR-081"]=function(state){const html=v350Render081Base(state);return activeFlowId==="UIF-16"?html.replace(/data-cr16-action="review-result"/g,'data-v350-action="cr16-review-result"'):html;};
  renderers["SCR-082"]=function(state){
    if(activeFlowId==="UIF-16"&&state==="MISMATCH_REMAINS")return appShell({title:"Rà soát kết quả",body:`${vBanner("warning","Sai lệch vẫn còn","Giữ hồ sơ mở và phạm vi được bảo vệ. Quay lại bằng chứng để tiếp tục điều tra.")}${crFactCard(cr16Current().id,[["Sổ kho","118 hộp"],["Số liệu hiển thị","117 hộp"],["Chênh lệch","−1 hộp",true]])}`,actions:primaryFooter("Quay lại bằng chứng",'data-v350-action="cr16-back-evidence"')});
    const html=v350Render082Base(state);
    if(activeFlowId==="UIF-16")return html.replace(/data-cr16-action="close-case"/g,'data-v350-action="cr16-close-case"');
    if(activeFlowId==="UIF-17")return html.replace(/data-cr17-action="finish-review"/g,'data-v350-action="cr17-finish-review"');
    return html;
  };
  renderers["SCR-083"]=function(state){return v350Render083Base(state);};

  // -------------------------------------------------------------------------
  // UNKNOWN result routing — a result in doubt must not silently return/retry.
  // -------------------------------------------------------------------------
  function wrapUnknown(screenId,flowId,metaFactory){const base=renderers[screenId];renderers[screenId]=function(state){if(activeFlowId===flowId&&["UNKNOWN","COMMIT_UNKNOWN"].includes(state))return v350UnknownResult(metaFactory());return base(state);};}
  const unknowns=[
    ["SCR-019","UIF-03",()=>({sourceFlow:"UIF-03",operation:`Giá trị ban đầu · ${val03Current()?.id||""}`,scope:"Lô/đơn vị vừa xác nhận"})],
    ["SCR-041","UIF-07",()=>({sourceFlow:"UIF-07",operation:io07Current().id,scope:`${io07Current().supplier} · ${io07Current().source}`})],
    ["SCR-047","UIF-08",()=>({sourceFlow:"UIF-08",operation:"KK-0709-03",scope:"Kho trung tâm · phiên kiểm kê"})],
    ["SCR-041","UIF-09",()=>({sourceFlow:"UIF-09",operation:`Đổi tình trạng · ${ic09Current().code}`,scope:`${ic09Current().name} · Lô ${ic09Current().lot}`})],
    ["SCR-041","UIF-10",()=>({sourceFlow:"UIF-10",operation:"TH-0709-04",scope:"Amox 500 · Lô L2407-A"})],
    ["SCR-066","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})],
    ["SCR-071","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})],
    ["SCR-089","UIF-13",()=>({sourceFlow:"UIF-13",operation:`Chi phí đến muộn · ${val13Current()?.id||""}`,scope:"Phạm vi phân bổ đã xác nhận"})],
    ["SCR-077","UIF-14",()=>({sourceFlow:"UIF-14",operation:val14Current()?.id||"Lần tính giá vốn",scope:`${val14Current()?.period||""} · ${val14Current()?.scope||""}`})]
  ];unknowns.forEach(x=>wrapUnknown(...x));
  // BJ02 verify/handoff-unknown: giữ listener data-v350-action (A10); wrapper SCR-012/013 đã chết (v392).

  // BJ11 navigation action must not create finality.
  const v350Render051Base=renderers["SCR-051"];
  renderers["SCR-051"]=(state)=>activeFlowId==="UIF-11"?v350Render051Base(state).replace(/data-cr11-action="approval-result"/g,'data-v350-action="cr11-approval-result"'):v350Render051Base(state);

  // -------------------------------------------------------------------------
  // Event binding for v3.5.0 controls.
  // -------------------------------------------------------------------------
  document.addEventListener("input",(event)=>{
    if(event.target.matches("[data-v350-ic09-reason]")){v350Ic09Reason=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-qty]")){v350Ic10RequestQty=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-reason]")){v350Ic10Reason=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-evidence]")){v350Ic10Evidence=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-actual]")){v350Ic10ActualQty=event.target.value;return;}
    if(event.target.matches("[data-v350-ic10-proof]")){v350Ic10Proof=event.target.value;return;}
  },true);

  document.addEventListener("click",(event)=>{
    const a=event.target.closest("[data-v350-action]");if(!a||a.disabled)return;
    event.preventDefault();event.stopPropagation();const k=a.dataset.v350Action;
    if(k==="handoff-unknown")return v350HandoffUnknown({sourceFlow:a.dataset.sourceFlow,operation:a.dataset.operation,scope:a.dataset.scope,evidence:"INSUFFICIENT"});
    if(k==="bj02-verify-unknown"){stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN";return navigate("SCR-013");}
    if(k==="bj02-handoff-unknown")return v350HandoffUnknown({sourceFlow:"UIF-02",operation:"Nhận hàng",scope:"Yêu cầu nhận hàng hiện tại",evidence:"INSUFFICIENT"});

    if(k==="ic08-confirm-submit-first"){
      ic08ConfirmKind=null;if(!v350Ic08FirstValid()){stateByScreen["SCR-044"]="VALIDATION_ERROR";return renderAppScreen();}
      v350Ic08Recompute();
      if(v350Ic08DiscrepancyIds.length){v350Ic08DiscrepancyIds.forEach(id=>ic08Recounts[id]="");stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
      stateByScreen["SCR-046"]="APPROVAL_REVIEW";return navigate("SCR-046");
    }
    if(k==="ic08-confirm-submit-recount"){
      ic08ConfirmKind=null;if(!v350Ic08RecountValid()){stateByScreen["SCR-045"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-042"]="PENDING_APPROVAL";return navigate("SCR-042");
    }
    if(k==="ic08-confirm-open-session"){ic08ConfirmKind=null;stateByScreen["SCR-044"]="BLIND_COUNT";return navigate("SCR-044");}
    if(k==="ic08-confirm-cancel"){if(!nonBlank(ic08CancelReason))return;ic08ConfirmKind=null;stateByScreen["SCR-047"]="CANCELLED";return navigate("SCR-047");}
    if(k==="ic08-approve"){if(!isApproverEntry()){stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}ic08ConfirmKind="approve";return renderAppScreen();}
    if(k==="ic08-confirm-approve"){if(!isApproverEntry()){ic08ConfirmKind=null;stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}ic08ConfirmKind=null;v350Ic08AdjustedCount=["amox","glove"].filter(id=>num(nonBlank(ic08Recounts[id])?ic08Recounts[id]:ic08Counts[id])!==v350Ic08Book[id]).length;stateByScreen["SCR-047"]="COMPLETED";return navigate("SCR-047");}
    if(k==="ic08-request-review"){ic08ReviewReason="";ic08ConfirmKind="request-review";return renderAppScreen();}
    if(k==="ic08-confirm-request-review"){if(!isApproverEntry()){ic08ConfirmKind=null;stateByScreen["SCR-046"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}if(!nonBlank(ic08ReviewReason))return;ic08ConfirmKind=null;stateByScreen["SCR-045"]="RECOUNT_REQUIRED";return navigate("SCR-045");}
    if(k==="ic08-approval-result")return navigate("SCR-047");

    if(k==="ic09-submit"){if(!ic09Destination||!nonBlank(v350Ic09Reason)){stateByScreen["SCR-038"]="VALIDATION_ERROR";return renderAppScreen();}const x=ic09Current();v350Ic09Request={itemId:x.id,from:x.state,destination:ic09Destination,reason:v350Ic09Reason.trim()};stateByScreen["SCR-038"]="PENDING_APPROVAL";return renderAppScreen();}
    if(k==="ic09-approve"){if(!isApproverEntry()){stateByScreen["SCR-038"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}const req=v350Ic09Request;if(!req){stateByScreen["SCR-038"]="VALIDATION_ERROR";return renderAppScreen();}const x=ic09Items.find(i=>i.id===req.itemId);if(x){x.state=req.destination;x.label=req.destination==="QUARANTINE"?"Cách ly":req.destination==="DAMAGED"?"Hỏng":req.destination==="DEMO"?"Dùng thử":"Bán được";}stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");}
    if(k==="ic09-reject"){if(!isApproverEntry()){stateByScreen["SCR-038"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}

    if(k==="ic10-submit"){if(!v350Ic10RequestValid()){stateByScreen["SCR-040"]="VALIDATION_ERROR";return renderAppScreen();}stateByScreen["SCR-040"]="PENDING_APPROVAL";return renderAppScreen();}
    if(k==="ic10-approve"){if(!isApproverEntry()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}v350Ic10ApprovedQty=num(v350Ic10RequestQty);stateByScreen["SCR-040"]="APPROVED_PENDING_DISPOSAL";return renderAppScreen();}
    if(k==="ic10-reject"){if(!isApproverEntry()){stateByScreen["SCR-040"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}stateByScreen["SCR-041"]="REJECTED_EXECUTION";return navigate("SCR-041");}
    if(k==="ic10-complete"){
      if(!isCompletionEntry()&&v350ActorMode!=="module"){return;}
      if(num(v350Ic10ActualQty)>num(v350Ic10ApprovedQty)){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
      if(!v350Ic10CompletionValid()){stateByScreen["SCR-040"]="COMPLETION_QTY_BLOCKED";return renderAppScreen();}
      v350Ic10CompletedQty=num(v350Ic10ActualQty);stateByScreen["SCR-041"]="COMPLETED";return navigate("SCR-041");
    }

    if(k==="cf12-check"){
      const valid=Boolean(cf12FileName&&cf12Cutoff&&cf12ControlQty!==""&&cf12ControlValue!==""&&num(cf12ControlQty)>=0&&num(cf12ControlValue)>=0);
      if(!valid){stateByScreen["SCR-067"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-068"]=v350Cf12Matches()?"READY":"CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");
    }
    if(k==="cf12-send-approval"){if(!v350Cf12Matches()){stateByScreen["SCR-068"]="CONTROL_TOTAL_MISMATCH";return navigate("SCR-068");}v350Cf12ApprovalHash=v350Cf12Hash();stateByScreen["SCR-069"]="PENDING_APPROVAL";stateByScreen["SCR-066"]="PENDING_APPROVAL";return navigate("SCR-066");}
    if(k==="cf12-approve"){
      if(!isApproverEntry()){stateByScreen["SCR-070"]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();}
      if(!v350Cf12ApprovalHash||v350Cf12ApprovalHash!==v350Cf12Hash()){stateByScreen["SCR-070"]="VALIDATION_ERROR";return renderAppScreen();}
      stateByScreen["SCR-071"]="PROCESSING";navigate("SCR-071");setTimeout(()=>{if(activeFlowId==="UIF-12"&&activeScreenId==="SCR-071"&&stateByScreen["SCR-071"]==="PROCESSING"){stateByScreen["SCR-071"]="COMPLETED";stateByScreen["SCR-066"]="ACTIVE_RECONCILED";render();}},420);return;
    }

    if(k==="cr11-approval-result")return navigate("SCR-053");
    if(k==="cr16-correction-handoff"){const c=cr16Current();const opId=c.correctionOperationId;if(!opId)return;cr11SelectedId=opId;stateByScreen["SCR-049"]="CORRECTABLE";return crSwitchFlow("UIF-11","SCR-049","CORRECTABLE");}
    if(k==="cr16-source-handoff"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
    if(k==="cr16-open-plan"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-080"]="READY";return navigate("SCR-080");}
    if(k==="cr16-start-recovery"){const c=cr16Current();if(num(c.planEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}c.recoveryEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-081"]="REBUILDING";navigate("SCR-081");setTimeout(()=>{if(activeFlowId==="UIF-16"&&activeScreenId==="SCR-081"){const cc=cr16Current();stateByScreen["SCR-081"]=num(cc.recoveryEvidenceVersion)===num(cc.evidenceVersion)?"READY":"CONFLICT";render();}},250);return;}
    if(k==="cr16-review-result"){const c=cr16Current();if(num(c.recoveryEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-081"]="CONFLICT";return renderAppScreen();}stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
    if(k==="cr16-review-close"){const c=cr16Current();c.planEvidenceVersion=c.evidenceVersion;stateByScreen["SCR-082"]="READY";return navigate("SCR-082");}
    if(k==="cr16-close-case"){const c=cr16Current();const snap=c.recoveryEvidenceVersion??c.planEvidenceVersion;if(num(snap)!==num(c.evidenceVersion)){stateByScreen["SCR-082"]="MISMATCH_REMAINS";return renderAppScreen();}c.closed=true;stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");}
    if(k==="cr16-back-evidence"){stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());return navigate("SCR-079");}

    if(k==="cr17-execute-plan"){
      const c=cr17Current();if(!c.planEvidenceVersion)c.planEvidenceVersion=c.evidenceVersion;
      if(num(c.planEvidenceVersion)!==num(c.evidenceVersion)){stateByScreen["SCR-080"]="CONFLICT";return renderAppScreen();}
      cr17ResolutionMode=c.evidence==="COMMITTED"?"COMMITTED":"CONTINUED";
      c.resolutionRecord={operationId:c.operation,scope:c.scope,evidenceVersion:c.evidenceVersion,newOperationCreated:false,duplicateEffect:false,mode:cr17ResolutionMode};
      stateByScreen["SCR-082"]="READY";return navigate("SCR-082");
    }
    if(k==="cr17-finish-review"){
      const c=cr17Current(),r=c.resolutionRecord;if(!r||!same(r.operationId,c.operation)||!same(r.scope,c.scope)||num(r.evidenceVersion)!==num(c.evidenceVersion)||r.newOperationCreated||r.duplicateEffect){stateByScreen["SCR-080"]="CONFLICT";return navigate("SCR-080");}
      stateByScreen["SCR-083"]="COMPLETED";return navigate("SCR-083");
    }
    if(k==="cr17-show-escalated"){stateByScreen["SCR-083"]="ESCALATED";return navigate("SCR-083");}
  },true);

  // Snapshot the recovery plan when it is opened with existing BJ17 controls.
  document.addEventListener("click",(event)=>{const a=event.target.closest('[data-cr17-action="open-plan"]');if(!a||activeFlowId!=="UIF-17")return;const c=cr17Current();c.planEvidenceVersion=c.evidenceVersion;c.resolutionRecord=null;},true);
  // Normal-return stale source feedback after legacy commit handler refuses commit.


  // Reset per-request drafts when the user starts a new business task.
  document.addEventListener("click",(event)=>{
    if(activeFlowId==="UIF-09" && event.target.closest("[data-ic09-action=\"change\"]")){v350Ic09Reason="";v350Ic09Request=null;}
    if(activeFlowId==="UIF-09" && event.target.closest("[data-ic09-item]")){v350Ic09Reason="";v350Ic09Request=null;}
    if(activeFlowId==="UIF-10" && event.target.closest("[data-ic10-action=\"request\"]")){v350Ic10RequestQty="";v350Ic10Reason="";v350Ic10Evidence="";v350Ic10ApprovedQty=0;v350Ic10ActualQty="";v350Ic10Proof="";v350Ic10CompletedQty=0;}
  },true);

  // -------------------------------------------------------------------------
  // Actor ownership — decision actions are executable only in the assigned
  // approver/completion context. Navigation/open-sheet actions remain harmless.
  // -------------------------------------------------------------------------
  const v350Render051ActorBase=renderers["SCR-051"];
  renderers["SCR-051"]=function(state){
    if(activeFlowId!=="UIF-11")return v350Render051ActorBase(state);
    return v350Render051ActorBase(state)
      .replace(/data-cr11-action="approve"/g,'data-v350-action="cr11-approve"')
      .replace(/data-cr11-action="reject-confirm"/g,'data-v350-action="cr11-reject-confirm"');
  };
  const v350Render070ActorBase=renderers["SCR-070"];
  renderers["SCR-070"]=function(state){
    if(activeFlowId!=="UIF-12")return v350Render070ActorBase(state);
    return v350Render070ActorBase(state)
      .replace(/data-cf12-action="confirm-reject"/g,'data-v350-action="cf12-confirm-reject"');
  };

  document.addEventListener("click",(event)=>{
    const a=event.target.closest("[data-v350-action]"); if(!a||a.disabled)return;
    const k=a.dataset.v350Action;
    if(!["cr11-approve","cr11-reject-confirm","cf12-confirm-reject"].includes(k))return;
    event.preventDefault();event.stopPropagation();
    if(!isApproverEntry()){
      const screen=activeFlowId==="UIF-11"?"SCR-051":"SCR-070";
      stateByScreen[screen]="SELF_APPROVAL_NOT_ALLOWED";return renderAppScreen();
    }
    if(k==="cr11-approve"){
      stateByScreen["SCR-053"]="PROCESSING";navigate("SCR-053");setTimeout(()=>{if(activeFlowId==="UIF-11"&&activeScreenId==="SCR-053"&&stateByScreen["SCR-053"]==="PROCESSING"){stateByScreen["SCR-053"]="COMPLETED";syncReviewUrl();render();}},300);return;
    }
    if(k==="cr11-reject-confirm"){
      if(!cr11ApprovalRejectReason.trim()){stateByScreen["SCR-051"]="VALIDATION_ERROR";return renderAppScreen();}cr11ApprovalRejectOpen=false;stateByScreen["SCR-053"]="REJECTED";return navigate("SCR-053");
    }
    if(k==="cf12-confirm-reject"){
      if(!cf12RejectReason.trim())return;cf12RejectOpen=false;stateByScreen["SCR-070"]="APPROVAL_ALREADY_DECIDED";stateByScreen["SCR-066"]="REJECTED";return renderAppScreen();
    }
  },true);

  // -------------------------------------------------------------------------
  // BJ08 list controls — search and filter must change the visible collection,
  // not merely render controls that look interactive.
  // -------------------------------------------------------------------------
  let v350Ic08ListQuery="", v350Ic08ListFilter="ALL";
  const v350Render042Base=renderers["SCR-042"];
  renderers["SCR-042"]=function(state){
    if(activeFlowId!=="UIF-08")return v350Render042Base(state);
    if(state==="CANCEL_REQUEST")return ac310Return(appShell({title:"Kiểm kê kho",body:`${vBanner("warning","Yêu cầu hủy cần được xử lý trong phiên","Không đặt thao tác hủy trên màn danh sách. Mở đúng phiên kiểm kê để tiếp tục xử lý theo trạng thái hiện hành.")}${ac310InfoSurface("Phiên kiểm kê",[["Mã phiên","KK-0709-03",true],["Kho","Kho trung tâm"],["Trạng thái","Cần mở phiên để xử lý"]])}`,actions:primaryFooter("Về danh sách",'data-v350-action="ic08-cancel-request-back"'),back:false}));
    if(!["READY","FILTER_EMPTY"].includes(state))return v350Render042Base(state);
    const records=[
      {id:"KK-0709-03",status:"COUNTING",title:"KK-0709-03",subtitle:"Kho trung tâm · Toàn kho · 12/38 đã đếm",badge:"Đang đếm",tone:"Info",action:'data-ic08-action="resume"'},
      {id:"KK-0708-02",status:"APPROVAL",title:"KK-0708-02",subtitle:"Kho trung tâm · Nhóm vaccine · Đã đếm xong",badge:"Chờ duyệt",tone:"Warning",action:'data-v350-action="ic08-open-approval"'}
    ];
    const q=v350Ic08ListQuery.trim().toLocaleLowerCase("vi");
    const rows=(state==="FILTER_EMPTY"?[]:records.filter(r=>(v350Ic08ListFilter==="ALL"||r.status===v350Ic08ListFilter)&&(!q||`${r.title} ${r.subtitle}`.toLocaleLowerCase("vi").includes(q))));
    const chips=`<div class="ds24-chip-scroll ac320-chip-row" aria-label="Lọc phiên kiểm kê">${ds24Chip("ALL","Tất cả",v350Ic08ListFilter==="ALL","data-v350-ic08-filter")}${ds24Chip("COUNTING","Đang đếm",v350Ic08ListFilter==="COUNTING","data-v350-ic08-filter")}${ds24Chip("APPROVAL","Chờ duyệt",v350Ic08ListFilter==="APPROVAL","data-v350-ic08-filter")}</div>`;
    const list=rows.length?`<div class="ac320-session-list">${rows.map(r=>ac310RecordRow({title:r.title,subtitle:r.subtitle,badge:r.badge,tone:r.tone,attrs:r.action,leading:null})).join("")}</div>`:ioEmpty("Không tìm thấy phiên kiểm kê","Thử từ khóa hoặc bộ lọc khác.");
    const body=`${ds24Search(v350Ic08ListQuery,'data-v350-ic08-list-search','Tìm phiên kiểm kê')}${chips}${list}`;
    return ac310Return(appShell({title:"Kiểm kê kho",body,actions:primaryFooter("Tạo phiên kiểm kê",'data-ic08-action="create"'),back:false}));
  };
  document.addEventListener("input",(event)=>{if(activeFlowId==="UIF-08"&&event.target.matches("[data-v350-ic08-list-search]")){v350Ic08ListQuery=event.target.value;return renderAppScreen();}},true);
  document.addEventListener("click",(event)=>{
    const f=event.target.closest("[data-v350-ic08-filter]");if(f&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();v350Ic08ListFilter=f.dataset.v350Ic08Filter;return renderAppScreen();}
    const a=event.target.closest('[data-v350-action="ic08-open-approval"]');if(a&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();stateByScreen["SCR-046"]="APPROVAL_REVIEW";return navigate("SCR-046");}
    const back=event.target.closest('[data-v350-action="ic08-cancel-request-back"]');if(back&&activeFlowId==="UIF-08"){event.preventDefault();event.stopPropagation();stateByScreen["SCR-042"]="READY";return renderAppScreen();}
  },true);

  // Fix List Row search hiding after DS migration.
  window.__VET45_V350__={
    version:VERSION,
    setActor(mode){v350ActorMode=String(mode||"module");return v350ActorMode;},
    getActor(){return v350ActorMode;},
    applyEntry(flowId,mode){
      v350ActorMode=String(mode||"module");
      const applied=v350ApplyEntry(String(flowId||activeFlowId),v350ActorMode,true);
      return {applied,flow:activeFlowId,screen:activeScreenId,state:stateByScreen[activeScreenId],actor:v350ActorMode};
    },
    bumpIO05Source(){const o=io05CurrentOrder();o.sourceVersion=num(o.sourceVersion)+1;return o.sourceVersion;},
    bumpIO06Source(){const r=io06CurrentRequest();r.sourceVersion=num(r.sourceVersion)+1;io06RefreshRequestState(r);return r.sourceVersion;},
    bumpCR16Evidence(){const c=cr16Current();c.evidenceVersion=num(c.evidenceVersion)+1;return c.evidenceVersion;},
    bumpCR17Evidence(){const c=cr17Current();c.evidenceVersion=num(c.evidenceVersion)+1;return c.evidenceVersion;},
    setCf12Control(qty,value){cf12ControlQty=String(qty);cf12ControlValue=String(value);return v350Cf12Matches();},
    getCf15Rows(mode=cf15DateMode){return v350Cf15Movements(mode).map(x=>x.id);},
    getState(){return {flow:activeFlowId,screen:activeScreenId,state:stateByScreen[activeScreenId]};},
    getIC10(){return {requestQty:v350Ic10RequestQty,reason:v350Ic10Reason,evidence:v350Ic10Evidence,approvedQty:v350Ic10ApprovedQty,actualQty:v350Ic10ActualQty,proof:v350Ic10Proof,completedQty:v350Ic10CompletedQty};},
    getIC09(){return {reason:v350Ic09Reason,destination:ic09Destination,request:v350Ic09Request,current:ic09Current()};},
    getBJ17(){const c=cr17Current();return {id:c.id,operation:c.operation,evidenceVersion:c.evidenceVersion,record:c.resolutionRecord};}
  };

  // Final render after correcting entry routing and effective renderer table.
  syncReviewUrl();render();
})();

/* ===== v351-list-chip-navigation-correction.js ===== */
/* VET45 Theme 7 v3.5.1 — list/chip/navigation correction
 * Parent: v3.5.0. Presentation and drill-down return behavior only.
 */
(function(){
  const patchBackAction=(html,action)=>{
    if(typeof html!=="string") return html;
    const t=document.createElement("template");
    t.innerHTML=html;
    const back=t.content.querySelector(".app-back-button");
    if(back){
      back.removeAttribute("data-back");
      back.setAttribute("data-action",action);
    }
    return t.innerHTML;
  };

  // BJ09 history is an auxiliary drill-down from SCR-037, not the next step after
  // the result screen. Back must restore the detail that launched it without
  // mutating status/result state.
  const base056=renderers["SCR-056"];
  renderers["SCR-056"]=function(state){
    const html=base056(state);
    if(activeFlowId==="UIF-09") return patchBackAction(html,"v351-ic09-history-back");
    if(activeFlowId==="UIF-15") return patchBackAction(html,"v351-cf15-movement-back");
    return html;
  };

  // BJ15 source evidence is another auxiliary drill-down. Make its parent explicit
  // instead of relying on screen-array order.
  const base057=renderers["SCR-057"];
  renderers["SCR-057"]=function(state){
    const html=base057(state);
    if(activeFlowId==="UIF-15") return patchBackAction(html,"v351-cf15-source-back");
    return html;
  };

  document.addEventListener("click",(event)=>{
    const btn=event.target.closest?.("[data-action]");
    if(!btn) return;
    const action=btn.dataset.action;
    if(action==="v351-ic09-history-back" && activeFlowId==="UIF-09"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-037");
    }
    if(action==="v351-cf15-movement-back" && activeFlowId==="UIF-15"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-055");
    }
    if(action==="v351-cf15-source-back" && activeFlowId==="UIF-15"){
      event.preventDefault(); event.stopImmediatePropagation();
      return navigate("SCR-056");
    }
  },true);

  if(["UIF-09","UIF-15"].includes(activeFlowId)) render();
})();

/* ===== v360-full-theme-completion.js ===== */
/* VET45 Theme 7 v3.6.0 — full-theme completion & UX QA correction
 * Parent: v3.5.1
 * Scope: active-session cancellation, representative-state coherence,
 * feedback/toast semantics, dead-end exits, and final UX simplification.
 * Figma is Design System + mature cross-theme reference only; Theme 7 design authority is this HTML harness.
 * CAP-01 đã chuyển sang app/cap01.js (T7-P gói A3).
 */
(() => {
  const VERSION = "3.6.0";

  // -----------------------------------------------------------------------
  // BJ08 cancellation: destructive action belongs inside an opened session,
  // never on the browse list.
  // -----------------------------------------------------------------------
  function injectSessionCancel(html){
    if(!html || html.includes('data-ic08-action="cancel-open"')) return html;
    const button=`<button class="button button--secondary v360-session-cancel" type="button" data-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.secondary" data-ds-prop-tone="VComponentTone.danger">Hủy phiên</button>`;
    if(html.includes('</footer>')) return html.replace('</footer>',`${button}</footer>`);
    return html;
  }
  const base044=renderers["SCR-044"];
  renderers["SCR-044"]=function(state){
    const html=base044(state);
    if(activeFlowId!=="UIF-08" || !["BLIND_COUNT","READY","VALIDATION_ERROR"].includes(state)) return html;
    return injectSessionCancel(html);
  };
  const base045=renderers["SCR-045"];
  renderers["SCR-045"]=function(state){
    const html=base045(state);
    if(activeFlowId!=="UIF-08" || !["RECOUNT_REQUIRED","READY","VALIDATION_ERROR","EVIDENCE_REQUIRED","PRICE_BASIS_REQUIRED"].includes(state)) return html;
    return injectSessionCancel(html);
  };

  // -----------------------------------------------------------------------
  // Representative-state coherence. These seeds are only for direct Inspector
  // entry to READY review screens; normal user transitions already populate
  // the same prerequisites and are never overwritten.
  // -----------------------------------------------------------------------
  function ensureVal03ReviewFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-017"||stateByScreen[activeScreenId]!=="READY") return;
    if(val03SelectedSlices().length>0 && val03ScopeReady()) { if(val03ReviewSourceVersion==null) val03ReviewSourceVersion=val03Current().sourceVersion; return; }
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(s=>{s.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const s=g?.slices.find(x=>x.pendingQty>0);
    if(g&&s){s.selected=true;s.selectedQty=s.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;}
  }
  function ensureVal03ResultFixture(){
    if(activeFlowId!=="UIF-03"||activeScreenId!=="SCR-019"||stateByScreen[activeScreenId]!=="COMPLETED"||val03LastResult) return;
    const r=val03Current();
    r.groups.forEach(g=>g.slices.forEach(sl=>{sl.selected=false;}));
    const g=r.groups.find(x=>x.id==="VAL03-G1")||r.groups.find(x=>val03EvidenceState(x)==="READY");
    const sl=g?.slices.find(x=>x.pendingQty>0);
    if(g&&sl){sl.selected=true;sl.selectedQty=sl.pendingQty;if(!g.selectedSource)g.selectedSource=g.sources[0]?.id||"";val03ReviewSourceVersion=r.sourceVersion;val03Commit();}
  }
  // Direct Inspector entry to the shared SCR-041 result must show a coherent
  // completed disposal rather than a zero-value artifact. Normal flow results
  // delegate to v3.5.0 and preserve the actual completed quantity.
  const v360Render041Base=renderers["SCR-041"];
  renderers["SCR-041"]=function(state){
    if(activeFlowId==="UIF-10"&&state==="COMPLETED"){
      const q=window.__VET45_V350__?.getIC10?.()||{};
      if(!(Number(q.completedQty)>0||Number(q.approvedQty)>0)) return appShell({title:"Kết quả tiêu hủy",body:ioResult("Đã ghi nhận tiêu hủy","Tồn vật lý và giá trị đã giảm theo đúng số lượng thực tế được xác nhận.",[["Yêu cầu","TH-0709-04"],["Đã tiêu hủy","6 hộp"],["Tồn vật lý còn lại","0 hộp"]]),actions:primaryFooter("Về hàng có thể xử lý",'data-ic10-action="to-list"'),centered:true,back:false});
    }
    return v360Render041Base(state);
  };
  function ensureIo07ReviewFixture(){
    if(activeFlowId!=="UIF-07"||activeScreenId!=="SCR-039"||stateByScreen[activeScreenId]!=="READY") return;
    const req=io07Current();
    if(!io07AllVerified(req)){io07Allocations(req).forEach(({allocation})=>{allocation.verified=true;allocation.physicalMismatch=false;allocation.affectedByChange=false;});}
    req.reviewSourceVersion=req.sourceVersion;
  }
  function ensureVal13ReviewFixture(){
    if(activeFlowId!=="UIF-13"||activeScreenId!=="SCR-088"||stateByScreen[activeScreenId]!=="READY") return;
    const t=val13Current();
    t.targets.forEach(x=>x.selected=true);
    if(!t.selectedMethod) t.selectedMethod=t.allowedMethods?.[0]?.id||"";
    val13ReviewSourceVersion=t.sourceVersion;
    val13PreviewHash=val13PreviewHashOf(t);
  }
  function ensureVal14ReviewFixture(){
    if(activeFlowId!=="UIF-14"||activeScreenId!=="SCR-076"||stateByScreen[activeScreenId]!=="READY") return;
    let r=val14Current();
    if(r.status!=="READY_FOR_REVIEW"){
      const ready=val14Runs.find(x=>x.status==="READY_FOR_REVIEW");
      if(ready){val14SelectedRunId=ready.id;r=ready;}
    }
    if(val14PublishReviewVersion==null) val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);
  }
  function ensureRepresentativeFixture(){
    try{ensureVal03ReviewFixture();ensureVal03ResultFixture();ensureIo07ReviewFixture();ensureVal13ReviewFixture();ensureVal14ReviewFixture();}catch(err){console.error("v360 fixture",err);}
  }
  const baseRenderAppScreen=renderFlowScreen;
  const v360TransientStates=new Set(["LOADING","PROCESSING","CALCULATING","REBUILDING","PREPARING","EXPORT_RUNNING"]);
  const v360RootScreens=new Set(["SCR-001","SCR-006","SCR-014","SCR-025","SCR-030","SCR-036","SCR-042","SCR-048","SCR-054","SCR-066","SCR-072","SCR-078","SCR-085","SCR-062","SCR-063"]);
  const v360ExitTargets={
    "SCR-011":"SCR-006","SCR-012":"SCR-006","SCR-013":"SCR-006",
    "SCR-019":"SCR-014","SCR-029":"SCR-025","SCR-034":"SCR-030","SCR-035":"SCR-030",
    "SCR-038":"SCR-036","SCR-040":"SCR-036","SCR-051":"SCR-048",
    "SCR-041":"SCR-036","SCR-046":"SCR-042","SCR-047":"SCR-042",
    "SCR-052":"SCR-048","SCR-053":"SCR-048","SCR-058":"SCR-055","SCR-059":"SCR-055",
    "SCR-070":"SCR-066","SCR-071":"SCR-066","SCR-077":"SCR-072","SCR-083":"SCR-078","SCR-089":"SCR-085"
  };
  function ensureStableExitAffordance(){
    const state=stateByScreen[activeScreenId];
    if(v360TransientStates.has(state)||v360RootScreens.has(activeScreenId))return;
    const root=document.getElementById("app-screen");if(!root)return;
    const interactive=root.querySelector('button:not([disabled]),a[href],[data-back],[data-action]:not([data-action=""]),[data-generic-next],[data-generic-action]');
    if(interactive)return;
    const target=v360ExitTargets[activeScreenId];if(!target)return;
    const label=activeScreenId==="SCR-058"||activeScreenId==="SCR-059"?"Về báo cáo":"Về danh sách";
    root.querySelector('.v-page-scaffold')?.insertAdjacentHTML('beforeend',primaryFooter(label,`data-v360-action="fallback-exit" data-v360-target="${target}"`));
  }
  renderFlowScreen=function(){ensureRepresentativeFixture();const out=baseRenderAppScreen();ensureStableExitAffordance();return out;};

  // -----------------------------------------------------------------------
  // Product feedback: mutation success is acknowledged when the user remains
  // in the same work context or returns to a work list. Dedicated result
  // screens keep sole ownership of operation-level success feedback.
  // -----------------------------------------------------------------------
  const toastRules=[
    ['[data-io07-action="confirm-allocation"]',"Đã xác nhận phần hàng","success"],
    ['[data-v350-action="ic09-submit"]',"Đã gửi yêu cầu thay đổi tình trạng","success"],
    ['[data-v350-action="ic10-submit"]',"Đã gửi yêu cầu tiêu hủy","success"],
    ['[data-cr11-action="submit-correction"]',"Đã gửi yêu cầu sửa sai","success"],
    ['[data-cf12-action="send-approval"]',"Đã gửi số dư đầu kỳ chờ duyệt","success"]
  ];
  document.addEventListener("click",(event)=>{
    for(const [selector,msg,tone] of toastRules){
      const hit=event.target.closest(selector);if(!hit||hit.disabled)continue;
      window.setTimeout(()=>{if(document.getElementById("app-screen"))showToast(msg,tone);},30);
      break;
    }
  },true);

  // -----------------------------------------------------------------------
  // Stable exit paths (fallback-exit).
  // -----------------------------------------------------------------------
  document.addEventListener("input",(event)=>{
    if(activeFlowId==="UIF-08" && event.target.matches("[data-ic08-cancel-reason]")){
      queueMicrotask(()=>{const b=document.querySelector('[data-v350-action="ic08-confirm-cancel"]');if(b)b.disabled=!String(event.target.value||"").trim();});
    }
  },true);
  document.addEventListener("click",(event)=>{
    const action=event.target.closest("[data-v360-action]");
    if(!action||action.disabled)return;
    if(action.dataset.v360Action==="fallback-exit"){event.preventDefault();event.stopPropagation();const target=action.dataset.v360Target;if(target)return navigate(target);}
  },true);

  // -----------------------------------------------------------------------
  // UX simplification: normal progress/context should not consume banner
  // semantics. Only exact informational banners which merely restate the
  // screen are demoted; exception/warning/error/success banners remain.
  // -----------------------------------------------------------------------
  const normalInfoBannerTitles=new Set([
    "Yêu cầu thay đổi tình trạng",
    "Phê duyệt chưa phải tiêu hủy",
    "Cần quyết định độc lập",
    "Chỉ xử lý dòng có chênh lệch"
  ]);
  function simplifyNormalBanners(){
    if(!["UIF-08","UIF-09","UIF-10","UIF-16","UIF-17"].includes(activeFlowId))return;
    document.querySelectorAll("#app-screen .v-banner--info").forEach(b=>{
      const title=b.querySelector("strong")?.textContent?.trim()||"";
      if(normalInfoBannerTitles.has(title)) b.classList.add("v360-context-banner");
    });
  }
  const prevRender=render;
  render=function(){const out=prevRender();requestAnimationFrame(simplifyNormalBanners);return out;};

  // Version metadata exposed to QA/runtime.
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.uiFlows=flowCatalog.map(f=>f.id);
    window.__VET45_PROTOTYPE__.screens=screens.map(s=>s.id);
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"supporting-policy","active-session-cancellation","feedback-semantic"];
  }
  window.__VET45_V360__={
    version:VERSION,
    ensureRepresentativeFixture
  };

  // Final render after all effective renderers and global QA corrections exist.
  syncReviewUrl();render();
})();

/* ===== v361-footer-action-correction.js ===== */
/* VET45 Theme 7 v3.6.1 — dual Sticky Footer normalization
 * Parent: v3.6.0
 * Scope: UI-only correction. No business rule, action, state or navigation change.
 */
(() => {
  const VERSION = "3.6.1";

  function directButtons(footer){
    return [...footer.children].filter((el)=>el.tagName === "BUTTON" && el.offsetParent !== null);
  }
  function isPrimary(button){
    return button.classList.contains("button--primary") || button.classList.contains("ds24-button--primary");
  }
  function isDanger(button){
    return button.classList.contains("button--danger") ||
      button.classList.contains("ds24-button--danger") ||
      button.classList.contains("ac310-danger-text") ||
      button.classList.contains("v360-session-cancel") ||
      button.dataset.dsPropTone === "VComponentTone.danger" ||
      button.dataset.dsProfile === "button.destructiveSecondary";
  }
  function hasDestructiveIntent(button){
    if(isDanger(button)) return true;
    const actionMetadata=Object.entries(button.dataset || {})
      .filter(([key])=>/action|intent|profile/i.test(key))
      .map(([,value])=>String(value || ""))
      .join(" ");
    return /(^|[-_\s])(reject|cancel|delete|remove|destructive)([-_\s]|$)/i.test(actionMetadata);
  }

  function normalizeDualFooters(){
    const root=document.getElementById("app-screen");
    if(!root) return;
    root.querySelectorAll(".app-actions").forEach((footer)=>{
      const buttons=directButtons(footer);
      footer.classList.remove("v361-dual-footer","v361-dual-footer--danger");
      if(buttons.length !== 2) return;

      const primary=buttons.find(isPrimary);
      const secondary=buttons.find((b)=>b !== primary);
      // DS convention is Secondary/Destructive | Primary. Keep DOM/tab order aligned with visual order.
      if(primary && secondary && footer.firstElementChild !== secondary){
        footer.insertBefore(secondary, primary);
      }

      // Destructive intent (reject/cancel/delete/remove) uses the canonical danger secondary hierarchy.
      if(secondary && hasDestructiveIntent(secondary) && !isPrimary(secondary)){
        secondary.dataset.dsPropTone="VComponentTone.danger";
        secondary.dataset.dsProfile="button.destructiveSecondary";
      }

      footer.classList.add("v361-dual-footer");
      footer.dataset.dsPropLayout="Dual";
      const tone=buttons.some(isDanger) ? "Danger" : "Default";
      footer.dataset.dsPropTone=tone;
      if(tone === "Danger") footer.classList.add("v361-dual-footer--danger");
    });
  }

  const previousRenderAppScreen=renderFlowScreen;
  renderFlowScreen=function(){
    const out=previousRenderAppScreen();
    normalizeDualFooters();
    return out;
  };

  // Normalize the screen already rendered by the previous release script.
  normalizeDualFooters();

  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"dual-footer-horizontal"];
  }
  window.__VET45_V361__={version:VERSION,normalizeDualFooters};
})();

/* ===== v362-list-rhythm-correction.js ===== */
/* VET45 Theme 7 v3.6.2 — independent list/card rhythm correction
 * Layout-only cumulative release. No business/state/action/navigation mutation.
 */
(()=>{
  const VERSION = "3.6.2";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version = VERSION;
    window.__VET45_PROTOTYPE__.scenarios = [
      ...(window.__VET45_PROTOTYPE__.scenarios || []),
      "independent-list-card-rhythm"
    ];
  }
})();

/* ===== v363-list-navigation-state-correction.js ===== */
/* VET45 Theme 7 v3.6.3 — homogeneous list navigation / disabled-state correction
 * Parent: v3.6.2
 * UI semantics only: non-actionable peers in a navigation collection keep Navigation anatomy
 * and chevron, using the canonical Disabled state instead of switching component Type.
 */
(()=>{
  const VERSION = "3.6.3";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version = VERSION;
    window.__VET45_PROTOTYPE__.scenarios = [
      ...(window.__VET45_PROTOTYPE__.scenarios || []),
      "homogeneous-navigation-list-disabled-state"
    ];
  }
})();

/* ===== v364-radio-helper-correction.js ===== */
/* VET45 Theme 7 v3.6.4 — canonical radio/helper correction */
(()=>{
  const VERSION="3.6.4";
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...(window.__VET45_PROTOTYPE__.scenarios||[]),"canonical-vradio-and-plain-helper-text"];
  }
})();

/* ===== legacy-sheet-cleanup (từ v381) ===== */
/* Legacy, xoá khi các BJ có sheet được viết lại ở T7-P: bỏ nút "Đóng" thừa ở sheet chỉ xem / chọn
 * (backdrop, tay nắm và Back hệ thống đã đóng được sheet). */
(()=>{
  function cleanupDismissibleSheets(){
    document.querySelectorAll('.ds24-select-sheet button[data-ic08-action="select-close"]').forEach(n=>n.remove());
    document.querySelectorAll('.cf15-sheet button[data-cf15-action="close-product-sheet"], .ac310-sheet button[data-cf15-action="close-product-sheet"]').forEach(n=>n.remove());
    document.querySelectorAll('.cf15-sheet .sheet-actions, .ac310-sheet .sheet-actions').forEach(actions=>{
      if(actions.children.length===1)actions.classList.add('t381-single-business-action');
    });
  }
  const previousRenderFlowScreen=renderFlowScreen;
  renderFlowScreen=function(){previousRenderFlowScreen();cleanupDismissibleSheets();};
})();
/* ===== legacy-cross-theme-copy (từ v390) ===== */
/* Legacy, xoá dần khi BJ-02 / 06 / 09 / 17 được viết lại ở T7-P: sửa chữ sau khi dựng màn. */
(()=>{
  function polishCrossThemeCopy(){
    // Approval is the actual next step in BJ09; make CTA explicit.
    if(activeFlowId==='UIF-09'&&activeScreenId==='SCR-038'&&stateByScreen['SCR-038']==='READY'){
      const b=document.querySelector('[data-ic09-action="submit"],[data-v350-action="ic09-submit"]');if(b)b.textContent='Gửi chờ duyệt';
    }
    // UIF-02 SCR-012 badge: bj02ReviewProductBlocks({ resultMode: true }) (T7-P A4).
    // Recovery copy should describe the user's business object, not an implementation identity token.
    if(activeFlowId==='UIF-17'){
      document.querySelectorAll('#app-screen *').forEach(el=>{if(el.children.length===0&&el.textContent.trim()==='Định danh')el.textContent='Lần xử lý';});
    }
    document.querySelectorAll('.ds24-info-row,.info-row,.key-value-row').forEach(row=>{
      const key=row.querySelector(':scope > :first-child');if(key&&key.textContent.trim()==='Định danh xử lý')key.textContent='Lần xử lý';
    });
  }

  const previousRenderFlowScreen=renderFlowScreen;
  renderFlowScreen=function(){previousRenderFlowScreen();polishCrossThemeCopy();};
})();


/* ===== v395-bj07-semantic-hardening.js ===== */
/* VET45 Theme 7 v3.9.5 — BJ07 supplier-return semantic hardening
 * Parent: v3.9.4
 * Approved decisions: T7-DR-138..143 / D07-01..D07-06
 */
(()=>{
  const ACTOR={id:'USR-WH-021',name:'Trần Huy · Thủ kho'};
  const STOCK_LABELS={SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng',EXPIRED:'Hết hạn'};
  const attr=(v)=>escapeAttribute(String(v??''));
  const num=(v)=>Number.isFinite(Number(v))?Number(v):0;
  const isoNow=()=>new Date().toISOString();
  const displayTime=(iso)=>{if(!iso)return '—';const d=new Date(iso);return d.toLocaleString('vi-VN',{timeZone:'Asia/Ho_Chi_Minh',hour12:false});};
  function stableHash(input){let h1=2166136261>>>0,h2=2246822519>>>0;const s=typeof input==='string'?input:JSON.stringify(input);for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);h1=Math.imul(h1^c,16777619)>>>0;h2=Math.imul(h2^c,3266489917)>>>0;}const base=h1.toString(16).padStart(8,'0')+h2.toString(16).padStart(8,'0');return (base+base+base+base).slice(0,64);}
  function sourceBalanceId(a,state){return `BAL-${String(a.sourceAllocationId||a.id).replace(/[^A-Z0-9]/gi,'')}-${state}`;}
  function defaultCandidateState(group,a){
    if(a.id==='RTV-A1')return null;
    if(a.id==='RTV-A2')return 'DAMAGED';
    if(a.id==='RTV-A8')return 'QUARANTINE';
    return 'SELLABLE';
  }
  function seedCandidates(group,a,force=false){
    if(!force&&Array.isArray(a.sourceStateCandidates)&&a.sourceStateCandidates.length)return;
    if(a.id==='RTV-A1'){
      a.sourceStateCandidates=[
        {state:'SELLABLE',available:3,balanceId:sourceBalanceId(a,'SELLABLE'),balanceVersion:12},
        {state:'DAMAGED',available:2,balanceId:sourceBalanceId(a,'DAMAGED'),balanceVersion:7}
      ];
      a.sourceSlices=[];
      a.sourceSliceUserResolved=false;
      return;
    }
    const state=defaultCandidateState(group,a)||'SELLABLE';
    a.sourceStateCandidates=[{state,available:Math.max(num(a.qty),1),balanceId:sourceBalanceId(a,state),balanceVersion:5}];
    a.sourceSlices=[{state,qty:num(a.qty),balanceId:sourceBalanceId(a,state),balanceVersion:5}];
    a.sourceSliceUserResolved=false;
  }
  function seedAllocation(req,group,a,force=false){
    req.sourceRequestId=req.sourceRequestId||req.source;
    req.warehouseId=req.warehouseId||'WH-MAIN';
    req.operationId=req.operationId||`IO-RTV-${String(req.id).replace(/^RTV-/,'')}`;
    group.sourceLineId=group.sourceLineId||`SRC-LINE-${group.id}`;
    a.sourceAllocationId=a.sourceAllocationId||a.id;
    a.sourceLineId=a.sourceLineId||group.sourceLineId;
    a.sourceRequestId=req.sourceRequestId;
    a.sourceVersion=req.sourceVersion;
    seedCandidates(group,a,force);
    if(!a.physicalObservation)a.physicalObservation=null;
  }
  function seedRequest(req){for(const group of req.groups||[])for(const a of group.allocations||[])seedAllocation(req,group,a,false);}
  io07Requests.forEach(seedRequest);

  function sliceTotal(a){return (a.sourceSlices||[]).reduce((s,x)=>s+num(x.qty),0);}
  function slicesResolved(a){return num(a.qty)>=0 && Math.abs(sliceTotal(a)-num(a.qty))<0.000001 && (a.sourceSlices||[]).every(x=>num(x.qty)>=0);}
  function sourceSliceSummary(a){
    if(!slicesResolved(a))return 'Chưa xác định đủ nguồn tồn';
    return (a.sourceSlices||[]).filter(x=>num(x.qty)>0).map(x=>`${STOCK_LABELS[x.state]||x.state} ${num(x.qty)}`).join(' · ')||'—';
  }
  function activeFound(){return io07FindAllocation(io07ActiveAllocationId,io07Current());}
  function scanMatches(group,a){
    if(group.tracking!=='LOT')return true;
    const scanned=String(io07ScanLot||'').trim();
    return !scanned || scanned.toLocaleUpperCase('vi')===String(a.lot||'').trim().toLocaleUpperCase('vi');
  }
  io07AllVerified=function(req=io07Current()){
    const lines=io07Allocations(req);
    return lines.length>0&&lines.every(({allocation})=>allocation.verified&&!allocation.physicalMismatch&&slicesResolved(allocation));
  };

  function preparationGroups(req,readOnly=false){
    return (req.groups||[]).map(group=>{
      const progress=io07ProductProgress(group);
      const heading=io07ProductGroupHeader(group,{label:`${progress.verified}/${progress.total} đã kiểm`,tone:progress.tone,role:'rtv-product-summary'});
      const rows=(group.allocations||[]).map(a=>{
        const status=a.physicalMismatch?'Chờ cập nhật':a.affectedByChange?'Cần kiểm lại':a.verified?'Đã kiểm':'';
        let subtitle=`${a.qty} ${group.uom}`;
        if(a.expiry)subtitle+=` · HSD ${a.expiry}`;
        if(status)subtitle+=` · ${status}`;
        if(a.previousQty!=null&&a.affectedByChange)subtitle+=` · trước ${a.previousQty} ${group.uom}`;
        const sourceNote=(a.sourceStateCandidates||[]).length>1?(slicesResolved(a)?` · Nguồn tồn: ${sourceSliceSummary(a)}`:' · Cần xác định nguồn tồn'):'';
        subtitle+=sourceNote;
        return ds24ListRow({title:io07AllocationLabel(group,a),subtitle,leading:null,attrs:readOnly?'':`data-io07-allocation="${attr(a.id)}" data-layout-role="rtv-allocation-row"`,type:readOnly?'Status':'Navigation',density:'Default',interactive:!readOnly,state:readOnly?'Disabled':'Default',disabled:readOnly});
      }).join('');
      return `<div class="io07-product-group ds24-grouped-subgroup" data-layout-role="product-allocation-subgroup" data-composed-from="DS v2 / List Row,VBadge">${heading}<div class="io07-allocation-list">${rows}</div></div>`;
    }).join('');
  }

  io07ReviewGroups=function(reqOrLines,{statusLabel='Đã kiểm',statusTone='Success'}={}){
    let groups=[];
    if(Array.isArray(reqOrLines)){
      const map=new Map();
      for(const line of reqOrLines||[]){const key=`${line.name}|${line.code||''}|${line.uom}`;if(!map.has(key))map.set(key,{name:line.name,code:line.code||'',uom:line.uom,tracking:line.lot?'LOT':'NONE',allocations:[]});map.get(key).allocations.push({...line});}
      groups=[...map.values()];
    } else groups=(reqOrLines?.groups||[]);
    const subgroups=groups.map(group=>{
      const heading=io07ProductGroupHeader(group,{label:statusLabel,tone:statusTone,role:'rtv-review-product'});
      const rows=(group.allocations||[]).map(a=>{
        const left=a.lot?`Lô ${a.lot}${a.expiry?` · HSD ${a.expiry}`:''}`:'Không theo lô';
        const source=(a.sourceSliceUserResolved||(a.sourceSlices||[]).length>1)?ds24KeyValueRow('Nguồn tồn',sourceSliceSummary(a)):'';
        return `${ds24KeyValueRow(left,`${a.qty} ${group.uom}`)}${source}`;
      }).join('');
      return `<div class="io07-review-product ds24-grouped-subgroup" data-layout-role="product-fact-subgroup" data-composed-from="VIcon,VText,VBadge,DS v2 / Key-value Row">${heading}<div class="io07-review-kv">${rows}</div></div>`;
    }).join('');
    return ds24GroupedCollection(subgroups,'io07-review-products io07-grouped-collection io07-grouped-collection--facts','DS v2 / List Row,DS v2 / Key-value Row');
  };

  io07SourceDelta=function(req){
    const notes=(req.sourceChanges||[]).filter(Boolean);
    if(!req.changed&&!notes.length)return '';
    const detail=notes.length?notes.join(' '):'Yêu cầu nguồn đã thay đổi. Chỉ phần bị ảnh hưởng cần kiểm lại.';
    return vBanner('warning','Yêu cầu đã cập nhật',detail,'','Compact');
  };

  let mismatchSheetOpen=false,mismatchType='',mismatchQty='',mismatchLot='',mismatchNote='';
  function sourceSliceInputs(group,a){
    const candidates=a.sourceStateCandidates||[];
    if(candidates.length<=1)return '';
    const current=new Map((a.sourceSlices||[]).map(s=>[s.state,num(s.qty)]));
    const fields=candidates.map(c=>`<label class="ds24-field v395-source-slice-field" data-ds-component="VNumberField"><span class="vet45-text-style-8">${esc(STOCK_LABELS[c.state]||c.state)}</span><div class="v395-source-slice-control"><input class="ds24-field__control vet45-text-style-6" type="number" min="0" max="${c.available}" step="1" inputmode="decimal" value="${attr(current.get(c.state)||'')}" data-io07-source-slice="${attr(c.state)}"><small class="vet45-text-style-11">Tối đa ${c.available} ${esc(group.uom)}</small></div></label>`).join('');
    const ok=slicesResolved(a);
    return `<section class="v395-source-slices" data-composed-from="VNumberField,DS v2 / Key-value Row">${ds24SectionTitle('Xác định nguồn tồn',`${sliceTotal(a)}/${a.qty} ${group.uom}`)}<p class="vet45-text-style-11 v395-source-help">Cùng lô đang nằm ở nhiều trạng thái. Chọn đúng lượng thực tế cần trả từ từng trạng thái.</p>${fields}<div data-v395-source-feedback>${ok?'':vBanner('warning','Chưa đủ nguồn tồn',`Cần phân bổ đúng ${a.qty} ${group.uom}.`,'','Compact')}</div></section>`;
  }
  function verifyButtonDisabled(group,a){return !scanMatches(group,a)||!slicesResolved(a);}
  function syncVerifyButton(){
    const found=activeFound();if(!found)return;const {group,allocation:a}=found;
    const b=document.querySelector('[data-io07-action="confirm-allocation"]');if(b)b.disabled=verifyButtonDisabled(group,a);
    const fb=document.querySelector('[data-v395-source-feedback]');if(fb)fb.innerHTML=slicesResolved(a)?'':vBanner('warning','Chưa đủ nguồn tồn',`Cần phân bổ đúng ${a.qty} ${group.uom}.`,'','Compact');
    const title=document.querySelector('.v395-source-slices .ds24-section-title span');if(title)title.textContent=`${sliceTotal(a)}/${a.qty} ${group.uom}`;
  }
  io07VerificationSheet=function(req){
    if(!io07VerifySheetOpen)return '';const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return '';const {group,allocation:a}=found;
    const expectedLot=group.tracking==='LOT'?String(a.lot||''):'';const mismatch=Boolean(expectedLot&&String(io07ScanLot||'').trim()&&String(io07ScanLot).trim().toLocaleUpperCase('vi')!==expectedLot.toLocaleUpperCase('vi'));
    const product=ds24ContextStatusRow({title:group.name,subtitle:`${group.code} · ${group.uom}`,label:a.verified?'Đã kiểm':'Cần kiểm',tone:a.verified?'Success':'Neutral',leading:'package',attrs:'data-layout-role="rtv-verify-product"'});
    const facts=ds24InfoGroup('',`${ds24InfoRow('Cần chuẩn bị',`${a.qty} ${group.uom}`)}${group.tracking==='LOT'?ds24InfoRow('Lô theo yêu cầu',a.lot):''}${a.expiry?ds24InfoRow('Hạn dùng',a.expiry):''}`,'ds24-info-group--untitled io07-sheet-facts');
    const lotInput=group.tracking==='LOT'?`${ds24TextField('Lô thực tế (không bắt buộc)',io07ScanLot,'data-io07-scan-lot autocomplete="off"','Chỉ đối chiếu với lô theo yêu cầu.')}<div data-io07-scan-feedback>${mismatch?vBanner('error','Lô không khớp',`Theo yêu cầu là lô ${expectedLot}. Hãy ghi nhận chênh lệch để Mua hàng cập nhật.`,'','Compact'):''}</div>`:'';
    const sources=sourceSliceInputs(group,a);
    return `<div class="sheet-backdrop io07-verify-backdrop" data-io07-verify-backdrop><section class="bottom-sheet io-bottom-sheet io07-verification-sheet v395-verification-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Kiểm hàng thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Kiểm hàng thực tế</h3></div><div class="io07-verification-content">${product}${facts}${lotInput}${sources}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="mark-mismatch" type="button">Không khớp</button><button class="button button--primary" data-io07-action="confirm-allocation" type="button" ${verifyButtonDisabled(group,a)?'disabled':''}>Đúng hàng</button></div></div></section></div>`;
  };

  function mismatchSheet(req){
    if(!mismatchSheetOpen)return '';const found=io07FindAllocation(io07ActiveAllocationId,req);if(!found)return '';const {group,allocation:a}=found;
    const options=[['QUANTITY','Sai số lượng'],['LOT','Sai lô'],['ITEM_NOT_FOUND','Không thấy hàng'],['OTHER','Khác']].map(([v,l])=>`<button type="button" class="v395-mismatch-choice${mismatchType===v?' is-selected':''}" data-io07-action="select-mismatch" data-io07-mismatch-type="${v}" aria-pressed="${mismatchType===v?'true':'false'}">${l}</button>`).join('');
    const qty=mismatchType==='QUANTITY'?ds24TextField('Số lượng thực tế',mismatchQty,'data-io07-mismatch-qty type="number" min="0" step="1" inputmode="decimal"',`Theo yêu cầu: ${a.qty} ${group.uom}`):'';
    const lot=mismatchType==='LOT'?ds24TextField('Lô thực tế',mismatchLot,'data-io07-mismatch-lot autocomplete="off"',`Theo yêu cầu: ${a.lot||'—'}`):'';
    const note=mismatchType==='OTHER'?ds24TextField('Mô tả chênh lệch',mismatchNote,'data-io07-mismatch-note autocomplete="off"','Bắt buộc khi chọn Khác.'):'';
    const valid=Boolean(mismatchType&&(mismatchType!=='QUANTITY'||String(mismatchQty).trim()!=='')&&(mismatchType!=='LOT'||String(mismatchLot).trim())&&(mismatchType!=='OTHER'||String(mismatchNote).trim()));
    return `<div class="sheet-backdrop v395-mismatch-backdrop"><section class="bottom-sheet io-bottom-sheet v395-mismatch-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353" role="dialog" aria-modal="true" aria-label="Ghi nhận chênh lệch thực tế"><div class="sheet-handle"></div><div class="sheet-title"><h3>Ghi nhận chênh lệch</h3></div><div class="sheet-content"><p class="vet45-text-style-11 v395-source-help">Chỉ ghi nhận điều nhìn thấy thực tế. Kho không tự sửa yêu cầu trả hoặc thay lô.</p><div class="v395-mismatch-choices">${options}</div>${qty}${lot}${note}<div class="io07-sheet-actions"><button class="button button--secondary" data-io07-action="close-mismatch" type="button">Hủy</button><button class="button button--primary" data-io07-action="record-mismatch-observation" type="button" ${valid?'':'disabled'}>Gửi chênh lệch</button></div></div></section></div>`;
  }

  function mismatchValid(){return Boolean(mismatchType&&(mismatchType!=='QUANTITY'||String(mismatchQty).trim()!=='')&&(mismatchType!=='LOT'||String(mismatchLot).trim())&&(mismatchType!=='OTHER'||String(mismatchNote).trim()));}
  function syncMismatchButton(){const b=document.querySelector('[data-io07-action="record-mismatch-observation"]');if(b)b.disabled=!mismatchValid();}
  function recordObservation(req){
    const found=activeFound();if(!found)return false;const {group,allocation:a}=found;
    if(!mismatchValid())return false;
    const observation={
      observationId:`OBS-${a.sourceAllocationId}-${String((a.observationSeq||0)+1).padStart(3,'0')}`,
      sourceRequestId:req.sourceRequestId,sourceVersion:req.sourceVersion,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,
      mismatchType,expectedQuantity:a.qty,actualQuantity:mismatchType==='QUANTITY'?num(mismatchQty):null,expectedLot:a.lot||null,actualLot:mismatchType==='LOT'?String(mismatchLot).trim():null,note:mismatchType==='OTHER'?String(mismatchNote).trim():'',
      actorId:ACTOR.id,actor:ACTOR.name,observedAt:isoNow(),stockEffect:'NONE',status:'OPEN'
    };
    observation.observationHash=stableHash(observation);a.observationSeq=Number(a.observationSeq||0)+1;a.physicalObservation=observation;a.verified=false;a.physicalMismatch=true;a.affectedByChange=false;
    req.queue='WAITING';req.awaitingSourceAmendment=true;req.waitingReason='Đã gửi chênh lệch thực tế. Đang chờ Mua hàng cập nhật yêu cầu.';
    mismatchSheetOpen=false;io07VerifySheetOpen=false;io07ScanLot='';stateByScreen['SCR-037']='PHYSICAL_MISMATCH';return true;
  }

  io07ApplySourceUpdate=function(reqId,changes=[]){
    const req=io07Requests.find(r=>r.id===reqId);if(!req||req.completed||req.closed)return false;
    req.sourceVersion=Number(req.sourceVersion||0)+1;req.changed=true;const notes=[];const affected=new Set();
    for(const change of changes){
      if(change.type==='QTY'){
        const f=io07FindAllocation(change.allocationId,req);if(!f)continue;const a=f.allocation;a.previousQty=a.qty;a.qty=change.newQty;a.verified=false;a.physicalMismatch=false;a.affectedByChange=true;a.sourceVersion=req.sourceVersion;affected.add(a.id);
        // Keep stable source allocation identity; re-resolve source slices only when current exact composition no longer equals the new authorization.
        if(!slicesResolved(a)){seedCandidates(f.group,a,true);} else if((a.sourceStateCandidates||[]).length===1){a.sourceSlices[0].qty=num(a.qty);}
        notes.push(change.note||`${f.group.name} · ${f.group.uom}: ${a.previousQty} → ${change.newQty} ${f.group.uom}.`);
      } else if(change.type==='LOT'){
        const f=io07FindAllocation(change.allocationId,req);if(!f)continue;const a=f.allocation;a.previousLot=a.lot;a.lot=change.newLot;a.verified=false;a.physicalMismatch=false;a.affectedByChange=true;a.sourceVersion=req.sourceVersion;affected.add(a.id);seedCandidates(f.group,a,true);
        notes.push(change.note||`${f.group.name} · ${f.group.uom}: lô ${a.previousLot} → ${change.newLot}.`);
      } else if(change.type==='REMOVE'){
        for(const group of req.groups||[]){const idx=(group.allocations||[]).findIndex(a=>a.id===change.allocationId);if(idx>=0){const old=group.allocations[idx];group.allocations.splice(idx,1);affected.add(old.id);notes.push(change.note||`${group.name} · ${group.uom}${old.lot?` · lô ${old.lot}`:''}: bỏ khỏi yêu cầu; lượng chờ trả được trả về đúng trạng thái nguồn.`);break;}}
        req.groups=req.groups.filter(g=>(g.allocations||[]).length);
      } else if(change.type==='ADD'){
        let group=req.groups.find(g=>g.id===change.groupId);if(!group&&change.group){group={...change.group,allocations:[]};req.groups.push(group);}if(!group)continue;
        const a={...change.allocation,verified:false,physicalMismatch:false,affectedByChange:true};seedAllocation(req,group,a,true);group.allocations.push(a);affected.add(a.id);notes.push(change.note||`${group.name} · ${group.uom}${a.lot?` · lô ${a.lot}`:''}: thêm ${a.qty} ${group.uom} cần kiểm.`);
      }
    }
    for(const {allocation:a} of io07Allocations(req)){
      if(a.physicalObservation&&affected.has(a.id)){a.physicalObservation.status='RESOLVED_BY_SOURCE_VERSION';a.physicalObservation.resolvedSourceVersion=req.sourceVersion;}
      a.sourceVersion=req.sourceVersion;
    }
    req.sourceChanges=notes.length?notes:['Yêu cầu nguồn đã được cập nhật.'];req.awaitingSourceAmendment=false;req.queue='ACTIONABLE';return true;
  };

  io07CreateResult=function(req){
    const op=req.operationId||`IO-RTV-${String(req.id).replace(/^RTV-/,'')}`;req.operationId=op;const confirmedAt=isoNow();
    const lines=io07Allocations(req).map(({group,allocation:a})=>({groupId:group.id,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}));
    const evidence={handoverEvidenceId:`HE-${op}`,operationId:op,sourceType:'SUPPLIER_RETURN',sourceDocumentId:req.source,sourceVersion:req.sourceVersion,sourceContext:{sourceRequestId:req.sourceRequestId,inventoryRequestId:req.id},warehouseId:req.warehouseId,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt,lineEvidence:lines.map(l=>({sourceLineId:l.sourceLineId,sourceAllocationId:l.sourceAllocationId,productCode:l.code,uom:l.uom,lot:l.lot,quantity:l.qty,sourceSlices:l.sourceSlices}))};
    evidence.evidenceHash=stableHash(evidence);
    io07LastResult={operationId:op,requestId:req.id,sourceRequestId:req.sourceRequestId,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt,lines,handoverEvidence:evidence};req.handoverEvidence=evidence;req.confirmedAt=confirmedAt;return io07LastResult;
  };
  io07ResultSnapshot=function(){if(io07LastResult)return io07LastResult;const req=io07Current();return {operationId:req.operationId,requestId:req.id,sourceRequestId:req.sourceRequestId,supplier:req.supplier,source:req.source,sourceVersion:req.sourceVersion,warehouse:req.warehouse,actorId:ACTOR.id,actor:ACTOR.name,confirmedAt:req.confirmedAt||null,lines:io07Allocations(req).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}))};};

  const base036=renderers['SCR-036'];
  render036IO07=function(state){
    if(activeFlowId==='UIF-09')return render036IC09(state);if(activeFlowId==='UIF-10')return render036IC10(state);if(activeFlowId!=='UIF-07')return base036?base036(state):renderGeneric(screens.find(s=>s.id==='SCR-036'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ trả nhà cung cấp',body:deniedBody(),centered:true,back:false});
    if(state==='LOADING')return appShell({title:'Hàng chờ trả nhà cung cấp',body:loadingBody(),back:false});
    const all=io07ActiveRequests().filter(r=>io07MatchesQueue(r));const candidates=all.filter(r=>ioMatchesSearch(io07Query,`${r.id} ${r.supplier} ${r.source}`));
    const search=ds24Search(io07Query,'data-io07-search','Tìm mã yêu cầu, NCC hoặc chứng từ');
    const filters=`<div class="io07-chip-scroll" data-composed-from="VChip">${[['ALL','Tất cả'],['ACTIONABLE','Cần chuẩn bị'],['READY','Sẵn sàng'],['WAITING','Đang chờ']].map(([k,l])=>ds24Chip(k,l,io07QueueFilter===k,'data-io07-filter')).join('')}</div>`;
    if(state==='EMPTY')return appShell({title:'Hàng chờ trả nhà cung cấp',body:`${search}${filters}${ioEmpty('Chưa có hàng chờ trả','Khi có yêu cầu trả đang hiệu lực, công việc sẽ xuất hiện tại đây.')}`,back:false});
    const queue=io07QueueList(candidates);const empty=`<div data-io07-filter-empty ${candidates.length?'hidden':''}>${ioEmpty('Không tìm thấy yêu cầu phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}</div>`;
    return appShell({title:'Hàng chờ trả nhà cung cấp',body:`${search}${filters}${queue}${empty}`,back:false});
  };

  const base037=renderers['SCR-037'];
  render037IO07=function(state){
    if(activeFlowId==='UIF-09')return render037IC09(state);if(activeFlowId==='UIF-10')return render037IC10(state);if(activeFlowId!=='UIF-07')return base037?base037(state):renderGeneric(screens.find(s=>s.id==='SCR-037'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Chuẩn bị hàng trả',body:deniedBody(),centered:true});if(state==='LOADING')return appShell({title:'Chuẩn bị hàng trả',body:loadingBody()});
    const req=io07Current(),total=io07Allocations(req).length,verified=io07VerifiedCount(req);const waiting=req.queue==='WAITING'||req.awaitingSourceAmendment;
    const requestContext=ds24ContextStatusRow({title:req.id,subtitle:`${req.supplier} · ${req.source}`,label:waiting?'Chờ cập nhật':`${verified}/${total}`,tone:waiting?'Info':io07HasMismatch(req)?'Danger':verified===total&&total?'Success':'Neutral',leading:null,attrs:'data-layout-role="rtv-request-context"'});
    if(req.sourceCancelled||req.closed)return appShell({title:'Chuẩn bị hàng trả',body:`${requestContext}${vBanner('info','Yêu cầu đã được hủy','Phần chờ trả đã được hệ thống trả về đúng trạng thái nguồn; Kho không cần thao tác thêm.','','Compact')}`,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
    const waitBanner=waiting?vBanner('info','Chờ cập nhật yêu cầu',req.waitingReason||'Kho chỉ xem trong lúc Mua hàng cập nhật yêu cầu theo chênh lệch thực tế.','','Compact'):'';
    const groups=preparationGroups(req,waiting);const collection=ds24GroupedCollection(groups,'io07-product-list io07-grouped-collection io07-grouped-collection--preparation','Product group header,Nested navigation row');
    const body=`${requestContext}${io07SourceDelta(req)}${waitBanner}${ds24SectionTitle('Hàng cần chuẩn bị',`${req.groups.length} nhóm sản phẩm`)}${collection}${waiting?'':io07VerificationSheet(req)}${waiting?'':mismatchSheet(req)}`;
    return appShell({title:'Chuẩn bị hàng trả',body,actions:waiting?'':primaryFooter('Rà soát bàn giao','data-io07-action="review-handover"',!io07AllVerified(req)||io07HasMismatch(req))});
  };

  const base039=renderers['SCR-039'];
  render039IO07=function(state){
    if(activeFlowId!=='UIF-07')return base039?base039(state):renderGeneric(screens.find(s=>s.id==='SCR-039'),state);if(state==='PERMISSION_DENIED')return appShell({title:'Bàn giao trả nhà cung cấp',body:deniedBody(),centered:true});
    const req=io07Current(),sourceChanged=state==='SOURCE_CHANGED'||Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion),mismatch=io07HasMismatch(req)||state==='PHYSICAL_MISMATCH',ready=io07AllVerified(req)&&!sourceChanged&&!mismatch&&req.queue!=='WAITING';
    const context=ds24InfoGroup('Thông tin bàn giao',`${ds24InfoRow('Nhà cung cấp',req.supplier)}${ds24InfoRow('Yêu cầu trả',req.id)}${ds24InfoRow('Chứng từ nguồn',req.source)}${ds24InfoRow('Kho',req.warehouse)}`,'io07-handover-context');
    const review=`${ds24SectionTitle('Hàng sẽ bàn giao',`${req.groups.length} nhóm sản phẩm`)}${io07ReviewGroups(req,{statusLabel:'Đã kiểm',statusTone:'Success'})}`;
    if(!ready){const why=sourceChanged?'Yêu cầu nguồn đã đổi. Chỉ phần bị ảnh hưởng cần kiểm lại.':'Một số hàng chưa đủ điều kiện bàn giao. Hãy kiểm lại.';return appShell({title:'Bàn giao trả nhà cung cấp',body:`${context}${vBanner('warning','Cần kiểm lại trước khi bàn giao',why,'','Default')}${review}`,actions:primaryFooter('Kiểm lại hàng','data-io07-action="back-to-preparation"')});}
    return appShell({title:'Bàn giao trả nhà cung cấp',body:`${context}${review}`,actions:primaryFooter('Xác nhận đã bàn giao','data-io07-action="confirm-handover"')});
  };

  const base041=renderers['SCR-041'];
  render041IO07=function(state){
    if(activeFlowId!=='UIF-07')return base041?base041(state):renderGeneric(screens.find(s=>s.id==='SCR-041'),state);
    const currentReq=io07Current();const result=state==='UNKNOWN'?{operationId:currentReq.operationId,requestId:currentReq.id,sourceRequestId:currentReq.sourceRequestId,supplier:currentReq.supplier,source:currentReq.source,sourceVersion:currentReq.sourceVersion,warehouse:currentReq.warehouse,confirmedAt:currentReq.confirmedAt||null,lines:io07Allocations(currentReq).map(({group,allocation:a})=>({name:group.name,code:group.code,uom:group.uom,lot:a.lot,expiry:a.expiry,qty:a.qty,sourceLineId:a.sourceLineId,sourceAllocationId:a.sourceAllocationId,sourceSlices:(a.sourceSlices||[]).map(s=>({...s})),sourceSliceUserResolved:!!a.sourceSliceUserResolved}))}:io07ResultSnapshot(),req=io07Requests.find(r=>r.id===result.requestId)||currentReq;
    if(state==='PROCESSING')return appShell({title:'Kết quả trả nhà cung cấp',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){
      const body=ioResult('Đang xác minh kết quả','Không gửi lại bàn giao. Hệ thống đang xác minh đúng lần xử lý này bằng cùng operation identity.',[['Yêu cầu',result.requestId],['Chứng từ nguồn',result.source],['Tồn vật lý','Chưa kết luận']],'warning');
      const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-07" data-operation="${attr(result.operationId||req.operationId)}" data-scope="${attr(result.requestId+' · '+result.source)}"`;
      return appShell({title:'Xác minh kết quả',body,centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});
    }
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả trả nhà cung cấp',body:ioResult('Chưa ghi nhận bàn giao','Không có tác động tồn kho mới. Xem lại yêu cầu hiện hành trước khi tiếp tục.',[['Yêu cầu',result.requestId],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter(req&&!req.closed&&!req.completed?'Xem yêu cầu hiện tại':'Về hàng chờ trả',req&&!req.closed&&!req.completed?'data-io07-action="back-to-rtv-request"':'data-io07-action="result-to-rtv-queue"')});
    if(state==='PERMISSION_DENIED')return appShell({title:'Kết quả trả nhà cung cấp',body:ioResult('Không có quyền thực hiện','Tồn kho không thay đổi.',[['Kết quả','Không ghi nhận bàn giao'],['Tồn kho','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
    const resultGroupCount=new Set((result.lines||[]).map(line=>`${line.name}|${line.code||''}|${line.uom}`)).size;
    const context=ds24InfoGroup('Thông tin trả hàng',`${ds24InfoRow('Nhà cung cấp',result.supplier)}${ds24InfoRow('Yêu cầu trả',result.requestId)}${ds24InfoRow('Chứng từ nguồn',result.source)}${ds24InfoRow('Bàn giao lúc',displayTime(result.confirmedAt))}`,'io07-result-context');
    const body=`<div class="io-result io07-result">${resultHero('Đã bàn giao cho nhà cung cấp','Tồn vật lý và giá trị đã giảm theo đúng hàng bàn giao.')}${context}${ds24SectionTitle('Hàng đã bàn giao',`${resultGroupCount} nhóm sản phẩm`)}${io07ReviewGroups(result.lines||[],{statusLabel:'Đã bàn giao',statusTone:'Success'})}</div>`;
    return appShell({title:'Kết quả trả nhà cung cấp',body,centered:false,back:false,actions:primaryFooter('Về hàng chờ trả','data-io07-action="result-to-rtv-queue"')});
  };
  renderers['SCR-036']=render036IO07;renderers['SCR-037']=render037IO07;renderers['SCR-039']=render039IO07;renderers['SCR-041']=render041IO07;

  window.addEventListener('input',event=>{
    if(activeFlowId!=='UIF-07')return;const t=event.target;
    if(t.matches('[data-io07-scan-lot]')){event.stopImmediatePropagation();io07ScanLot=t.value;const found=activeFound();if(found){const expected=String(found.allocation.lot||''),bad=!scanMatches(found.group,found.allocation);const fb=document.querySelector('[data-io07-scan-feedback]');if(fb)fb.innerHTML=bad?vBanner('error','Lô không khớp',`Theo yêu cầu là lô ${expected}. Hãy ghi nhận chênh lệch để Mua hàng cập nhật.`,'','Compact'):'';syncVerifyButton();}return;}
    if(t.matches('[data-io07-source-slice]')){event.stopImmediatePropagation();const found=activeFound();if(!found)return;const a=found.allocation,state=t.dataset.io07SourceSlice,c=(a.sourceStateCandidates||[]).find(x=>x.state===state);if(!c)return;const q=Math.max(0,Math.min(num(t.value),num(c.available)));const map=new Map((a.sourceSlices||[]).map(s=>[s.state,{...s}]));if(q>0)map.set(state,{state,qty:q,balanceId:c.balanceId,balanceVersion:c.balanceVersion});else map.delete(state);a.sourceSlices=[...map.values()];a.sourceSliceUserResolved=true;a.verified=false;syncVerifyButton();return;}
    if(t.matches('[data-io07-mismatch-qty]')){event.stopImmediatePropagation();mismatchQty=t.value;syncMismatchButton();return;}
    if(t.matches('[data-io07-mismatch-lot]')){event.stopImmediatePropagation();mismatchLot=t.value;syncMismatchButton();return;}
    if(t.matches('[data-io07-mismatch-note]')){event.stopImmediatePropagation();mismatchNote=t.value;syncMismatchButton();return;}
  },true);

  window.addEventListener('click',event=>{
    if(activeFlowId!=='UIF-07')return;
    const a=event.target.closest('[data-io07-action]');if(!a)return;const k=a.dataset.io07Action;
    if(!['mark-mismatch','select-mismatch','close-mismatch','record-mismatch-observation','confirm-allocation','confirm-handover'].includes(k))return;
    event.preventDefault();event.stopImmediatePropagation();
    if(k==='mark-mismatch'){
      const found=activeFound();if(!found)return;mismatchSheetOpen=true;io07VerifySheetOpen=false;mismatchType='';mismatchQty='';mismatchLot=String(io07ScanLot||'').trim()||'';mismatchNote='';return renderAppScreen();
    }
    if(k==='select-mismatch'){mismatchType=a.dataset.io07MismatchType||'';if(mismatchType==='LOT'&&!mismatchLot)mismatchLot=String(io07ScanLot||'').trim();return renderAppScreen();}
    if(k==='close-mismatch'){mismatchSheetOpen=false;mismatchType='';return renderAppScreen();}
    if(k==='record-mismatch-observation'){if(recordObservation(io07Current()))return renderAppScreen();return;}
    if(k==='confirm-allocation'){
      const found=activeFound();if(!found)return;const {group,allocation:x}=found;if(verifyButtonDisabled(group,x))return;x.verified=true;x.physicalMismatch=false;x.affectedByChange=false;x.verifyMethod=String(io07ScanLot||'').trim()?'SCAN_OR_TYPED_MATCH':'VISUAL';x.verifiedSourceVersion=io07Current().sourceVersion;x.verifiedAt=isoNow();io07VerifySheetOpen=false;io07ScanLot='';stateByScreen['SCR-037']='READY';return renderAppScreen();
    }
    if(k==='confirm-handover'){
      const req=io07Current();if(Number(req.reviewSourceVersion||req.sourceVersion)!==Number(req.sourceVersion)){stateByScreen['SCR-039']='SOURCE_CHANGED';return renderAppScreen();}if(!io07AllVerified(req)||io07HasMismatch(req)||req.queue==='WAITING')return;io07CreateResult(req);req.completed=true;req.queue='CLOSED';stateByScreen['SCR-041']='COMPLETED';return navigate('SCR-041');
    }
  },true);

  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version='3.9.5';
})();

/* ===== v397-bj03-semantic-hardening.js ===== */
/* VET45 Theme 7 v3.9.7 — BJ03 direct valuation semantic hardening
 * Parent: v3.9.6
 * Approved decisions: T7-DR-150..156 / D03-01..D03-07
 */
(()=>{
  if(typeof val03Receipts==='undefined') return;

  const fmt=(n)=>`${Math.round(Number(n)||0).toLocaleString('vi-VN')} đ`;
  const stableHash=(parts)=>`sha256-fixture-${String(parts).replace(/[^a-zA-Z0-9]+/g,'-').toLowerCase()}`;

  function basisCandidate({id,label,version,unitPrice,currency='VND',fxRate=1,fxLabel='VND',unitLineDiscount=0,unitDocDiscount=0,unitKnownCost=0,unitNonDeductibleVat=0,components=[],evidenceRefs=[]}){
    const unitActual=unitPrice*fxRate-unitLineDiscount-unitDocDiscount+unitKnownCost+unitNonDeductibleVat;
    return {id,label,version:`v${version}`,basisVersion:version,basisHash:stableHash(`${id}|${version}|${unitActual}|${currency}|${fxRate}|${components.map(x=>`${x.type}:${x.source}:${x.version}:${x.amount||''}`).join('|')}`),authoritativeValueHash:stableHash(`${currency}|${fxRate}|${unitActual}`),unitPrice,currency,fxRate,fxLabel,unitLineDiscount,unitDocDiscount,unitKnownCost,unitNonDeductibleVat,components,evidenceRefs,provenance:components.map(x=>`${x.label} · ${x.source} ${x.version||''}`.trim())};
  }

  // Recast legacy source fixtures as complete DirectCostBasis candidates.
  for(const [ri,r] of val03Receipts.entries()){
    for(const [gi,g] of r.groups.entries()){
      g.receiptItemRef=g.receiptItemRef||`${r.id}-ITEM-${gi+1}`;
      g.valuationBasisKey=g.valuationBasisKey||`VB-${g.id}`;
      g.baseUom=g.baseUom||g.uom;
      g.conversionToBase=Number(g.conversionToBase||1);
      g.conversionVersion=g.conversionVersion||`CONV-${g.code}-v1`;
      g.basisDisplayLabel=g.basisDisplayLabel||`Dòng nguồn ${gi+1}`;
      for(const s of g.slices){
        s.originalQty=Number(s.originalQty??s.pendingQty);
        s.confirmedQty=Number(s.confirmedQty||0);
        s.confirmedValue=Number(s.confirmedValue||0);
      }
    }
  }
  const g1=val03Receipts[0].groups[0];
  g1.baseUom='lọ'; g1.conversionToBase=10; g1.conversionVersion='CONV-SP00142-v2';
  g1.sources=[basisCandidate({id:'BASIS-G1-A',label:'Căn cứ tổng hợp PO-2608-041',version:4,unitPrice:83000,unitLineDiscount:1000,unitDocDiscount:500,unitKnownCost:200,components:[
    {type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:83000},
    {type:'LINE_DISCOUNT',label:'Chiết khấu dòng',source:'PO-2608-041',version:'v3',amount:-1000},
    {type:'DOCUMENT_DISCOUNT',label:'Chiết khấu phiếu đã phân bổ',source:'PO-2608-041',version:'ALLOC-v2',amount:-500},
    {type:'KNOWN_PURCHASE_COST',label:'Chi phí mua đã có',source:'CTCP-2608-12',version:'v1',amount:200},
    {type:'SUPPLIER_CONFIRMATION',label:'Bằng chứng bổ sung',source:'Xác nhận NCC 02/09',version:'v1'}
  ],evidenceRefs:['PO-2608-041 v3','Xác nhận NCC 02/09 v1']})];
  g1.selectedSource='BASIS-G1-A';

  const g2=val03Receipts[0].groups[1];
  g2.sources=[
    basisCandidate({id:'BASIS-G2-PO',label:'Căn cứ theo PO-2608-041',version:3,unitPrice:120000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2608-041',version:'v3',amount:120000}]}),
    basisCandidate({id:'BASIS-G2-SUP',label:'Căn cứ theo xác nhận NCC 02/09',version:2,unitPrice:121000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 02/09',version:'v2',amount:121000}]})
  ];
  g2.selectedSource='';

  const g4=val03Receipts[2].groups[0];
  g4.sources=[basisCandidate({id:'BASIS-G4-A',label:'Căn cứ xác nhận NCC 01/09 + tỷ giá kế toán',version:2,unitPrice:4.1,currency:'USD',fxRate:24450,fxLabel:'Tỷ giá kế toán 24.450 VND/USD',components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'Xác nhận NCC 01/09',version:'v2',amount:4.1},{type:'FX',label:'Tỷ giá',source:'Kế toán',version:'FX-v7',amount:24450}]})];
  g4.selectedSource='BASIS-G4-A';
  const g5=val03Receipts[3].groups[0];
  g5.sources=[basisCandidate({id:'BASIS-G5-A',label:'Căn cứ theo PO-2609-008',version:1,unitPrice:46000,components:[{type:'PURCHASE_PRICE',label:'Giá mua',source:'PO-2609-008',version:'v1',amount:46000}]})];
  g5.selectedSource='BASIS-G5-A';

  let reviewTokens=null;
  function chosenBasis(g){return g.sources.find(x=>x.id===g.selectedSource)||null;}
  function basisState(g){
    if(!g.sources.length) return 'MISSING';
    const valueHashes=new Set(g.sources.map(x=>x.authoritativeValueHash));
    return valueHashes.size>1?'CONFLICT':'READY';
  }
  function ensureSingleBasis(g){if(basisState(g)==='READY'&&g.sources.length&&!g.selectedSource) g.selectedSource=g.sources[0].id;}
  function unitActual(g){const b=chosenBasis(g); if(!b) return null; return b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);}
  function normalizedBaseCost(g){const u=unitActual(g); return u==null?null:u/Math.max(1,Number(g.conversionToBase)||1);}
  function selectedQty(g){return g.slices.filter(s=>s.selected&&s.pendingQty>0).reduce((n,s)=>n+Math.min(Number(s.selectedQty)||0,s.pendingQty),0);}
  function confirmationAmount(g,s,q){
    const u=unitActual(g); if(u==null||q<=0) return 0;
    const original=Number(s.originalQty||s.pendingQty+s.confirmedQty||q);
    const fullScopeValue=Number(s.scopeAllocatedValue ?? Math.round(u*original));
    const newCumQty=Math.min(original,Number(s.confirmedQty||0)+q);
    const cumulativeTarget=Math.round(fullScopeValue*(newCumQty/original));
    return cumulativeTarget-Number(s.confirmedValue||0);
  }
  function calc(g){
    ensureSingleBasis(g);
    const b=chosenBasis(g),qty=selectedQty(g); if(!b||qty<=0) return null;
    let value=0;
    for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
      const q=Math.min(Number(s.selectedQty)||0,s.pendingQty); value+=confirmationAmount(g,s,q);
    }
    const actual=unitActual(g),base=normalizedBaseCost(g);
    return {qty,value,unitActual:actual,normalizedBaseCost:base,baseVnd:b.unitPrice*b.fxRate,src:b};
  }
  function currentTokenMap(r=val03Current()){
    const out={};
    for(const g of r.groups.filter(x=>selectedQty(x)>0)){
      ensureSingleBasis(g); const b=chosenBasis(g); if(!b) continue;
      out[g.id]={basisKey:g.valuationBasisKey,basisVersion:b.basisVersion,basisHash:b.basisHash,scopes:g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>({id:s.id,scopeVersion:s.scopeVersion}))};
    }
    return out;
  }
  function tokenStale(r=val03Current()){
    if(!reviewTokens) return false;
    const now=currentTokenMap(r);
    for(const [gid,t] of Object.entries(reviewTokens)){
      const n=now[gid]; if(!n||n.basisKey!==t.basisKey||n.basisVersion!==t.basisVersion||n.basisHash!==t.basisHash) return true;
      for(const s of t.scopes){const x=n.scopes.find(a=>a.id===s.id); if(!x||x.scopeVersion!==s.scopeVersion) return true;}
    }
    return false;
  }
  function duplicateBasisMeta(r,g){
    const dup=r.groups.filter(x=>x.code===g.code&&x.uom===g.uom&&x.slices.some(s=>s.pendingQty>0));
    return dup.length>1?`${g.basisDisplayLabel} · ${g.receiptItemRef}`:'';
  }
  function bootstrapConflict(r=val03Current()){
    const byProduct=new Map();
    for(const g of r.groups.filter(x=>selectedQty(x)>0&&x.officialCostStatus==='NONE')){
      const c=calc(g); if(!c) continue; const key=g.code; const arr=byProduct.get(key)||[]; arr.push(Math.round(c.normalizedBaseCost*1e6)/1e6); byProduct.set(key,arr);
    }
    return [...byProduct.values()].some(a=>new Set(a).size>1);
  }

  val03EvidenceState=basisState;
  val03Source=chosenBasis;
  val03GroupSelectedQty=selectedQty;
  val03Calc=calc;
  val03SourceDetail=function(g){const b=chosenBasis(g);return b?b.label:'Chưa chọn';};
  val03ScopeReady=function(r=val03Current()){
    const sel=val03SelectedSlices(r); if(!sel.length||bootstrapConflict(r)) return false;
    return r.groups.every(g=>{
      if(selectedQty(g)<=0) return true; const st=basisState(g); if(st==='MISSING') return false; if(st==='CONFLICT'&&(!g.selectedSource||!g.reason.trim())) return false; return !!chosenBasis(g);
    });
  };
  val03HasSelectedConflict=function(r=val03Current()){return r.groups.some(g=>selectedQty(g)>0&&basisState(g)==='CONFLICT'&&(!g.selectedSource||!g.reason.trim()));};
  val03TotalValue=function(r=val03Current()){return r.groups.reduce((n,g)=>n+(calc(g)?.value||0),0);};
  val03ReceiptState=function(r){const a=val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');if(!a.length)return 'WAITING';return a.some(x=>basisState(x.group)==='CONFLICT')?'CONFLICT':'READY';};
  val03ActionablePairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)!=='MISSING');};
  val03WaitingPairs=function(r=val03Current()){return val03PendingSlices(r).filter(x=>basisState(x.group)==='MISSING');};
  val03SourcePriceText=function(src,uom){return src.currency==='VND'?`${fmt(src.unitPrice)}/${uom}`:`${Number(src.unitPrice).toLocaleString('vi-VN')} ${src.currency}/${uom}`;};

  val03ApplySourceUpdate=function(groupId,newPrice){
    const r=val03Current(),g=r.groups.find(x=>x.id===groupId); if(!g||!g.sources.length)return false;
    const b=g.sources[0],before=val03SourcePriceText(b,g.uom),selectedAffected=activeScreenId==='SCR-017'&&selectedQty(g)>0;
    b.unitPrice=newPrice; b.basisVersion=Number(b.basisVersion||1)+1; b.version=`v${b.basisVersion}`;
    const actual=b.unitPrice*b.fxRate-(b.unitLineDiscount||0)-(b.unitDocDiscount||0)+(b.unitKnownCost||0)+(b.unitNonDeductibleVat||0);
    b.basisHash=stableHash(`${b.id}|${b.basisVersion}|${actual}|${Date.now()}`); b.authoritativeValueHash=stableHash(`${b.currency}|${b.fxRate}|${actual}`);
    val03LastSourceChange={name:g.name,source:b.label,from:before,to:val03SourcePriceText(b,g.uom)};
    if(basisState(g)==='CONFLICT'){g.selectedSource='';g.reason='';}
    // Preserve legacy sourceVersion only as a compatibility trigger when the selected reviewed basis changed.
    if(selectedAffected) r.sourceVersion+=1;
    return true;
  };
  window.val03ApplySourceUpdate=val03ApplySourceUpdate;

  val03Commit=function(){
    const r=val03Current(),selected=val03SelectedSlices(r),groups=[]; let totalValue=0;
    const productBootstrapTaken=new Set();
    for(const g of r.groups.filter(x=>selectedQty(x)>0)){
      const c=calc(g); if(!c) continue;
      const slices=[]; let groupValue=0;
      for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
        const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),amount=confirmationAmount(g,s,q),ad=val03SelectedAvailability(g,s);
        groupValue+=amount;
        slices.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount,availabilityDelta:ad,availabilityNote:s.availabilityNote,businessDate:r.receivedAt});
      }
      let bootstrapStatus='NOT_APPLICABLE';
      if(g.officialCostStatus==='NONE'){
        if(!productBootstrapTaken.has(g.code)){bootstrapStatus='INITIALIZED';productBootstrapTaken.add(g.code);}
        else bootstrapStatus='ALREADY_INITIALIZED';
      }
      groups.push({name:g.name,code:g.code,uom:g.uom,baseUom:g.baseUom,receiptItemRef:g.receiptItemRef,basisKey:g.valuationBasisKey,basisHash:c.src.basisHash,tracking:g.tracking,qty:c.qty,value:groupValue,unitActual:c.unitActual,normalizedBaseCost:c.normalizedBaseCost,source:c.src.label,officialCostBootstrapStatus:bootstrapStatus,slices});
      totalValue+=groupValue;
    }
    val03LastResult={operationId:`VAL-260904-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,recordedAt:'16/09/2026 16:25',accountingPeriod:r.receivedAt.slice(3),groups,totalValue};
    for(const {group,slice} of selected){
      const q=Math.min(Number(slice.selectedQty)||0,slice.pendingQty),amount=confirmationAmount(group,slice,q);
      slice.pendingQty-=q; slice.confirmedQty=Number(slice.confirmedQty||0)+q; slice.confirmedValue=Number(slice.confirmedValue||0)+amount; slice.scopeVersion+=1; slice.selected=false; slice.partialOpen=false; slice.selectedQty=slice.pendingQty;
      if(group.officialCostStatus==='NONE') group.officialCostStatus='EXISTS';
    }
    val03ReviewSourceVersion=null; reviewTokens=null; return val03LastResult;
  };

  val03ScopeGroupsHtml=function(r){
    const content=r.groups.filter(g=>g.slices.some(s=>s.pendingQty>0)).map(g=>{
      const st=basisState(g),badge=st==='MISSING'?['Chờ căn cứ','Neutral']:st==='CONFLICT'?['Cần đối chiếu','Warning']:['Đủ căn cứ','Success'];
      const rows=g.slices.filter(s=>s.pendingQty>0).map(s=>{
        const disabled=st==='MISSING',qty=Math.min(Number(s.selectedQty)||0,s.pendingQty),partial=s.selected?`<div class="val03-partial-controls"><button class="val03-partial-link" type="button" data-val03-partial="${s.id}" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">${s.partialOpen?'Dùng toàn bộ':'Xác nhận một phần'}</button>${s.partialOpen?`<label class="val03-qty" data-ds-component="VTextField" data-figma-node="522:7186"><span>Số lượng lần này</span><input type="number" min="1" max="${s.pendingQty}" value="${qty}" data-val03-qty="${s.id}"/><small>Tối đa ${s.pendingQty} ${esc(g.uom)}</small></label>`:''}</div>`:'';
        return `<div class="valuation-child-item val03-scope-item${s.selected?' is-selected':''}${disabled?' is-disabled':''}"><button type="button" class="valuation-child-row val03-check" data-val03-slice="${s.id}" aria-pressed="${s.selected}" ${disabled?'disabled aria-disabled="true"':''} data-composed-from="VCheckbox,VText"><span class="valuation-child-branch" aria-hidden="true"></span><span class="valuation-selection-control val03-check-mark" aria-hidden="true" data-ds-component="VCheckbox" data-ds-prop-state="${disabled?'Disabled':s.selected?'Checked':'Unchecked'}">${s.selected?icon('check','icon--xs'):''}</span><span class="valuation-child-copy"><strong>${esc(val03ScopeLabel(g,s))}</strong><small>${esc(s.stateLabel)} · Chờ giá ${s.pendingQty} ${esc(g.uom)}</small></span></button>${partial}</div>`;
      }).join('');
      return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,status:badge[0],tone:badge[1],meta:duplicateBasisMeta(r,g)})}<div class="valuation-child-list">${rows}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection val03-product-collection','DS v2 / Icon,VBadge,VCheckbox,VText,VTextField');
  };

  function componentsHtml(b){
    if(!b?.components?.length)return '';
    return `<div class="valuation-provenance" data-composed-from="VText"><strong>Thành phần của căn cứ</strong>${b.components.map(x=>`<p>${esc(`${x.label} · ${x.source}${x.version?` ${x.version}`:''}`)}</p>`).join('')}</div>`;
  }
  val03CalculationGroupsHtml=function(r){
    return r.groups.filter(g=>selectedQty(g)>0).map(g=>{
      const st=basisState(g); let basisUI='';
      if(st==='CONFLICT'){
        basisUI=`${vBanner('warning','Căn cứ giá đang mâu thuẫn','Chọn một căn cứ giá hoàn chỉnh có thẩm quyền và ghi lý do.')}<div class="valuation-source-list" data-composed-from="DS v2 / List Row,VRadio">${g.sources.map(b=>`<button type="button" class="val03-source-option ${g.selectedSource===b.id?'is-selected':''}" data-val03-source="${g.id}" data-val03-source-id="${b.id}" aria-pressed="${g.selectedSource===b.id}" data-ds-component="DS v2 / List Row"><span class="valuation-radio-control" aria-hidden="true"><span></span></span><span><strong>${esc(b.label)}</strong><small>${esc(val03SourcePriceText(b,g.uom))}</small></span></button>`).join('')}</div><label class="val03-reason" data-ds-component="VTextarea"><span>Lý do chọn căn cứ <b>*</b></span><textarea rows="3" data-val03-reason="${g.id}" placeholder="Nêu căn cứ để truy vết">${esc(g.reason||'')}</textarea></label>`;
      }else if(st==='MISSING') basisUI=vBanner('warning','Chưa đủ căn cứ','Phần này đang chờ căn cứ giá có thẩm quyền; không nhập giá tạm để đi tiếp.');
      else{ensureSingleBasis(g);const b=chosenBasis(g);basisUI=`${ds24InfoGroup('Căn cứ giá',ds24InfoRow('Căn cứ',b.label),'valuation-info-group valuation-info-group--wrap')}${componentsHtml(b)}`;}
      const c=calc(g),b=c?.src;
      const breakdown=c?`<div class="valuation-kv-stack" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nguồn quy đổi',`${fmt(c.baseVnd)}/${g.uom}`)}${b.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${fmt(b.unitLineDiscount)}/${g.uom}`):''}${b.unitDocDiscount?ds24KeyValueRow('Chiết khấu phiếu',`− ${fmt(b.unitDocDiscount)}/${g.uom}`):''}${b.unitKnownCost?ds24KeyValueRow('Chi phí mua đã có',`+ ${fmt(b.unitKnownCost)}/${g.uom}`):''}${b.unitNonDeductibleVat?ds24KeyValueRow('Thuế không khấu trừ',`+ ${fmt(b.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Giá nhập thực tế',`${fmt(c.unitActual)}/${g.uom}`,true)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Giá trị lần này',fmt(c.value),true)}</div>`:'';
      return `<section class="valuation-evidence-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,meta:duplicateBasisMeta(r,g)})}<div class="valuation-evidence-body">${basisUI}${breakdown}</div></section>`;
    }).join('');
  };
  val03EvidenceSheet=function(r=val03Current()){
    if(!val03EvidenceSheetOpen)return '';
    const invalid=!val03ScopeReady(r),title=val03HasSelectedConflict(r)?'Đối chiếu căn cứ giá':'Căn cứ giá và cách tính';
    const feedback=val03LastSourceChange?vBanner('warning','Căn cứ giá vừa thay đổi',`${val03LastSourceChange.name}: ${val03LastSourceChange.from} → ${val03LastSourceChange.to}`):bootstrapConflict(r)?vBanner('error','Không thể khởi tạo nhiều đơn giá khác nhau','Sản phẩm chưa có đơn giá chính thức; hãy xác nhận một căn cứ chuẩn hóa trước.'):invalid&&val03HasSelectedConflict(r)?vBanner('error','Cần hoàn tất căn cứ giá','Chọn căn cứ có thẩm quyền và ghi lý do cho phần đang mâu thuẫn.'):'';
    const body=val03CalculationGroupsHtml(r)||ioEmpty('Chưa có phạm vi để xem căn cứ','Chọn ít nhất một phạm vi hàng trước khi xem căn cứ giá và cách tính.');
    return `<div class="sheet-backdrop valuation-sheet-backdrop" data-val03-action="close-evidence-sheet"><section class="bottom-sheet val03-evidence-sheet valuation-evidence-sheet" data-ds-component="VBottomSheet" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}" onclick="event.stopPropagation()"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${feedback}${body}<div class="sheet-actions"><button class="button button--primary" type="button" data-val03-action="close-evidence-sheet" ${val03HasSelectedConflict(r)&&!val03ScopeReady(r)?'disabled':''} data-ds-component="VButton">${val03HasSelectedConflict(r)?'Xong':'Đóng'}</button></div></div></section></div>`;
  };

  val03ReviewGroupsHtml=function(r){
    const content=r.groups.filter(g=>selectedQty(g)>0).map(g=>{
      const c=calc(g),facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',c?`${fmt(c.unitActual)}/${g.uom}`:'—')}${g.baseUom!==g.uom&&c?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}${ds24KeyValueRow('Căn cứ giá',val03SourceDetail(g))}${g.officialCostStatus==='NONE'&&c?ds24KeyValueRow('Đơn giá chính thức khởi tạo',`${fmt(c.normalizedBaseCost)}/${g.baseUom}`):''}</div>`;
      const slices=g.slices.filter(s=>s.selected&&s.pendingQty>0).map(s=>{const q=Math.min(Number(s.selectedQty)||0,s.pendingQty),ad=val03SelectedAvailability(g,s),effect=ad>0?`+${ad} ${g.uom}`:s.availabilityNote;return valuationReadOnlyChild({title:val03ScopeLabel(g,s),subtitle:`${s.stateLabel} · ${q} ${g.uom}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(effect)}</strong></span>`});}).join('');
      return `<div class="valuation-product-group" data-valuation-basis="${escapeAttribute(g.valuationBasisKey)}">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:c?fmt(c.value):'—',meta:duplicateBasisMeta(r,g)})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection valuation-review-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
  };
  val03ResultGroupsHtml=function(res){
    const content=(res.groups||[]).map(g=>{
      const boot=g.officialCostBootstrapStatus==='INITIALIZED'?`Đã khởi tạo · ${fmt(g.normalizedBaseCost)}/${g.baseUom}`:g.officialCostBootstrapStatus==='ALREADY_INITIALIZED'?'Đã có trước đó · không ghi đè':'';
      const facts=`<div class="valuation-product-facts" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Giá nhập thực tế',`${fmt(g.unitActual)}/${g.uom}`)}${g.baseUom!==g.uom?ds24KeyValueRow(`Quy đổi ${g.baseUom}`,`${fmt(g.normalizedBaseCost)}/${g.baseUom}`):''}${boot?ds24KeyValueRow('Đơn giá chính thức',boot):''}</div>`;
      const slices=g.slices.map(s=>valuationReadOnlyChild({title:s.lot?`Lô ${s.lot}`:'Không theo lô',subtitle:`${s.state} · ${s.qty} ${g.uom} · ${fmt(s.value)}`,trailing:`<span class="valuation-child-value"><small>Khả dụng</small><strong>${esc(s.availabilityDelta>0?`+${s.availabilityDelta} ${g.uom}`:s.availabilityNote)}</strong></span>`})).join('');
      return `<div class="valuation-product-group">${valuationProductHeader({name:g.name,code:g.code,uom:g.uom,value:fmt(g.value),meta:g.receiptItemRef})}${facts}<div class="valuation-child-list">${slices}</div></div>`;
    }).join('');
    return ds24GroupedCollection(content,'valuation-product-collection valuation-result-collection','DS v2 / Icon,DS v2 / Key-value Row,VText');
  };

  const old014=render014IV03;
  render014IV03=function(state){
    if(activeFlowId!=='UIF-03')return old014(state);
    if(state==='FINANCIAL_MASKED')return appShell({title:'Hàng chờ xác nhận giá nhập',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Yêu cầu quyền tài chính phù hợp để mở công việc xác nhận giá.'),back:false});
    return old014(state);
  };
  const old015=render015IV03;
  render015IV03=function(state){
    if(activeFlowId!=='UIF-03')return old015(state);
    reviewTokens=null;
    if(state==='FINANCIAL_MASKED')return appShell({title:'Chọn hàng cần xác nhận giá',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Dữ liệu giá và căn cứ không được đưa vào DOM khi chưa có quyền.'),back:true});
    return old015(state);
  };
  render017IV03=function(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);
    const r=val03Current();
    if(state==='PERMISSION_DENIED'||state==='FINANCIAL_MASKED')return appShell({title:'Rà soát xác nhận giá',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Dữ liệu giá và căn cứ không được đưa vào DOM khi chưa có quyền.'),centered:true});
    if(!reviewTokens)reviewTokens=currentTokenMap(r);
    const stale=state==='SOURCE_CHANGED'||tokenStale(r);
    const summary=`${ds24InfoGroup('Phiếu nhận',`${ds24InfoRow('Phiếu',r.receipt)}${ds24InfoRow('Nhà cung cấp',r.supplier)}`,'valuation-info-group')}<div class="valuation-total-strip" data-composed-from="DS v2 / Key-value Row">${ds24KeyValueRow('Tổng giá trị sẽ ghi',fmt(val03TotalValue(r)),true)}</div>`;
    if(stale){val03EvidenceSheetOpen=true;return appShell({title:'Rà soát xác nhận giá',body:`${vBanner('warning','Căn cứ giá hoặc phạm vi đã thay đổi','Không thể xác nhận trên preview cũ. Đối chiếu lại căn cứ hiện hành trước khi tiếp tục.')}${summary}${ds24SectionTitle('Nội dung sẽ xác nhận',`${val03SelectedGroupCount(r)} nhóm căn cứ`)}${val03ReviewGroupsHtml(r)}${val03EvidenceSheet(r)}`});}
    const body=`${summary}${ds24SectionTitle('Nội dung sẽ xác nhận',`${val03SelectedGroupCount(r)} nhóm căn cứ`)}${val03ReviewGroupsHtml(r)}<button type="button" class="io-text-action valuation-text-action" data-val03-action="open-evidence-sheet" data-ds-component="DS v2 / Link">Xem căn cứ giá và cách tính</button>${val03EvidenceSheet(r)}`;
    return appShell({title:'Rà soát xác nhận giá',body,actions:primaryFooter('Xác nhận giá trị','data-val03-action="confirm-value"',!val03ScopeReady(r))});
  };
  render019IV03=function(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);
    const res=val03ResultSnapshot();
    if(state==='PROCESSING')return appShell({title:'Kết quả xác nhận giá',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const op=res.operationId||`VAL03-${res.receipt||'UNKNOWN'}`;const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(op)}" data-scope="${escapeAttribute(res.receipt||'BJ03 direct valuation')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định thao tác đã ghi hay chưa','Không gửi lại xác nhận. Chuyển đúng lần xử lý này sang luồng xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác nhận giá',body:ioResult('Chưa ghi nhận giá trị','Không có thay đổi. Kiểm tra lại phạm vi và căn cứ giá hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại hàng cần xác nhận','data-val03-action="result-to-scope"')});
    const actionable=val03ActionablePairs(val03Current()).length,waiting=val03WaitingPairs(val03Current()).length,waitingNote=waiting&&!actionable?vBanner('info','Phần còn lại đang chờ căn cứ','Bạn đã hoàn tất phần có thể xử lý.'):'';
    const overview=ds24InfoGroup('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt)}${ds24InfoRow('Ngày nghiệp vụ',res.businessDate||'—')}${ds24InfoRow('Ghi nhận lúc',res.recordedAt||'—')}${ds24KeyValueRow('Giá trị đã ghi',fmt(res.totalValue),true)}`,'valuation-info-group valuation-result-overview');
    const body=`<div class="io-result val03-result">${resultHero('Đã xác nhận giá','Giá trị đã được ghi cho đúng phạm vi đã chọn.')}${overview}${ds24SectionTitle('Phạm vi đã ghi')}${val03ResultGroupsHtml(res)}${waitingNote}</div>`;
    return appShell({title:'Kết quả xác nhận giá',body,centered:true,back:false,actions:primaryFooter(actionable?'Tiếp tục xác nhận':'Về danh sách',actionable?'data-val03-action="continue-remaining"':'data-val03-action="result-to-queue"')});
  };
  if(typeof renderers!=='undefined'){
    renderers['SCR-014']=render014IV03;renderers['SCR-015']=render015IV03;renderers['SCR-017']=render017IV03;renderers['SCR-019']=render019IV03;
  }

  // Public trace helpers for QA and fresh-eye review.
  window.val03V397={basisState,currentTokenMap,tokenStale,confirmationAmount,bootstrapConflict,normalizedBaseCost};
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.9.7';
})();

/* ===== v398-bj13-semantic-hardening.js ===== */
/* VET45 Theme 7 v3.9.8 — BJ13 late-landed-cost semantic hardening
 * Parent: v3.9.7
 * Approved decisions: T7-DR-157..163 / D13-01..D13-07
 */
(()=>{
  if(typeof val13Tasks==='undefined') return;

  const fmtMoney=(n)=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const stable=(v)=>{
    const s=typeof v==='string'?v:JSON.stringify(v,Object.keys(v||{}).sort());
    let h=2166136261>>>0; for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)>>>0;}
    return `fixture-hash-${h.toString(16).padStart(8,'0')}`;
  };
  const stableObj=(obj)=>{
    if(Array.isArray(obj)) return obj.map(stableObj);
    if(obj&&typeof obj==='object') return Object.fromEntries(Object.keys(obj).sort().map(k=>[k,stableObj(obj[k])]));
    return obj;
  };
  const stableHash=(obj)=>stable(JSON.stringify(stableObj(obj)));

  function periodForReceipt(receipt){
    if(/2608/.test(receipt)) return {businessDate:'21/08/2026',originalPeriod:'08/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đã khóa; ghi điều chỉnh ở kỳ mở hiện tại'};
    if(/2609/.test(receipt)) return {businessDate:'02/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
    return {businessDate:'16/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở'};
  }

  // Convert legacy fixtures into the v3.9.8 economic-source / valuation-exposure model.
  for(const t of val13Tasks){
    t.sourceComponentKey=t.sourceComponentKey||`LCOMP-${t.id.replace('LC13-','')}`;
    t.operationId=t.operationId||`LC13-CMD-${t.sourceComponentKey}`;
    t.sourceRevision=Number(t.sourceVersion||1);
    t.accountingRoute=t.accountingRoute||'LATE';
    t.taxTreatmentVersion=t.taxTreatmentVersion||'TAX-v3';
    t.fxSourceVersion=t.currency==='VND'?'VND':(t.fxSourceVersion||'FX-ACCOUNTING-v7');
    t.targetScopeMode=t.targetScopeMode||'FIXED';
    t.targetScopeKey=t.targetScopeKey||`TS-${t.sourceComponentKey}`;
    t.targetScopeVersion=t.targetScopeVersion||'v1';
    for(const x of (t.targets||[])){
      const p=periodForReceipt(x.receipt||'');
      x.initialValued=x.initialValued!==false;
      x.receiptItemRef=x.receiptItemRef||`${x.receipt}-ITEM-${x.lineId}`;
      x.valuationExposureKey=x.valuationExposureKey||`VE-${x.lineId}`;
      x.exposureVersion=Number(x.exposureVersion||1);
      x.baseQty=Number(x.baseQty||x.qty||0);
      x.initialDirectValue=Number(x.initialDirectValue??x.receivedValue??0);
      x.businessDate=x.businessDate||p.businessDate;
      x.originalPeriod=x.originalPeriod||p.originalPeriod;
      x.postingPeriod=x.postingPeriod||p.postingPeriod;
      x.periodReason=x.periodReason||p.periodReason;
      x.receiptValuationRefs=x.receiptValuationRefs||[`RV-${x.lineId}-1`];
      x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});
      x.selected=t.targetScopeMode==='FIXED'?true:(x.selected!==false);
    }
    t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:(t.targets||[]).map(x=>x.valuationExposureKey).sort()});
  }

  // Add a representative late-route component that must wait for initial valuation.
  if(!val13Tasks.some(t=>t.id==='LC13-005')){
    val13Tasks.push({id:'LC13-005',sourceRef:'Phí kiểm định QC-2609-22 · dòng 1',sourceVersion:1,sourceRevision:1,sourceComponentKey:'LCOMP-QC-2609-22-1',accountingRoute:'LATE',supplier:'Trung tâm kiểm định',component:'Phí kiểm định hàng mua',sourceAmount:420000,currency:'VND',normalizedAmount:420000,fxLabel:'VND',status:'WAITING',waitingOwner:'Chờ xác nhận giá ban đầu của 1 dòng',taxTreatmentVersion:'TAX-v3',fxSourceVersion:'VND',targetScopeMode:'FIXED',targetScopeKey:'TS-LCOMP-QC-2609-22-1',targetScopeVersion:'v1',policyVersion:'ALC-POL-v5',allowedMethods:[],selectedMethod:'',targets:[{id:'LC13-T8',receipt:'PN-260915-02',lineId:'ROL-702',product:'Oxytetracycline 20%',code:'SP-00702',uom:'chai',lot:null,qty:20,baseQty:20,initialDirectValue:0,initialValued:false,receiptItemRef:'PN-260915-02-ITEM-ROL-702',valuationExposureKey:'VE-ROL-702',exposureVersion:1,businessDate:'15/09/2026',originalPeriod:'09/2026',postingPeriod:'09/2026',periodReason:'Kỳ gốc đang mở',receiptValuationRefs:[],selected:true}]});
    const t=val13Tasks[val13Tasks.length-1],x=t.targets[0];x.exposureHash=stableHash({key:x.valuationExposureKey,version:1,qty:x.baseQty,value:0,refs:[],businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});t.targetScopeHash=stableHash({key:t.targetScopeKey,version:t.targetScopeVersion,members:[x.valuationExposureKey]});
  }

  function selectedTargets(t=val13Current()){
    return (t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'?true:x.selected);
  }
  function metricSnapshot(t,x,method=t.selectedMethod){
    const quantityMethod=method==='FIXTURE_QTY';
    const value=quantityMethod?Math.max(0,Number(x.quantityMetricValue)||0):Math.max(0,Number(x.initialDirectValue)||0);
    const unit=quantityMethod?(x.quantityMetricUnit||''):'initial_valuation_value_vnd';
    const version=quantityMethod?(x.quantityMetricVersion||'METRIC-QTY-v2'):'METRIC-INITIAL-VALUE-v2';
    return {method,metricValue:value,unit,metricVersion:version,metricHash:stableHash({exposure:x.valuationExposureKey,method,value,unit,version})};
  }
  function methodEligible(t,method=t.selectedMethod){
    const targets=selectedTargets(t);if(!targets.length)return false;
    const metrics=targets.map(x=>metricSnapshot(t,x,method));
    if(method==='FIXTURE_QTY'){const units=new Set(metrics.map(m=>m.unit).filter(Boolean));if(units.size!==1||metrics.some(m=>!m.unit))return false;}
    return metrics.reduce((n,m)=>n+m.metricValue,0)>0;
  }
  function lateCostBasisPayload(t=val13Current()){
    const targets=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
    return {sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||t.sourceRevision||1),sourceRef:t.sourceRef,sourceAmount:t.sourceAmount,currency:t.currency,normalizedAmount:t.normalizedAmount,taxTreatmentVersion:t.taxTreatmentVersion,fxSourceVersion:t.fxSourceVersion,fxRate:t.fxRate||1,accountingRoute:t.accountingRoute,policyVersion:t.policyVersion,method:t.selectedMethod,targetScopeKey:t.targetScopeKey,targetScopeVersion:t.targetScopeVersion,targetScopeHash:t.targetScopeHash,exposures:targets.map(x=>({key:x.valuationExposureKey,version:x.exposureVersion,hash:x.exposureHash,metric:metricSnapshot(t,x),businessDate:x.businessDate,originalPeriod:x.originalPeriod,postingPeriod:x.postingPeriod}))};
  }
  function lateCostBasisHash(t=val13Current()){return stableHash(lateCostBasisPayload(t));}
  function allocate(t=val13Current()){
    const selected=selectedTargets(t).slice().sort((a,b)=>a.valuationExposureKey.localeCompare(b.valuationExposureKey));
    const total=Number(t.normalizedAmount||0); if(!selected.length||t.normalizedAmount==null||!t.selectedMethod)return [];
    const metrics=selected.map(x=>metricSnapshot(t,x));
    const weightTotal=metrics.reduce((n,m)=>n+m.metricValue,0); if(weightTotal<=0||!methodEligible(t,t.selectedMethod))return [];
    const amounts=new Map(); let used=0;
    selected.forEach((x,i)=>{
      const weight=metrics[i].metricValue;
      const amount=i===selected.length-1?total-used:Math.round(total*(weight/weightTotal));
      used+=amount; amounts.set(x.valuationExposureKey,{amount,metric:metrics[i],ratio:weight/weightTotal});
    });
    return selected.map((x,i)=>({...x,allocatedAmount:amounts.get(x.valuationExposureKey).amount,allocationMetric:amounts.get(x.valuationExposureKey).metric,roundingAdjustment:i===selected.length-1?total-selected.slice(0,-1).reduce((n,y)=>n+amounts.get(y.valuationExposureKey).amount,0)-amounts.get(x.valuationExposureKey).amount:0}));
  }
  function allocationHash(t=val13Current()){
    return stableHash(allocate(t).map(x=>({key:x.valuationExposureKey,amount:x.allocatedAmount,metricHash:x.allocationMetric.metricHash,original:x.originalPeriod,posting:x.postingPeriod})));
  }
  function combinedPreviewHash(t=val13Current()){return `${lateCostBasisHash(t)}|${allocationHash(t)}`;}
  function dirtyScopes(t=val13Current()){
    const m=new Map(); for(const x of allocate(t)){const k=`${x.code}|${x.postingPeriod}`;m.set(k,{product:x.product,code:x.code,postingPeriod:x.postingPeriod,label:`${x.product} · ${x.postingPeriod}`});} return [...m.values()];
  }
  function periodGroups(t=val13Current()){
    const map=new Map(); for(const x of allocate(t)){const k=x.postingPeriod;const g=map.get(k)||{postingPeriod:k,originalPeriods:new Set(),reason:new Set(),count:0};g.originalPeriods.add(x.originalPeriod);if(x.periodReason)g.reason.add(x.periodReason);g.count++;map.set(k,g);}return [...map.values()].map(g=>({...g,originalPeriods:[...g.originalPeriods],reason:[...g.reason]}));
  }
  function allInitialValued(t=val13Current()){return selectedTargets(t).every(x=>x.initialValued);}
  function canOpen(t=val13Current()){return t.status==='ACTIONABLE'&&t.accountingRoute==='LATE'&&t.normalizedAmount!=null&&selectedTargets(t).length>0&&allInitialValued(t);}
  function canPreview(t=val13Current()){return canOpen(t)&&t.allowedMethods.some(m=>m.id===t.selectedMethod)&&methodEligible(t,t.selectedMethod)&&allocate(t).length>0;}

  val13SelectedTargets=selectedTargets;
  val13AllocationWeight=(target,method)=>metricSnapshot(val13Current(),target,method).metricValue;
  val13Preview=allocate;
  val13PreviewHashOf=combinedPreviewHash;
  val13CanOpenAllocation=canOpen;
  val13CanPreview=canPreview;
  val13DirtyScope=(t=val13Current())=>dirtyScopes(t).map(x=>x.label);
  val13StatusMeta=function(t){if(t.status==='WAITING')return [t.waitingOwner||'Đang chờ','neutral'];return ['', 'neutral'];};
  val13ResetTaskDraft=function(t){for(const x of (t.targets||[]))x.selected=true;const eligible=(t.allowedMethods||[]).filter(m=>methodEligible(t,m.id));t.selectedMethod=eligible.length===1?eligible[0].id:(eligible.some(m=>m.id===t.selectedMethod)?t.selectedMethod:'');val13ReviewSourceVersion=null;val13PreviewHash=null;val13LastSourceChange=null;};
  val13SourceCard=function(t){
    const context=ds24ContextStatusRow({title:t.sourceRef,subtitle:`${t.component} · ${t.supplier}`,label:t.status==='WAITING'?'Đang chờ':'',tone:'neutral',leading:null});
    const facts=`${ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))}${t.currency!=='VND'&&t.fxLabel?ds24InfoRow('Tỷ giá',t.fxLabel):''}${t.normalizedAmount!=null?ds24KeyValueRow('Sau chuẩn hóa',val13FmtMoney(t.normalizedAmount),true):''}`;
    return `${context}${ds24InfoGroup('Chi tiết nguồn',facts,'valuation-info-group valuation-info-group--wrap val13-source-card')}`;
  };
  val13TargetHtml=function(t){
    const fixed=t.targetScopeMode==='FIXED';
    return (t.targets||[]).map(x=>{
      const subtitle=`${x.receipt} · ${x.code} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`;
      if(fixed)return `<div class="val13-target-row is-selected v398-fixed-scope" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${icon('check','icon--xs')}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></div>`;
      return `<button type="button" class="val13-target-row ${x.selected?'is-selected':''}" data-val13-target="${x.id}" data-valuation-exposure="${esc(x.valuationExposureKey)}" aria-pressed="${x.selected}" data-composed-from="VCheckbox,VText"><span class="valuation-selection-control val13-check-mark" aria-hidden="true">${x.selected?icon('check','icon--xs'):''}</span><span class="val13-target-copy"><strong>${esc(x.product)}</strong><small>${esc(subtitle)}</small></span></button>`;
    }).join('');
  };
  val13AllocationRows=function(t=val13Current()){
    return allocate(t).map(x=>`<div class="val13-allocation-row valuation-allocation-row" data-valuation-exposure="${esc(x.valuationExposureKey)}" data-composed-from="VText"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
  };
  val13PeriodCard=function(t){
    const groups=periodGroups(t); if(!groups.length)return '';
    const rows=groups.map(g=>ds24InfoRow(`Ghi nhận ${g.postingPeriod}`,g.originalPeriods.length===1&&g.originalPeriods[0]===g.postingPeriod?`${g.count} dòng · cùng kỳ`:`${g.count} dòng · từ kỳ ${g.originalPeriods.join(', ')}`)).join('');
    const moved=groups.some(g=>g.originalPeriods.some(p=>p!==g.postingPeriod));
    return `${moved?vBanner('info','Có chi phí ghi ở kỳ mở','Kỳ gốc đã khóa vẫn được giữ để truy vết; adjustment được ghi ở kỳ mở theo policy.') : ''}${ds24InfoGroup('Kỳ ghi nhận',rows,'valuation-info-group')}`;
  };
  val13ReviewBody=function(t){
    const rows=allocate(t),method=t.allowedMethods.find(m=>m.id===t.selectedMethod)?.label||'—',total=rows.reduce((n,x)=>n+x.allocatedAmount,0);
    const allocation=`${ds24SectionTitle('Phân bổ sẽ ghi',`${rows.length} dòng`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow('Tổng phân bổ',val13FmtMoney(total),true)}</div>`,'valuation-allocation-collection val13-review-group','VText,DS v2 / Key-value Row')}`;
    const basis=ds24InfoGroup('Căn cứ phân bổ',`${ds24KeyValueRow('Chi phí sẽ ghi',val13FmtMoney(t.normalizedAmount),true)}${ds24InfoRow('Phương pháp',method)}`,'valuation-info-group');
    const effects=ds24InfoGroup('Sau khi ghi',`${ds24InfoRow('Cần tính lại',dirtyScopes(t).map(x=>x.label).join('; ')||'—')}`,'valuation-info-group valuation-info-group--wrap');
    return `${val13SourceCard(t)}${basis}${allocation}${val13PeriodCard(t)}${effects}`;
  };
  val13Commit=function(){
    const t=val13Current(),rows=allocate(t),groups=periodGroups(t),basisHash=lateCostBasisHash(t),allocHash=allocationHash(t);
    const adjustmentBatches=groups.map((g,i)=>({id:`LC13-ADJ-${String(val13OperationSeq).padStart(3,'0')}-${i+1}`,postingPeriod:g.postingPeriod,originalPeriods:g.originalPeriods,allocationCount:g.count}));
    val13LastResult={operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:rows.map(x=>({...x})),dirtyScope:dirtyScopes(t),periodGroups:groups,adjustmentBatches,lateCostBasisHash:basisHash,allocationHash:allocHash};
    t.status='COMPLETED';return val13LastResult;
  };
  val13Result=function(){const t=val13Current();return val13LastResult||{operationId:t.operationId,taskId:t.id,sourceComponentKey:t.sourceComponentKey,sourceRevision:Number(t.sourceVersion||1),sourceRef:t.sourceRef,component:t.component,normalizedAmount:t.normalizedAmount,allocations:allocate(t),dirtyScope:dirtyScopes(t),periodGroups:periodGroups(t),adjustmentBatches:[],lateCostBasisHash:lateCostBasisHash(t),allocationHash:allocationHash(t)};};
  val13ApplySourceUpdate=function(){const t=val13Current();if(t.status!=='ACTIONABLE')return;t.sourceVersion=Number(t.sourceVersion||1)+1;t.sourceRevision=t.sourceVersion;const before=t.normalizedAmount;t.normalizedAmount=Number(t.normalizedAmount||0)+100000;val13LastSourceChange={from:val13FmtMoney(before),to:val13FmtMoney(t.normalizedAmount),version:t.sourceVersion};if(activeScreenId==='SCR-088')stateByScreen['SCR-088']='SOURCE_CHANGED';render();};
  window.val13ApplySourceUpdate=val13ApplySourceUpdate;

  render085IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Chi phí mua bổ sung',body:deniedBody(),centered:true,back:false});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Chi phí mua bổ sung',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Liên hệ người quản trị nếu bạn cần xử lý chi phí mua.'),centered:true,back:false});
    const all=val13Tasks.filter(t=>t.status!=='COMPLETED');const filtered=all.filter(t=>{const ok=val13Filter==='ALL'||(val13Filter==='ACTIONABLE'&&t.status==='ACTIONABLE')||(val13Filter==='WAITING'&&t.status==='WAITING');return ok&&(!val13Query||val13TaskSearchText(t).includes(ioNormalizeSearch(val13Query)));});
    if(state==='EMPTY'&&!all.length)return appShell({title:'Chi phí mua bổ sung',body:ioEmpty('Không có chi phí mua bổ sung','Các chứng từ cần xử lý sẽ xuất hiện tại đây.'),centered:true,back:false});
    const rows=filtered.map(t=>ds24ListRow({title:val13QueueTitle(t),subtitle:`${t.component} · ${t.supplier}`,trailing:t.status==='WAITING'?ds24Badge('Đang chờ','neutral'):'',leading:null,attrs:`data-val13-task="${t.id}"`,type:'Navigation',state:t.status==='WAITING'?'Disabled':'Default',disabled:t.status==='WAITING'})).join('');
    const body=`${ds24Search(val13Query,'data-val13-search','Chứng từ chi phí hoặc nhà cung cấp')}<div class="ds24-chip-scroll" aria-label="Lọc chi phí mua bổ sung">${[['ALL','Tất cả'],['ACTIONABLE','Có thể xử lý'],['WAITING','Đang chờ']].map(([k,l])=>ds24Chip(k,l,val13Filter===k,'data-val13-filter')).join('')}</div>${filtered.length?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty('Không tìm thấy công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Chi phí mua bổ sung',body,back:false});
  };
  render086IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Nguồn và phạm vi chi phí',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Nguồn và phạm vi chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Nguồn và phạm vi chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể hiển thị nguồn và phạm vi chi phí.'),centered:true});
    if(t.status==='WAITING')return appShell({title:'Nguồn và phạm vi chi phí',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ căn cứ cần thiết.')}${val13SourceCard(t)}`});
    const changed=state==='SOURCE_CHANGED'||Boolean(val13LastSourceChange),selected=selectedTargets(t).length,scopeText=t.targetScopeMode==='FIXED'?`${t.targets.length} dòng theo chứng từ nguồn`:`${selected}/${t.targets.length} dòng đã chọn`;
    const body=`${changed?vBanner('warning','Nguồn chi phí vừa thay đổi',val13LastSourceChange?`Giá trị chuẩn hóa ${val13LastSourceChange.from} → ${val13LastSourceChange.to}. Kiểm tra lại phạm vi hiện hành trước khi tiếp tục.`:'Tải lại nguồn hiện hành trước khi tiếp tục.') : ''}${val13SourceCard(t)}${ds24SectionTitle('Phạm vi liên quan',scopeText)}${ds24GroupedCollection(val13TargetHtml(t),'valuation-selection-collection val13-target-list','VText')}`;
    return appShell({title:'Nguồn và phạm vi chi phí',body,actions:primaryFooter('Tiếp tục phân bổ','data-val13-action="scope-to-allocation"',!canOpen(t))});
  };
  render087IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-087'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Phân bổ chi phí',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Phân bổ chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể hiển thị phân bổ chi phí.'),centered:true});
    if(state==='SOURCE_CHANGED')return appShell({title:'Phân bổ chi phí',body:`${vBanner('warning','Căn cứ phân bổ đã thay đổi','Preview cũ không còn hợp lệ.')}${val13SourceCard(t)}`,actions:primaryFooter('Kiểm tra lại phạm vi','data-val13-action="back-scope"')});
    const preview=allocate(t),total=preview.reduce((n,x)=>n+x.allocatedAmount,0),opts=`<option value="">Chọn căn cứ phân bổ</option>`+t.allowedMethods.map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');
    const normalized=ds24InfoGroup('Chi phí cần phân bổ',`${ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))}${t.currency!=='VND'?ds24InfoRow('Tỷ giá',t.fxLabel):''}${ds24KeyValueRow('Sau chuẩn hóa',val13FmtMoney(t.normalizedAmount),true)}`,'valuation-info-group');
    const allocationBody=canPreview(t)?`${ds24SectionTitle('Kết quả phân bổ',`${preview.length} dòng`)}${ds24GroupedCollection(`${val13AllocationRows(t)}<div class="valuation-total-strip valuation-total-strip--inside">${ds24KeyValueRow('Tổng phân bổ',val13FmtMoney(total),true)}</div>`,'valuation-allocation-collection val13-allocation-list','VText,DS v2 / Key-value Row')}${val13PeriodCard(t)}`:vBanner('info','Chọn căn cứ phân bổ','Chọn một căn cứ được phép để xem phân bổ trước khi rà soát.','', 'Compact');
    const body=`${normalized}${ds24SectionTitle('Căn cứ phân bổ')}<label class="val13-select-field valuation-field" data-ds-component="VField"><span>Căn cứ phân bổ</span><select data-val13-method data-ds-component="VSelect" data-figma-node="522:7291">${opts}</select></label>${allocationBody}`;
    return appShell({title:'Phân bổ chi phí',body,actions:primaryFooter('Rà soát ghi chi phí','data-val13-action="open-review"',!canPreview(t))});
  };
  render088IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-088'),state);const t=val13Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát ghi chi phí',body:deniedBody(),centered:true});
    if(state==='FINANCIAL_MASKED')return appShell({title:'Rà soát ghi chi phí',body:ioEmpty('Không có quyền xem dữ liệu tài chính','Không thể rà soát hoặc ghi chi phí.'),centered:true});
    const stale=state==='SOURCE_CHANGED'||val13PreviewHash==null||val13PreviewHash!==combinedPreviewHash(t);
    if(stale)return appShell({title:'Rà soát ghi chi phí',body:`${vBanner('warning','Nguồn hoặc phân bổ đã thay đổi','Tạo lại phân bổ trước khi ghi chi phí.')}${val13SourceCard(t)}`,actions:primaryFooter('Tạo lại phân bổ','data-val13-action="back-allocation"')});
    const body=`${val13ReviewBody(t)}<button type="button" class="io-text-action valuation-text-action" data-val13-action="back-allocation" data-ds-component="DS v2 / Link" data-figma-node="4431:10396">Chỉnh sửa phân bổ</button>`;
    return appShell({title:'Rà soát ghi chi phí',body,actions:primaryFooter('Ghi chi phí mua bổ sung','data-val13-action="confirm-late-cost"')});
  };
  render089IV13=function(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const res=val13Result();
    if(state==='PROCESSING')return appShell({title:'Kết quả ghi chi phí',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const operation=res.operationId||val13Current().operationId,scope=res.sourceRef||val13Current().sourceRef;const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${esc(operation)}" data-scope="${esc(scope)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định thao tác đã ghi hay chưa','Không gửi lại chi phí. Giữ nguyên đúng lần xử lý này và chuyển sang xác minh trước mọi lần thử khác.',[['Chứng từ chi phí',scope],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả ghi chi phí',body:ioResult('Chưa ghi chi phí mua bổ sung','Không có thay đổi. Kiểm tra lại nguồn, phạm vi và phân bổ hiện hành.',[['Chứng từ chi phí',res.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-val13-action="back-allocation"')});
    if(state==='PERMISSION_DENIED'||state==='FINANCIAL_MASKED')return appShell({title:'Kết quả ghi chi phí',body:deniedBody(),centered:true,back:false,actions:primaryFooter('Về chi phí mua bổ sung','data-val13-action="result-to-queue"')});
    const allocationSummary=(res.allocations||[]).map(x=>`<div class="val13-result-line valuation-allocation-row"><span><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small></span><strong class="valuation-amount">${esc(val13FmtMoney(x.allocatedAmount))}</strong></div>`).join('');
    const periodText=(res.periodGroups||[]).map(g=>g.postingPeriod).join(', ')||'—';
    const overview=ds24InfoGroup('Kết quả',`${ds24InfoRow('Chứng từ',res.sourceRef)}${ds24KeyValueRow('Chi phí đã ghi',val13FmtMoney(res.normalizedAmount),true)}${ds24InfoRow('Kỳ ghi nhận',periodText)}${ds24InfoRow('Cần tính lại',(res.dirtyScope||[]).map(x=>x.label||x).join('; ')||'—')}`,'valuation-info-group valuation-info-group--wrap');
    const body=`<div class="io-result val13-result">${resultHero('Đã ghi chi phí mua bổ sung','Chi phí đã được ghi theo đúng phạm vi và kỳ đã xác nhận.')}${overview}${ds24SectionTitle('Phân bổ đã ghi')}${ds24GroupedCollection(allocationSummary,'valuation-allocation-collection val13-result-lines','VText')}</div>`;
    return appShell({title:'Kết quả ghi chi phí',body,centered:true,back:false,actions:primaryFooter('Về chi phí mua bổ sung','data-val13-action="result-to-queue"')});
  };

  if(typeof renderers!=='undefined'){
    renderers['SCR-085']=render085IV13;renderers['SCR-086']=render086IV13;renderers['SCR-087']=render087IV13;renderers['SCR-088']=render088IV13;renderers['SCR-089']=render089IV13;
  }

  window.val13V398={lateCostBasisPayload,lateCostBasisHash,allocationHash,combinedPreviewHash,metricSnapshot,methodEligible,allocate,dirtyScopes,periodGroups,allInitialValued,economicIdentity:(t=val13Current())=>t.sourceComponentKey,touchExposure:(id)=>{const t=val13Current(),x=t.targets.find(y=>y.id===id);if(!x)return false;x.exposureVersion+=1;x.exposureHash=stableHash({key:x.valuationExposureKey,version:x.exposureVersion,qty:x.baseQty,value:x.initialDirectValue,refs:x.receiptValuationRefs,businessDate:x.businessDate,original:x.originalPeriod,posting:x.postingPeriod});return true;},shuffleTargets:(t=val13Current())=>{t.targets.reverse();return true;}};
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.9.8';
})();

/* ===== v399-bj14-semantic-hardening.js ===== */
/* v3.9.9 BJ14 costing-run semantic hardening — D14-01..D14-07 */
(function(){
  const nowLabel="17/09/2026 · 08:41";
  const productSeed=[
    {product:"Nobivac DHPPi",baseUom:"lọ",state:"CHANGED",oldCost:81000,newCost:81700,cogsDelta:-900000,endingDelta:1450000,official:"81.700 đ/lọ"},
    {product:"Amoxicillin 500mg",baseUom:"viên",state:"CHANGED",oldCost:12450,newCost:12380,cogsDelta:-920000,endingDelta:1670000,official:"12.380 đ/viên"},
    {product:"Găng tay khám",baseUom:"đôi",state:"NO_NEW_COST_BASIS",oldCost:3200,newCost:3200,cogsDelta:0,endingDelta:0,official:"Giữ 3.200 đ/đôi"}
  ];
  function hashFor(r){return `RUN-${String(r.id).replace(/[^A-Z0-9]/gi,'').slice(-10)}-${r.runVersion||1}-${r.dirtyScopeVersion||1}`;}
  function enrich(r,idx){
    r.runType=r.runType||r.kind;
    r.calculationPeriod=r.calculationPeriod||r.period;
    r.postingPeriod=r.postingPeriod||r.period;
    r.scopeOrigin=r.scopeOrigin||(r.kind==="AD_HOC"?"DIRTY_SCOPE":"PERIOD_CLOSE_POLICY");
    r.dirtyScopeVersion=r.dirtyScopeVersion||(r.kind==="AD_HOC"?3:1);
    r.dirtyScopeHash=r.dirtyScopeHash||`DIRTY-${r.period.replace('/','')}-${r.dirtyScopeVersion}`;
    r.dirtyCauseCount=r.dirtyCauseCount||(r.kind==="AD_HOC"?3:0);
    r.cutoffValuationSequence=r.cutoffValuationSequence||(12840+idx*100);
    r.productCount=r.productCount||(r.kind==="AD_HOC"?3:184);
    r.changedProductCount=r.changedProductCount||(r.status==="BLOCKED"?0:(r.kind==="AD_HOC"?2:37));
    r.productResults=r.productResults||productSeed.map((x,i)=>({...x,resultHash:`PCR-${r.period.replace('/','')}-${i+1}`}));
    r.productResultSetHash=r.productResultSetHash||`PCRSET-${r.period.replace('/','')}-${r.runVersion||1}`;
    r.runInputHash=r.runInputHash||hashFor(r);
    r.cogsTrueUp=Number(r.cogsTrueUp||0);
    r.endingAdjustment=Number(r.endingAdjustment||0);
    if(r.id==="COST-0826" && r.status!=="PUBLISHED") r.effectiveAt="Khi công bố";
    if(r.kind==="AD_HOC" && r.status!=="PUBLISHED") r.effectiveAt="Khi công bố";
    return r;
  }
  val14Runs.forEach(enrich);

  function scopeLabel(r){return r.scopeOrigin==="DIRTY_SCOPE"?`${r.productCount} sản phẩm cần tính lại`:r.scope;}
  function productRows(r){
    const rows=(r.productResults||[]).slice(0,3).map(x=>`<div class="v399-product-cost-row" data-composed-from="VText,VBadge"><span class="v399-product-copy"><strong>${esc(x.product)}</strong><small>${x.state==="NO_NEW_COST_BASIS"?'Không có căn cứ giá mới':`Giá đề xuất ${esc(x.official)}`}</small></span><span class="v399-product-delta"><strong>${esc(val14Money(x.cogsDelta+x.endingDelta))}</strong><small>${x.state==="NO_NEW_COST_BASIS"?'Không điều chỉnh':'Chênh lệch ròng'}</small></span></div>`).join('');
    return ds24GroupedCollection(rows,"v399-product-cost-list","VText,VBadge");
  }
  function v399PeriodFacts(r){
    return ds24InfoGroup("Phạm vi tính",`${ds24InfoRow("Kỳ tính",r.calculationPeriod)}${ds24InfoRow("Kỳ ghi nhận",r.postingPeriod)}${ds24InfoRow("Sản phẩm",String(r.productCount))}${ds24InfoRow("Có thay đổi",String(r.changedProductCount))}`,'valuation-info-group valuation-info-group--wrap');
  }

  val14RunSummary=function(r){
    enrich(r,0); const [label,tone]=val14StatusMeta(r);
    const context=ds24ContextStatusRow({title:r.label,subtitle:`Kỳ ${r.postingPeriod} · ${scopeLabel(r)}`,label,tone:valuationDsTone(tone),leading:null});
    const facts=ds24InfoGroup("Thông tin lần tính",`${ds24InfoRow("Thời điểm chốt",r.cutoff)}${ds24InfoRow("Phương pháp công bố",r.policyLabel)}${ds24InfoRow("Kỳ tính",r.calculationPeriod)}${ds24InfoRow("Kỳ ghi nhận",r.postingPeriod)}`,'valuation-info-group valuation-info-group--wrap val14-summary');
    return `${context}${facts}`;
  };
  val14AdjustmentCard=function(r,title="Chênh lệch cần ghi"){
    return ds24InfoGroup(title,`${ds24KeyValueRow("Giá vốn xuất",val14Money(r.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(r.endingAdjustment),true)}${ds24InfoRow("Hiệu lực giá vốn",r.effectiveAt||"Khi công bố")}`,'valuation-info-group val14-adjustment');
  };
  val14CreateRun=function(){
    const id=`COST-${Date.now()}`; const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null;
    const isDirty=val14SetupKind==="AD_HOC" || !!base?.scopeOrigin&&base.scopeOrigin==="DIRTY_SCOPE";
    const run={id,label:val14SetupKind==="PERIOD_CLOSE"?`Tháng ${val14SetupPeriod}`:`Cập nhật ${nowLabel.split(' · ')[0]}`,kind:val14SetupKind,runType:val14SetupKind,status:"CALCULATING",period:val14SetupPeriod,calculationPeriod:val14SetupPeriod,postingPeriod:val14SetupPeriod,scope:isDirty?"Sản phẩm cần tính lại":val14SetupScope,scopeOrigin:isDirty?"DIRTY_SCOPE":"PERIOD_CLOSE_POLICY",cutoff:val14SetupKind==="PERIOD_CLOSE"?`Cuối kỳ ${val14SetupPeriod}`:nowLabel,policyMethod:base?.policyMethod||"PERIODIC",policyLabel:base?.policyLabel||"Bình quân cuối kỳ",policyVersion:base?.policyVersion||"Chính sách giá vốn",moving:{inventory:1243100000,cogs:488000000},periodic:{inventory:1246150000,cogs:486150000},cogsTrueUp:-1850000,endingAdjustment:3050000,effectiveAt:"Khi công bố",blockers:[],inputVersion:(base?.inputVersion||7)+1,runVersion:1,supersedes:base?.id||null,dirtyScopeVersion:(base?.dirtyScopeVersion||2)+1,dirtyCauseCount:isDirty?(base?.dirtyCauseCount||3):0,cutoffValuationSequence:(base?.cutoffValuationSequence||13000)+50,productCount:isDirty?(base?.productCount||3):184,changedProductCount:isDirty?2:38,productResults:productSeed.map((x,i)=>({...x,resultHash:`PCR-${Date.now()}-${i+1}`}))};
    enrich(run,0); val14Runs.unshift(run); val14SelectedRunId=id; val14PublishReviewVersion=null;
    if(val14CalcTimer)clearTimeout(val14CalcTimer); val14CalcTimer=setTimeout(()=>{run.status="READY_FOR_REVIEW";if(activeFlowId==="UIF-14"&&activeScreenId==="SCR-074")renderAppScreen();},120); return run;
  };
  val14ApplyInputChange=function(){const r=val14Current();r.inputVersion+=1;r.dirtyScopeVersion+=1;r.runInputHash=`${hashFor(r)}-STALE`;if(r.status==="READY_FOR_REVIEW")r.status="INPUT_CHANGED";return r.runInputHash;};
  val14Commit=function(){
    const r=val14Current(); enrich(r,0); r.status="PUBLISHED";r.runVersion+=1;r.publishedAt=nowLabel;r.effectiveAt=nowLabel;
    const created=(r.productResults||[]).filter(x=>x.state!=="NO_NEW_COST_BASIS"&&x.newCost!==x.oldCost).length;
    val14LastResult={runId:r.id,period:r.period,calculationPeriod:r.calculationPeriod,postingPeriod:r.postingPeriod,scope:scopeLabel(r),method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount,changedProducts:r.changedProductCount,officialCostVersions:created,dirtyCausesCleared:r.scopeOrigin==="DIRTY_SCOPE"?r.dirtyCauseCount:0,runInputHash:r.runInputHash,productResultSetHash:r.productResultSetHash};return val14LastResult;
  };
  render072IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-072"),state); if(state==="PERMISSION_DENIED")return appShell({title:"Giá vốn",body:deniedBody(),centered:true,back:false});
    const active=val14Runs.filter(r=>r.status!=="PUBLISHED");
    const rows=active.map(r=>{enrich(r,0);const [label,tone]=val14StatusMeta(r);const subtitle=r.scopeOrigin==="DIRTY_SCOPE"?`${r.productCount} sản phẩm · ${r.dirtyCauseCount} nguyên nhân cần đối soát`:`${r.scope} · ${r.policyLabel}`;return ds24ListRow({title:r.label,subtitle,trailing:ds24Badge(label,valuationDsTone(tone)),leading:null,attrs:`data-val14-run="${r.id}"`,type:"Navigation"});}).join('');
    return appShell({title:"Giá vốn",body:rows?`<section class="ds24-list-stack valuation-work-list" data-composed-from="DS v2 / List Row,VBadge">${rows}</section>`:ioEmpty("Chưa có lần tính giá vốn","Tạo một lần tính để bắt đầu."),back:false,actions:primaryFooter("Tạo lần tính",'data-val14-action="new-run"')});
  };
  render073IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-073"),state);if(state==="PERMISSION_DENIED")return appShell({title:"Thiết lập lần tính",body:deniedBody(),centered:true});
    const base=val14SuccessorOf?val14Runs.find(x=>x.id===val14SuccessorOf):null; const dirty=val14SetupKind==="AD_HOC"||base?.scopeOrigin==="DIRTY_SCOPE"; const periodClose=!dirty;
    const setupFacts=ds24InfoGroup("Chính sách áp dụng",`${ds24InfoRow("Thời điểm chốt",periodClose?`Cuối kỳ ${val14SetupPeriod}`:nowLabel)}${ds24InfoRow("Phương pháp công bố",base?.policyLabel||"Bình quân cuối kỳ")}${ds24InfoRow("Kỳ tính",val14SetupPeriod)}${ds24InfoRow("Kỳ ghi nhận",val14SetupPeriod)}`,'valuation-info-group');
    const periodField=`<label class="val14-field valuation-field" data-ds-component="VField"><span>Kỳ</span><select data-val14-period data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupPeriod==="08/2026"?'selected':''}>08/2026</option><option ${val14SetupPeriod==="09/2026"?'selected':''}>09/2026</option></select></label>`;
    const scope=dirty?ds24InfoGroup("Phạm vi cần tính lại",`${ds24InfoRow("Nguồn phạm vi","Điều chỉnh định giá đã ghi")}${ds24InfoRow("Sản phẩm",String(base?.productCount||3))}${ds24InfoRow("Nguyên nhân cần đối soát",String(base?.dirtyCauseCount||3))}`,'valuation-info-group v399-locked-scope'):`<label class="val14-field valuation-field" data-ds-component="VField"><span>Phạm vi</span><select data-val14-scope data-ds-component="VSelect" data-figma-node="522:7291"><option ${val14SetupScope==="Toàn bộ sản phẩm"?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==="Sản phẩm cần tính lại"?'selected':''}>Sản phẩm cần tính lại</option></select></label>`;
    const body=`${val14SuccessorOf?vBanner("warning","Dữ liệu đã thay đổi","Lần tính mới dùng phạm vi hiện hành; lần cũ được giữ để truy vết."):""}${ds24SectionTitle("Loại lần tính")}${val14KindChoices()}${periodField}${scope}${setupFacts}`;
    return appShell({title:"Thiết lập lần tính",body,actions:primaryFooter("Tính giá vốn",'data-val14-action="calculate"')});
  };
  render074IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-074"),state);const r=val14Current();enrich(r,0);if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả lần tính",body:deniedBody(),centered:true});
    if(state==="INPUT_CHANGED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố kết quả cũ. Tạo lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
    if(r.status==="CALCULATING"||state==="PROCESSING")return appShell({title:"Kết quả lần tính",body:ioResult("Đang tính giá vốn","Có thể rời màn hình; kết quả được lưu trong cùng lần tính.",[["Kỳ ghi nhận",r.postingPeriod],["Phạm vi",scopeLabel(r)]],"info"),centered:true});
    if(r.status==="BLOCKED"||state==="BLOCKED")return appShell({title:"Kết quả lần tính",body:`${vBanner("warning","Chưa thể công bố","Xử lý các vấn đề dưới đây trước khi tạo lần tính kế tiếp.")}${val14RunSummary(r)}${ds24SectionTitle("Đang bị chặn",`${r.blockers.length} vấn đề`)}${val14Blockers(r)}`});
    const body=`${val14RunSummary(r)}${v399PeriodFacts(r)}${ds24SectionTitle("Đối chiếu hai phương pháp")}${val14MethodCard(r)}${val14AdjustmentCard(r)}${ds24SectionTitle("Kết quả theo sản phẩm",`${r.changedProductCount} có thay đổi`)}${productRows(r)}`;
    return appShell({title:"Kết quả lần tính",body,actions:primaryFooter("Rà soát công bố",'data-val14-action="review-publish"',r.status!=="READY_FOR_REVIEW")});
  };
  render076IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-076"),state);const r=val14Current();enrich(r,0);if(state==="PERMISSION_DENIED")return appShell({title:"Rà soát công bố",body:deniedBody(),centered:true});
    const stale=state==="SOURCE_CHANGED"||val14PublishReviewVersion==null||String(val14PublishReviewVersion)!==String(r.runInputHash);
    if(stale)return appShell({title:"Rà soát công bố",body:`${vBanner("warning","Dữ liệu đầu vào đã thay đổi","Không thể công bố lần tính cũ. Tạo một lần tính kế tiếp từ dữ liệu hiện hành.")}${val14RunSummary(r)}`,actions:primaryFooter("Tạo lần tính kế tiếp",'data-val14-action="successor"')});
    const after=ds24InfoGroup("Sau công bố",`${ds24InfoRow("Sản phẩm đối soát",String(r.productCount))}${ds24InfoRow("Phiên bản giá vốn mới",String((r.productResults||[]).filter(x=>x.state!=="NO_NEW_COST_BASIS"&&x.newCost!==x.oldCost).length))}${ds24InfoRow("Hiệu lực","Không sớm hơn thời điểm công bố")}${r.scopeOrigin==="DIRTY_SCOPE"?ds24InfoRow("Phạm vi cần tính lại","Chỉ xóa sau khi ghi thành công"):''}`,'valuation-info-group');
    const body=`${val14RunSummary(r)}${v399PeriodFacts(r)}${val14AdjustmentCard(r,"Chênh lệch sẽ ghi")}${after}`;
    return appShell({title:"Rà soát công bố",body,actions:primaryFooter("Công bố giá vốn",'data-val14-action="publish"',r.status!=="READY_FOR_REVIEW")});
  };
  render077IV14=function(state){
    if(activeFlowId!=="UIF-14")return renderGeneric(screens.find(s=>s.id==="SCR-077"),state);const r=val14Current();const res=val14LastResult||{runId:r.id,period:r.period,postingPeriod:r.postingPeriod||r.period,scope:scopeLabel(r),method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,changedProducts:r.changedProductCount||0,officialCostVersions:0,dirtyCausesCleared:0};
    if(state==="PROCESSING")return appShell({title:"Kết quả công bố",body:loadingBody(),centered:true,back:false});
    if(state==="UNKNOWN"){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute((res.postingPeriod||r.postingPeriod||r.period)+' · '+scopeLabel(r))}"`;return appShell({title:"Đang xác minh kết quả",body:ioResult("Chưa xác định giá vốn đã được công bố hay chưa","Không gửi lại lệnh công bố. Chuyển đúng lần công bố này sang xác minh kết quả.",[["Lần tính",res.runId],["Trạng thái","Đang xác minh"]],"warning"),centered:true,back:false,actions:primaryFooter("Chuyển sang xác minh",attrs)});}
    if(state==="REJECTED_EXECUTION")return appShell({title:"Kết quả công bố",body:ioResult("Chưa công bố giá vốn","Không có điều chỉnh hoặc phiên bản giá vốn mới.",[["Kỳ ghi nhận",res.postingPeriod],["Tác động","Không thay đổi"]],"warning"),centered:true,back:false,actions:primaryFooter("Về kết quả lần tính",'data-val14-action="result-to-run"')});
    if(state==="PERMISSION_DENIED")return appShell({title:"Kết quả công bố",body:deniedBody(),centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
    const overview=ds24InfoGroup("Kết quả",`${ds24InfoRow("Lần tính",res.runId)}${ds24InfoRow("Kỳ ghi nhận",res.postingPeriod)}${ds24InfoRow("Phương pháp",res.method)}${ds24InfoRow("Sản phẩm đã đối soát",String(res.reconciledProducts))}${ds24InfoRow("Phiên bản giá vốn mới",String(res.officialCostVersions))}${ds24InfoRow("Hiệu lực",res.effectiveAt)}${ds24KeyValueRow("Giá vốn xuất",val14Money(res.cogsTrueUp),true)}${ds24KeyValueRow("Giá trị tồn cuối",val14Money(res.endingAdjustment),true)}${res.dirtyCausesCleared?ds24InfoRow("Nguyên nhân đã xử lý",String(res.dirtyCausesCleared)):''}`,'valuation-info-group valuation-info-group--wrap');
    return appShell({title:"Kết quả công bố",body:`<div class="io-result val14-result">${resultHero("Đã công bố giá vốn","Chênh lệch và phiên bản giá vốn đã được ghi từ kết quả đã chốt của lần tính.")}${overview}</div>`,centered:true,back:false,actions:primaryFooter("Về giá vốn",'data-val14-action="result-to-list"')});
  };
  // renderers map captured original function references in app.js; rebind BJ14 entries after overrides.
  renderers["SCR-072"]=render072IV14;
  renderers["SCR-073"]=render073IV14;
  renderers["SCR-074"]=render074IV14;
  renderers["SCR-076"]=render076IV14;
  renderers["SCR-077"]=render077IV14;
  window.__VET45_V399__={version:"3.9.9",decisions:[164,165,166,167,168,169,170],enrichRun:enrich};
})();

/* ===== v3100-bj08-semantic-hardening.js ===== */
(function(){
  const baseRender042V3100=renderers['SCR-042'];
  const BOOK={amox:20,glove:6};
  const META={
    amox:{name:'Amox 500',code:'SP-00128',lot:'L2407-A',uom:'hộp',state:'Bán được'},
    glove:{name:'Găng tay M',code:'SP-00410',lot:'L2405-M',uom:'hộp',state:'Cách ly'}
  };
  let roundNo=1;
  let roundHistory=[];
  let resultSnapshot=null;
  let dialogKind=null;
  let approvalCaseNo=1;
  let contributorNames=['Nguyễn An'];

  const num=(v)=>Number(String(v||'0').replace(',','.'))||0;
  const signed=(n)=>`${n>0?'+':''}${n}`;
  const allZero=(vals)=>Object.keys(BOOK).every(k=>num(vals[k])===BOOK[k]) && (!ic08UnexpectedLine || num(ic08UnexpectedLine.value)===0);
  const currentVariance=(vals)=>Object.keys(BOOK).map(k=>({id:k,...META[k],book:BOOK[k],count:num(vals[k]),variance:num(vals[k])-BOOK[k]})).filter(x=>x.variance!==0);
  const info=(rows)=>ic08ContextRows(rows);
  const lineHead=(m,badge='')=>ds24ListRow({title:m.name,subtitle:`${m.code} · Lô ${m.lot} · ${m.state} · ${m.uom}`,trailing:badge?ds24Badge(badge,'Info'):'',leading:'package',type:'Status',density:'Compact',interactive:false});
  function blindRow(id){ const m=META[id]; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockCountLine" data-physical-count-key="${id}">${lineHead(m)}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08Counts[id],`count:${id}`,m.uom,false)}</div></section>`; }
  function recountRow(id){ const m=META[id], book=BOOK[id], first=num(ic08Counts[id]), value=ic08Recounts[id], variance=first-book; return `<section class="ac321-product-input-group" data-theme-component="Theme7StockRecountLine" data-physical-count-key="${id}">${lineHead(m)}<div class="ac321-product-facts">${ds24KeyValueRow('Theo sổ',`${book} ${m.uom}`)}${ds24KeyValueRow('Lần đếm đầu',`${first} ${m.uom}`)}${ds24KeyValueRow('Chênh lệch',`${signed(variance)} ${m.uom}`)}</div><div class="ac321-product-field">${ic08QuantityTrigger('Số lượng đếm lại',value,`recount:${id}`,m.uom,false)}</div></section>`; }
  function unexpectedBlock(blind=true){
    if(!ic08UnexpectedLine) return '';
    const st=ic08UnexpectedLine.stockState||'';
    const select=`<label class="ds24-field" data-ds-component="VSelect"><span class="vet45-text-style-8">Trạng thái hàng</span><select class="ds24-field__control" data-v3100-stock-state><option value="">Chọn trạng thái</option><option value="SELLABLE" ${st==='SELLABLE'?'selected':''}>Bán được</option><option value="QUARANTINE" ${st==='QUARANTINE'?'selected':''}>Cách ly</option><option value="DAMAGED" ${st==='DAMAGED'?'selected':''}>Hỏng</option></select></label>`;
    const m={name:ic08UnexpectedLine.name,code:'Sản phẩm hiện có',lot:ic08UnexpectedLine.lot,uom:ic08UnexpectedLine.uom,state:st?({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng'}[st]||st):'Chưa xác định trạng thái'};
    return `<section class="ac321-product-input-group" data-theme-component="Theme7UnexpectedPhysicalKey">${lineHead(m,'Hàng thực tế')}${select}<div class="ac321-product-field">${ic08QuantityTrigger('Số lượng thực tế',ic08UnexpectedLine.value,'count:unexpected',m.uom,false)}</div><small class="vet45-text-style-11">Giá trị hàng thừa do nguồn có thẩm quyền cung cấp; người đếm không nhập giá.</small></section>`;
  }
  function footer(primaryLabel,primaryAction,secondary=true){ return `<footer class="app-actions figma-sticky-footer ds24-footer-stack" data-ds-pattern="Sticky Footer"><button class="ds24-button ds24-button--primary" type="button" data-v3100-ic08-action="${primaryAction}" data-ds-component="VButton">${primaryLabel}</button>${secondary?`<button class="ds24-button ds24-button--secondary" type="button" data-v3100-ic08-action="cancel-open" data-action-contract="ACT-09-CANCEL" data-ds-component="VButton">Hủy phiên</button>`:''}</footer>`; }
  function confirmSheet(){
    if(!dialogKind)return '';
    const cfg={open:['Mở phiên kiểm kê?','Hệ thống khóa phạm vi trước khi chốt số sổ và mở phiên.','Mở phiên',false],first:['Nộp lần đếm đầu?','Sau khi nộp, số sổ và chênh lệch mới được hiển thị.','Nộp kết quả',false],recount:['Gửi kết quả đếm lại?','Kết quả được lưu thành một vòng đếm lại bất biến.','Gửi kết quả',false],approve:['Duyệt và điều chỉnh?','Hệ thống kiểm tra lại căn cứ giá, quyền và khóa trước khi ghi điều chỉnh.','Duyệt và điều chỉnh',false],review:['Yêu cầu đếm lại?','Vòng đếm hiện tại được giữ nguyên. Một vòng đếm lại mới sẽ được mở.','Yêu cầu đếm lại',true],cancel:['Hủy phiên kiểm kê?','Không tạo điều chỉnh; toàn bộ lịch sử đếm được giữ và phạm vi được mở khóa.','Hủy phiên',true]}[dialogKind];
    if(!cfg)return '';
    const [title,desc,label,reason]=cfg; const val=dialogKind==='cancel'?ic08CancelReason:ic08ReviewReason;
    const reasonHtml=reason?ds24TextField('Lý do',val,dialogKind==='cancel'?'data-v3100-cancel-reason':'data-v3100-review-reason','Bắt buộc để lưu lịch sử quyết định.'):'';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="DS v2 / Confirmation Sheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${title}</h3><p class="vet45-text-style-6">${desc}</p>${reasonHtml}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="dialog-close">Quay lại</button><button class="ds24-button ${dialogKind==='cancel'?'ds24-button--danger':'ds24-button--primary'}" data-v3100-ic08-action="confirm-${dialogKind}" ${reason&&!val.trim()?'disabled':''}>${label}</button></div></section></div>`;
  }
  function overlays(){ return `${ic08NumericSheet()}${ic08SelectSheet()}${confirmSheet()}`; }

  render042IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-042'),state);
    // Preserve the previously approved interactive list/search/filter surface.
    // v3.10.0 changes stock-count semantics, not browse-list information architecture.
    const html=baseRender042V3100(state);
    return String(html).replace(/data-ic08-action=\"create\"/g,'data-v3100-ic08-action=\"new\"').replace(/data-ic08-action=\"resume\"/g,'data-v3100-ic08-action=\"resume-count\"');
  };

  render043IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-043'),state);
    if(state==='COUNT_SCOPE_HAS_UNRESOLVED_VALUATION') return appShell({title:'Tạo phiên kiểm kê',body:`${vBanner('warning','Chưa thể mở phiên','Phạm vi còn hàng chờ xác nhận giá trị. Hoàn tất phần giá trị hàng nhận trước khi kiểm kê.')}${info([['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}`,actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"')});
    const scopeOptions=[['ALL','Toàn kho'],['PRODUCT','Sản phẩm'],['GROUP','Nhóm sản phẩm'],['LOT','Lô']];
    const target=ic08Scope==='ALL'?'':`<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="scope-select-open">${ic08ScopeTarget||'Chọn phạm vi cụ thể'}</button>`;
    const body=`${info([['Kho','Kho trung tâm'],['Thời điểm chốt','Khi mở phiên'],['Người đếm',ic08AssignedCounter]])}${ds24SelectField('Phạm vi',ic08Scope,scopeOptions,'data-ic08-scope')}${target}${ds24TextField('Lý do kiểm kê',ic08Reason,'data-ic08-reason')}${vBanner('info','Phạm vi được khóa khi mở phiên','Hệ thống chốt số sổ và thành viên nhóm tại thời điểm khóa phạm vi.')}${overlays()}`;
    return appShell({title:'Tạo phiên kiểm kê',body,actions:primaryFooter('Mở phiên kiểm kê','data-v3100-ic08-action="open"')});
  };

  render044IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-044'),state);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ kết quả đếm','Nhập số lượng thực tế cho tất cả dòng trước khi nộp.'):'';
    const body=`${validation}${vBanner('info','Đếm mù','Số lượng theo sổ chỉ xuất hiện sau khi nộp lần đếm đầu.')}${info([['Phiên','KK-1709-01'],['Kho','Kho trung tâm'],['Người đếm',ic08AssignedCounter]])}${ic08Section('Hàng trong phạm vi',blindRow('amox')+blindRow('glove'))}${unexpectedBlock(true)}<button class="ds24-button ds24-button--secondary" type="button" data-ic08-action="add-actual-open">Thêm hàng thực tế</button>${overlays()}`;
    return appShell({title:'Đếm mù',body,actions:footer('Nộp kết quả đếm','submit-first',true)});
  };

  render045IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-045'),state);
    const diffs=currentVariance(ic08Counts);
    const ids=diffs.map(x=>x.id);
    const rows=ids.map(recountRow).join('');
    const basisBlocked=state==='PRICE_BASIS_REQUIRED';
    const basis=basisBlocked?vBanner('warning','Thiếu căn cứ giá hàng thừa','Phiên vẫn khóa; căn cứ giá phải đến từ nguồn có thẩm quyền.'):info([['Căn cứ giá hàng thừa',ids.includes('glove')?'Đã xác nhận':'Không phát sinh'],['Khóa phạm vi','Đang giữ']]);
    const validation=state==='VALIDATION_ERROR'?vBanner('error','Kết quả đếm lại chưa hợp lệ','Nhập số lượng đếm lại cho tất cả dòng chênh lệch.'):'';
    const body=`${validation}${vBanner('warning',`Đếm lại lần ${roundNo}`,`${ids.length} dòng còn chênh lệch. Kết quả vòng trước được giữ nguyên trong lịch sử.`)}${ic08Section('Dòng cần đếm lại',rows||'<p class="vet45-text-style-7">Không còn dòng chênh lệch.</p>')}${basis}${overlays()}`;
    return appShell({title:'Chênh lệch và đếm lại',body,actions:footer('Gửi kết quả đếm lại','submit-recount',true)});
  };

  render046IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-046'),state);
    if(state==='PERMISSION_DENIED')return appShell({title:'Duyệt kết quả kiểm kê',body:deniedBody(),centered:true,back:false});
    if(state==='COUNT_APPROVAL_SNAPSHOT_STALE')return appShell({title:'Duyệt kết quả kiểm kê',body:`${vBanner('warning','Kết quả cần được lập lại','Căn cứ giá hoặc dữ liệu kiểm kê đã thay đổi. Không thể điều chỉnh theo lần duyệt cũ.')}${info([['Phiên','KK-1709-01'],['Tác động','Chưa ghi điều chỉnh']])}`,back:false});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('warning','Không thể tự duyệt','Bạn đã tham gia kiểm đếm của kết quả này. Công việc cần người duyệt độc lập.'),back:false});
    if(state==='APPROVAL_ALREADY_DECIDED')return appShell({title:'Duyệt kết quả kiểm kê',body:vBanner('info','Công việc đã có quyết định','Mở kết quả phiên để xem trạng thái hiện hành.'),actions:primaryFooter('Xem kết quả','data-v3100-ic08-action="approval-result"'),back:false});
    const vals={amox:String(ic08Recounts.amox??'').trim()!==''?ic08Recounts.amox:(String(ic08Counts.amox??'').trim()!==''?ic08Counts.amox:'18'),glove:String(ic08Recounts.glove??'').trim()!==''?ic08Recounts.glove:(String(ic08Counts.glove??'').trim()!==''?ic08Counts.glove:'7')};
    const diffs=Object.keys(BOOK).map(k=>({id:k,...META[k],book:BOOK[k],count:num(vals[k]),variance:num(vals[k])-BOOK[k]})).filter(x=>x.variance!==0);
    const lines=diffs.map(x=>ic08Section(`${x.name} · ${x.lot}`,info([['Trạng thái',x.state],['Theo sổ',`${x.book} ${x.uom}`],['Đếm lại',`${x.count} ${x.uom}`],['Chênh lệch',`${signed(x.variance)} ${x.uom}`],...(x.variance>0?[['Căn cứ giá hàng thừa','Đã xác nhận']]:[['Căn cứ giá thiếu','Giá vốn đã khóa']])]))).join('');
    const body=`${vBanner('info','Cần quyết định độc lập','Bạn chỉ rà soát kết quả và quyết định; không sửa số đếm.')}${info([['Phiên','KK-1709-01'],['Lần đếm lại',String(roundNo)],['Người đã tham gia đếm',contributorNames.join(', ')],['Mức duyệt','Đã xác định theo rủi ro hiện hành']])}${lines}${overlays()}`;
    const actions=`<footer class="app-actions figma-sticky-footer ds24-footer-stack"><button class="ds24-button ds24-button--primary" data-v3100-ic08-action="approve">Duyệt và điều chỉnh</button><button class="ds24-button ds24-button--secondary" data-v3100-ic08-action="request-review">Yêu cầu xem lại</button></footer>`;
    return appShell({title:'Duyệt kết quả kiểm kê',body,actions,back:false});
  };

  render047IC08=function(state){
    if(activeFlowId!=='UIF-08') return renderGeneric(screens.find(s=>s.id==='SCR-047'),state);
    const snap=resultSnapshot;
    if(state==='UNKNOWN')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đang xác minh kết quả','Không gửi lại thao tác. Hệ thống cần xác minh đúng lần xử lý này.',[['Phiên','KK-1709-01'],['Định danh xử lý','Giữ nguyên'],['Tồn kho','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-08" data-operation="KK-1709-01" data-scope="Kho trung tâm · Kiểm kê"'),centered:true,back:false});
    if(state==='CANCELLED'||snap?.type==='CANCELLED')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hủy phiên','Không tạo điều chỉnh. Lịch sử đếm được giữ và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Thời điểm','17/09/2026 09:52']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Chưa thực hiện điều chỉnh','Điều kiện nghiệp vụ không đạt; không có tác động tồn kho.',[['Phiên','KK-1709-01'],['Tác động','Không ghi nhận']],'warning'),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    if(snap?.type==='ZERO')return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Kết quả thực tế khớp số sổ. Không cần tạo điều chỉnh và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh','Không tạo'],['Khóa phạm vi','Đã mở'],['Hoàn tất lúc',snap.committedAt]]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
    return appShell({title:'Kết quả kiểm kê',body:ds24Result('Đã hoàn tất kiểm kê','Điều chỉnh chênh lệch đã được ghi và phạm vi đã mở khóa.',[['Phiên','KK-1709-01'],['Điều chỉnh',snap?.adjustmentId||'ADJ-1709-08'],['Đã điều chỉnh',`${snap?.lines||2} dòng`],['Khóa phạm vi','Đã mở'],['Ghi nhận lúc',snap?.committedAt||'17/09/2026 09:52']]),actions:primaryFooter('Về kiểm kê','data-v3100-ic08-action="to-list"'),centered:true,back:false});
  };

  renderers['SCR-042']=render042IC08; renderers['SCR-043']=render043IC08; renderers['SCR-044']=render044IC08; renderers['SCR-045']=render045IC08; renderers['SCR-046']=render046IC08; renderers['SCR-047']=render047IC08;

  function rerender(){ if(typeof renderAppScreen==='function')renderAppScreen(); }
  document.addEventListener('input',function(e){
    if(e.target.matches('[data-v3100-cancel-reason]')){ic08CancelReason=e.target.value;rerender();}
    if(e.target.matches('[data-v3100-review-reason]')){ic08ReviewReason=e.target.value;rerender();}
  },true);
  document.addEventListener('change',function(e){ if(e.target.matches('[data-v3100-stock-state]')&&ic08UnexpectedLine){ic08UnexpectedLine.stockState=e.target.value;rerender();}},true);
  document.addEventListener('click',function(e){
    const a=e.target.closest('[data-v3100-ic08-action]'); if(!a||a.disabled)return;
    e.preventDefault();e.stopImmediatePropagation(); const k=a.dataset.v3100Ic08Action;
    if(k==='new'){roundNo=1;roundHistory=[];resultSnapshot=null;dialogKind=null;approvalCaseNo=1;contributorNames=[ic08AssignedCounter];ic08Counts={amox:'',glove:''};ic08Recounts={amox:'',glove:''};ic08UnexpectedLine=null;ic08CancelReason='';ic08ReviewReason='';stateByScreen['SCR-043']='READY';return navigate('SCR-043');}
    if(k==='resume-count'){return navigate('SCR-044');}
    if(k==='to-list'){resultSnapshot=null;return navigate('SCR-042');}
    if(k==='open'){dialogKind='open';return rerender();}
    if(k==='confirm-open'){dialogKind=null;stateByScreen['SCR-044']='BLIND_COUNT';return navigate('SCR-044');}
    if(k==='submit-first'){dialogKind='first';return rerender();}
    if(k==='confirm-first'){
      dialogKind=null;
      const missing=Object.keys(BOOK).some(id=>String(ic08Counts[id]??'').trim()===''||!Number.isFinite(Number(ic08Counts[id]))||Number(ic08Counts[id])<0);
      if(missing||(ic08UnexpectedLine&&num(ic08UnexpectedLine.value)>0&&!ic08UnexpectedLine.stockState)){stateByScreen['SCR-044']='VALIDATION_ERROR';return rerender();}
      roundHistory.push({round:1,type:'FIRST',actor:ic08AssignedCounter,values:{...ic08Counts},hash:'cnt-first-v3100'});
      if(allZero(ic08Counts)){resultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:50'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
      roundNo=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');
    }
    if(k==='submit-recount'){dialogKind='recount';return rerender();}
    if(k==='confirm-recount'){
      dialogKind=null;
      const ids=currentVariance(ic08Counts).map(x=>x.id);
      const missing=ids.some(id=>String(ic08Recounts[id]??'').trim()===''||!Number.isFinite(Number(ic08Recounts[id]))||Number(ic08Recounts[id])<0);
      if(missing){stateByScreen['SCR-045']='VALIDATION_ERROR';return rerender();}
      if(stateByScreen['SCR-045']==='PRICE_BASIS_REQUIRED'){return rerender();}
      roundHistory.push({round:roundNo+1,type:'RECOUNT',actor:ic08AssignedCounter,values:{...ic08Recounts},hash:`cnt-recount-${roundNo+1}-v3100`});
      if(allZero(ic08Recounts)){resultSnapshot={type:'ZERO',committedAt:'17/09/2026 09:51'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
      stateByScreen['SCR-042']='PENDING_APPROVAL';approvalCaseNo+=1;return navigate('SCR-042');
    }
    if(k==='cancel-open'){ic08CancelReason='';dialogKind='cancel';return rerender();}
    if(k==='confirm-cancel'){if(!ic08CancelReason.trim())return;dialogKind=null;resultSnapshot={type:'CANCELLED',reason:ic08CancelReason};stateByScreen['SCR-047']='CANCELLED';return navigate('SCR-047');}
    if(k==='approve'){if(window.__VET45_V350__?.getActor?.()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}dialogKind='approve';return rerender();}
    if(k==='confirm-approve'){if(window.__VET45_V350__?.getActor?.()!=='approver'){dialogKind=null;stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}dialogKind=null;resultSnapshot={type:'ADJUSTED',adjustmentId:'ADJ-1709-08',lines:currentVariance(ic08Recounts).length,committedAt:'17/09/2026 09:52'};stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
    if(k==='request-review'){if(window.__VET45_V350__?.getActor?.()!=='approver'){stateByScreen['SCR-046']='SELF_APPROVAL_NOT_ALLOWED';return rerender();}ic08ReviewReason='';dialogKind='review';return rerender();}
    if(k==='confirm-review'){if(!ic08ReviewReason.trim())return;dialogKind=null;roundNo+=1;stateByScreen['SCR-045']='RECOUNT_REQUIRED';return navigate('SCR-045');}
    if(k==='dialog-close'){dialogKind=null;return rerender();}
    if(k==='approval-result'){stateByScreen['SCR-047']='COMPLETED';return navigate('SCR-047');}
  },true);

  window.__VET45_V3100__={version:'3.10.0',decisions:[171,172,173,174,175,176,177],getRoundHistory:()=>roundHistory.slice(),getResult:()=>resultSnapshot};
})();

/* ===== v3101-bj09-semantic-hardening.js ===== */
(function(){
  'use strict';
  const VERSION='3.10.1';
  const BUSINESS_DATE='17/09/2026';
  const POLICY={
    id:'STPOL-INVENTORY-STATE',versionId:'STPOL-V7-20260917-01',version:'7',fixtureHash:'fixture-sha256-policy-v7',
    transitions:{
      SELLABLE:{
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:true,eligibility:'DECREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'DECREASE'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'DECREASE'}
      },
      QUARANTINE:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:false,approval:true,eligibility:'UNCHANGED'},
        DEMO:{label:'Dùng thử',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'}
      },
      DAMAGED:{QUARANTINE:{label:'Cách ly',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}},
      DEMO:{
        SELLABLE:{label:'Bán được',reason:true,evidence:true,approval:true,eligibility:'INCREASE'},
        QUARANTINE:{label:'Cách ly',reason:true,evidence:false,approval:false,eligibility:'UNCHANGED'},
        DAMAGED:{label:'Hỏng',reason:true,evidence:true,approval:true,eligibility:'UNCHANGED'}
      },
      EXPIRED:{}
    }
  };
  const SOURCE={
    amox:{slices:[{balanceId:'BAL-AMOX-C',version:7,valuationState:'VALUATION_CONFIRMED',qty:12},{balanceId:'BAL-AMOX-P',version:4,valuationState:'VALUATION_PENDING',qty:6}],reservationBefore:10},
    'găng':{slices:[{balanceId:'BAL-GLOVE-C',version:3,valuationState:'VALUATION_CONFIRMED',qty:6}],reservationBefore:0},
    vitc:{slices:[{balanceId:'BAL-VITC-C',version:2,valuationState:'VALUATION_CONFIRMED',qty:4}],reservationBefore:0},
    dungthu:{slices:[{balanceId:'BAL-DEMO-C',version:5,valuationState:'VALUATION_CONFIRMED',qty:2}],reservationBefore:0}
  };
  let draft={destination:'QUARANTINE',quantity:'5',reason:'Bao bì có dấu hiệu bất thường',evidence:''};
  let basis=null, decision=null, rejectOpen=false, rejectReason='', movement=null, seq=1;
  let staleOnExecute=false;

  const escText=(v)=>typeof esc==='function'?esc(String(v??'')):String(v??'');
  const num=(v)=>Number(String(v??'').replace(',','.'))||0;
  const current=()=>ic09Current();
  const actor=()=>window.__VET45_V350__?.getActor?.()||'module';
  const stateLabel=(v)=>({SELLABLE:'Bán được',QUARANTINE:'Cách ly',DAMAGED:'Hỏng',DEMO:'Dùng thử',EXPIRED:'Hết hạn'}[v]||v);
  const transition=()=>POLICY.transitions[current().state]?.[draft.destination]||null;
  function fixtureHash(payload){
    // Deterministic harness fixture only. Production contract requires canonical SHA-256.
    const s=JSON.stringify(payload);let h=2166136261;
    for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return `fixture-${(h>>>0).toString(16).padStart(8,'0')}`;
  }
  function resolveSlices(item,qty){
    const src=SOURCE[item.id]?.slices||[]; let remaining=qty,out=[];
    // Fixture resolver uses stable source-lineage order. Production resolver is server-owned.
    for(const slice of src){if(remaining<=0)break;const take=Math.min(remaining,slice.qty);if(take>0){out.push({...slice,quantity:take});remaining-=take;}}
    if(remaining>0)return null;
    return out;
  }
  function eligibleQty(item,slices){
    if(item.state!=='SELLABLE')return 0;
    return (slices||SOURCE[item.id]?.slices||[]).filter(x=>x.valuationState==='VALUATION_CONFIRMED').reduce((a,x)=>a+(x.qty??x.quantity??0),0);
  }
  function basisValid(){
    const x=current(),t=transition(),q=num(draft.quantity);
    if(!t||q<=0||q>x.qty||!draft.reason.trim())return false;
    if(t.evidence && !draft.evidence.trim())return false;
    return Boolean(resolveSlices(x,q));
  }
  function buildBasis(){
    const x=current(),t=transition(),q=num(draft.quantity),slices=resolveSlices(x,q);
    if(!t||!slices)return null;
    const src=SOURCE[x.id]||{reservationBefore:0};
    const beforeEligible=eligibleQty(x);
    const confirmedMoved=slices.filter(z=>z.valuationState==='VALUATION_CONFIRMED').reduce((a,z)=>a+z.quantity,0);
    const destinationEligible=draft.destination==='SELLABLE';
    const afterEligible=Math.max(0,beforeEligible-(x.state==='SELLABLE'?confirmedMoved:0)+(destinationEligible?confirmedMoved:0));
    const reservationAfter=Math.min(src.reservationBefore||0,afterEligible);
    const payload={
      basisId:`SCB-1709-${String(seq++).padStart(3,'0')}`,itemId:x.id,product:x.name,lot:x.lot,from:x.state,to:draft.destination,
      quantity:q,uom:x.uom,sourceSlices:slices,policyVersionId:POLICY.versionId,policyHash:POLICY.fixtureHash,
      reason:draft.reason.trim(),evidence:draft.evidence.trim(),businessDate:BUSINESS_DATE,expiry:x.expiry,
      reservationImpact:{before:src.reservationBefore||0,after:reservationAfter,shortfall:Math.max(0,(src.reservationBefore||0)-reservationAfter),allocationReviewRequired:(src.reservationBefore||0)>reservationAfter}
    };
    payload.basisHash=fixtureHash(payload);
    return Object.freeze(payload);
  }
  function resetDraft(){
    draft={destination:current().state==='SELLABLE'?'QUARANTINE':'SELLABLE',quantity:String(Math.min(current().qty,5)),reason:'',evidence:''};
    basis=null;decision=null;rejectOpen=false;rejectReason='';movement=null;staleOnExecute=false;
  }
  function approvalRows(b){
    return icHeaderRows([
      ['Sản phẩm',b.product,true],['Lô',b.lot],['Từ',stateLabel(b.from)],['Sang',stateLabel(b.to)],['Số lượng',`${b.quantity} ${b.uom}`],['Lý do',b.reason||'—'],
      ...(b.evidence?[['Bằng chứng',b.evidence]]:[]),
      ['Tác động khả dụng',b.reservationImpact.shortfall>0?`Giảm; ${b.reservationImpact.shortfall} ${b.uom} cần phân bổ lại`:'Đã kiểm tra']
    ]);
  }
  function rejectSheet(){
    if(!rejectOpen)return '';
    return `<div class="sheet-backdrop ds24-overlay"><section class="ds24-confirmation" data-ds-component="VBottomSheet" role="dialog" aria-modal="true"><div class="ds24-confirmation__handle"></div><h3>Từ chối yêu cầu?</h3><p>Lý do được lưu cùng quyết định và không làm thay đổi tồn kho.</p>${icTextarea('Lý do từ chối',rejectReason,'data-v3101-reject-reason','Bắt buộc')}<div class="ds24-confirmation__actions"><button class="ds24-button ds24-button--secondary" data-v3101-action="reject-close">Quay lại</button><button class="ds24-button ds24-button--danger" data-v3101-action="reject-confirm" ${rejectReason.trim()?'':'disabled'}>Xác nhận từ chối</button></div></section></div>`;
  }
  function destinationChoices(){
    const x=current();return Object.entries(POLICY.transitions[x.state]||{}).map(([code,cfg])=>`<label class="v364-radio-option" data-ds-component="VRadio" data-ds-prop-state="${draft.destination===code?'On':'Off'}"><input type="radio" name="v3101-destination" value="${code}" data-v3101-destination ${draft.destination===code?'checked':''}><span class="v364-radio-control" aria-hidden="true"></span><span class="v364-radio-copy"><strong>${cfg.label}</strong><small>${cfg.approval?'Cần người duyệt độc lập':'Có thể xử lý ngay theo quy tắc hiện hành'}</small></span></label>`).join('');
  }
  function infoCurrent(x){
    const src=SOURCE[x.id];const available=x.state==='SELLABLE'?eligibleQty(x):0;
    return icHeaderRows([['Sản phẩm',x.name,true],['Mã',x.code],['Lô',x.lot],['Hạn dùng',x.expiry],['Tình trạng',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`${available} ${x.uom}`]]);
  }

  const base036=renderers['SCR-036'],base037=renderers['SCR-037'],base038=renderers['SCR-038'],base041=renderers['SCR-041'],base056=renderers['SCR-056'];
  renderers['SCR-036']=function(state){
    if(activeFlowId!=='UIF-09')return base036(state);
    if(['PERMISSION_DENIED','LOADING','EMPTY'].includes(state))return base036(state);
    const labels=[['ALL','Tất cả'],['SELLABLE','Bán được'],['QUARANTINE','Cách ly'],['DAMAGED','Hỏng'],['DEMO','Dùng thử'],['EXPIRED','Hết hạn']];
    const q=ic09Query.trim().toLowerCase();
    const items=ic09Items.filter(x=>(ic09Filter==='ALL'||x.state===ic09Filter)&&(!q||`${x.name} ${x.code} ${x.lot}`.toLowerCase().includes(q)));
    const rows=items.map(x=>ioProductRow({name:x.name,code:x.code,primary:`${x.qty} ${x.uom}`,secondary:`Lô ${x.lot}`,badge:stateLabel(x.state),badgeStatus:ic09StatusTone(x.state),attr:`data-ic09-item="${x.id}"`})).join('');
    return appShell({title:'Tình trạng hàng',body:`${ds24Search(ic09Query,'data-ic09-search','Tìm sản phẩm hoặc lô')}<div class="ac321-chip-wrap" data-composed-from="VChip">${labels.map(([k,l])=>ds24Chip(k,l,ic09Filter===k,'data-ic09-filter')).join('')}</div>${rows?`<div class="io-list-card" data-ds-component="VSection"><div class="io-product-list">${rows}</div></div>`:ioEmpty('Không có hàng phù hợp','Thử đổi bộ lọc hoặc từ khóa tìm kiếm.')}`,back:false});
  };
  renderers['SCR-037']=function(state){
    if(activeFlowId!=='UIF-09')return base037(state);
    if(['PERMISSION_DENIED','LOADING'].includes(state))return base037(state);
    const x=current(),expired=x.state==='EXPIRED'||state==='EXPIRED';
    const notice=expired?vBanner('warning','Lô đã hết hạn',`Hết hạn theo ngày nghiệp vụ ${BUSINESS_DATE}; hệ thống tự loại khỏi khả dụng.`):state==='LOCKED'?vBanner('info','Đang thuộc phạm vi kiểm kê','Thông tin chỉ đọc cho đến khi phạm vi được mở khóa.'):'';
    const body=`${notice}${infoCurrent(x)}${ioSectionTitle('Tác động')}<p class="io-footnote">Đổi tình trạng chỉ phân loại lại cùng lượng hàng. Tổng tồn vật lý và giá trị ghi sổ không đổi.</p>${icSecondary('Xem lịch sử','data-ic09-action="history"')}`;
    return appShell({title:'Chi tiết tình trạng hàng',body,actions:expired||state==='LOCKED'?'':primaryFooter('Thay đổi tình trạng','data-ic09-action="change"')});
  };
  renderers['SCR-038']=function(state){
    if(activeFlowId!=='UIF-09')return base038(state);
    const x=current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Chuyển tình trạng hàng',body:deniedBody(),centered:true,back:false});
    if(state==='LOCKED')return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đang thuộc phạm vi kiểm kê','Không thể đổi tình trạng khi phạm vi đang khóa.')}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Tình trạng hiện tại',stateLabel(x.state)]])}`,back:false});
    if(state==='SELF_APPROVAL_NOT_ALLOWED')return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không thể tự duyệt','Người lập yêu cầu không được tự duyệt yêu cầu này.'),back:false});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='CONFLICT')return appShell({title:'Yêu cầu đã thay đổi',body:`${vBanner('warning','Cần lập lại yêu cầu','Dữ liệu đã thay đổi; quyết định cũ không còn hiệu lực.')}${basis?approvalRows(basis):infoCurrent(x)}`,actions:primaryFooter('Lập lại yêu cầu','data-v3101-action="rebuild"'),back:false});
    if(state==='PENDING_APPROVAL'){
      const b=basis;return appShell({title:'Chuyển tình trạng hàng',body:`${vBanner('info','Đã gửi chờ duyệt','Tồn kho chưa thay đổi; người duyệt nhận công việc riêng.')}${b?approvalRows(b):infoCurrent(x)}`,back:false});
    }
    if(state==='APPROVAL_REVIEW'){
      if(!basis)return appShell({title:'Duyệt thay đổi tình trạng',body:vBanner('warning','Không còn căn cứ hiện hành','Mở lại công việc từ danh sách được giao để lấy đúng phiên bản yêu cầu.'),back:false});
      const body=`${vBanner('info','Phê duyệt không ghi tồn','Quyết định chỉ áp dụng cho đúng yêu cầu này. Hệ thống sẽ kiểm tra lại trước khi thực thi.')}${approvalRows(basis)}${rejectSheet()}`;
      return appShell({title:'Duyệt thay đổi tình trạng',body,actions:`<div class="ic-action-stack">${icSecondary('Từ chối','data-v3101-action="reject-open"','danger')}${primaryFooter('Duyệt','data-v3101-action="approve"')}</div>`,back:false});
    }
    const t=transition();
    const error=state==='VALIDATION_ERROR'?vBanner('error','Chưa đủ thông tin','Kiểm tra tình trạng đích, số lượng và thông tin bắt buộc theo quy tắc hiện hành.'):'';
    const policyNote=t?`<small class="helper-text">${t.approval?'Yêu cầu này sẽ được gửi người duyệt độc lập.':'Quy tắc hiện hành cho phép hệ thống xử lý sau khi gửi.'}</small>`:'';
    const evidence=t?.evidence?icTextarea('Bằng chứng',draft.evidence,'data-v3101-evidence','Nhập hoặc tham chiếu bằng chứng'):'';
    const body=`${error}${icHeaderRows([['Sản phẩm',x.name,true],['Lô',x.lot],['Từ',stateLabel(x.state)],['Tồn vật lý',`${x.qty} ${x.uom}`]])}${ioSectionTitle('Tình trạng mới')}<div class="choice-list">${destinationChoices()}</div>${policyNote}${icField('Số lượng chuyển',draft.quantity,'data-v3101-qty','number',`Tối đa ${x.qty} ${x.uom}. Hệ thống tự xác định đúng phần tồn được chuyển.`)}${icTextarea('Lý do',draft.reason,'data-v3101-reason','Nhập lý do')}${evidence}`;
    return appShell({title:'Chuyển tình trạng hàng',body,actions:primaryFooter('Gửi xử lý','data-v3101-action="submit"')});
  };
  renderers['SCR-041']=function(state){
    if(activeFlowId!=='UIF-09')return base041(state);
    const x=current();
    if(state==='PROCESSING')return appShell({title:'Kết quả thay đổi',body:`${vBanner('info','Đang kiểm tra và ghi nhận','Hệ thống đang kiểm tra lại đúng căn cứ đã gửi trước khi cập nhật tồn.')}${basis?approvalRows(basis):''}`,centered:false,back:false});
    if(state==='UNKNOWN')return appShell({title:'Kết quả thay đổi',body:ioResult('Đang xác minh kết quả','Không gửi yêu cầu mới. Hệ thống đang kiểm tra cùng lần xử lý này.',[['Sản phẩm',basis?.product||x.name],['Tình trạng','Chưa kết luận']],'warning'),actions:primaryFooter('Chuyển sang xác minh','data-v350-action="handoff-unknown" data-source-flow="UIF-09"'),centered:true,back:false});
    if(state==='STATE_CHANGE_BASIS_STALE'||state==='REJECTED_EXECUTION')return appShell({title:'Kết quả thay đổi',body:ioResult('Yêu cầu chưa được thực hiện','Tình trạng và tồn kho không thay đổi. Nếu căn cứ đã thay đổi, cần lập yêu cầu mới.',[['Sản phẩm',basis?.product||x.name],['Tác động tồn kho','Không có']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='EXPIRED')return appShell({title:'Tình trạng hàng',body:ioResult('Lô đã hết hạn',`Theo ngày nghiệp vụ ${BUSINESS_DATE}, hệ thống đã loại lượng hàng này khỏi khả dụng bán.`,[['Tồn vật lý',`${x.qty} ${x.uom}`],['Khả dụng bán',`0 ${x.uom}`],['Tác động giá trị','Không đổi']],'warning'),actions:primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"'),centered:true,back:false});
    if(state==='COMPLETED'&&movement){
      const r=movement.reservationImpact;const rows=[['Sản phẩm',movement.product],['Đã chuyển',`${movement.quantity} ${movement.uom} · ${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Còn ở trạng thái nguồn',`${movement.remainingSource} ${movement.uom}`],['Tồn vật lý','Không đổi'],['Giá trị ghi sổ','Không đổi']];
      if(r.shortfall>0)rows.push(['Cần phân bổ lại',`${r.shortfall} ${movement.uom}`]);
      return appShell({title:'Kết quả thay đổi',body:ioResult('Đã cập nhật tình trạng','Hệ thống đã ghi chuyển trạng thái trên đúng phạm vi và kiểm tra lại khả dụng.',rows),actions:`<div class="ic-action-stack">${movement.id?icSecondary('Xem biến động','data-ic09-action="history"'):''}${primaryFooter('Về tình trạng hàng','data-ic09-action="to-list"')}</div>`,centered:true,back:false});
    }
    return base041(state);
  };
  renderers['SCR-056']=function(state){
    if(activeFlowId!=='UIF-09')return base056(state);
    if(!movement)return base056(state);
    const body=`${icHeaderRows([['Sản phẩm',movement.product,true],['Lô',movement.lot],['Biến động',`${stateLabel(movement.from)} → ${stateLabel(movement.to)}`],['Số lượng',`${movement.quantity} ${movement.uom}`],['Ghi nhận lúc',movement.recordedAt]])}<p class="io-footnote">Việc đổi tình trạng không làm thay đổi giá trị ghi sổ của lượng hàng này.</p>`;
    return appShell({title:'Chi tiết biến động',body});
  };

  function systemCommit(){
    if(!basis)return false;
    stateByScreen['SCR-041']='PROCESSING';
    if(staleOnExecute){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const x=ic09Items.find(z=>z.id===basis.itemId);
    if(!x||x.state!==basis.from||x.qty<basis.quantity||POLICY.versionId!==basis.policyVersionId){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const slices=resolveSlices(x,basis.quantity);
    const currentHash=fixtureHash({...basis,basisHash:undefined,sourceSlices:slices});
    // Basis hash is frozen in this harness; runtime rechecks semantic facts rather than reproducing canonical production serialization.
    if(!slices){stateByScreen['SCR-041']='STATE_CHANGE_BASIS_STALE';renderAppScreen();return false;}
    const originalQty=x.qty;
    if(basis.quantity===x.qty){x.state=basis.to;x.label=stateLabel(basis.to);}
    else{
      x.qty=Number((x.qty-basis.quantity).toFixed(6));
      const splitId=`${x.id}-state-${Date.now()}`;
      ic09Items.push({id:splitId,name:x.name,code:x.code,lot:x.lot,qty:basis.quantity,uom:x.uom,state:basis.to,label:stateLabel(basis.to),expiry:x.expiry});
      SOURCE[splitId]={slices:basis.sourceSlices.map(z=>({balanceId:`${z.balanceId}-to`,version:1,valuationState:z.valuationState,qty:z.quantity})),reservationBefore:0};
    }
    const src=SOURCE[basis.itemId];
    // Reduce source fixture slices in the same deterministic slice order; preserve valuation state.
    let rem=basis.quantity; for(const sl of src.slices){if(rem<=0)break;const take=Math.min(rem,sl.qty);sl.qty-=take;rem-=take;}
    src.reservationBefore=basis.reservationImpact.after;
    movement={id:`MOV-STATE-${String(seq++).padStart(3,'0')}`,product:basis.product,lot:basis.lot,from:basis.from,to:basis.to,quantity:basis.quantity,uom:basis.uom,remainingSource:originalQty-basis.quantity,sourceSlices:basis.sourceSlices.map(z=>({...z,valuationStateSnapshot:z.valuationState})),valuationPreserved:true,valueMovementCreated:false,reservationImpact:basis.reservationImpact,recordedAt:'17/09/2026 · 15:04'};
    stateByScreen['SCR-041']='COMPLETED';renderAppScreen();return true;
  }
  function queueSystemCommit(){setTimeout(()=>{if(activeFlowId==='UIF-09'&&activeScreenId==='SCR-041'&&stateByScreen['SCR-041']==='PROCESSING')systemCommit();},180);}

  document.addEventListener('input',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-qty]')){draft.quantity=e.target.value;}
    if(e.target.matches('[data-v3101-reason]')){draft.reason=e.target.value;}
    if(e.target.matches('[data-v3101-evidence]')){draft.evidence=e.target.value;}
    if(e.target.matches('[data-v3101-reject-reason]')){rejectReason=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('change',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.matches('[data-v3101-destination]')){draft.destination=e.target.value;renderAppScreen();}
  },true);
  document.addEventListener('click',function(e){
    if(activeFlowId!=='UIF-09')return;
    if(e.target.closest('[data-ic09-item]')||e.target.closest('[data-ic09-action="change"]')){queueMicrotask(resetDraft);}
    const a=e.target.closest('[data-v3101-action]');if(!a||a.disabled)return;
    e.preventDefault();e.stopImmediatePropagation();const k=a.dataset.v3101Action;
    if(k==='submit'){
      if(!basisValid()){stateByScreen['SCR-038']='VALIDATION_ERROR';return renderAppScreen();}
      basis=buildBasis();decision=null;const t=transition();
      if(t?.approval){stateByScreen['SCR-038']='PENDING_APPROVAL';return renderAppScreen();}
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='approve'){
      if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}
      if(!basis){stateByScreen['SCR-038']='STATE_CHANGE_BASIS_STALE';return renderAppScreen();}
      decision={decision:'APPROVE',basisHash:basis.basisHash,actor:'approver',decidedAt:'17/09/2026 15:04'};
      stateByScreen['SCR-041']='PROCESSING';navigate('SCR-041');queueSystemCommit();return;
    }
    if(k==='reject-open'){if(actor()!=='approver'){stateByScreen['SCR-038']='SELF_APPROVAL_NOT_ALLOWED';return renderAppScreen();}rejectReason='';rejectOpen=true;return renderAppScreen();}
    if(k==='reject-close'){rejectOpen=false;rejectReason='';return renderAppScreen();}
    if(k==='reject-confirm'){
      if(actor()!=='approver'||!rejectReason.trim())return;
      decision={decision:'REJECT',basisHash:basis?.basisHash||null,reason:rejectReason.trim(),actor:'approver',decidedAt:'17/09/2026 15:04'};rejectOpen=false;
      stateByScreen['SCR-041']='REJECTED_EXECUTION';navigate('SCR-041');return;
    }
    if(k==='rebuild'){resetDraft();stateByScreen['SCR-038']='READY';return renderAppScreen();}
  },true);

  window.__VET45_V3101__={
    version:VERSION,decisions:[178,179,180,181,182,183,184],policy:POLICY,
    getDraft:()=>({...draft}),getBasis:()=>basis,getDecision:()=>decision,getMovement:()=>movement,
    getSource:(id)=>JSON.parse(JSON.stringify(SOURCE[id||current().id]||null)),
    setDraft(v={}){draft={...draft,...v};return {...draft};},
    setStaleOnExecute(v=true){staleOnExecute=Boolean(v);return staleOnExecute;},
    buildBasis(){basis=buildBasis();return basis;},systemCommit,
    fixtureHashNote:'Deterministic harness fixture hash only; production contract requires canonical SHA-256.'
  };
  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version=VERSION;
  renderAppScreen();
})();

/* ===== v313-valuation-design.js ===== */
/* VET45 Theme 7 v3.13.0 — Inventory valuation design parity
 * Parent: v3.12.0 specification baseline / v3.10.1 prototype carry-forward
 * Scope: UIF-03, UIF-13, UIF-14 only. Rebinds renderers last; no cross-flow mutation.
 */
(()=>{
  if(typeof renderers==='undefined') return;
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const qty=(g)=>g.slices.filter(s=>s.pendingQty>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=(r)=>r.groups.filter(g=>qty(g)>0);
  const entryType=(r)=>r.v313EntryType||'DOCUMENT';
  const entryLabel=(r)=>entryType(r)==='QUICK'?'Nhập nhanh':'Theo chứng từ';
  const stable=(value)=>{let h=2166136261>>>0;for(const c of String(value)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)>>>0;}return `fixture-v313-${h.toString(16)}`;};
  const info=(title,rows)=>ds24InfoGroup(title,rows,'valuation-info-group v313-info-group');
  const key=(label,value,em=false)=>ds24KeyValueRow(label,value,em);
  const row=(args)=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(title,meta='')=>`<div class="v313-section-heading"><h2>${esc(title)}</h2>${meta?`<span>${esc(meta)}</span>`:''}</div>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v313-text-action" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const field=(label,control,helper='')=>`<label class="v313-field" data-ds-component="VTextField"><span class="v313-field__label">${esc(label)}</span>${control}${helper?`<small>${esc(helper)}</small>`:''}</label>`;
  const select=(attrs,options)=>`<select ${attrs} class="v313-control" data-ds-component="VSelect">${options}</select>`;
  const input=(attrs,value='',type='text',placeholder='')=>`<input ${attrs} class="v313-control" type="${type}" value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}"/>`;
  const summary=(title,body,tone='Neutral')=>`<section class="v313-summary v313-summary--${String(tone).toLowerCase()}" data-ds-component="DS v2 / Summary Card" data-figma-node="525:552" data-ds-prop-tone="${tone}"><h2>${esc(title)}</h2><p>${esc(body)}</p></section>`;
  const readiness=(title,body,tone='Warning')=>`<div class="v313-readiness v313-readiness--${String(tone).toLowerCase()}" data-ds-component="DS v2 / Readiness Item" data-figma-node="526:4442"><span class="v313-readiness__icon">${icon(tone==='Success'?'checkCircle':'alert','icon--sm')}</span><span><strong>${esc(title)}</strong><small>${esc(body)}</small></span></div>`;
  const sheet=(title,content,actions='')=>`<div class="v313-sheet-layer" data-v313-sheet-backdrop><div class="v313-sheet-backdrop"></div><section class="v313-sheet" data-ds-component="VBottomSheet" data-figma-node="4695:6353"><div class="v313-sheet__handle"></div><h2>${esc(title)}</h2><div class="v313-sheet__content">${content}</div>${actions?`<div class="v313-sheet__actions">${actions}</div>`:''}</section></div>`;
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" ${disabled?'disabled':''}>${esc(label)}</button>`;

  // ---------------------------------------------------------------------------
  // BJ03 — Xác lập giá trị nhập ban đầu
  // ---------------------------------------------------------------------------
  if(typeof val03Receipts!=='undefined'){
    const types={"VAL03-R1":"DOCUMENT","VAL03-R2":"QUICK","VAL03-R3":"QUICK","VAL03-R4":"DOCUMENT"};
    val03Receipts.forEach(r=>{r.v313EntryType=types[r.id]||'DOCUMENT';});
  }
  let v313Val03Filter='ALL';
  let v313Val03Sheet=null;
  function v313Val03GroupState(r,g){
    const st=val03EvidenceState(g);
    if(st==='READY') return 'READY';
    if(st==='CONFLICT') return entryType(r)==='DOCUMENT'?'COMMERCIAL_CONFLICT':'DIRECT_CONFLICT';
    return entryType(r)==='QUICK'?'DIRECT_MISSING':'COMMERCIAL_MISSING';
  }
  function v313Val03ReceiptState(r){
    const states=pendingGroups(r).map(g=>v313Val03GroupState(r,g));
    if(states.some(x=>x==='COMMERCIAL_CONFLICT'||x==='DIRECT_CONFLICT')) return 'CONFLICT';
    if(states.length && states.every(x=>x.includes('MISSING'))) return 'MISSING';
    return 'READY';
  }
  function v313Val03SelectedGroups(r=val03Current()){return pendingGroups(r).filter(g=>g.slices.some(s=>s.selected&&s.pendingQty>0));}
  function v313Val03SelectGroup(g,on){g.slices.filter(s=>s.pendingQty>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});}
  function v313Val03ClearSelection(r=val03Current()){r.groups.forEach(g=>v313Val03SelectGroup(g,false));}
  function v313Val03Breakdown(g){
    const source=val03Source(g); if(!source) return '';
    const unit=source.unitPrice*source.fxRate;
    const actual=unit-(source.unitLineDiscount||0)-(source.unitDocDiscount||0)+(source.unitKnownCost||0)+(source.unitNonDeductibleVat||0);
    return `<div class="v313-kv">${key(source.currency==='VND'?'Giá mua':'Giá mua quy đổi',`${money(unit)}/${g.uom}`)}${source.unitLineDiscount?key('Chiết khấu dòng',`− ${money(source.unitLineDiscount)}/${g.uom}`):''}${source.unitDocDiscount?key('Chiết khấu chứng từ',`− ${money(source.unitDocDiscount)}/${g.uom}`):''}${source.unitKnownCost?key('Chi phí mua đã biết',`+ ${money(source.unitKnownCost)}/${g.uom}`):''}${source.unitNonDeductibleVat?key('Thuế tính vào giá trị',`+ ${money(source.unitNonDeductibleVat)}/${g.uom}`):''}${key('Đơn giá ghi nhận ban đầu',`${money(actual)}/${g.uom}`,true)}</div>`;
  }
  function v313Val03BasisLabel(g){const s=val03Source(g);return s?s.label:'Chưa có căn cứ';}
  function v313Val03DirectSheet(r,g){
    const content=`${vBanner('info','Căn cứ cho nhập nhanh','Giá này chỉ dùng để xác lập giá trị ban đầu của lượng hàng đã nhận. Nếu chứng từ mua xuất hiện sau, chênh lệch được ghi bằng điều chỉnh giá trị.','','Compact')}
      ${field('Đơn giá mua',input('data-v313-basis-price','', 'number','0'),'Nhập theo đơn vị '+g.uom)}
      <div class="v313-field"><span class="v313-field__label">Cách hiểu giá</span><div class="v313-segment" data-ds-component="VSegmentedControl" data-figma-node="1049:9619"><button type="button" class="is-selected" data-v313-tax-mode="INCLUDED">Đã gồm thuế</button><button type="button" data-v313-tax-mode="EXCLUDED">Chưa gồm thuế</button></div></div>
      <div data-v313-tax-amount-wrap hidden>${field('Thuế trên giá mua',input('data-v313-basis-tax','0','number','0'),'Theo chính sách hộ kinh doanh hiện tại, phần thuế này được tính vào giá trị hàng nhập.')}</div>
      ${field('Nguồn căn cứ',input('data-v313-basis-source','','text','Ví dụ: Xác nhận giá từ nhà cung cấp'))}
      ${field('Ngày căn cứ',input('data-v313-basis-date','24/09/2026','text','dd/mm/yyyy'))}
      ${field('Tham chiếu / bằng chứng',input('data-v313-basis-ref','','text','Mã báo giá, email, ghi chú...'))}
      ${field('Lý do xác lập trực tiếp',input('data-v313-basis-reason','','text','Nêu ngắn gọn lý do'),'Bắt buộc khi chưa có chứng từ mua có cấu trúc.')}`;
    const actions=`${button('Hủy','data-v313-val03-sheet="close"','secondary')}${button('Lưu căn cứ','data-v313-val03-sheet="save"')}`;
    return sheet(`Thêm căn cứ giá · ${g.name}`,content,actions);
  }
  function v313Val03Group(r,g){
    const st=v313Val03GroupState(r,g),pending=qty(g),selected=v313Val03SelectedGroups(r).includes(g);
    const subtitle=`${pending} ${g.uom} đang chờ giá trị${g.tracking==='LOT'?` · ${g.slices.filter(s=>s.pendingQty>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g); const calc=v313Val03Breakdown(g);
      return `<section class="v313-work-section ${selected?'is-selected':''}" data-v313-group="${g.id}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v313-val03-select="${g.id}"`})}<div class="v313-section-body">${info('Căn cứ giá',ds24InfoRow('Nguồn',s?.label||'—')+(s?.currency!=='VND'?ds24InfoRow('Tỷ giá',s?.fxLabel||'—'):''))}${calc}</div></section>`;
    }
    if(st==='COMMERCIAL_CONFLICT') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần đối chiếu','Warning'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Giá trên các căn cứ thương mại chưa thống nhất. Hãy đối chiếu chứng từ mua trước khi xác lập giá trị cho dòng này.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần căn cứ','Warning'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body">${vBanner('warning','Chưa đủ căn cứ mua hàng','Dòng nhận theo chứng từ chưa có căn cứ giá đủ điều kiện. Khi căn cứ được bổ sung, công việc sẽ tự cập nhật.')}</div></section>`;
    if(st==='DIRECT_MISSING') return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Chưa có căn cứ','Neutral'),leading:null,type:'Status',interactive:false})}<div class="v313-section-body"><p class="v313-helper">Nhập nhanh không cần chờ Theme Mua. Kế toán có thể lập căn cứ giá trực tiếp có dấu vết.</p>${button('Thêm căn cứ giá',`data-v313-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    return `<section class="v313-work-section">${row({title:g.name,subtitle,trailing:ds24Badge('Cần kiểm tra','Warning'),leading:null,type:'Status',interactive:false})}</section>`;
  }
  function v313Val03CanReview(r=val03Current()){
    const sel=v313Val03SelectedGroups(r);return sel.length>0&&sel.every(g=>v313Val03GroupState(r,g)==='READY');
  }
  function v313Val03SaveBasis(groupId){
    const r=val03Current(),g=r.groups.find(x=>x.id===groupId); if(!g) return false;
    const root=document.querySelector('.v313-sheet');
    const price=Number(root?.querySelector('[data-v313-basis-price]')?.value||0);
    const sourceLabel=String(root?.querySelector('[data-v313-basis-source]')?.value||'').trim();
    const date=String(root?.querySelector('[data-v313-basis-date]')?.value||'').trim();
    const ref=String(root?.querySelector('[data-v313-basis-ref]')?.value||'').trim();
    const reason=String(root?.querySelector('[data-v313-basis-reason]')?.value||'').trim();
    const taxMode=root?.querySelector('[data-v313-tax-mode].is-selected')?.dataset.v313TaxMode||'INCLUDED';
    const tax=taxMode==='EXCLUDED'?Number(root?.querySelector('[data-v313-basis-tax]')?.value||0):0;
    if(price<=0||!sourceLabel||!reason){root?.classList.add('has-validation-error');return false;}
    const id=`DIRECT-${g.id}-${Date.now()}`;
    const components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:sourceLabel,version:date||'Hiện hành',amount:price}];
    if(tax)components.push({type:'NON_RECOVERABLE_TAX',label:'Thuế tính vào giá trị',source:sourceLabel,version:date||'Hiện hành',amount:tax});
    g.sources=[{id,label:`${sourceLabel}${date?` · ${date}`:''}`,version:'v1',basisVersion:1,basisHash:stable(`${id}|${price}|${tax}|${date}`),authoritativeValueHash:stable(`${price+tax}`),unitPrice:price,currency:'VND',fxRate:1,fxLabel:'VND',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:tax,components,evidenceRefs:[ref||reason],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:reason,taxMode,sourceDate:date,reference:ref}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;v313Val03SelectGroup(g,true);return true;
  }
  function v313Val03Commit(){
    const r=val03Current(),groups=[];let totalValue=0,totalQty=0;
    for(const g of v313Val03SelectedGroups(r)){
      const c=val03Calc(g);if(!c)continue;
      const lines=[];let groupQty=0,groupValue=0;
      for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){
        const q=Number(s.pendingQty||0),amount=Math.round(Number(c.unitActual||0)*q);groupQty+=q;groupValue+=amount;
        lines.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount});
      }
      groups.push({name:g.name,code:g.code,uom:g.uom,qty:groupQty,value:groupValue,unitInitial:c.unitActual,source:val03SourceDetail(g),slices:lines});
      totalQty+=groupQty;totalValue+=groupValue;
    }
    val03LastResult={operationId:`VAL-260925-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,groups,totalValue,totalQty,dirtyScope:groups.map(g=>`${g.name} · kỳ ${r.receivedAt.slice(3)}`)};
    for(const g of v313Val03SelectedGroups(r)) for(const s of g.slices.filter(x=>x.selected&&x.pendingQty>0)){const q=s.pendingQty,amount=Math.round((val03Calc(g)?.unitActual||0)*q);s.pendingQty=0;s.confirmedQty=Number(s.confirmedQty||0)+q;s.confirmedValue=Number(s.confirmedValue||0)+amount;s.scopeVersion=Number(s.scopeVersion||0)+1;s.selected=false;s.selectedQty=0;}
    val03ReviewSourceVersion=null;return val03LastResult;
  }
  val03Commit=v313Val03Commit;

  function render014V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-014'),state);
    if(state==='LOADING')return appShell({title:'Hàng chờ xác lập giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ xác lập giá trị',body:deniedBody(),centered:true,back:false});
    const q=String(val03Query||'').toLocaleLowerCase('vi');
    const rows=val03Receipts.filter(r=>pendingGroups(r).length).filter(r=>!q||`${r.receipt} ${r.supplier}`.toLocaleLowerCase('vi').includes(q)).filter(r=>{
      const st=v313Val03ReceiptState(r);return v313Val03Filter==='ALL'||(v313Val03Filter==='READY'&&st==='READY')||(v313Val03Filter==='ISSUE'&&st!=='READY');
    }).map(r=>{
      const st=v313Val03ReceiptState(r),count=pendingGroups(r).length;
      const trailing=st==='CONFLICT'?ds24Badge('Cần đối chiếu','Warning'):st==='MISSING'?ds24Badge('Cần căn cứ','Neutral'):'';
      return row({title:r.receipt,subtitle:`${r.supplier} · ${entryLabel(r)} · ${count} dòng chờ`,trailing,leading:null,attrs:`data-v313-val03-receipt="${r.id}"`,type:'Navigation'});
    }).join('');
    const body=`${ds24Search(val03Query,'data-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',v313Val03Filter==='ALL','data-v313-val03-filter')}${ds24Chip('READY','Có thể xác lập',v313Val03Filter==='READY','data-v313-val03-filter')}${ds24Chip('ISSUE','Cần xử lý',v313Val03Filter==='ISSUE','data-v313-val03-filter')}</div>${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Hàng chờ xác lập giá trị',body,back:false});
  }
  function render015V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();
    if(state==='LOADING')return appShell({title:'Xác lập giá trị nhập ban đầu',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const context=info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier)+ds24InfoRow('Ngày nhận',r.receivedAt)+ds24InfoRow('Hình thức',entryLabel(r)));
    const work=pendingGroups(r).map(g=>v313Val03Group(r,g)).join('');
    const selected=v313Val03SelectedGroups(r);const total=selected.reduce((n,g)=>n+(val03Calc(g)?.value||0),0);
    const selection=selected.length?summary('Sẽ xác lập',`${selected.length} dòng hàng · ${money(total)}`,'Brand'):'';
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Căn cứ đã thay đổi','Kiểm tra lại giá và cấu thành trước khi tiếp tục.'):''}${context}${heading('Hàng chờ giá trị')}${work}${selection}${v313Val03Sheet?v313Val03DirectSheet(r,r.groups.find(g=>g.id===v313Val03Sheet)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát', 'data-v313-val03-review',!v313Val03CanReview(r))});
  }
  function render016V313(){return render015V313('READY');}
  function render017V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);
    if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Kết quả rà soát cũ không còn hiệu lực. Quay lại kiểm tra căn cứ hiện hành.')}${info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier))}`,actions:primaryFooter('Kiểm tra lại','data-v313-val03-back')});
    const sections=v313Val03SelectedGroups(r).map(g=>{const c=val03Calc(g);return `<section class="v313-review-section">${heading(g.name,`${c?.qty||0} ${g.uom}`)}${info('Căn cứ',ds24InfoRow('Nguồn',val03SourceDetail(g)))}${v313Val03Breakdown(g)}${key('Giá trị sẽ ghi',money(c?.value||0),true)}</section>`;}).join('');
    const total=v313Val03SelectedGroups(r).reduce((n,g)=>n+(val03Calc(g)?.value||0),0);
    const body=`${info('Phiếu nhận',ds24InfoRow('Phiếu',r.receipt)+ds24InfoRow('Nhà cung cấp',r.supplier)+ds24InfoRow('Ngày nhận',r.receivedAt))}${sections}${summary('Tổng giá trị nhập ban đầu',money(total),'Brand')}${linkButton('Chỉnh sửa căn cứ','data-v313-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v313-val03-confirm')});
  }
  function render019V313(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0,totalQty:0,dirtyScope:[]};
    if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v313-val03-result-back')});
    const remaining=pendingGroups(val03Current()).length;
    const rows=(res.groups||[]).map(g=>key(g.name,`${g.qty} ${g.uom} · ${money(g.value)}`)).join('');
    const body=`<div class="io-result">${resultHero('Đã xác lập giá trị nhập ban đầu','Giá trị đã được ghi cho lượng hàng đã rà soát. Giá vốn sẽ được cập nhật ở công việc giá vốn.')}${info('Kết quả',ds24InfoRow('Phiếu nhận',res.receipt)+ds24InfoRow('Số dòng đã xác lập',String(res.groups?.length||0))+ds24InfoRow('Số lượng',String(res.totalQty||0))+key('Tổng giá trị đã ghi',money(res.totalValue),true)+ds24InfoRow('Giá vốn','Cần cập nhật'))}${res.groups?.length?`<div class="v313-kv">${rows}</div>`:''}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} dòng của phiếu này chưa đủ điều kiện hoặc chưa được chọn trong lần xử lý.`,'','Compact'):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v313-val03-result-back':'data-v313-val03-result-list')});
  }

  // ---------------------------------------------------------------------------
  // BJ13 — Điều chỉnh giá trị hàng nhập
  // ---------------------------------------------------------------------------
  let v313Val13Filter='ALL';
  function v313Val13ImpactLabel(t){const n=Number(t.normalizedAmount||0);return n<0?'Giảm giá trị':n>0?'Tăng giá trị':'Không đổi';}
  function v313Val13Source(t){return info('Nguồn điều chỉnh',ds24InfoRow('Nguồn',t.sourceRef)+ds24InfoRow('Loại',t.component)+ds24InfoRow('Đối tác',t.supplier)+(t.currency!=='VND'?ds24InfoRow('Giá trị nguồn',val13FmtSourceAmount(t))+ds24InfoRow('Tỷ giá',t.fxLabel):'')+key('Giá trị điều chỉnh',signed(t.normalizedAmount),true));}
  function v313Val13Targets(t){
    return (t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:t.targetScopeMode==='FIXED'?ds24Badge('Theo nguồn','Neutral'):(x.selected?icon('checkCircle','icon--sm'):''),leading:null,type:t.targetScopeMode==='FIXED'?'Status':'Selection',interactive:t.targetScopeMode!=='FIXED',state:x.selected?'Selected':'Default',attrs:t.targetScopeMode==='FIXED'?'':`data-val13-target="${x.id}"`})).join('');
  }
  function v313Val13Method(t){const opts=`<option value="">Chọn cách phân bổ</option>`+(t.allowedMethods||[]).map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');return field('Cách phân bổ',select('data-val13-method',opts));}
  function v313Val13Preview(t){
    const p=val13Preview(t);if(!p.length)return vBanner('info','Chưa có preview','Chọn phạm vi và cách phân bổ hợp lệ để xem kết quả trước khi rà soát.','','Compact');
    const rows=p.map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    return `<section class="v313-preview">${heading('Kết quả phân bổ',`${p.length} dòng`)}<div class="v313-kv">${rows}${key('Tổng phân bổ',signed(p.reduce((n,x)=>n+x.allocatedAmount,0)),true)}</div></section>`;
  }
  function render085V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);
    if(state==='LOADING')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:deniedBody(),centered:true,back:false});
    const q=String(val13Query||'').toLocaleLowerCase('vi');const tasks=val13Tasks.filter(t=>t.status!=='COMPLETED').filter(t=>!q||`${t.sourceRef} ${t.supplier} ${t.component}`.toLocaleLowerCase('vi').includes(q)).filter(t=>v313Val13Filter==='ALL'||(v313Val13Filter==='ACTIONABLE'&&t.status==='ACTIONABLE')||(v313Val13Filter==='WAITING'&&t.status==='WAITING'));
    const rows=tasks.map(t=>{const wait=t.status==='WAITING';return row({title:t.sourceRef.replace(/ · dòng \d+$/,''),subtitle:`${t.component} · ${t.supplier}${t.normalizedAmount!=null?` · ${signed(t.normalizedAmount)}`:''}`,trailing:wait?ds24Badge('Đang chờ','Neutral'):'',leading:null,type:'Navigation',attrs:`data-v313-val13-task="${t.id}"`});}).join('');
    const body=`${ds24Search(val13Query,'data-val13-search','Nguồn điều chỉnh hoặc đối tác')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',v313Val13Filter==='ALL','data-v313-val13-filter')}${ds24Chip('ACTIONABLE','Có thể xử lý',v313Val13Filter==='ACTIONABLE','data-v313-val13-filter')}${ds24Chip('WAITING','Đang chờ',v313Val13Filter==='WAITING','data-v313-val13-filter')}</div>${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;
    return appShell({title:'Điều chỉnh giá trị hàng nhập',body,back:false});
  }
  function render086V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();
    if(state==='LOADING')return appShell({title:'Nguồn, phạm vi và phân bổ',body:loadingBody(),centered:true});
    if(state==='PERMISSION_DENIED')return appShell({title:'Nguồn, phạm vi và phân bổ',body:deniedBody(),centered:true});
    if(t.status==='WAITING')return appShell({title:'Nguồn, phạm vi và phân bổ',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ căn cứ cần thiết.')}${v313Val13Source(t)}${(t.targets||[]).length?`${heading('Phạm vi liên quan')}${v313Val13Targets(t)}`:''}`});
    const changed=state==='SOURCE_CHANGED'||Boolean(val13LastSourceChange);
    const body=`${changed?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Preview cũ không còn hiệu lực. Kiểm tra lại phạm vi và cách phân bổ.'):''}${v313Val13Source(t)}${heading('Phạm vi áp dụng',t.targetScopeMode==='FIXED'?'Theo nguồn xác định':'Chọn trong phạm vi cho phép')}<section class="ds24-list-stack v313-list">${v313Val13Targets(t)}</section>${v313Val13Method(t)}${v313Val13Preview(t)}${info('Kỳ ghi nhận',ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')+ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—')+(t.periodReason?ds24InfoRow('Lý do',t.periodReason):''))}`;
    return appShell({title:'Nguồn, phạm vi và phân bổ',body,actions:primaryFooter('Rà soát điều chỉnh','data-v313-val13-review',!val13CanPreview(t))});
  }
  function render087V313(state){return render086V313(state);}
  function render088V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-088'),state);const t=val13Current();
    if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát điều chỉnh giá trị',body:deniedBody(),centered:true});
    const stale=state==='SOURCE_CHANGED'||val13PreviewHash==null||val13PreviewHash!==val13PreviewHashOf(t)||Number(val13ReviewSourceVersion)!==Number(t.sourceVersion);
    if(stale)return appShell({title:'Rà soát điều chỉnh giá trị',body:`${vBanner('warning','Nguồn hoặc phân bổ đã thay đổi','Tạo lại preview trước khi ghi điều chỉnh.')}${v313Val13Source(t)}`,actions:primaryFooter('Tạo lại preview','data-v313-val13-back')});
    const p=val13Preview(t),rows=p.map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    const body=`${v313Val13Source(t)}${info('Cách phân bổ',ds24InfoRow('Phương pháp',(t.allowedMethods||[]).find(m=>m.id===t.selectedMethod)?.label||'—')+ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')+ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—'))}${heading('Phân bổ sẽ ghi')}<div class="v313-kv">${rows}${key('Tổng điều chỉnh',signed(t.normalizedAmount),true)}</div>${vBanner('info','Sau khi ghi','Số lượng tồn không đổi. Các sản phẩm liên quan sẽ được đánh dấu cần cập nhật giá vốn.','','Compact')}${linkButton('Chỉnh sửa phân bổ','data-v313-val13-back')}`;
    return appShell({title:'Rà soát điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v313-val13-confirm')});
  }
  function render089V313(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const res=val13Result();
    if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||'ADJ-UNKNOWN')}" data-scope="${escapeAttribute(res.sourceRef||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không gửi lại lệnh. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Nguồn',res.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh giá trị','Không có thay đổi. Kiểm tra lại nguồn và phân bổ hiện hành.',[['Nguồn',res.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v313-val13-back')});
    const rows=(res.allocations||[]).map(x=>key(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('');
    const body=`<div class="io-result">${resultHero(Number(res.normalizedAmount||0)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập','Điều chỉnh đã được ghi theo phạm vi và kỳ đã rà soát.')}${info('Kết quả',ds24InfoRow('Nguồn',res.sourceRef)+key('Tổng điều chỉnh',signed(res.normalizedAmount),true)+ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||'—')+ds24InfoRow('Giá vốn','Cần cập nhật'))}${rows?`<div class="v313-kv">${rows}</div>`:''}</div>`;
    return appShell({title:'Kết quả điều chỉnh giá trị',body,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v313-val13-list')});
  }

  // ---------------------------------------------------------------------------
  // BJ14 — Tính, rà soát và công bố giá vốn
  // ---------------------------------------------------------------------------
  let v313Val14Mode='RESULT';
  let v313Val14PublishSheet=false;
  let v313Val14CompareOpen=false;
  function v313EnrichRun(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod='PERIODIC';r.policyLabel='Bình quân cuối kỳ';r.policyVersion='Chính sách giá vốn';return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(v313EnrichRun);
  function v313RunScope(r){return r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;}
  function v313Val14WorkMeta(r){
    v313EnrichRun(r);
    if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};
    if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};
    if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};
    return {title:r.label,subtitle:v313RunScope(r),label:'Đang xử lý',tone:'Neutral'};
  }
  function v313Policy(r){return info('Chính sách giá vốn',ds24InfoRow('Phương pháp áp dụng','Bình quân cuối kỳ')+ds24InfoRow('Cấp cấu hình','Tổ chức')+ds24InfoRow('Trạng thái','Áp dụng tự động'));}
  function v313Blockers(r){return (r.blockers||[]).map(b=>readiness(b.title,`Đang chờ: ${b.owner}`,'Warning')).join('');}
  function v313PrimaryResult(r){v313EnrichRun(r);const x=r.periodic||{};return `${summary('Kết quả theo phương pháp áp dụng',`Bình quân cuối kỳ · ${v313RunScope(r)}`,'Brand')}<div class="v313-kv">${key('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${key('Giá vốn xuất',val14Money(x.cogs||0),true)}${key('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0))}${key('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0))}</div>`;}
  function v313Compare(r){const x=r.moving||{};return `<details class="v313-details" ${v313Val14CompareOpen?'open':''} data-v313-compare><summary>Xem đối chiếu</summary><div class="v313-details__body">${info('Bình quân liên hoàn · chỉ đối chiếu',key('Giá trị tồn cuối',val14Money(x.inventory||0))+key('Giá vốn xuất',val14Money(x.cogs||0)))}</div></details>`;}
  function v313PeriodSetup(r){
    const isDirty=v313Val14Mode==='DIRTY_SETUP';
    const period=isDirty?(r?.period||val14SetupPeriod):val14SetupPeriod;
    const scope=isDirty?v313RunScope(r):val14SetupScope;
    const controls=isDirty?info('Phạm vi cần cập nhật',ds24InfoRow('Kỳ ghi nhận',period)+ds24InfoRow('Phạm vi',scope)+ds24InfoRow('Nguồn phạm vi','Hệ thống xác định từ thay đổi giá trị')):`${field('Kỳ',select('data-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`))}${field('Phạm vi',select('data-val14-scope',`<option ${val14SetupScope==='Toàn bộ sản phẩm'?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==='Sản phẩm cần tính lại'?'selected':''}>Sản phẩm cần tính lại</option>`))}`;
    return `${controls}${v313Policy(r||{})}`;
  }
  function v313PublishSheet(r){
    const content=`${vBanner('info','Công bố kết quả đã rà soát','Hệ thống chỉ ghi phần chênh lệch và phiên bản giá vốn mới; không sửa chứng từ lịch sử.','','Compact')}${info('Phạm vi công bố',ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)+ds24InfoRow('Phạm vi',v313RunScope(r))+ds24InfoRow('Phương pháp','Bình quân cuối kỳ'))}${info('Chênh lệch sẽ ghi',key('Giá vốn xuất',signed(r.cogsTrueUp||0),true)+key('Giá trị tồn cuối',signed(r.endingAdjustment||0),true))}`;
    return sheet('Công bố giá vốn',content,`${button('Hủy','data-v313-val14-publish-sheet="close"','secondary')}${button('Công bố','data-v313-val14-publish')}`);
  }
  function render072V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);
    if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});
    if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});
    const active=val14Runs.filter(r=>r.status!=='PUBLISHED');
    const rows=active.map(r=>{const m=v313Val14WorkMeta(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v313-val14-run="${r.id}"`});}).join('');
    const body=`${rows?`<section class="ds24-list-stack v313-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.')}`;
    return appShell({title:'Công việc giá vốn',body,back:false,actions:primaryFooter('Chốt kỳ','data-v313-val14-close-period')});
  }
  function render074V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=v313EnrichRun(val14Current());
    if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});
    if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${v313Policy(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v313-val14-successor')});
    if(v313Val14Mode==='DIRTY_SETUP'||v313Val14Mode==='PERIOD_CLOSE_SETUP')return appShell({title:v313Val14Mode==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:`${v313PeriodSetup(r)}`,actions:primaryFooter(v313Val14Mode==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v313-val14-calculate')});
    if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',v313RunScope(r)]],'info'),centered:true});
    if(r.status==='BLOCKED'||state==='BLOCKED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây; hệ thống sẽ giữ nguyên phạm vi công việc này.')}${v313Policy(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<div class="v313-readiness-list">${v313Blockers(r)}</div>`});
    const productRows=(r.productResults||[]).slice(0,6).map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?money(x.newCost):'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');
    const body=`${v313Policy(r)}${v313PrimaryResult(r)}${v313Compare(r)}${productRows?`${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<section class="ds24-list-stack v313-list">${productRows}</section>`:''}${v313Val14PublishSheet? v313PublishSheet(r):''}`;
    return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v313-val14-open-publish',r.status!=='READY_FOR_REVIEW')});
  }
  function render073V313(){v313Val14Mode='PERIOD_CLOSE_SETUP';return render074V313('READY');}
  function render075V313(state){return render074V313(state);}
  function render076V313(state){v313Val14PublishSheet=true;return render074V313(state);}
  function render077V313(state){
    if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=v313EnrichRun(val14Current());const res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:'Bình quân cuối kỳ',reconciledProducts:r.productCount||0,officialCostVersions:0,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};
    if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});
    if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}
    const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Kết quả đã được ghi và có hiệu lực theo kỳ, phạm vi đã rà soát.')}${info('Kết quả',ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)+ds24InfoRow('Phương pháp','Bình quân cuối kỳ')+ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))+ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt)+key('Giá vốn xuất',signed(res.cogsTrueUp||0),true)+key('Giá trị tồn cuối',signed(res.endingAdjustment||0),true))}</div>`;
    return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v313-val14-list')});
  }

  // Renderer rebinding — last loaded layer owns valuation cluster only.
  Object.assign(renderers,{
    'SCR-014':render014V313,'SCR-015':render015V313,'SCR-016':render016V313,'SCR-017':render017V313,'SCR-019':render019V313,
    'SCR-085':render085V313,'SCR-086':render086V313,'SCR-087':render087V313,'SCR-088':render088V313,'SCR-089':render089V313,
    'SCR-072':render072V313,'SCR-073':render073V313,'SCR-074':render074V313,'SCR-075':render075V313,'SCR-076':render076V313,'SCR-077':render077V313
  });

  // Capture custom actions before legacy document-level handlers.
  window.addEventListener('click',(event)=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v313-val03-filter]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03Filter=el.dataset.v313Val03Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-receipt]'))){event.preventDefault();event.stopImmediatePropagation();val03SelectedReceiptId=el.dataset.v313Val03Receipt;v313Val03ClearSelection();v313Val03Sheet=null;stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=val03Current().groups.find(x=>x.id===el.dataset.v313Val03Select);if(g&&v313Val03GroupState(val03Current(),g)==='READY')v313Val03SelectGroup(g,!v313Val03SelectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03Sheet=el.dataset.v313Val03AddBasis;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();document.querySelectorAll('[data-v313-tax-mode]').forEach(x=>x.classList.toggle('is-selected',x===el));const wrap=document.querySelector('[data-v313-tax-amount-wrap]');if(wrap)wrap.hidden=el.dataset.v313TaxMode!=='EXCLUDED';return;}
      if((el=event.target.closest('[data-v313-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v313Val03Sheet==='close'){v313Val03Sheet=null;return renderAppScreen();}if(el.dataset.v313Val03Sheet==='save'&&v313Val03SaveBasis(v313Val03Sheet)){v313Val03Sheet=null;return renderAppScreen();}return;}
      if(event.target.closest('[data-v313-sheet-backdrop]')&&!event.target.closest('.v313-sheet')){event.preventDefault();event.stopImmediatePropagation();v313Val03Sheet=null;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!v313Val03CanReview())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v313-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}v313Val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v313-val03-result-back]'))){event.preventDefault();event.stopImmediatePropagation();v313Val03ClearSelection();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v313-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();val03Query='';v313Val03Filter='ALL';return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v313-val13-filter]'))){event.preventDefault();event.stopImmediatePropagation();v313Val13Filter=el.dataset.v313Val13Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val13-task]'))){event.preventDefault();event.stopImmediatePropagation();val13SelectedTaskId=el.dataset.v313Val13Task;val13ResetTaskDraft(val13Current());stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v313-val13-review]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t)){stateByScreen['SCR-086']='VALIDATION_ERROR';return renderAppScreen();}val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);stateByScreen['SCR-088']='READY';return navigate('SCR-088');}
      if((el=event.target.closest('[data-v313-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v313-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen['SCR-088']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v313-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();val13Query='';v313Val13Filter='ALL';return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v313-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v313Val14Run;const r=v313EnrichRun(val14Current());v313Val14PublishSheet=false;v313Val14CompareOpen=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;v313Val14Mode='DIRTY_SETUP';}else{v313Val14Mode='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v313-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope='Toàn bộ sản phẩm';v313Val14Mode='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v313-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();val14SetupKind=v313Val14Mode==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();v313EnrichRun(run);v313Val14Mode='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=v313EnrichRun(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);v313Val14PublishSheet=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-publish-sheet]'))){event.preventDefault();event.stopImmediatePropagation();v313Val14PublishSheet=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=v313EnrichRun(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';v313Val14PublishSheet=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();v313Val14PublishSheet=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v313-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';v313Val14Mode=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v313-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();v313Val14Mode='RESULT';v313Val14PublishSheet=false;return navigate('SCR-072');}
    }
  },true);

  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='3.13.0';
  window.__VET45_V313__={version:'3.13.0',screens:{bj03:['SCR-014','SCR-015','SCR-017','SCR-019'],bj13:['SCR-085','SCR-086','SCR-088','SCR-089'],bj14:['SCR-072','SCR-074','SCR-077']}};
})();

/* ===== v430-valuation-uiux.js ===== */
/* VET45 Theme 7 v4.3.0 — Valuation UI/UX + runtime hardening
 * Parent: v4.2.0
 * Scope: UIF-03, UIF-13, UIF-14 only.
 * UI authority: VET45 Figma DS v2 (Components 505:5890, Patterns 505:5891).
 * Business semantics are unchanged. This layer owns the final valuation renderers.
 */
(()=>{
  if(typeof renderers==='undefined') return;
  const VALUATION_FLOWS=new Set(['UIF-03','UIF-13','UIF-14']);
  const SCREEN_ALIAS={
    'UIF-03':{'SCR-016':'SCR-015'},
    'UIF-13':{'SCR-087':'SCR-086'},
    'UIF-14':{'SCR-073':'SCR-074','SCR-075':'SCR-074','SCR-076':'SCR-074'}
  };
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const entryType=r=>r.v313EntryType||({VAL03_R2:'QUICK'}[r.id])||'DOCUMENT';
  const entryLabel=r=>entryType(r)==='QUICK'?'Nhập nhanh':'Theo chứng từ';
  const stable=value=>{let h=2166136261>>>0;for(const c of String(value)){h^=c.charCodeAt(0);h=Math.imul(h,16777619)>>>0;}return `fixture-v430-${h.toString(16)}`;};
  const row=args=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(title,meta='')=>ds24SectionTitle(title,meta);
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" data-figma-node="521:529" ${disabled?'disabled':''}>${esc(label)}</button>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v430-link" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const flatRows=(title,rows,extra='')=>`<section class="v430-flat ${extra}" data-composed-from="DS v2 / Info Row,DS v2 / Key-value Row">${title?heading(title):''}<div class="v430-flat__rows">${rows}</div></section>`;
  const keyRows=(rows,extra='')=>`<div class="v430-key-stack ${extra}" data-composed-from="DS v2 / Key-value Row">${rows}</div>`;
  const contextRow=(title,subtitle,badge='',tone='Neutral')=>row({title,subtitle,trailing:badge?ds24Badge(badge,tone):'',leading:null,type:'Status',interactive:false});
  const textField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextField" data-figma-node="522:7186"><span>${esc(label)}${required?' <b>*</b>':''}</span><input class="v430-control" ${attrs} value="${escapeAttribute(value)}"/>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const moneyField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span>đ</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const textareaField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}${required?' <b>*</b>':''}</span><textarea class="v430-control v430-textarea" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const selectField=(label,attrs,options)=>`<label class="v430-field" data-ds-component="VSelect" data-figma-node="522:7291"><span>${esc(label)}</span><select class="v430-control" ${attrs}>${options}</select></label>`;
  const formSheet=({title,intro,body,saveLabel='Lưu',saveAttr,closeAttr})=>`<div class="v430-overlay" data-v430-overlay><div class="v430-overlay__backdrop" ${closeAttr}></div><section class="v430-form-sheet" data-ds-component="DS v2 / Form Sheet" data-figma-node="1353:6355" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="v430-sheet-handle-area"><div class="v430-sheet-handle"></div></div><header class="v430-sheet-header"><h2>${esc(title)}</h2><button type="button" class="v430-sheet-close" ${closeAttr} aria-label="Đóng" data-ds-component="DS v2 / Icon Button" data-figma-node="4431:10317">${icon('close','icon--sm')}</button></header>${intro?`<p class="v430-sheet-intro">${esc(intro)}</p>`:''}<div class="v430-form-sheet__body">${body}</div><footer class="v430-sheet-footer" data-ds-component="DS v2 / Sticky Footer" data-figma-node="549:927" data-ds-prop-layout="Single"><button type="button" class="button button--primary" ${saveAttr} data-ds-component="VButton" data-figma-node="521:529">${esc(saveLabel)}</button></footer></section></div>`;
  const confirmSheet=({title,desc,body,confirmLabel,confirmAttr,closeAttr})=>`<div class="sheet-backdrop ds24-overlay v430-confirm-overlay"><div class="v430-confirm-backdrop" ${closeAttr}></div><section class="ds24-confirmation v430-confirmation" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" data-ds-prop-content="Plain" data-ds-prop-tone="Default" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${body}<div class="ds24-confirmation__actions"><button type="button" class="ds24-button ds24-button--secondary" ${closeAttr} data-ds-component="VButton">Quay lại</button><button type="button" class="ds24-button ds24-button--primary" ${confirmAttr} data-ds-component="VButton">${esc(confirmLabel)}</button></div></section></div>`;
  const resultSummary=(title,body)=>ds24SummaryCard(title,body,'data-ds-prop-tone="Neutral"');

  // Hard-retire legacy valuation route nodes without deleting their historical evidence.
  const baseNavigate=navigate;
  navigate=function(screenId){
    if(activeFlowId==='UIF-03'&&screenId==='SCR-018'){activeFlowId='UIF-13';return baseNavigate('SCR-085');}
    const canonical=SCREEN_ALIAS[activeFlowId]?.[screenId]||screenId;
    return baseNavigate(canonical);
  };
  try{
    ['SCR-016','SCR-018'].forEach(x=>delete FIGMA_TEMPLATE_BY_FLOW_SCREEN['UIF-03']?.[x]);
    ['SCR-087'].forEach(x=>delete FIGMA_TEMPLATE_BY_FLOW_SCREEN['UIF-13']?.[x]);
    ['SCR-073','SCR-075','SCR-076'].forEach(x=>delete FIGMA_TEMPLATE_BY_FLOW_SCREEN['UIF-14']?.[x]);
  }catch(_){}
  if(activeFlowId==='UIF-03'&&activeScreenId==='SCR-018'){activeFlowId='UIF-13';activeScreenId='SCR-085';}
  else if(SCREEN_ALIAS[activeFlowId]?.[activeScreenId]) activeScreenId=SCREEN_ALIAS[activeFlowId][activeScreenId];

  // -------------------------------------------------------------------------
  // BJ03 — Xác lập giá trị nhập ban đầu
  // -------------------------------------------------------------------------
  let val03Filter430='ALL';
  let val03SheetGroup430=null;
  let val03TaxMode430='INCLUDED';
  function val03GroupState430(r,g){
    const st=val03EvidenceState(g);
    if(st==='READY') return 'READY';
    if(st==='CONFLICT') return entryType(r)==='DOCUMENT'?'COMMERCIAL_CONFLICT':'DIRECT_CONFLICT';
    return entryType(r)==='QUICK'?'DIRECT_MISSING':'COMMERCIAL_MISSING';
  }
  function val03ReceiptState430(r){const sts=pendingGroups(r).map(g=>val03GroupState430(r,g));if(sts.some(x=>x.includes('CONFLICT')))return 'CONFLICT';if(sts.length&&sts.every(x=>x.includes('MISSING')))return 'MISSING';return 'READY';}
  function val03Selected430(r=val03Current()){return pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));}
  function val03Select430(g,on){(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});}
  function val03Clear430(r=val03Current()){(r.groups||[]).forEach(g=>val03Select430(g,false));}
  function val03Actual430(g){const s=val03Source(g);if(!s)return null;return s.unitPrice*s.fxRate-(s.unitLineDiscount||0)-(s.unitDocDiscount||0)+(s.unitKnownCost||0)+(s.unitNonDeductibleVat||0);}
  function val03Basis430(g){const s=val03Source(g);return s?s.label:'Chưa có căn cứ';}
  function val03Breakdown430(g){
    const s=val03Source(g);if(!s)return '';
    const unit=s.unitPrice*s.fxRate,actual=val03Actual430(g);
    return keyRows(`${ds24KeyValueRow(s.currency==='VND'?'Giá mua':'Giá mua quy đổi',`${money(unit)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(actual)}/${g.uom}`,true)}`);
  }
  function val03CanReview430(r=val03Current()){const s=val03Selected430(r);return s.length>0&&s.every(g=>val03GroupState430(r,g)==='READY');}
  function val03Group430(r,g){
    const st=val03GroupState430(r,g),selected=val03Selected430(r).includes(g),pending=qty(g);
    const base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const source=val03Source(g),subtitle=`${base} · ${val03Basis430(g)}`;
      return `<section class="v430-task-block ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v430-val03-select="${g.id}"`})}${selected?`<div class="v430-expanded">${flatRows('Căn cứ giá',`${ds24InfoRow('Nguồn',source?.label||'—')}${source?.currency!=='VND'?ds24InfoRow('Tỷ giá',source?.fxLabel||'—'):''}`)}${val03Breakdown430(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v430-task-block">${contextRow(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu chứng từ mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v430-task-block">${contextRow(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Dòng nhận theo chứng từ chưa có căn cứ giá đủ điều kiện. Công việc sẽ cập nhật khi căn cứ mua hàng được bổ sung.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v430-task-block">${contextRow(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Nhập nhanh không cần chờ chứng từ mua. Kế toán có thể lập căn cứ giá trực tiếp và lưu dấu vết.</p>${button('Thêm căn cứ giá',`data-v430-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    return `<section class="v430-task-block">${contextRow(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  function val03Form430(r,g){
    const body=`${moneyField('Đơn giá mua','data-v430-basis-price min="0" step="1"','',`Theo đơn vị ${g.uom}`,true)}<div class="v430-field" data-ds-component="VSegmentedControl" data-figma-node="1049:9598"><span>Cách hiểu giá</span><div class="v430-segment"><button type="button" class="${val03TaxMode430==='INCLUDED'?'is-selected':''}" data-v430-tax-mode="INCLUDED">Đã gồm thuế</button><button type="button" class="${val03TaxMode430==='EXCLUDED'?'is-selected':''}" data-v430-tax-mode="EXCLUDED">Chưa gồm thuế</button></div></div><div data-v430-tax-wrap ${val03TaxMode430==='EXCLUDED'?'':'hidden'}>${moneyField('Thuế tính vào giá trị','data-v430-basis-tax min="0" step="1"','0','Nhập phần thuế không được khấu trừ nếu có.')}</div>${textField('Nguồn căn cứ','data-v430-basis-source placeholder="Ví dụ: Xác nhận giá từ nhà cung cấp"','', '',true)}${textField('Ngày căn cứ','data-v430-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"','24/09/2026')}${textField('Tham chiếu / bằng chứng','data-v430-basis-ref placeholder="Mã báo giá, email, ghi chú..."')}${textareaField('Lý do xác lập trực tiếp','data-v430-basis-reason placeholder="Nêu ngắn gọn lý do"','','Bắt buộc khi chưa có chứng từ mua có cấu trúc.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Nhập thông tin cần thiết để kế toán và người kiểm tra có thể truy vết căn cứ.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v430-val03-sheet="save"',closeAttr:'data-v430-val03-sheet="close"'});
  }
  function val03SetError430(root,selector,msg){const input=root.querySelector(selector);const field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function val03SaveBasis430(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const price=Number(root.querySelector('[data-v430-basis-price]')?.value||0),sourceLabel=String(root.querySelector('[data-v430-basis-source]')?.value||'').trim(),date=String(root.querySelector('[data-v430-basis-date]')?.value||'').trim(),ref=String(root.querySelector('[data-v430-basis-ref]')?.value||'').trim(),reason=String(root.querySelector('[data-v430-basis-reason]')?.value||'').trim(),tax=val03TaxMode430==='EXCLUDED'?Number(root.querySelector('[data-v430-basis-tax]')?.value||0):0;
    const errors=[];if(!(price>0))errors.push(val03SetError430(root,'[data-v430-basis-price]','Nhập đơn giá lớn hơn 0.'));if(!sourceLabel)errors.push(val03SetError430(root,'[data-v430-basis-source]','Nhập nguồn căn cứ.'));if(!reason)errors.push(val03SetError430(root,'[data-v430-basis-reason]','Nêu lý do xác lập trực tiếp.'));const first=errors.find(Boolean);if(first){first.focus();return false;}
    const id=`DIRECT-${g.id}-${Date.now()}`,components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:sourceLabel,version:date||'Hiện hành',amount:price}];if(tax)components.push({type:'NON_RECOVERABLE_TAX',label:'Thuế tính vào giá trị',source:sourceLabel,version:date||'Hiện hành',amount:tax});
    g.sources=[{id,label:`${sourceLabel}${date?` · ${date}`:''}`,version:'v1',basisVersion:1,basisHash:stable(`${id}|${price}|${tax}|${date}`),authoritativeValueHash:stable(`${price+tax}`),unitPrice:price,currency:'VND',fxRate:1,fxLabel:'VND',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:tax,components,evidenceRefs:[ref||reason],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:reason,taxMode:val03TaxMode430,sourceDate:date,reference:ref}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;val03Select430(g,true);return true;
  }
  function val03Commit430(){
    const r=val03Current(),groups=[];let totalValue=0,totalQty=0;
    for(const g of val03Selected430(r)){const c=val03Calc(g);if(!c)continue;const lines=[];let groupQty=0,groupValue=0;for(const s of (g.slices||[]).filter(x=>x.selected&&Number(x.pendingQty||0)>0)){const q=Number(s.pendingQty||0),amount=Math.round(Number(c.unitActual||0)*q);groupQty+=q;groupValue+=amount;lines.push({scopeKey:s.scopeKey,lot:s.lot,state:s.stateLabel,qty:q,value:amount});}groups.push({name:g.name,code:g.code,uom:g.uom,qty:groupQty,value:groupValue,unitInitial:c.unitActual,source:val03SourceDetail(g),slices:lines});totalQty+=groupQty;totalValue+=groupValue;}
    val03LastResult={operationId:`VAL-260925-${String(val03OperationSeq++).padStart(3,'0')}`,receipt:r.receipt,supplier:r.supplier,businessDate:r.receivedAt,groups,totalValue,totalQty,dirtyScope:groups.map(g=>`${g.name} · kỳ ${r.receivedAt.slice(3)}`)};
    for(const g of val03Selected430(r))for(const s of (g.slices||[]).filter(x=>x.selected&&Number(x.pendingQty||0)>0)){const q=s.pendingQty,amount=Math.round((val03Calc(g)?.unitActual||0)*q);s.pendingQty=0;s.confirmedQty=Number(s.confirmedQty||0)+q;s.confirmedValue=Number(s.confirmedValue||0)+amount;s.scopeVersion=Number(s.scopeVersion||0)+1;s.selected=false;s.selectedQty=0;}
    val03ReviewSourceVersion=null;return val03LastResult;
  }
  val03Commit=val03Commit430;
  function render014V430(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-014'),state);if(state==='LOADING')return appShell({title:'Hàng chờ xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Hàng chờ xác lập giá trị',body:deniedBody(),centered:true,back:false});
    const q=String(val03Query||'').toLocaleLowerCase('vi'),rows=val03Receipts.filter(r=>pendingGroups(r).length).filter(r=>!q||`${r.receipt} ${r.supplier}`.toLocaleLowerCase('vi').includes(q)).filter(r=>{const st=val03ReceiptState430(r);return val03Filter430==='ALL'||(val03Filter430==='READY'&&st==='READY')||(val03Filter430==='ISSUE'&&st!=='READY');}).map(r=>{const st=val03ReceiptState430(r),trailing=st==='CONFLICT'?ds24Badge('Cần đối chiếu','Warning'):st==='MISSING'?ds24Badge('Cần căn cứ','Neutral'):'';return row({title:r.receipt,subtitle:`${r.supplier} · ${entryLabel(r)} · ${pendingGroups(r).length} dòng chờ`,trailing,leading:null,type:'Navigation',attrs:`data-v430-val03-receipt="${r.id}"`});}).join('');
    const body=`${ds24Search(val03Query,'data-v430-val03-search','Phiếu nhận hoặc nhà cung cấp')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',val03Filter430==='ALL','data-v430-val03-filter')}${ds24Chip('READY','Có thể xác lập',val03Filter430==='READY','data-v430-val03-filter')}${ds24Chip('ISSUE','Cần xử lý',val03Filter430==='ISSUE','data-v430-val03-filter')}</div>${rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;return appShell({title:'Hàng chờ xác lập giá trị',body,back:false});
  }
  function render015V430(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='LOADING')return appShell({title:'Xác lập giá trị nhập ban đầu',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const context=contextRow(r.receipt,`${r.supplier} · ${r.receivedAt}`,entryLabel(r),'Neutral'),work=pendingGroups(r).map(g=>val03Group430(r,g)).join(''),selected=val03Selected430(r),total=selected.reduce((n,g)=>n+(val03Calc(g)?.value||0),0),selection=selected.length?keyRows(ds24KeyValueRow(`Đã chọn ${selected.length} dòng`,money(total),true),'v430-selection-total'):'';
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Căn cứ đã thay đổi','Kiểm tra lại giá và cấu thành trước khi tiếp tục.'):''}${context}${heading('Hàng chờ giá trị')}${work}${selection}${val03SheetGroup430?val03Form430(r,(r.groups||[]).find(g=>g.id===val03SheetGroup430)):''}`;return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v430-val03-review',!val03CanReview430(r))});
  }
  function render017V430(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Kết quả rà soát cũ không còn hiệu lực. Quay lại kiểm tra căn cứ hiện hành.')}${contextRow(r.receipt,r.supplier)}`,actions:primaryFooter('Kiểm tra lại','data-v430-val03-back')});
    const sections=val03Selected430(r).map(g=>{const c=val03Calc(g);return `<section class="v430-review-block">${heading(g.name,`${c?.qty||0} ${g.uom}`)}<p class="v430-source-line">${esc(val03SourceDetail(g))}</p>${val03Breakdown430(g)}${keyRows(ds24KeyValueRow('Giá trị sẽ ghi',money(c?.value||0),true))}</section>`;}).join(''),total=val03Selected430(r).reduce((n,g)=>n+(val03Calc(g)?.value||0),0),body=`${contextRow(r.receipt,`${r.supplier} · ${r.receivedAt}`)}${sections}${resultSummary('Tổng giá trị nhập ban đầu',money(total))}${linkButton('Chỉnh sửa căn cứ','data-v430-val03-back')}`;return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v430-val03-confirm')});
  }
  function render019V430(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,supplier:val03Current().supplier,groups:[],totalValue:0,totalQty:0};if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v430-val03-result-back')});
    const remaining=pendingGroups(val03Current()).length,rows=(res.groups||[]).map(g=>ds24KeyValueRow(g.name,`${g.qty} ${g.uom} · ${money(g.value)}`)).join(''),body=`<div class="io-result">${resultHero('Đã xác lập giá trị nhập ban đầu','Giá trị đã được ghi cho lượng hàng đã rà soát. Giá vốn sẽ được cập nhật ở công việc giá vốn.')}${flatRows('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt)}${ds24InfoRow('Số dòng đã xác lập',String(res.groups?.length||0))}${ds24InfoRow('Số lượng',String(res.totalQty||0))}${ds24KeyValueRow('Tổng giá trị đã ghi',money(res.totalValue),true)}${ds24InfoRow('Giá vốn','Cần cập nhật')}`)}${rows?keyRows(rows):''}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} dòng chưa đủ điều kiện hoặc chưa được chọn trong lần xử lý.`,'','Default'):''}</div>`;return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v430-val03-result-back':'data-v430-val03-result-list')});
  }

  // -------------------------------------------------------------------------
  // BJ13 — Điều chỉnh giá trị hàng nhập
  // -------------------------------------------------------------------------
  let val13Filter430='ALL';
  function val13Source430(t){return `${contextRow(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keyRows(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true),'v430-source-amount')}`;}
  function val13Targets430(t){return (t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:t.targetScopeMode==='FIXED'?ds24Badge('Theo nguồn','Neutral'):(x.selected?icon('checkCircle','icon--sm'):''),leading:null,type:t.targetScopeMode==='FIXED'?'Status':'Selection',interactive:t.targetScopeMode!=='FIXED',state:x.selected?'Selected':'Default',attrs:t.targetScopeMode==='FIXED'?'':`data-v430-val13-target="${x.id}"`})).join('');}
  function val13Method430(t){const opts=`<option value="">Chọn cách phân bổ</option>`+(t.allowedMethods||[]).map(m=>`<option value="${m.id}" ${m.id===t.selectedMethod?'selected':''}>${esc(m.label)}</option>`).join('');return selectField('Cách phân bổ','data-v430-val13-method',opts);}
  function val13Preview430(t){const p=val13Preview(t);if(!p.length)return vBanner('info','Chưa có kết quả phân bổ','Chọn phạm vi và cách phân bổ để xem kết quả trước khi rà soát.','','Compact');return `<section class="v430-preview">${heading('Kết quả phân bổ',`${p.length} dòng`)}${keyRows(p.map(x=>ds24KeyValueRow(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join('')+ds24KeyValueRow('Tổng phân bổ',signed(p.reduce((n,x)=>n+x.allocatedAmount,0)),true))}</section>`;}
  function render085V430(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-085'),state);if(state==='LOADING')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Điều chỉnh giá trị hàng nhập',body:deniedBody(),centered:true,back:false});const q=String(val13Query||'').toLocaleLowerCase('vi'),tasks=val13Tasks.filter(t=>t.status!=='COMPLETED').filter(t=>!q||`${t.sourceRef} ${t.supplier} ${t.component}`.toLocaleLowerCase('vi').includes(q)).filter(t=>val13Filter430==='ALL'||(val13Filter430==='ACTIONABLE'&&t.status==='ACTIONABLE')||(val13Filter430==='WAITING'&&t.status==='WAITING')),rows=tasks.map(t=>row({title:t.sourceRef.replace(/ · dòng \d+$/,''),subtitle:`${t.component} · ${t.supplier} · ${signed(t.normalizedAmount)}`,trailing:t.status==='WAITING'?ds24Badge('Đang chờ','Neutral'):'',leading:null,type:'Navigation',attrs:`data-v430-val13-task="${t.id}"`})).join(''),body=`${ds24Search(val13Query,'data-v430-val13-search','Nguồn điều chỉnh hoặc đối tác')}<div class="ds24-chip-scroll">${ds24Chip('ALL','Tất cả',val13Filter430==='ALL','data-v430-val13-filter')}${ds24Chip('ACTIONABLE','Có thể xử lý',val13Filter430==='ACTIONABLE','data-v430-val13-filter')}${ds24Chip('WAITING','Đang chờ',val13Filter430==='WAITING','data-v430-val13-filter')}</div>${rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc phù hợp','Đổi từ khóa hoặc bộ lọc để xem công việc khác.')}`;return appShell({title:'Điều chỉnh giá trị hàng nhập',body,back:false});}
  function render086V430(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();if(state==='LOADING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ điều chỉnh giá trị',body:deniedBody(),centered:true});if(t.status==='WAITING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ căn cứ cần thiết.')}${val13Source430(t)}${(t.targets||[]).length?`${heading('Phạm vi liên quan')}<section class="ds24-list-stack v430-list">${val13Targets430(t)}</section>`:''}`});const changed=state==='SOURCE_CHANGED'||Boolean(val13LastSourceChange),period=flatRows('Kỳ ghi nhận',`${ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')}${ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—')}${t.periodReason?`<div class="v450-read-note" data-ds-component="VText"><span>Lý do</span><strong>${esc(t.periodReason)}</strong></div>`:''}`),body=`${changed?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Kết quả phân bổ cũ không còn hiệu lực. Kiểm tra lại phạm vi và cách phân bổ.'):''}${val13Source430(t)}${heading('Phạm vi áp dụng',t.targetScopeMode==='FIXED'?'Theo nguồn xác định':'Chọn trong phạm vi cho phép')}<section class="ds24-list-stack v430-list">${val13Targets430(t)}</section>${val13Method430(t)}${val13Preview430(t)}${period}`;return appShell({title:'Phân bổ điều chỉnh giá trị',body,actions:primaryFooter('Rà soát điều chỉnh','data-v430-val13-review',!val13CanPreview(t))});}
  function render088V430(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-088'),state);const t=val13Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát điều chỉnh giá trị',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val13PreviewHash==null||val13PreviewHash!==val13PreviewHashOf(t)||Number(val13ReviewSourceVersion)!==Number(t.sourceVersion);if(stale)return appShell({title:'Rà soát điều chỉnh giá trị',body:`${vBanner('warning','Nguồn hoặc phân bổ đã thay đổi','Tạo lại kết quả phân bổ trước khi ghi điều chỉnh.')}${val13Source430(t)}`,actions:primaryFooter('Tạo lại phân bổ','data-v430-val13-back')});const p=val13Preview(t),rows=p.map(x=>ds24KeyValueRow(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join(''),method=(t.allowedMethods||[]).find(m=>m.id===t.selectedMethod)?.label||'—',body=`${val13Source430(t)}${flatRows('Cách phân bổ',`${ds24InfoRow('Phương pháp',method)}${ds24InfoRow('Kỳ gốc',t.originalPeriod||'—')}${ds24InfoRow('Kỳ ghi nhận',t.postingPeriod||'—')}`)}${heading('Phân bổ sẽ ghi')}${keyRows(rows+ds24KeyValueRow('Tổng điều chỉnh',signed(t.normalizedAmount),true))}${vBanner('info','Sau khi ghi','Số lượng tồn không đổi. Các sản phẩm liên quan cần cập nhật giá vốn.','','Default')}${linkButton('Chỉnh sửa phân bổ','data-v430-val13-back')}`;return appShell({title:'Rà soát điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v430-val13-confirm')});}
  function render089V430(state){if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const res=val13Result();if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||'ADJ-UNKNOWN')}" data-scope="${escapeAttribute(res.sourceRef||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không gửi lại lệnh. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Nguồn',res.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh giá trị','Không có thay đổi. Kiểm tra lại nguồn và phân bổ hiện hành.',[['Nguồn',res.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v430-val13-back')});const rows=(res.allocations||[]).map(x=>ds24KeyValueRow(`${x.product} · ${x.receipt}`,signed(x.allocatedAmount))).join(''),body=`<div class="io-result">${resultHero(Number(res.normalizedAmount||0)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập','Điều chỉnh đã được ghi theo phạm vi và kỳ đã rà soát.')}${flatRows('Kết quả',`${ds24InfoRow('Nguồn',res.sourceRef)}${ds24KeyValueRow('Tổng điều chỉnh',signed(res.normalizedAmount),true)}${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||'—')}${ds24InfoRow('Giá vốn','Cần cập nhật')}`)}${rows?keyRows(rows):''}</div>`;return appShell({title:'Kết quả điều chỉnh giá trị',body,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v430-val13-list')});}

  // -------------------------------------------------------------------------
  // BJ14 — Tính, rà soát và công bố giá vốn
  // -------------------------------------------------------------------------
  let val14Mode430='RESULT',val14Publish430=false,val14Compare430=false;
  function enrich430(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod='PERIODIC';r.policyLabel='Bình quân cuối kỳ';r.policyVersion='Chính sách giá vốn';return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(enrich430);
  function scope430(r){return r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;}
  function policy430(r){return flatRows('Chính sách áp dụng',`${ds24InfoRow('Phương pháp','Bình quân cuối kỳ')}${ds24InfoRow('Cấp cấu hình','Tổ chức')}${ds24InfoRow('Áp dụng','Tự động')}`,'v430-policy');}
  function workMeta430(r){enrich430(r);if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};return {title:r.label,subtitle:scope430(r),label:'Đang xử lý',tone:'Neutral'};}
  function result430(r){const x=r.periodic||{};return `${resultSummary('Kết quả giá vốn',`Bình quân cuối kỳ · ${scope430(r)}`)}${keyRows(`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0),true)}${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0))}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0))}`)}`;}
  function compare430(r){const x=r.moving||{};return `<details class="v430-details" ${val14Compare430?'open':''} data-v430-compare><summary>Xem đối chiếu phương pháp khác</summary><div class="v430-details__body">${flatRows('Bình quân liên hoàn · chỉ đối chiếu',`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0))}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0))}`)}</div></details>`;}
  function setup430(r){const dirty=val14Mode430==='DIRTY_SETUP',period=dirty?(r?.period||val14SetupPeriod):val14SetupPeriod,scope=dirty?scope430(r):val14SetupScope,controls=dirty?flatRows('Phạm vi cần cập nhật',`${ds24InfoRow('Kỳ ghi nhận',period)}${ds24InfoRow('Phạm vi',scope)}${ds24InfoRow('Nguồn phạm vi','Hệ thống xác định từ thay đổi giá trị')}`):`${selectField('Kỳ','data-v430-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`)}${selectField('Phạm vi','data-v430-val14-scope',`<option ${val14SetupScope==='Toàn bộ sản phẩm'?'selected':''}>Toàn bộ sản phẩm</option><option ${val14SetupScope==='Sản phẩm cần tính lại'?'selected':''}>Sản phẩm cần tính lại</option>`)}`;return `${controls}${policy430(r||{})}`;}
  function publish430(r){const body=`${flatRows('Phạm vi công bố',`${ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)}${ds24InfoRow('Phạm vi',scope430(r))}${ds24InfoRow('Phương pháp','Bình quân cuối kỳ')}`)}${keyRows(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`)}`;return confirmSheet({title:'Công bố giá vốn?',desc:'Kết quả đã rà soát sẽ trở thành phiên bản giá vốn có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',body,confirmLabel:'Công bố giá vốn',confirmAttr:'data-v430-val14-publish',closeAttr:'data-v430-val14-publish-close'});}
  function render072V430(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});const rows=val14Runs.filter(r=>r.status!=='PUBLISHED').map(r=>{const m=workMeta430(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v430-val14-run="${r.id}"`});}).join(''),body=rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.');return appShell({title:'Công việc giá vốn',body,back:false,actions:primaryFooter('Chốt kỳ','data-v430-val14-close-period')});}
  function render074V430(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=enrich430(val14Current());if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${policy430(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v430-val14-successor')});if(val14Mode430==='DIRTY_SETUP'||val14Mode430==='PERIOD_CLOSE_SETUP')return appShell({title:val14Mode430==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:setup430(r),actions:primaryFooter(val14Mode430==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v430-val14-calculate')});if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',scope430(r)]],'info'),centered:true});if(r.status==='BLOCKED'||state==='BLOCKED'){const blockers=(r.blockers||[]).map(b=>contextRow(b.title,`Đang chờ: ${b.owner}`,'Cần xử lý','Warning')).join('');return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây; hệ thống giữ nguyên phạm vi công việc này.')}${policy430(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<section class="ds24-list-stack v430-list">${blockers}</section>`});}
    const productRows=(r.productResults||[]).slice(0,6).map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?money(x.newCost):'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join(''),body=`${policy430(r)}${result430(r)}${compare430(r)}${productRows?`${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<section class="ds24-list-stack v430-list">${productRows}</section>`:''}${val14Publish430?publish430(r):''}`;return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v430-val14-open-publish',r.status!=='READY_FOR_REVIEW')});}
  function render077V430(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=enrich430(val14Current()),res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,reconciledProducts:r.productCount||0,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment};if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Kết quả đã được ghi và có hiệu lực theo kỳ, phạm vi đã rà soát.')}${flatRows('Kết quả',`${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)}${ds24InfoRow('Phương pháp','Bình quân cuối kỳ')}${ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))}${ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt)}${ds24KeyValueRow('Giá vốn xuất',signed(res.cogsTrueUp||0),true)}${ds24KeyValueRow('Giá trị tồn cuối',signed(res.endingAdjustment||0),true)}`)}</div>`;return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v430-val14-list')});}

  Object.assign(renderers,{
    'SCR-014':render014V430,'SCR-015':render015V430,'SCR-016':render015V430,'SCR-017':render017V430,'SCR-018':render017V430,'SCR-019':render019V430,
    'SCR-085':render085V430,'SCR-086':render086V430,'SCR-087':render086V430,'SCR-088':render088V430,'SCR-089':render089V430,
    'SCR-072':render072V430,'SCR-073':render074V430,'SCR-074':render074V430,'SCR-075':render074V430,'SCR-076':render074V430,'SCR-077':render077V430
  });

  // Latest valuation interaction layer. New data attributes avoid legacy handlers.
  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v430-val03-search]')){val03Query=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-search]')){val13Query=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-13'&&event.target.matches('[data-v430-val13-method]')){event.stopImmediatePropagation();const t=val13Current();if((t.allowedMethods||[]).some(m=>m.id===event.target.value)){t.selectedMethod=event.target.value;val13PreviewHash=null;}stateByScreen['SCR-086']='READY';return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v430-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v430-val14-scope]')){event.stopImmediatePropagation();val14SetupScope=event.target.value;return renderAppScreen();}
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v430-val03-filter]'))){event.preventDefault();event.stopImmediatePropagation();val03Filter430=el.dataset.v430Val03Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val03-receipt]'))){event.preventDefault();event.stopImmediatePropagation();val03SelectedReceiptId=el.dataset.v430Val03Receipt;val03Clear430();val03SheetGroup430=null;stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v430Val03Select);if(g&&val03GroupState430(val03Current(),g)==='READY')val03Select430(g,!val03Selected430().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();val03SheetGroup430=el.dataset.v430Val03AddBasis;val03TaxMode430='INCLUDED';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();val03TaxMode430=el.dataset.v430TaxMode;document.querySelectorAll('[data-v430-tax-mode]').forEach(x=>x.classList.toggle('is-selected',x.dataset.v430TaxMode===val03TaxMode430));const wrap=document.querySelector('[data-v430-tax-wrap]');if(wrap)wrap.hidden=val03TaxMode430!=='EXCLUDED';return;}
      if((el=event.target.closest('[data-v430-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v430Val03Sheet==='close'){val03SheetGroup430=null;return renderAppScreen();}if(el.dataset.v430Val03Sheet==='save'&&val03SaveBasis430(val03SheetGroup430)){val03SheetGroup430=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v430-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!val03CanReview430())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v430-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit430();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v430-val03-result-back]'))){event.preventDefault();event.stopImmediatePropagation();val03Clear430();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v430-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();val03Query='';val03Filter430='ALL';return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v430-val13-filter]'))){event.preventDefault();event.stopImmediatePropagation();val13Filter430=el.dataset.v430Val13Filter;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-task]'))){event.preventDefault();event.stopImmediatePropagation();val13SelectedTaskId=el.dataset.v430Val13Task;val13ResetTaskDraft(val13Current());stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-target]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),line=(t.targets||[]).find(x=>x.id===el.dataset.v430Val13Target);if(line&&t.targetScopeMode!=='FIXED')line.selected=!line.selected;val13PreviewHash=null;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val13-review]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t)){stateByScreen['SCR-086']='VALIDATION_ERROR';return renderAppScreen();}val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);stateByScreen['SCR-088']='READY';return navigate('SCR-088');}
      if((el=event.target.closest('[data-v430-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v430-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){stateByScreen['SCR-088']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v430-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();val13Query='';val13Filter430='ALL';return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v430-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v430Val14Run;const r=enrich430(val14Current());val14Publish430=false;val14Compare430=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;val14Mode430='DIRTY_SETUP';}else{val14Mode430='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v430-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope='Toàn bộ sản phẩm';val14Mode430='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v430-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();val14SetupKind=val14Mode430==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();enrich430(run);val14Mode430='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-compare] summary'))){val14Compare430=!val14Compare430;return;}
      if((el=event.target.closest('[data-v430-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=enrich430(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);val14Publish430=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();val14Publish430=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=enrich430(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';val14Publish430=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();val14Publish430=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v430-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=val14Current();val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';val14Mode430=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v430-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();val14Mode430='RESULT';val14Publish430=false;return navigate('SCR-072');}
    }
  },true);

  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='4.3.0';
  window.__VET45_V430__={version:'4.3.0',authority:'Figma DS v2',screens:{bj03:['SCR-014','SCR-015','SCR-017','SCR-019'],bj13:['SCR-085','SCR-086','SCR-088','SCR-089'],bj14:['SCR-072','SCR-074','SCR-077']},retiredAliases:SCREEN_ALIAS,crossFlowRetired:{'SCR-018':{flow:'UIF-13',screen:'SCR-085'}}};

  // app.js performs its first render before downstream hardening layers are loaded.
  // Re-render valuation flows now so direct/deep links always use the newest renderer.
  if(VALUATION_FLOWS.has(activeFlowId)){syncReviewUrl();render();}
})();

/* ===== v431-grouped-surface-regression-fix.js ===== */
/* VET45 Theme 7 v4.3.1 — grouped surface regression fix metadata */
(()=>{
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version='4.3.1';
  if(window.__VET45_V430__) window.__VET45_V430__.version='4.3.1';
  window.__VET45_V431__={version:'4.3.1',parent:'4.3.0',scope:['UIF-03','UIF-13','UIF-14'],rule:'ONE_HOMOGENEOUS_COLLECTION_ONE_SURFACE_BOUNDARY'};
})();

/* ===== v440-theme-wide-grouped-surface.js ===== */
/* VET45 Theme 7 v4.4.0 — theme-wide grouped information surface normalization */
(()=>{
  const VERSION='4.4.0';
  const ROW_SELECTOR='[data-ds-component="DS v2 / Info Row"],[data-ds-component="DS v2 / Key-value Row"]';
  const ROOT_BOUNDARY_SELECTOR='#app-screen,.app-content,.app-body,.app-shell,.device-screen';
  const alpha=(value)=>{
    const text=String(value||'');
    if(!text||text==='transparent') return 0;
    const m=text.match(/rgba?\(([^)]+)\)/i);
    if(!m) return 1;
    const parts=m[1].split(',').map(v=>v.trim());
    return parts.length<4?1:Number(parts[3]);
  };
  const hasVisualSurface=(el)=>{
    if(!el) return false;
    const s=getComputedStyle(el);
    const borderWidths=[s.borderTopWidth,s.borderRightWidth,s.borderBottomWidth,s.borderLeftWidth].map(v=>parseFloat(v)||0);
    const hasBorder=borderWidths.some(v=>v>0.1) && [s.borderTopStyle,s.borderRightStyle,s.borderBottomStyle,s.borderLeftStyle].some(v=>v!=='none');
    const hasShadow=Boolean(s.boxShadow&&s.boxShadow!=='none');
    const hasBackground=alpha(s.backgroundColor)>0.01;
    return hasBorder||hasShadow||hasBackground;
  };
  const alreadyOwnedBySurface=(stack)=>{
    let current=stack;
    for(let depth=0;current&&depth<3;depth+=1,current=current.parentElement){
      if(depth>0 && current.matches?.(ROOT_BOUNDARY_SELECTOR)) break;
      if(hasVisualSurface(current)) return true;
    }
    return false;
  };
  const isMinimalRowStack=(el)=>{
    const direct=[...el.children].filter(child=>child.matches?.(ROW_SELECTOR));
    if(direct.length<2) return false;
    return ![...el.children].some(child=>[...child.children].filter(grand=>grand.matches?.(ROW_SELECTOR)).length>=2);
  };
  function applyGroupedSurfaceRule(){
    const root=document.querySelector('#app-screen');
    if(!root) return {candidates:0,added:0};
    let candidates=0,added=0;
    root.querySelectorAll('*').forEach((el)=>{
      if(!isMinimalRowStack(el)) return;
      candidates+=1;
      if(alreadyOwnedBySurface(el)) return;
      el.classList.add('v440-grouped-surface');
      el.setAttribute('data-layout-pattern','Grouped surface');
      el.setAttribute('data-v440-grouped-surface','auto');
      added+=1;
    });
    return {candidates,added};
  }
  const priorRenderAppScreen=renderFlowScreen;
  if(priorRenderAppScreen){
    renderFlowScreen=function(){
      const out=priorRenderAppScreen.apply(this,arguments);
      applyGroupedSurfaceRule();
      return out;
    };
  }
  const priorRender=typeof render==='function'?render:null;
  if(priorRender){
    render=function(){
      const out=priorRender.apply(this,arguments);
      applyGroupedSurfaceRule();
      return out;
    };
  }
  const root=document.querySelector('#app-screen');
  if(root && typeof MutationObserver!=='undefined'){
    let scheduled=false;
    const observer=new MutationObserver(()=>{
      if(scheduled) return;
      scheduled=true;
      queueMicrotask(()=>{scheduled=false;applyGroupedSurfaceRule();});
    });
    observer.observe(root,{childList:true,subtree:true});
  }
  applyGroupedSurfaceRule();
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version=VERSION;
  window.__VET45_V440__={version:VERSION,parent:'4.3.1',scope:'ALL_CANONICAL_UIF',rule:'ONE_HOMOGENEOUS_COLLECTION_ONE_SURFACE_BOUNDARY',applyGroupedSurfaceRule};
})();

/* ===== v450-theme-visual-qa.js ===== */
/* VET45 Theme 7 v4.5.0 — snapshot-led visual QA release marker.
 * No business behavior is changed here; visual fixes live in the scoped CSS/source-copy edits.
 */
(()=>{
  const VERSION='4.5.0';
  window.__VET45_V450__={version:VERSION,scope:'snapshot-led-visual-qa'};
  if(window.__VET45_PROTOTYPE__) window.__VET45_PROTOTYPE__.version=VERSION;
})();

/* ===== v460-semantic-ux.js ===== */
/* VET45 Theme 7 v4.6.0 — semantic closure + focused UX simplification
 * Parent package: v4.5.2
 * Authority: v4.6 Decisions/BC/UI contracts + VET45 Figma DS v2.
 * Scope: SCR-008; UIF-03; UIF-13; UIF-14.
 */
(()=>{
  if(typeof renderers==='undefined') return;
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const pct=n=>`${(Number(n||0)*100).toLocaleString('vi-VN',{maximumFractionDigits:1})}%`;
  const row=args=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(t,m='')=>ds24SectionTitle(t,m);
  const flat=(title,rows,extra='')=>`<section class="v430-flat v460-flat ${extra}" data-composed-from="DS v2 / Info Row,DS v2 / Key-value Row">${title?heading(title):''}<div class="v430-flat__rows">${rows}</div></section>`;
  const keys=(rows,extra='')=>`<div class="v430-key-stack v460-key-stack ${extra}" data-composed-from="DS v2 / Key-value Row">${rows}</div>`;
  const context=(title,subtitle,badge='',tone='Neutral')=>row({title,subtitle,trailing:badge?ds24Badge(badge,tone):'',leading:null,type:'Status',interactive:false});
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" data-figma-node="521:529" ${disabled?'disabled':''}>${esc(label)}</button>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v430-link" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const textField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextField" data-figma-node="522:7186"><span>${esc(label)}${required?' <b>*</b>':''}</span><input class="v430-control" ${attrs} value="${escapeAttribute(value)}"/>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const moneyField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span>đ</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const textarea=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}${required?' <b>*</b>':''}</span><textarea class="v430-control v430-textarea" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const selectField=(label,attrs,options)=>`<label class="v430-field" data-ds-component="VSelect" data-figma-node="522:7291"><span>${esc(label)}</span><select class="v430-control" ${attrs}>${options}</select></label>`;
  const formSheet=({title,intro,body,saveLabel='Lưu',saveAttr,closeAttr})=>`<div class="v430-overlay" data-v460-overlay><div class="v430-overlay__backdrop" ${closeAttr}></div><section class="v430-form-sheet" data-ds-component="DS v2 / Form Sheet" data-figma-node="1353:6355" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="v430-sheet-handle-area"><div class="v430-sheet-handle"></div></div><header class="v430-sheet-header"><h2>${esc(title)}</h2><button type="button" class="v430-sheet-close" ${closeAttr} aria-label="Đóng" data-ds-component="DS v2 / Icon Button" data-figma-node="4431:10317">${icon('close','icon--sm')}</button></header>${intro?`<p class="v430-sheet-intro">${esc(intro)}</p>`:''}<div class="v430-form-sheet__body">${body}</div><footer class="v430-sheet-footer" data-ds-component="DS v2 / Sticky Footer" data-figma-node="549:927"><button type="button" class="button button--primary" ${saveAttr} data-ds-component="VButton">${esc(saveLabel)}</button></footer></section></div>`;
  const confirmSheet=({title,desc,body,confirmLabel,confirmAttr,closeAttr})=>`<div class="sheet-backdrop ds24-overlay v430-confirm-overlay"><div class="v430-confirm-backdrop" ${closeAttr}></div><section class="ds24-confirmation v430-confirmation" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${body}<div class="ds24-confirmation__actions"><button type="button" class="ds24-button ds24-button--secondary" ${closeAttr} data-ds-component="VButton">Quay lại</button><button type="button" class="ds24-button ds24-button--primary" ${confirmAttr} data-ds-component="VButton">${esc(confirmLabel)}</button></div></section></div>`;

  // ------------------------------------------------------------------
  // SCR-008 — only remove architecture copy and show warehouse disabled.
  // ------------------------------------------------------------------
// ------------------------------------------------------------------
  // BJ03
  // ------------------------------------------------------------------
  let basisSheetGroup=null, taxMode='INCLUDED', directSourceType='SUPPLIER_CONFIRMED_PRICE';
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const selectedGroups=(r=val03Current())=>pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));
  const isQuick=r=>r.v313EntryType==='QUICK'||r.id==='VAL03-R2'||r.id==='VAL03-R3';
  const groupState=(r,g)=>{const st=val03EvidenceState(g);if(st==='READY')return 'READY';if(st==='CONFLICT')return isQuick(r)?'DIRECT_CONFLICT':'COMMERCIAL_CONFLICT';return isQuick(r)?'DIRECT_MISSING':'COMMERCIAL_MISSING';};
  const selectGroup=(g,on)=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});
  const actualUnit=g=>Number(val03Calc(g)?.unitActual||0);
  const breakdown=g=>{const s=val03Source(g),c=val03Calc(g);if(!s||!c)return '';const purchase=Number(s.unitPrice||0)*Number(s.fxRate||1);return keys(`${ds24KeyValueRow('Giá mua',`${money(purchase)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế/phí tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(c.unitActual)}/${g.uom}`,true)}`);};
  const sourceTypeLabel=t=>t==='ACCOUNTING_DIRECT_BASIS'?'Kế toán xác lập trực tiếp':'Giá do nhà cung cấp xác nhận';
  function groupHtml(r,g){
    const st=groupState(r,g),selected=selectedGroups(r).includes(g),pending=qty(g),base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g),unit=actualUnit(g),subtitle=`${base} · ${money(unit)}/${g.uom}`;
      return `<section class="v460-task ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v460-val03-select="${g.id}"`})}${selected?`<div class="v460-task__detail">${flat('Căn cứ đang dùng',ds24InfoRow('Nguồn',s?.label||'—'))}${breakdown(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu nguồn mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v460-task">${context(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Công việc sẽ cập nhật khi nguồn mua có thẩm quyền cung cấp đủ giá trị.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v460-task">${context(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Nhập nhanh có thể lập căn cứ VND trực tiếp khi chưa có chứng từ mua cấu trúc.</p>${button('Thêm căn cứ giá',`data-v460-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  function sourceChoices(){
    const item=(id,label,desc)=>`<button type="button" class="v460-choice ${directSourceType===id?'is-selected':''}" data-v460-source-type="${id}" data-ds-component="VRadio" data-figma-node="522:7410" aria-pressed="${directSourceType===id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(label)}</strong><small>${esc(desc)}</small></span></button>`;
    return `<div class="v460-field-group"><span class="v460-field-label">Loại nguồn <b>*</b></span><div class="v460-choice-list">${item('SUPPLIER_CONFIRMED_PRICE','Giá do nhà cung cấp xác nhận','Dùng khi nhà cung cấp đã xác nhận đơn giá của hàng nhận.')}${item('ACCOUNTING_DIRECT_BASIS','Kế toán xác lập trực tiếp','Dùng khi kế toán có căn cứ hợp lệ để xác lập giá trước khi có nguồn mua cấu trúc.')}</div></div>`;
  }
  function basisForm(g){
    const body=`${moneyField('Đơn giá mua',`data-v460-basis-price min="0" step="1"`,'',`VND / ${g.uom}`,true)}<div class="v430-field" data-ds-component="VSegmentedControl" data-figma-node="1049:9598"><span>Cách hiểu giá</span><div class="v430-segment"><button type="button" class="${taxMode==='INCLUDED'?'is-selected':''}" data-v460-tax-mode="INCLUDED">Đã gồm thuế</button><button type="button" class="${taxMode==='EXCLUDED'?'is-selected':''}" data-v460-tax-mode="EXCLUDED">Chưa gồm thuế</button></div></div><div data-v460-tax-wrap ${taxMode==='EXCLUDED'?'':'hidden'}>${moneyField('Thuế trên căn cứ','data-v460-basis-tax min="0" step="1"','0','Hệ thống áp chính sách thuế để xác định phần được tính vào giá trị.')}</div>${sourceChoices()}${textField('Ngày căn cứ','data-v460-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"','28/09/2026','',true)}${textField('Tham chiếu / bằng chứng','data-v460-basis-ref placeholder="Mã báo giá, email, ghi chú..."')}${textarea('Lý do xác lập trực tiếp','data-v460-basis-reason placeholder="Nêu ngắn gọn lý do"','','Bắt buộc khi chưa có nguồn mua cấu trúc.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Căn cứ trực tiếp dùng VND và phải có nguồn, ngày hiệu lực, lý do rõ ràng.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v460-val03-sheet="save"',closeAttr:'data-v460-val03-sheet="close"'});
  }
  function setError(root,sel,msg){const input=root.querySelector(sel),field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function saveBasis(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const price=Number(root.querySelector('[data-v460-basis-price]')?.value||0),date=String(root.querySelector('[data-v460-basis-date]')?.value||'').trim(),ref=String(root.querySelector('[data-v460-basis-ref]')?.value||'').trim(),reason=String(root.querySelector('[data-v460-basis-reason]')?.value||'').trim(),tax=taxMode==='EXCLUDED'?Number(root.querySelector('[data-v460-basis-tax]')?.value||0):0;
    const errs=[];if(!(price>0))errs.push(setError(root,'[data-v460-basis-price]','Nhập đơn giá lớn hơn 0.'));if(!date)errs.push(setError(root,'[data-v460-basis-date]','Nhập ngày căn cứ.'));if(!/^\d{2}\/\d{2}\/\d{4}$/.test(date))errs.push(setError(root,'[data-v460-basis-date]','Dùng định dạng dd/mm/yyyy.'));if(!reason)errs.push(setError(root,'[data-v460-basis-reason]','Nêu lý do xác lập trực tiếp.'));const first=errs.find(Boolean);if(first){first.focus();return false;}
    const label=sourceTypeLabel(directSourceType),id=`DIRECT-${g.id}-${Date.now()}`,components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:label,version:date,amount:price}];if(tax)components.push({type:'SOURCE_TAX',label:'Thuế trên căn cứ',source:label,version:date,amount:tax});
    g.sources=[{id,label:`${label} · ${date}`,sourceAuthorityType:directSourceType,version:'v1',basisVersion:1,basisHash:`v460-${id}`,authoritativeValueHash:`v460-${price+tax}`,unitPrice:price,currency:'VND',fxRate:1,fxLabel:'VND',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:tax,components,evidenceRefs:ref?[ref]:[],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:reason,taxMode,sourceDate:date,reference:ref}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;selectGroup(g,true);return true;
  }
  function canReview03(r=val03Current()){const a=selectedGroups(r);return a.length>0&&a.every(g=>groupState(r,g)==='READY');}
  function render015(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const groups=pendingGroups(r).map(g=>groupHtml(r,g)).join(''),selected=selectedGroups(r),total=selected.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),summary=selected.length?keys(`${ds24KeyValueRow(`${selected.length} sản phẩm đã chọn`,money(total),true)}`,'v460-selection-summary'):'';
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`,isQuick(r)?'Nhập nhanh':'Theo chứng từ','Neutral')}${groups||ioEmpty('Không còn hàng chờ giá trị','Các dòng thuộc phiếu nhận này đã được xử lý.')}${summary}${basisSheetGroup?basisForm((r.groups||[]).find(g=>g.id===basisSheetGroup)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v460-val03-review',!canReview03(r))});
  }
  function render017(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận.')}${context(r.receipt,r.supplier)}`,actions:primaryFooter('Kiểm tra lại','data-v460-val03-back')});
    const groups=selectedGroups(r),total=groups.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),items=groups.map(g=>{const c=val03Calc(g),s=val03Source(g);return `<section class="v460-review-item">${row({title:g.name,subtitle:`${c.qty} ${g.uom} · ${money(c.unitActual)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(c.value)}</strong>`,leading:null,type:'Status',interactive:false})}<details class="v430-details v460-details"><summary>Chi tiết căn cứ</summary><div class="v430-details__body">${flat('',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div></details></section>`;}).join('');
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`)}${ds24SummaryCard('Tổng giá trị sẽ ghi',`${money(total)} · ${groups.length} sản phẩm`,'data-ds-prop-tone="Neutral"')}${heading('Sản phẩm sẽ ghi',`${groups.length} sản phẩm`)}<div class="v460-review-list">${items}</div>${linkButton('Chỉnh sửa căn cứ','data-v460-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v460-val03-confirm')});
  }
  function render019(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,groups:[],totalValue:0};if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v460-val03-result-back')});
    const detail=(res.groups||[]).map(g=>row({title:g.name,subtitle:`${g.qty} ${g.uom} · ${money(g.unitInitial)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(g.value)}</strong>`,leading:null,type:'Status',interactive:false})).join(''),remaining=pendingGroups(val03Current()).length,summary=flat('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt||'—')}${ds24InfoRow('Sản phẩm đã xác lập',String((res.groups||[]).length))}${ds24KeyValueRow('Tổng giá trị đã ghi',money(res.totalValue||0),true)}${ds24InfoRow('Giá vốn','Cần cập nhật')}`),details=detail?`<details class="v430-details v460-details"><summary>Xem chi tiết ${(res.groups||[]).length} sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detail}</section></div></details>`:'';
    const body=`<div class="io-result">${resultHero('Đã ghi giá trị nhập ban đầu','Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} sản phẩm/dòng còn cần xử lý.`):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v460-val03-result-back':'data-v460-val03-result-list')});
  }

  // ------------------------------------------------------------------
  // BJ13
  // ------------------------------------------------------------------
  let confirm13=false,detail13=false;
  const eligibleMethods=t=>(t.allowedMethods||[]).filter(m=>window.val13V398?.methodEligible?window.val13V398.methodEligible(t,m.id):true);
  const methodLabel=(t,id=t.selectedMethod)=>eligibleMethods(t).find(m=>m.id===id)?.label||(t.allowedMethods||[]).find(m=>m.id===id)?.label||'—';
  const selectedTargets13=t=>(t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'||x.selected);
  function allocationRows13(t){const rows=val13Preview(t),sum=rows.reduce((n,x)=>n+Number(x.allocationMetric?.metricValue||0),0);return rows.map(x=>{const metric=Number(x.allocationMetric?.metricValue||0),metricText=t.selectedMethod==='FIXTURE_VALUE'?`${money(metric)} · ${pct(sum?metric/sum:0)}`:`${metric.toLocaleString('vi-VN')} ${x.allocationMetric?.unit||''} · ${pct(sum?metric/sum:0)}`;return `<div class="v460-allocation-row" data-composed-from="VText,DS v2 / Key-value Row"><div><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small><small>Căn cứ phân bổ: ${esc(metricText)}</small></div><strong>${esc(signed(x.allocatedAmount))}</strong></div>`;}).join('');}
  function methodControl13(t){const methods=eligibleMethods(t);if(methods.length<=1){const m=methods[0];if(!m)return flat('Cách phân bổ',ds24InfoRow('Phương pháp','Chưa có phương pháp hợp lệ'),'v460-method-readonly');const desc=m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm, trước các điều chỉnh phát sinh sau đó.':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị và có thể so sánh.';return `<section class="v460-methods v460-method-readonly">${heading('Cách phân bổ')}<div class="v460-method-summary" data-composed-from="VText,DS v2 / Summary Card"><strong>${esc(m.label)}</strong><span>${esc(desc)}</span></div></section>`;}return `<section class="v460-methods">${heading('Cách phân bổ')}<div class="v460-choice-list">${methods.map(m=>`<button type="button" class="v460-choice ${t.selectedMethod===m.id?'is-selected':''}" data-v460-val13-method="${m.id}" data-ds-component="VRadio" aria-pressed="${t.selectedMethod===m.id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(m.label)}</strong><small>${m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị'}</small></span></button>`).join('')}</div></section>`;}
  function period13(t){const targets=selectedTargets13(t),posting=[...new Set(targets.map(x=>x.postingPeriod).filter(Boolean))],original=[...new Set(targets.map(x=>x.originalPeriod).filter(Boolean))],moved=targets.some(x=>x.originalPeriod&&x.postingPeriod&&x.originalPeriod!==x.postingPeriod);if(!posting.length)return '';if(!moved&&posting.length===1)return flat('Kỳ ghi nhận',ds24InfoRow('Kỳ ghi điều chỉnh',posting[0]));const originalLabel=original.join(', ')||'—',postingLabel=posting.join(', ')||'—';return `${vBanner('info','Kỳ của hàng gốc đã khóa',`Điều chỉnh được ghi ở kỳ ${postingLabel}; kỳ ${originalLabel} vẫn được giữ để truy vết.`)}${flat('Kỳ ghi nhận',`${ds24InfoRow('Kỳ của hàng gốc',originalLabel)}${ds24InfoRow('Kỳ ghi điều chỉnh',postingLabel)}`)}`;}
  function render086(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();if(state==='LOADING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ điều chỉnh giá trị',body:deniedBody(),centered:true});if(t.status==='WAITING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ nguồn hoàn tất dữ liệu cần thiết.')}${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}`});
    const methods=eligibleMethods(t);if(methods.length===1&&t.selectedMethod!==methods[0].id){t.selectedMethod=methods[0].id;val13PreviewHash=null;}const preview=val13Preview(t),total=preview.reduce((n,x)=>n+Number(x.allocatedAmount||0),0),targets=(t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:'',leading:null,type:'Status',interactive:false})).join(''),valid=val13CanPreview(t)&&preview.length>0;
    const source=`${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keys(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true))}`;
    const allocation=valid?`${heading('Kết quả phân bổ',`${preview.length} sản phẩm`)}<section class="v460-allocation-list">${allocationRows13(t)}${ds24KeyValueRow('Tổng phân bổ',signed(total),true)}</section>`:vBanner('warning','Chưa có phương pháp phân bổ hợp lệ','Cần metric hợp lệ và so sánh được trên toàn phạm vi; hệ thống không tự chia đều.');
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Kiểm tra lại dữ liệu hiện hành trước khi ghi.'):''}${source}${heading('Phạm vi áp dụng','Theo nguồn xác định')}<section class="ds24-list-stack v430-list">${targets}</section>${methodControl13(t)}${allocation}${period13(t)}${confirm13?confirmSheet({title:'Ghi điều chỉnh giá trị?',desc:'Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi.',body:flat('Xác nhận',`${ds24InfoRow('Nguồn',t.sourceRef.replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm',String(preview.length))}${ds24InfoRow('Cách phân bổ',methodLabel(t))}${ds24InfoRow('Kỳ ghi nhận',[...new Set(preview.map(x=>x.postingPeriod))].join(', ')||'—')}${ds24KeyValueRow('Tổng điều chỉnh',signed(total),true)}`),confirmLabel:'Ghi điều chỉnh',confirmAttr:'data-v460-val13-confirm',closeAttr:'data-v460-val13-confirm-close'}):''}`;
    return appShell({title:'Phân bổ điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v460-val13-open-confirm',!valid)});
  }
  function render089(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const t=val13Current(),res=val13LastResult||val13Result();if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||t.operationId)}" data-scope="${escapeAttribute(t.sourceComponentKey||t.id)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không ghi lại adjustment. Chuyển đúng thao tác này sang xác minh.',[['Nguồn',t.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh','Không có thay đổi giá trị.',[['Nguồn',t.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v460-val13-back')});
    const allocations=res.allocations||[],periods=[...new Set(allocations.map(x=>x.postingPeriod).filter(Boolean))],detailRows=allocations.map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}`,trailing:`<strong class="v460-money-trailing">${signed(x.allocatedAmount)}</strong>`,leading:null,type:'Status',interactive:false})).join('');
    const summary=flat('Kết quả',`${ds24InfoRow('Nguồn',String(res.sourceRef||t.sourceRef).replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm bị ảnh hưởng',String(allocations.length))}${ds24InfoRow('Kỳ ghi nhận',periods.join(', ')||'—')}${ds24InfoRow('Giá vốn','Cần cập nhật')}${ds24KeyValueRow('Tổng điều chỉnh',signed(res.normalizedAmount??t.normalizedAmount),true)}`),details=detailRows?`<details class="v430-details v460-details" ${detail13?'open':''}><summary>Xem chi tiết phân bổ (${allocations.length})</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detailRows}</section></div></details>`:'';
    const title=Number(res.normalizedAmount??t.normalizedAmount)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập';return appShell({title:'Kết quả điều chỉnh giá trị',body:`<div class="io-result">${resultHero(title,'Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}</div>`,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v460-val13-list')});
  }

  // ------------------------------------------------------------------
  // BJ14
  // ------------------------------------------------------------------
  const COST_POLICY={version:'COST-POLICY-v460',method:'PERIODIC',label:'Bình quân cuối kỳ',periodCloseScopes:[{id:'ALL_PRODUCTS',label:'Toàn bộ sản phẩm'},{id:'DIRTY_PRODUCTS_ONLY',label:'Sản phẩm cần tính lại'}]};
  let mode14='RESULT',publish14=false,compare14=false,productDetail14=false;
  window.__VET45_TENANT_COST_POLICY_V460__=COST_POLICY;
  function applyPolicy(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod=COST_POLICY.method;r.policyLabel=COST_POLICY.label;r.policyVersion=COST_POLICY.version;return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(applyPolicy);
  const baseCreate14=val14CreateRun;
  val14CreateRun=function(){const r=baseCreate14();applyPolicy(r);return r;};
  const scopeLabel14=r=>r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;
  const methodResult=r=>r.policyMethod==='MOVING'?(r.moving||{}):(r.periodic||{});
  const compareResult=r=>r.policyMethod==='MOVING'?(r.periodic||{}):(r.moving||{});
  const compareLabel=r=>r.policyMethod==='MOVING'?'Bình quân cuối kỳ':'Bình quân liên hoàn';
  const policy14=r=>flat('Phương pháp',`${ds24InfoRow('Phương pháp áp dụng',r.policyLabel)}${ds24InfoRow('Chính sách','Theo chính sách của tổ chức')}`,'v460-policy');
  function setup14(r){const dirty=mode14==='DIRTY_SETUP',period=dirty?(r.postingPeriod||r.period):val14SetupPeriod;if(dirty)return `${flat('Phạm vi cần cập nhật',`${ds24InfoRow('Kỳ ghi nhận',period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}`)}${policy14(r)}`;const periodField=selectField('Kỳ','data-v460-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`),scopeOpts=COST_POLICY.periodCloseScopes.map(x=>`<option value="${x.id}" ${(val14SetupScope==='Toàn bộ sản phẩm'&&x.id==='ALL_PRODUCTS')||(val14SetupScope==='Sản phẩm cần tính lại'&&x.id==='DIRTY_PRODUCTS_ONLY')?'selected':''}>${esc(x.label)}</option>`).join(''),scope=COST_POLICY.periodCloseScopes.length===1?flat('Phạm vi',ds24InfoRow('Phạm vi',COST_POLICY.periodCloseScopes[0].label)):selectField('Phạm vi','data-v460-val14-scope',scopeOpts);return `${periodField}${scope}${policy14(r)}`;}
  function results14(r){const x=methodResult(r);return `${ds24SummaryCard('Kết quả sau tính',`${r.policyLabel} · ${scopeLabel14(r)}`,'data-ds-prop-tone="Neutral"')}${keys(`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0),true)}`,'v460-cost-total')}${heading('Thay đổi sẽ ghi khi công bố')}<p class="v460-helper">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`,'v460-cost-delta')}`;}
  function comparison14(r){const x=compareResult(r);return `<details class="v430-details v460-details" ${compare14?'open':''} data-v460-compare><summary>Xem đối chiếu theo ${esc(compareLabel(r))}</summary><div class="v430-details__body">${flat(`${compareLabel(r)} · chỉ đối chiếu`,`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0))}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0))}`)}</div></details>`;}
  function products14(r){const all=r.productResults||[],rows=all.map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?`${money(x.newCost)}/${x.baseUom||'đơn vị cơ sở'}`:'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');if(!rows)return '';return `${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<details class="v430-details v460-details" ${productDetail14?'open':''} data-v460-products><summary>Xem kết quả theo sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${rows}</section></div></details>`;}
  function publishSheet14(r){return confirmSheet({title:'Công bố giá vốn?',desc:'Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',body:`${flat('Phạm vi công bố',`${ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}${ds24InfoRow('Phương pháp',r.policyLabel)}`)}${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`)}`,confirmLabel:'Công bố giá vốn',confirmAttr:'data-v460-val14-publish',closeAttr:'data-v460-val14-publish-close'});}
  function workMeta14(r){applyPolicy(r);if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};return {title:r.label,subtitle:scopeLabel14(r),label:'Đang xử lý',tone:'Neutral'};}
  function render072(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});const rows=val14Runs.filter(r=>r.status!=='PUBLISHED').map(r=>{const m=workMeta14(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v460-val14-run="${r.id}"`});}).join('');return appShell({title:'Công việc giá vốn',body:rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.'),back:false,actions:primaryFooter('Chốt kỳ','data-v460-val14-close-period')});}
  function render074(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=applyPolicy(val14Current());if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${policy14(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v460-val14-successor')});if(mode14==='DIRTY_SETUP'||mode14==='PERIOD_CLOSE_SETUP')return appShell({title:mode14==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:setup14(r),actions:primaryFooter(mode14==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v460-val14-calculate')});if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',scopeLabel14(r)]],'info'),centered:true});if(r.status==='BLOCKED'||state==='BLOCKED'){const blockers=(r.blockers||[]).map(b=>context(b.title,`Đang chờ: ${b.owner}`,'Cần xử lý','Warning')).join('');return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây trước khi công bố.')}${policy14(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<section class="ds24-list-stack v430-list">${blockers}</section>`});}const body=`${policy14(r)}${results14(r)}${comparison14(r)}${products14(r)}${publish14?publishSheet14(r):''}`;return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v460-val14-open-publish',r.status!=='READY_FOR_REVIEW')});}
  function render077(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=applyPolicy(val14Current()),res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,officialCostVersions:(r.productResults||[]).filter(x=>x.state!=='NO_NEW_COST_BASIS'&&x.newCost!==x.oldCost).length};if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả công bố giá vốn',body:ioResult('Chưa công bố giá vốn','Không có điều chỉnh hoặc phiên bản giá vốn mới.',[['Kỳ ghi nhận',res.postingPeriod||r.period],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v460-val14-list')});const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.')}${flat('Kết quả',`${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)}${ds24InfoRow('Phương pháp',res.method||r.policyLabel)}${ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))}${ds24InfoRow('Sản phẩm có giá vốn mới',String(res.officialCostVersions??0))}${ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt||'—')}${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(res.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(res.endingAdjustment||0),true)}`)}</div>`;return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v460-val14-list')});}

  // Retire SCR-088 at runtime and preserve legacy deep links.
  const navParent=navigate;
  navigate=function(screenId){if(activeFlowId==='UIF-13'&&screenId==='SCR-088')screenId='SCR-086';return navParent(screenId);};
  if(activeFlowId==='UIF-13'&&activeScreenId==='SCR-088')activeScreenId='SCR-086';

  Object.assign(renderers,{
    'SCR-015':render015,'SCR-017':render017,'SCR-019':render019,
    'SCR-086':render086,'SCR-087':render086,'SCR-088':function(state){activeScreenId='SCR-086';return render086(state);},'SCR-089':render089,
    'SCR-072':render072,'SCR-073':render074,'SCR-074':render074,'SCR-075':render074,'SCR-076':render074,'SCR-077':render077
  });

  // Unique v4.6 interaction attributes prevent legacy event handlers from firing.
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v460-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v460-val14-scope]')){event.stopImmediatePropagation();val14SetupScope=event.target.value==='DIRTY_PRODUCTS_ONLY'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';return renderAppScreen();}
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v460-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v460Val03Select);if(g&&groupState(val03Current(),g)==='READY')selectGroup(g,!selectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();basisSheetGroup=el.dataset.v460Val03AddBasis;taxMode='INCLUDED';directSourceType='SUPPLIER_CONFIRMED_PRICE';return renderAppScreen();}
      if((el=event.target.closest('[data-v460-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();taxMode=el.dataset.v460TaxMode;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-source-type]'))){event.preventDefault();event.stopImmediatePropagation();directSourceType=el.dataset.v460SourceType;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v460Val03Sheet==='close'){basisSheetGroup=null;return renderAppScreen();}if(el.dataset.v460Val03Sheet==='save'&&saveBasis(basisSheetGroup)){basisSheetGroup=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v460-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!canReview03())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v460-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v460-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v460-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v460-val13-method]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),id=el.dataset.v460Val13Method;if(eligibleMethods(t).some(m=>m.id===id)){t.selectedMethod=id;val13PreviewHash=null;}return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val13-open-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t))return;val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);confirm13=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val13-confirm-close]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){confirm13=false;stateByScreen['SCR-086']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();confirm13=false;stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v460-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v460-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v460-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v460Val14Run;const r=applyPolicy(val14Current());publish14=false;compare14=false;productDetail14=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;mode14='DIRTY_SETUP';}else{mode14='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v460-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope=COST_POLICY.periodCloseScopes[0]?.label||'Toàn bộ sản phẩm';mode14='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v460-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();val14SetupKind=mode14==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();applyPolicy(run);mode14='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v460-compare] summary'))){compare14=!compare14;return;}
      if((el=event.target.closest('[data-v460-products] summary'))){productDetail14=!productDetail14;return;}
      if((el=event.target.closest('[data-v460-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);publish14=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();publish14=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';publish14=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();publish14=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v460-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?'Sản phẩm cần tính lại':'Toàn bộ sản phẩm';mode14=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v460-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();mode14='RESULT';publish14=false;return navigate('SCR-072');}
    }
  },true);

  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version='4.6.0';
  window.__VET45_V460__={version:'4.6.0',parent:'4.5.2',costPolicy:COST_POLICY,activeScreens:{bj03:['SCR-014','SCR-015','SCR-017','SCR-019'],bj13:['SCR-085','SCR-086','SCR-089'],bj14:['SCR-072','SCR-074','SCR-077']},retired:['SCR-088']};
  if(new Set(['UIF-03','UIF-13','UIF-14']).has(activeFlowId)){syncReviewUrl();render();}
})();

/* ===== v461-semantic-correction.js ===== */
/* VET45 Theme 7 v4.6.1 — authority correction + silent-default removal
 * Parent package: v4.6.0
 * Authority: v4.6.1 Decisions/BC/UI contracts + VET45 Figma DS v2.
 * Scope: SCR-008; UIF-03; UIF-13; UIF-14.
 */
(()=>{
  if(typeof renderers==='undefined') return;
  const money=n=>`${Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const signed=n=>`${Number(n||0)>0?'+ ':Number(n||0)<0?'− ':''}${Math.abs(Math.round(Number(n)||0)).toLocaleString('vi-VN')} đ`;
  const pct=n=>`${(Number(n||0)*100).toLocaleString('vi-VN',{maximumFractionDigits:1})}%`;
  const row=args=>ds24ListRow({...args,density:args.density||'Compact'});
  const heading=(t,m='')=>ds24SectionTitle(t,m);
  const flat=(title,rows,extra='')=>`<section class="v430-flat v460-flat ${extra}" data-composed-from="DS v2 / Info Row,DS v2 / Key-value Row">${title?heading(title):''}<div class="v430-flat__rows">${rows}</div></section>`;
  const keys=(rows,extra='')=>`<div class="v430-key-stack v460-key-stack ${extra}" data-composed-from="DS v2 / Key-value Row">${rows}</div>`;
  const context=(title,subtitle,badge='',tone='Neutral')=>row({title,subtitle,trailing:badge?ds24Badge(badge,tone):'',leading:null,type:'Status',interactive:false});
  const button=(label,attrs,kind='primary',disabled=false)=>`<button type="button" class="button button--${kind}" ${attrs} data-ds-component="VButton" data-figma-node="521:529" ${disabled?'disabled':''}>${esc(label)}</button>`;
  const linkButton=(label,attrs)=>`<button type="button" class="v430-link" ${attrs} data-ds-component="DS v2 / Link">${esc(label)}</button>`;
  const textField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextField" data-figma-node="522:7186"><span>${esc(label)}${required?' <b>*</b>':''}</span><input class="v430-control" ${attrs} value="${escapeAttribute(value)}"/>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const moneyField=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span>đ</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const textarea=(label,attrs,value='',helper='',required=false)=>`<label class="v430-field" data-ds-component="VTextarea" data-figma-node="522:7212"><span>${esc(label)}${required?' <b>*</b>':''}</span><textarea class="v430-control v430-textarea" rows="3" ${attrs}>${esc(value)}</textarea>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  const selectField=(label,attrs,options)=>`<label class="v430-field" data-ds-component="VSelect" data-figma-node="522:7291"><span>${esc(label)}</span><select class="v430-control" ${attrs}>${options}</select></label>`;
  const formSheet=({title,intro,body,saveLabel='Lưu',saveAttr,closeAttr})=>`<div class="v430-overlay" data-v461-overlay><div class="v430-overlay__backdrop" ${closeAttr}></div><section class="v430-form-sheet" data-ds-component="DS v2 / Form Sheet" data-figma-node="1353:6355" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="v430-sheet-handle-area"><div class="v430-sheet-handle"></div></div><header class="v430-sheet-header"><h2>${esc(title)}</h2><button type="button" class="v430-sheet-close" ${closeAttr} aria-label="Đóng" data-ds-component="DS v2 / Icon Button" data-figma-node="4431:10317">${icon('close','icon--sm')}</button></header>${intro?`<p class="v430-sheet-intro">${esc(intro)}</p>`:''}<div class="v430-form-sheet__body">${body}</div><footer class="v430-sheet-footer" data-ds-component="DS v2 / Sticky Footer" data-figma-node="549:927"><button type="button" class="button button--primary" ${saveAttr} data-ds-component="VButton">${esc(saveLabel)}</button></footer></section></div>`;
  const confirmSheet=({title,desc,body,confirmLabel,confirmAttr,closeAttr})=>`<div class="sheet-backdrop ds24-overlay v430-confirm-overlay"><div class="v430-confirm-backdrop" ${closeAttr}></div><section class="ds24-confirmation v430-confirmation" data-ds-component="DS v2 / Confirmation Sheet" data-figma-node="550:1058" role="dialog" aria-modal="true" aria-label="${escapeAttribute(title)}"><div class="ds24-confirmation__handle"></div><h3 class="vet45-text-style-4">${esc(title)}</h3><p class="vet45-text-style-6">${esc(desc)}</p>${body}<div class="ds24-confirmation__actions"><button type="button" class="ds24-button ds24-button--secondary" ${closeAttr} data-ds-component="VButton">Quay lại</button><button type="button" class="ds24-button ds24-button--primary" ${confirmAttr} data-ds-component="VButton">${esc(confirmLabel)}</button></div></section></div>`;

  // ------------------------------------------------------------------
  // SCR-008 — only remove architecture copy and show warehouse disabled.
  // ------------------------------------------------------------------
// ------------------------------------------------------------------
  // BJ03
  // ------------------------------------------------------------------
  let basisSheetGroup=null, basisDraft=null;
  const qty=g=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).reduce((n,s)=>n+Number(s.pendingQty||0),0);
  const pendingGroups=r=>(r.groups||[]).filter(g=>qty(g)>0);
  const selectedGroups=(r=val03Current())=>pendingGroups(r).filter(g=>(g.slices||[]).some(s=>s.selected&&Number(s.pendingQty||0)>0));
  const isQuick=r=>r.v313EntryType==='QUICK'||r.id==='VAL03-R2'||r.id==='VAL03-R3';
  const groupState=(r,g)=>{const st=val03EvidenceState(g);if(st==='READY')return 'READY';if(st==='CONFLICT')return isQuick(r)?'DIRECT_CONFLICT':'COMMERCIAL_CONFLICT';return isQuick(r)?'DIRECT_MISSING':'COMMERCIAL_MISSING';};
  const selectGroup=(g,on)=>(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).forEach(s=>{s.selected=on;s.selectedQty=s.pendingQty;s.partialOpen=false;});
  const actualUnit=g=>Number(val03Calc(g)?.unitActual||0);
  const breakdown=g=>{const s=val03Source(g),c=val03Calc(g);if(!s||!c)return '';const purchase=Number(s.unitPrice||0)*Number(s.fxRate||1);return keys(`${ds24KeyValueRow('Giá mua',`${money(purchase)}/${g.uom}`)}${s.unitLineDiscount?ds24KeyValueRow('Chiết khấu dòng',`− ${money(s.unitLineDiscount)}/${g.uom}`):''}${s.unitDocDiscount?ds24KeyValueRow('Chiết khấu chứng từ',`− ${money(s.unitDocDiscount)}/${g.uom}`):''}${s.unitKnownCost?ds24KeyValueRow('Chi phí mua đã biết',`+ ${money(s.unitKnownCost)}/${g.uom}`):''}${s.unitNonDeductibleVat?ds24KeyValueRow('Thuế/phí tính vào giá trị',`+ ${money(s.unitNonDeductibleVat)}/${g.uom}`):''}${ds24KeyValueRow('Đơn giá ghi nhận ban đầu',`${money(c.unitActual)}/${g.uom}`,true)}`);};
  function groupHtml(r,g){
    const st=groupState(r,g),selected=selectedGroups(r).includes(g),pending=qty(g),base=`${pending} ${g.uom} đang chờ${g.tracking==='LOT'?` · ${(g.slices||[]).filter(s=>Number(s.pendingQty||0)>0).length} lô`:''}`;
    if(st==='READY'){
      const s=val03Source(g),unit=actualUnit(g),subtitle=`${base} · ${money(unit)}/${g.uom}`;
      return `<section class="v460-task ${selected?'is-selected':''}">${row({title:g.name,subtitle,trailing:selected?icon('checkCircle','icon--sm'):'',leading:null,type:'Selection',state:selected?'Selected':'Default',attrs:`data-v461-val03-select="${g.id}"`})}${selected?`<div class="v460-task__detail">${flat('Căn cứ đang dùng',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div>`:''}</section>`;
    }
    if(st==='COMMERCIAL_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần đối chiếu','Warning')}<div class="v430-support">${vBanner('warning','Căn cứ mua hàng đang mâu thuẫn','Đối chiếu nguồn mua có thẩm quyền trước khi xác lập giá trị.')}</div></section>`;
    if(st==='COMMERCIAL_MISSING')return `<section class="v460-task">${context(g.name,base,'Cần căn cứ','Warning')}<div class="v430-support">${vBanner('warning','Chưa đủ căn cứ mua hàng','Công việc sẽ cập nhật khi nguồn mua có thẩm quyền cung cấp đủ giá trị.')}</div></section>`;
    if(st==='DIRECT_MISSING')return `<section class="v460-task">${context(g.name,base,'Chưa có căn cứ','Neutral')}<div class="v430-support"><p class="v430-helper">Chưa có nguồn mua cấu trúc đủ dùng. Kế toán có thể lập căn cứ trực tiếp khi có đủ thông tin và bằng chứng.</p>${button('Thêm căn cứ giá',`data-v461-val03-add-basis="${g.id}"`,'secondary')}</div></section>`;
    if(st==='DIRECT_CONFLICT')return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}<div class="v430-support">${vBanner('warning','Có nhiều căn cứ trực tiếp cần kiểm tra','Chỉ tiếp tục khi căn cứ sử dụng đã được xác định theo policy và có dấu vết rõ ràng.')}</div></section>`;
    return `<section class="v460-task">${context(g.name,base,'Cần kiểm tra','Warning')}</section>`;
  }
  const currencyCatalog=()=>window.__VET45_MONEY_CURRENCY_CATALOG__||[];
  const taxPolicy=()=>window.__VET45_TAX_TREATMENT_POLICY__||{recoverableRate:0,version:'UNSET'};
  const fxFor=currency=>window.__VET45_FX_SOURCE_FIXTURE__?.[currency]||null;
  function ensureBasisDraft(){if(!basisDraft)basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return basisDraft;}
  function amountField(label,attrs,value='',helper='',required=false,currency=''){
    return `<label class="v430-field" data-ds-component="VMoneyField" data-figma-node="522:7322"><span>${esc(label)}${required?' <b>*</b>':''}</span><div class="v430-money"><input class="v430-control" inputmode="decimal" type="number" ${attrs} value="${escapeAttribute(value)}"/><span data-v461-currency-suffix>${esc(currency||'—')}</span></div>${helper?`<small>${esc(helper)}</small>`:''}<small class="v430-field-error" hidden></small></label>`;
  }
  function taxChoice(){const d=ensureBasisDraft();const item=(id,label,desc)=>`<button type="button" class="v460-choice ${d.taxMode===id?'is-selected':''}" data-v461-tax-mode="${id}" data-ds-component="VRadio" data-figma-node="522:7410" aria-pressed="${d.taxMode===id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(label)}</strong><small>${esc(desc)}</small></span></button>`;return `<div class="v460-field-group"><span class="v460-field-label">Cách hiểu giá <b>*</b></span><div class="v460-choice-list">${item('INCLUDED','Đã gồm thuế','Đơn giá trên căn cứ đã bao gồm phần thuế của nguồn.')}${item('EXCLUDED','Chưa gồm thuế','Đơn giá trên căn cứ chưa bao gồm phần thuế của nguồn.')}</div><small class="v430-field-error" data-v461-taxmode-error hidden></small></div>`;}
  function basisForm(g){
    const d=ensureBasisDraft(), opts=[`<option value="">Chọn tiền tệ</option>`,...currencyCatalog().map(x=>`<option value="${escapeAttribute(x.id)}" ${d.currency===x.id?'selected':''}>${esc(x.label)}</option>`)].join('');
    const body=`${selectField('Tiền tệ *','data-v461-basis-currency',opts)}${amountField('Đơn giá mua','data-v461-basis-price min="0" step="0.01"',d.price,`Theo đơn vị ${g.uom}`,true,d.currency)}${taxChoice()}<div data-v461-tax-wrap ${d.taxMode==='EXCLUDED'?'':'hidden'}>${amountField('Thuế trên căn cứ','data-v461-basis-tax min="0" step="0.01"',d.tax,'Nhập số thuế ghi trên căn cứ nếu có; hệ thống áp chính sách thuế để xác định phần đi vào giá trị.',false,d.currency)}</div>${textField('Căn cứ giá từ đâu?','data-v461-basis-source placeholder="Ví dụ: Báo giá hoặc xác nhận giá của nhà cung cấp"',d.source,'Ghi nguồn nghiệp vụ tạo ra đơn giá, không phải tên tệp.',true)}${textField('Ngày căn cứ','data-v461-basis-date inputmode="numeric" placeholder="dd/mm/yyyy"',d.date,'',true)}${textField('Tham chiếu / bằng chứng','data-v461-basis-ref placeholder="Mã báo giá, email, ghi chú..."',d.ref)}${textarea('Lý do xác lập trực tiếp','data-v461-basis-reason placeholder="Nêu ngắn gọn lý do"',d.reason,'Bắt buộc vì chưa có nguồn mua cấu trúc đủ dùng.',true)}`;
    return formSheet({title:'Thêm căn cứ giá',intro:`${g.name} · Ghi đơn giá, tiền tệ, nguồn và ngày căn cứ.`,body,saveLabel:'Lưu căn cứ',saveAttr:'data-v461-val03-sheet="save"',closeAttr:'data-v461-val03-sheet="close"'});
  }
  function setError(root,sel,msg){const input=root.querySelector(sel),field=input?.closest('.v430-field');if(!input||!field)return null;input.classList.add('is-error');const e=field.querySelector('.v430-field-error');if(e){e.textContent=msg;e.hidden=false;}return input;}
  function syncBasisDraft(root){const d=ensureBasisDraft();d.price=String(root.querySelector('[data-v461-basis-price]')?.value||'');d.currency=String(root.querySelector('[data-v461-basis-currency]')?.value||'');d.tax=String(root.querySelector('[data-v461-basis-tax]')?.value||'');d.source=String(root.querySelector('[data-v461-basis-source]')?.value||'').trim();d.date=String(root.querySelector('[data-v461-basis-date]')?.value||'').trim();d.ref=String(root.querySelector('[data-v461-basis-ref]')?.value||'').trim();d.reason=String(root.querySelector('[data-v461-basis-reason]')?.value||'').trim();return d;}
  function saveBasis(groupId){
    const r=val03Current(),g=(r.groups||[]).find(x=>x.id===groupId),root=document.querySelector('.v430-form-sheet');if(!g||!root)return false;
    root.querySelectorAll('.is-error').forEach(x=>x.classList.remove('is-error'));root.querySelectorAll('.v430-field-error').forEach(x=>{x.hidden=true;x.textContent='';});
    const d=syncBasisDraft(root), price=Number(d.price||0), taxSource=d.taxMode==='EXCLUDED'?Number(d.tax||0):0, errs=[];
    if(!d.currency)errs.push(setError(root,'[data-v461-basis-currency]','Chọn tiền tệ.'));
    if(!(price>0))errs.push(setError(root,'[data-v461-basis-price]','Nhập đơn giá lớn hơn 0.'));
    if(!d.taxMode){const e=root.querySelector('[data-v461-taxmode-error]');if(e){e.textContent='Chọn cách hiểu giá.';e.hidden=false;}errs.push(root.querySelector('[data-v461-tax-mode]'));}
    if(!d.source)errs.push(setError(root,'[data-v461-basis-source]','Nhập căn cứ giá.'));
    if(!d.date)errs.push(setError(root,'[data-v461-basis-date]','Nhập ngày căn cứ.'));
    else if(!/^\d{2}\/\d{2}\/\d{4}$/.test(d.date))errs.push(setError(root,'[data-v461-basis-date]','Dùng định dạng dd/mm/yyyy.'));
    if(!d.reason)errs.push(setError(root,'[data-v461-basis-reason]','Nêu lý do xác lập trực tiếp.'));
    const fx=fxFor(d.currency);if(d.currency&&!fx)errs.push(setError(root,'[data-v461-basis-currency]','Chưa có dữ liệu quy đổi có thẩm quyền cho tiền tệ này.'));
    const first=errs.find(Boolean);if(first){first.focus?.();return false;}
    const recoverable=Math.max(0,Math.min(1,Number(taxPolicy().recoverableRate||0))), fxRate=Number(fx.rate||1), nonRecoverableTax=Math.round(taxSource*fxRate*(1-recoverable));
    const id=`DIRECT-${g.id}-${Date.now()}`, components=[{type:'PURCHASE_PRICE',label:'Giá mua',source:d.source,version:d.date,amount:price,currency:d.currency}];
    if(taxSource)components.push({type:'SOURCE_TAX',label:'Thuế trên căn cứ',source:d.source,version:d.date,amount:taxSource,currency:d.currency,taxPolicyVersion:taxPolicy().version,nonRecoverableAmountVnd:nonRecoverableTax});
    g.sources=[{id,label:`${d.source} · ${d.date}`,sourceAuthorityLabel:d.source,version:'v1',basisVersion:1,basisHash:`v461-${id}`,authoritativeValueHash:`v461-${Math.round(price*fxRate)+nonRecoverableTax}`,unitPrice:price,currency:d.currency,fxRate,fxSourceVersion:fx.version,fxLabel:'INTERNAL',unitLineDiscount:0,unitDocDiscount:0,unitKnownCost:0,unitNonDeductibleVat:nonRecoverableTax,components,evidenceRefs:d.ref?[d.ref]:[],provenance:components.map(c=>`${c.label} · ${c.source}`),directReason:d.reason,taxMode:d.taxMode,sourceDate:d.date,reference:d.ref,taxPolicyVersion:taxPolicy().version}];
    g.selectedSource=id;r.sourceVersion=Number(r.sourceVersion||0)+1;selectGroup(g,true);return true;
  }
  function canReview03(r=val03Current()){const a=selectedGroups(r);return a.length>0&&a.every(g=>groupState(r,g)==='READY');}
  function render015(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-015'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Xác lập giá trị nhập ban đầu',body:deniedBody(),centered:true});
    const groups=pendingGroups(r).map(g=>groupHtml(r,g)).join(''),selected=selectedGroups(r),total=selected.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),summary=selected.length?keys(`${ds24KeyValueRow(`${selected.length} sản phẩm đã chọn`,money(total),true)}`,'v460-selection-summary'):'';
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`,isQuick(r)?'Nhập nhanh':'Theo chứng từ','Neutral')}${groups||ioEmpty('Không còn hàng chờ giá trị','Các dòng thuộc phiếu nhận này đã được xử lý.')}${summary}${basisSheetGroup?basisForm((r.groups||[]).find(g=>g.id===basisSheetGroup)):''}`;
    return appShell({title:'Xác lập giá trị nhập ban đầu',body,actions:primaryFooter('Rà soát','data-v461-val03-review',!canReview03(r))});
  }
  function render017(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-017'),state);const r=val03Current();if(state==='PERMISSION_DENIED')return appShell({title:'Rà soát giá trị nhập ban đầu',body:deniedBody(),centered:true});const stale=state==='SOURCE_CHANGED'||val03ReviewSourceVersion==null||Number(val03ReviewSourceVersion)!==Number(r.sourceVersion);if(stale)return appShell({title:'Rà soát giá trị nhập ban đầu',body:`${vBanner('warning','Căn cứ đã thay đổi','Quay lại kiểm tra dữ liệu hiện hành trước khi xác nhận.')}${context(r.receipt,r.supplier)}`,actions:primaryFooter('Kiểm tra lại','data-v461-val03-back')});
    const groups=selectedGroups(r),total=groups.reduce((n,g)=>n+Number(val03Calc(g)?.value||0),0),items=groups.map(g=>{const c=val03Calc(g),s=val03Source(g);return `<section class="v460-review-item">${row({title:g.name,subtitle:`${c.qty} ${g.uom} · ${money(c.unitActual)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(c.value)}</strong>`,leading:null,type:'Status',interactive:false})}<details class="v430-details v460-details"><summary>Chi tiết căn cứ</summary><div class="v430-details__body">${flat('',ds24InfoRow('Căn cứ',s?.label||'—'))}${breakdown(g)}</div></details></section>`;}).join('');
    const body=`${context(r.receipt,`${r.supplier} · ${r.receivedAt}`)}${ds24SummaryCard('Tổng giá trị sẽ ghi',`${money(total)} · ${groups.length} sản phẩm`,'data-ds-prop-tone="Neutral"')}${heading('Sản phẩm sẽ ghi',`${groups.length} sản phẩm`)}<div class="v460-review-list">${items}</div>${linkButton('Chỉnh sửa căn cứ','data-v461-val03-back')}`;
    return appShell({title:'Rà soát giá trị nhập ban đầu',body,actions:primaryFooter('Xác nhận giá trị','data-v461-val03-confirm')});
  }
  function render019(state){
    if(activeFlowId!=='UIF-03')return renderGeneric(screens.find(s=>s.id==='SCR-019'),state);const res=val03LastResult||{receipt:val03Current().receipt,groups:[],totalValue:0};if(state==='PROCESSING')return appShell({title:'Kết quả xác lập giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-03" data-operation="${escapeAttribute(res.operationId||'VAL-UNKNOWN')}" data-scope="${escapeAttribute(res.receipt||'')}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá trị đã được ghi hay chưa','Không gửi lại lệnh xác nhận. Chuyển đúng lần xử lý này sang xác minh kết quả.',[['Phiếu nhận',res.receipt],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả xác lập giá trị',body:ioResult('Chưa ghi giá trị nhập ban đầu','Không có thay đổi. Kiểm tra lại căn cứ hiện hành.',[['Phiếu nhận',res.receipt],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại công việc','data-v461-val03-result-back')});
    const detail=(res.groups||[]).map(g=>row({title:g.name,subtitle:`${g.qty} ${g.uom} · ${money(g.unitInitial)}/${g.uom}`,trailing:`<strong class="v460-money-trailing">${money(g.value)}</strong>`,leading:null,type:'Status',interactive:false})).join(''),remaining=pendingGroups(val03Current()).length,summary=flat('Kết quả',`${ds24InfoRow('Phiếu nhận',res.receipt||'—')}${ds24InfoRow('Sản phẩm đã xác lập',String((res.groups||[]).length))}${ds24KeyValueRow('Tổng giá trị đã ghi',money(res.totalValue||0),true)}${ds24InfoRow('Giá vốn','Cần cập nhật')}`),details=detail?`<details class="v430-details v460-details"><summary>Xem chi tiết ${(res.groups||[]).length} sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detail}</section></div></details>`:'';
    const body=`<div class="io-result">${resultHero('Đã ghi giá trị nhập ban đầu','Giá trị đã được ghi cho đúng phạm vi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}${remaining?vBanner('info','Còn hàng chờ giá trị',`${remaining} sản phẩm/dòng còn cần xử lý.`):''}</div>`;
    return appShell({title:'Kết quả xác lập giá trị',body,centered:true,back:false,actions:primaryFooter(remaining?'Tiếp tục xử lý':'Về danh sách',remaining?'data-v461-val03-result-back':'data-v461-val03-result-list')});
  }

  // ------------------------------------------------------------------
  // BJ13
  // ------------------------------------------------------------------
  let confirm13=false,detail13=false;
  const eligibleMethods=t=>(t.allowedMethods||[]).filter(m=>window.val13V398?.methodEligible?window.val13V398.methodEligible(t,m.id):true);
  const methodLabel=(t,id=t.selectedMethod)=>eligibleMethods(t).find(m=>m.id===id)?.label||(t.allowedMethods||[]).find(m=>m.id===id)?.label||'—';
  const selectedTargets13=t=>(t.targets||[]).filter(x=>t.targetScopeMode==='FIXED'||x.selected);
  function allocationRows13(t){const rows=val13Preview(t),sum=rows.reduce((n,x)=>n+Number(x.allocationMetric?.metricValue||0),0);return rows.map(x=>{const metric=Number(x.allocationMetric?.metricValue||0),metricText=t.selectedMethod==='FIXTURE_VALUE'?`${money(metric)} · ${pct(sum?metric/sum:0)}`:`${metric.toLocaleString('vi-VN')} ${x.allocationMetric?.unit||''} · ${pct(sum?metric/sum:0)}`;return `<div class="v460-allocation-row" data-composed-from="VText,DS v2 / Key-value Row"><div><strong>${esc(x.product)}</strong><small>${esc(x.receipt)} · ${x.qty} ${esc(x.uom)}${x.lot?` · Lô ${esc(x.lot)}`:''}</small><small>Căn cứ phân bổ: ${esc(metricText)}</small></div><strong>${esc(signed(x.allocatedAmount))}</strong></div>`;}).join('');}
  function methodControl13(t){const methods=eligibleMethods(t);if(methods.length<=1){const m=methods[0];if(!m)return flat('Cách phân bổ',ds24InfoRow('Phương pháp','Chưa có phương pháp hợp lệ'),'v460-method-readonly');const desc=m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm, trước các điều chỉnh phát sinh sau đó.':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị và có thể so sánh.';return `<section class="v460-methods v460-method-readonly">${heading('Cách phân bổ')}<div class="v460-method-summary" data-composed-from="VText,DS v2 / Summary Card"><strong>${esc(m.label)}</strong><span>${esc(desc)}</span></div></section>`;}return `<section class="v460-methods">${heading('Cách phân bổ')}<div class="v460-choice-list">${methods.map(m=>`<button type="button" class="v460-choice ${t.selectedMethod===m.id?'is-selected':''}" data-v461-val13-method="${m.id}" data-ds-component="VRadio" aria-pressed="${t.selectedMethod===m.id}"><span class="v460-choice__radio"><span></span></span><span><strong>${esc(m.label)}</strong><small>${m.id==='FIXTURE_VALUE'?'Phân bổ theo tỷ trọng giá trị nhập ban đầu của từng sản phẩm':'Chỉ dùng khi toàn bộ phạm vi có chỉ tiêu lượng chuẩn cùng đơn vị'}</small></span></button>`).join('')}</div></section>`;}
  function period13(t){const targets=selectedTargets13(t),posting=[...new Set(targets.map(x=>x.postingPeriod).filter(Boolean))],original=[...new Set(targets.map(x=>x.originalPeriod).filter(Boolean))],moved=targets.some(x=>x.originalPeriod&&x.postingPeriod&&x.originalPeriod!==x.postingPeriod);if(!posting.length)return '';if(!moved&&posting.length===1)return flat('Kỳ ghi nhận',ds24InfoRow('Kỳ ghi điều chỉnh',posting[0]));const originalLabel=original.join(', ')||'—',postingLabel=posting.join(', ')||'—';return `${vBanner('info','Kỳ của hàng gốc đã khóa',`Điều chỉnh được ghi ở kỳ ${postingLabel}; kỳ ${originalLabel} vẫn được giữ để truy vết.`)}${flat('Kỳ ghi nhận',`${ds24InfoRow('Kỳ của hàng gốc',originalLabel)}${ds24InfoRow('Kỳ ghi điều chỉnh',postingLabel)}`)}`;}
  function render086(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-086'),state);const t=val13Current();if(state==='LOADING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:loadingBody(),centered:true});if(state==='PERMISSION_DENIED')return appShell({title:'Phân bổ điều chỉnh giá trị',body:deniedBody(),centered:true});if(t.status==='WAITING')return appShell({title:'Phân bổ điều chỉnh giá trị',body:`${vBanner('info','Chưa thể xử lý',t.waitingOwner||'Đang chờ nguồn hoàn tất dữ liệu cần thiết.')}${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}`});
    const methods=eligibleMethods(t);if(methods.length===1&&t.selectedMethod!==methods[0].id){t.selectedMethod=methods[0].id;val13PreviewHash=null;}const preview=val13Preview(t),total=preview.reduce((n,x)=>n+Number(x.allocatedAmount||0),0),targets=(t.targets||[]).map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}${x.lot?` · Lô ${x.lot}`:''}`,trailing:'',leading:null,type:'Status',interactive:false})).join(''),valid=val13CanPreview(t)&&preview.length>0;
    const source=`${context(t.sourceRef.replace(/ · dòng \d+$/,''),`${t.component} · ${t.supplier}`)}${keys(ds24KeyValueRow('Giá trị điều chỉnh',signed(t.normalizedAmount),true))}`;
    const allocation=valid?`${heading('Kết quả phân bổ',`${preview.length} sản phẩm`)}<section class="v460-allocation-list">${allocationRows13(t)}${ds24KeyValueRow('Tổng phân bổ',signed(total),true)}</section>`:vBanner('warning','Chưa có phương pháp phân bổ hợp lệ','Cần metric hợp lệ và so sánh được trên toàn phạm vi; hệ thống không tự chia đều.');
    const body=`${state==='SOURCE_CHANGED'?vBanner('warning','Nguồn điều chỉnh đã thay đổi','Kiểm tra lại dữ liệu hiện hành trước khi ghi.'):''}${source}${heading('Phạm vi áp dụng','Theo nguồn xác định')}<section class="ds24-list-stack v430-list">${targets}</section>${methodControl13(t)}${allocation}${period13(t)}${confirm13?confirmSheet({title:'Ghi điều chỉnh giá trị?',desc:'Kiểm tra lại tổng tiền, phạm vi, cách phân bổ và kỳ ghi nhận trước khi ghi.',body:flat('Xác nhận',`${ds24InfoRow('Nguồn',t.sourceRef.replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm',String(preview.length))}${ds24InfoRow('Cách phân bổ',methodLabel(t))}${ds24InfoRow('Kỳ ghi nhận',[...new Set(preview.map(x=>x.postingPeriod))].join(', ')||'—')}${ds24KeyValueRow('Tổng điều chỉnh',signed(total),true)}`),confirmLabel:'Ghi điều chỉnh',confirmAttr:'data-v461-val13-confirm',closeAttr:'data-v461-val13-confirm-close'}):''}`;
    return appShell({title:'Phân bổ điều chỉnh giá trị',body,actions:primaryFooter('Ghi điều chỉnh','data-v461-val13-open-confirm',!valid)});
  }
  function render089(state){
    if(activeFlowId!=='UIF-13')return renderGeneric(screens.find(s=>s.id==='SCR-089'),state);const t=val13Current(),res=val13LastResult||val13Result();if(state==='PROCESSING')return appShell({title:'Kết quả điều chỉnh giá trị',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-13" data-operation="${escapeAttribute(res.operationId||t.operationId)}" data-scope="${escapeAttribute(t.sourceComponentKey||t.id)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định điều chỉnh đã được ghi hay chưa','Không ghi lại adjustment. Chuyển đúng thao tác này sang xác minh.',[['Nguồn',t.sourceRef],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả điều chỉnh giá trị',body:ioResult('Chưa ghi điều chỉnh','Không có thay đổi giá trị.',[['Nguồn',t.sourceRef],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Xem lại phân bổ','data-v461-val13-back')});
    const allocations=res.allocations||[],periods=[...new Set(allocations.map(x=>x.postingPeriod).filter(Boolean))],detailRows=allocations.map(x=>row({title:x.product,subtitle:`${x.receipt} · ${x.qty} ${x.uom}`,trailing:`<strong class="v460-money-trailing">${signed(x.allocatedAmount)}</strong>`,leading:null,type:'Status',interactive:false})).join('');
    const summary=flat('Kết quả',`${ds24InfoRow('Nguồn',String(res.sourceRef||t.sourceRef).replace(/ · dòng \d+$/,''))}${ds24InfoRow('Sản phẩm bị ảnh hưởng',String(allocations.length))}${ds24InfoRow('Kỳ ghi nhận',periods.join(', ')||'—')}${ds24InfoRow('Giá vốn','Cần cập nhật')}${ds24KeyValueRow('Tổng điều chỉnh',signed(res.normalizedAmount??t.normalizedAmount),true)}`),details=detailRows?`<details class="v430-details v460-details" ${detail13?'open':''}><summary>Xem chi tiết phân bổ (${allocations.length})</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${detailRows}</section></div></details>`:'';
    const title=Number(res.normalizedAmount??t.normalizedAmount)<0?'Đã ghi giảm giá trị hàng nhập':'Đã ghi điều chỉnh giá trị hàng nhập';return appShell({title:'Kết quả điều chỉnh giá trị',body:`<div class="io-result">${resultHero(title,'Điều chỉnh đã được ghi; sản phẩm liên quan cần cập nhật giá vốn.')}${summary}${details}</div>`,centered:true,back:false,actions:primaryFooter('Về công việc điều chỉnh','data-v461-val13-list')});
  }

  // ------------------------------------------------------------------
  // BJ14
  // ------------------------------------------------------------------
  const COST_POLICY=window.__VET45_TENANT_COST_POLICY__||{version:'MISSING',method:null,label:'Chưa cấu hình',periodCloseScopes:[]};
  let mode14='RESULT',publish14=false,compare14=false,productDetail14=false;
  window.__VET45_TENANT_COST_POLICY_V461__=COST_POLICY;
  function applyPolicy(r){try{window.__VET45_V399__?.enrichRun?.(r,0);}catch(_){}r.policyMethod=COST_POLICY.method;r.policyLabel=COST_POLICY.label;r.policyVersion=COST_POLICY.version;return r;}
  if(typeof val14Runs!=='undefined')val14Runs.forEach(applyPolicy);
  const baseCreate14=val14CreateRun;
  val14CreateRun=function(){const r=baseCreate14();applyPolicy(r);return r;};
  const scopeLabel14=r=>r.scopeOrigin==='DIRTY_SCOPE'?`${r.productCount||3} sản phẩm cần cập nhật`:r.scope;
  const methodResult=r=>r.policyMethod==='MOVING'?(r.moving||{}):(r.periodic||{});
  const compareResult=r=>r.policyMethod==='MOVING'?(r.periodic||{}):(r.moving||{});
  const compareLabel=r=>r.policyMethod==='MOVING'?'Bình quân cuối kỳ':'Bình quân liên hoàn';
  const policy14=r=>flat('Phương pháp',`${ds24InfoRow('Phương pháp áp dụng',r.policyLabel)}${ds24InfoRow('Chính sách','Theo chính sách của tổ chức')}`,'v460-policy');
  function setup14(r){
    const dirty=mode14==='DIRTY_SETUP',period=dirty?(r.postingPeriod||r.period):val14SetupPeriod;
    if(dirty)return `${flat('Phạm vi cần cập nhật',`${ds24InfoRow('Kỳ ghi nhận',period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}`)}${policy14(r)}`;
    const periodField=selectField('Kỳ','data-v461-val14-period',`<option ${val14SetupPeriod==='08/2026'?'selected':''}>08/2026</option><option ${val14SetupPeriod==='09/2026'?'selected':''}>09/2026</option>`), opts=COST_POLICY.periodCloseScopes||[];
    if(opts.length===1)val14SetupScope=opts[0].label;
    const scopeOpts=[`<option value="" ${!val14SetupScope?'selected':''} disabled>Chọn phạm vi</option>`,...opts.map(x=>`<option value="${escapeAttribute(x.id)}" ${val14SetupScope===x.label?'selected':''}>${esc(x.label)}</option>`)].join('');
    const scope=opts.length===1?flat('Phạm vi',ds24InfoRow('Phạm vi',opts[0].label)):selectField('Phạm vi','data-v461-val14-scope',scopeOpts);
    return `${periodField}${scope}${policy14(r)}`;
  }
  function results14(r){const x=methodResult(r);return `${ds24SummaryCard('Kết quả sau tính',`${r.policyLabel} · ${scopeLabel14(r)}`,'data-ds-prop-tone="Neutral"')}${keys(`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0),true)}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0),true)}`,'v460-cost-total')}${heading('Thay đổi sẽ ghi khi công bố')}<p class="v460-helper">Chỉ phần chênh lệch dưới đây được ghi; chứng từ lịch sử không bị sửa.</p>${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`,'v460-cost-delta')}`;}
  function comparison14(r){const x=compareResult(r);return `<details class="v430-details v460-details" ${compare14?'open':''} data-v461-compare><summary>Xem đối chiếu theo ${esc(compareLabel(r))}</summary><div class="v430-details__body">${flat(`${compareLabel(r)} · chỉ đối chiếu`,`${ds24KeyValueRow('Giá trị tồn cuối',val14Money(x.inventory||0))}${ds24KeyValueRow('Giá vốn xuất',val14Money(x.cogs||0))}`)}</div></details>`;}
  function products14(r){const all=r.productResults||[],rows=all.map(x=>row({title:x.product||x.name||'Sản phẩm',subtitle:x.state==='NO_NEW_COST_BASIS'?'Chưa có căn cứ giá vốn mới':`Giá vốn mới ${x.newCost!=null?`${money(x.newCost)}/${x.baseUom||'đơn vị cơ sở'}`:'—'}`,trailing:x.state==='NO_NEW_COST_BASIS'?ds24Badge('Không đổi','Neutral'):'',leading:null,type:'Status',interactive:false})).join('');if(!rows)return '';return `${heading('Kết quả theo sản phẩm',`${r.changedProductCount||0} có thay đổi`)}<details class="v430-details v460-details" ${productDetail14?'open':''} data-v461-products><summary>Xem kết quả theo sản phẩm</summary><div class="v430-details__body"><section class="ds24-list-stack v430-list">${rows}</section></div></details>`;}
  function publishSheet14(r){return confirmSheet({title:'Công bố giá vốn?',desc:'Kết quả đã rà soát sẽ có hiệu lực. Hệ thống chỉ ghi phần chênh lệch, không sửa chứng từ lịch sử.',body:`${flat('Phạm vi công bố',`${ds24InfoRow('Kỳ ghi nhận',r.postingPeriod||r.period)}${ds24InfoRow('Phạm vi',scopeLabel14(r))}${ds24InfoRow('Phương pháp',r.policyLabel)}`)}${keys(`${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(r.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(r.endingAdjustment||0),true)}`)}`,confirmLabel:'Công bố giá vốn',confirmAttr:'data-v461-val14-publish',closeAttr:'data-v461-val14-publish-close'});}
  function workMeta14(r){applyPolicy(r);if(r.status==='DIRTY')return {title:'Cập nhật giá vốn',subtitle:`${r.productCount||3} sản phẩm · có thay đổi giá trị`,label:'Cần tính lại',tone:'Warning'};if(r.status==='READY_FOR_REVIEW')return {title:`Chốt giá vốn ${r.period}`,subtitle:`Đã tính · ${r.productCount||r.scope} · chờ công bố`,label:'Sẵn sàng',tone:'Success'};if(r.status==='BLOCKED')return {title:`Chốt giá vốn ${r.period}`,subtitle:`${r.blockers?.length||0} vấn đề cần xử lý`,label:'Bị chặn',tone:'Warning'};return {title:r.label,subtitle:scopeLabel14(r),label:'Đang xử lý',tone:'Neutral'};}
  function render072(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-072'),state);if(state==='LOADING')return appShell({title:'Công việc giá vốn',body:loadingBody(),centered:true,back:false});if(state==='PERMISSION_DENIED')return appShell({title:'Công việc giá vốn',body:deniedBody(),centered:true,back:false});const rows=val14Runs.filter(r=>r.status!=='PUBLISHED').map(r=>{const m=workMeta14(r);return row({title:m.title,subtitle:m.subtitle,trailing:ds24Badge(m.label,m.tone),leading:null,type:'Navigation',attrs:`data-v461-val14-run="${r.id}"`});}).join('');return appShell({title:'Công việc giá vốn',body:rows?`<section class="ds24-list-stack v430-list">${rows}</section>`:ioEmpty('Không có công việc giá vốn','Chưa có phạm vi cần cập nhật hoặc chốt kỳ.'),back:false,actions:primaryFooter('Chốt kỳ','data-v461-val14-close-period')});}
  function render074(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-074'),state);const r=applyPolicy(val14Current());if(state==='PERMISSION_DENIED')return appShell({title:'Tính và rà soát giá vốn',body:deniedBody(),centered:true});if(state==='INPUT_CHANGED'||r.status==='INPUT_CHANGED')return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Dữ liệu đầu vào đã thay đổi','Kết quả cũ được giữ để truy vết nhưng không còn đủ điều kiện công bố.')}${policy14(r)}`,actions:primaryFooter('Tạo lần tính kế tiếp','data-v461-val14-successor')});if(mode14==='DIRTY_SETUP'||mode14==='PERIOD_CLOSE_SETUP'){const noScope=mode14==='PERIOD_CLOSE_SETUP'&&(COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope;return appShell({title:mode14==='DIRTY_SETUP'?'Cập nhật giá vốn':'Chốt giá vốn kỳ',body:setup14(r),actions:primaryFooter(mode14==='DIRTY_SETUP'?'Tính lại giá vốn':'Tính giá vốn','data-v461-val14-calculate',noScope)});}if(r.status==='CALCULATING'||state==='PROCESSING')return appShell({title:'Tính và rà soát giá vốn',body:ioResult('Đang tính giá vốn','Có thể rời màn hình. Kết quả được lưu trong cùng lần tính.',[['Kỳ ghi nhận',r.postingPeriod||r.period],['Phạm vi',scopeLabel14(r)]],'info'),centered:true});if(r.status==='BLOCKED'||state==='BLOCKED'){const blockers=(r.blockers||[]).map(b=>context(b.title,`Đang chờ: ${b.owner}`,'Cần xử lý','Warning')).join('');return appShell({title:'Tính và rà soát giá vốn',body:`${vBanner('warning','Chưa thể chốt giá vốn','Xử lý các vấn đề dưới đây trước khi công bố.')}${policy14(r)}${heading('Cần xử lý',`${r.blockers?.length||0} vấn đề`)}<section class="ds24-list-stack v430-list">${blockers}</section>`});}const body=`${policy14(r)}${results14(r)}${comparison14(r)}${products14(r)}${publish14?publishSheet14(r):''}`;return appShell({title:'Tính và rà soát giá vốn',body,actions:primaryFooter('Công bố giá vốn','data-v461-val14-open-publish',r.status!=='READY_FOR_REVIEW')});}
  function render077(state){if(activeFlowId!=='UIF-14')return renderGeneric(screens.find(s=>s.id==='SCR-077'),state);const r=applyPolicy(val14Current()),res=val14LastResult||{runId:r.id,postingPeriod:r.postingPeriod||r.period,method:r.policyLabel,effectiveAt:r.effectiveAt,cogsTrueUp:r.cogsTrueUp,endingAdjustment:r.endingAdjustment,reconciledProducts:r.productCount||0,officialCostVersions:(r.productResults||[]).filter(x=>x.state!=='NO_NEW_COST_BASIS'&&x.newCost!==x.oldCost).length};if(state==='PROCESSING')return appShell({title:'Kết quả công bố giá vốn',body:loadingBody(),centered:true,back:false});if(state==='UNKNOWN'){const attrs=`data-v350-action="handoff-unknown" data-source-flow="UIF-14" data-operation="${escapeAttribute(res.runId||r.id)}" data-scope="${escapeAttribute(res.postingPeriod||r.period)}"`;return appShell({title:'Đang xác minh kết quả',body:ioResult('Chưa xác định giá vốn đã được công bố hay chưa','Không gửi lại lệnh công bố. Chuyển đúng lần này sang xác minh kết quả.',[['Lần tính',res.runId||r.id],['Trạng thái','Đang xác minh']],'warning'),centered:true,back:false,actions:primaryFooter('Chuyển sang xác minh',attrs)});}if(state==='REJECTED_EXECUTION')return appShell({title:'Kết quả công bố giá vốn',body:ioResult('Chưa công bố giá vốn','Không có điều chỉnh hoặc phiên bản giá vốn mới.',[['Kỳ ghi nhận',res.postingPeriod||r.period],['Tác động','Không thay đổi']],'warning'),centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});const body=`<div class="io-result">${resultHero('Đã công bố giá vốn','Phần chênh lệch đã được ghi và giá vốn chính thức mới đã có hiệu lực.')}${flat('Kết quả',`${ds24InfoRow('Kỳ ghi nhận',res.postingPeriod||r.period)}${ds24InfoRow('Phương pháp',res.method||r.policyLabel)}${ds24InfoRow('Sản phẩm đã đối soát',String(res.reconciledProducts||r.productCount||0))}${ds24InfoRow('Sản phẩm có giá vốn mới',String(res.officialCostVersions??0))}${ds24InfoRow('Hiệu lực',res.effectiveAt||r.effectiveAt||'—')}${ds24KeyValueRow('Điều chỉnh giá vốn xuất',signed(res.cogsTrueUp||0),true)}${ds24KeyValueRow('Điều chỉnh giá trị tồn',signed(res.endingAdjustment||0),true)}`)}</div>`;return appShell({title:'Kết quả công bố giá vốn',body,centered:true,back:false,actions:primaryFooter('Về công việc giá vốn','data-v461-val14-list')});}

  // Retire SCR-088 at runtime and preserve legacy deep links.
  const navParent=navigate;
  navigate=function(screenId){if(activeFlowId==='UIF-13'&&screenId==='SCR-088')screenId='SCR-086';return navParent(screenId);};
  if(activeFlowId==='UIF-13'&&activeScreenId==='SCR-088')activeScreenId='SCR-086';

  Object.assign(renderers,{
    'SCR-015':render015,'SCR-017':render017,'SCR-019':render019,
    'SCR-086':render086,'SCR-087':render086,'SCR-088':function(state){activeScreenId='SCR-086';return render086(state);},'SCR-089':render089,
    'SCR-072':render072,'SCR-073':render074,'SCR-074':render074,'SCR-075':render074,'SCR-076':render074,'SCR-077':render077
  });

  // Unique v4.6 interaction attributes prevent legacy event handlers from firing.
  window.addEventListener('change',event=>{
    if(activeFlowId==='UIF-03'&&event.target.matches('[data-v461-basis-currency]')){event.stopImmediatePropagation();ensureBasisDraft().currency=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-period]')){event.stopImmediatePropagation();val14SetupPeriod=event.target.value;return renderAppScreen();}
    if(activeFlowId==='UIF-14'&&event.target.matches('[data-v461-val14-scope]')){event.stopImmediatePropagation();const opt=(COST_POLICY.periodCloseScopes||[]).find(x=>x.id===event.target.value);val14SetupScope=opt?.label||'';return renderAppScreen();}
  },true);
  window.addEventListener('input',event=>{
    if(activeFlowId==='UIF-03'&&basisSheetGroup&&event.target.closest('.v430-form-sheet')){
      const root=document.querySelector('.v430-form-sheet');if(root)syncBasisDraft(root);
    }
  },true);
  window.addEventListener('click',event=>{
    let el;
    if(activeFlowId==='UIF-03'){
      if((el=event.target.closest('[data-v461-val03-select]'))){event.preventDefault();event.stopImmediatePropagation();const g=(val03Current().groups||[]).find(x=>x.id===el.dataset.v461Val03Select);if(g&&groupState(val03Current(),g)==='READY')selectGroup(g,!selectedGroups().includes(g));return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-add-basis]'))){event.preventDefault();event.stopImmediatePropagation();basisSheetGroup=el.dataset.v461Val03AddBasis;basisDraft={price:'',currency:'',taxMode:'',tax:'',source:'',date:'',ref:'',reason:''};return renderAppScreen();}
      if((el=event.target.closest('[data-v461-tax-mode]'))){event.preventDefault();event.stopImmediatePropagation();ensureBasisDraft().taxMode=el.dataset.v461TaxMode;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val03-sheet]'))){event.preventDefault();event.stopImmediatePropagation();if(el.dataset.v461Val03Sheet==='close'){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}if(el.dataset.v461Val03Sheet==='save'&&saveBasis(basisSheetGroup)){basisSheetGroup=null;basisDraft=null;return renderAppScreen();}return;}
      if((el=event.target.closest('[data-v461-val03-review]'))){event.preventDefault();event.stopImmediatePropagation();if(!canReview03())return;val03ReviewSourceVersion=val03Current().sourceVersion;stateByScreen['SCR-017']='READY';return navigate('SCR-017');}
      if((el=event.target.closest('[data-v461-val03-back]'))){event.preventDefault();event.stopImmediatePropagation();stateByScreen['SCR-015']='READY';return navigate('SCR-015');}
      if((el=event.target.closest('[data-v461-val03-confirm]'))){event.preventDefault();event.stopImmediatePropagation();if(Number(val03ReviewSourceVersion)!==Number(val03Current().sourceVersion)){stateByScreen['SCR-017']='SOURCE_CHANGED';return renderAppScreen();}val03Commit();stateByScreen['SCR-019']='COMPLETED';return navigate('SCR-019');}
      if((el=event.target.closest('[data-v461-val03-result-list]'))){event.preventDefault();event.stopImmediatePropagation();return navigate('SCR-014');}
    }
    if(activeFlowId==='UIF-13'){
      if((el=event.target.closest('[data-v461-val13-method]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current(),id=el.dataset.v461Val13Method;if(eligibleMethods(t).some(m=>m.id===id)){t.selectedMethod=id;val13PreviewHash=null;}return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-open-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(!val13CanPreview(t))return;val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);confirm13=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm-close]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val13-confirm]'))){event.preventDefault();event.stopImmediatePropagation();const t=val13Current();if(Number(val13ReviewSourceVersion)!==Number(t.sourceVersion)||val13PreviewHash!==val13PreviewHashOf(t)){confirm13=false;stateByScreen['SCR-086']='SOURCE_CHANGED';return renderAppScreen();}val13Commit();confirm13=false;stateByScreen['SCR-089']='COMPLETED';return navigate('SCR-089');}
      if((el=event.target.closest('[data-v461-val13-back]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;stateByScreen['SCR-086']='READY';return navigate('SCR-086');}
      if((el=event.target.closest('[data-v461-val13-list]'))){event.preventDefault();event.stopImmediatePropagation();confirm13=false;return navigate('SCR-085');}
    }
    if(activeFlowId==='UIF-14'){
      if((el=event.target.closest('[data-v461-val14-run]'))){event.preventDefault();event.stopImmediatePropagation();val14SelectedRunId=el.dataset.v461Val14Run;const r=applyPolicy(val14Current());publish14=false;compare14=false;productDetail14=false;if(r.status==='DIRTY'){val14SetupKind='AD_HOC';val14SetupPeriod=r.period;val14SetupScope='Sản phẩm cần tính lại';val14SuccessorOf=r.id;mode14='DIRTY_SETUP';}else{mode14='RESULT';stateByScreen['SCR-074']=r.status==='BLOCKED'?'BLOCKED':'READY';}return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-close-period]'))){event.preventDefault();event.stopImmediatePropagation();val14SuccessorOf=null;val14SetupKind='PERIOD_CLOSE';val14SetupScope=(COST_POLICY.periodCloseScopes||[]).length===1?COST_POLICY.periodCloseScopes[0].label:'';mode14='PERIOD_CLOSE_SETUP';return navigate('SCR-074');}
      if((el=event.target.closest('[data-v461-val14-calculate]'))){event.preventDefault();event.stopImmediatePropagation();if(mode14==='PERIOD_CLOSE_SETUP'&&(COST_POLICY.periodCloseScopes||[]).length>1&&!val14SetupScope)return;val14SetupKind=mode14==='DIRTY_SETUP'?'AD_HOC':'PERIOD_CLOSE';const run=val14CreateRun();applyPolicy(run);mode14='RESULT';stateByScreen['SCR-074']='READY';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-compare] summary'))){compare14=!compare14;return;}
      if((el=event.target.closest('[data-v461-products] summary'))){productDetail14=!productDetail14;return;}
      if((el=event.target.closest('[data-v461-val14-open-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(r.status!=='READY_FOR_REVIEW')return;val14PublishReviewVersion=r.runInputHash||String(r.inputVersion);publish14=true;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish-close]'))){event.preventDefault();event.stopImmediatePropagation();publish14=false;return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-publish]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());if(String(val14PublishReviewVersion)!==String(r.runInputHash||r.inputVersion)){r.status='INPUT_CHANGED';publish14=false;stateByScreen['SCR-074']='INPUT_CHANGED';return renderAppScreen();}val14Commit();publish14=false;stateByScreen['SCR-077']='COMPLETED';return navigate('SCR-077');}
      if((el=event.target.closest('[data-v461-val14-successor]'))){event.preventDefault();event.stopImmediatePropagation();const r=applyPolicy(val14Current());val14SuccessorOf=r.id;val14SetupKind=r.kind;val14SetupPeriod=r.period;val14SetupScope=r.scopeOrigin==='DIRTY_SCOPE'?scopeLabel14(r):((COST_POLICY.periodCloseScopes||[]).some(x=>x.label===r.scope)?r.scope:((COST_POLICY.periodCloseScopes||[]).length===1?COST_POLICY.periodCloseScopes[0].label:''));mode14=r.scopeOrigin==='DIRTY_SCOPE'?'DIRTY_SETUP':'PERIOD_CLOSE_SETUP';return renderAppScreen();}
      if((el=event.target.closest('[data-v461-val14-list]'))){event.preventDefault();event.stopImmediatePropagation();mode14='RESULT';publish14=false;return navigate('SCR-072');}
    }
  },true);

  if(window.__VET45_PROTOTYPE__)window.__VET45_PROTOTYPE__.version='4.6.1';
  window.__VET45_V461__={version:'4.6.1',parent:'4.6.0',costPolicy:COST_POLICY,activeScreens:{bj03:['SCR-014','SCR-015','SCR-017','SCR-019'],bj13:['SCR-085','SCR-086','SCR-089'],bj14:['SCR-072','SCR-074','SCR-077']},retired:['SCR-088']};
  if(new Set(['UIF-03','UIF-13','UIF-14']).has(activeFlowId)){syncReviewUrl();render();}
})();

/* ===== v470-color-semantics.js ===== */
/* VET45 Theme 7 v4.7.0 — T7-P colorize.
   Post-render decoration only: no renderer, fixture or copy is changed.
   - Stock state suffix in list-row captions ("… · Tồn thấp") becomes a DS badge in the trailing slot.
   - Key-value rows carrying risk or a non-zero discrepancy get the warning tone; minus uses U+2212. */
(()=>{
  const VERSION='4.7.0';
  const badge=document.querySelector('.review-meta > .review-badge:not(.review-badge--muted)');
  if(badge)badge.textContent='v4.7.0 · T7-P UI refinement';
  if(window.__VET45_PROTOTYPE__){
    window.__VET45_PROTOTYPE__.version=VERSION;
    window.__VET45_PROTOTYPE__.scenarios=[...new Set([...(window.__VET45_PROTOTYPE__.scenarios||[]),'t7p-colorize'])];
  }

  const STOCK_STATES=[
    ['Có lô hết hạn','Danger'],
    ['Hết hạn','Danger'],
    ['Hết hàng','Danger'],
    ['Có lô cận hạn','Warning'],
    ['Cận hạn','Warning'],
    ['Tồn thấp','Warning'],
  ];

  function stockBadge(label,tone){
    const t=tone.toLowerCase();
    return `<span class="ds24-badge ds24-badge--${t} ds24-badge--dot" data-ds-component="VBadge" data-ds-prop-style="Soft" data-ds-prop-tone="${tone}">${label}</span>`;
  }

  function decorateCaptions(root){
    root.querySelectorAll('.ds24-list-row__copy > small:not([data-v470])').forEach(small=>{
      small.dataset.v470='1';
      const parts=small.textContent.split(' · ');
      if(parts.length<2)return;
      const last=parts[parts.length-1].trim();
      const hit=STOCK_STATES.find(([label])=>label===last);
      if(!hit)return;
      const row=small.closest('.ds24-list-row');
      const trailing=row&&row.querySelector('.ds24-list-row__trailing');
      if(!trailing)return;
      small.textContent=parts.slice(0,-1).join(' · ');
      trailing.insertAdjacentHTML('afterbegin',stockBadge(hit[0],hit[1]));
    });
  }

  function decorateKeyValues(root){
    root.querySelectorAll('.ds24-key-value-row:not([data-v470]), .bj02-key-value-row:not([data-v470])').forEach(row=>{
      row.dataset.v470='1';
      const label=(row.querySelector(':scope > span')?.textContent||'').trim();
      const value=row.querySelector(':scope > strong');
      if(!value)return;
      const text=value.textContent.trim();
      if(/^-\s?\d/.test(text))value.textContent=text.replace(/^-\s?/,'−');
      if(/rủi ro/i.test(label)){row.classList.add('v470-kv--warning');return;}
      if(/^Chênh lệch$/i.test(label)&&/\d/.test(text)&&!/^[−+-]?\s?0(\s|$)/.test(text))row.classList.add('v470-kv--attention');
    });
  }

  function decorate(){
    const root=document.getElementById('app-screen');
    if(!root||ownedFlows.has(activeFlowId))return;
    decorateCaptions(root);
    decorateKeyValues(root);
  }

  const root=document.getElementById('app-screen');
  if(!root)return;
  let queued=false;
  new MutationObserver(()=>{
    if(queued)return;
    queued=true;
    requestAnimationFrame(()=>{queued=false;decorate();});
  }).observe(root,{childList:true,subtree:true});
  decorate();
})();


