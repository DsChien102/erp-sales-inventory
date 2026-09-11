import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_outlined_field.dart';

class PartnerPrimaryContactSection extends StatelessWidget {
  const PartnerPrimaryContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;

    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VCheckbox(
            key: const Key('switch_add_primary_contact'),
            value: state.primaryContactEnabled,
            label: 'Thêm người liên hệ chính',
            onChanged: (value) => cubit.setPrimaryContactEnabled(value ?? false),
          ),
          if (state.primaryContactEnabled) ...[
            const VGap.md(),
            PartnerOutlinedTextField(
              key: const Key('input_primary_contact_title'),
              label: 'Danh xưng',
              initialValue: state.primaryContactTitle,
              hintText: 'Nhập danh xưng',
              onChanged: cubit.updatePrimaryContactTitle,
            ),
            const VGap.md(),
            PartnerOutlinedTextField(
              key: const Key('input_primary_contact_name'),
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên',
              initialValue: state.primaryContactName,
              isRequired: true,
              errorText: state.errors['primaryContactName'],
              onChanged: cubit.updatePrimaryContactName,
            ),
            const VGap.md(),
            PartnerOutlinedTextField(
              key: const Key('input_primary_contact_phone'),
              label: 'SĐT chính',
              initialValue: state.primaryContactPhone,
              isRequired: true,
              errorText: state.errors['primaryContactPhone'],
              hintText: 'Nhập SĐT chính',
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              onChanged: cubit.updatePrimaryContactPhone,
            ),
            const VGap.md(),
            PartnerOutlinedTextField(
              key: const Key('input_primary_contact_secondary_phone'),
              label: 'SĐT phụ',
              initialValue: state.primaryContactSecondaryPhone,
              errorText: state.errors['primaryContactSecondaryPhone'],
              hintText: 'Nhập SĐT phụ',
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              onChanged: cubit.updatePrimaryContactSecondaryPhone,
            ),
            const VGap.md(),
            PartnerOutlinedTextField(
              key: const Key('input_primary_contact_email'),
              label: 'Email',
              hintText: 'Nhập email',
              initialValue: state.primaryContactEmail,
              errorText: state.errors['primaryContactEmail'],
              keyboardType: TextInputType.emailAddress,
              onChanged: cubit.updatePrimaryContactEmail,
            ),
          ],
        ],
      ),
    );
  }
}
