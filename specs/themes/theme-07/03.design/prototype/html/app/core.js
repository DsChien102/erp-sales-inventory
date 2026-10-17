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
/* ic09Items moved to app/bj09.js (T7-P A6) */
function icCard(title,body){const calibrated=FIGMA_MIGRATED_FLOWS.has(activeFlowId);return `<section class="review-card" data-ds-component="${calibrated?'VSection':'VCard'}" ${calibrated?'data-composed-from="VText,DS v2 / Info Row,VTextField"':'data-ds-profile="card.readOnly"'}><div class="review-card-header"><strong>${title}</strong></div><div class="review-card-body">${body}</div></section>`;}
function icField(label,value,attr="",type="text",hint=""){return `<div class="form-field" data-ds-component="${type==='number'?'VNumberField':'VTextField'}"><label>${label}</label><div class="input-shell"><input type="${type}" value="${escapeAttribute(value)}" ${attr}></div>${hint?`<small class="helper-text">${hint}</small>`:""}</div>`;}
function icTextarea(label,value,attr="",placeholder=""){return `<div class="form-field ic-textarea-field" data-ds-component="VTextarea" data-figma-node="522:7212"><label>${label}</label><textarea class="textarea" ${attr} placeholder="${escapeAttribute(placeholder)}">${esc(value)}</textarea></div>`;}
/* icChoice moved to app/bj09.js (T7-P A6) */
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

/* ic09StatusTone moved (T7-P A6) */
/* ic09Current moved (T7-P A6) */
/* render036IC09 moved (T7-P A6) */
/* render037IC09 moved (T7-P A6) */
/* render038IC09 moved (T7-P A6) */
/* render041IC09 moved (T7-P A6) */
function render056IC09(state){
  if(activeFlowId!=="UIF-09") return renderGeneric(screens.find(s=>s.id==="SCR-056"),state);
  if(state==="PERMISSION_DENIED")return appShell({title:"Lịch sử tình trạng",body:deniedBody(),centered:true});
  if(state==="LOADING")return appShell({title:"Lịch sử tình trạng",body:loadingBody()});
  // ic09Current sống ở bj09.js — lần dựng sớm trong core (trước khi nạp bj) bỏ qua.
  if(typeof ic09Current!=="function") return appShell({title:"Lịch sử tình trạng",body:loadingBody()});
  const x=ic09Current();
  const body=`${icHeaderRows([["Sản phẩm",x.name,true],["Lô",x.lot]])}<div class="timeline"><div class="timeline-card">${ioMetaRow("07/09/2026 · 09:14","Bán được → Cách ly",true)}<small>Nguyễn An · Bao bì có dấu hiệu bất thường</small></div><div class="timeline-card">${ioMetaRow("01/09/2026 · 08:00","Nhận vào kho",true)}<small>Tình trạng ban đầu: Bán được</small></div></div>`;
  return appShell({title:"Lịch sử tình trạng",body});
}

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

const renderers = {"SCR-048":render048CR11,"SCR-049":render049CR11,"SCR-050":render050CR11,"SCR-051":render051CR11,"SCR-052":render052CR11,"SCR-053":render053CR11,"SCR-078":render078CR,"SCR-079":render079CR,"SCR-080":render080CR,"SCR-081":render081CR,"SCR-082":render082CR,"SCR-083":render083CR,"SCR-042":render042IC08,"SCR-043":render043IC08,"SCR-044":render044IC08,"SCR-045":render045IC08,"SCR-046":render046IC08,"SCR-047":render047IC08,"SCR-054":render054CF15,"SCR-055":render055CF15,"SCR-056":render056CF15,"SCR-057":render057CF15,"SCR-058":render058CF15,"SCR-059":render059CF15,"SCR-066":render066CF12,"SCR-067":render067CF12,"SCR-068":render068CF12,"SCR-069":render069CF12,"SCR-070":render070CF12,"SCR-071":render071CF12};
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
/* ac310Render036 removed (T7-P A6) */
/* ac310Render037 removed (T7-P A6) */
function ac310StateLabel(value){return value==="QUARANTINE"?"Cách ly":value==="DAMAGED"?"Hỏng":value==="DEMO"?"Dùng thử":"Bán được";}
/* ac310Render038 removed (T7-P A6) */
/* ac310Render041 removed (T7-P A6) */
function ac310Render056(state){
  if(activeFlowId==="UIF-09"){
    if(!["READY","LOADING","PERMISSION_DENIED"].includes(state)) return ac310Base("SCR-056",state);
    if(state!=="READY") return ac310Base("SCR-056",state);
    if(typeof ic09Current!=="function") return ac310Base("SCR-056",state);
    const x=ic09Current();
    const body=`${ac310ProductRow({name:x.name,code:x.code,meta:`Lô ${x.lot}`,badge:x.label,tone:ic09StatusTone(x.state),status:true})}${ac310AuditSurface("Lịch sử",[ac310AuditItem("Update","Bán được → Cách ly","07/09/2026 · 09:14 · Nguyễn An · Bao bì có dấu hiệu bất thường"),ac310AuditItem("Create","Nhận vào kho","01/09/2026 · 08:00 · Tình trạng ban đầu: Bán được")])}`;
    return ac310Return(appShell({title:"Lịch sử tình trạng",body}));
  }
  if(activeFlowId==="UIF-15") return ac310Render056CF15(state);
  return ac310Base("SCR-056",state);
}

/* ------------------------------ BJ10 ----------------------------------- */
/* ac310Render040 removed (T7-P A6) */

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
    ["SCR-047","UIF-08",()=>({sourceFlow:"UIF-08",operation:"KK-0709-03",scope:"Kho trung tâm · phiên kiểm kê"})],
    ["SCR-066","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})],
    ["SCR-071","UIF-12",()=>({sourceFlow:"UIF-12",operation:"Khởi tạo tồn kho đầu kỳ",scope:`Kho trung tâm · ${cfDateVN(cf12Cutoff)}`})]
  ];unknowns.forEach(x=>wrapUnknown(...x));
  // BJ02 verify/handoff-unknown: giữ listener data-v350-action (A10); wrapper SCR-012/013 đã chết (v392).

  // BJ11 navigation action must not create finality.
  const v350Render051Base=renderers["SCR-051"];
  renderers["SCR-051"]=(state)=>activeFlowId==="UIF-11"?v350Render051Base(state).replace(/data-cr11-action="approval-result"/g,'data-v350-action="cr11-approval-result"'):v350Render051Base(state);

  // -------------------------------------------------------------------------
  // Event binding for v3.5.0 controls.
  // -------------------------------------------------------------------------
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
    getIC10(){return window.__VET45_BJ10__?.getIC10?.()||{};},
    getIC09(){return window.__VET45_V3101__?{draft:window.__VET45_V3101__.getDraft?.(),basis:window.__VET45_V3101__.getBasis?.(),current:typeof ic09Current==='function'?ic09Current():null}:{};},
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
  const toastRules=[
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


