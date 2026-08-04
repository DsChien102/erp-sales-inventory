# Component Audit Report

- Generated at: `2026-07-29T10:42:46.149714`
- Matrix: `docs/audit/contract_matrix.yaml`
- Scope: primitives / components / business / patterns / forms widgets

| Category | Class | Role | Tone | Emphasis | State | semanticLabel | Semantics |
|---|---|---|---|---|---|---|---|
| business | `VActivityItem` | business_chrome | Pass (preferred) | Pass (preferred) | — (optional) | Pass (preferred) | Yes |
| business | `VCreateOrderButton` | action | Pass (preferred) | Pass (preferred) | — (optional) | Pass (preferred) | Yes |
| business | `VMetricCard` | business_chrome | Pass (preferred) | Pass (preferred) | — (optional) | Pass (preferred) | Yes |
| business | `VRevenueCard` | business_chrome | Pass (preferred) | Pass (preferred) | — (optional) | Pass (preferred) | Yes |
| business | `VTodoItem` | business_chrome | Pass (preferred) | Pass (preferred) | — (optional) | Pass (preferred) | Yes |
| components | `VAppBar` | navigation_chrome | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| components | `VAvatar` | unmapped | Pass (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VBanner` | unmapped | Pass (optional) | — (optional) | — (optional) | Pass (optional) | Yes |
| components | `VBottomNavigationBar` | navigation_chrome | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| components | `VBottomSheet` | overlay_shell | Pass (optional) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VButton` | action | Pass (required) | Pass (required) | Pass (preferred) | Pass (required) | Yes |
| components | `VCard` | container | Pass (optional) | Pass (optional) | N/A (na) | — (optional) | No |
| components | `VCheckbox` | toggle | Pass (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VCompactSearchableDropdown` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VDatePickerField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VDropdown` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VEmptyState` | status_display | Pass (optional) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VFileDropZone` | input | — (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VFloatingActionButton` | action | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (required) | Yes |
| components | `VHomeHeader` | navigation_chrome | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| components | `VLoading` | status_display | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VConfirmDialog` | overlay_shell | Pass (optional) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VNumericKeypadSheet` | overlay_shell | Pass (preferred) | Pass (preferred) | Pass (optional) | Pass (preferred) | Yes |
| components | `VProgress` | status_display | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VQuantitySelector` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VQuickActionButton` | action | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (required) | Yes |
| components | `VRadio` | toggle | Pass (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VSearchBar` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VSearchableDropdown` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VSegmentedControl` | navigation_chrome | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (preferred) | Yes |
| components | `VSteps` | navigation_chrome | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VSwipeActionRecord` | business_chrome | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (preferred) | Yes |
| components | `VSwitch` | toggle | Pass (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VTable` | container | Pass (optional) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VTabs` | navigation_chrome | Pass (optional) | Pass (optional) | N/A (na) | Pass (optional) | Yes |
| components | `VTextField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VTextFormField` | unmapped | Pass (optional) | Pass (optional) | Pass (optional) | Pass (optional) | Yes |
| components | `VToast` | status_display | Pass (required) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| forms | `VChoiceList` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| forms | `VEmailField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VMoneyField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VNumberField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VPasswordField` | unmapped | Pass (optional) | Pass (optional) | Pass (optional) | Pass (optional) | No |
| forms | `VSelect` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| patterns | `VContentWidth` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VGap` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VPagePadding` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VPageScaffold` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VResponsive` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VResponsiveGrid` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VResponsiveVisibility` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VSection` | container | — (optional) | — (optional) | N/A (na) | — (optional) | No |
| primitives | `VBadge` | status_display | Pass (required) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| primitives | `VChip` | status_display | Pass (required) | Pass (required) | Pass (optional) | Pass (required) | Yes |
| primitives | `VIcon` | typography_primitive | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| primitives | `VIconBox` | status_display | Pass (optional) | — (optional) | N/A (na) | — (optional) | No |
| primitives | `VSkeleton` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | Pass (preferred) | Yes |
| primitives | `VText` | typography_primitive | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
