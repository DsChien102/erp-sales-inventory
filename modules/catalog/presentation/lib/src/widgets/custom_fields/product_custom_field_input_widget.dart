import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductCustomFieldInputWidget extends StatefulWidget {
  const ProductCustomFieldInputWidget({
    super.key,
    required this.field,
    required this.input,
    required this.onChanged,
    this.errorText,
  });

  final ProductCustomFieldValueFieldDto field;
  final ProductCustomFieldValueInput input;
  final ValueChanged<ProductCustomFieldValueInput> onChanged;
  final String? errorText;

  @override
  State<ProductCustomFieldInputWidget> createState() => _ProductCustomFieldInputWidgetState();
}

class _ProductCustomFieldInputWidgetState extends State<ProductCustomFieldInputWidget> {
  late final TextEditingController _textController;
  late final TextEditingController _numberController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.field.fieldType == CustomFieldType.text.name ? widget.input.textValue : null,
    );
    _numberController = TextEditingController(
      text: widget.field.fieldType == CustomFieldType.number.name
          ? _formatNumber(widget.input.numberValue)
          : null,
    );
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return VNumberValidator.format(value.round(), allowDecimal: false);
    }
    return VNumberValidator.format(value, allowDecimal: true);
  }

  @override
  void didUpdateWidget(covariant ProductCustomFieldInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.field.fieldType == CustomFieldType.text.name &&
        widget.input.textValue != oldWidget.input.textValue &&
        _textController.text != widget.input.textValue) {
      _textController.text = widget.input.textValue ?? '';
    }
    if (widget.field.fieldType == CustomFieldType.number.name &&
        widget.input.numberValue != oldWidget.input.numberValue) {
      final currentParsed = VNumberValidator.parse(
        _numberController.text,
        allowDecimal: true,
      );
      if (widget.input.numberValue != currentParsed) {
        _numberController.text = _formatNumber(widget.input.numberValue);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: _buildInputContent(context),
    );
  }

  Widget _buildInputContent(BuildContext context) {
    if (widget.field.fieldType == CustomFieldType.text.name) {
      return VTextField(
        label: widget.field.name,
        isRequired: widget.field.isRequired,
        controller: _textController,
        errorText: widget.errorText,
        enabled: widget.field.isActive,
        onChanged: (val) {
          widget.onChanged(
            ProductCustomFieldValueInput(
              fieldId: widget.field.fieldId,
              textValue: val,
            ),
          );
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.number.name) {
      return VNumberField(
        controller: _numberController,
        label: widget.field.name,
        isRequired: widget.field.isRequired,
        value: widget.input.numberValue,
        errorText: widget.errorText,
        enabled: widget.field.isActive,
        allowDecimal: true,
        onChanged: (val) {
          widget.onChanged(
            ProductCustomFieldValueInput(
              fieldId: widget.field.fieldId,
              numberValue: val?.toDouble(),
            ),
          );
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.singleSelect.name) {
      return VSelect<String>(
        label: widget.field.name,
        value: widget.input.optionId,
        hintText: '- Chọn -',
        enabled: widget.field.isActive,
        items: widget.field.options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt.optionId,
            child: VText(opt.label),
          );
        }).toList(),
        onChanged: (val) {
          widget.onChanged(
            ProductCustomFieldValueInput(
              fieldId: widget.field.fieldId,
              optionId: val,
            ),
          );
        },
      );
    } else if (widget.field.fieldType == CustomFieldType.boolean.name) {
      return VSwitch(
        label: widget.field.name + (widget.field.isRequired ? ' *' : ''),
        value: widget.input.booleanValue ?? false,
        onChanged: widget.field.isActive
            ? (val) {
                widget.onChanged(
                  ProductCustomFieldValueInput(
                    fieldId: widget.field.fieldId,
                    booleanValue: val,
                  ),
                );
              }
            : null,
      );
    } else if (widget.field.fieldType == CustomFieldType.date.name) {
      return VDatePickerField(
        label: widget.field.name,
        required: widget.field.isRequired,
        value: widget.input.dateValue,
        onTap: () async {
          if (!widget.field.isActive) return;
          final date = await showDatePicker(
            context: context,
            initialDate: widget.input.dateValue ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            widget.onChanged(
              ProductCustomFieldValueInput(
                fieldId: widget.field.fieldId,
                dateValue: date,
              ),
            );
          }
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
