import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../logic/partner_create_cubit.dart';
import '../data/vn_administrative_unit.dart';
import '../data/vn_administrative_units_loader.dart';
import 'partner_administrative_unit_picker_sheet.dart';

class PartnerDeliverySection extends StatefulWidget {
  const PartnerDeliverySection({super.key});

  @override
  State<PartnerDeliverySection> createState() => _PartnerDeliverySectionState();
}

class _PartnerDeliverySectionState extends State<PartnerDeliverySection> {
  late final Future<List<VnAdministrativeUnit>> _unitsFuture =
      VnAdministrativeUnitsLoader.load();

  Future<void> _openPicker({
    required BuildContext context,
    required List<VnAdministrativeUnit> units,
    required PartnerCreateCubit cubit,
    required String? provinceName,
    required String? communeName,
    required int initialTab,
  }) async {
    final result = await showPartnerAdministrativeUnitPickerSheet(
      context: context,
      units: units,
      initialProvinceName: provinceName,
      initialCommuneName: communeName,
      initialTab: initialTab,
    );

    if (result != null) {
      cubit.updateDeliveryProvince(result.province.fullName);
      cubit.updateDeliveryCommune(result.ward?.fullName ?? '');
    }
  }

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
        final canSelectWard = state.deliveryProvince.isNotEmpty;

        return VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledSearchDropdown(
                label: 'Tỉnh / Thành phố',
                child: _AdministrativeUnitTouchField(
                  fieldKey: const Key('input_delivery_province'),
                  clearKey: const Key('input_delivery_province_clear'),
                  value: state.deliveryProvince.isEmpty
                      ? null
                      : state.deliveryProvince,
                  hintText: 'Chọn tỉnh / thành phố',
                  prefixIcon: Icons.location_on_outlined,
                  enabled: units.isNotEmpty,
                  onTap: () => _openPicker(
                    context: context,
                    units: units,
                    cubit: cubit,
                    provinceName: state.deliveryProvince.isEmpty
                        ? null
                        : state.deliveryProvince,
                    communeName: state.deliveryCommune.isEmpty
                        ? null
                        : state.deliveryCommune,
                    initialTab: 0,
                  ),
                  onClear: state.deliveryProvince.isNotEmpty
                      ? () {
                          cubit.updateDeliveryProvince('');
                          cubit.updateDeliveryCommune('');
                        }
                      : null,
                ),
              ),
              const VGap.md(),
              _LabeledSearchDropdown(
                label: 'Xã / Phường',
                child: _AdministrativeUnitTouchField(
                  fieldKey: const Key('input_delivery_commune'),
                  clearKey: const Key('input_delivery_commune_clear'),
                  value: state.deliveryCommune.isEmpty
                      ? null
                      : state.deliveryCommune,
                  hintText: canSelectWard
                      ? 'Chọn xã / phường'
                      : 'Chọn tỉnh / thành phố trước',
                  prefixIcon: Icons.apartment_outlined,
                  enabled: canSelectWard,
                  onTap: () => _openPicker(
                    context: context,
                    units: units,
                    cubit: cubit,
                    provinceName: state.deliveryProvince.isEmpty
                        ? null
                        : state.deliveryProvince,
                    communeName: state.deliveryCommune.isEmpty
                        ? null
                        : state.deliveryCommune,
                    initialTab: canSelectWard ? 1 : 0,
                  ),
                  onClear: state.deliveryCommune.isNotEmpty
                      ? () => cubit.updateDeliveryCommune('')
                      : null,
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


}

/// Interactive touch field that triggers the administrative unit picker bottom sheet.
class _AdministrativeUnitTouchField extends StatelessWidget {
  const _AdministrativeUnitTouchField({
    required this.fieldKey,
    this.clearKey,
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.enabled,
    required this.onTap,
    this.onClear,
  });

  final Key fieldKey;
  final Key? clearKey;
  final String? value;
  final String hintText;
  final IconData prefixIcon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      key: fieldKey,
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(VRadius.input),
      child: Container(
        height: VCombobox.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space3),
        decoration: BoxDecoration(
          color: enabled
              ? colors.surface
              : colors.surfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.all(
            color: enabled
                ? colors.borderStrong
                : colors.borderDefault.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              prefixIcon,
              size: 18,
              color: enabled ? colors.textSecondary : colors.textMuted,
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: Text(
                hasValue ? value! : hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: !enabled
                      ? colors.textMuted
                      : (hasValue ? colors.textPrimary : colors.textSecondary),
                ),
              ),
            ),
            if (hasValue && onClear != null)
              IconButton(
                key: clearKey,
                icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Xóa lựa chọn',
                onPressed: onClear,
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: enabled ? colors.textSecondary : colors.textMuted,
              ),
          ],
        ),
      ),
    );
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
    return VField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Địa chỉ chi tiết'),
          VTextArea(
            controller: _controller,
            hintText: 'Số nhà, tên đường...',
            minLines: 3,
            maxLines: 5,
            onChanged: widget.onChanged,
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
