import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_compact_field.dart';
import 'partner_form_field_row.dart';

class PartnerPersonSection extends StatelessWidget {
  const PartnerPersonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      children: [
        PartnerFormFieldRow(
          label: 'Danh xưng',
          field: PartnerCompactDropdown<String>(
            value: state.personTitle.isEmpty ? null : state.personTitle,
            hintText: 'Chọn',
            items: const [
              'Ông',
              'Bà',
              'Anh',
              'Chị',
            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => cubit.updatePersonTitle(value ?? ''),
          ),
        ),
        PartnerFormFieldRow(
          label: 'Họ và tên',
          isRequired: true,
          errorText: state.errors['fullName'],
          field: PartnerCompactTextField(
            key: const Key('input_full_name'),
            onChanged: cubit.updateFullName,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Tên thường gọi',
          field: PartnerCompactTextField(
            key: const Key('input_nickname'),
            hintText: 'Nhập tên thường gọi',
            onChanged: cubit.updateNickname,
          ),
        ),
        PartnerFormFieldRow(
          label: 'SĐT chính',
          isRequired: true,
          errorText: state.errors['phone'],
          field: PartnerCompactTextField(
            key: const Key('input_phone'),
            hintText: 'Nhập SĐT chính',
            keyboardType: TextInputType.phone,
            onChanged: cubit.updatePhone,
          ),
        ),
        PartnerFormFieldRow(
          label: 'SĐT phụ',
          errorText: state.errors['secondaryPhone'],
          field: PartnerCompactTextField(
            key: const Key('input_secondary_phone'),
            hintText: 'Nhập SĐT phụ',
            keyboardType: TextInputType.phone,
            onChanged: cubit.updateSecondaryPhone,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Email',
          errorText: state.errors['email'],
          field: PartnerCompactTextField(
            key: const Key('input_email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: cubit.updateEmail,
          ),
        ),
      ],
    );
  }
}
