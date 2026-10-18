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
// Giữ màn retired (vd. SCR-018/088) dù không còn trong flow.screens — bj*.js screenAliases đổi trước hub render().
const requestedScreen = initialParams.get("screen");
let activeScreenId = (() => {
  if (!requestedScreen) return initialFlow?.screens[0] || "SCR-006";
  if (initialFlow?.screens.includes(requestedScreen)) return requestedScreen;
  if (screens.some((s) => s.id === requestedScreen)) return requestedScreen;
  return initialFlow?.screens[0] || "SCR-006";
})();
let viewport = initialParams.get("viewport") === "wide" ? "wide" : "mobile";
let flowMode = initialParams.get("flow") === "quick" ? "quick" : "document";
if (!requestedScreen) {
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

/* io07* moved to app/bj07.js (T7-P A6) */


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
/* ic08* fixtures → app/bj08.js (T7-P A7) */

/* ic09Items moved to app/bj09.js (T7-P A6) */
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
/* icChoice moved to app/bj09.js (T7-P A6) */
function icHeaderRows(rows){return ioReadCard(rows.map(([a,b,strong])=>ioMetaRow(a,b,!!strong)).join(''));}
function icSecondary(label,action,tone="secondary"){const c=tone==='danger'?'button button--danger button--full':'button button--secondary button--full';return `<button class="${c}" type="button" ${action}>${label}</button>`;}
function icApprovalButtons(prefix){return `<div class="ic-action-stack">${icSecondary("Từ chối",`data-${prefix}-action="reject"`,'danger')}${primaryFooter("Duyệt",`data-${prefix}-action="approve"`)}</div>`;}

/* ic08Section → app/bj08.js (T7-P A7) */
function ds24SelectField(label,value,options,attr="") {
  return `<label class="ds24-field" data-ds-component="VSelect" data-figma-node="522:7291"><span class="vet45-text-style-8">${esc(label)}</span><select ${attr} class="ds24-field__control vet45-text-style-6">${options.map(([v,l])=>`<option value="${v}" ${v===value?'selected':''}>${esc(l)}</option>`).join('')}</select></label>`;
}
function ds24TextField(label,value,attrs="",helper="") {
  return `<label class="ds24-field" data-ds-component="VTextField" data-figma-node="522:7186"><span class="vet45-text-style-8">${esc(label)}</span><input class="ds24-field__control vet45-text-style-6" value="${escapeAttribute(value)}" ${attrs}>${helper?`<small class="vet45-text-style-11">${esc(helper)}</small>`:''}</label>`;
}
/* ic08QuantityTrigger → app/bj08.js (T7-P A7) */
/* ic08ContextRows → app/bj08.js (T7-P A7) */
/* ic08ProductInputGroup → app/bj08.js (T7-P A7) */
/* ic08CountRow → app/bj08.js (T7-P A7) */
/* ic08RecountRow → app/bj08.js (T7-P A7) */
/* ic08NumericSheet → app/bj08.js (T7-P A7) */
/* ic08ConfirmationSheet → app/bj08.js (T7-P A7) */
/* ic08SelectSheet → app/bj08.js (T7-P A7) */
/* ic08Overlays → app/bj08.js (T7-P A7) */
/* ic08SessionRow → app/bj08.js (T7-P A7) */
/* render042IC08 → app/bj08.js (T7-P A7) */
/* render043IC08 → app/bj08.js (T7-P A7) */
/* render044IC08 → app/bj08.js (T7-P A7) */
/* render045IC08 → app/bj08.js (T7-P A7) */
/* render046IC08 → app/bj08.js (T7-P A7) */
function ds24Result(title,description,rows,tone='success') {
  const iconName=tone==='success'?'checkCircle':tone==='danger'?'xCircle':'alert';
  return `<section class="ds24-result" data-theme-component="Theme7OperationResult" data-composed-from="VIcon,VText,DS v2 / Info Row,State Pattern"><div class="ds24-result__icon ds24-result__icon--${tone}">${icon(iconName)}</div><h2 class="vet45-text-style-3">${esc(title)}</h2><p class="vet45-text-style-6">${esc(description)}</p><div class="ds24-info-stack">${rows.map(([k,v])=>ds24InfoRow(k,v)).join('')}</div></section>`;
}
/* render047IC08 → app/bj08.js (T7-P A7) */

/* ic09StatusTone moved (T7-P A6) */
/* ic09Current moved (T7-P A6) */
/* render036IC09 moved (T7-P A6) */
/* render037IC09 moved (T7-P A6) */
/* render038IC09 moved (T7-P A6) */
/* render041IC09 moved (T7-P A6) */
/* render056IC09 → app/bj09.js (T7-P A9) */

/* render036IC10 moved (T7-P A6) */
/* render037IC10 moved (T7-P A6) */
/* render040IC10 moved (T7-P A6) */
/* render041IC10 moved (T7-P A6) */

/* render036IO07 moved (T7-P A6) */
/* render037IO07 moved (T7-P A6) */
/* render039IO07 moved (T7-P A6) */
/* render041IO07 moved (T7-P A6) */

// ============================================================================
// v1.7.0 — Correction & Recovery Product correction (UIF-11/UIF-16/UIF-17)
// Product UI exposes business facts, decisions and authoritative finality only.
// Technical identifiers/replay/rebuild/hash/polling remain contracts/Inspect concerns.
// ============================================================================
/* cr11* state + cr11Operations → app/bj11.js (T7-P A8) */
/* cr11Current → app/bj11.js (T7-P A8) */

/* cr11StateFor → app/bj11.js or bj12.js (T7-P A8) */

/* crChoice → app/bj11.js or bj12.js (T7-P A8) */

function crFactCard(title,rows,badge="",tone="info"){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card cr-fact-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,VBadge,DS v2 / Info Row"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong data-ds-component="VText">${title}</strong>${badge?vBadge(badge,tone):""}</div><div class="review-card-body">${rows.map(r=>ioMetaRow(r[0],r[1],!!r[2])).join("")}</div></section>`;}
/* crTextAction → app/bj11.js or bj12.js (T7-P A8) */

function crSwitchFlow(flowId,screenId,state){activeFlowId=flowId;activeScreenId=screenId;if(state&&stateByScreen[screenId]!==undefined)stateByScreen[screenId]=state;syncReviewUrl();render();}
/* cr11ListRows → app/bj11.js or bj12.js (T7-P A8) */

/* render048CR11 → app/bj11.js or bj12.js (T7-P A8) */

/* render049CR11 → app/bj11.js or bj12.js (T7-P A8) */

/* render052CR11 → app/bj11.js or bj12.js (T7-P A8) */

/* render050CR11 → app/bj11.js or bj12.js (T7-P A8) */

/* render051CR11 → app/bj11.js or bj12.js (T7-P A8) */

/* render053CR11 → app/bj11.js or bj12.js (T7-P A8) */


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
/* cf12* state + cf12Summary → app/bj12.js (T7-P A8) */
/* cfMoney…cfSecondary → app/shared-control.js (T7-P A9) */
/* cf12ReviewCard → app/bj11.js or bj12.js (T7-P A8) */

/* render066CF12 → app/bj11.js or bj12.js (T7-P A8) */

/* render067CF12 → app/bj11.js or bj12.js (T7-P A8) */

/* render068CF12 → app/bj11.js or bj12.js (T7-P A8) */

/* render069CF12 → app/bj11.js or bj12.js (T7-P A8) */

/* cf12ApprovalFooter → app/bj11.js or bj12.js (T7-P A8) */

/* cf12RejectSheet → app/bj11.js or bj12.js (T7-P A8) */

/* render070CF12 → app/bj11.js or bj12.js (T7-P A8) */

/* render071CF12 → app/bj11.js or bj12.js (T7-P A8) */


/* cf15* state + render054…059CF15 → app/bj15.js (T7-P A9) */

const renderers = {"SCR-078":render078CR,"SCR-079":render079CR,"SCR-080":render080CR,"SCR-081":render081CR,"SCR-082":render082CR,"SCR-083":render083CR};
for (const screen of screens) if (!renderers[screen.id]) renderers[screen.id]=(state)=>renderGeneric(screen,state);
/* flowScreen assigns after framework */





// Một điểm vào duy nhất. Màn gốc của chế độ theme (Thêm, Hub Kho) do app/hub.js dựng; mọi màn BJ qua
// renderFlowScreen. Các bước sửa sau dựng còn lại (legacy) bọc renderFlowScreen và được xoá dần theo BJ ở T7-P.
// Luồng đã viết lại sạch trong app/bjNN.js tự đăng ký vào đây: màn của chúng dựng thẳng bằng renderers[...],
// không qua các bước sửa sau dựng legacy bọc renderFlowScreen.
const ownedFlows = new Set();
// Màn dùng chung nhiều luồng: mỗi luồng đăng ký hàm dựng riêng, flowRenderers["UIF-NN"]["SCR-NNN"] = fn.
const flowRenderers = {};
function rendererFor(flowId, screenId) { return flowRenderers[flowId]?.[screenId] || renderers[screenId]; }
// Mục renderers cho màn chỉ dựng theo luồng: rẽ sang flowRenderers, không có thì renderGeneric.
function flowScreen(screenId) {
  return (state) => (flowRenderers[activeFlowId]?.[screenId] || ((st) => renderGeneric(screens.find((s) => s.id === screenId), st)))(state);
}
["SCR-036","SCR-037","SCR-038","SCR-039","SCR-040","SCR-041"].forEach((id)=>{ renderers[id]=flowScreen(id); });
function renderAppScreen() {
  if (typeof ThemeApp !== "undefined" && ThemeApp.isRoot()) return ThemeApp.renderRoot();
  if (ownedFlows.has(activeFlowId)) document.getElementById("app-screen").innerHTML = rendererFor(activeFlowId, activeScreenId)(stateByScreen[activeScreenId]);
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

// Đường cũ của luồng: navigate(màn cũ) → màn mới (cùng luồng), hoặc → [luồng khác, màn].
const screenAliases = {};

function navigate(screenId) {
  const alias = screenAliases[activeFlowId]?.[screenId];
  if (Array.isArray(alias)) { activeFlowId = alias[0]; screenId = alias[1]; }
  else if (alias) screenId = alias;
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



/* UIF-07 click listener moved to app/bj07.js (T7-P A6) */

// v1.7.0 Correction & Recovery interactions (UIF-11 → bj11.js T7-P A8; UIF-16/17 remain for A10)
 document.addEventListener("input",(event)=>{
  if(["UIF-16","UIF-17"].includes(activeFlowId)&&event.target.matches("[data-cr-control-search]")){crControlQuery=event.target.value;return renderAppScreen();}
 },true);

 document.addEventListener("click",(event)=>{
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


// v1.8.0 UIF-12 → bj12.js (A8); UIF-15 → bj15.js (T7-P A9)

const flowSelectorEl=document.getElementById("flow-selector");
flowSelectorEl?.addEventListener("change",(e)=>{activeFlowId=e.target.value; const f=activeFlow(); activeScreenId=f.screens[0]; syncReviewUrl(); render();});
document.addEventListener("click",(e)=>{
  const next=e.target.closest("[data-generic-next]"); if(next){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); else showToast("Đã hoàn thành flow demo", "checkCircle"); }
  const act=e.target.closest("[data-generic-action]"); if(act){ showToast(`${act.textContent.trim()} · prototype không gọi backend`, "checkCircle"); }
  const card=e.target.closest(".generic-data-card[data-ds-profile='card.interactive']"); if(card&&!inspectEnabled){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); }
});
/* load-time render() → hub.js (T7-P A7) */

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

/* ac310Tone → app/shared-control.js (T7-P A7) */
/* ac310CleanText → app/shared-control.js (T7-P A7) */
/* ac310SanitizeMarkup → app/shared-control.js (T7-P A7) */
function ac310Base(id,state){
  const fn=ac310BaseRenderers[id];
  return ac310SanitizeMarkup(fn?fn(state):renderGeneric(screens.find((s)=>s.id===id),state));
}
/* ac310Return → app/shared-control.js (T7-P A7) */
/* ac310SectionTitle → app/bj11.js or bj12.js (T7-P A8) */

/* ac310InfoSurface → app/shared-control.js (T7-P A7) */
/* ac310KeyValueSurface → app/bj11.js or bj12.js (T7-P A8) */

/* ac310RecordRow → app/shared-control.js (T7-P A7) */
/* ac310ProductRow → app/shared-control.js (T7-P A9) */
/* ac310ListSurface → app/bj11.js or bj12.js (T7-P A8) */

/* ac310RadioChoice → app/bj11.js or bj12.js (T7-P A8) */

/* ac310RadioSurface → app/bj11.js or bj12.js (T7-P A8) */

/* ac310AuditItem → app/bj11.js or bj12.js (T7-P A8) */

/* ac310AuditSurface → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Field → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Textarea → app/bj11.js or bj12.js (T7-P A8) */

/* ac310FileDrop → app/bj11.js or bj12.js (T7-P A8) */

/* ac310ApprovalFooter → app/bj11.js or bj12.js (T7-P A8) */

/* ac310SummaryMetrics → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Result → app/bj11.js or bj12.js (T7-P A8) */


/* BJ08 v310 renderers → app/bj08.js (T7-P A7) */

/* ------------------------------ BJ09 ----------------------------------- */
/* ac310Render036 removed (T7-P A6) */
/* ac310Render037 removed (T7-P A6) */
/* ac310StateLabel removed (T7-P A9) */
/* ac310Render038 removed (T7-P A6) */
/* ac310Render041 removed (T7-P A6) */
/* ac310Render056 → bj09.js / bj15.js (T7-P A9) */

/* ------------------------------ BJ10 ----------------------------------- */
/* ac310Render040 removed (T7-P A6) */

/* ------------------------------ BJ11 ----------------------------------- */
/* ac310Render048 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render049 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render052 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render050 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render051 → app/bj11.js or bj12.js (T7-P A8) */


/* ------------------------------ BJ12 ----------------------------------- */
/* ac310Cf12Review → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render066 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render067 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310IssueRow → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render068 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render069 → app/bj11.js or bj12.js (T7-P A8) */

/* ac310Render070 → app/bj11.js or bj12.js (T7-P A8) */


/* BJ15 ac310* → app/bj15.js (T7-P A9) */

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
/* SCR-042…047 renderers → bj08.js (T7-P A7) */
/* SCR-048…053 / SCR-066…071 → app/bj11.js / bj12.js (T7-P A8) */
/* SCR-054…059 → app/bj15.js (T7-P A9); SCR-056 = flowScreen */
renderers["SCR-056"]=flowScreen("SCR-056");
renderers["SCR-078"]=ac310Render078;
renderers["SCR-079"]=ac310Render079;
renderers["SCR-080"]=ac310Render080;
renderers["SCR-081"]=ac310Render081;
renderers["SCR-082"]=ac310Render082;
renderers["SCR-083"]=(state)=>["UIF-16","UIF-17"].includes(activeFlowId)?ac310Base("SCR-083",state):ac310Base("SCR-083",state);

// Re-render once so a deep-linked Audit & Control screen immediately uses v3.1.0.
/* load-time render removed (T7-P A7): if (["UIF-08","UIF-09","UIF-10","UIF-11"… */

/* v320 → bj09.js / bj15.js (T7-P A9) */

/* v340 BJ-08 moved/removed (T7-P A7) */

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
    "UIF-11": {"approver":["SCR-051","READY"], "operation-context":["SCR-049","CORRECTABLE"]},
    "UIF-12": {"approver":["SCR-070","READY"]},
    "UIF-14": {"dirty-scope":["SCR-073","READY"]}
  };
  function v350ApplyEntry(flowId, mode, shouldRender=false) {
    const target = v350EntryTargets[flowId]?.[mode];
    if (!target) return false;
    activeFlowId = flowId;
    activeScreenId = target[0];
    if (stateByScreen[activeScreenId] !== undefined) stateByScreen[activeScreenId] = target[1];
    if (flowId === "UIF-14" && mode === "dirty-scope" && typeof val14Runs !== "undefined") {
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


  // Capture source version when entering a review/receipt context.
  const v350Navigate = navigate;
  navigate = function(screenId){
    return v350Navigate(screenId);
  };


  // -------------------------------------------------------------------------
  /* BJ08 v350 renderers/helpers → app/bj08.js (T7-P A7) */

  // -------------------------------------------------------------------------
  // BJ14 — successor must preserve immediate predecessor and policy method.
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
// BJ15 → app/bj15.js (T7-P A9)

  // BJ16 / BJ17 — context integrity + evidence freshness + safe finality.
  // -------------------------------------------------------------------------
  cr16Cases.forEach((c,i)=>{c.evidenceVersion ??= 1;c.planEvidenceVersion ??= null;c.recoveryEvidenceVersion ??= null;c.closed ??= false;if(c.id==="REC-260907-04")c.correctionOperationId="IO-260904-021";});
  /* IO-260904-021 seed → app/bj11.js (T7-P A8) */
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
  /* wrapUnknown SCR-047/066/071 → bj08/bj12 (T7-P A7/A8); handoff-unknown listener giữ */
  const unknowns=[];
  // BJ02 verify/handoff-unknown: giữ listener data-v350-action (A10); wrapper SCR-012/013 đã chết (v392).

  /* BJ11 SCR-051 → app/bj11.js (T7-P A8) */

  // -------------------------------------------------------------------------
  // Event binding for v3.5.0 controls.
  // -------------------------------------------------------------------------
  document.addEventListener("click",(event)=>{
    const a=event.target.closest("[data-v350-action]");if(!a||a.disabled)return;
    event.preventDefault();event.stopPropagation();const k=a.dataset.v350Action;
    if(k==="handoff-unknown")return v350HandoffUnknown({sourceFlow:a.dataset.sourceFlow,operation:a.dataset.operation,scope:a.dataset.scope,evidence:"INSUFFICIENT"});
    if(k==="bj02-verify-unknown"){stateByScreen["SCR-013"]="PROCESSING_OR_UNKNOWN";return navigate("SCR-013");}
    if(k==="bj02-handoff-unknown")return v350HandoffUnknown({sourceFlow:"UIF-02",operation:"Nhận hàng",scope:"Yêu cầu nhận hàng hiện tại",evidence:"INSUFFICIENT"});


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
  },true);

  // -------------------------------------------------------------------------
  // Actor ownership — decision actions are executable only in the assigned
  // approver/completion context. Navigation/open-sheet actions remain harmless.
  // -------------------------------------------------------------------------
  /* BJ11/BJ12 actor listeners → app/bj11.js / bj12.js (T7-P A8) */

  // -------------------------------------------------------------------------
  /* BJ08 list controls → app/bj08.js (T7-P A7) */

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
    setCf12Control(qty,value){cf12ControlQty=String(qty);cf12ControlValue=String(value);return (typeof bj12ControlMatches==='function'?bj12ControlMatches():false);},
    getCf15Rows(mode=typeof cf15DateMode!=='undefined'?cf15DateMode:'BUSINESS'){return (typeof bj15Movements==='function'?bj15Movements(mode):[]).map(x=>x.id);},
    getState(){return {flow:activeFlowId,screen:activeScreenId,state:stateByScreen[activeScreenId]};},
    getIC10(){return window.__VET45_BJ10__?.getIC10?.()||{};},
    getIC09(){return window.__VET45_V3101__?{draft:window.__VET45_V3101__.getDraft?.(),basis:window.__VET45_V3101__.getBasis?.(),current:typeof ic09Current==='function'?ic09Current():null}:{};},
    getBJ17(){const c=cr17Current();return {id:c.id,operation:c.operation,evidenceVersion:c.evidenceVersion,record:c.resolutionRecord};}
  };

  // Final render after correcting entry routing and effective renderer table.
  syncReviewUrl(); /* load-time render removed T7-P A7 */
})();

/* v351 → bj09.js / bj15.js (T7-P A9) */

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
  /* BJ08 session cancel / SCR-044/045 inject moved to bj08.js (T7-P A7) */

  // Representative-state coherence. These seeds are only for direct Inspector
  // entry to READY review screens; normal user transitions already populate
  // the same prerequisites and are never overwritten.
  // -----------------------------------------------------------------------
  function ensureRepresentativeFixture(){
    /* ensureIo07ReviewFixture moved to bj07.js */
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
  /* toastRules cr11/cf12 → bj11 submit-correction toast (T7-P A8) */

  // -----------------------------------------------------------------------
  // Stable exit paths (fallback-exit).
  // -----------------------------------------------------------------------
  /* v360 ic08-cancel-reason listener removed (T7-P A7) */

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
  syncReviewUrl(); /* load-time render removed T7-P A7 */
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

/* legacy-sheet-cleanup → bj15.js sheets (T7-P A9) */

/* ===== legacy-cross-theme-copy (từ v390) ===== */
/* Legacy, xoá dần khi BJ-02 / 06 / 09 / 17 được viết lại ở T7-P: sửa chữ sau khi dựng màn. */
(()=>{
  function polishCrossThemeCopy(){
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


/* v3100 BJ-08 moved to app/bj08.js (T7-P A7) */

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




