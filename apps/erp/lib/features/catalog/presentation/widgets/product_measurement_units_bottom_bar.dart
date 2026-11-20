import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'product_form_bottom_bar.dart';

class ProductMeasurementUnitsBottomBar extends StatelessWidget {
  const ProductMeasurementUnitsBottomBar({
    super.key,
    this.saveEnabled = false,
  });

  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    return ProductFormBottomBar(
      onCancel: () => context.pop(),
      saveEnabled: saveEnabled,
      onSave: saveEnabled ? () => context.pop() : null,
    );
  }
}
