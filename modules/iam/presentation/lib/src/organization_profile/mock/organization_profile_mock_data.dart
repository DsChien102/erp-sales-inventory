import '../models/organization_profile_ui_model.dart';

/// Dữ liệu giả lập mẫu cho màn hình Hồ sơ tổ chức (TA-D-01).
class OrganizationProfileMockData {
  static const sampleLegalProfile = LegalProfileUiModel(
    entityType: 'Hộ kinh doanh',
    legalName: 'HKD Thú y Minh Phát',
    taxCode: '360123456789',
    registeredAddress: '125 Phạm Văn Thuận',
    city: 'Đồng Nai',
    ward: 'Trấn Biên',
  );

  static const sampleProfile = OrganizationProfileUiModel(
    id: 'org_001',
    name: 'Thú y Minh Phát',
    statusLabel: 'Hoạt động',
    statusDescription: 'Tổ chức đang hoạt động',
    phone: '0901 234 567',
    email: 'contact@minhphat.vn',
    address: 'Biên Hòa, Đồng Nai',
    hasLegalProfile: false,
    legalNoticeTitle: 'Chưa có hồ sơ pháp lý',
    legalNoticeMessage: 'Có thể bổ sung sau. Một số tính năng pháp lý chưa sử dụng được.',
    legalProfile: sampleLegalProfile,
  );
}
