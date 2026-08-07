import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview/components_tab.dart';
import 'preview/forms_tab.dart';
import 'preview/primitives_tab.dart';
import 'preview/tokens_tab.dart';
import 'preview/ui_audit_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 Design System Preview',
      theme: VTheme.lightTheme,
      home: const PreviewHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PreviewHomeScreen extends StatefulWidget {
  const PreviewHomeScreen({super.key});

  @override
  State<PreviewHomeScreen> createState() => _PreviewHomeScreenState();
}

class _PreviewHomeScreenState extends State<PreviewHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    'Tokens',
    'Primitives',
    'Components',
    'Forms',
    'UI Audit',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VET45 Design System Preview'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: colors.surface,
            child: VTabs(
              tabs: _tabs,
              selectedIndex: _currentTab,
              isScrollable: true,
              onTabSelected: (index) {
                setState(() => _currentTab = index);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: const [
            TokensPreviewTab(),
            PrimitivesPreviewTab(),
            ComponentsPreviewTab(),
            FormsPreviewTab(),
            UIAuditTab(),
          ],
        ),
      ),
    );
  }
}
