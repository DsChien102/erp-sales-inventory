import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Skeleton của SG-04 picker khi đang tải / tìm kiếm.
///
/// Giữ đúng layout của [SalesCustomerPickerBody] state loaded: nhãn đếm (khi
/// [showResultCount]) rồi danh sách thẻ khách hàng.
class SalesCustomerPickerLoadingState extends StatelessWidget {
  const SalesCustomerPickerLoadingState({
    super.key,
    this.showResultCount = true,
    this.itemCount = 5,
  });

  final bool showResultCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return VSkeletonScope(
      key: const Key('wgt_sg04_loading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showResultCount) ...[
            const VPagePadding(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: VSkeleton(width: 120, height: 20),
              ),
            ),
            const VGap.sm(),
          ],
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.screenMobile,
                0,
                VSpacing.screenMobile,
                VSpacing.space2,
              ),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const VGap.sm(),
              itemBuilder: (_, _) => const VSkeleton(height: 72),
            ),
          ),
        ],
      ),
    );
  }
}
