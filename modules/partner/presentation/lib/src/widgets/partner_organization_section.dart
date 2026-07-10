import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';

class PartnerOrganizationSection extends StatelessWidget {
  const PartnerOrganizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      children: [
        VDropdown<OrganizationType>(
          value: state.organizationType,
          label: 'Loại tổ chức',
          items: const [
            DropdownMenuItem(
              value: OrganizationType.company,
              child: Text('Công ty/TNHH'),
            ),
            DropdownMenuItem(
              value: OrganizationType.businessHousehold,
              child: Text('Hộ kinh doanh'),
            ),
            DropdownMenuItem(
              value: OrganizationType.other,
              child: Text('Khác'),
            ),
          ],
          onChanged: (value) {
            if (value != null) cubit.updateOrganizationType(value);
          },
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_organization_name'),
          label: 'Tên tổ chức',
          isRequired: true,
          errorText: state.errors['organizationName'],
          onChanged: cubit.updateOrganizationName,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_short_name'),
          label: 'Tên viết tắt',
          onChanged: cubit.updateShortName,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          key: const Key('input_international_name'),
          label: 'Tên quốc tế',
          onChanged: cubit.updateInternationalName,
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
