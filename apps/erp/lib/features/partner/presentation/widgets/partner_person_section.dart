import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../logic/partner_create_cubit.dart';
import 'partner_outlined_field.dart';

class PartnerPersonSection extends StatelessWidget {
  const PartnerPersonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;

    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerOutlinedTextField(
            key: const Key('input_person_title'),
            label: 'Danh xưng',
            initialValue: state.personTitle,
            hintText: 'Nhập danh xưng',
            onChanged: cubit.updatePersonTitle,
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerOutlinedTextField(
            key: const Key('input_full_name'),
            label: 'Họ và tên',
            hintText: 'Nhập họ và tên',
            initialValue: state.fullName,
            isRequired: true,
            errorText: state.errors['fullName'],
            onChanged: cubit.updateFullName,
          ),
          const VGap.md(),
          PartnerOutlinedTextField(
            key: const Key('input_nickname'),
            label: 'Tên thường gọi',
            initialValue: state.nickname,
            hintText: 'Nhập tên thường gọi',
            onChanged: cubit.updateNickname,
          ),
          const VGap.md(),
          VPhoneField(
            key: const Key('input_phone'),
            label: 'SĐT chính',
            initialValue: state.phone,
            isRequired: true,
            errorText: state.errors['phone'],
            hintText: 'Nhập SĐT chính',
            validateOnChanged: false,
            onChanged: cubit.updatePhone,
          ),
          const VGap.md(),
          VPhoneField(
            key: const Key('input_secondary_phone'),
            label: 'SĐT phụ',
            initialValue: state.secondaryPhone,
            errorText: state.errors['secondaryPhone'],
            hintText: 'Nhập SĐT phụ',
            validateOnChanged: false,
            onChanged: cubit.updateSecondaryPhone,
          ),
          const VGap.md(),
          PartnerOutlinedTextField(
            key: const Key('input_email'),
            label: 'Email',
            hintText: 'Nhập email',
            initialValue: state.email,
            errorText: state.errors['email'],
            keyboardType: TextInputType.emailAddress,
            onChanged: cubit.updateEmail,
          ),
        ],
      ),
    );
  }
}
