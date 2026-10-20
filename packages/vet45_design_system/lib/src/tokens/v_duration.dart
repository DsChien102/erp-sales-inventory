import 'package:flutter/animation.dart';

/// Motion timing for the design system.
///
/// Motion here explains state (selected, pressed, error, loading) or spatial
/// relationship (a sheet rising from the bottom edge). It never decorates.
/// VET45 is an Operate surface used mid-sale: feedback must read as instant,
/// so routine changes stay at or below [medium] and nothing blocks input.
///
/// ## Rules
///
/// - Enter slower than exit: pair [normal] in with [medium] out.
/// - Pair every duration with a [VCurve]; never leave `Curves.linear`.
/// - Animate paint (color, opacity, transform), not layout. A fade is the
///   default for content that changes size.
/// - Honor reduced motion: when
///   `MediaQuery.disableAnimationsOf(context)` is true, use
///   [Duration.zero] for spatial movement (slide, scale, thumb travel) and
///   keep the color/opacity change itself, because it carries the state.
///   `VSegmentedControl` and `VSwipeReveal` are the reference pattern.
/// - Debounce and polling delays are not motion. Do not borrow these tokens
///   for them.
///
/// ## Components that move
///
/// Status: **live** = already animated in code, **todo** = wanted, not built.
/// Entries marked "hard-coded" should adopt the token when next touched.
///
/// [instant] (100 ms), press feedback on a control that has no splash:
/// - `VButton` primary / secondary / tertiary: fill and border on press,
///   focus. **todo**
/// - `VFloatingActionButton`: fill on press. **todo**
/// - `VNumericKeypadGrid` keys: key background on press. **todo**
///
/// [fast] (150 ms), a control changes state:
/// - `VSegmentedControl`: selected pill and label weight. **live**
/// - `VCheckbox` / `VRadio`: box fill and the check / dot appearing. **todo**
/// - `VSwitch`: track color and thumb travel. **todo**
/// - `VBottomNavigationBar`: active tab icon and label color (the bar has no
///   splash, so this is the only acknowledgement). **todo**
/// - `VCard` with `onTap`: background on press. **todo**
/// - `VFileDropZone`: border and fill while a file is dragged over. **todo**
///
/// [medium] (200 ms), a small element enters or leaves, or any exit:
/// - `VTextFieldFocusRing`: focus ring wash. **live**
/// - `VTabs`: indicator and label (hard-coded 200–250 ms). **live**
/// - `VSwipeReveal`: row settle open / closed (hard-coded 200 ms). **live**
/// - Field error message: fade in under `VTextField` and the typed fields in
///   `forms/` when validation fails. **todo**
/// - `VComboboxList`: options panel fade and short rise on open. **todo**
/// - `VSteps`: a step turning complete (circle fill, connector). **todo**
/// - Exit of [VToast], `VBottomSheet`, `VConfirmDialog`, `VLoading`. **todo**
///
/// [normal] (300 ms), an overlay or banner enters from an edge:
/// - `VProgress`: bar value change (hard-coded 300 ms). **live**
/// - `VBottomSheet` and `VNumericKeypadSheet`: rise from the bottom edge,
///   via `sheetAnimationStyle` on `showModalBottomSheet`. **todo**
/// - `VConfirmDialog` and `VLoading`: fade plus scale from 0.96, via
///   `showDialog` `animationStyle`. **todo**
/// - `VToast` and `VBanner`: slide in from the edge they are anchored to.
///   **todo**
///
/// [slow] (350 ms), reserved. Use only for a movement that crosses most of
/// the screen. No component needs it today.
///
/// [pulse] (1 s), `VSkeleton` shimmer only. **live**, and it stops under
/// reduced motion.
///
/// Out of scope on purpose: `VTable` rows, `VEmptyState`, `VAvatar`,
/// `VCardHeader` and the other static layout pieces. They do not change state,
/// so they do not move.
class VDuration {
  VDuration._();

  /// Press feedback; below the threshold where a delay is perceived.
  static const Duration instant = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 350);

  /// Skeleton / placeholder pulse (shadcn-style).
  static const Duration pulse = Duration(milliseconds: 1000);
}

/// Easing curves paired with [VDuration].
class VCurve {
  VCurve._();

  /// Default for state changes (selection, color, toggle). Matches the curve
  /// `VSegmentedControl` already uses.
  static const Curve standard = Curves.easeOutCubic;

  /// Entrances: starts fast, settles gently. Use with [VDuration.normal].
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);

  /// Exits: accelerates away. Use with [VDuration.medium] or shorter.
  static const Curve exit = Curves.easeInCubic;

  /// Looping pulses such as the skeleton shimmer.
  static const Curve pulse = Curves.easeInOut;
}
