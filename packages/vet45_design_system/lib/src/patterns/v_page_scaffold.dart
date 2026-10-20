import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../components/v_app_bar.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_breakpoints.dart';
import 'v_responsive.dart';

/// Standard ERP page shell: [VAppBar] + scrollable/flexible body + optional bottom bar.
///
/// Phone first: below the tablet breakpoint the body and bottom bar run
/// edge to edge, exactly as before. From the tablet breakpoint up they sit in a
/// centered single column ([defaultContentMaxWidth]) so a counter tablet does
/// not get a stretched phone page; the app bar and the page background still
/// span the window. The column's gutter, not [VPagePadding], is what changes
/// with width: the inset inside the column stays [VSpacing.screenMobile].
///
/// A page that lays out its own panes (master–detail, split cart) passes
/// [fullWidth] and handles width itself.
class VPageScaffold extends StatelessWidget {
  const VPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    required this.body,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
    this.bottomBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.contentMaxWidth = defaultContentMaxWidth,
  });

  /// Single-column task pages: full width on phones, 640 on tablet, 720 on
  /// desktop-width windows (landscape counter tablets, web).
  static const VResponsiveValue<double> defaultContentMaxWidth = VResponsiveValue(
    mobile: double.infinity,
    tablet: 640,
    desktop: 720,
  );

  /// Opt out of the column: body and bottom bar use the whole window width.
  static const VResponsiveValue<double> fullWidth = VResponsiveValue(mobile: double.infinity);

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  /// Max width of the body and [bottomBar] column per breakpoint.
  final VResponsiveValue<double> contentMaxWidth;

  /// Space left of / right of the column at the current window width.
  double _gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final max = contentMaxWidth.resolve(VBreakpoints.ofWidth(width));
    return max >= width ? 0 : (width - max) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      TapRegion(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: context.vColors.background,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          appBar: VAppBar(
            title: title,
            subtitle: subtitle,
            titleStyle: titleStyle,
            leading: leading != null ? vInspectorShow(leading!) : null,
            actions: actions?.map(vInspectorShow).toList(),
            showBackButton: showBackButton,
            centerTitle: centerTitle,
          ),
          // Landscape phones: keep content out from under the notch / island.
          body: SafeArea(
            top: false,
            bottom: false,
            child: _ContentColumn(
              maxWidth: contentMaxWidth,
              child: vInspectorShow(body),
            ),
          ),
          bottomNavigationBar: bottomBar != null
              ? Material(
                  // Hairline, not a shadow: same separation as the bottom nav.
                  color: context.vColors.surface,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: VBorders.side(context.vColors.borderDefault),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: _ContentColumn(
                        maxWidth: contentMaxWidth,
                        child: vInspectorShow(bottomBar!),
                      ),
                    ),
                  ),
                )
              : null,
          floatingActionButton: floatingActionButton != null
              ? Padding(
                  // Follow the column's trailing edge, not the window's.
                  padding: EdgeInsetsDirectional.only(end: _gutter(context)),
                  child: vInspectorShow(floatingActionButton!),
                )
              : null,
        ),
      ),
    );
  }
}

/// Centers [child] in a column of at most [maxWidth] by padding both sides.
///
/// Padding (not Align + ConstrainedBox) keeps the incoming height constraint
/// tight, so a body that fills the page keeps filling it. At or below the
/// column width it adds nothing, so phones are untouched.
class _ContentColumn extends StatelessWidget {
  const _ContentColumn({required this.maxWidth, required this.child});

  final VResponsiveValue<double> maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (!width.isFinite) return vInspectorShow(child);
          final max = maxWidth.resolve(VBreakpoints.ofWidth(width));
          if (max >= width) return vInspectorShow(child);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: (width - max) / 2),
            child: vInspectorShow(child),
          );
        },
      ),
    );
  }
}
