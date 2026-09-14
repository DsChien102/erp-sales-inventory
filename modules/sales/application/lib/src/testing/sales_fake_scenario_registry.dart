import 'sales_fake_scenario_definition.dart';

/// Canonical TH-05 scenario identifiers used by contract fakes.
abstract final class SalesFakeScenarioRegistry {
  static const ids = <String>[
    'e01_u01_scn01_khoi_tao_don_moi_voi_khach_le',
    'e01_u01_scn02_khoi_tao_don_tu_ho_so_khach_hang',
    'e01_u01_scn03_tenant_yeu_cau_ca_ban_nhung_chua_co_ca_hop_le',
    'e01_u01_scn04_khong_co_quyen_tai_cua_hang',
    'e01_u01_scn05_roi_working_state_da_co_du_lieu',
    'e01_u01_scn06_bo_working_state_rong',
    'e01_u02_scn01_tiep_tuc_ban_cho_khach_le',
    'e01_u02_scn02_chon_khach_hang_co_ho_so',
    'e01_u02_scn03_quay_lai_khach_le',
    'e01_u02_scn04_tao_nhanh_khach_hang_thanh_cong',
    'e01_u02_scn05_huy_luong_tao_nhanh_khach_hang',
    'e01_u02_scn06_khach_hang_khong_con_hoat_dong_khi_checkout',
    'e01_u03_scn01_them_san_pham_bang_tim_kiem',
    'e01_u03_scn02_them_san_pham_bang_barcode',
    'e01_u03_scn03_them_lai_cung_san_pham_va_don_vi',
    'e01_u03_scn04_thay_doi_don_vi_ban',
    'e01_u03_scn05_nhap_so_luong_khong_hop_le',
    'e01_u03_scn06_san_pham_da_ngung_ban',
    'e01_u03_scn07_chan_thanh_toan_khi_co_dong_khong_hop_le',
    'e01_u04_scn01_lay_pricing_preview_thanh_cong',
    'e01_u04_scn02_gia_thay_doi_khi_doi_khach_hang',
    'e01_u04_scn03_dieu_chinh_gia_thu_cong_hop_le',
    'e01_u04_scn04_khong_co_quyen_sua_gia',
    'e01_u04_scn05_gia_duoi_san_bi_chan',
    'e01_u04_scn06_gia_duoi_san_duoc_override',
    'e01_u04_scn07_khong_lay_duoc_gia_hop_le',
    'e01_u05_scn01_mo_flow_luu_gia_rieng',
    'e01_u05_scn02_chan_khach_le_luu_gia_rieng',
    'e01_u05_scn03_luu_rule_thanh_cong',
    'e01_u05_scn04_huy_flow_theme_4',
    'e01_u05_scn05_theme_4_tu_choi_do_rule_trung',
    'e01_u05_scn06_khong_tai_duoc_pricing_preview_sau_khi_luu_rule',
    'e01_u06_scn01_luu_draft_thanh_cong',
    'e01_u06_scn02_luu_draft_co_khach_hang_dinh_danh',
    'e01_u06_scn03_khong_cho_luu_draft_rong',
    'e01_u06_scn04_luu_draft_khi_pricing_preview_can_lam_moi',
    'e01_u06_scn05_submit_luu_draft_nhieu_lan',
    'e01_u06_scn06_luu_draft_that_bai',
    'e01_u07_scn01_xem_danh_sach_draft_active',
    'e01_u07_scn02_khoi_phuc_draft_khong_co_thay_doi',
    'e01_u07_scn03_khoi_phuc_draft_co_gia_thay_doi',
    'e01_u07_scn04_khoi_phuc_draft_co_san_pham_khong_con_hop_le',
    'e01_u07_scn05_cap_nhat_draft_thanh_cong',
    'e01_u07_scn06_version_conflict',
    'e01_u07_scn07_huy_mem_draft',
    'e02_u01_scn01_don_chua_co_payment_intent',
    'e02_u01_scn02_don_da_nhap_thanh_toan_mot_phan',
    'e02_u01_scn03_don_da_nhap_du_thanh_toan',
    'e02_u01_scn04_tong_payment_intent_vuot_tong_phai_tra',
    'e02_u01_scn05_gia_thay_doi_lam_payment_intent_khong_con_hop_le',
    'e02_u01_scn06_quay_lai_sua_don',
    'e02_u02_scn01_thanh_toan_toan_bo_bang_tien_mat',
    'e02_u02_scn02_thanh_toan_toan_bo_bang_chuyen_khoan_thu_cong',
    'e02_u02_scn03_ket_hop_nhieu_phuong_thuc',
    'e02_u02_scn04_cap_nhat_payment_intent',
    'e02_u02_scn05_xoa_payment_intent',
    'e02_u02_scn06_chan_tong_thanh_toan_vuot_nghia_vu',
    'e02_u02_scn07_checkout_bi_chan_truoc_commit',
    'e02_u03_scn01_khach_hang_thanh_toan_mot_phan',
    'e02_u03_scn02_khach_hang_chua_thanh_toan',
    'e02_u03_scn03_chan_khach_le_ban_thieu',
    'e02_u03_scn04_chan_nguoi_dung_khong_co_quyen_ban_thieu',
    'e02_u03_scn05_ngay_hen_thanh_toan_khong_hop_le',
    'e02_u03_scn06_don_da_thanh_toan_du',
    'e02_u03_scn07_theme_6_xu_ly_cham',
    'e02_u04_scn01_precheck_san_sang',
    'e02_u04_scn02_gia_thay_doi_truoc_checkout',
    'e02_u04_scn03_san_pham_khong_con_duoc_ban',
    'e02_u04_scn04_khong_du_ton_kho_khi_cam_am_kho',
    'e02_u04_scn05_thieu_thong_tin_ban_thieu',
    'e02_u04_scn06_dependency_tam_thoi_khong_phan_hoi',
    'e02_u04_scn07_du_lieu_thay_doi_sau_precheck',
    'e02_u05_scn01_checkout_thanh_cong',
    'e02_u05_scn02_retry_cung_payload',
    'e02_u05_scn03_tai_su_dung_key_voi_payload_khac',
    'e02_u05_scn04_timeout_sau_khi_server_commit',
    'e02_u05_scn05_checkout_bi_blocked_tai_command_time',
    'e02_u05_scn06_checkout_uncertain',
    'e02_u05_scn07_draft_nguon_duoc_converted',
    'e02_u06_scn01_don_thanh_toan_du',
    'e02_u06_scn02_don_con_phai_thu',
    'e02_u06_scn04_khong_yeu_cau_hoa_don_dien_tu',
    'e02_u06_scn05_checkout_dang_uncertain',
    'e02_u06_scn06_mo_chi_tiet_don',
    'e02_u06_scn07_tao_don_moi',
    'e02_u07_scn01_tao_receipt_sau_checkout',
    'e02_u07_scn02_xem_receipt',
    'e02_u07_scn03_in_receipt',
    'e02_u07_scn04_chia_se_receipt',
    'e02_u07_scn05_receipt_chua_tao_xong',
    'e02_u07_scn06_du_lieu_master_thay_doi_sau_ban',
    'e02_u07_scn07_goi_tao_receipt_lap_lai',
    'e03_u01_scn01_mo_danh_sach_don_hang',
    'e03_u01_scn02_tim_theo_ma_don',
    'e03_u01_scn03_tim_theo_customer_snapshot',
    'e03_u01_scn04_loc_theo_nhieu_dieu_kien',
    'e03_u01_scn05_empty_state',
    'e03_u01_scn06_no_result_state',
    'e03_u01_scn07_khong_co_quyen',
    'e03_u02_scn01_mo_chi_tiet_tu_danh_sach',
    'e03_u02_scn02_product_master_da_thay_doi',
    'e03_u02_scn03_customer_profile_da_thay_doi',
    'e03_u02_scn04_xem_don_da_huy',
    'e03_u02_scn05_deep_link_ngoai_pham_vi',
    'e03_u02_scn06_khong_tim_thay_don',
    'e03_u02_scn07_projection_dang_cap_nhat',
    'e03_u03_scn01_don_da_thanh_toan_du',
    'e03_u03_scn02_don_thanh_toan_mot_phan',
    'e03_u03_scn03_don_co_hoan_tien',
    'e03_u03_scn04_payment_bi_void',
    'e03_u03_scn05_mo_cong_no_trong_theme_6',
    'e03_u03_scn06_khong_co_quyen_xem_payment_chi_tiet',
    'e03_u03_scn07_projection_payment_dang_cham',
    'e03_u04_scn01_xem_timeline_giao_dich_co_ban',
    'e03_u04_scn02_xem_adjustment_diff',
    'e03_u04_scn03_xem_don_da_huy',
    'e03_u04_scn04_xem_return_summary',
    'e03_u04_scn05_tra_toan_bo_hang_nhung_khong_huy_don',
    'e03_u04_scn06_khong_co_quyen_mo_source',
    'e03_u04_scn07_timeline_projection_dang_cham',
    'e03_u05_scn01_xem_receipt_hien_hanh',
    'e03_u05_scn02_sinh_receipt_khi_chua_co',
    'e03_u05_scn03_xem_nhieu_version',
    'e03_u05_scn04_in_lai_receipt',
    'e03_u05_scn05_chia_se_receipt',
    'e03_u05_scn06_receipt_generation_that_bai',
    'e03_u05_scn07_product_master_da_doi_ten',
    'e03_u07_scn01_mo_flow_dieu_chinh',
    'e03_u07_scn02_mo_flow_huy_don',
    'e03_u07_scn03_mo_flow_doi_tra',
    'e03_u07_scn04_khong_co_quyen',
    'e03_u07_scn05_state_thay_doi_sau_khi_action_hien_thi',
    'e03_u07_scn06_huy_flow_sau_ban',
    'e03_u07_scn07_quay_lai_sau_nghiep_vu_thanh_cong',
    'e05_u01_scn01_don_chua_co_tien_thuc_thu_rong',
    'e05_u01_scn02_don_da_co_tien_thuc_thu',
    'e05_u01_scn03_khoan_thu_da_duoc_hoan_hoac_void_day_du',
    'e05_u01_scn04_don_da_bi_huy',
    'e05_u01_scn05_co_phieu_doi_tra_da_xac_nhan',
    'e05_u01_scn06_co_phieu_doi_tra_draft',
    'e05_u01_scn07_don_con_khoan_phai_thu_chua_thu',
    'e05_u02_scn01_chon_ly_do_hop_le',
    'e05_u02_scn02_ly_do_khac_yeu_cau_mo_ta',
    'e05_u02_scn03_reason_note_chi_co_khoang_trang',
    'e05_u02_scn04_khong_hien_thi_phuong_an_hoan_tien',
    'e05_u02_scn05_settlement_thay_doi_sau_precheck',
    'e05_u02_scn06_phat_sinh_tien_thuc_thu_moi',
    'e05_u02_scn07_huy_flow',
    'e05_u03_scn01_xac_nhan_huy_thanh_cong',
    'e05_u03_scn02_retry_cung_payload',
    'e05_u03_scn03_cung_key_nhung_payload_khac',
    'e05_u03_scn04_phat_sinh_tien_thuc_thu_sau_precheck',
    'e05_u03_scn05_version_conflict',
    'e05_u03_scn06_lifecycle_command_dang_xu_ly',
    'e05_u03_scn07_downstream_delivery_that_bai',
    'e05_u05_scn01_xem_ket_qua_huy_thanh_cong',
    'e05_u05_scn02_khong_phat_sinh_hoan_tien_trong_ep_05',
    'e05_u05_scn03_xem_commercial_snapshot_goc',
    'e05_u05_scn04_xem_timeline_huy',
    'e05_u05_scn05_xem_receipt_cua_don_da_huy',
    'e05_u05_scn06_tao_don_moi',
    'e05_u05_scn07_projection_dang_cap_nhat',
    'e06_u01_scn01_khoi_tao_flow_chuan',
    'e06_u01_scn02_chuyen_tu_thao_tac_huy_da_bi_chan',
    'e06_u01_scn03_don_da_huy',
    'e06_u01_scn04_cancellation_dang_xu_ly',
    'e06_u01_scn05_khong_con_hang_co_the_tra',
    'e06_u01_scn06_quick_flow_chi_con_phan_chua_tra',
    'e06_u01_scn07_retry_khoi_tao',
    'e06_u02_scn01_them_dong_tra_hop_le',
    'e06_u02_scn02_prefill_quick_full_return',
    'e06_u02_scn03_giam_quantity_lam_chuyen_sang_standard_return',
    'e06_u02_scn04_chan_so_luong_vuot_kha_dung',
    'e06_u02_scn05_lay_gia_tri_theo_commercial_snapshot',
    'e06_u02_scn06_khong_mac_dinh_hang_nhap_lai_kho_ban_duoc',
    'e06_u02_scn07_conflict_do_phieu_khac_hoan_tat',
    'e06_u03_scn01_them_dong_exchange_hop_le',
    'e06_u03_scn02_gia_hien_hanh_duoc_ap_dung',
    'e06_u03_scn03_product_khong_con_ban_duoc',
    'e06_u03_scn04_khong_du_ton_kho',
    'e06_u03_scn05_cap_nhat_quantity',
    'e06_u03_scn06_xoa_dong_exchange',
    'e06_u03_scn07_chan_phieu_chi_co_hang_exchange',
    'e06_u04_scn01_giu_working_state_giua_sg',
    'e06_u04_scn02_confirmation_khi_thoat',
    'e06_u04_scn03_tiep_tuc_giu_state',
    'e06_u04_scn04_bo_thay_doi_release_reservation',
    'e06_u04_scn05_khong_co_quan_ly_phieu_nhap',
    'e06_u05_scn01_khach_phai_tra_them',
    'e06_u05_scn02_doanh_nghiep_phai_hoan_tien',
    'e06_u05_scn03_full_return_don_da_thanh_toan_du',
    'e06_u05_scn04_full_return_don_thanh_toan_mot_phan',
    'e06_u05_scn05_khong_phat_sinh_chenh_lech',
    'e06_u05_scn06_valuation_stale_do_settlement_thay_doi',
    'e06_u05_scn07_chua_tao_transaction',
    'e06_u06_scn01_thu_them_toan_bo',
    'e06_u06_scn02_hoan_tien_toan_bo',
    'e06_u06_scn03_tra_toan_bo_don_da_thanh_toan_mot_phan',
    'e06_u06_scn04_can_tru_cong_no_trong_doi_tra',
    'e06_u06_scn05_chan_khach_le_dung_cong_no',
    'e06_u06_scn06_khong_phat_sinh_tien',
    'e06_u06_scn07_theme_6_tu_choi_impact',
    'e06_u07_scn01_xac_nhan_phieu_thanh_cong',
    'e06_u07_scn02_hoan_tat_nghiep_vu',
    'e06_u07_scn03_tra_mot_phan_don',
    'e06_u07_scn04_hoan_tat_full_return_tu_thao_tac_huy',
    'e06_u07_scn05_result_cua_don_thanh_toan_mot_phan',
    'e06_u07_scn06_retry_cung_confirmation',
    'e06_u07_scn07_downstream_inventory_failed',
  ];

