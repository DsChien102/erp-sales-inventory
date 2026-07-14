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
          field: PartnerCompactTextField(
            key: const Key('input_person_title'),
            initialValue: state.personTitle,
            hintText: 'Nhập danh xưng',
            onChanged: cubit.updatePersonTitle,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Họ và tên',
          isRequired: true,
          errorText: state.errors['fullName'],
          field: PartnerCompactTextField(
            key: const Key('input_full_name'),
            initialValue: state.fullName,
            onChanged: cubit.updateFullName,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Tên thường gọi',
          field: PartnerCompactTextField(
            key: const Key('input_nickname'),
            initialValue: state.nickname,
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
            initialValue: state.phone,
            hintText: 'Nhập SĐT chính',
            keyboardType: TextInputType.phone,
            digitsOnly: true,
            onChanged: cubit.updatePhone,
          ),
        ),
        PartnerFormFieldRow(
          label: 'SĐT phụ',
          errorText: state.errors['secondaryPhone'],
          field: PartnerCompactTextField(
            key: const Key('input_secondary_phone'),
            initialValue: state.secondaryPhone,
            hintText: 'Nhập SĐT phụ',
            keyboardType: TextInputType.phone,
            digitsOnly: true,
            onChanged: cubit.updateSecondaryPhone,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Email',
          errorText: state.errors['email'],
          field: PartnerCompactTextField(
            key: const Key('input_email'),
            initialValue: state.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: cubit.updateEmail,
          ),
        ),
      ],
    );
  }
}
