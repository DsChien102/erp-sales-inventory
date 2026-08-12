# Theme 7 — HTML ↔ Figma DS mapping v2.1.0

Authority: **live Figma Design System v2.0.2**. v2.1.0 completes Phase 4 across all active Theme 7 Product screens. Legacy keys remain only for traceability; active Product resolution must not land on migration-debt statuses.

Mapping precedence: `Theme component → DS internal slot → component+profile → component`.

## Component / legacy construct

| Source key | Mapping status | Figma target | Node | Layer | Note |
|---|---|---|---|---|---|
| `VAppBar` | `EXACT` | VAppBar | `547:1594` | COMPONENT |  |
| `VAppBarSubtitle` | `OWNED_SLOT` | VAppBar | `547:1594` | COMPONENT | Subtitle/context slot of VAppBar. |
| `VAppBarTitle` | `OWNED_SLOT` | VAppBar | `547:1594` | COMPONENT | Title slot of VAppBar. |
| `VBadge` | `EXACT` | VBadge | `525:309` | COMPONENT |  |
| `VBanner` | `EXACT` | VBanner | `526:4215` | COMPONENT |  |
| `VBottomSheet` | `CONTEXTUAL_PATTERN` | Bottom-sheet shell | `—` | COMPOSITION | Shell only. Exact product pattern is contextual: Action Sheet / Confirmation Sheet / Filter Sheet / Select Sheet / Form Sheet. |
| `VButton` | `EXACT` | VButton | `521:529` | COMPONENT |  |
| `VCard` | `CONTEXTUAL_CARD` | Contextual data-display surface | `—` | COMPOSITION | Legacy generic card key is retained for trace only. Phase 4 active Product renders must not resolve to VCard; use a canonical data-display asset or justified VSection composition. |
| `VCardIcon` | `OWNED_SLOT` | VET45 approved Icon Library | `—` | FOUNDATION | Owned content slot; resolve icon tone/size through semantic icon variables. |
| `VCardTitle` | `OWNED_SLOT` | VET45 v2 Typography styles | `—` | FOUNDATION | Owned content slot; resolve text style by card family/context. |
| `VCheckbox` | `EXACT` | VCheckbox | `522:7397` | COMPONENT |  |
| `VChip` | `EXACT` | VChip | `522:7449` | COMPONENT |  |
| `VChoiceList` | `COMPOSITION` | Choice group from VRadio / VCheckbox | `—` | COMPOSITION | No standalone ChoiceList master in live DS; compose canonical selection controls. |
| `VCombobox` | `CONTEXTUAL_PATTERN` | DS v2 / Search Results Dropdown | `1280:6272` | PATTERN | Combobox behavior decomposes to canonical field/search + Search Results Dropdown; product semantics choose Product or Entity result pattern. |
| `VConfirmDialog` | `LEGACY_ALIAS` | DS v2 / Confirmation Sheet | `550:1058` | PATTERN | Destructive confirmation is a pattern responsibility, not a custom dialog. |
| `VDatePicker` | `EXACT` | VDatePicker | `522:7368` | COMPONENT |  |
| `VDatePickerField` | `LEGACY_ALIAS` | VDatePicker | `522:7368` | COMPONENT | Legacy field alias resolves to canonical VDatePicker. |
| `VEmptyDescription` | `OWNED_SLOT` | VEmptyState | `526:4352` | COMPONENT | Description slot of VEmptyState; not a separate component master. |
| `VEmptyMedia` | `OWNED_SLOT` | VEmptyState | `526:4352` | COMPONENT | Media slot of VEmptyState; not a separate component master. |
| `VEmptyState` | `EXACT` | VEmptyState | `526:4352` | COMPONENT |  |
| `VEmptyTitle` | `OWNED_SLOT` | VEmptyState | `526:4352` | COMPONENT | Title slot of VEmptyState; not a separate component master. |
| `VFileDropZone` | `EXACT` | VFileDropZone | `522:7507` | COMPONENT |  |
| `VIcon` | `EXACT_FOUNDATION` | VET45 approved Icon Library | `—` | FOUNDATION | Use the canonical icon registry / Lucide-backed VET45 icon instances; icon size and touch target remain independent. |
| `VIconBox` | `COMPOSITION` | Icon presentation container | `—` | COMPOSITION | Non-interactive icon container is a composition. Interactive icon-only actions must use DS v2 / Icon Button. |
| `VLoading` | `EXACT` | VLoading | `526:4373` | COMPONENT |  |
| `VModal` | `EXACT` | VModal | `550:1275` | COMPONENT |  |
| `VMoneyField` | `EXACT` | VMoneyField | `522:7322` | COMPONENT |  |
| `VNumberField` | `LEGACY_ALIAS` | VTextField | `522:7186` | COMPONENT | Numeric input uses VTextField semantics. Numeric keypad overlay, where required, uses VNumericKeypadSheet. |
| `VNumericKeypadSheet` | `EXACT` | VNumericKeypadSheet | `1829:16196` | COMPONENT |  |
| `VPagePadding` | `EXACT_FOUNDATION` | Layout/Mobile edge = 16 | `—` | FOUNDATION | Page body/footer horizontal padding is foundation layout responsibility. |
| `VPageScaffold` | `CONTEXTUAL` | Mobile / Detail | `551:1396` | TEMPLATE | Legacy scaffold has no 1:1 template. Phase 3/4 selects Root List / Nested List / Detail / Form / Wizard / Search & Select / State from screen task and entry architecture. |
| `VProgress` | `EXACT` | VProgress | `526:4386` | COMPONENT |  |
| `VQuantitySelector` | `LEGACY_ALIAS` | VTextField | `522:7186` | COMPONENT | Phase 4: historical plain quantity annotations are normalized to canonical VTextField; no active Theme 7 Product render uses VQuantitySelector. |
| `VRadio` | `EXACT` | VRadio | `522:7410` | COMPONENT |  |
| `VSearchBar` | `EXACT` | VSearchBar | `522:7245` | COMPONENT |  |
| `VSection` | `COMPOSITION` | Section layout | `—` | COMPOSITION | Semantic section/layout wrapper; uses foundation spacing and typography rather than inventing a reusable visual component. |
| `VSegmentedButton` | `LEGACY_ALIAS` | VSegmentedControl  | `1049:9619` | COMPONENT | Legacy segmented button/group must normalize to VSegmentedControl. |
| `VSegmentedControl` | `EXACT` | VSegmentedControl  | `1049:9619` | COMPONENT |  |
| `VSegmentedControlItem` | `OWNED_SLOT` | VSegmentedControl  | `1049:9619` | COMPONENT | Segment item is owned by the canonical control. |
| `VSelect` | `EXACT` | VSelect | `522:7291` | COMPONENT |  |
| `VSkeleton` | `EXACT` | VSkeleton | `526:4380` | COMPONENT |  |
| `VSwitch` | `EXACT` | VSwitch | `522:7427` | COMPONENT |  |
| `VText` | `EXACT_FOUNDATION` | VET45 v2 Typography styles | `—` | FOUNDATION | Resolve to the canonical text style by semantic role; legacy VText is a primitive, not a Components-page master. |
| `VTextField` | `EXACT` | VTextField | `522:7186` | COMPONENT |  |
| `VTextFormField` | `LEGACY_ALIAS` | VTextField | `522:7186` | COMPONENT | Single-line legacy fields map to VTextField; multiline instances map to VTextarea via runtime resolver. |
| `VTextarea` | `EXACT` | VTextarea | `522:7212` | COMPONENT |  |
| `VToast` | `EXACT` | VToast | `526:4305` | COMPONENT |  |

