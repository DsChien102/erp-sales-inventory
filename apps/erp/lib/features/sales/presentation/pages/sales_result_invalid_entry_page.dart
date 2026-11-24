import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../navigation/sales_typed_routes.dart';

class SalesResultInvalidEntryPage extends StatelessWidget {
  const SalesResultInvalidEntryPage({super.key});

  @override
  Widget build(BuildContext context) => VPageScaffold(
        key: const Key('wgt_sg06_invalid_result_entry'),
        title: 'Kết quả bán hàng',
        body: Center(
          child: VButton(
            label: 'Quay lại danh sách đơn',
            onPressed: () => context.go(SalesNav.ordersList),
          ),
        ),
      );
}
