abstract final class EInvoiceDateTimeCopy {
  static String checkedAt(DateTime value) {
    return 'Kiểm tra gần nhất: ${_hm(value)}, ${_dmy(value)}';
  }

  static String _hm(DateTime value) {
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _dmy(DateTime value) {
    return '${_two(value.day)}/${_two(value.month)}/${value.year}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
