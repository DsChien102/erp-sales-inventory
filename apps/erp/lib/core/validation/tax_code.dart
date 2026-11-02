/// MST hợp lệ: 10 số, 12 số, hoặc chi nhánh `10 số-3 số` (`0123456789-001`).
/// Gạch ngang được giữ: MISA và cơ quan thuế nhận dạng chi nhánh theo dạng có gạch.
final RegExp _taxCodeFormat = RegExp(r'^(\d{10}|\d{12}|\d{10}-\d{3})$');

const String taxCodeFormatMessage =
    'Mã số thuế phải gồm 10 hoặc 12 chữ số, hoặc dạng chi nhánh 10 số-3 số (VD: 0123456789-001).';

/// Chỉ cắt khoảng trắng hai đầu (`' 0101234567-001 '` → `0101234567-001`).
String normalizeTaxCode(String raw) => raw.trim();

bool isValidTaxCode(String raw) => _taxCodeFormat.hasMatch(normalizeTaxCode(raw));

/// Ô MST nhập tay (partner): bỏ mọi khoảng trắng; gõ liền 13 số thì thành `10 số-3 số`.
String compactTaxCodeInput(String raw) {
  final compact = raw.replaceAll(RegExp(r'\s'), '');
  if (RegExp(r'^\d{13}$').hasMatch(compact)) {
    return '${compact.substring(0, 10)}-${compact.substring(10)}';
  }
  return compact;
}
