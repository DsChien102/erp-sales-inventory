import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import '../data/vn_administrative_unit.dart';
import '../data/vn_administrative_units_loader.dart';
import 'partner_compact_field.dart';
import 'partner_form_field_row.dart';
import 'partner_ward_search_dropdown.dart';

class PartnerDeliverySection extends StatefulWidget {
  const PartnerDeliverySection({super.key});

  @override
  State<PartnerDeliverySection> createState() => _PartnerDeliverySectionState();
}

class _PartnerDeliverySectionState extends State<PartnerDeliverySection> {
  late final Future<List<VnAdministrativeUnit>> _unitsFuture = VnAdministrativeUnitsLoader.load();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;

    return FutureBuilder<List<VnAdministrativeUnit>>(
      future: _unitsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Không thể tải danh mục địa giới hành chính.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (!snapshot.hasData) {
          return const _DeliverySectionLoading();
        }

        final units = snapshot.data!;
        final selectedProvince = _findProvince(units, state.deliveryProvince);
        final wardItems = selectedProvince?.wards ?? const <VnWard>[];
        final canSelectWard = state.deliveryProvince.isNotEmpty;

        return Column(
          children: [
            PartnerFormFieldRow(
              // Keep label on one line so both rows share the same field baseline.
              labelWidth: 108,
              labelFieldGap: 12,
              label: 'Tỉnh / Thành phố',
              field: VCompactSearchableDropdown<String>(
                key: const Key('input_delivery_province'),
                value: state.deliveryProvince.isEmpty ? null : state.deliveryProvince,
                hintText: 'Chọn tỉnh / thành phố',
                stickyActionsReserve: PartnerCompactField.stickyActionsReserve,
                menuHeight: PartnerCompactField.menuHeight,
                items: units
                    .map(
                      (province) => DropdownMenuEntry<String>(
                        value: province.fullName,
                        label: province.fullName,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => cubit.updateDeliveryProvince(value ?? ''),
              ),
            ),
            PartnerFormFieldRow(
              labelWidth: 108,
              labelFieldGap: 12,
              label: 'Xã / Phường',
              field: PartnerWardSearchDropdown(
                key: const Key('input_delivery_commune'),
                value: state.deliveryCommune,
                hintText: canSelectWard ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước',
                enabled: canSelectWard,
                wards: wardItems,
                onSelected: (ward) => cubit.updateDeliveryCommune(ward.fullName),
              ),
            ),
            _DeliveryDetailAddressField(
              initialValue: state.deliveryAddress,
              onChanged: cubit.updateDeliveryAddress,
            ),
          ],
        );
      },
    );
  }

  VnAdministrativeUnit? _findProvince(
    List<VnAdministrativeUnit> units,
    String fullName,
  ) {
    for (final unit in units) {
      if (unit.fullName == fullName) return unit;
    }
    return null;
  }
}

class _DeliveryDetailAddressField extends StatelessWidget {
  const _DeliveryDetailAddressField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space4,
        VSpacing.space2,
        VSpacing.space4,
        VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Địa chỉ chi tiết',
            style: VTypography.bodySmall.copyWith(
              color: context.vColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerCompactMultilineTextField(
            key: const Key('input_delivery_address'),
            initialValue: initialValue,
            hintText: 'Số nhà, tên đường...',
            minLines: 3,
            maxLines: 5,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DeliverySectionLoading extends StatelessWidget {
  const _DeliverySectionLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 2; index++)
          PartnerFormFieldRow(
            labelWidth: 108,
            labelFieldGap: 12,
            label: index == 0 ? 'Tỉnh / Thành phố' : 'Xã / Phường',
            field: SizedBox(
              height: PartnerCompactField.controlHeight,
              child: DecoratedBox(
                decoration: PartnerCompactField.decoration(
                  context,
                  enabled: false,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Địa chỉ chi tiết',
                style: VTypography.bodySmall.copyWith(
                  color: context.vColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: VSpacing.space2),
              SizedBox(
                height: 72,
                child: DecoratedBox(
                  decoration: PartnerCompactField.decoration(
                    context,
                    enabled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
