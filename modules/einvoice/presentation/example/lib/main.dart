import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview/overview_tab.dart';
import 'preview/sg01_tab.dart';
import 'preview/sg02_tab.dart';
import 'preview/sg03_tab.dart';
import 'preview/sg06_tab.dart';
import 'preview/sg07_tab.dart';

void main() {
  runApp(const EInvoicePresentationExampleApp());
}

class EInvoicePresentationExampleApp extends StatelessWidget {
  const EInvoicePresentationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 E-Invoice Presentation Preview',
      theme: VTheme.lightTheme,
      home: const EInvoicePreviewHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EInvoicePreviewHomeScreen extends StatefulWidget {
  const EInvoicePreviewHomeScreen({super.key});

  @override
  State<EInvoicePreviewHomeScreen> createState() =>
      _EInvoicePreviewHomeScreenState();
}

class _EInvoicePreviewHomeScreenState extends State<EInvoicePreviewHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    'Overview',
    'SG-01',
    'SG-02',
    'SG-03',
    'SG-06',
    'SG-07',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Invoice presentation preview'),
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
            EInvoiceOverviewTab(),
            EInvoiceSg01Tab(),
            EInvoiceSg02Tab(),
            EInvoiceSg03Tab(),
            EInvoiceSg06Tab(),
            EInvoiceSg07Tab(),
          ],
        ),
      ),
    );
  }
}
