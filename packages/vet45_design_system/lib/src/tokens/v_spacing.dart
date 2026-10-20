/// Spacing scale on a 4px base: 4, 8, 12, 16, 20, 24, 32, 40, 48, 72.
///
/// Rhythm in use (see DESIGN.md → Layout):
/// - [space1] (4): icon ↔ text, label ↔ its own caption.
/// - [space2] (8): related elements inside one group.
/// - [space3] (12): rows inside a list / control padding.
/// - [space4] (16): between blocks and inside cards (default).
/// - [space6] (24) and up: separation between groups / sections.
///
/// Prefer the semantic ladder ([xs]…[xxl]) in layouts; use the numeric steps
/// when a value must match a documented component measurement.
class VSpacing {
  VSpacing._();

  /// 1px optical nudge (e.g. inset that clears a 1px border). Not a step of the
  /// scale: it never replaces a gap between elements.
  static const double hairline = 1;

  @Deprecated('Use VSpacing.hairline: this is 1px, not a zero step.')
  static const double space0 = hairline;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space18 = 72;

  static const double minTouchTarget = 44;
  static const double controlCompact = 34;

  /// Semantic ladder: [xs] 4 · [sm] 8 · [cozy] 12 · [md] 16 · [lg] 24 · [xl] 32 · [xxl] 40.
  static const double xs = space1;
  static const double sm = space2;
  static const double cozy = space3;
  static const double md = space4;
  static const double lg = space6;
  static const double xl = space8;
  static const double xxl = space10;

  /// Horizontal screen inset per breakpoint: mobile / tablet / desktop.
  static const double screenMobile = 16;
  static const double screenTablet = 24;
  static const double screenDesktop = 32;
}