  static bool contains(String id) => ids.contains(id);

  static SalesFakeScenarioDefinition definitionFor(String id) {
    if (!contains(id)) {
      throw ArgumentError.value(id, 'id', 'Unknown TH-05 fake scenario ID');
    }
    final story = id.substring(0, 7);
    final resultFamily = _resultFamilyById[id] ?? _resultFamilyByStory[story];
    if (resultFamily == null) {
      throw StateError('Missing result-family mapping for $story');
    }
    return SalesFakeScenarioDefinition(
      id: id,
      resultFamily: resultFamily,
      outcomeFamily: _outcomeFamily(id),
    );
  }

  /// Per-scenario overrides when one US story spans multiple CQRS result types.
  static const _resultFamilyById = <String, String>{
    'e06_u04_scn01_giu_working_state_giua_sg': 'ReturnExchangeDraftDto',
    'e06_u04_scn02_confirmation_khi_thoat': 'ReturnExchangeDraftDto',
    'e06_u04_scn03_tiep_tuc_giu_state': 'ReturnExchangeDraftDto',
    'e06_u04_scn04_bo_thay_doi_release_reservation': 'ReturnExchangeResultDto',
    'e06_u04_scn05_khong_co_quan_ly_phieu_nhap': 'ReturnExchangeDraftDto',
  };

