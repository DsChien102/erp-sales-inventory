import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:vet45_design_system/design_system.dart';

String _normalizeForSearch(String value) {
  var normalized = value.toLowerCase().trim();
  normalized = normalized.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  normalized = normalized.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  normalized = normalized.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  normalized = normalized.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  normalized = normalized.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  normalized = normalized.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  normalized = normalized.replaceAll(RegExp(r'[đ]'), 'd');
  return normalized;
}

List<TenantMeasurementUnitDto> filterTenantMeasurementUnits(
  List<TenantMeasurementUnitDto> units,
  String query,
) {
  final normalizedQuery = _normalizeForSearch(query);
  if (normalizedQuery.isEmpty) {
    return List<TenantMeasurementUnitDto>.from(units);
  }

  return units
      .where((unit) => _normalizeForSearch(unit.name).contains(normalizedQuery))
      .toList(growable: false);
}

List<TenantMeasurementUnitDto> excludeTenantMeasurementUnits(
  List<TenantMeasurementUnitDto> units,
  Iterable<String> excludedNames,
) {
  final excluded = excludedNames.map(_normalizeForSearch).toSet();
  return units
      .where((unit) => !excluded.contains(_normalizeForSearch(unit.name)))
      .toList(growable: false);
}

bool isSameMeasurementUnitName(String a, String b) =>
    _normalizeForSearch(a) == _normalizeForSearch(b);

String normalizeMeasurementUnitNameForSearch(String value) => _normalizeForSearch(value);

class TenantMeasurementUnitSearchField extends StatefulWidget {
  const TenantMeasurementUnitSearchField({
    super.key,
    required this.controller,
    required this.units,
    required this.onChanged,
    this.focusNode,
    this.hintText,
    this.inputDecoration,
    this.textStyle,
    this.fieldKey = const Key('input_guided_base_unit'),
    this.useVTextField = false,
    this.dropdownKey = const Key('dropdown_tenant_measurement_unit_matches'),
    this.overlayOpensAbove = false,
    this.disabledUnitNames = const [],
    this.isUnitsLoading = false,
  });

  final TextEditingController controller;
  final List<TenantMeasurementUnitDto> units;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? hintText;
  final InputDecoration? inputDecoration;
  final TextStyle? textStyle;
  final Key fieldKey;
  final bool useVTextField;
  final Key dropdownKey;
  final bool overlayOpensAbove;
  final List<String> disabledUnitNames;
  final bool isUnitsLoading;

  @override
  State<TenantMeasurementUnitSearchField> createState() => _TenantMeasurementUnitSearchFieldState();
}

class _TenantMeasurementUnitSearchFieldState extends State<TenantMeasurementUnitSearchField> {
  late final FocusNode _focusNode;
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  double _overlayWidth = 0;
  bool _overlaySyncScheduled = false;

  bool get _usesExternalFocusNode => widget.focusNode != null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onOverlayStateChanged);
    widget.controller.addListener(_onOverlayStateChanged);
  }

  @override
  void didUpdateWidget(TenantMeasurementUnitSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.units != widget.units || oldWidget.isUnitsLoading != widget.isUnitsLoading) {
      _onOverlayStateChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOverlayStateChanged);
    _focusNode.removeListener(_onOverlayStateChanged);
    if (!_usesExternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  List<TenantMeasurementUnitDto> get _matches =>
      filterTenantMeasurementUnits(widget.units, widget.controller.text);

  bool _isDisabledUnit(TenantMeasurementUnitDto unit) {
    return widget.disabledUnitNames.any(
      (name) => isSameMeasurementUnitName(name, unit.name),
    );
  }

  void _onOverlayStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleOverlayControllerSync();
  }

  void _scheduleOverlayControllerSync() {
    if (_overlaySyncScheduled) {
      return;
    }
    _overlaySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlaySyncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncOverlayController();
    });
  }

  void _syncOverlayController() {
    final shouldShow = _focusNode.hasFocus && (widget.isUnitsLoading || _matches.isNotEmpty);
    if (shouldShow) {
      if (!_overlayController.isShowing) {
        _overlayController.show();
      }
      return;
    }
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _selectUnit(TenantMeasurementUnitDto unit) {
    widget.controller.text = unit.name;
    widget.onChanged(unit.name);
    _focusNode.unfocus();
    _onOverlayStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final matches = _matches;

    return LayoutBuilder(
      builder: (context, constraints) {
        _overlayWidth = constraints.maxWidth;
        return CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: _overlayController,
            overlayLocation: OverlayChildLocation.rootOverlay,
            overlayChildBuilder: (context) {
              if (!_focusNode.hasFocus) {
                return const SizedBox.shrink();
              }
              if (widget.isUnitsLoading) {
                return _buildOverlayShell(
                  context,
                  child: Padding(
                    key: widget.dropdownKey,
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: dynamicColors.primary,
                          ),
                        ),
                        const SizedBox(width: VSpacing.space3),
                        VText(
                          'Đang tải đơn vị...',
                          variant: VTextVariant.bodyDefault,
                          color: dynamicColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (matches.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildOverlayShell(
                context,
                child: _buildMatchList(context, matches),
              );
            },
            child: widget.useVTextField
                ? VTextField(
                    key: widget.fieldKey,
                    controller: widget.controller,
                    focusNode: _focusNode,
                    hintText: widget.hintText,
                    onChanged: (value) {
                      widget.onChanged(value);
                      _onOverlayStateChanged();
                    },
                  )
                : TextField(
                    key: widget.fieldKey,
                    controller: widget.controller,
                    focusNode: _focusNode,
                    decoration: widget.inputDecoration,
                    style: widget.textStyle,
                    onChanged: (value) {
                      widget.onChanged(value);
                      _onOverlayStateChanged();
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayShell(BuildContext context, {required Widget child}) {
    final dynamicColors = context.vColors;

    return Positioned(
      width: _overlayWidth,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: widget.overlayOpensAbove ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: widget.overlayOpensAbove ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, widget.overlayOpensAbove ? -4 : 4),
        child: Material(
          elevation: 8,
          color: dynamicColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            side: BorderSide(color: dynamicColors.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<TenantMeasurementUnitDto> matches,
  ) {
    final dynamicColors = context.vColors;

    return Container(
      key: widget.dropdownKey,
      padding: const EdgeInsets.all(VSpacing.space3),
      constraints: const BoxConstraints(maxHeight: 250),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: matches
              .map(
                (unit) {
                  final isDisabled = _isDisabledUnit(unit);
                  return Listener(
                    key: Key('dropdown_tenant_measurement_unit_item_${unit.id}'),
                    onPointerDown: isDisabled ? null : (_) => _selectUnit(unit),
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
                      child: Row(
                        children: [
                          Icon(
                            isDisabled ? Icons.block : Icons.sell_outlined,
                            size: 18,
                            color: isDisabled
                                ? dynamicColors.textSecondary
                                : dynamicColors.textPrimary,
                          ),
                          const SizedBox(width: VSpacing.space2),
                          Expanded(
                            child: VText(
                              isDisabled ? '${unit.name} (đơn vị cơ sở)' : unit.name,
                              variant: VTextVariant.bodyDefault,
                              color: isDisabled
                                  ? dynamicColors.textSecondary
                                  : dynamicColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
