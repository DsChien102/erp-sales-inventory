/// Built-in validation for [VChoiceList].
abstract final class VChoiceListValidator {
  static const String defaultRequiredMessage = 'Vui lòng chọn ít nhất một mục';

  static String defaultMinSelectionsMessage(int min) =>
      'Vui lòng chọn ít nhất $min mục';

  static String defaultMaxSelectionsMessage(int max) =>
      'Chỉ được chọn tối đa $max mục';

  static bool isValid<T>(
    List<T> selected, {
    bool isRequired = false,
    int? minSelections,
    int? maxSelections,
  }) {
    return validate(
          selected,
          isRequired: isRequired,
          minSelections: minSelections,
          maxSelections: maxSelections,
        ) ==
        null;
  }

  static String? validate<T>(
    List<T> selected, {
    required bool isRequired,
    int? minSelections,
    int? maxSelections,
    String requiredMessage = defaultRequiredMessage,
    String? minSelectionsMessage,
    String? maxSelectionsMessage,
  }) {
    if (isRequired && selected.isEmpty) {
      return requiredMessage;
    }

    if (minSelections != null && selected.length < minSelections) {
      return minSelectionsMessage ?? defaultMinSelectionsMessage(minSelections);
    }

    if (maxSelections != null && selected.length > maxSelections) {
      return maxSelectionsMessage ?? defaultMaxSelectionsMessage(maxSelections);
    }

    return null;
  }

  /// Updates the selected list when a choice is toggled (Polaris logic).
  static List<T> updateSelected<T>(
    T value,
    bool checked,
    List<T> current, {
    required bool allowMultiple,
  }) {
    if (checked) {
      return allowMultiple ? [...current, value] : [value];
    }

    return current.where((item) => item != value).toList();
  }
}
