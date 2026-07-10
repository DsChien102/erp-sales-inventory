import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_outlined_field.dart';

class PartnerOrganizationSection extends StatelessWidget {
  const PartnerOrganizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        0,
        VSpacing.space4,
        VSpacing.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerOutlinedTextField(
            key: const Key('input_organization_type'),
            label: 'Loại tổ chức',
            initialValue: state.organizationTypeLabel,
            hintText: 'VD: Công ty/TNHH, Hộ kinh doanh',
            onChanged: cubit.updateOrganizationType,
          ),
          const SizedBox(height: PartnerOutlinedField.fieldGap),
          PartnerOutlinedTextField(
            key: const Key('input_organization_name'),
            label: 'Tên tổ chức',
            initialValue: state.organizationName,
            isRequired: true,
            errorText: state.errors['organizationName'],
            onChanged: cubit.updateOrganizationName,
          ),
          const SizedBox(height: PartnerOutlinedField.fieldGap),
          PartnerOutlinedTextField(
            key: const Key('input_short_name'),
            label: 'Tên viết tắt',
            initialValue: state.shortName,
            onChanged: cubit.updateShortName,
          ),
          const SizedBox(height: PartnerOutlinedField.fieldGap),
          PartnerOutlinedTextField(
            key: const Key('input_international_name'),
            label: 'Tên quốc tế',
            initialValue: state.internationalName,
            onChanged: cubit.updateInternationalName,
          ),
          const SizedBox(height: PartnerOutlinedField.fieldGap),
          PartnerOutlinedTextField(
            key: const Key('input_phone'),
            label: 'SĐT chính',
            initialValue: state.phone,
            isRequired: true,
            errorText: state.errors['phone'],
            keyboardType: TextInputType.phone,
            onChanged: cubit.updatePhone,
          ),
          const SizedBox(height: PartnerOutlinedField.fieldGap),
          PartnerOutlinedTextField(
            key: const Key('input_email'),
            label: 'Email',
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