  static const _resultFamilyByStory = <String, String>{
    'e01_u01': 'SalesOrderWorkingStateDto',
    'e01_u02': 'CustomerSelectionDto',
    'e01_u03': 'DraftLinePreviewDto',
    'e01_u04': 'PricingPreviewDto',
    'e01_u05': 'RememberedPriceOutcomeDto (Pricing-owned)',
    'e01_u06': 'SalesOrderDraftDto',
    'e01_u07': 'SalesOrderDraftForRestoreDto',
    'e02_u01': 'CheckoutMonetarySummaryDto',
    'e02_u02': 'PaymentIntentSummaryDto',
    'e02_u03': 'ReceivableRequirementDto',
    'e02_u04': 'CheckoutPrecheckDto',
    'e02_u05': 'CheckoutResultDto',
    'e02_u06': 'CheckoutResultViewDto',
    'e02_u07': 'SalesReceiptDto',
    'e03_u01': 'PagedSalesOrderListDto',
    'e03_u02': 'SalesOrderDetailDto',
    'e03_u03': 'SalesOrderPaymentSummaryDto',
    'e03_u04': 'SalesOrderTimelineDto',
    'e03_u05': 'SalesReceiptDto',
    'e03_u07': 'AvailablePostSaleActionsDto',
    'e05_u01': 'CancellationPrecheckDto',
    'e05_u02': 'CancellationReasonDto',
    'e05_u03': 'SalesOrderCancellationResultDto',
    'e05_u05': 'SalesOrderCancellationDetailDto',
    'e06_u01': 'ReturnExchangeDraftDto',
    'e06_u02': 'ReturnExchangeDraftDto',
    'e06_u03': 'ReturnExchangeDraftDto',
    'e06_u04': 'ReturnExchangeDraftDto',
    'e06_u05': 'ReturnExchangeValuationDto',
    'e06_u06': 'ReturnExchangeSettlementResultDto',
    'e06_u07': 'ReturnExchangeResultDto',
  };