## Profile override

| Source key | Mapping status | Figma target | Node | Layer | Note |
|---|---|---|---|---|---|
| `VBottomSheet|approval.reject` | `EXACT_PATTERN` | DS v2 / Confirmation Sheet | `550:1058` | PATTERN | Approval rejection with reason is confirmation/form-sheet composition; no custom bottom-sheet convention. |
| `VButton|button.destructiveSecondary` | `EXACT` | VButton | `521:529` | COMPONENT | Destructive action normalizes to Danger hierarchy; no custom destructive-secondary component. |
| `VButton|button.primaryFooter` | `EXACT_PATTERN` | DS v2 / Sticky Footer | `549:927` | PATTERN | Footer composition is governed by Sticky Footer and contains canonical VButton. |
| `VButton|button.secondary` | `EXACT` | VButton | `521:529` | COMPONENT | Secondary hierarchy normalized at runtime. |
| `VCard|card.interactive` | `CONTEXTUAL_CARD` | Interactive record/list item | `—` | COMPOSITION | Legacy trace only. Phase 4 active Product UI must resolve interactive records to DS v2 / List Row / Record Card or justified composition. |
| `VCard|card.readOnly` | `CONTEXTUAL_CARD` | Read-only data display | `—` | COMPOSITION | Legacy trace only. Phase 4 active Product UI must resolve read-only data to Summary Card / Info Row / Key-value Row / Record Card or justified composition. |
| `VPagePadding|screen.body.standard` | `EXACT_FOUNDATION` | Layout/Mobile edge = 16 | `—` | FOUNDATION | Canonical mobile body gutter. |
| `VPageScaffold|screen.shell.standard` | `CONTEXTUAL` | Mobile / Detail | `551:1396` | TEMPLATE | Screen template chosen by task/surface in Phase 3/4; scaffold itself is not a canonical component. |
| `VSearchBar|search.standard` | `CONTEXTUAL_PATTERN` | DS v2 / Search & Filter Header | `547:2306` | PATTERN | When search and filter participate in list discovery, use Search & Filter Header; search-only remains VSearchBar. |

