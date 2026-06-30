class PartnerFormData {
  final String role; // 'customer', 'supplier', 'both'
  final String type; // 'individual', 'company', 'household'
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? taxId;
  final String? note;

  PartnerFormData({
    required this.role,
    required this.type,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.taxId,
    this.note,
  });
}

class MockPartnerRepository {
  // Giả lập danh sách đối tác đã tồn tại
  final List<Map<String, dynamic>> _mockDb = [
    {'phone': '0987654321', 'email': 'test@gmail.com', 'taxId': '0123456789'},
    {'phone': '0912345678', 'email': 'an@example.com', 'taxId': '9876543210'},
  ];

  Future<void> savePartner(PartnerFormData data) async {
    // Giả lập delay mạng
    await Future.delayed(const Duration(seconds: 1));
    if (data.name.isEmpty || data.phone.isEmpty) {
      throw Exception('Tên và số điện thoại là bắt buộc');
    }
    // Giả lập lưu thành công
    return;
  }

  Future<List<String>> checkDuplicate(String phone, String? email, String? taxId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<String> warnings = [];

    for (var partner in _mockDb) {
      if (partner['phone'] == phone) {
        warnings.add('Số điện thoại đã tồn tại.');
      }
      if (email != null && email.isNotEmpty && partner['email'] == email) {
        warnings.add('Email đã tồn tại.');
      }
      if (taxId != null && taxId.isNotEmpty && partner['taxId'] == taxId) {
        warnings.add('Mã số thuế đã tồn tại.');
      }
    }
    return warnings.toSet().toList();
  }
}
