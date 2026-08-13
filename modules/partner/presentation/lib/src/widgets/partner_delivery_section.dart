import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/partner_create_cubit.dart';
import '../data/vn_administrative_unit.dart';
import '../data/vn_administrative_units_loader.dart';
import 'partner_ward_search_dropdown.dart';

class PartnerDeliverySection extends StatefulWidget {
  const PartnerDeliverySection({super.key});

  @override
  State<PartnerDeliverySection> createState() => _PartnerDeliverySectionState();
}

class _PartnerDeliverySectionState extends State<PartnerDeliverySection> {
  late final Future<List<VnAdministrativeUnit>> _unitsFuture =
      VnAdministrativeUnitsLoader.load();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;

    return FutureBuilder<List<VnAdministrativeUnit>>(
      future: _unitsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: VText(
              'Không thể tải danh mục địa giới hành chính.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const _DeliverySectionLoading();
        }

        final units = snapshot.data!;
        final selectedProvince = _findProvince(units, state.deliveryProvince);
        final wardItems = selectedProvince?.wards ?? const <VnWard>[];
        final canSelectWard = state.deliveryProvince.isNotEmpty;

        return VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledSearchDropdown(
                label: 'Tỉnh / Thành phố',
                child: VCombobox<String>(
                  key: const Key('input_delivery_province'),
                  value: state.deliveryProvince.isEmpty
                      ? null
                      : state.deliveryProvince,
                  hintText: 'Nhập tỉnh / thành phố',
                  items: units
                      .map(
                        (province) => DropdownMenuEntry<String>(
                          value: province.fullName,
                          label: province.fullName,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      cubit.updateDeliveryProvince(value ?? ''),
                ),
              ),
              const VGap.md(),
              _LabeledSearchDropdown(
                label: 'Xã / Phường',
                child: PartnerWardSearchDropdown(
                  key: const Key('input_delivery_commune'),
                  value: state.deliveryCommune,
                  hintText: canSelectWard
                      ? 'Nhập xã / phường'
                      : 'Nhập tỉnh / thành phố trước',
                  enabled: canSelectWard,
                  wards: wardItems,
                  onSelected: (ward) =>
                      cubit.updateDeliveryCommune(ward.fullName),
                ),
              ),
              const VGap.md(),
              _DeliveryDetailAddressField(
                key: const Key('input_delivery_address'),
                initialValue: state.deliveryAddress,
                onChanged: cubit.updateDeliveryAddress,
              ),
            ],
          ),
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

/// Label above control — same vertical pattern as personal-info fields.
class _LabeledSearchDropdown extends StatelessWidget {
  const _LabeledSearchDropdown({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: context.vColors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: VSpacing.space2),
        child,
      ],
    );
  }
}

class _DeliveryDetailAddressField extends StatefulWidget {
  const _DeliveryDetailAddressField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_DeliveryDetailAddressField> createState() =>
      _DeliveryDetailAddressFieldState();
}

class _DeliveryDetailAddressFieldState
    extends State<_DeliveryDetailAddressField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _DeliveryDetailAddressField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VTextFormField(
      controller: _controller,
      label: 'Địa chỉ chi tiết',
      hintText: 'Số nhà, tên đường...',
      minLines: 3,
      maxLines: 5,
      onChanged: widget.onChanged,
    );
  }
}

class _DeliverySectionLoading extends StatelessWidget {
  const _DeliverySectionLoading();

  @override
  Widget build(BuildContext context) {
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
          for (final label in ['Tỉnh / Thành phố', 'Xã / Phường']) ...[
            if (label != 'Tỉnh / Thành phố')
              const SizedBox(height: VSpacing.space2),
            _LabeledSearchDropdown(
              label: label,
              child: SizedBox(
                height: VCombobox.controlHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.vColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(VRadius.input),
                    border: Border.all(color: context.vColors.borderDefault),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          VText(
            'Địa chỉ chi tiết',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space2),
          SizedBox(
            height: VSpacing.space18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.vColors.surfaceAlt,
                borderRadius: BorderRadius.circular(VRadius.input),
                border: Border.all(color: context.vColors.borderDefault),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
