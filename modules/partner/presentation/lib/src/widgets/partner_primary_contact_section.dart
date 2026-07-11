import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_compact_field.dart';
import 'partner_form_field_row.dart';

class PartnerPrimaryContactSection extends StatelessWidget {
  const PartnerPrimaryContactSection({super.key});

  static const _rowLayout = (
    dense: true,
    labelWidth: PartnerFormFieldRow.contactLabelWidth,
    labelFieldGap: PartnerFormFieldRow.contactLabelFieldGap,
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            0,
            VSpacing.space4,
            VSpacing.space1,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VCheckbox(
              value: state.primaryContactEnabled,
              label: 'Thêm người liên hệ chính',
              onChanged: (value) => cubit.setPrimaryContactEnabled(value ?? false),
            ),
          ),
        ),
        if (state.primaryContactEnabled) ...[
          PartnerFormFieldRow(
            label: 'Danh xưng',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            field: PartnerCompactTextField(
              key: const Key('input_primary_contact_title'),
              initialValue: state.primaryContactTitle,
              hintText: 'Nhập danh xưng',
              onChanged: cubit.updatePrimaryContactTitle,
            ),
          ),
          PartnerFormFieldRow(
            label: 'Họ và tên',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            errorText: state.errors['primaryContactName'],
            field: PartnerCompactTextField(
              key: const Key('input_primary_contact_name'),
              initialValue: state.primaryContactName,
              onChanged: cubit.updatePrimaryContactName,
            ),
          ),
          PartnerFormFieldRow(
            label: 'SĐT chính',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            errorText: state.errors['primaryContactPhone'],
            field: PartnerCompactTextField(
              key: const Key('input_primary_contact_phone'),
              initialValue: state.primaryContactPhone,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              onChanged: cubit.updatePrimaryContactPhone,
            ),
          ),
          PartnerFormFieldRow(
            label: 'SĐT phụ',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            errorText: state.errors['primaryContactSecondaryPhone'],
            field: PartnerCompactTextField(
              key: const Key('input_primary_contact_secondary_phone'),
              initialValue: state.primaryContactSecondaryPhone,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
              onChanged: cubit.updatePrimaryContactSecondaryPhone,
            ),
          ),
          PartnerFormFieldRow(
            label: 'Email',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            errorText: state.errors['primaryContactEmail'],
            field: PartnerCompactTextField(
              key: const Key('input_primary_contact_email'),
              initialValue: state.primaryContactEmail,
              keyboardType: TextInputType.emailAddress,
              onChanged: cubit.updatePrimaryContactEmail,
            ),
          ),
          PartnerFormFieldRow(
            label: 'Là liên hệ chính',
            dense: _rowLayout.dense,
            labelWidth: _rowLayout.labelWidth,
            labelFieldGap: _rowLayout.labelFieldGap,
            field: Align(
              alignment: Alignment.centerRight,
              child: VSwitch(
                key: const Key('switch_primary_contact'),
                value: true,
                onChanged: null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