## Theme 7 composition

| Source key | Mapping status | Figma target | Node | Layer | Note |
|---|---|---|---|---|---|
| `InventoryOperationItemRow` | `LEGACY_ALIAS` | DS v2 / List Row | `525:519` | COMPONENT | Phase 4: legacy annotation is bypassed in all active UIFs; active operational rows render canonical DS v2 / List Row. |
| `InventoryTaskFilterRow` | `LEGACY_ALIAS` | DS v2 / Search & Filter Header | `547:2306` | PATTERN | Phase 4: legacy filter-row key is retained for trace only; active list discovery composes canonical VSearchBar/VChip under Figma list-pattern responsibility. |
| `LotAllocationSection` | `COMPOSITION` | Allocation section from canonical rows/fields | `—` | COMPOSITION | Phase 4: allocation editor is a screen-local composition from canonical form fields, date input and actions; no custom DS master is introduced. |
| `OperationEvidenceTimeline` | `EXACT` | DS v2 / Timeline Item | `525:587` | COMPONENT | Phase 4: repeated operation evidence events use canonical DS v2 / Timeline Item. |
| `PermissionDeniedState` | `EXACT` | VEmptyState | `526:4352` | COMPONENT | Use Type=No Permission. |
| `PickLotAllocation` | `COMPOSITION` | LOT allocation from List Row + quantity input | `—` | COMPOSITION | Phase 4: LOT allocation is a business composition from canonical list/fact/form primitives; no standalone DS component is invented. |
| `ReceivingBalanceSummary` | `EXACT` | DS v2 / Summary Card | `525:552` | COMPONENT | Phase 4: receiving balance summary uses DS v2 / Summary Card responsibility. |
| `ReceivingLotEditor` | `COMPOSITION` | Form composition under Mobile / Form | `—` | COMPOSITION | Phase 4: nested LOT editor follows Mobile / Form anatomy using canonical fields; it is not itself a page-template instance. |
| `ReceivingProductSummary` | `EXACT` | DS v2 / Summary Card | `525:552` | COMPONENT | Phase 4: selected-product summary uses canonical DS v2 / Summary Card. |
| `ReturnLotMismatchReasons` | `COMPOSITION` | Single-choice group from VRadio | `—` | COMPOSITION | Phase 4: audited mismatch reasons are a single-choice group composed from canonical VRadio semantics. |
| `Theme7EvidenceTimeline` | `COMPOSITION` | Timeline from DS v2 / Timeline Item | `—` | COMPOSITION | Phase 4: timeline container is layout-only; events use canonical Timeline Item responsibility. |
| `Theme7InlineSingleChoice` | `COMPOSITION` | Selection group from DS v2 / List Row | `—` | COMPOSITION | Phase 4: full-row mobile choice uses canonical DS v2 / List Row Type=Selection rather than a feature-specific card. |
| `Theme7InventoryEvidenceRows` | `COMPOSITION` | Evidence fact rows from DS v2 / Info Row | `—` | COMPOSITION | Phase 4: evidence container is layout-only; each fact row uses canonical DS v2 / Info Row. |
| `Theme7InventoryFilterRow` | `EXACT_PATTERN` | DS v2 / Search & Filter Header | `547:2306` | PATTERN | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7InventoryLotRow` | `EXACT` | DS v2 / List Row | `525:519` | COMPONENT | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7InventoryProductRow` | `EXACT` | DS v2 / List Row | `525:519` | COMPONENT | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7InventoryProvenanceEntry` | `EXACT` | DS v2 / List Row | `525:519` | COMPONENT | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7InventoryQuantityRow` | `EXACT` | DS v2 / Info Row | `525:351` | COMPONENT | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7InventoryRecordList` | `COMPOSITION` | List container of DS v2 / List Row | `—` | COMPOSITION | Phase 4: layout-only container composed from canonical DS v2 / List Row children. |
| `Theme7InventorySummaryCard` | `EXACT` | DS v2 / Summary Card | `525:552` | COMPONENT | Phase 4: active Theme 7 Product usage is calibrated to the named live Figma asset. |
| `Theme7OperationResult` | `EXACT_PATTERN` | Mobile / State | `551:1746` | TEMPLATE | Phase 4: authoritative operation results use Mobile / State responsibility with VEmptyState/result facts; behavior remains business-defined. |
| `Theme7QuickReceiptProductSearch` | `EXACT_PATTERN` | DS v2 / Search Results Dropdown | `1280:6272` | PATTERN | Phase 4: quick product lookup uses canonical Search Results Dropdown/Product responsibility with VSearchBar. |

## Internal slot

| Source key | Mapping status | Figma target | Node | Layer | Note |
|---|---|---|---|---|---|
| `VAppBar.leading` | `OWNED_SLOT` | VAppBar | `547:1594` | COMPONENT | Leading navigation slot owned by VAppBar. |
| `VBanner.copy` | `OWNED_SLOT` | VBanner | `526:4215` | COMPONENT | Copy slot owned by VBanner. |
| `VBanner.icon` | `OWNED_SLOT` | VBanner | `526:4215` | COMPONENT | Icon slot owned by VBanner. |
| `VBottomSheet.divider` | `OWNED_SLOT` | Bottom-sheet pattern divider | `—` | COMPOSITION | Pattern-internal separator. |
| `VBottomSheet.handle` | `OWNED_SLOT` | Bottom-sheet pattern handle | `—` | COMPOSITION | Pattern-internal presentation; not a standalone Product component. |
| `VBottomSheet.title` | `OWNED_SLOT` | Bottom-sheet pattern title | `—` | COMPOSITION | Pattern-internal title slot. |
| `VLoading.CircularProgressIndicator` | `OWNED_SLOT` | VLoading | `526:4373` | COMPONENT | Internal loading indicator owned by VLoading. |
| `VToast.close` | `OWNED_SLOT` | VToast | `526:4305` | COMPONENT | Close affordance owned by VToast. |
| `VToast.message` | `OWNED_SLOT` | VToast | `526:4305` | COMPONENT | Message slot owned by VToast. |
| `showVBottomSheet.SafeArea` | `IMPLEMENTATION_DETAIL` | Bottom-sheet safe-area behavior | `—` | COMPOSITION | Pattern implementation detail; never exposed as Product component. |

## Phase 4 release boundary

- Business/behavior: frozen from cumulative v1.9.0 through parent v2.0.2.
- UI authority: live Figma DS v2.0.2.
- Active Product scope: 17 UIF · 73 distinct canonical screens · 497 state renders.
- Active mapping gate: zero `MIGRATION_TARGET`, zero `OPEN_DS_GAP`, zero `CONTEXTUAL_CARD`.
- `VCard`, Flutter aliases and other legacy constructs may remain in the registry only as provenance/migration input; they are not current Product UI authority.
