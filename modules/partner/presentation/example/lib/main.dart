import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview/contact_tab.dart';
import 'preview/create_tab.dart';
import 'preview/detail_tab.dart';
import 'preview/list_tab.dart';
import 'preview/overview_tab.dart';
import 'preview/sheets_tab.dart';
import 'preview/transform_tab.dart';

void main() {
  runApp(const PartnerPresentationExampleApp());
}

class PartnerPresentationExampleApp extends StatelessWidget {
  const PartnerPresentationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 Partner Presentation Preview',
      theme: VTheme.lightTheme,
      home: const PartnerPreviewHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PartnerPreviewHomeScreen extends StatefulWidget {
  const PartnerPreviewHomeScreen({super.key});

  @override
  State<PartnerPreviewHomeScreen> createState() =>
      _PartnerPreviewHomeScreenState();
}

class _PartnerPreviewHomeScreenState extends State<PartnerPreviewHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    'Overview',
    'List',
    'Detail',
    'Create',
    'Contact',
    'Transform',
    'Sheets',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner presentation preview'),
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
            PartnerOverviewTab(),
            PartnerListTab(),
            PartnerDetailTab(),
            PartnerCreateTab(),
            PartnerContactTab(),
            PartnerTransformTab(),
            PartnerSheetsTab(),
          ],
        ),
      ),
    );
  }
}
