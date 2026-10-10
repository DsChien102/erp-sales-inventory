import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PlatformOrganizationSearchBar extends StatelessWidget {
  const PlatformOrganizationSearchBar({
    super.key,
    this.controller,
    this.onChanged,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space2,
      ),
      child: VSearchBar(
        hintText: 'Tìm tên hoặc mã tổ chức',
        controller: controller,
        onChanged: onChanged,
      ),
    );
  }
}
