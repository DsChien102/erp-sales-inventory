import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerPrimaryContactSection extends StatelessWidget {
  const PartnerPrimaryContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VCheckbox(
          value: state.primaryContactEnabled,
          label: 'Thêm người liên hệ chính',
          onChanged: (value) => cubit.setPrimaryContactEnabled(value ?? false),
        ),
        if (state.primaryContactEnabled) ...[
          const SizedBox(height: VSpacing.space3),
          VDropdown<String>(
            value: state.primaryContactTitle.isEmpty ? null : state.primaryContactTitle,
            label: 'Danh xưng',
            items: const [
              'Ông',
              'Bà',
              'Anh',
              'Chị',
            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => cubit.updatePrimaryContactTitle(value ?? ''),
          ),
          const SizedBox(height: VSpacing.space3),
          VTextField(
            key: const Key('input_primary_contact_name'),
            label: 'Họ và tên',
            isRequired: true,
            errorText: state.errors['primaryContactName'],
            onChanged: cubit.updatePrimaryContactName,
          ),
          const SizedBox(height: VSpacing.space3),
          VTextField(
            key: const Key('input_primary_contact_phone'),
            label: 'SĐT chính',
            isRequired: true,
            keyboardType: TextInputType.phone,
            errorText: state.errors['primaryContactPhone'],
            onChanged: cubit.updatePrimaryContactPhone,
          ),
          const SizedBox(height: VSpacing.space3),
          VTextField(
            label: 'SĐT phụ',
            keyboardType: TextInputType.phone,
            errorText: state.errors['primaryContactSecondaryPhone'],
            onChanged: cubit.updatePrimaryContactSecondaryPhone,
          ),
          const SizedBox(height: VSpacing.space3),
          VEmailField(
            label: 'Email',
            errorText: state.errors['primaryContactEmail'],
            onChanged: cubit.updatePrimaryContactEmail,
          ),
        ],
      ],
    );
  }
}