  static SalesFakeOutcomeFamily _outcomeFamily(String id) {
    if (id.contains('khong_co_quyen') ||
        id.contains('permission_bi_thu_hoi') ||
        id.contains('thieu_quyen') ||
        id.contains('mat_quyen')) {
      return SalesFakeOutcomeFamily.permissionDenied;
    }
    if (id.contains('version_conflict') ||
        id.contains('conflict_version') ||
        id.contains('conflict_do_')) {
      return SalesFakeOutcomeFamily.staleVersion;
    }
    if (id.contains('payload_khac') || id.contains('tai_su_dung_key')) {
      return SalesFakeOutcomeFamily.idempotencyConflict;
    }
    if (id.contains('khong_tim_thay') || id.contains('not_found')) {
      return SalesFakeOutcomeFamily.notFound;
    }
    if (id.contains('projection_') || id.contains('dang_cham')) {
      return SalesFakeOutcomeFamily.projectionPending;
    }
    if (id.contains('uncertain') || id.contains('timeout_')) {
      return SalesFakeOutcomeFamily.uncertainResult;
    }
    if (id.contains('dependency_') ||
        id.contains('khong_phan_hoi') ||
        id.contains('khong_tai_duoc') ||
        id.contains('that_bai') ||
        id.contains('_failed') ||
        id.contains('tu_choi')) {
      return SalesFakeOutcomeFamily.dependencyUnavailable;
    }
    if (id.contains('noop_') ||
        id.contains('reject_field') ||
        id.contains('_bi_chan') ||
        id.contains('_chan_') ||
        id.contains('khong_hop_le') ||
        id.contains('khong_con_') ||
        id.contains('_vuot_') ||
        id.contains('_bi_khoa') ||
        id.contains('field_khong_') ||
        id.contains('khong_sua_don_da_huy')) {
      return SalesFakeOutcomeFamily.blocked;
    }
    return SalesFakeOutcomeFamily.success;
  }
}
