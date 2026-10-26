window.VET45_HARNESS_DATA = {
  "flows": [
    {
      "id": "UIF-02",
      "bj": "BJ-02",
      "name": "Nhận hàng mua",
      "screens": [
        "SCR-007",
        "SCR-008",
        "SCR-009",
        "SCR-084",
        "SCR-010",
        "SCR-011",
        "SCR-012",
        "SCR-013"
      ],
      "entry": [
        "SCR-007"
      ],
      "terminals": [
        "SCR-012",
        "SCR-013"
      ],
      "uc": [
        "UC-02-01",
        "UC-02-02",
        "UC-02-03",
        "UC-02-04",
        "UC-02-05"
      ],
      "intent": "Nhận hàng nhiều sản phẩm theo chứng từ (nhân viên lập trên iPhone) hoặc nhập hàng nhanh khi hàng đến chưa có chứng từ; vượt chứng từ và nhập nhanh luôn cần chủ cửa hàng duyệt trên web, chủ cửa hàng tự nhận thì tự duyệt. Một ô tìm cho cả tìm mặt hàng và quét mã vạch; Đạt nhập thẳng, hạn dùng một ô.",
      "patterns": [
        "WHOLE_CARD_NAV",
        "RECEIPT_HEADER",
        "MASTER_DETAIL_RECEIPT_LINES",
        "ACTOR_HANDOFF",
        "REJECT_REASON_SHEET",
        "AUTO_EXECUTION_RESULT",
        "UNKNOWN_RECOVERY"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-007",
          "actor": "Warehouse receiver",
          "from": "Inventory > Nhận hàng"
        },
        {
          "id": "document-context",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-009",
          "actor": "Warehouse receiver",
          "from": "Purchase document > Nhận hàng",
          "urlParam": "entry=document-context"
        },
        {
          "id": "approver",
          "type": "ACTOR_HANDOFF_TASK",
          "screen": "SCR-011",
          "actor": "Receiving approver",
          "from": "Assigned approval task / notification",
          "urlParam": "entry=approver"
        },
        {
          "id": "unknown-recovery",
          "type": "SYSTEM_RECOVERY",
          "screen": "SCR-013",
          "actor": "Warehouse receiver",
          "from": "SCR-012 UNKNOWN only"
        },
        {
          "id": "hub-pending-maker",
          "type": "WAREHOUSE_HUB_ATTENTION",
          "screen": "SCR-010",
          "actor": "Warehouse receiver",
          "from": "Warehouse Hub > Cần chú ý > Nhận hàng chờ phê duyệt",
          "urlParam": "entry=warehouse-hub-pending"
        },
        {
          "id": "hub-pending-approver",
          "type": "WAREHOUSE_HUB_ATTENTION",
          "screen": "SCR-011",
          "actor": "Receiving approver",
          "from": "Warehouse Hub > Cần chú ý > Nhận hàng chờ phê duyệt",
          "urlParam": "entry=warehouse-hub-pending"
        }
      ]
    },
    {
      "id": "UIF-01",
      "bj": "BJ-01",
      "name": "Theo dõi tồn, khả dụng và chỉ báo vận hành",
      "screens": [
        "SCR-001",
        "SCR-003"
      ],
      "entry": [
        "SCR-001"
      ],
      "terminals": [
        "SCR-003"
      ],
      "uc": [
        "UC-01-01",
        "UC-01-02",
        "UC-01-03",
        "UC-01-04",
        "UC-01-05"
      ],
      "intent": "Theo dõi tồn bằng 2 full screens; visual/interaction composition map public Flutter DS. LOT/provenance là VBottomSheet; trace sâu handoff BJ-15.",
      "patterns": [
        "WHOLE_CARD_NAV",
        "AS_OF_FRESHNESS",
        "ACTIONABLE_DASHBOARD",
        "BJ15_TRACE_HANDOFF"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-001",
          "actor": "Inventory viewer/operator",
          "from": "Inventory > Tồn kho"
        },
        {
          "id": "product-deep-link",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-003",
          "actor": "Inventory viewer/operator",
          "from": "Product/inventory context",
          "urlParam": "entry=product-context"
        }
      ]
    },
    {
      "id": "UIF-03",
      "bj": "BJ-03",
      "name": "Xác lập giá trị nhập ban đầu",
      "screens": [
        "SCR-014",
        "SCR-015",
        "SCR-019"
      ],
      "entry": [
        "SCR-014"
      ],
      "terminals": [
        "SCR-019"
      ],
      "uc": [
        "UC-03-01"
      ],
      "intent": "Xác lập giá trị ban đầu cho lượng hàng thực nhận; nhận theo chứng từ dùng căn cứ thương mại read-only, nhập nhanh có thể thêm căn cứ giá trực tiếp; không tạo giá vốn chính thức.",
      "patterns": [
        "VALUATION_WORK_QUEUE",
        "DOCUMENT_OR_QUICK_BASIS",
        "DIRECT_BASIS_SHEET",
        "VALUE_COMPONENT_BREAKDOWN",
        "COMMERCIAL_CONFLICT_HANDOFF",
        "READ_ONLY_FINAL_REVIEW",
        "INITIAL_VALUE_RESULT",
        "UNKNOWN_RECOVERY",
        "FINANCIAL_MASKING"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-014",
          "actor": "Kế toán",
          "from": "Giá trị & giá vốn > Hàng chờ xác lập giá trị"
        },
        {
          "id": "receipt-task",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-015",
          "actor": "Kế toán",
          "from": "Phiếu nhận cần xác lập giá trị"
        }
      ]
    },
    {
      "id": "UIF-13",
      "bj": "BJ-13",
      "name": "Điều chỉnh giá trị hàng nhập",
      "screens": [
        "SCR-085",
        "SCR-086",
        "SCR-089"
      ],
      "entry": [
        "SCR-085"
      ],
      "terminals": [
        "SCR-089"
      ],
      "uc": [
        "UC-13-01"
      ],
      "intent": "Ghi điều chỉnh tăng hoặc giảm sau BJ03; trên SCR-086 người dùng hiểu nguồn, phạm vi, cách phân bổ và preview rồi xác nhận bằng Confirmation Sheet trước khi commit.",
      "patterns": [
        "SIGNED_VALUE_ADJUSTMENT_QUEUE",
        "SOURCE_SCOPE_ALLOCATION_ON_ONE_SURFACE",
        "VALUE_COMPONENT_PROVENANCE",
        "DIRTY_COST_SCOPE_HANDOFF",
        "UNKNOWN_RECOVERY",
        "FINANCIAL_MASKING",
        "CONFIRMATION_SHEET_BEFORE_COMMIT"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-085",
          "actor": "Kế toán",
          "from": "Giá trị & giá vốn > Điều chỉnh giá trị hàng nhập"
        },
        {
          "id": "source-task",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-086",
          "actor": "Kế toán",
          "from": "Căn cứ điều chỉnh đã được liên kết"
        }
      ]
    },
    {
      "id": "UIF-04",
      "bj": "BJ-04",
      "name": "Quản lý vòng đời giữ hàng",
      "screens": [
        "SCR-021"
      ],
      "entry": [
        "SCR-021"
      ],
      "terminals": [
        "SCR-021"
      ],
      "uc": [
        "UC-04-01",
        "UC-04-02",
        "UC-04-03",
        "UC-04-04"
      ],
      "intent": "Contextual read-only reservation projection for source orders using Advanced Stock; source/system owns lifecycle commands.",
      "patterns": [
        "SYSTEM_OWNED_RESERVATION",
        "READ_ONLY_PROJECTION",
        "SHORTAGE_TO_SOURCE",
        "CONTEXTUAL_ONLY_ENTRY",
        "NO_GLOBAL_DISCOVERY",
        "EXPLICIT_RESERVATION_POLICY",
        "CURRENT_HELD_NOT_HISTORICAL",
        "DETERMINISTIC_RESERVATION_PRIORITY",
        "RESERVATION_GROUP_ATOMIC_COMBO",
        "BJ04_BJ05_OWNERSHIP_BOUNDARY",
        "PER_LINE_CURRENT_PROJECTION"
      ],
      "entryContexts": [
        {
          "id": "order-context",
          "type": "CONTEXTUAL_ONLY",
          "screen": "SCR-021",
          "actor": "Order/warehouse viewer",
          "from": "Order detail > Tình trạng giữ hàng",
          "urlParam": "entry=order-context"
        }
      ]
    },
    {
      "id": "UIF-05",
      "bj": "BJ-05",
      "name": "Lấy hàng và bàn giao đơn",
      "screens": [
        "SCR-025",
        "SCR-026",
        "SCR-028",
        "SCR-029"
      ],
      "entry": [
        "SCR-025"
      ],
      "terminals": [
        "SCR-029"
      ],
      "uc": [
        "UC-05-01",
        "UC-05-02",
        "UC-05-03",
        "UC-05-04",
        "UC-05-05"
      ],
      "intent": "Lấy hàng đúng Order/Fulfillment, hỗ trợ multi-LOT, physical correction khi stale/override và actual/partial handover có finality an toàn.",
      "patterns": [
        "TASK_QUEUE_ALL_DEFAULT",
        "ORDER_SCOPED_PICK_DATA",
        "MULTI_LOT_ALLOCATION",
        "AUTHORIZED_LOT_OVERRIDE",
        "PHYSICAL_PICK_INVALIDATION",
        "ACTUAL_HANDOVER_BY_ALLOCATION",
        "PARTIAL_CONTINUATION",
        "RESULT_FINALITY",
        "UNKNOWN_RECOVERY"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-025",
          "actor": "Warehouse picker",
          "from": "Inventory > Lấy hàng"
        },
        {
          "id": "order-task",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-026",
          "actor": "Warehouse picker",
          "from": "Assigned pick task / order",
          "urlParam": "entry=order-task"
        }
      ]
    },
    {
      "id": "UIF-06",
      "bj": "BJ-06",
      "name": "Tiếp nhận và phân loại hàng khách trả",
      "screens": [
        "SCR-030",
        "SCR-031",
        "SCR-032",
        "SCR-033",
        "SCR-035",
        "SCR-034"
      ],
      "entry": [
        "SCR-030"
      ],
      "terminals": [
        "SCR-035"
      ],
      "uc": [
        "UC-06-01",
        "UC-06-02",
        "UC-06-03",
        "UC-06-04"
      ],
      "intent": "Physical-verify nhiều return lines nguyên tử; multi-LOT trace theo source allocation; wrong-LOT per-line approval case khóa snapshot; classification draft/finality an toàn.",
      "patterns": [
        "TASK_QUEUE_ALL_DEFAULT",
        "PHYSICAL_RETURN_VERIFICATION",
        "MULTI_LOT_SOURCE_TRACE",
        "MULTI_LINE_ATOMIC_RECEIPT",
        "WRONG_LOT_CASE_PER_LINE",
        "APPROVAL_SNAPSHOT_BINDING",
        "PRODUCT_UOM_LOT_CLASSIFICATION",
        "RESULT_FINALITY",
        "UNKNOWN_RECOVERY",
        "SEPARATE_ACTOR_ENTRY"
      ],
      "entryContexts": [
        {
          "id": "maker-module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-030",
          "actor": "Warehouse return receiver",
          "from": "Inventory > Hàng khách trả"
        },
        {
          "id": "maker-request",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-031",
          "actor": "Warehouse return receiver",
          "from": "Assigned return request",
          "urlParam": "entry=return-task"
        },
        {
          "id": "approver",
          "type": "ACTOR_HANDOFF_TASK",
          "screen": "SCR-034",
          "actor": "Wrong-LOT approver",
          "from": "Assigned approval task / notification",
          "urlParam": "entry=approver"
        }
      ]
    },
    {
      "id": "UIF-07",
      "bj": "BJ-07",
      "name": "Thực hiện trả hàng cho nhà cung cấp",
      "screens": [
        "SCR-036",
        "SCR-037",
        "SCR-039",
        "SCR-041"
      ],
      "entry": [
        "SCR-036"
      ],
      "terminals": [
        "SCR-041"
      ],
      "uc": [
        "UC-07-01",
        "UC-07-02",
        "UC-07-03",
        "UC-07-04"
      ],
      "intent": "Thực hiện supplier return đã được source-authorize với UX Figma DS: queue tách collection actionable/ready/waiting; physical verify exact Product+UOM+LOT; source delta invalidate granular; actual handover là commit duy nhất; result giữ finality.",
      "patterns": [
        "SOURCE_AUTHORIZED",
        "SEMANTIC_COLLECTIONS",
        "PRODUCT_UOM_MULTI_LOT",
        "PHYSICAL_PREPARATION_VERIFICATION",
        "EXACT_SOURCE_SCOPE_NO_WAREHOUSE_PARTIAL",
        "SOURCE_DELTA_GRANULAR_INVALIDATION",
        "HANDOVER_IS_PHYSICAL_COMMIT",
        "RESULT_FINALITY",
        "UNKNOWN_RECOVERY"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-036",
          "actor": "Warehouse supplier-return operator",
          "from": "Inventory > Trả nhà cung cấp"
        },
        {
          "id": "return-task",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-037",
          "actor": "Warehouse supplier-return operator",
          "from": "Purchase-authorized supplier-return task",
          "urlParam": "entry=return-task"
        },
        {
          "id": "source-amendment",
          "type": "CROSS_DOMAIN_REENTRY",
          "screen": "SCR-037",
          "actor": "Warehouse supplier-return operator",
          "from": "Purchase amendment issues new source version"
        }
      ]
    },
    {
      "id": "UIF-09",
      "bj": "BJ-09",
      "name": "Quản lý trạng thái hàng",
      "screens": [
        "SCR-036",
        "SCR-037",
        "SCR-038",
        "SCR-041",
        "SCR-056"
      ],
      "entry": [
        "SCR-036"
      ],
      "terminals": [
        "SCR-041",
        "SCR-056"
      ],
      "uc": [
        "UC-09-01",
        "UC-09-02",
        "UC-09-03",
        "UC-09-04"
      ],
      "intent": "Quản lý tình trạng hàng theo Product mental model: chỉ hỏi các chuyển đổi business state hợp lệ; expiry là derived behavior; state change không làm đổi tổng physical/value; approval là actor handoff.",
      "patterns": [
        "STATE_WHITELIST",
        "DERIVED_EXPIRY",
        "ACTOR_HANDOFF",
        "TRUE_READ_ONLY_LOCK",
        "PHYSICAL_VALUE_PRESERVATION",
        "UNKNOWN_RECOVERY",
        "NO_ARCHITECTURE_EXPLANATION_UI"
      ],
      "entryContexts": [
        {
          "type": "MODULE_ENTRY",
          "screen": "SCR-036",
          "actor": "Inventory controller",
          "from": "Inventory > Tình trạng hàng"
        },
        {
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-037",
          "actor": "Inventory controller",
          "from": "Product/Lot context"
        },
        {
          "type": "ACTOR_HANDOFF_TASK",
          "screen": "SCR-038",
          "actor": "Eligible approver",
          "from": "Assigned state-change approval task"
        }
      ]
    },
    {
      "id": "UIF-10",
      "bj": "BJ-10",
      "name": "Tiêu hủy hàng",
      "screens": [
        "SCR-036",
        "SCR-037",
        "SCR-040",
        "SCR-041"
      ],
      "entry": [
        "SCR-036"
      ],
      "terminals": [
        "SCR-041"
      ],
      "uc": [
        "UC-10-01",
        "UC-10-02",
        "UC-10-03",
        "UC-10-04"
      ],
      "intent": "Tiêu hủy theo đúng finality vật lý: lập yêu cầu → phê duyệt → chờ xử lý thực tế → xác nhận lượng đã tiêu hủy → ghi giảm; approval không bao giờ đồng nghĩa giảm tồn.",
      "patterns": [
        "NON_SELLABLE_SOURCE_ONLY",
        "ACTOR_HANDOFF",
        "APPROVAL_NOT_DISPOSAL",
        "COMPLETION_ASSERTION",
        "PRICE_BASIS_BLOCKER",
        "UNKNOWN_RECOVERY",
        "NO_ARCHITECTURE_EXPLANATION_UI"
      ],
      "entryContexts": [
        {
          "type": "MODULE_ENTRY",
          "screen": "SCR-036",
          "actor": "Disposal maker",
          "from": "Inventory > Hàng có thể xử lý"
        },
        {
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-037",
          "actor": "Disposal maker",
          "from": "Eligible non-sellable Product/Lot"
        },
        {
          "type": "ACTOR_HANDOFF_TASK",
          "screen": "SCR-040",
          "actor": "Eligible approver",
          "from": "Assigned disposal approval task"
        },
        {
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-040",
          "actor": "Completion operator",
          "from": "Approved disposal awaiting physical completion"
        }
      ]
    },
    {
      "id": "UIF-08",
      "bj": "BJ-08",
      "name": "Kiểm kê và điều chỉnh chênh lệch",
      "screens": [
        "SCR-042",
        "SCR-043",
        "SCR-044",
        "SCR-045",
        "SCR-046",
        "SCR-047"
      ],
      "entry": [
        "SCR-042"
      ],
      "terminals": [
        "SCR-047"
      ],
      "uc": [
        "UC-08-01",
        "UC-08-02",
        "UC-08-03",
        "UC-08-04",
        "UC-08-05"
      ],
      "intent": "Kiểm kê với atomic scope barrier, frozen CountScopeSnapshot, PhysicalCountKey/base UOM, immutable count rounds; zero variance hoàn tất không approval; non-zero dùng independent approval trên current risk/value basis.",
      "patterns": [
        "ATOMIC_SCOPE_BARRIER",
        "FROZEN_SCOPE_SNAPSHOT",
        "BLIND_COUNT_SUPPRESSION",
        "PHYSICAL_COUNT_KEY",
        "IMMUTABLE_RECOUNT_ROUNDS",
        "ZERO_VARIANCE_NO_APPROVAL",
        "PRICE_BASIS_BLOCKER",
        "CONTRIBUTOR_EXCLUSION",
        "ACTOR_HANDOFF",
        "SESSION_CONTEXT_CANCELLATION",
        "RESULT_FINALITY",
        "UNKNOWN_RECOVERY"
      ],
      "entryContexts": [
        {
          "type": "MODULE_ENTRY",
          "screen": "SCR-042",
          "actor": "Stock-count maker",
          "from": "Inventory > Kiểm kê"
        },
        {
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-044",
          "actor": "Assigned counter",
          "from": "Assigned stock-count session"
        },
        {
          "type": "ACTOR_HANDOFF_TASK",
          "screen": "SCR-046",
          "actor": "Eligible approver",
          "from": "Assigned stock-count approval task"
        }
      ]
    },
    {
      "id": "UIF-11",
      "bj": "BJ-11",
      "name": "Hủy và sửa sai nghiệp vụ kho",
      "screens": [
        "SCR-048",
        "SCR-049",
        "SCR-050",
        "SCR-053",
        "SCR-051"
      ],
      "entry": [
        "SCR-048",
        "SCR-049",
        "SCR-050",
        "SCR-051"
      ],
      "terminals": [
        "SCR-053"
      ],
      "uc": [
        "UC-11-01",
        "UC-11-02",
        "UC-11-03",
        "UC-11-04",
        "UC-11-05"
      ],
      "intent": "Hủy yêu cầu chưa thực thi hoặc tạo correction bất biến cho nghiệp vụ đã hoàn tất; maker và approver là hai task độc lập, UNKNOWN bàn giao BJ-17.",
      "patterns": [
        "CONTEXTUAL_ENTRY",
        "ACTOR_HANDOFF",
        "AUTO_SAVE_DRAFT",
        "AUTO_EXECUTION_AFTER_APPROVAL",
        "UNKNOWN_HANDOFF",
        "CORRECTION_CHAIN"
      ]
    },
    {
      "id": "UIF-12",
      "bj": "BJ-12",
      "name": "Khởi tạo số dư tồn kho đầu kỳ",
      "screens": [
        "SCR-066",
        "SCR-067",
        "SCR-068",
        "SCR-070",
        "SCR-071"
      ],
      "entry": [
        "SCR-066",
        "SCR-070"
      ],
      "terminals": [
        "SCR-066",
        "SCR-071"
      ],
      "uc": [
        "UC-12-01",
        "UC-12-02",
        "UC-12-03"
      ],
      "intent": "Khởi tạo tồn kho đầu kỳ như một controlled activation task: chuẩn bị → kiểm tra → maker review → actor handoff → system commit/reconcile → authoritative result.",
      "patterns": [
        "SINGLE_INITIALIZATION_STATUS",
        "FILE_UPLOAD_VALIDATE",
        "ACTOR_HANDOFF",
        "AUTO_EXECUTION_RESULT",
        "UNKNOWN_RECOVERY"
      ]
    },
    {
      "id": "UIF-14",
      "bj": "BJ-14",
      "name": "Tính và công bố giá vốn",
      "screens": [
        "SCR-072",
        "SCR-074",
        "SCR-077"
      ],
      "entry": [
        "SCR-072"
      ],
      "terminals": [
        "SCR-077"
      ],
      "uc": [
        "UC-14-01",
        "UC-14-04"
      ],
      "intent": "Chủ cửa hàng chốt giá vốn mỗi kỳ hoặc cập nhật trong kỳ: việc chặn đọc từ dữ liệu thật và dẫn tới nơi xử lý; phương pháp lấy từ chính sách cửa hàng và chỉ đọc; công bố chỉ ghi phần chênh lệch.",
      "patterns": [
        "COST_WORK_QUEUE",
        "DIRTY_SCOPE_SYSTEM_DERIVED",
        "TENANT_METHOD_READ_ONLY",
        "BLOCKERS_INLINE",
        "ALTERNATIVE_METHOD_AS_COMPARISON",
        "PUBLICATION_REVIEW_SHEET",
        "OFFICIAL_COST_RESULT",
        "UNKNOWN_RECOVERY",
        "FINANCIAL_MASKING"
      ],
      "entryContexts": [
        {
          "id": "module",
          "type": "MODULE_ENTRY",
          "screen": "SCR-072",
          "actor": "Chủ cửa hàng",
          "from": "Giá trị kho > Giá vốn"
        },
        {
          "id": "dirty-scope",
          "type": "CONTEXTUAL_DEEP_LINK",
          "screen": "SCR-074",
          "actor": "Chủ cửa hàng",
          "from": "Phạm vi cần cập nhật giá vốn"
        }
      ]
    },
    {
      "id": "UIF-15",
      "bj": "BJ-15",
      "name": "Báo cáo nhập – xuất – tồn và thẻ kho",
      "screens": [
        "SCR-055",
        "SCR-056",
        "SCR-059"
      ],
      "entry": [
        "SCR-055"
      ],
      "terminals": [
        "SCR-055",
        "SCR-059"
      ],
      "uc": [
        "UC-15-01",
        "UC-15-02",
        "UC-15-03",
        "UC-15-04"
      ],
      "intent": "Chủ cửa hàng xem báo cáo nhập – xuất – tồn theo kỳ và mọi người tra thẻ kho một sản phẩm: vào thẳng số liệu, rõ cách hiểu ngày và mốc dữ liệu, tiền chỉ chủ thấy; chỉ đọc, thấy sai thì sang sửa sai (BJ-11).",
      "patterns": [
        "SHARED_SCREEN_CONTEXT_MODE",
        "AS_OF_FRESHNESS",
        "BUSINESS_EVIDENCE_TIMELINE",
        "EXPORT_REVIEW"
      ]
    },
    {
      "id": "UIF-16",
      "bj": "BJ-16",
      "name": "Điều tra và đối soát sai lệch",
      "screens": [
        "SCR-078",
        "SCR-079",
        "SCR-081",
        "SCR-082",
        "SCR-083"
      ],
      "entry": [
        "SCR-078",
        "SCR-079"
      ],
      "terminals": [
        "SCR-083"
      ],
      "uc": [
        "UC-16-01",
        "UC-16-02",
        "UC-16-03",
        "UC-16-04"
      ],
      "intent": "Điều tra sai lệch evidence-first, chỉ bảo vệ phạm vi cần thiết và route đúng owner; chỉ khôi phục dữ liệu hiển thị khi đã chứng minh sổ kho đúng.",
      "patterns": [
        "EVIDENCE_FIRST",
        "SCOPE_PROTECTION",
        "SYSTEM_RECOMMENDED_RECOVERY",
        "CROSS_BJ_HANDOFF",
        "REVIEW_DIFFERENCES_FIRST"
      ]
    },
    {
      "id": "UIF-17",
      "bj": "BJ-17",
      "name": "Phục hồi nghiệp vụ có kết quả chưa xác định",
      "screens": [
        "SCR-078",
        "SCR-079",
        "SCR-083"
      ],
      "entry": [
        "SCR-078",
        "SCR-079"
      ],
      "terminals": [
        "SCR-083"
      ],
      "uc": [
        "UC-17-01",
        "UC-17-02",
        "UC-17-03",
        "UC-17-04"
      ],
      "intent": "Xác lập finality cho operation UNKNOWN bằng đúng định danh; có commit thì không ghi lại tác động, no-commit thì tiếp tục cùng operation, thiếu bằng chứng thì giữ UNKNOWN và escalated.",
      "patterns": [
        "UNKNOWN_RECOVERY",
        "SAME_IDENTITY_CONTINUATION",
        "EVIDENCE_FIRST",
        "NO_BLIND_RETRY",
        "CONTROLLED_ESCALATION"
      ]
    },
    {
      "id": "CAP-01",
      "bj": "CAP-01",
      "name": "Chính sách tồn & cận hạn",
      "screens": [
        "SCR-062",
        "SCR-063",
        "SCR-065"
      ],
      "entry": [
        "SCR-062",
        "SCR-063"
      ],
      "terminals": [
        "SCR-065"
      ],
      "uc": [],
      "intent": "Supporting capability của Theme 7. Prototype trong HTML harness theo quyết định dự án 2026-09-15; Figma chỉ cung cấp Design System và tham khảo visual. Entry/permission/return destination vẫn là điểm tích hợp chưa khóa nghiệp vụ, nên không suy diễn thành navigation production.",
      "patterns": [
        "FORM_TO_REVIEW",
        "POLICY_VERSION_RESULT",
        "NO_LEDGER_EFFECT",
        "CONTEXT_EXIT"
      ],
      "entryContexts": [
        {
          "id": "workbench-policy",
          "type": "SUPPORTING_CAPABILITY_ENTRY",
          "screen": "SCR-062",
          "actor": "Chủ cửa hàng",
          "from": "Theme 7 prototype / supporting capability"
        },
        {
          "id": "workbench-near-expiry",
          "type": "SUPPORTING_CAPABILITY_ENTRY",
          "screen": "SCR-063",
          "actor": "Chủ cửa hàng",
          "from": "Theme 7 prototype / supporting capability"
        }
      ]
    }
  ],
  "screens": [
    {
      "id": "SCR-001",
      "short": "001",
      "name": "Tồn kho",
      "surface": "list",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-01"
      ],
      "purpose": "Tìm sản phẩm và lọc nhanh stock-level/expiry attention trên cùng một danh sách; freshness theo query_as_of; attention phrase phải đọc trọn trong canonical row.",
      "actors": [
        "Nhân viên bán hàng",
        "Thủ kho",
        "Chủ cửa hàng",
        "Người mua hàng"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "STALE",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nobivac DHPPi · SP-000184",
          "106 hộp khả dụng",
          "Có lô cận hạn"
        ],
        [
          "Amox 500 · SP-000066",
          "42 hộp khả dụng",
          "Tồn thấp"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VChip",
        "VText",
        "VIcon",
        "VBanner",
        "VButton",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Canonical List Row + Search/Chips; one context-aware attention phrase, no status badge for quantities",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nobivac DHPPi",
          "example": "SP-000184 · 106 hộp khả dụng",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Amox 500",
          "example": "SP-000066 · 42 hộp khả dụng",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-002",
      "short": "002",
      "name": "Kết quả khả dụng",
      "surface": "dashboard",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-02"
      ],
      "purpose": "So sánh vật lý, đủ điều kiện, đã giữ và khả dụng.",
      "actors": [
        "Nhân viên bán hàng",
        "Thủ kho",
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "STALE",
        "PERMISSION_DENIED",
        "FINANCIAL_MASKED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Tồn vật lý",
          "Toàn bộ hàng hiện diện",
          "120"
        ],
        [
          "Đủ điều kiện bán",
          "Đã có giá và trạng thái hợp lệ",
          "118"
        ],
        [
          "Đã giữ",
          "Theo reservation",
          "12"
        ],
        [
          "Khả dụng",
          "Có thể bán ngay",
          "106"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VCard",
        "VIconBox",
        "VText",
        "VBadge",
        "VBanner",
        "VSkeleton"
      ],
      "themeComposition": "Theme7DashboardSurface",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Tồn vật lý",
          "example": "Toàn bộ hàng hiện diện · 120",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Đủ điều kiện bán",
          "example": "Đã có giá và trạng thái hợp lệ · 118",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Đã giữ",
          "example": "Theo reservation · 12",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Khả dụng",
          "example": "Có thể bán ngay · 106",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-003",
      "short": "003",
      "name": "Chi tiết tồn kho",
      "surface": "detail",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-02"
      ],
      "purpose": "Hiểu Product-level availability, lý do physical khác eligible, monitoring attention và LOT expiry trong snapshot query_as_of hiện tại.",
      "actors": [
        "Nhân viên bán hàng",
        "Thủ kho",
        "Chủ cửa hàng",
        "Người mua hàng"
      ],
      "states": [
        "READY",
        "LOADING",
        "STALE",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Sản phẩm",
          "Nobivac DHPPi"
        ],
        [
          "Dữ liệu đến",
          "09:42 · 27/08/2026"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "DS v2 / List Row",
        "DS v2 / Key-value Row",
        "VBanner",
        "VBottomSheet",
        "VText",
        "VButton"
      ],
      "themeComposition": "Compact Product identity → Emphasis Key-value availability → supporting/reason Key-value Rows → LOT Navigation rows",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Khả dụng",
          "example": "106 hộp",
          "ownership": "SYSTEM_DERIVED_PRODUCT_LEVEL"
        },
        {
          "label": "Tồn vật lý",
          "example": "120 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Đủ điều kiện bán",
          "example": "118 hộp",
          "ownership": "SYSTEM_DERIVED_FROM_ELIGIBILITY"
        },
        {
          "label": "Đã giữ",
          "example": "12 hộp",
          "ownership": "SERVER_AUTHORITATIVE_PRODUCT_WAREHOUSE_RESERVATION"
        },
        {
          "label": "Không đủ điều kiện",
          "example": "Cách ly 2 hộp",
          "ownership": "SYSTEM_DERIVED_REASON_BREAKDOWN"
        },
        {
          "label": "Dữ liệu đến",
          "example": "09:42 · 27/08/2026",
          "ownership": "SERVER_QUERY_AS_OF"
        }
      ]
    },
    {
      "id": "SCR-004",
      "short": "004",
      "name": "Chi tiết lô",
      "surface": "overlay",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-02"
      ],
      "purpose": "Contextual LOT detail: physical/eligible + HSD precision + expiry action; không phân bổ reservation/availability xuống LOT.",
      "actors": [
        "Nhân viên bán hàng",
        "Thủ kho",
        "Chủ cửa hàng",
        "Người mua hàng"
      ],
      "states": [
        "READY"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "DH2507",
          "HSD 30/11/2026",
          "70 hộp vật lý · 70 đủ điều kiện"
        ],
        [
          "DH2509",
          "HSD 15/09/2026",
          "50 hộp vật lý · 48 đủ điều kiện"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VBottomSheet",
        "VText"
      ],
      "themeComposition": "Theme7InventoryLotDetailSheet",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Lô",
          "example": "DH2509",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "HSD",
          "example": "15/09/2026 (DAY)",
          "ownership": "EXTERNAL_SOURCE_PRECISION_PRESERVED"
        },
        {
          "label": "Tồn vật lý",
          "example": "50 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Đủ điều kiện bán",
          "example": "48 hộp",
          "ownership": "SYSTEM_DERIVED_FROM_ELIGIBILITY"
        }
      ]
    },
    {
      "id": "SCR-005",
      "short": "005",
      "name": "Nguồn và thời điểm cập nhật",
      "surface": "overlay",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-03"
      ],
      "purpose": "Contextual provenance summary: query_as_of + recent physical movement/source + reservation summary; deep history handoff BJ-15.",
      "actors": [
        "Nhân viên bán hàng",
        "Thủ kho",
        "Chủ cửa hàng",
        "Người mua hàng"
      ],
      "states": [
        "READY"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nhận hàng gần nhất",
          "PN-260816-04",
          "+118 hộp"
        ],
        [
          "Đang giữ",
          "SO-260817-08",
          "12 hộp"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VBottomSheet",
        "VText"
      ],
      "themeComposition": "Theme7InventoryProvenanceSheet",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Dữ liệu đến",
          "example": "09:42 · 27/08/2026",
          "ownership": "SERVER_QUERY_AS_OF"
        },
        {
          "label": "Nhận hàng gần nhất",
          "example": "PN-260816-04 · +118 hộp",
          "ownership": "SERVER_AUTHORITATIVE_TRACE_SUMMARY"
        },
        {
          "label": "Đang giữ",
          "example": "SO-260817-08 · 12 hộp",
          "ownership": "SERVER_AUTHORITATIVE_RESERVATION_SUMMARY"
        }
      ]
    },
    {
      "id": "SCR-006",
      "short": "006",
      "name": "Chọn cách nhận hàng (đã gộp vào SCR-007)",
      "surface": "choice",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-01",
        "UC-02-02"
      ],
      "purpose": "Đã gộp vào SCR-007 từ v5.8.0: link cũ mở Nhận hàng ở trạng thái mặc định.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nhận theo chứng từ",
          "Đã có chứng từ mua để đối chiếu",
          ""
        ],
        [
          "Nhập hàng nhanh",
          "Hàng đã đến, chưa có chứng từ mua",
          "Theo capability"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VCardIcon",
        "VCardTitle",
        "VIcon"
      ],
      "themeComposition": "Theme7ChoiceSurface",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nhận theo chứng từ",
          "example": "Đã có chứng từ mua để đối chiếu",
          "ownership": "NAVIGATION_CHOICE"
        },
        {
          "label": "Nhập hàng nhanh",
          "example": "Hiển thị theo capability; disabled nếu có blocker tạm thời",
          "ownership": "CAPABILITY_GATED_NAVIGATION_CHOICE"
        }
      ]
    },
    {
      "id": "SCR-007",
      "short": "007",
      "name": "Nhận hàng",
      "surface": "list",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-01"
      ],
      "purpose": "Chọn chứng từ nguồn cần nhận (tìm theo chứng từ, nhà cung cấp hoặc sản phẩm) hoặc nhập hàng nhanh khi hàng đến chưa có chứng từ; mỗi dòng dùng source_line_id/version và remaining_receivable_qty do source domain cung cấp, không tự suy ra phần còn được nhận.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED",
        "PARTIAL_RECEIPT",
        "SOURCE_VERSION_STALE"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "PN-260816-04",
          "Minh Dũng · Ngày chứng từ 16/08/2026",
          "2 mặt hàng đang chờ nhận"
        ],
        [
          "PN-260816-05",
          "An Việt · Ngày chứng từ 16/08/2026",
          "1 mặt hàng · đã nhận một phần trước đó"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VCard",
        "VCardTitle",
        "VText",
        "VSkeleton",
        "VEmptyState",
        "VBanner"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Chứng từ",
          "example": "PN-260816-04",
          "ownership": "SOURCE_AUTHORITATIVE_DOCUMENT"
        },
        {
          "label": "Ngày chứng từ",
          "example": "16/08/2026",
          "ownership": "SOURCE_AUTHORITATIVE_DOCUMENT_DATE"
        },
        {
          "label": "Lượng còn được nhận",
          "example": "Theo từng source line + version + transaction UOM",
          "ownership": "SOURCE_AUTHORITATIVE_REMAINING_RECEIVABLE"
        }
      ]
    },
    {
      "id": "SCR-008",
      "short": "008",
      "name": "Thông tin nhập hàng nhanh",
      "surface": "form",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-02"
      ],
      "purpose": "Ghi thông tin chung của một lần nhập hàng nhanh: nhà cung cấp hiện hữu, kho mặc định disabled, ngày nhận do hệ thống xác lập và chứng từ giao nhận; sản phẩm được xử lý ở Hàng thực nhận.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Nhà cung cấp",
          "Chọn từ master hiện hữu · bắt buộc"
        ],
        [
          "Kho nhận",
          "Kho mặc định · disabled"
        ],
        [
          "Ngày nhận",
          "Ngày hệ thống xác lập · read-only"
        ],
        [
          "Chứng từ giao nhận",
          "1+ evidence refs"
        ]
      ],
      "cards": [],
      "notice": "Quick chỉ xuất hiện khi có capability. Kho nhận là kho mặc định Phase 1 và không thể thay đổi. Dữ liệu trước submit chỉ sống trong phiên màn hình; rời flow, refresh hoặc đóng app thì mất.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VText",
        "VSelect",
        "VTextField",
        "VFileDropZone",
        "VBanner",
        "VButton",
        "VEmptyState",
        "DS v2 / Select Sheet",
        "DS v2 / List Row",
        "VSearchBar",
        "DS v2 / Sticky Footer"
      ],
      "themeComposition": "Theme7ReceiptHeaderForm",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nhà cung cấp",
          "example": "Minh Dũng · NCC-00018",
          "ownership": "USER_SELECTION_EXISTING_MASTER_SERVER_VALIDATED"
        },
        {
          "label": "Kho nhận",
          "example": "Kho trung tâm",
          "ownership": "SERVER_CONTEXT_READ_ONLY"
        },
        {
          "label": "Ngày nhận",
          "example": "16/09/2026",
          "ownership": "SERVER_TENANT_BUSINESS_DATE_READ_ONLY"
        },
        {
          "label": "Chứng từ giao nhận",
          "example": "1+ delivery evidence refs",
          "ownership": "USER_EVIDENCE_REFS_SHARED_ATTACHMENT_POLICY"
        },
        {
          "label": "Ownership assertion",
          "example": "actor + asserted_at + evidence refs + version/hash",
          "ownership": "STRUCTURED_ASSERTION_CAPABILITY_GATED"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-009",
      "short": "009",
      "name": "Hàng thực nhận",
      "surface": "list",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-01",
        "UC-02-02"
      ],
      "purpose": "Theo dõi các mặt hàng Product+transaction UOM của lần nhận; mỗi dòng mở editor chi tiết. Không cộng chéo số lượng khác UOM.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "EMPTY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED",
        "READ_ONLY"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nobivac DHPPi",
          "120 hộp theo chứng từ",
          "Chưa ghi nhận"
        ],
        [
          "Amoxicillin LA",
          "24 chai theo chứng từ",
          "Chưa ghi nhận"
        ]
      ],
      "notice": "Quick: Product+UOM đang chuẩn bị chỉ sống trong session memory; không có server/local draft. Document mode giữ persistence riêng theo UC-02-01.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VCard",
        "VText",
        "VBanner",
        "VEmptyState",
        "VButton",
        "VSection",
        "VCardTitle",
        "VIcon"
      ],
      "themeComposition": "Theme7ReceiptLinesOverview",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Tiến độ",
          "example": "0/2 sản phẩm đã xử lý",
          "ownership": "DERIVED"
        },
        {
          "label": "Sản phẩm",
          "example": "Nobivac DHPPi · 120 hộp theo chứng từ · Chưa ghi nhận",
          "ownership": "SOURCE_OR_DRAFT_LINE_SUMMARY"
        },
        {
          "label": "Sản phẩm",
          "example": "Amoxicillin LA · 24 chai theo chứng từ · Chưa ghi nhận",
          "ownership": "SOURCE_OR_DRAFT_LINE_SUMMARY"
        }
      ]
    },
    {
      "id": "SCR-084",
      "short": "084",
      "name": "Chi tiết hàng thực nhận",
      "surface": "form",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-01",
        "UC-02-02"
      ],
      "purpose": "Xử lý đúng một receipt line Product+transaction UOM; bốn phân loại là authoritative inputs, Tổng kiểm nhận và Vào tồn vật lý là derived; LOT date giữ precision nguồn DAY/MONTH/YEAR.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "LOT_CONFLICT",
        "DUPLICATE_LINE",
        "PERMISSION_DENIED",
        "READ_ONLY"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Sản phẩm",
          "Nobivac DHPPi"
        ],
        [
          "Đơn vị nhập",
          "hộp"
        ],
        [
          "Đạt",
          "118"
        ],
        [
          "Cách ly",
          "2"
        ],
        [
          "Hỏng",
          "0"
        ],
        [
          "Từ chối",
          "0 · không vào tồn"
        ],
        [
          "Tổng kiểm nhận",
          "120 (derive)"
        ],
        [
          "Vào tồn vật lý",
          "120 (Đạt + Cách ly + Hỏng)"
        ],
        [
          "Mã lô",
          "ND2408"
        ],
        [
          "Hạn dùng",
          "31/12/2027 hoặc 12/2027 hoặc 2027"
        ],
        [
          "Ngày sản xuất",
          "Giữ precision nguồn nếu có"
        ]
      ],
      "cards": [],
      "notice": "Bốn phân loại là authoritative inputs. Quick: Xong chỉ cập nhật session memory; không command lưu nháp. Document mode giữ persistence riêng theo UC-02-01.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "DS v2 / List Row",
        "VTextField",
        "VSelect",
        "DS v2 / Key-value Row",
        "VNumericKeypadSheet",
        "VButton",
        "VBanner",
        "VEmptyState",
        "DS v2 / Sticky Footer"
      ],
      "themeComposition": "Compact Status List Row product context → quantity/LOT form controls → derived Key-value summary",
      "uifs": [
        "UIF-02"
      ],
      "mode": {
        "modes": {
          "document": "SOURCE_LINE_READ_ONLY_IDENTITY",
          "quick": "PRODUCT_AND_UOM_SELECTION"
        },
        "note": "Cùng editor, khác nguồn xác định product/UOM."
      },
      "dataRows": [
        {
          "label": "Sản phẩm",
          "example": "Nobivac DHPPi",
          "ownership": "SOURCE_PREFILLED_OR_EXISTING_PRODUCT_SELECTION"
        },
        {
          "label": "Đơn vị nhập",
          "example": "hộp",
          "ownership": "SOURCE_PREFILLED_OR_VALID_UOM_SELECTION"
        },
        {
          "label": "Đạt / Cách ly / Hỏng / Từ chối",
          "example": "118 / 2 / 0 / 0",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Tổng kiểm nhận",
          "example": "120 (derived)",
          "ownership": "DERIVED_READ_ONLY"
        },
        {
          "label": "Vào tồn vật lý",
          "example": "120 (derived)",
          "ownership": "DERIVED_READ_ONLY"
        },
        {
          "label": "Lô/HSD/NSX",
          "example": "LOT identity + original date precision DAY/MONTH/YEAR",
          "ownership": "CONDITIONAL_BY_PRODUCT_POLICY_SERVER_VALIDATED"
        }
      ]
    },
    {
      "id": "SCR-010",
      "short": "010",
      "name": "Rà soát nhận hàng",
      "surface": "review",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-01",
        "UC-02-02",
        "UC-02-03"
      ],
      "purpose": "Rà soát lần nhận, ngoại lệ nổi lên đầu; người lập gửi duyệt, chủ cửa hàng tự ghi nhận; khi đã gửi phê duyệt thì chỉ xem và về Kho, bị từ chối thì nhận lại.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "APPROVAL_REQUIRED",
        "PERMISSION_DENIED",
        "PENDING_APPROVAL",
        "REJECTED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Thông tin lần nhận",
          "Nguồn · nhà cung cấp · kho · ngày nhận · chứng từ giao nhận",
          "Đã xác lập"
        ],
        [
          "Hàng thực nhận",
          "Tóm tắt theo từng Product+UOM/LOT",
          "Đã xử lý"
        ]
      ],
      "notice": "Quick: submit create-and-submit không yêu cầu price/FX basis. Thành công mới có receiptId và PENDING_APPROVAL; thiếu approver hoặc dữ liệu BJ02 bắt buộc thì rejection không tạo phiếu.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-02-SUBMIT",
          "label": "Gửi phê duyệt / Xác nhận nhận hàng",
          "bc": "BC-IC-07",
          "api": "API-C-26",
          "tone": "primary"
        },
        {
          "id": "NAV-02-RETURN-WAREHOUSE",
          "label": "Về Kho",
          "bc": "NAVIGATION_ONLY",
          "api": "NONE",
          "tone": "primary",
          "state": "PENDING_APPROVAL"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBanner",
        "VButton",
        "DS v2 / Sticky Footer"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Thông tin lần nhận",
          "example": "Nguồn · nhà cung cấp · kho · ngày nhận · evidence",
          "ownership": "SERVER_AUTHORITATIVE_SUMMARY"
        },
        {
          "label": "Hàng thực nhận",
          "example": "Per-line Tổng kiểm nhận / Vào tồn vật lý / LOT",
          "ownership": "DERIVED_FROM_AUTHORITATIVE_INPUTS"
        },
        {
          "label": "Kết quả định tuyến",
          "example": "Quick luôn cần approval; document theo accepted-physical over-source/tolerance",
          "ownership": "SYSTEM_DERIVED"
        }
      ]
    },
    {
      "id": "SCR-011",
      "short": "011",
      "name": "Phê duyệt yêu cầu nhận hàng",
      "surface": "review",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-03"
      ],
      "purpose": "Người duyệt rà soát evidence/ownership/hàng thực nhận và quyết định đúng submitted revision; Quick Receipt không yêu cầu aggregate risk/price-FX tại BJ02.",
      "actors": [
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "APPROVAL_REQUIRED",
        "PERMISSION_DENIED",
        "SELF_APPROVAL_NOT_ALLOWED",
        "APPROVAL_ALREADY_DECIDED",
        "FINANCIAL_MASKED",
        "RECORDED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Lý do cần duyệt",
          "Nhập hàng nhanh / vượt lượng còn được nhận"
        ],
        [
          "Người gửi",
          "Nguyễn Văn An"
        ],
        [
          "Gửi lúc",
          "09:41 · 16/09/2026"
        ],
        [
          "Tổng giá trị rủi ro",
          "Chỉ nhánh document/risk-based · theo capability"
        ],
        [
          "Chứng từ giao nhận",
          "Preview evidence refs"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-02-DECIDE",
          "label": "Quyết định yêu cầu nhận hàng",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VBanner",
        "VButton",
        "VBottomSheet",
        "VTextFormField",
        "DS v2 / Sticky Footer"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Lý do cần duyệt",
          "example": "Nhập hàng nhanh",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Người gửi",
          "example": "Nguyễn Văn An",
          "ownership": "SERVER_AUTHORITATIVE_SUBMISSION_ACTOR"
        },
        {
          "label": "Gửi lúc",
          "example": "09:41 · 16/09/2026",
          "ownership": "SERVER_AUTHORITATIVE_SUBMITTED_AT"
        },
        {
          "label": "Tổng giá trị rủi ro",
          "example": "Chỉ document/risk-based; Quick không yêu cầu",
          "ownership": "SYSTEM_DERIVED_CONDITIONAL_PERMISSION_GATED"
        },
        {
          "label": "Chứng từ giao nhận",
          "example": "Preview evidence refs immutable with revision",
          "ownership": "SERVER_AUTHORITATIVE_EVIDENCE_REFS"
        }
      ]
    },
    {
      "id": "SCR-012",
      "short": "012",
      "name": "Kết quả nhận hàng",
      "surface": "result",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-04",
        "UC-02-05"
      ],
      "purpose": "Hiển thị kết quả theo từng Product+UOM line; zero-impact document receipt nói rõ không có hàng vào tồn. UNKNOWN dẫn tới đối soát cùng operation identity, không blind retry.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED",
        "VALUATION_PENDING_RESULT",
        "COMMIT_UNKNOWN"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Mã xử lý",
          "IO-260817-002"
        ],
        [
          "Kết quả",
          "Theo từng sản phẩm/đơn vị"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-02-RECEIVE"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Mã xử lý",
          "example": "IO-260817-002",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Hàng đã ghi nhận",
          "example": "Theo từng sản phẩm và đơn vị",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-013",
      "short": "013",
      "name": "Đối soát kết quả nhận hàng",
      "surface": "timeline",
      "bj": [
        "BJ-02"
      ],
      "uc": [
        "UC-02-05"
      ],
      "purpose": "Đối soát đúng lần nhận bằng evidence authoritative: submitted revision, approval decision, operation result, inventory movement/ledger sequence và server checked_at; chỉ hiện fact đã được chứng minh.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "STALE",
        "PERMISSION_DENIED",
        "PROCESSING_OR_UNKNOWN",
        "TERMINAL"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Hồ sơ nhận",
          "REC-260817-04 · revision đã khóa",
          "submitted_at + maker"
        ],
        [
          "Phê duyệt",
          "APR-REC-260817-04",
          "decided_at + actor"
        ],
        [
          "Kết quả operation",
          "Cùng operation identity",
          "authoritative status"
        ],
        [
          "Movement",
          "Accepted physical movement",
          "recorded_at + ledger sequence"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VLoading",
        "VEmptyState",
        "VCard",
        "VIconBox",
        "VText",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7EvidenceTimeline",
      "uifs": [
        "UIF-02"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Hồ sơ nhận",
          "example": "Mã lần nhận REC-260817-04 · Đã khóa",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Phê duyệt",
          "example": "Người duyệt + thời điểm, chỉ khi có approval",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Kết quả",
          "example": "Đang xác lập / đã xác lập",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Tồn kho",
          "example": "Đang kiểm tra / đã cập nhật",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-014",
      "short": "014",
      "name": "Hàng chờ xác lập giá trị",
      "surface": "list",
      "bj": [
        "BJ-03"
      ],
      "uc": [
        "UC-03-01"
      ],
      "purpose": "Danh sách hàng đã nhận nhưng chưa có giá trị nhập ban đầu; người dùng hiểu ngay việc nào có thể xử lý, cần đối chiếu hoặc cần bổ sung căn cứ.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED",
        "FINANCIAL_MASKED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-03"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Theo chứng từ",
          "example": "PN-260816-04 · Có thể xác lập",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Nhập nhanh",
          "example": "PN-260816-02 · Cần bổ sung căn cứ giá",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ],
      "prototype_status": "DESIGN_PARITY_v3.13.0"
    },
    {
      "id": "SCR-015",
      "short": "015",
      "name": "Xác lập giá trị nhập ban đầu",
      "surface": "detail",
      "bj": [
        "BJ-03"
      ],
      "uc": [
        "UC-03-01"
      ],
      "purpose": "Xử lý từng hàng chờ giá trị: dùng căn cứ VND đã chuẩn hóa hoặc lập direct basis VND có nguồn/ngày/lý do; không hiển thị hay nhập tỷ giá.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "READY",
        "LOADING",
        "VALIDATION_ERROR",
        "PERMISSION_DENIED",
        "EVIDENCE_MISSING",
        "ALREADY_CONFIRMED",
        "SOURCE_CHANGED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Căn cứ đang dùng",
          "Nguồn giá có thẩm quyền dùng để xác lập"
        ],
        [
          "Đơn giá ghi nhận ban đầu",
          "Giá trị dẫn xuất theo UOM"
        ],
        [
          "Direct basis",
          "Đơn giá VND + loại nguồn + ngày căn cứ + bằng chứng tùy chọn + lý do"
        ]
      ],
      "cards": [],
      "notice": "UI không hiển thị Currency/FX. Nguồn ngoại tệ phải được adapter nguồn chuẩn hóa VND trước khi READY.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VAppBar",
        "DS v2 / List Row",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VBanner",
        "VMoneyField",
        "VTextField",
        "VTextarea",
        "VSegmentedControl",
        "VRadio",
        "DS v2 / Form Sheet",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Theme7DetailSurface",
      "uifs": [
        "UIF-03"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nguồn căn cứ",
          "example": "Đơn mua PO-2608-041 hoặc xác nhận trực tiếp của NCC",
          "ownership": "SERVER_AUTHORITATIVE_OR_USER_AUTHORED_DIRECT_BASIS"
        },
        {
          "label": "Cấu thành giá trị",
          "example": "Giá mua − giảm giá + thuế/phí không thu hồi + chi phí đủ căn cứ",
          "ownership": "SYSTEM_DERIVED_READ_ONLY"
        },
        {
          "label": "Tình trạng",
          "example": "Có thể xác lập / Cần đối chiếu / Cần bổ sung căn cứ",
          "ownership": "SERVER_DERIVED_READ_ONLY"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-016",
      "short": "016",
      "name": "Căn cứ và cách tính — Đã hợp nhất",
      "surface": "form",
      "bj": [
        "BJ-03"
      ],
      "uc": [],
      "purpose": "Retired in v3.13.0; route redirects to SCR-015.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-015; không còn là màn hình active.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7FormSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0"
    },
    {
      "id": "SCR-017",
      "short": "017",
      "name": "Rà soát giá trị nhập ban đầu (đã gộp vào SCR-015)",
      "surface": "review",
      "bj": [
        "BJ-03"
      ],
      "uc": [
        "UC-03-01"
      ],
      "purpose": "Đã gộp vào SCR-015 từ v5.9.0: link cũ mở Xác lập giá trị nhập ban đầu ở trạng thái mặc định; rà soát là sheet xác nhận trong SCR-015.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "READY",
        "SOURCE_CHANGED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Giá và giá trị chỉ render khi có quyền tài chính.",
      "actions": [
        {
          "id": "ACT-03-CONFIRM-COST",
          "label": "Xác nhận giá trị",
          "bc": "BC-IV-01",
          "api": "API-C-20",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VAppBar",
        "DS v2 / Summary Card",
        "DS v2 / List Row",
        "DS v2 / Key-value Row",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-03"
      ],
      "mode": {
        "modes": {
          "UIF-03": "DIRECT_VALUATION"
        },
        "note": "Same review anatomy; action/summary copy changes by UIF context."
      },
      "dataRows": [
        {
          "label": "Đơn giá ghi nhận ban đầu",
          "example": "81.700 đ/hộp",
          "ownership": "SERVER_DERIVED_PREVIEW_READ_ONLY"
        },
        {
          "label": "Số lượng áp dụng",
          "example": "50 hộp",
          "ownership": "SERVER_AUTHORITATIVE_PREVIEW"
        },
        {
          "label": "Giá trị nhập ban đầu",
          "example": "4.085.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_PREVIEW"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-018",
      "short": "018",
      "name": "Ghi chi phí mua bổ sung — Đã thay thế",
      "surface": "form",
      "bj": [
        "BJ-13"
      ],
      "uc": [],
      "purpose": "Legacy screen đã được thay thế bởi UIF-13 mới bắt đầu ở SCR-085; không còn route active.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã thay thế bởi SCR-085 → SCR-086 → SCR-089.",
      "sensitive": "Toàn bộ trường tài chính bị loại khỏi DOM khi thiếu quyền.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7FormSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0"
    },
    {
      "id": "SCR-019",
      "short": "019",
      "name": "Kết quả xác lập giá trị",
      "surface": "result",
      "bj": [
        "BJ-03"
      ],
      "uc": [
        "UC-03-01"
      ],
      "purpose": "Kết quả authoritative của initial valuation: receipt, số sản phẩm/dòng, tổng giá trị và trạng thái cần cập nhật giá vốn; không cộng quantity khác UOM.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Phiếu nhận",
          "Receipt đã ghi"
        ],
        [
          "Sản phẩm đã xác lập",
          "Số Product/scope đã ghi"
        ],
        [
          "Tổng giá trị đã ghi",
          "VND"
        ],
        [
          "Giá vốn",
          "Cần cập nhật khi dirty scope phát sinh"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-03-CONFIRM-COST"
      ],
      "components": [
        "VAppBar",
        "VEmptyState",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "DS v2 / List Row",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-03"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Đơn giá ghi nhận ban đầu",
          "example": "81.700 đ/hộp",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        },
        {
          "label": "Giá trị đã ghi",
          "example": "4.085.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        },
        {
          "label": "Giá vốn",
          "example": "Cần cập nhật",
          "ownership": "SERVER_DERIVED_RESULT"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-020",
      "short": "020",
      "name": "Đơn cần giữ hàng",
      "surface": "list",
      "bj": [
        "BJ-04"
      ],
      "uc": [
        "UC-04-01"
      ],
      "purpose": "Tìm đơn đã xác nhận cần kiểm tra khả dụng.",
      "actors": [
        "Nhân viên xử lý đơn",
        "Quản lý"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "SO-260817-08",
          "3 sản phẩm",
          "Chờ giữ"
        ],
        [
          "SO-260817-09",
          "Thiếu 2 hộp",
          "Một phần"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VCard",
        "VCardIcon",
        "VCardTitle",
        "VBadge",
        "VText",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-04"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "SO-260817-08",
          "example": "3 sản phẩm · Chờ giữ",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "SO-260817-09",
          "example": "Thiếu 2 hộp · Một phần",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-021",
      "short": "021",
      "name": "Giữ hàng theo đơn",
      "surface": "detail",
      "bj": [
        "BJ-04"
      ],
      "uc": [
        "UC-04-01",
        "UC-04-02",
        "UC-04-03",
        "UC-04-04"
      ],
      "purpose": "Xem projection giữ hàng hiện hành theo từng source line: còn cần, đang giữ, đã bàn giao và thiếu; không thao tác reservation thủ công.",
      "actors": [
        "Nhân viên xử lý đơn",
        "Quản lý"
      ],
      "states": [
        "READY",
        "LOADING",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nobivac DHPPi · SP-000184",
          "Cần giữ còn lại 16 hộp · Đang giữ 16 hộp",
          ""
        ],
        [
          "Amox 500 · SP-000066",
          "Cần giữ còn lại 50 hộp · Đang giữ 42 hộp",
          "Thiếu 8 hộp"
        ],
        [
          "Bộ chăm sóc cơ bản",
          "Cần giữ còn lại 3 bộ · Đang giữ 2 bộ",
          "Thiếu 1 bộ"
        ],
        [
          "Vitamin ADE · SP-000311",
          "Đã bàn giao 6 chai · Không còn giữ",
          ""
        ]
      ],
      "notice": "Contextual-only từ source có reservation context; current facts only.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-04-RESERVE",
        "ACT-04-RELEASE"
      ],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / Info Row",
        "VSection",
        "DS v2 / List Row",
        "VBadge",
        "VBanner",
        "VSkeleton",
        "VEmptyState",
        "VText"
      ],
      "themeComposition": "VSection → Info Row + List Row + contextual semantic feedback; no mutation CTA",
      "uifs": [
        "UIF-04"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nobivac DHPPi",
          "example": "Cần giữ còn lại 16 hộp · Đang giữ 16 hộp",
          "ownership": "SERVER_AUTHORITATIVE_CURRENT_RESERVATION_PROJECTION"
        },
        {
          "label": "Amox 500",
          "example": "Cần giữ còn lại 50 hộp · Đang giữ 42 hộp · Thiếu 8 hộp",
          "ownership": "SERVER_AUTHORITATIVE_CURRENT_RESERVATION_PROJECTION"
        },
        {
          "label": "Bộ chăm sóc cơ bản",
          "example": "Cần giữ còn lại 3 bộ · Đang giữ 2 bộ · Thiếu 1 bộ",
          "ownership": "SERVER_AUTHORITATIVE_COMBO_GROUP_PROJECTION"
        }
      ]
    },
    {
      "id": "SCR-022",
      "short": "022",
      "name": "Rà soát giữ hàng",
      "surface": "review",
      "bj": [
        "BJ-04"
      ],
      "uc": [
        "UC-04-01"
      ],
      "purpose": "Xác nhận chính sách giao đủ hoặc giao từng phần.",
      "actors": [
        "Nhân viên xử lý đơn",
        "Quản lý"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "APPROVAL_REQUIRED",
        "PERMISSION_DENIED",
        "EXPIRED_RESERVATION"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Giữ ngay",
          "2 dòng",
          "62 đơn vị"
        ],
        [
          "Phần thiếu",
          "Trả về nguồn",
          "8 đơn vị"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-04-RESERVE",
          "label": "Giữ hàng",
          "bc": "BC-IO-03",
          "api": "API-C-03",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VConfirmDialog",
        "VBottomSheet"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-04"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Giữ ngay",
          "example": "2 dòng · 62 đơn vị",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Phần thiếu",
          "example": "Trả về nguồn · 8 đơn vị",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-023",
      "short": "023",
      "name": "Giải phóng hoặc phân bổ lại",
      "surface": "form",
      "bj": [
        "BJ-04"
      ],
      "uc": [
        "UC-04-02",
        "UC-04-03",
        "UC-04-04"
      ],
      "purpose": "Chọn lý do và lượng cần giải phóng hoặc thay thế.",
      "actors": [
        "Nhân viên xử lý đơn",
        "Quản lý"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED",
        "REALLOCATION_REQUIRED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Reservation",
          "RSV-260817-08"
        ],
        [
          "Lý do",
          "Đơn giảm số lượng"
        ],
        [
          "Lượng giải phóng",
          "5 hộp"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-04-RELEASE",
          "label": "Giải phóng hoặc phân bổ lại",
          "bc": "BC-IO-06",
          "api": "API-C-06",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VTextFormField",
        "VNumberField",
        "VMoneyField",
        "VSelect",
        "VCombobox",
        "VDatePicker",
        "VQuantitySelector",
        "VFileDropZone",
        "VButton",
        "VBanner"
      ],
      "themeComposition": "Theme7FormSurface",
      "uifs": [
        "UIF-04"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Reservation",
          "example": "RSV-260817-08",
          "ownership": "PREFILLED_OR_USER_SELECTION"
        },
        {
          "label": "Lý do",
          "example": "Đơn giảm số lượng",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Lượng giải phóng",
          "example": "5 hộp",
          "ownership": "PREFILLED_OR_USER_INPUT_REQUIRES_UC_VALIDATION"
        }
      ]
    },
    {
      "id": "SCR-024",
      "short": "024",
      "name": "Kết quả reservation",
      "surface": "result",
      "bj": [
        "BJ-04"
      ],
      "uc": [
        "UC-04-01",
        "UC-04-02",
        "UC-04-03",
        "UC-04-04"
      ],
      "purpose": "Hiển thị lượng đã giữ, phần thiếu và bước tiếp theo của đơn.",
      "actors": [
        "Nhân viên xử lý đơn",
        "Quản lý"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "PROCESSING",
      "fields": [
        [
          "Đã giữ",
          "62 đơn vị"
        ],
        [
          "Còn thiếu",
          "8 đơn vị"
        ],
        [
          "Tác động tồn vật lý",
          "Không thay đổi"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-04-RESERVE"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-04"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Đã giữ",
          "example": "62 đơn vị",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Còn thiếu",
          "example": "8 đơn vị",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tác động tồn vật lý",
          "example": "Không thay đổi",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-025",
      "short": "025",
      "name": "Đơn cần lấy hàng",
      "surface": "list",
      "bj": [
        "BJ-05"
      ],
      "uc": [
        "UC-05-01"
      ],
      "purpose": "Tìm fulfillment cần lấy/bàn giao. WAITING là chờ source; VERIFYING là đang xác minh finality của đúng operation và phải hiển thị nhưng không actionable.",
      "actors": [
        "Nhân viên xử lý đơn"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "SO-260827-21",
          "Đại lý An Phú · Kho chính",
          "Cần lấy hàng"
        ],
        [
          "SO-260827-24",
          "Phòng khám Minh Tâm · Kho chính",
          "Chờ đơn bán"
        ]
      ],
      "notice": "Tất cả / Cần lấy / Đang chờ là filter cùng một list; default Tất cả. Đang xác minh bàn giao là trạng thái riêng, non-actionable và không được biến thành retry.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "One Navigation/Default List Row collection; source-waiting = State Disabled, same geometry/chevron",
      "uifs": [
        "UIF-05"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Fulfillment / đơn nguồn",
          "example": "SO-260827-21 · source version 7",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Trạng thái xử lý",
          "example": "Cần lấy hàng / Chờ đơn bán / Đang xác minh bàn giao",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-026",
      "short": "026",
      "name": "Hàng cần lấy",
      "surface": "detail",
      "bj": [
        "BJ-05"
      ],
      "uc": [
        "UC-05-01",
        "UC-05-04"
      ],
      "purpose": "Theo dõi đúng fulfillment bằng requested quantity bất biến và tiến độ derive từ picked/consumed/delivered; stale correction chỉ invalidate phạm vi bị ảnh hưởng.",
      "actors": [
        "Nhân viên xử lý đơn"
      ],
      "states": [
        "READY",
        "STALE_RECOVERED",
        "SHORTAGE",
        "LOADING",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Đơn",
          "SO-260827-21"
        ],
        [
          "Khách hàng",
          "Đại lý An Phú"
        ],
        [
          "Tiến độ",
          "12/26 đơn vị đã lấy; 0 đã bàn giao"
        ]
      ],
      "cards": [],
      "notice": "Một Product+UOM có thể gồm nhiều LOT allocations. Requested quantity là source fact bất biến; remaining_to_handover là derived. Stale phải trả affected allocations thật thay vì narrative hard-code.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "DS v2 / Info Row",
        "DS v2 / List Row",
        "VBanner",
        "VButton",
        "VEmptyState"
      ],
      "themeComposition": "Grouped Info Rows → one Navigation/Default Product+UOM collection; unavailable lines = State Disabled",
      "uifs": [
        "UIF-05"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Đơn / fulfillment",
          "example": "SO-260827-21 · source version 7",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Yêu cầu ban đầu",
          "example": "26 đơn vị",
          "ownership": "SOURCE_AUTHORITATIVE_IMMUTABLE"
        },
        {
          "label": "Tiến độ",
          "example": "picked / consumed / remaining được derive từ allocation + handover evidence",
          "ownership": "SYSTEM_DERIVED_FROM_AUTHORITATIVE_FACTS"
        }
      ]
    },
    {
      "id": "SCR-027",
      "short": "027",
      "name": "Chi tiết lấy hàng (đã gộp vào SCR-026)",
      "surface": "form",
      "bj": [
        "BJ-05"
      ],
      "uc": [
        "UC-05-02",
        "UC-05-04"
      ],
      "purpose": "Đã gộp vào SCR-026 từ v5.11.0: mỗi lô một dòng ngay trên Hàng cần lấy, \"Lấy đủ\" một chạm; sheet sửa lượng / đổi lô mở từ dòng lô. Link cũ mở Hàng cần lấy của đơn hiện tại.",
      "actors": [
        "Nhân viên xử lý đơn"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [
        [
          "Sản phẩm",
          "Nobivac DHPPi · hộp"
        ],
        [
          "Còn cần lấy",
          "20 hộp"
        ],
        [
          "Phân bổ lô",
          "DH2507: 4 hộp + DH2509: 16 hộp"
        ],
        [
          "Đã lấy",
          "12/20 hộp"
        ]
      ],
      "cards": [],
      "notice": "Không badge hóa raw quantity. Alternative LOT không preselect; HSD giữ precision DAY/MONTH/YEAR. Nhập picked mới không tự clear physical correction.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VText",
        "VBadge",
        "VBanner",
        "VTextField",
        "DS v2 / Link",
        "DS v2 / List Row",
        "VRadio",
        "VTextarea",
        "VBottomSheet",
        "VButton"
      ],
      "themeComposition": "Product identity → Key-value remaining fact → LOT allocation sections → canonical Bottom Sheet override/correction",
      "uifs": [],
      "mode": null,
      "dataRows": [
        {
          "label": "Sản phẩm + source UOM",
          "example": "Nobivac DHPPi · hộp",
          "ownership": "SOURCE_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "LOT candidate",
          "example": "DH2509 · HSD 09/2027 · Có thể lấy 18 hộp",
          "ownership": "SERVER_CALCULATED_VERSIONED_SNAPSHOT"
        },
        {
          "label": "Lượng đã lấy",
          "example": "4 hộp",
          "ownership": "USER_ASSERTED_SERVER_VALIDATED"
        },
        {
          "label": "Physical correction",
          "example": "Trả old LOT + lấy lại new LOT + actor/time/status",
          "ownership": "USER_ASSERTED_AUDITED"
        }
      ],
      "prototype_status": "RETIRED_v5.11.0"
    },
    {
      "id": "SCR-028",
      "short": "028",
      "name": "Rà soát bàn giao",
      "surface": "review",
      "bj": [
        "BJ-05"
      ],
      "uc": [
        "UC-05-03",
        "UC-05-05"
      ],
      "purpose": "Rà soát actual handover chỉ từ lượng đã pick nhưng chưa consumed; revalidate source/allocation version trước commit và ghi HandoverEvidence bất biến.",
      "actors": [
        "Nhân viên xử lý đơn"
      ],
      "states": [
        "READY",
        "PARTIAL_ALLOWED",
        "PARTIAL_BLOCKED",
        "SOURCE_CHANGED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Khách hàng",
          "Đại lý An Phú"
        ],
        [
          "Bàn giao lần này",
          "12 đơn vị"
        ],
        [
          "Còn sau bàn giao",
          "14 đơn vị"
        ]
      ],
      "cards": [
        [
          "Đã lấy",
          "2 dòng",
          "62 đơn vị"
        ],
        [
          "Xác nhận vật lý",
          "Người dùng xác nhận",
          "Hệ thống lưu bằng chứng"
        ]
      ],
      "notice": "Actual handover <= picked_base_quantity − consumed_base_quantity. Partial policy thuộc fulfillment/source version. CTA Xác nhận đã bàn giao là actor assertion và không rewrite allocation/pick history.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-06-HANDOVER",
          "label": "Xác nhận đã bàn giao",
          "bc": "BC-IO-05",
          "api": "API-C-05",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VBadge",
        "DS v2 / List Row",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VText",
        "VTextField",
        "VBanner",
        "VButton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ActualHandoverReview",
      "uifs": [
        "UIF-05"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Có thể bàn giao",
          "example": "picked − consumed theo từng allocation",
          "ownership": "SYSTEM_DERIVED_FROM_AUTHORITATIVE_FACTS"
        },
        {
          "label": "Bàn giao thực tế",
          "example": "12 đơn vị",
          "ownership": "USER_ASSERTED_SERVER_VALIDATED"
        },
        {
          "label": "Bằng chứng bàn giao",
          "example": "operation + actor/time + source/version + allocation version + product/UOM/LOT/actual base qty",
          "ownership": "SYSTEM_GENERATED_IMMUTABLE"
        }
      ]
    },
    {
      "id": "SCR-029",
      "short": "029",
      "name": "Kết quả bàn giao",
      "surface": "result",
      "bj": [
        "BJ-05"
      ],
      "uc": [
        "UC-05-03",
        "UC-05-05"
      ],
      "purpose": "Hiển thị kết quả bàn giao cùng confirmed_at. UNKNOWN/COMMIT_UNKNOWN giữ nguyên operation identity, chuyển fulfillment sang Đang xác minh bàn giao và handoff BJ17; không Back/retry mutation.",
      "actors": [
        "Nhân viên xử lý đơn"
      ],
      "states": [
        "COMPLETED",
        "PARTIAL_COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Đơn",
          "SO-260827-21"
        ],
        [
          "Bàn giao lúc",
          "16/09/2026 13:08"
        ],
        [
          "Đã bàn giao",
          "12 đơn vị"
        ],
        [
          "Còn lại",
          "14 đơn vị"
        ]
      ],
      "cards": [],
      "notice": "Completed/partial/UNKNOWN render riêng. Partial không rewrite requested/allocation/picked history. UNKNOWN là finality chưa biết, không phải failure cho phép gửi lại.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-06-HANDOVER"
      ],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VIcon",
        "VText",
        "DS v2 / Info Row",
        "DS v2 / List Row",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-05"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Bàn giao lúc",
          "example": "confirmed_at authoritative",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Handover evidence",
          "example": "HO-SO-260827-21-01 · same operation identity",
          "ownership": "SYSTEM_GENERATED_IMMUTABLE"
        },
        {
          "label": "UNKNOWN finality",
          "example": "Đang xác minh bàn giao → BJ17",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-030",
      "short": "030",
      "name": "Hàng khách trả",
      "surface": "list",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-01",
        "UC-06-02",
        "UC-06-03",
        "UC-06-04"
      ],
      "purpose": "Triage return task với mặc định Tất cả; actionable request điều hướng được, request đang chờ duyệt là true read-only/non-actionable.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "RET-260827-03",
          "SO-260812-44 · Cần nhận"
        ],
        [
          "RET-260827-05",
          "SO-260815-19 · Cần phân loại"
        ],
        [
          "RET-260827-07",
          "SO-260820-08 · Đang chờ duyệt lô"
        ]
      ],
      "notice": "Default Tất cả; Cần phân loại đi thẳng SCR-033; request Đang chờ duyệt lô là status-only/non-actionable; completed request rời active queue.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / Search & Filter Header",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VEmptyState"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Filter mặc định",
          "example": "Tất cả",
          "ownership": "PRESENTATION_STATE"
        },
        {
          "label": "RET-260827-03",
          "example": "Phòng khám Minh Tâm · SO-260812-44 · Cần nhận",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Đang chờ duyệt lô",
          "example": "Hiển thị trạng thái; không chevron, không tap vào editing flow",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-031",
      "short": "031",
      "name": "Hàng khách trả",
      "surface": "detail",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-01",
        "UC-06-02",
        "UC-06-03"
      ],
      "purpose": "Rà soát multi-line physical return request; current ReturnExchangeLine authorization là upper bound, cho phép nhận thực tế một phần; gửi line-exception approvals hoặc commit một receipt attempt atomically.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "WAITING_APPROVAL",
        "RETURN_CAP_CHANGED",
        "SOURCE_CHANGED",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Yêu cầu trả",
          "RET-260827-03"
        ],
        [
          "Physical verification",
          "Theo từng Product + UOM + source line"
        ],
        [
          "Commit",
          "Atomic theo receipt attempt; không đồng nghĩa actual = authorized"
        ]
      ],
      "cards": [],
      "notice": "Current ReturnExchangeLine authorization là upper bound; receipt attempt commit atomically sau current approvals/hard guards; physical partial được phép.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-07-SUBMIT-LOT-EXCEPTIONS",
          "label": "Gửi ngoại lệ duyệt",
          "bc": "BC-IC-07",
          "api": "API-C-26",
          "tone": "primary"
        },
        {
          "id": "ACT-07-RECEIVE-RETURN",
          "label": "Ghi nhận hàng trả",
          "bc": "BC-IO-07",
          "api": "API-C-07",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / Info Row",
        "DS v2 / List Row",
        "VBadge",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Được phép nhận lần này",
          "example": "3 hộp theo ReturnExchangeLine hiện tại",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Actual verification",
          "example": "2 hộp · lô DH2507 · Đã kiểm",
          "ownership": "USER_CONFIRMED_SERVER_VALIDATED"
        },
        {
          "label": "Lô giao / Lô thực nhận",
          "example": "Hiển thị thành các fact có nhãn khi khác nhau",
          "ownership": "SERVER_AND_USER_CONFIRMED_FACTS"
        }
      ]
    },
    {
      "id": "SCR-032",
      "short": "032",
      "name": "Chi tiết hàng trả",
      "surface": "form",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-01",
        "UC-06-02"
      ],
      "purpose": "Physical-verify actual quantity/LOT cho một ReturnExchangeLine; quantity không vượt current authorization; declared condition chỉ read-only; new LOT được resolve/hoàn thiện attribute; wrong LOT dùng reason + immutable evidence identity/hash.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "APPROVED_EXCEPTION",
        "REJECTED_EXCEPTION",
        "PENDING_APPROVAL",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Số lượng thực nhận",
          "0..remaining_authorized_quantity theo precision UOM"
        ],
        [
          "Tình trạng khai báo",
          "Read-only từ Theme 5; không prefill inventory classification"
        ],
        [
          "Lô thực nhận",
          "Resolve existing lot hoặc hoàn thiện thuộc tính lô mới"
        ],
        [
          "Ngoại lệ lô",
          "RETURNED_DIFFERENT_LOT hoặc OTHER + evidence id/version/content hash"
        ]
      ],
      "cards": [],
      "notice": "Source LOT không prefill thành user-confirmed actual LOT. Declared condition chỉ để đối chiếu. Lô mới phải hoàn thiện attribute theo Product policy; wrong LOT approval bind evidence content hash.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / List Row",
        "DS v2 / Info Row",
        "VTextField",
        "DS v2 / List Row Selection",
        "VRadio",
        "VTextarea",
        "VBanner",
        "VFileDropZone",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Được phép nhận lần này",
          "example": "3 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tình trạng khai báo",
          "example": "Còn nguyên vẹn",
          "ownership": "SOURCE_CONTEXT_READ_ONLY"
        },
        {
          "label": "Actual quantity",
          "example": "2 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Source LOT",
          "example": "DH2507",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Actual LOT",
          "example": "DH2507 hoặc lô khác",
          "ownership": "USER_CONFIRMED_SERVER_VALIDATED"
        },
        {
          "label": "Evidence identity",
          "example": "evidence_id + version + content_hash",
          "ownership": "SYSTEM_GENERATED_IMMUTABLE"
        }
      ]
    },
    {
      "id": "SCR-033",
      "short": "033",
      "name": "Phân loại hàng trả",
      "surface": "form",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-04"
      ],
      "purpose": "Phân loại vật lý authoritative theo Product+UOM+LOT: user chỉ phân bổ Bán được/Cách ly/Hỏng cho lô chưa hết hạn; Hết hạn do hệ thống derive cho toàn line; không routine approval/evidence trong Phase 1.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "EXPIRED_GUARD",
        "SOURCE_CHANGED",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Tình trạng khai báo",
          "Read-only để đối chiếu"
        ],
        [
          "Bán được / Cách ly / Hỏng",
          "USER_INPUT cho lô chưa hết hạn"
        ],
        [
          "Hết hạn",
          "SYSTEM_DERIVED từ Lot.expiry_date + tenant business date"
        ]
      ],
      "cards": [],
      "notice": "Theme 7 classification là authoritative inventory disposition; EXPIRED do hệ thống derive cho toàn line, user chỉ nhập Bán được/Cách ly/Hỏng cho lô chưa hết hạn.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-07-CLASSIFY",
          "label": "Hoàn tất phân loại",
          "bc": "BC-IO-08",
          "api": "API-C-08",
          "tone": "primary"
        }
      ],
      "traceActions": [
        "ACT-07-CLASSIFY"
      ],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / Info Row",
        "DS v2 / List Row",
        "VBadge",
        "VBottomSheet",
        "VTextField",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Bán được",
          "example": "2 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Cách ly",
          "example": "1 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Hỏng",
          "example": "0 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Hết hạn",
          "example": "Toàn bộ line khi expiry rule đúng; không có input",
          "ownership": "SYSTEM_DERIVED_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-034",
      "short": "034",
      "name": "Ngoại lệ lô cần duyệt",
      "surface": "review",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-02"
      ],
      "purpose": "Approver task list + exact LINE_EXCEPTION decision bound to immutable subject snapshot hash; UI trình bày maker, source return/order context, Product/UOM, quantity, source↔actual LOT, reason và evidence thay vì raw case/version IDs.",
      "actors": [
        "Người duyệt có permission và warehouse scope"
      ],
      "states": [
        "TASK_LIST",
        "READY",
        "APPROVED",
        "REJECTED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Người gửi",
          "Maker read-only"
        ],
        [
          "Ngữ cảnh nguồn",
          "Yêu cầu trả + SalesOrder"
        ],
        [
          "Nội dung ngoại lệ",
          "Product/UOM + actual quantity + source LOT ↔ actual LOT + reason"
        ],
        [
          "Evidence",
          "Ảnh nhãn LOT; identity/version/content hash contract-only"
        ]
      ],
      "cards": [],
      "notice": "LINE_EXCEPTION approval; raw approval/version/hash không phải default Product UI. Thay actual LOT/reason/evidence/lot attrs làm snapshot cũ superseded.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-07-DECIDE-LOT-EXCEPTION",
          "label": "Quyết định ngoại lệ lô",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "DS v2 / List Row",
        "VBadge",
        "DS v2 / Info Row",
        "VBottomSheet",
        "VTextarea",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Người gửi",
          "example": "Nguyễn Minh",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Yêu cầu trả / Đơn bán",
          "example": "RET-260827-07 · SO-260820-08",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Evidence image",
          "example": "Ảnh nhãn LOT xem được",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "subject_snapshot_hash",
          "example": "Contract/audit only; không show mặc định",
          "ownership": "CONTRACT_ONLY"
        }
      ]
    },
    {
      "id": "SCR-035",
      "short": "035",
      "name": "Kết quả hàng trả",
      "surface": "result",
      "bj": [
        "BJ-06"
      ],
      "uc": [
        "UC-06-03",
        "UC-06-04"
      ],
      "purpose": "Authoritative receipt/classification result keyed by source return request and SalesOrder, with server recorded_at/classified_at; không phát minh receipt number; UNKNOWN handoff BJ17 giữ same operation identity và cấm blind retry.",
      "actors": [
        "Thủ kho"
      ],
      "states": [
        "RECEIVED_PENDING_CLASSIFICATION",
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "RECEIVED_PENDING_CLASSIFICATION",
      "fields": [
        [
          "Yêu cầu trả",
          "RET-260827-03"
        ],
        [
          "Đơn bán",
          "SO-260812-44"
        ],
        [
          "Kết quả",
          "per Product/UOM/LOT"
        ],
        [
          "Thời điểm",
          "recorded_at hoặc classified_at authoritative"
        ]
      ],
      "cards": [],
      "notice": "Không tạo số phiếu nhận hàng trả riêng. Result dùng source request + SalesOrder + authoritative timestamp; UNKNOWN chuyển BJ17 bằng same operation identity, không blind retry.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-07-RECEIVE-RETURN",
        "ACT-07-CLASSIFY"
      ],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VPagePadding",
        "VEmptyState",
        "DS v2 / Info Row",
        "VSection",
        "DS v2 / Sticky Footer",
        "VButton",
        "DS v2 / List Row",
        "VBadge"
      ],
      "themeComposition": "Figma DS canonical composition — content-driven mobile surface",
      "uifs": [
        "UIF-06"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Yêu cầu trả",
          "example": "RET-260827-03",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Đơn bán",
          "example": "SO-260812-44",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Ghi nhận lúc / Phân loại lúc",
          "example": "16/09/2026 14:15",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "UNKNOWN finality",
          "example": "Đang xác minh kết quả → BJ17 bằng cùng operation identity",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-036",
      "short": "036",
      "name": "Hàng cần xử lý",
      "surface": "list",
      "bj": [
        "BJ-07",
        "BJ-09",
        "BJ-10"
      ],
      "uc": [
        "UC-07-01",
        "UC-09-01",
        "UC-09-03",
        "UC-10-01"
      ],
      "purpose": "K5: một danh sách chung cho UIF-07 / 09 / 10 — hàng không bán được (hết hạn, hỏng, cách ly, dùng thử), yêu cầu trả nhà cung cấp, hàng chờ tiêu hủy; lọc theo việc bằng chip có số, mở đúng bước đang dở.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Nobivac DHPPi · ND2408",
          "Hết hạn",
          "4 hộp"
        ],
        [
          "Amox 500",
          "Hỏng bao bì",
          "2 hộp"
        ]
      ],
      "notice": "K5 + K6: chip \"Tất cả · Cần xử lý · Trả nhà cung cấp · Tiêu hủy · Đang chờ\"; hàng \"Bán được\" không vào danh sách; dòng chờ duyệt mở được, chỉ đọc.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "DS v2 / Search & Filter Header",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VEmptyState",
        "VSkeleton"
      ],
      "themeComposition": "Mobile / Root List → Search & Filter Header → one homogeneous Navigation List Row collection",
      "uifs": [
        "UIF-07",
        "UIF-09",
        "UIF-10"
      ],
      "mode": {
        "modes": {
          "UIF-07": "RTV",
          "UIF-09": "STATE_CHANGE",
          "UIF-10": "DISPOSAL"
        },
        "note": "Same inventory triage list; labels/filters use active operation context."
      },
      "dataRows": [
        {
          "label": "Nobivac DHPPi · ND2408",
          "example": "Hết hạn · 4 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Amox 500",
          "example": "Hỏng bao bì · 2 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-037",
      "short": "037",
      "name": "Chuẩn bị hàng trả",
      "surface": "detail",
      "bj": [
        "BJ-07",
        "BJ-09",
        "BJ-10"
      ],
      "uc": [
        "UC-07-01",
        "UC-09-01",
        "UC-09-03",
        "UC-10-01"
      ],
      "purpose": "Xac minh vat ly theo exact source Product+UOM+LOT. Product+UOM duoc the hien thanh product group header bang VIcon+VText+VBadge; LOT/non-LOT la nested navigation rows phang ben duoi. Mot grouped collection duy nhat giu ro parent-child hierarchy ma khong tao card cho tung dong.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "SOURCE_UPDATED",
        "WAITING",
        "LOADING",
        "EXPIRED",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Lô",
          "ND2408"
        ],
        [
          "Trạng thái",
          "Cách ly"
        ],
        [
          "Lượng",
          "4 hộp"
        ]
      ],
      "cards": [],
      "notice": "UIF-07 v3.0.1: phân cấp bằng chính List Row của DS. Sản phẩm + đơn vị dùng Status/Compact với icon sản phẩm; lô/không theo lô dùng Navigation/Default không icon trang trí. Không dùng connector hay card lồng; số lượng/lô nguồn vẫn chỉ đọc và sai lệch vẫn yêu cầu cập nhật từ nguồn.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VSection",
        "VText",
        "VIcon",
        "VBadge",
        "VBanner",
        "DS v2 / Info Row",
        "VTextField",
        "VBottomSheet",
        "VButton",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Mobile / Detail -> compact request context -> one grouped collection -> Product+UOM group header -> nested LOT/non-LOT navigation rows -> contextual verification sheet",
      "uifs": [
        "UIF-07",
        "UIF-09",
        "UIF-10"
      ],
      "mode": {
        "modes": {
          "UIF-07": "RTV",
          "UIF-09": "STATE_CHANGE",
          "UIF-10": "DISPOSAL"
        },
        "note": "Evidence/detail is canonical; action availability comes from active context."
      },
      "dataRows": [
        {
          "label": "Lô",
          "example": "ND2408",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Trạng thái",
          "example": "Cách ly",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Lượng",
          "example": "4 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-038",
      "short": "038",
      "name": "Chuyển trạng thái",
      "surface": "form",
      "bj": [
        "BJ-09"
      ],
      "uc": [
        "UC-09-01",
        "UC-09-02",
        "UC-09-04"
      ],
      "purpose": "Maker lập một state-change request hợp lệ hoặc approver độc lập xem evidence read-only để quyết định; không có user-facing save draft.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "PENDING_APPROVAL",
        "APPROVAL_REVIEW",
        "LOCKED",
        "SELF_APPROVAL_NOT_ALLOWED",
        "PERMISSION_DENIED",
        "STATE_CHANGE_BASIS_STALE"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Từ",
          "Bán được · chỉ đọc"
        ],
        [
          "Sang",
          "Cách ly"
        ],
        [
          "Số lượng chuyển",
          "5 hộp"
        ],
        [
          "Lý do",
          "Bao bì có dấu hiệu bất thường"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-COMMON-SUBMIT",
          "label": "Gửi xử lý",
          "bc": "BC-IC-07",
          "api": "API-C-26",
          "tone": "primary"
        },
        {
          "id": "ACT-COMMON-DECIDE",
          "label": "Quyết định phê duyệt",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        }
      ],
      "traceActions": [
        "ACT-08-STATE",
        "ACT-COMMON-SAVE-DRAFT"
      ],
      "components": [
        "VSection",
        "VCard",
        "VTextFormField",
        "VNumberField",
        "VMoneyField",
        "VSelect",
        "VCombobox",
        "VDatePicker",
        "VQuantitySelector",
        "VFileDropZone",
        "VButton",
        "VBanner"
      ],
      "themeComposition": "Theme7FormSurface",
      "uifs": [
        "UIF-09"
      ],
      "mode": {
        "modes": {
          "UIF-09": "PREPARE_OR_APPROVAL"
        },
        "note": "Không còn thuộc UIF-07; BJ-07 dùng source-authorized system preparation và đi thẳng tới handover."
      },
      "dataRows": [
        {
          "label": "Trạng thái hiện tại",
          "example": "Bán được",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Trạng thái mới",
          "example": "Cách ly",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Số lượng",
          "example": "6 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Lý do",
          "example": "Chờ đánh giá",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        }
      ]
    },
    {
      "id": "SCR-039",
      "short": "039",
      "name": "Bàn giao trả nhà cung cấp",
      "surface": "review",
      "bj": [
        "BJ-07"
      ],
      "uc": [
        "UC-07-04"
      ],
      "purpose": "Final review actual handover: concise grouped Info Row context + one grouped collection where Product/UOM uses the same product group header and LOT evidence uses Key-value rows; no cross-UOM aggregation and no duplicate confirmation.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "SOURCE_CHANGED",
        "PHYSICAL_MISMATCH",
        "VALIDATION_ERROR",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Yêu cầu",
          "RTV-260827-02"
        ],
        [
          "Mục Product+UOM",
          "3"
        ],
        [
          "Dòng xác minh",
          "4"
        ],
        [
          "Xác nhận vật lý",
          "Actual handover"
        ]
      ],
      "cards": [],
      "notice": "v3.0.1: rà soát cuối dùng cùng phân cấp sản phẩm + đơn vị như bước chuẩn bị; bằng chứng lô dùng Key-value Row và số lượng là dữ liệu, không phải badge. Chỉ có một CTA bàn giao chính.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-08-RTV",
          "label": "Xác nhận đã bàn giao",
          "bc": "BC-IO-09",
          "api": "API-C-09",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VSection",
        "VText",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VBadge",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Mobile / Detail -> concise grouped Info Rows -> Product/UOM group headers -> grouped allocation Key-value rows -> sticky commit",
      "uifs": [
        "UIF-07"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Approved return",
          "example": "RTV-260817-02",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Lượng bàn giao",
          "example": "4 hộp",
          "ownership": "SERVER_AUTHORITATIVE_RECHECKED"
        },
        {
          "label": "Bằng chứng bàn giao",
          "example": "actor + time + source/version + product/lot/qty",
          "ownership": "SYSTEM_GENERATED_IMMUTABLE"
        }
      ]
    },
    {
      "id": "SCR-040",
      "short": "040",
      "name": "Yêu cầu tiêu hủy",
      "surface": "review",
      "bj": [
        "BJ-10"
      ],
      "uc": [
        "UC-10-01",
        "UC-10-02",
        "UC-10-03"
      ],
      "purpose": "Một canonical surface có các mode loại trừ nhau: maker draft, maker pending, approver review, approved-awaiting-completion và completion assertion.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "READY",
        "PRICE_BASIS_REQUIRED",
        "PENDING_APPROVAL",
        "APPROVAL_REVIEW",
        "APPROVED_PENDING_DISPOSAL",
        "COMPLETION",
        "COMPLETION_QTY_BLOCKED",
        "PERMISSION_DENIED",
        "VALIDATION_ERROR",
        "SELF_APPROVAL_NOT_ALLOWED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Số lượng đề nghị",
          "4 hộp"
        ],
        [
          "Lý do",
          "Hàng hết hạn"
        ],
        [
          "Bằng chứng",
          "2 ảnh"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Giá trị rủi ro chỉ render cho người có quyền tài chính.",
      "actions": [
        {
          "id": "ACT-COMMON-SUBMIT",
          "label": "Gửi yêu cầu tiêu hủy",
          "bc": "BC-IC-07",
          "api": "API-C-26",
          "tone": "primary"
        },
        {
          "id": "ACT-COMMON-DECIDE",
          "label": "Quyết định phê duyệt",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        },
        {
          "id": "ACT-08-DISPOSE",
          "label": "Xác nhận đã tiêu hủy",
          "bc": "BC-IO-11",
          "api": "API-C-11",
          "tone": "danger"
        }
      ],
      "traceActions": [
        "ACT-COMMON-SAVE-DRAFT"
      ],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VConfirmDialog",
        "VBottomSheet"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-10"
      ],
      "mode": {
        "modes": {
          "UIF-10": "PREPARE_APPROVAL_COMPLETION"
        },
        "note": "Three mutually-exclusive modes; approval never decrements physical inventory."
      },
      "dataRows": [
        {
          "label": "Số lượng đề nghị",
          "example": "4 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Lý do",
          "example": "Hàng hết hạn",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Bằng chứng",
          "example": "2 ảnh",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        }
      ]
    },
    {
      "id": "SCR-041",
      "short": "041",
      "name": "Kết quả xử lý",
      "surface": "result",
      "bj": [
        "BJ-07",
        "BJ-09",
        "BJ-10"
      ],
      "uc": [
        "UC-07-02",
        "UC-07-03",
        "UC-07-04",
        "UC-09-02",
        "UC-09-03",
        "UC-09-04",
        "UC-10-04"
      ],
      "purpose": "Finality tra nha cung cap. COMPLETED dung mot grouped collection voi Product+UOM group header -> LOT evidence; UNKNOWN giu cung lan xac nhan, khong blind retry; terminal no Back.",
      "actors": [
        "Thủ kho",
        "Người phê duyệt"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "PENDING_APPROVAL",
        "REJECTED_EXECUTION",
        "REJECTED",
        "UNKNOWN",
        "EXPIRED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Operation",
          "IO-260817-088"
        ],
        [
          "Action",
          "Chuyển trạng thái"
        ],
        [
          "Tác động vật lý",
          "Không đổi"
        ]
      ],
      "cards": [],
      "notice": "UIF-07 v3.0.1: kết quả dùng lại phân cấp sản phẩm + đơn vị; số lượng/lô nằm trong Key-value Row; màn kết thúc chỉ còn thao tác thoát an toàn.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-08-STATE"
      ],
      "components": [
        "VPageScaffold",
        "VAppBar",
        "VSection",
        "VText",
        "VEmptyState",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VBadge",
        "VBanner",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Result finality -> factual context -> Product/UOM group header + grouped allocation evidence -> safe queue exit",
      "uifs": [
        "UIF-07",
        "UIF-09",
        "UIF-10"
      ],
      "mode": {
        "modes": {
          "UIF-07": "RTV_RESULT",
          "UIF-09": "STATE_RESULT",
          "UIF-10": "DISPOSAL_RESULT"
        },
        "note": "One result layout with operation_type-specific summary/copy."
      },
      "dataRows": [
        {
          "label": "Operation",
          "example": "IO-260817-088",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Action",
          "example": "Chuyển trạng thái",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tác động vật lý",
          "example": "Không đổi",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-042",
      "short": "042",
      "name": "Kiểm kê kho",
      "surface": "list",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-01"
      ],
      "purpose": "Browse/start/resume stock-count task; cancellation is not a list action.",
      "actors": [
        "Stock-count maker"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "CNT-260817-01",
          "Toàn kho · 82 dòng",
          "Đang đếm"
        ],
        [
          "CNT-260810-02",
          "Nhóm vaccine",
          "Chờ duyệt"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VButton",
        "VEmptyState"
      ],
      "themeComposition": "Mobile / Nested List + Search & Filter + State Patterns",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "CNT-260817-01",
          "example": "Toàn kho · 82 dòng · Đang đếm",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "CNT-260810-02",
          "example": "Nhóm vaccine · Chờ duyệt",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-043",
      "short": "043",
      "name": "Tạo phiên kiểm kê",
      "surface": "form",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-01"
      ],
      "purpose": "Choose frozen scope/reason; server owns atomic barrier then cut-off/book snapshot. Warehouse/cut-off/counter are read-only context.",
      "actors": [
        "Stock-count opener"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "COUNT_SCOPE_HAS_UNRESOLVED_VALUATION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Phạm vi",
          "Toàn kho / Sản phẩm / Nhóm / Lô"
        ],
        [
          "Kho",
          "Kho trung tâm · read-only"
        ],
        [
          "Thời điểm chốt",
          "Khi mở phiên · read-only"
        ],
        [
          "Lý do kiểm kê",
          "Kiểm kê định kỳ"
        ],
        [
          "Người đếm",
          "Nguyễn An · read-only"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-09-OPEN",
          "label": "Mở phiên kiểm kê",
          "bc": "BC-IC-01",
          "api": "API-C-14",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSelect",
        "DS v2 / Select Sheet",
        "DS v2 / List Row",
        "VTextField",
        "DS v2 / Info Row",
        "VBanner",
        "VButton",
        "DS v2 / Confirmation Sheet"
      ],
      "themeComposition": "Mobile / Form + Search & Select + Sticky Footer + Confirmation Sheet",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Phạm vi",
          "example": "Toàn kho",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Requested cut-off",
          "example": "09/09/2026 · 08:00",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Lý do kiểm kê",
          "example": "Kiểm kê định kỳ",
          "ownership": "USER_INPUT_SERVER_VALIDATED_SOURCE_MODEL_BACKPORT_RECOMMENDED"
        },
        {
          "label": "Người đếm được phân công",
          "example": "Nguyễn An",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY_SOURCE_MODEL_GAP"
        }
      ]
    },
    {
      "id": "SCR-044",
      "short": "044",
      "name": "Đếm mù",
      "surface": "form",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-02",
        "UC-08-05"
      ],
      "purpose": "True blind FIRST count using Product + physical stock state + LOT/non-LOT + base UOM. Unexpected physical keys require complete identity; counter never enters surplus price.",
      "actors": [
        "Assigned counter"
      ],
      "states": [
        "BLIND_COUNT",
        "VALIDATION_ERROR",
        "LOCK_LOST",
        "CONFLICT",
        "PERMISSION_DENIED"
      ],
      "defaultState": "BLIND_COUNT",
      "fields": [
        [
          "Amox 500 · L2407-A",
          "Physical count only"
        ],
        [
          "Găng tay M · L2405-M",
          "Physical count only"
        ],
        [
          "Unexpected key inside scope",
          "Optional physical observation"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-09-SUBMIT",
          "label": "Nộp kết quả đếm",
          "bc": "BC-IC-02",
          "api": "API-C-15",
          "tone": "primary"
        },
        {
          "id": "ACT-09-CANCEL",
          "label": "Hủy phiên",
          "bc": "BC-IC-08",
          "api": "API-C-27",
          "tone": "danger"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VNumericKeypadSheet",
        "DS v2 / Select Sheet",
        "DS v2 / List Row",
        "VBadge",
        "VBanner",
        "VButton",
        "DS v2 / Confirmation Sheet"
      ],
      "themeComposition": "Mobile / Form + Blind-count composition + VNumericKeypadSheet",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "PhysicalCountKey",
          "example": "Amox 500 · Bán được · L2407-A · hộp",
          "ownership": "SERVER_SCOPE_IDENTITY_USER_QUANTITY"
        },
        {
          "label": "Unexpected physical key",
          "example": "Product hiện có + state + tracking + base quantity",
          "ownership": "USER_OBSERVED_SERVER_VALIDATED"
        }
      ]
    },
    {
      "id": "SCR-045",
      "short": "045",
      "name": "Chênh lệch và đếm lại",
      "surface": "form",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-03",
        "UC-08-05"
      ],
      "purpose": "Immutable recount rounds for discrepant physical keys. Server-authoritative surplus value-basis status; zero variance completes without approval.",
      "actors": [
        "Assigned counter"
      ],
      "states": [
        "RECOUNT_REQUIRED",
        "READY",
        "PRICE_BASIS_REQUIRED",
        "VALIDATION_ERROR",
        "LOCK_LOST",
        "PERMISSION_DENIED"
      ],
      "defaultState": "RECOUNT_REQUIRED",
      "fields": [],
      "cards": [
        [
          "Amox 500",
          "Sổ 42 · Đếm 40",
          "Lệch −2"
        ],
        [
          "Găng tay M",
          "Sổ 20 · Đếm 21",
          "Lệch +1"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-09-SUBMIT",
          "label": "Gửi kết quả đếm lại",
          "bc": "BC-IC-02",
          "api": "API-C-15",
          "tone": "primary"
        },
        {
          "id": "ACT-09-CANCEL",
          "label": "Hủy phiên",
          "bc": "BC-IC-08",
          "api": "API-C-27",
          "tone": "danger"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "DS v2 / Info Row",
        "VNumericKeypadSheet",
        "VTextarea",
        "VBanner",
        "VButton",
        "DS v2 / Confirmation Sheet"
      ],
      "themeComposition": "Mobile / Form + discrepancy groups + State Patterns + Sticky Footer",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Amox 500",
          "example": "Sổ 42 · Đếm 40 · Lệch −2",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Găng tay M",
          "example": "Sổ 20 · Đếm 21 · Lệch +1",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-046",
      "short": "046",
      "name": "Duyệt điều chỉnh",
      "surface": "review",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-04"
      ],
      "purpose": "Independent read-only approval for current non-zero variance snapshot. Contributors cannot approve; stale value/risk basis blocks commit.",
      "actors": [
        "Eligible independent approver"
      ],
      "states": [
        "READY",
        "PENDING_APPROVAL",
        "SELF_APPROVAL_NOT_ALLOWED",
        "COUNT_APPROVAL_SNAPSHOT_STALE",
        "APPROVAL_ALREADY_DECIDED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Tổng dòng lệch",
          "2/82 dòng",
          "3 đơn vị"
        ],
        [
          "Giá trị rủi ro",
          "Có quyền mới thấy",
          "***"
        ]
      ],
      "notice": "",
      "sensitive": "Giá trị rủi ro thuộc FINANCIAL_RESTRICTED. Dữ liệu không được phép phải bị omit/mask trước response; không render số thật rồi ẩn bằng CSS.",
      "actions": [
        {
          "id": "ACT-09-APPROVE",
          "label": "Duyệt / Yêu cầu xem lại",
          "bc": "BC-IC-03",
          "api": "API-C-16",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "DS v2 / Info Row",
        "VBanner",
        "VButton",
        "DS v2 / Confirmation Sheet"
      ],
      "themeComposition": "Mobile / Detail + read-only evidence + dual decision footer",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Tổng dòng lệch",
          "example": "2 dòng",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Giá trị rủi ro",
          "example": "Provided only when authorized",
          "ownership": "SERVER_AUTHORITATIVE_FINANCIAL_RESTRICTED"
        }
      ]
    },
    {
      "id": "SCR-047",
      "short": "047",
      "name": "Kết quả kiểm kê",
      "surface": "result",
      "bj": [
        "BJ-08"
      ],
      "uc": [
        "UC-08-02",
        "UC-08-03",
        "UC-08-04",
        "UC-08-05"
      ],
      "purpose": "Authoritative finality for zero-variance completion, adjusted completion, cancellation, rejected execution or UNKNOWN handoff.",
      "actors": [
        "Stock-count participant"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "CANCELLED",
        "REJECTED_EXECUTION",
        "UNKNOWN",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Phiên",
          "CNT-260817-01"
        ],
        [
          "Adjustment",
          "ADJ-260817-01"
        ],
        [
          "Khóa phạm vi",
          "Đã mở"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VLoading",
        "VEmptyState",
        "DS v2 / Info Row",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Mobile / Detail + Result content + State Patterns",
      "uifs": [
        "UIF-08"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Phiên",
          "example": "KK-1709-01",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Kết quả",
          "example": "Không điều chỉnh / ADJ-1709-08",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Khóa phạm vi",
          "example": "Đã mở",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ],
      "migrationNote": "Core v4.3.1 trace ACT-09-APPROVE -> SCR-047 is stale for Product rendering and is superseded by BJ08-MIGRATION-CONTRACT-v2.3.0.md."
    },
    {
      "id": "SCR-048",
      "short": "048",
      "name": "Hủy & sửa sai",
      "surface": "list",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-01"
      ],
      "purpose": "Tìm phiếu kho sai theo mã phiếu hoặc sản phẩm; biết ngay hủy được, sửa được hay đang chờ.",
      "actors": [
        "Người phụ trách kho",
        "Người có quyền xem"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "IO-260906-022",
          "Thay đổi tình trạng hàng · Có thể hủy",
          "12 hộp"
        ],
        [
          "IO-260901-014",
          "Nhận hàng · Có thể sửa",
          "120 hộp"
        ],
        [
          "IO-260906-031",
          "Tiêu hủy · Đang xác minh",
          "5 hộp"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VChip",
        "VCard",
        "VBadge",
        "VText",
        "VIcon",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ControlWorklist",
      "uifs": [
        "UIF-11"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "IO-260906-022",
          "example": "Thay đổi tình trạng hàng · Có thể hủy · 12 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "IO-260901-014",
          "example": "Nhận hàng · Có thể sửa · 120 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "IO-260906-031",
          "example": "Tiêu hủy · Đang xác minh · 5 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-049",
      "short": "049",
      "name": "Chi tiết phiếu kho",
      "surface": "timeline",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-01",
        "UC-11-03",
        "UC-11-05"
      ],
      "purpose": "Hiểu tác động, trạng thái hiện hành và hành động kiểm soát hợp lệ mà không lộ metadata kỹ thuật.",
      "actors": [
        "Người phụ trách kho",
        "Người có quyền xem"
      ],
      "states": [
        "READY",
        "LOADING",
        "PERMISSION_DENIED",
        "UNKNOWN",
        "CANCELABLE",
        "CORRECTABLE",
        "BLOCKED_PHYSICAL_HANDOVER",
        "TERMINAL",
        "PENDING_APPROVAL"
      ],
      "defaultState": "CORRECTABLE",
      "fields": [],
      "cards": [
        [
          "Nghiệp vụ",
          "Nhận hàng · PN-260901-07",
          "Hoàn tất"
        ],
        [
          "Tác động",
          "Nobivac DHPPi · 120 hộp",
          "Kho trung tâm"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VIcon",
        "VSkeleton"
      ],
      "themeComposition": "Theme7OperationControlDetail",
      "uifs": [
        "UIF-11"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nghiệp vụ",
          "example": "Nhận hàng · PN-260901-07 · Hoàn tất",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Tác động",
          "example": "Nobivac DHPPi · 120 hộp · Kho trung tâm",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-050",
      "short": "050",
      "name": "Sửa sai",
      "surface": "form",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-03",
        "UC-11-04"
      ],
      "purpose": "Một màn: chọn cách sửa, nhập số đúng và lý do; thấy tồn (và tiền với chủ cửa hàng) sau khi sửa.",
      "actors": [
        "Người lập sửa sai"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "PERMISSION_DENIED",
        "SOURCE_VERSION_STALE",
        "DEPENDENCY_BLOCKED",
        "PERIOD_POLICY_VIOLATION"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Số gốc",
          "120 hộp"
        ],
        [
          "Số đúng",
          "118 hộp"
        ],
        [
          "Điều chỉnh",
          "−2 hộp"
        ],
        [
          "Lý do",
          "Ghi nhận thừa 2 hộp"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-10-SUBMIT",
          "label": "Gửi phê duyệt",
          "bc": "BC-IC-07",
          "api": "API-C-26",
          "tone": "primary"
        }
      ],
      "traceActions": [
        "ACT-10-SAVE-DRAFT"
      ],
      "components": [
        "VSection",
        "VCard",
        "VNumberField",
        "VTextField",
        "VText",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7CorrectionEditor",
      "uifs": [
        "UIF-11"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Số gốc",
          "example": "120 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Số đúng",
          "example": "118 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Điều chỉnh",
          "example": "−2 hộp",
          "ownership": "DERIVED_READ_ONLY"
        },
        {
          "label": "Lý do",
          "example": "Ghi nhận thừa 2 hộp",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        }
      ]
    },
    {
      "id": "SCR-051",
      "short": "051",
      "name": "Duyệt sửa sai",
      "surface": "review",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-04"
      ],
      "purpose": "Người duyệt độc lập xem before/after, lý do và tác động trước khi quyết định.",
      "actors": [
        "Người phê duyệt độc lập"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "PERMISSION_DENIED",
        "SELF_APPROVAL_NOT_ALLOWED",
        "APPROVAL_ALREADY_DECIDED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Trước",
          "120 hộp",
          "Theo nghiệp vụ gốc"
        ],
        [
          "Sau",
          "118 hộp",
          "Điều chỉnh −2 hộp"
        ],
        [
          "Người lập",
          "Nguyễn An",
          "Không được tự duyệt"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-10-DECIDE",
          "label": "Duyệt / Từ chối",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VBottomSheet"
      ],
      "themeComposition": "Theme7IndependentApprovalReview",
      "uifs": [
        "UIF-11"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Trước",
          "example": "120 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Sau",
          "example": "118 hộp · Điều chỉnh −2 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Người lập",
          "example": "Nguyễn An · không được tự duyệt",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-052",
      "short": "052",
      "name": "Hủy hoặc chọn cách sửa (đã gộp vào SCR-050 và SCR-049)",
      "surface": "form",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-02",
        "UC-11-03"
      ],
      "purpose": "Đã gộp từ v5.17.0: chọn cách sửa và nhập số đúng nằm ở SCR-050; hủy yêu cầu là sheet có lý do ở SCR-049. Link cũ mở màn sửa sai.",
      "actors": [
        "Người phụ trách kho"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [
        [
          "Operation gốc",
          "IO-260901-014"
        ],
        [
          "Cách sửa",
          "Sửa phần sai"
        ],
        [
          "Lý do",
          "Sai lượng nhận"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-10-CORRECT"
      ],
      "components": [
        "VSection",
        "VCard",
        "VRadio",
        "VTextField",
        "VText",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7CorrectionRoute",
      "uifs": [],
      "mode": {
        "modes": {
          "CANCEL_UNEXECUTED": "CANCEL_CONFIRMATION",
          "CORRECTION_ROUTE": "CORRECTION_STRATEGY"
        },
        "note": "Hai task loại trừ nhau; route authoritative quyết định mode."
      },
      "dataRows": [
        {
          "label": "Operation gốc",
          "example": "IO-260901-014",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Cách sửa",
          "example": "Sửa phần sai",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Lý do",
          "example": "Sai lượng nhận",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        }
      ],
      "prototype_status": "RETIRED_v5.17.0"
    },
    {
      "id": "SCR-053",
      "short": "053",
      "name": "Kết quả sửa sai",
      "surface": "result",
      "bj": [
        "BJ-11"
      ],
      "uc": [
        "UC-11-02",
        "UC-11-04",
        "UC-11-05"
      ],
      "purpose": "Hiển thị authoritative result cho cancel/correction/approval; UNKNOWN giữ cùng operation identity và bàn giao BJ-17.",
      "actors": [
        "Người lập sửa sai",
        "Người phê duyệt độc lập",
        "Người có quyền xem"
      ],
      "states": [
        "PROCESSING",
        "PENDING_APPROVAL",
        "CANCELLED",
        "COMPLETED",
        "REJECTED",
        "UNKNOWN",
        "BLOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "PENDING_APPROVAL",
      "fields": [
        [
          "Nghiệp vụ gốc",
          "IO-260901-014"
        ],
        [
          "Kết quả",
          "Chờ duyệt"
        ],
        [
          "Tác động tồn kho",
          "Chưa thay đổi"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-10-CORRECT"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-11"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Nghiệp vụ gốc",
          "example": "IO-260901-014",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Kết quả",
          "example": "Chờ duyệt / Hoàn tất / Từ chối / Chưa xác định",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tác động tồn kho",
          "example": "Theo authoritative finality",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-054",
      "short": "054",
      "name": "Tra cứu thẻ kho (đã bỏ — mọi lối vào mở thẳng SCR-055)",
      "surface": "form",
      "bj": [
        "BJ-01",
        "BJ-15"
      ],
      "uc": [
        "UC-01-01",
        "UC-15-01"
      ],
      "purpose": "Đã bỏ từ v5.20.0: báo cáo và thẻ kho mở thẳng với kỳ mặc định; kỳ và cách hiểu ngày nằm ở thanh lọc SCR-055. Link cũ mở SCR-055.",
      "actors": [
        "Thủ kho",
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã bỏ từ v5.20.0: báo cáo và thẻ kho mở thẳng với kỳ mặc định; kỳ và cách hiểu ngày nằm ở thanh lọc SCR-055. Link cũ mở SCR-055.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VTextFormField",
        "VNumberField",
        "VMoneyField",
        "VSelect",
        "VCombobox",
        "VDatePicker",
        "VQuantitySelector",
        "VFileDropZone",
        "VButton",
        "VBanner"
      ],
      "themeComposition": "Theme7FormSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v5.20.0"
    },
    {
      "id": "SCR-055",
      "short": "055",
      "name": "Báo cáo nhập – xuất – tồn / Thẻ kho",
      "surface": "list",
      "bj": [
        "BJ-15",
        "BJ-01"
      ],
      "uc": [
        "UC-15-02",
        "UC-15-03",
        "UC-01-03"
      ],
      "purpose": "Hai chế độ của một màn: báo cáo nhập – xuất – tồn theo kỳ (đầu kỳ, nhập, xuất, cuối kỳ, giá trị cuối kỳ cho chủ) và thẻ kho một sản phẩm (từng biến động, tồn sau mỗi dòng, lọc theo lô). Thanh lọc: kỳ, ngày nghiệp vụ / ngày ghi nhận, mốc dữ liệu.",
      "actors": [
        "Chủ cửa hàng",
        "Thủ kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED",
        "RECORDED_DATE_VIEW",
        "BUSINESS_DATE_VIEW",
        "ARCHIVED_DATA",
        "STALE",
        "FINANCIAL_RESTRICTED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Báo cáo nhập – xuất – tồn",
          "Đầu kỳ · Nhập · Xuất · Cuối kỳ",
          "Tháng 09/2026"
        ],
        [
          "Thẻ kho",
          "Nhận hàng PN-260904-08",
          "+20"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VCard",
        "VCardIcon",
        "VCardTitle",
        "VBadge",
        "VText",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-01",
        "UIF-15"
      ],
      "mode": {
        "modes": {
          "UIF-01": "STOCK_CARD_RESULTS",
          "UIF-15": [
            "INVENTORY_REPORT_RESULT",
            "STOCK_CARD_RESULTS"
          ]
        },
        "note": "UIF15 mode switches report/list behavior without cloning shared screen."
      },
      "dataRows": [
        {
          "label": "Cuối kỳ",
          "example": "120 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Giá trị cuối kỳ",
          "example": "chỉ chủ cửa hàng",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-056",
      "short": "056",
      "name": "Chi tiết movement",
      "surface": "detail",
      "bj": [
        "BJ-01",
        "BJ-09",
        "BJ-15"
      ],
      "uc": [
        "UC-01-03",
        "UC-09-04",
        "UC-15-03"
      ],
      "purpose": "Xem operation, actor, source/version và trước/sau.",
      "actors": [
        "Thủ kho",
        "Kế toán"
      ],
      "states": [
        "READY",
        "LOADING",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED",
        "FINANCIAL_RESTRICTED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Movement",
          "MOV-260817-002"
        ],
        [
          "Operation",
          "IO-260817-002"
        ],
        [
          "Delta",
          "+118 hộp"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VSkeleton"
      ],
      "themeComposition": "Theme7DetailSurface",
      "uifs": [
        "UIF-01",
        "UIF-09",
        "UIF-15"
      ],
      "mode": {
        "modes": {
          "UIF-01": "MOVEMENT_DETAIL",
          "UIF-09": "MOVEMENT_DETAIL",
          "UIF-15": "MOVEMENT_DETAIL_BUSINESS"
        },
        "note": "UIF15 prioritizes business source + before/delta/after; technical IDs stay Inspect/audit."
      },
      "dataRows": [
        {
          "label": "Movement",
          "example": "MOV-260817-002",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Operation",
          "example": "IO-260817-002",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Delta",
          "example": "+118 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-057",
      "short": "057",
      "name": "Dòng thời gian nguồn (đã gộp vào SCR-056)",
      "surface": "timeline",
      "bj": [
        "BJ-01",
        "BJ-15"
      ],
      "uc": [
        "UC-01-03",
        "UC-15-03"
      ],
      "purpose": "Đã gộp từ v5.20.0: khối \"Nguồn\" của SCR-056 (dòng thời gian ba bước). Link cũ mở SCR-056.",
      "actors": [
        "Thủ kho",
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã gộp từ v5.20.0: khối \"Nguồn\" của SCR-056 (dòng thời gian ba bước). Link cũ mở SCR-056.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VCard",
        "VIconBox",
        "VText",
        "VBadge",
        "VBanner",
        "VSkeleton"
      ],
      "themeComposition": "Theme7EvidenceTimeline",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v5.20.0"
    },
    {
      "id": "SCR-058",
      "short": "058",
      "name": "Xuất báo cáo (đã gộp vào sheet ở SCR-055)",
      "surface": "review",
      "bj": [
        "BJ-15"
      ],
      "uc": [
        "UC-15-04"
      ],
      "purpose": "Đã gộp từ v5.20.0: sheet \"Xuất báo cáo\" ở SCR-055. Link cũ mở SCR-055 kèm sheet.",
      "actors": [
        "Thủ kho",
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã gộp từ v5.20.0: sheet \"Xuất báo cáo\" ở SCR-055. Link cũ mở SCR-055 kèm sheet.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VLoading"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v5.20.0"
    },
    {
      "id": "SCR-059",
      "short": "059",
      "name": "Kết quả xuất báo cáo",
      "surface": "result",
      "bj": [
        "BJ-15"
      ],
      "uc": [
        "UC-15-04"
      ],
      "purpose": "Biết file đã sẵn sàng và phạm vi/as-of nào đã được xuất.",
      "actors": [
        "Thủ kho",
        "Kế toán"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "REJECTED_EXECUTION",
        "SOURCE_STALE",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Tệp",
          "bao-cao-nhap-xuat-ton-092026.csv"
        ],
        [
          "Số liệu đến",
          "17/09/2026 · 21:30"
        ],
        [
          "Giá trị tài chính",
          "Có"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-11-EXPORT"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-15"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Tệp",
          "example": "bao-cao-nhap-xuat-ton-092026.csv",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Số liệu đến",
          "example": "17/09/2026 · 21:30",
          "ownership": "SYSTEM_DERIVED_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-060",
      "short": "060",
      "name": "Chỉ báo tồn kho",
      "surface": "dashboard",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-04",
        "UC-01-05"
      ],
      "purpose": "Xem hàng hết, thấp, bình thường và cận hạn.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "STALE",
        "PERMISSION_DENIED",
        "OUT_OF_STOCK",
        "LOW_STOCK",
        "NORMAL",
        "NEAR_EXPIRY_WARN",
        "NEAR_EXPIRY_BLOCKED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Hết hàng",
          "Cần xem xét",
          "3"
        ],
        [
          "Tồn thấp",
          "Dưới ngưỡng",
          "12"
        ],
        [
          "Cận hạn",
          "Trong 90 ngày",
          "4"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VCard",
        "VIconBox",
        "VText",
        "VBadge",
        "VBanner",
        "VSkeleton"
      ],
      "themeComposition": "Theme7DashboardSurface",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Hết hàng",
          "example": "Cần xem xét · 3",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Tồn thấp",
          "example": "Dưới ngưỡng · 12",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Cận hạn",
          "example": "Trong 90 ngày · 4",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-061",
      "short": "061",
      "name": "Chi tiết chỉ báo sản phẩm",
      "surface": "detail",
      "bj": [
        "BJ-01"
      ],
      "uc": [
        "UC-01-04",
        "UC-01-05"
      ],
      "purpose": "Phân biệt available, threshold, target và lượng gợi ý.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "LOADING",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED",
        "NOT_CONFIGURED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Khả dụng",
          "42 hộp"
        ],
        [
          "Ngưỡng cảnh báo",
          "50 hộp"
        ],
        [
          "Mức tồn mục tiêu",
          "80 hộp"
        ],
        [
          "Lượng gợi ý",
          "38 hộp"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-12-REFRESH",
          "label": "Tính lại gợi ý",
          "bc": "BC-IO-14",
          "api": "API-Q-02",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VSkeleton"
      ],
      "themeComposition": "Theme7DetailSurface",
      "uifs": [
        "UIF-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Khả dụng",
          "example": "42 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Ngưỡng cảnh báo",
          "example": "50 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Mức tồn mục tiêu",
          "example": "80 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Lượng gợi ý",
          "example": "38 hộp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-066",
      "short": "066",
      "name": "Khởi tạo tồn kho",
      "surface": "status / entry",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-01"
      ],
      "purpose": "Biết tồn kho đã được khởi tạo tới đâu và thực hiện đúng bước tiếp theo.",
      "actors": [
        "Người chuẩn bị số dư",
        "Người có quyền xem trạng thái"
      ],
      "states": [
        "READY",
        "LOADING",
        "PERMISSION_DENIED",
        "PREPARING",
        "PENDING_APPROVAL",
        "REJECTED",
        "UNKNOWN",
        "ACTIVE_RECONCILED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Trạng thái",
          "Chưa thiết lập",
          "Bắt đầu khi sẵn sàng"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VBadge",
        "VText",
        "VBanner",
        "VButton",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7StatusEntrySurface",
      "uifs": [
        "UIF-12"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Trạng thái khởi tạo",
          "example": "Chưa thiết lập",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-067",
      "short": "067",
      "name": "Dữ liệu tồn kho đầu kỳ",
      "surface": "form",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-01"
      ],
      "purpose": "Chọn tệp, ngày chốt số dư và các số kiểm soát độc lập.",
      "actors": [
        "Người chuẩn bị số dư"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Tệp dữ liệu",
          "opening-balance.xlsx"
        ],
        [
          "Ngày chốt số dư",
          "31/08/2026"
        ],
        [
          "Tổng số lượng kiểm soát",
          "4.820"
        ],
        [
          "Tổng giá trị kiểm soát",
          "386.240.000 ₫"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-13-PREPARE",
          "label": "Kiểm tra dữ liệu",
          "bc": "BC-IC-09",
          "api": "API-C-28",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VFileDropZone",
        "VDatePicker",
        "VNumberField",
        "VMoneyField",
        "VText",
        "VButton",
        "VBanner"
      ],
      "themeComposition": "Theme7FormSurface",
      "uifs": [
        "UIF-12"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Tệp dữ liệu",
          "example": "opening-balance.xlsx",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Ngày chốt số dư",
          "example": "31/08/2026",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Tổng số lượng kiểm soát",
          "example": "4.820",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Tổng giá trị kiểm soát",
          "example": "386.240.000 ₫",
          "ownership": "USER_INPUT_SERVER_VALIDATED_PERMISSION_GATED"
        }
      ]
    },
    {
      "id": "SCR-068",
      "short": "068",
      "name": "Kết quả kiểm tra dữ liệu",
      "surface": "validation result",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-01"
      ],
      "purpose": "Biết dữ liệu đã đủ điều kiện chưa và thấy đúng lỗi cần sửa ở nguồn.",
      "actors": [
        "Người chuẩn bị số dư"
      ],
      "states": [
        "READY",
        "LOADING",
        "CONFLICT",
        "PERMISSION_DENIED",
        "VALIDATION_FAILED",
        "CONTROL_TOTAL_MISMATCH"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Dòng hợp lệ",
          "82/82",
          "Đạt"
        ],
        [
          "Số kiểm soát",
          "Khớp",
          "Đạt"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7FileImportValidation",
      "uifs": [
        "UIF-12"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Dòng hợp lệ",
          "example": "82/82",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Số kiểm soát",
          "example": "Khớp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-069",
      "short": "069",
      "name": "Rà soát số dư đầu kỳ",
      "surface": "review",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-02"
      ],
      "purpose": "Kiểm lại business facts trước khi gửi người duyệt.",
      "actors": [
        "Người chuẩn bị số dư"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "PERMISSION_DENIED",
        "PENDING_APPROVAL"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Ngày chốt",
          "31/08/2026",
          ""
        ],
        [
          "Sản phẩm",
          "36",
          ""
        ],
        [
          "Số kiểm soát",
          "Khớp",
          "Đạt"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-13-PREPARE",
          "label": "Gửi phê duyệt",
          "bc": "BC-IC-09",
          "api": "API-C-28",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VConfirmDialog",
        "VBottomSheet"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-12"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Ngày chốt",
          "example": "31/08/2026",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Số kiểm soát",
          "example": "Khớp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-070",
      "short": "070",
      "name": "Duyệt số dư đầu kỳ",
      "surface": "approval review",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-02",
        "UC-12-03"
      ],
      "purpose": "Người duyệt độc lập quyết định Duyệt/Từ chối trên business evidence; system commit sau approval.",
      "actors": [
        "Người phê duyệt độc lập"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "PERMISSION_DENIED",
        "SELF_APPROVAL_NOT_ALLOWED",
        "APPROVAL_ALREADY_DECIDED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Người lập",
          "Nguyễn An"
        ],
        [
          "Ngày chốt",
          "31/08/2026"
        ],
        [
          "Tổng giá trị",
          "386.240.000 ₫"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-COMMON-DECIDE",
          "label": "Quyết định phê duyệt",
          "bc": "BC-IC-06",
          "api": "API-C-19",
          "tone": "primary"
        }
      ],
      "traceActions": [
        "ACT-13-COMMIT"
      ],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VBottomSheet",
        "VTextField"
      ],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [
        "UIF-12"
      ],
      "mode": {
        "modes": {
          "UIF-12": "APPROVAL_ONLY"
        },
        "note": "Approver task is independent; commit is system-owned after approval."
      },
      "dataRows": [
        {
          "label": "Người lập",
          "example": "Nguyễn An",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Ngày chốt",
          "example": "31/08/2026",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tổng giá trị",
          "example": "386.240.000 ₫",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY_PERMISSION_GATED"
        }
      ]
    },
    {
      "id": "SCR-071",
      "short": "071",
      "name": "Kết quả khởi tạo tồn kho",
      "surface": "result",
      "bj": [
        "BJ-12"
      ],
      "uc": [
        "UC-12-03"
      ],
      "purpose": "Biết tồn kho đã được kích hoạt hay chưa và tác động thực tế là gì.",
      "actors": [
        "Người chuẩn bị số dư",
        "Người phê duyệt"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED",
        "COMMIT_UNKNOWN",
        "ACTIVE_RECONCILED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Ngày chốt",
          "31/08/2026"
        ],
        [
          "Sản phẩm",
          "36"
        ],
        [
          "Đối soát",
          "Đã khớp"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-13-COMMIT"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-12"
      ],
      "mode": {
        "modes": {
          "UIF-12": "AUTO_COMMIT_RESULT"
        },
        "note": "Processing/result owns commit finality; no user commit CTA."
      },
      "dataRows": [
        {
          "label": "Ngày chốt",
          "example": "31/08/2026",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Sản phẩm",
          "example": "36",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Đối soát",
          "example": "Đã khớp",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-072",
      "short": "072",
      "name": "Giá vốn",
      "surface": "list",
      "bj": [
        "BJ-14"
      ],
      "uc": [
        "UC-14-01",
        "UC-14-04"
      ],
      "purpose": "Giá vốn theo K6: chip \"Cần làm\" / \"Đã công bố\"; mỗi dòng là một lần tính (chốt kỳ hoặc cập nhật trong kỳ) và mở đúng bước của lần tính đó.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "NEEDS_PERIOD_CLOSE",
        "LOADING",
        "EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VSkeleton",
        "VEmptyState",
        "VButton"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-14"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Cập nhật giá vốn",
          "example": "3 sản phẩm có thay đổi giá trị",
          "ownership": "SERVER_DERIVED_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Chốt giá vốn tháng 09/2026",
          "example": "Sẵn sàng thực hiện",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Công việc bị chặn",
          "example": "2 mặt hàng chưa hoàn tất xác lập giá trị",
          "ownership": "SERVER_DERIVED_LIST_OR_SUMMARY_ITEM"
        }
      ],
      "prototype_status": "DESIGN_PARITY_v3.13.0",
      "notes": "BJ14 v3.9.9: dirty Product+posting-period worklist; exact cause/version is contract-only."
    },
    {
      "id": "SCR-073",
      "short": "073",
      "name": "Thiết lập lần tính — Đã hợp nhất",
      "surface": "form",
      "bj": [
        "BJ-14"
      ],
      "uc": [],
      "purpose": "Retired in v3.13.0; route redirects to SCR-074.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-074; không còn là màn hình active.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7FormSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0",
      "notes": "BJ14 v3.9.9: calculation/posting period separated; dirty scope read-only."
    },
    {
      "id": "SCR-074",
      "short": "074",
      "name": "Giá vốn theo kỳ",
      "surface": "dashboard",
      "bj": [
        "BJ-14"
      ],
      "uc": [
        "UC-14-01",
        "UC-14-04"
      ],
      "purpose": "Một màn cho mọi trạng thái của lần tính, khối theo thứ tự: việc chặn → kết quả → thay đổi sẽ ghi → theo sản phẩm → phương pháp. Việc chặn đọc từ BJ-03 / BJ-11 / BJ-16 và có nút sang nơi xử lý.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "NOT_CALCULATED",
        "BLOCKED",
        "CALCULATING",
        "READY_FOR_REVIEW",
        "INPUT_CHANGED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY_FOR_REVIEW",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Toàn bộ kết quả giá trị chỉ render cho quyền tài chính.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VAppBar",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "DS v2 / List Row",
        "DS v2 / Summary Card",
        "VBanner",
        "VSelect",
        "DS v2 / Confirmation Sheet",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Theme7DashboardSurface",
      "uifs": [
        "UIF-14"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Phương pháp áp dụng",
          "example": "Bình quân cuối kỳ · Theo chính sách của tổ chức",
          "ownership": "TENANT_POLICY_READ_ONLY"
        },
        {
          "label": "Phạm vi cần cập nhật",
          "example": "3 sản phẩm · Hệ thống xác định",
          "ownership": "SERVER_DERIVED_READ_ONLY"
        },
        {
          "label": "Kết quả theo phương pháp áp dụng",
          "example": "Tồn cuối kỳ 431,2 triệu",
          "ownership": "SERVER_AUTHORITATIVE_PREVIEW"
        },
        {
          "label": "Đối chiếu",
          "example": "Bình quân liên hoàn · xem khi cần",
          "ownership": "SERVER_DERIVED_COMPARISON_ONLY"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0",
      "notes": "BJ14 v3.9.9: ProductCostResult aggregate + incremental deltas."
    },
    {
      "id": "SCR-075",
      "short": "075",
      "name": "Blocker và adjustment — Đã hợp nhất",
      "surface": "detail",
      "bj": [
        "BJ-14"
      ],
      "uc": [],
      "purpose": "Retired in v3.13.0; route redirects to SCR-074.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-074; không còn là màn hình active.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7DetailSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0"
    },
    {
      "id": "SCR-076",
      "short": "076",
      "name": "Rà soát công bố — Đã hợp nhất",
      "surface": "review",
      "bj": [
        "BJ-14"
      ],
      "uc": [],
      "purpose": "Retired in v3.13.0; route redirects to SCR-074.",
      "actors": [
        "Kế toán"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-074; không còn là màn hình active.",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0",
      "notes": "BJ14 v3.9.9: read-only review; publish finality only via ACT-14-PUBLISH."
    },
    {
      "id": "SCR-077",
      "short": "077",
      "name": "Kết quả công bố giá vốn",
      "surface": "result",
      "bj": [
        "BJ-14"
      ],
      "uc": [
        "UC-14-04"
      ],
      "purpose": "Kết quả publication: kỳ, phương pháp, số sản phẩm, hiệu lực và đúng hai signed delta đã ghi.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "COMPLETED",
        "REJECTED_EXECUTION",
        "UNKNOWN",
        "PROCESSING",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Kỳ ghi nhận",
          "Kỳ publication"
        ],
        [
          "Phương pháp",
          "Theo tenant policy"
        ],
        [
          "Sản phẩm đã đối soát",
          "Số Product trong run"
        ],
        [
          "Sản phẩm có giá vốn mới",
          "Số OfficialCostVersion mới"
        ],
        [
          "Hiệu lực",
          "Thời điểm publication có hiệu lực"
        ],
        [
          "Điều chỉnh giá vốn xuất",
          "Signed COGS delta"
        ],
        [
          "Điều chỉnh giá trị tồn",
          "Signed ending inventory delta"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-14-PUBLISH"
      ],
      "components": [
        "VAppBar",
        "VEmptyState",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-14"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Kỳ",
          "example": "09/2026",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        },
        {
          "label": "Phương pháp",
          "example": "Bình quân cuối kỳ",
          "ownership": "TENANT_POLICY_READ_ONLY"
        },
        {
          "label": "Trạng thái",
          "example": "Đã công bố",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0",
      "notes": "v3.13.0: product copy hides Batch/Event/OfficialCostVersion; technical identity remains available in Inspect/audit."
    },
    {
      "id": "SCR-078",
      "short": "078",
      "name": "Hồ sơ cần kiểm tra",
      "surface": "list",
      "bj": [
        "BJ-16",
        "BJ-17"
      ],
      "uc": [
        "UC-16-01",
        "UC-17-01"
      ],
      "purpose": "Một danh sách chung cho hồ sơ sai lệch và thao tác chưa rõ kết quả; chip có số \"Tất cả · Sai lệch · Chưa rõ kết quả · Đang chờ\", mỗi dòng mở đúng hồ sơ.",
      "actors": [
        "Người phụ trách kiểm soát kho",
        "Người có quyền xem"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Số trên app lệch sổ kho",
          "Nobivac DHPPi · Lô DH2507 · REC-260907-03",
          "Cần làm"
        ],
        [
          "Phiếu nhận ghi khác hoá đơn",
          "Amox 500 · SP-000066 · REC-260907-04",
          "Cần làm"
        ],
        [
          "Tiêu hủy đã ghi vào kho",
          "Găng tay khám Nitrile · 5 hộp · REC-UNKNOWN-01",
          "Cần làm"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSearchBar",
        "VChip",
        "VCard",
        "VBadge",
        "VText",
        "VIcon",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ReconciliationWorklist",
      "uifs": [
        "UIF-16",
        "UIF-17"
      ],
      "mode": {
        "modes": {
          "UIF-16": "RECON_CASES",
          "UIF-17": "UNKNOWN_CASES"
        },
        "note": "Một danh sách; chip và ô tìm là trạng thái chung, lối vào quyết định chip (Home: Tất cả; Hub: Sai lệch)."
      },
      "dataRows": [
        {
          "label": "Số trên app lệch sổ kho",
          "example": "Nobivac DHPPi · Lô DH2507 · REC-260907-03 · Cần làm",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Tiêu hủy đã ghi vào kho",
          "example": "Găng tay khám Nitrile · 5 hộp · REC-UNKNOWN-01 · Cần làm",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-079",
      "short": "079",
      "name": "Bằng chứng & kết luận",
      "surface": "timeline",
      "bj": [
        "BJ-16",
        "BJ-17"
      ],
      "uc": [
        "UC-16-02",
        "UC-16-03",
        "UC-17-01",
        "UC-17-04"
      ],
      "purpose": "Nói bằng một câu hồ sơ này lệch gì, bao nhiêu, hàng nào đang tạm khoá và một việc tiếp theo; xác nhận bằng sheet ngay tại màn này.",
      "actors": [
        "Người phụ trách kiểm soát kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "PERMISSION_DENIED",
        "INSUFFICIENT_EVIDENCE",
        "SOURCE_MISMATCH",
        "PROJECTION_MISMATCH",
        "CORRECTION_REQUIRED",
        "UNKNOWN_EVIDENCE",
        "LEDGER_INTEGRITY_RISK",
        "NO_REAL_DIFFERENCE",
        "LOCKED",
        "CONFLICT"
      ],
      "defaultState": "PROJECTION_MISMATCH",
      "fields": [],
      "cards": [
        [
          "Phiếu gốc",
          "118 hộp",
          ""
        ],
        [
          "Sổ kho",
          "118 hộp",
          ""
        ],
        [
          "Số trên app",
          "116 hộp",
          "lệch −2 hộp"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton",
        "VSkeleton"
      ],
      "themeComposition": "Theme7EvidenceConclusion",
      "uifs": [
        "UIF-16",
        "UIF-17"
      ],
      "mode": {
        "modes": {
          "UIF-16": "INVESTIGATION_EVIDENCE",
          "UIF-17": "UNKNOWN_EVIDENCE"
        },
        "note": "Evidence is user-readable; technical identifiers remain Inspect/on-demand."
      },
      "dataRows": [
        {
          "label": "Kết luận",
          "example": "Số trên app lệch 2 hộp so với sổ kho. Sổ kho đúng; chỉ cần cập nhật số trên app.",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Phiếu gốc",
          "example": "118 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Sổ kho",
          "example": "118 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Số trên app",
          "example": "116 hộp · lệch −2 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-080",
      "short": "080",
      "name": "Phương án xử lý (đã gộp vào sheet xác nhận ở SCR-079)",
      "surface": "form",
      "bj": [
        "BJ-16",
        "BJ-17"
      ],
      "uc": [
        "UC-16-02",
        "UC-16-03",
        "UC-17-02",
        "UC-17-03"
      ],
      "purpose": "Đã gộp từ v5.18.0: xác nhận cập nhật số trên app / đóng hồ sơ / xác nhận đã hoàn tất / làm tiếp thao tác là sheet ở SCR-079. Link cũ mở bằng chứng của hồ sơ.",
      "actors": [
        "Người phụ trách kiểm soát kho"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7ControlledRecoveryPlan",
      "uifs": [],
      "mode": {
        "modes": {
          "UIF-16": "PROJECTION_RECOVERY",
          "UIF-17": "SAME_IDENTITY_FINALITY"
        },
        "note": "System recommends only a contract-valid path; no raw technical action selector."
      },
      "dataRows": [],
      "prototype_status": "RETIRED_v5.18.0"
    },
    {
      "id": "SCR-081",
      "short": "081",
      "name": "Đang cập nhật số trên app",
      "surface": "detail",
      "bj": [
        "BJ-16"
      ],
      "uc": [
        "UC-16-03"
      ],
      "purpose": "Báo đang cập nhật số trên app theo sổ kho; xong tự sang kiểm lại. Không thanh tiến độ giả.",
      "actors": [
        "Người phụ trách kiểm soát kho"
      ],
      "states": [
        "REBUILDING",
        "PERMISSION_DENIED",
        "CONFLICT",
        "VALIDATION_FAILED"
      ],
      "defaultState": "REBUILDING",
      "fields": [],
      "cards": [
        [
          "Phạm vi",
          "Nobivac DHPPi · Lô DH2507",
          "Đang cập nhật"
        ],
        [
          "Sổ kho",
          "Không thay đổi",
          ""
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VLoading"
      ],
      "themeComposition": "Theme7RecoveryProgress",
      "uifs": [
        "UIF-16"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Phạm vi",
          "example": "Nobivac DHPPi · Lô DH2507",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Sổ kho",
          "example": "Không thay đổi",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-082",
      "short": "082",
      "name": "Rà soát kết quả",
      "surface": "review",
      "bj": [
        "BJ-16",
        "BJ-17"
      ],
      "uc": [
        "UC-16-04",
        "UC-17-02",
        "UC-17-03"
      ],
      "purpose": "Kiểm lại số trên app đã khớp sổ kho chưa trước khi đóng hồ sơ và mở khoá.",
      "actors": [
        "Người phụ trách kiểm soát kho"
      ],
      "states": [
        "READY",
        "MISMATCH_REMAINS",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Sổ kho",
          "118 hộp",
          ""
        ],
        [
          "Số trên app",
          "118 hộp",
          "Đã khớp"
        ],
        [
          "Chênh lệch",
          "0 hộp",
          "Có thể đóng hồ sơ"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-15-RECONCILE",
          "label": "Đóng hồ sơ",
          "bc": "BC-IC-05",
          "api": "API-C-18",
          "tone": "primary"
        }
      ],
      "traceActions": [],
      "components": [
        "VSection",
        "VCard",
        "VText",
        "VBadge",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7ReconciliationReview",
      "uifs": [
        "UIF-16"
      ],
      "mode": {
        "modes": {
          "UIF-16": "RECON_REVIEW",
          "UIF-17": "FINALITY_REVIEW"
        },
        "note": "Review facts relevant to finality/closure only."
      },
      "dataRows": [
        {
          "label": "Sổ kho",
          "example": "118 hộp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Số trên app",
          "example": "118 hộp · đã khớp",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Chênh lệch",
          "example": "0 hộp",
          "ownership": "DERIVED_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-083",
      "short": "083",
      "name": "Kết quả xử lý",
      "surface": "result",
      "bj": [
        "BJ-16",
        "BJ-17"
      ],
      "uc": [
        "UC-16-04",
        "UC-17-02",
        "UC-17-03",
        "UC-17-04"
      ],
      "purpose": "Kết quả đóng hồ sơ, hoặc đã gửi bộ phận hỗ trợ / chuyển cho Mua hàng; không có nút làm lại mù.",
      "actors": [
        "Người phụ trách kiểm soát kho",
        "Người có quyền xem"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "UNKNOWN",
        "ESCALATED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Hồ sơ",
          "REC-260907-03"
        ],
        [
          "Kết quả",
          "Đã xử lý sai lệch"
        ],
        [
          "Phạm vi",
          "Đã mở khóa"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [],
      "traceActions": [
        "ACT-15-RECONCILE"
      ],
      "components": [
        "VLoading",
        "VEmptyState",
        "VEmptyMedia",
        "VEmptyTitle",
        "VEmptyDescription",
        "VCard",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7ControlResult",
      "uifs": [
        "UIF-16",
        "UIF-17"
      ],
      "mode": {
        "modes": {
          "UIF-16": "RECON_RESULT",
          "UIF-17": "RECOVERY_RESULT"
        },
        "note": "Resolved result or unresolved escalation; same source operation/case identity preserved."
      },
      "dataRows": [
        {
          "label": "Hồ sơ",
          "example": "REC-260907-03 / REC-UNKNOWN-01",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Kết quả",
          "example": "Đã xử lý / Đã xác lập hoàn tất / Chưa xác định — đã chuyển xử lý",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Phạm vi",
          "example": "Đã mở khóa hoặc tiếp tục được bảo vệ",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    },
    {
      "id": "SCR-085",
      "short": "085",
      "name": "Điều chỉnh giá trị hàng nhập",
      "surface": "list",
      "bj": [
        "BJ-13"
      ],
      "uc": [
        "UC-13-01"
      ],
      "purpose": "Danh sách các căn cứ mới hoặc thay đổi cần ghi điều chỉnh tăng/giảm vào giá trị hàng nhập.",
      "actors": [
        "Kế toán mua hàng",
        "Kế toán kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "EMPTY",
        "FILTER_EMPTY",
        "PERMISSION_DENIED",
        "FINANCIAL_MASKED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Amount/source tài chính chỉ render khi có quyền.",
      "actions": [],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VSearchBar",
        "VChip",
        "DS v2 / List Row",
        "VBadge",
        "VSkeleton",
        "VEmptyState"
      ],
      "themeComposition": "Theme7ListSurface",
      "uifs": [
        "UIF-13"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Căn cứ điều chỉnh",
          "example": "Hóa đơn vận chuyển VC-8842 · +1.200.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Điều chỉnh giảm",
          "example": "Chiết khấu NCC CK-2201 · −350.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Tình trạng",
          "example": "Có thể xử lý / Đang chờ căn cứ",
          "ownership": "SERVER_DERIVED_READ_ONLY"
        }
      ],
      "prototype_status": "DESIGN_PARITY_v3.13.0"
    },
    {
      "id": "SCR-086",
      "short": "086",
      "name": "Phân bổ điều chỉnh giá trị",
      "surface": "detail",
      "bj": [
        "BJ-13"
      ],
      "uc": [
        "UC-13-01"
      ],
      "purpose": "Một bề mặt duy nhất để xem nguồn, fixed scope, phương pháp hợp lệ, metric/tỷ trọng, preview allocation và kỳ ghi nhận; CTA mở Confirmation Sheet trước commit.",
      "actors": [
        "Kế toán mua hàng",
        "Kế toán kho"
      ],
      "states": [
        "READY",
        "LOADING",
        "SOURCE_CHANGED",
        "VALIDATION_ERROR",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [],
      "notice": "Không hiển thị/nhập tỷ giá; không tự chia đều khi metric không hợp lệ. SCR-088 đã retire.",
      "sensitive": "Source amount và valuation context là financial restricted.",
      "actions": [],
      "traceActions": [
        "BC-IV-06",
        "API-Q-12"
      ],
      "components": [
        "VAppBar",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "DS v2 / List Row",
        "DS v2 / Summary Card",
        "VBanner",
        "VRadio",
        "DS v2 / Confirmation Sheet",
        "DS v2 / Sticky Footer",
        "VButton"
      ],
      "themeComposition": "Theme7DetailSurface",
      "uifs": [
        "UIF-13"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Căn cứ điều chỉnh",
          "example": "VC-8842 · +1.200.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Phạm vi áp dụng",
          "example": "PN-260816-04 · 50 hộp",
          "ownership": "SERVER_AUTHORITATIVE_FIXED_SCOPE"
        },
        {
          "label": "Cách phân bổ",
          "example": "Theo giá trị nhập ban đầu",
          "ownership": "USER_SELECTION_FROM_SERVER_ALLOWED_SET_OR_READ_ONLY_IF_SINGLE"
        },
        {
          "label": "Tổng phân bổ",
          "example": "+1.200.000 đ",
          "ownership": "SERVER_DERIVED_READ_ONLY"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-087",
      "short": "087",
      "name": "Phân bổ điều chỉnh — Đã hợp nhất",
      "surface": "form",
      "bj": [
        "BJ-13"
      ],
      "uc": [],
      "purpose": "Retired in v3.13.0; route redirects to SCR-086.",
      "actors": [
        "Kế toán mua hàng",
        "Kế toán kho"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-086; không còn là màn hình active.",
      "sensitive": "Allocation amount/FX/tax provenance là financial restricted.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7FormSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v3.13.0"
    },
    {
      "id": "SCR-088",
      "short": "088",
      "name": "Rà soát điều chỉnh — Đã hợp nhất",
      "surface": "review",
      "bj": [
        "BJ-13"
      ],
      "uc": [
        "UC-13-01"
      ],
      "purpose": "Retired in v4.6.0; review được thực hiện bằng Confirmation Sheet trên SCR-086.",
      "actors": [
        "Kế toán mua hàng",
        "Kế toán kho"
      ],
      "states": [
        "RETIRED_ACTIVE_ROUTE"
      ],
      "defaultState": "RETIRED_ACTIVE_ROUTE",
      "fields": [],
      "cards": [],
      "notice": "Đã hợp nhất vào SCR-086; deep link cũ chuyển về SCR-086.",
      "sensitive": "Tất cả giá trị tài chính bị omit khỏi DOM khi thiếu quyền.",
      "actions": [],
      "traceActions": [],
      "components": [],
      "themeComposition": "Theme7ReviewSurface",
      "uifs": [],
      "mode": null,
      "dataRows": [],
      "prototype_status": "RETIRED_v4.6.0"
    },
    {
      "id": "SCR-089",
      "short": "089",
      "name": "Kết quả điều chỉnh giá trị",
      "surface": "result",
      "bj": [
        "BJ-13"
      ],
      "uc": [
        "UC-13-01"
      ],
      "purpose": "Result summary của signed adjustment; chi tiết nhiều sản phẩm nằm sau disclosure thay vì render toàn bộ mặc định.",
      "actors": [
        "Kế toán mua hàng",
        "Kế toán kho"
      ],
      "states": [
        "PROCESSING",
        "COMPLETED",
        "REJECTED_EXECUTION",
        "UNKNOWN",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [],
      "cards": [],
      "notice": "",
      "sensitive": "Financial result masked/omitted theo permission.",
      "actions": [],
      "traceActions": [
        "ACT-03-RECORD-LATE-COST"
      ],
      "components": [
        "VAppBar",
        "VEmptyState",
        "DS v2 / Summary Card",
        "DS v2 / Key-value Row",
        "VBanner",
        "VButton"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "UIF-13"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Giá trị điều chỉnh",
          "example": "−350.000 đ",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        },
        {
          "label": "Kỳ ghi nhận",
          "example": "09/2026",
          "ownership": "SERVER_AUTHORITATIVE_RESULT"
        },
        {
          "label": "Giá vốn",
          "example": "Cần cập nhật",
          "ownership": "SERVER_DERIVED_RESULT"
        }
      ],
      "prototype_status": "SEMANTIC_UX_v4.6.0"
    },
    {
      "id": "SCR-062",
      "short": "062",
      "name": "Cấu hình chính sách tồn",
      "surface": "form",
      "bj": [
        "CAP-01"
      ],
      "uc": [],
      "purpose": "Đặt ngưỡng cảnh báo và mức tồn mục tiêu theo từng sản phẩm (mục tiêu ≥ ngưỡng ≥ 0): sửa tại dòng trên web, sửa một sản phẩm từ chi tiết tồn.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Ngưỡng cảnh báo",
          "50"
        ],
        [
          "Mức tồn mục tiêu",
          "80"
        ],
        [
          "Nguồn",
          "Ghi đè theo sản phẩm"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-12-CONFIGURE",
          "label": "Lưu chính sách tồn",
          "bc": "BC-XD-05",
          "api": "API-X-04",
          "permission": "Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại",
          "confirmation": "Có",
          "effect": "Tạo policy version; không ghi inventory ledger",
          "screen_ids": [
            "SCR-062",
            "SCR-063",
            "SCR-065"
          ],
          "evidence_level": "STATIC_VALIDATED_DERIVED"
        }
      ],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VNumberField",
        "VSelect",
        "DS v2 / Info Row",
        "VButton",
        "VBanner",
        "VToast"
      ],
      "themeComposition": "Theme7PolicyForm",
      "uifs": [
        "CAP-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Ngưỡng cảnh báo",
          "example": "50",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Mức tồn mục tiêu",
          "example": "80",
          "ownership": "SYSTEM_DERIVED_READ_ONLY"
        },
        {
          "label": "Nguồn",
          "example": "Ghi đè theo sản phẩm",
          "ownership": "PREFILLED_OR_USER_SELECTION"
        }
      ]
    },
    {
      "id": "SCR-063",
      "short": "063",
      "name": "Cấu hình hàng cận hạn",
      "surface": "form",
      "bj": [
        "CAP-01"
      ],
      "uc": [],
      "purpose": "Đặt số ngày cận hạn và hành động (cảnh báo / chặn bán) mặc định, cùng sản phẩm có chính sách riêng.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "CONFLICT",
        "LOCKED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [
        [
          "Số ngày cận hạn",
          "90"
        ],
        [
          "Hành động",
          "Cảnh báo"
        ],
        [
          "Nguồn",
          "Mặc định tenant"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-12-CONFIGURE",
          "label": "Lưu chính sách tồn",
          "bc": "BC-XD-05",
          "api": "API-X-04",
          "permission": "Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại",
          "confirmation": "Có",
          "effect": "Tạo policy version; không ghi inventory ledger",
          "screen_ids": [
            "SCR-062",
            "SCR-063",
            "SCR-065"
          ],
          "evidence_level": "STATIC_VALIDATED_DERIVED"
        }
      ],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VNumberField",
        "VSelect",
        "DS v2 / Info Row",
        "VButton",
        "VBanner",
        "VToast"
      ],
      "themeComposition": "Theme7NearExpiryPolicyForm",
      "uifs": [
        "CAP-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Số ngày cận hạn",
          "example": "90",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Hành động",
          "example": "Cảnh báo",
          "ownership": "USER_INPUT_SERVER_VALIDATED"
        },
        {
          "label": "Nguồn",
          "example": "Mặc định tenant",
          "ownership": "PREFILLED_OR_USER_SELECTION"
        }
      ]
    },
    {
      "id": "SCR-064",
      "short": "064",
      "name": "Rà soát chính sách",
      "surface": "review",
      "bj": [
        "CAP-01"
      ],
      "uc": [],
      "purpose": "Xem tác động đến chỉ báo/khả dụng trước khi lưu.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "READY",
        "VALIDATION_ERROR",
        "APPROVAL_REQUIRED",
        "PERMISSION_DENIED"
      ],
      "defaultState": "READY",
      "fields": [],
      "cards": [
        [
          "Target/threshold",
          "80 / 50",
          "Hợp lệ"
        ],
        [
          "Cận hạn",
          "90 ngày",
          "WARN"
        ]
      ],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-12-CONFIGURE",
          "label": "Lưu chính sách tồn",
          "bc": "BC-XD-05",
          "api": "API-X-04",
          "permission": "Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại",
          "confirmation": "Có",
          "effect": "Tạo policy version; không ghi inventory ledger",
          "screen_ids": [
            "SCR-062",
            "SCR-063",
            "SCR-065"
          ],
          "evidence_level": "STATIC_VALIDATED_DERIVED"
        }
      ],
      "traceActions": [],
      "components": [
        "VAppBar",
        "DS v2 / Info Row",
        "DS v2 / Key-value Row",
        "VButton",
        "VBanner"
      ],
      "themeComposition": "Theme7PolicyReview",
      "uifs": [
        "CAP-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Target/threshold",
          "example": "80 / 50 · Hợp lệ",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        },
        {
          "label": "Cận hạn",
          "example": "90 ngày · WARN",
          "ownership": "SERVER_AUTHORITATIVE_LIST_OR_SUMMARY_ITEM"
        }
      ]
    },
    {
      "id": "SCR-065",
      "short": "065",
      "name": "Kết quả cập nhật",
      "surface": "result",
      "bj": [
        "CAP-01"
      ],
      "uc": [],
      "purpose": "Chỉ còn khi chưa rõ kết quả hoặc bị từ chối; lưu thành công hiện toast ngay tại màn chính sách.",
      "actors": [
        "Chủ cửa hàng"
      ],
      "states": [
        "COMPLETED",
        "UNKNOWN",
        "REJECTED_EXECUTION",
        "PERMISSION_DENIED"
      ],
      "defaultState": "COMPLETED",
      "fields": [
        [
          "Policy version",
          "v6"
        ],
        [
          "Tác động ledger",
          "Không"
        ],
        [
          "Chỉ báo tồn thấp",
          "12 sản phẩm"
        ]
      ],
      "cards": [],
      "notice": "",
      "sensitive": "Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.",
      "actions": [
        {
          "id": "ACT-12-CONFIGURE",
          "label": "Lưu chính sách tồn",
          "bc": "BC-XD-05",
          "api": "API-X-04",
          "permission": "Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại",
          "confirmation": "Có",
          "effect": "Tạo policy version; không ghi inventory ledger",
          "screen_ids": [
            "SCR-062",
            "SCR-063",
            "SCR-065"
          ],
          "evidence_level": "STATIC_VALIDATED_DERIVED"
        }
      ],
      "traceActions": [],
      "components": [
        "VAppBar",
        "VEmptyState",
        "DS v2 / Info Row",
        "VButton",
        "VBanner",
        "VToast"
      ],
      "themeComposition": "Theme7OperationResult",
      "uifs": [
        "CAP-01"
      ],
      "mode": null,
      "dataRows": [
        {
          "label": "Policy version",
          "example": "v6",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Tác động ledger",
          "example": "Không",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        },
        {
          "label": "Chỉ báo tồn thấp",
          "example": "12 sản phẩm",
          "ownership": "SERVER_AUTHORITATIVE_READ_ONLY"
        }
      ]
    }
  ],
  "runOrder": [
    "UIF-02",
    "UIF-01",
    "UIF-03",
    "UIF-13",
    "UIF-04",
    "UIF-05",
    "UIF-06",
    "UIF-07",
    "UIF-09",
    "UIF-10",
    "UIF-08",
    "UIF-11",
    "UIF-12",
    "UIF-14",
    "UIF-15",
    "UIF-16",
    "UIF-17",
    "CAP-01"
  ],
  "version": "4.6.8"
};
