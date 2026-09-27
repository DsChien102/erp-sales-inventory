# VET45 Flutter Design System — Public Component Catalog

Nguồn: public barrel `lib/design_system.dart` trong `vet45_design_system` version `1.0.0`.

> Flutter package là source of truth. HTML đi kèm chỉ là static reference renderer, không phải một Design System thứ hai.

## Foundations & theme

- **`VColors`** — Primitive color palette; chỉ dùng để xây theme.
- **`VColorScheme`** — Semantic color roles cho light/dark theme.
- **`VTheme`** — Material 3 ThemeData của VET45.
- **`VDensity / VDensityMode`** — Comfortable và compact control metrics.
- **`VSpacing`** — Spacing, screen padding và touch target.
- **`VRadius`** — Radius cho input, button, card, sheet, pill.
- **`VBorders`** — Border widths/factories.
- **`VBreakpoints / VBreakpoint`** — mobile < 600; tablet 600–1023; desktop ≥ 1024.
- **`VTypography`** — Inter + JetBrains Mono type roles.
- **`VShadows`** — Elevation e1–e4.
- **`VDuration`** — Motion durations.
- **`VAssets`** — Asset path registry.
- **`VIcons`** — Canonical icon enum.
- **`VComponentTone / Emphasis / State`** — Shared semantic contracts.

## Layout & responsive patterns

- **`VGap`** — Tokenized horizontal/vertical gaps.
- **`VPagePadding`** — Responsive page inset.
- **`VSection`** — Section title/subtitle/trailing/content composition.
- **`VPageScaffold`** — App bar + body + optional bottom bar shell.
- **`VResponsive / VResponsiveValue`** — Breakpoint-aware value/widget selection.
- **`VResponsiveVisibility`** — Breakpoint visibility control.
- **`VContentWidth`** — Readable/max content width constraint.
- **`VResponsiveGrid`** — Responsive grid layout.

## Primitives

- **`VText`** — Typography primitive using VTextVariant.
- **`VIcon`** — Canonical icon renderer.
- **`VIconBox`** — Icon/label container with semantic tone.
- **`VBadge`** — Status badge; maps VBadgeStatus to tone.
- **`VChip`** — Static, selectable, or removable chip.
- **`VSkeleton / VSkeletonScope`** — Pulse skeleton bones and shared animation scope.

## Core components

- **`VAvatar`** — Avatar image/initials presentation.
- **`VBanner`** — Persistent inline feedback banner.
- **`VButton`** — Primary/secondary/tertiary/link action.
- **`VCard`** — Container with tone/emphasis.
- **`VCardHeader / VCardIcon / VCardTitle / VCardAction / VCardContent / VCardFooter`** — Composable card anatomy.
- **`VCheckbox`** — Boolean toggle.
- **`VRadio<T>`** — Mutually exclusive selection.
- **`VSwitch`** — Immediate on/off toggle.
- **`VFloatingActionButton`** — 56px circular action.
- **`VTextField`** — Full input contract.
- **`VTextFormField`** — Form-integrated text input.
- **`VVerificationCodeField`** — OTP/code cells; numeric or alphanumeric.
- **`VSearchBar`** — outlined / filled / header variants.
- **`VTabs`** — Tab navigation with disabled indices.
- **`VEmptyState`** — Composable empty/status surface.
- **`VEmptyHeader / VEmptyMedia / VEmptyTitle / VEmptyDescription / VEmptyContent`** — Empty-state anatomy.
- **`VFileDropZone`** — empty / valid / invalid / disabled file input.
- **`VToast`** — Transient success/warning/danger/info feedback.
- **`VCombobox<T>`** — Searchable selection overlay.
- **`VQuantitySelector`** — Increment/decrement quantity input.
- **`VBottomNavigationBar / VBottomNavigationItem`** — Mobile bottom navigation.
- **`VConfirmDialog / showVConfirmDialog`** — Confirmation overlay shell.
- **`VBottomSheet / showVBottomSheet`** — Bottom-sheet overlay shell.
- **`VAppBar / VAppBarTitle / VAppBarSubtitle`** — Top navigation chrome.
- **`VTable / VTableHeader`** — Simple semantic table.
- **`VLoading`** — Spinner, task loading, and modal loading.
- **`VSteps / VStepItem`** — horizontal or list stepper.
- **`VProgress`** — Determinate progress bar.
- **`VSegmentedControl`** — 2–4 mutually exclusive segments.
- **`VSwipeActionRecord`** — Record row with swipe actions.
- **`VNumericKeypadSheet / showVNumericKeypadSheet`** — Money/quantity bottom keypad.
- **`VSwipeReveal`** — Generic swipe-to-reveal interaction shell.

## High-level form components

- **`VEmailField`** — Email input + validator contract.
- **`VPasswordField`** — Password visibility and validation.
- **`VMoneyField`** — Money formatting/validation.
- **`VNumberField`** — Numeric formatting/validation.
- **`VSelect<T>`** — Selection field.
- **`VChoiceList<T> / VChoiceOption<T>`** — Single/multiple choice list model and UI.
- **`VDatePicker`** — Date field + picker flow.

## Supporting non-visual APIs

- **`VEmailValidator / VPasswordValidator / VMoneyValidator / VNumberValidator / VSelectValidator / VChoiceListValidator`** — Validators; không phải visual components.
- **`VMoneyInputFormatter / VNumberInputFormatter`** — Input formatters; không phải visual components.
- **`VComponentAuditEntry`** — Audit metadata.
