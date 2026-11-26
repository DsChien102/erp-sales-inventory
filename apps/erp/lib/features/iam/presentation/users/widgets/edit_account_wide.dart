import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';

/// Bố cục web của Chỉnh sửa thông tin (ID-22): một thẻ cột 560.
class EditAccountWide extends StatelessWidget {
  const EditAccountWide({
    super.key,
    required this.fullName,
    required this.email,
    required this.lastNameField,
    required this.firstNameField,
    required this.phoneField,
    required this.emailField,
  });

  final String fullName;
  final String email;
  final Widget lastNameField;
  final Widget firstNameField;
  final Widget phoneField;
  final Widget emailField;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final initials = VAvatar(name: fullName).label;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.screenDesktop),
      child: FlowCard(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DetailAvatar(initials, size: 48),
                const SizedBox(width: VSpacing.space4),
                Expanded(
                  child: VText(
                    'Ảnh đại diện',
                    variant: VTextVariant.bodyDefault,
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.borderDefault,
              ),
            ),
            lastNameField,
            const SizedBox(height: VSpacing.space4),
            firstNameField,
            const SizedBox(height: VSpacing.space4),
            phoneField,
            const SizedBox(height: VSpacing.space4),
            emailField,
          ],
        ),
      ),
    );
  }
}
