# Component Audit Report

- Generated at: `2026-11-25T23:20:16.751469`
- Matrix: `docs/audit/contract_matrix.yaml`
- Scope: primitives / components / business / patterns / forms widgets

| Category | Class | Role | Tone | Emphasis | State | semanticLabel | Semantics |
|---|---|---|---|---|---|---|---|
| components | `VSheetDialog` | unmapped | Pass (optional) | — (optional) | — (optional) | Pass (optional) | Yes |
| components | `VAppBar` | navigation_chrome | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| components | `VAvatar` | unmapped | Pass (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VBanner` | unmapped | Pass (optional) | — (optional) | — (optional) | Pass (optional) | Yes |
| components | `VBottomNavigationBar` | navigation_chrome | N/A (na) | N/A (na) | N/A+ (na) | — (optional) | Yes |
| components | `VBottomSheet` | overlay_shell | Pass (optional) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VButton` | action | Pass (required) | Pass (required) | Pass (preferred) | Pass (required) | Yes |
| components | `VCard` | container | Pass (optional) | Pass (optional) | Pass (optional) | — (optional) | Yes |
| components | `VCheckbox` | toggle | Pass (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VCombobox` | unmapped | — (optional) | — (optional) | Pass (optional) | Pass (optional) | Yes |
| components | `VComboboxContent` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VComboboxEmpty` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VComboboxInput` | unmapped | — (optional) | — (optional) | Pass (optional) | Pass (optional) | No |
| components | `VComboboxItem` | unmapped | — (optional) | — (optional) | Pass (optional) | — (optional) | No |
| components | `VComboboxList` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VEmptyState` | status_display | Pass (optional) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VFileDropZone` | input | — (optional) | — (optional) | Missing (required) | Pass (required) | Yes |
| components | `VFloatingActionButton` | action | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (required) | Yes |
| components | `VKeyValueRow` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VListRow` | unmapped | — (optional) | — (optional) | Pass (optional) | Pass (optional) | Yes |
| components | `VLoading` | status_display | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VConfirmDialog` | overlay_shell | Pass (optional) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VNumericKeypadSheet` | overlay_shell | Pass (preferred) | Pass (preferred) | Pass (optional) | Pass (preferred) | Yes |
| components | `VProgress` | status_display | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VQuickActionButton` | unmapped | — (optional) | — (optional) | — (optional) | Pass (optional) | Yes |
| components | `VRadio` | toggle | — (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VSearchBar` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VSegmentedControl` | navigation_chrome | Pass (preferred) | Pass (preferred) | Pass (preferred) | Pass (preferred) | Yes |
| components | `VSideNavigation` | unmapped | — (optional) | — (optional) | Pass (optional) | — (optional) | Yes |
| components | `VStepProgress` | unmapped | — (optional) | — (optional) | — (optional) | Pass (optional) | Yes |
| components | `VSteps` | navigation_chrome | — (optional) | N/A (na) | N/A (na) | Pass (required) | Yes |
| components | `VStockRow` | unmapped | — (optional) | — (optional) | — (optional) | Pass (optional) | No |
| components | `VSummaryStrip` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| components | `VSwipeReveal` | unmapped | — (optional) | — (optional) | Pass (optional) | — (optional) | Yes |
| components | `VSwitch` | toggle | Pass (optional) | — (optional) | Pass (required) | Pass (required) | Yes |
| components | `VTable` | container | Pass (optional) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VTabs` | navigation_chrome | Pass (optional) | Pass (optional) | N/A+ (na) | Pass (optional) | Yes |
| components | `VTextArea` | unmapped | Pass (optional) | Pass (optional) | Pass (optional) | Pass (optional) | Yes |
| components | `VTextField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| components | `VTextFormField` | unmapped | Pass (optional) | Pass (optional) | — (optional) | Pass (optional) | No |
| components | `VToast` | status_display | Pass (required) | Pass (optional) | N/A (na) | Pass (preferred) | Yes |
| components | `VVerificationCodeField` | unmapped | Pass (optional) | Pass (optional) | Pass (optional) | Pass (optional) | Yes |
| forms | `VChoiceList` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| forms | `VDatePicker` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| forms | `VEmailField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VMoneyField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VNumberField` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | No |
| forms | `VPasswordField` | unmapped | Pass (optional) | Pass (optional) | Pass (optional) | Pass (optional) | No |
| forms | `VPhoneField` | unmapped | — (optional) | — (optional) | Pass (optional) | Pass (optional) | No |
| forms | `VSelect` | input | Pass (preferred) | Pass (preferred) | Pass (required) | Pass (required) | Yes |
| patterns | `VContentWidth` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VField` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VGap` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VListDetailLayout` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VPagePadding` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VPageScaffold` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | N/A (na) | No |
| patterns | `VResponsive` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VResponsiveGrid` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VResponsiveVisibility` | unmapped | — (optional) | — (optional) | — (optional) | — (optional) | No |
| patterns | `VSection` | container | — (optional) | — (optional) | N/A (na) | — (optional) | No |
| primitives | `VBadge` | status_display | Pass (required) | — (optional) | N/A (na) | Pass (preferred) | Yes |
| primitives | `VChip` | status_display | Pass (required) | Pass (optional) | Pass (optional) | Pass (required) | Yes |
| primitives | `VDivider` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | — (optional) | No |
| primitives | `VIcon` | typography_primitive | N/A (na) | N/A (na) | N/A (na) | — (optional) | Yes |
| primitives | `VIconBox` | status_display | Pass (optional) | — (optional) | N/A (na) | Pass (optional) | Yes |
| primitives | `VSkeleton` | layout_pattern | N/A (na) | N/A (na) | N/A (na) | Pass (preferred) | Yes |
| primitives | `VText` | typography_primitive | Pass (optional) | N/A (na) | N/A (na) | — (optional) | No |
