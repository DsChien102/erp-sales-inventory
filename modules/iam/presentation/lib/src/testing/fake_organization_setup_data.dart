import '../organization_profile/mock/organization_profile_mock_data.dart';
import '../organization_profile/models/organization_profile_ui_model.dart';

/// Fake data for organization setup & activation flow (TA-D-03, TA-D-04, TA-O-01).
abstract class FakeOrganizationSetupData {
  /// Cờ kiểm tra tổ chức đã sẵn sàng kích hoạt chưa (true: TA-D-04, false: TA-D-03).
  static bool isReadyToActivate = false;

  /// Cờ kiểm tra tổ chức đã được kích hoạt thành công chưa.
  static bool isActivated = false;

  /// Thông tin hồ sơ tổ chức mẫu.
  static OrganizationProfileUiModel profile = OrganizationProfileMockData.sampleProfile;

  /// Quản trị viên / Chủ sở hữu
  static String ownerName = 'Lê Thị Lan';

  /// Vai trò vận hành
  static String operatingRole = 'Chủ cửa hàng';

  /// Khôi phục dữ liệu ban đầu
  static void reset() {
    isReadyToActivate = false;
    isActivated = false;
    profile = OrganizationProfileMockData.sampleProfile;
    ownerName = 'Lê Thị Lan';
    operatingRole = 'Chủ cửa hàng';
  }
}
