import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'partner/main.dart' as partner show PartnerPreviewHomeScreen;

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
            title: const Text('Partner'),
            subtitle: const Text('List / detail / create / sheets'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const partner.PartnerPreviewHomeScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
