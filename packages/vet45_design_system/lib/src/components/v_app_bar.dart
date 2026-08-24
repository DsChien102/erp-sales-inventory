import 'package:flutter/material.dart';
// contract: na tone/emphasis/state
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../primitives/v_text.dart';
import '../primitives/v_icon.dart';
import '../foundations/icons/v_icons.dart';

class VAppBarTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const VAppBarTitle({super.key, required this.title, this.style});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return vInspectorHide(
      VText(
        title,
        style:
            style ??
            VTypography.headingH3.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class VAppBarSubtitle extends StatelessWidget {
  final String text;
  const VAppBarSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return vInspectorHide(
      VText(
        text,
        variant: VTextVariant.caption,
        color: dynamicColors.textSecondary,
      ),
    );
  }
}

class VAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool? centerTitle;

  const VAppBar({
    super.key,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final Widget? resolvedLeading = leading != null
        ? vInspectorShow(leading!)
        : (showBackButton && Navigator.of(context).canPop()
            ? IconButton(
                icon: VIcon(
                  icon: VIcons.chevronLeft,
                  color: dynamicColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null);

    final List<Widget>? resolvedActions = actions
        ?.map((action) => vInspectorShow(action))
        .toList();

    return vInspectorHide(
      AppBar(
        backgroundColor: dynamicColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        title: subtitle != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: centerTitle == true
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  VAppBarTitle(title: title, style: titleStyle),
                  const SizedBox(height: 2),
                  VAppBarSubtitle(text: subtitle!),
                ],
              )
            : VAppBarTitle(title: title, style: titleStyle),
        leading: resolvedLeading,
        actions: resolvedActions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: dynamicColors.borderDefault, height: 1),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64 : kToolbarHeight);
}
