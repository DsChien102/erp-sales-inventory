import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../components/v_app_bar.dart';
import '../foundation/v_context_extensions.dart';

/// Standard ERP page shell: [VAppBar] + scrollable/flexible body + optional bottom bar.
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
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.vColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: VAppBar(
        title: title,
        subtitle: subtitle,
        titleStyle: titleStyle,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
        centerTitle: centerTitle,
      ),
      body: body,
      bottomNavigationBar: bottomBar != null
          ? Material(
              color: context.vColors.surface,
              elevation: 8,
              child: SafeArea(top: false, child: bottomBar!),
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
