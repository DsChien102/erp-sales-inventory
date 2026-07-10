import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerPersonSection extends StatelessWidget {
  const PartnerPersonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      children: [
        VDropdown<String>(
          value: state.personTitle.isEmpty ? null : state.personTitle,
          label: 'Danh xưng',
          hintText: 'Chọn danh xưng',
          items: const [
            'Ông',
            'Bà',
            'Anh',
            'Chị',
          ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) => cubit.updatePersonTitle(value ?? ''),
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_full_name'),
          label: 'Họ và tên',
          isRequired: true,
          errorText: state.errors['fullName'],
          onChanged: cubit.updateFullName,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_nickname'),
          label: 'Tên thường gọi',
          onChanged: cubit.updateNickname,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_phone'),
          label: 'SĐT chính',
          isRequired: true,
          keyboardType: TextInputType.phone,
          errorText: state.errors['phone'],
          onChanged: cubit.updatePhone,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_secondary_phone'),
          label: 'SĐT phụ',
          keyboardType: TextInputType.phone,
          errorText: state.errors['secondaryPhone'],
          onChanged: cubit.updateSecondaryPhone,
        ),
        const SizedBox(height: VSpacing.space3),
        VEmailField(
          key: const Key('input_email'),
          label: 'Email',
          errorText: state.errors['email'],
          onChanged: cubit.updateEmail,
        ),
      ],
    );
  }
}
