import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SalesResultLoadingView extends StatelessWidget {
  const SalesResultLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VLoading(),
          VGap.md(),
          VText('Đang tải kết quả bán hàng...'),
        ],
      ),
    );
  }
}
