import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview/overview_tab.dart';
import 'preview/sg01_drafts_tab.dart';
import 'preview/sg02_compose_tab.dart';
import 'preview/sg03_product_picker_tab.dart';
import 'preview/sg04_customer_picker_tab.dart';
import 'preview/sg05_checkout_tab.dart';
import 'preview/sg06_result_tab.dart';
import 'preview/sg07_order_list_tab.dart';
import 'preview/sg08_detail_tab.dart';
import 'preview/sg10_cancel_tab.dart';
import 'preview/sg11_session_tab.dart';
import 'preview/sg12_settlement_tab.dart';
import 'preview/sg13_return_result_tab.dart';

void main() {
  runApp(const SalesPresentationExampleApp());
}

class SalesPresentationExampleApp extends StatelessWidget {
  const SalesPresentationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 Sales Presentation Preview',
      theme: VTheme.lightTheme,
      home: const SalesPreviewHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SalesPreviewHomeScreen extends StatefulWidget {
  const SalesPreviewHomeScreen({super.key});

  @override
  State<SalesPreviewHomeScreen> createState() => _SalesPreviewHomeScreenState();
}

class _SalesPreviewHomeScreenState extends State<SalesPreviewHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    'Overview',
    'SG-01',
    'SG-02',
    'SG-03',
    'SG-04',
    'SG-05',
    'SG-06',
    'SG-07',
    'SG-08',
    'SG-10',
    'SG-11',
    'SG-12',
    'SG-13',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales presentation preview'),
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
            SalesOverviewTab(),
            SalesSg01DraftsTab(),
            SalesSg02ComposeTab(),
            SalesSg03ProductPickerTab(),
            SalesSg04CustomerPickerTab(),
            SalesSg05CheckoutTab(),
            SalesSg06ResultTab(),
            SalesSg07OrderListTab(),
            SalesSg08DetailTab(),
            SalesSg10CancelTab(),
            SalesSg11SessionTab(),
            SalesSg12SettlementTab(),
            SalesSg13ReturnResultTab(),
          ],
        ),
      ),
    );
  }
}
