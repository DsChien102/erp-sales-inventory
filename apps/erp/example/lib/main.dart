import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'dashboard/main.dart' as dashboard show DashboardPreviewHomeScreen;
import 'sales/main.dart' as sales show SalesPreviewHomeScreen;

void main() {
  runApp(const ErpPresentationExampleApp());
}

class ErpPresentationExampleApp extends StatelessWidget {
  const ErpPresentationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 ERP Presentation Preview',
      theme: VTheme.lightTheme,
      home: const _CatalogHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _CatalogHome extends StatelessWidget {
  const _CatalogHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ERP presentation catalog')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Dashboard'),
            subtitle: const Text('Default pair gate error'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const dashboard.DashboardPreviewHomeScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Sales'),
            subtitle: const Text('SG-01 … SG-13 widget previews'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const sales.SalesPreviewHomeScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
