import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_transform_field.dart';

class PartnerTransformOrganizationForm extends StatelessWidget {
  const PartnerTransformOrganizationForm({
    super.key,
    required this.organizationType,
    required this.organizationName,
    required this.shortName,
    required this.internationalName,
    required this.phone,
    required this.email,
    required this.taxCode,
    required this.onOrganizationTypeChanged,
    required this.onOrganizationNameChanged,
    required this.onShortNameChanged,
    required this.onInternationalNameChanged,
    required this.onPhoneChanged,
    required this.onEmailChanged,
    required this.onTaxCodeChanged,
    this.errors = const {},
  });

  final OrganizationType? organizationType;
  final String organizationName;
  final String shortName;
  final String internationalName;
  final String phone;
  final String email;
  final String taxCode;
  final ValueChanged<OrganizationType> onOrganizationTypeChanged;
  final ValueChanged<String> onOrganizationNameChanged;
  final ValueChanged<String> onShortNameChanged;
  final ValueChanged<String> onInternationalNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onTaxCodeChanged;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thông tin tổ chức (mới)',
          style: VTypography.headingH4.copyWith(
            color: context.vColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        PartnerTransformLabeledDropdown<OrganizationType>(
          key: const Key('transform_organization_type'),
          label: 'Loại tổ chức',
          value: organizationType,
          isRequired: true,
          hintText: 'Chọn loại tổ chức',
          errorText: errors['organizationType'],
          items: const [
            DropdownMenuItem(
              value: OrganizationType.company,
              child: Text('Công ty'),
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
            if (value != null) onOrganizationTypeChanged(value);
          },
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_organization_name'),
          labelKey: const Key('transform_organization_name_label'),
          label: 'Tên tổ chức',
          initialValue: organizationName,
          isRequired: true,
          errorText: errors['organizationName'],
          onChanged: onOrganizationNameChanged,
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_short_name'),
          label: 'Tên viết tắt',
          initialValue: shortName,
          onChanged: onShortNameChanged,
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_international_name'),
          label: 'Tên quốc tế',
          initialValue: internationalName,
          onChanged: onInternationalNameChanged,
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_phone'),
          label: 'SĐT tổ chức',
          initialValue: phone,
          isRequired: true,
          hintText: 'Nhập số điện thoại',
          keyboardType: TextInputType.phone,
          errorText: errors['phone'],
          onChanged: onPhoneChanged,
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_email'),
          label: 'Email tổ chức',
          initialValue: email,
          keyboardType: TextInputType.emailAddress,
          errorText: errors['email'],
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: 10),
        PartnerTransformLabeledTextField(
          key: const Key('transform_tax_code'),
          label: 'MST',
          initialValue: taxCode,
          hintText: 'Nhập MST (10 hoặc 13 số)',
          keyboardType: TextInputType.number,
          errorText: errors['taxCode'],
          onChanged: onTaxCodeChanged,
        ),
      ],
    );
  }
}
