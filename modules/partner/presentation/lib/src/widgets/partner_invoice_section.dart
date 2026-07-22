import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_compact_field.dart';
import 'partner_form_field_row.dart';

class PartnerInvoiceSection extends StatelessWidget {
  const PartnerInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    final isOrganization = state.partnerType == PartnerType.organization;
    return Column(
      children: [
        PartnerFormFieldRow(
          label: 'MST',
          isRequired: isOrganization,
          errorText: state.errors['taxCode'],
          field: PartnerCompactTextField(
            key: const Key('input_tax_code'),
            initialValue: state.taxCode,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            onChanged: cubit.updateTaxCode,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Tên xuất hóa đơn',
          isRequired: isOrganization,
          field: PartnerCompactTextField(
            initialValue: state.invoiceName,
            onChanged: cubit.updateInvoiceName,
          ),
        ),
        PartnerFormFieldRow(
          label: 'Email nhận hóa đơn',
          errorText: state.errors['invoiceEmail'],
          field: PartnerCompactTextField(
            initialValue: state.invoiceEmail,
            keyboardType: TextInputType.emailAddress,
            onChanged: cubit.updateInvoiceEmail,
          ),
        ),
        _InvoiceAddressField(
          initialValue: state.invoiceAddress,
          isRequired: isOrganization,
          onChanged: cubit.updateInvoiceAddress,
        ),
        if (state.taxCode.trim().isEmpty && isOrganization) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space1,
              VSpacing.space4,
              VSpacing.space2,
            ),
            child: _InvoiceWarning(),
          ),
        ],
      ],
    );
  }
}

class _InvoiceAddressField extends StatelessWidget {
  const _InvoiceAddressField({
    required this.initialValue,
    required this.onChanged,
    required this.isRequired,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        VSpacing.space2,
        VSpacing.space4,
        VSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            text: TextSpan(
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 14,
              ),
              children: [
                const TextSpan(text: 'Địa chỉ xuất hóa đơn'),
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerCompactMultilineTextField(
            key: const Key('input_invoice_address'),
            initialValue: initialValue,
            minLines: 3,
            maxLines: 5,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InvoiceWarning extends StatelessWidget {
  const _InvoiceWarning();

  @override
  Widget build(BuildContext context) {
    return const VBanner(
      status: VBannerStatus.warning,
      title: 'Vui lòng kiểm tra lại MST và địa chỉ xuất hóa đơn trước khi lưu.',
      icon: VIcons.warning,
    );
  }
}
