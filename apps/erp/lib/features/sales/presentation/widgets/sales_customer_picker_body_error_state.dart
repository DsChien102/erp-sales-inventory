import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Lỗi tải / tìm kiếm trong vùng list picker.
class SalesCustomerPickerBodyErrorState extends StatelessWidget {
  const SalesCustomerPickerBodyErrorState({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return VEmptyState(
      key: const Key('wgt_sg04_error'),
      child: Column(
        children: [
          VEmptyHeader(
            tone: VComponentTone.danger,
            children: [
              const VEmptyMedia(icon: VIcons.warning),
              VEmptyTitle(title),
              VEmptyDescription(description),
            ],
          ),
        ],
      ),
    );
  }
}
