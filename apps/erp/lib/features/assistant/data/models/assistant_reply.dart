enum AssistantStatus { ok, troChuyen, ngoaiPhamVi, chuaHoTro, tuChoi, khongQuyen, loi, hetLuot, ban }

enum ColumnKind { chu, tien, so, ngay, phanTram }

AssistantStatus _statusFrom(Object? raw) => switch (raw) {
  'ok' => AssistantStatus.ok,
  'tro_chuyen' => AssistantStatus.troChuyen,
  'ngoai_pham_vi' => AssistantStatus.ngoaiPhamVi,
  'chua_ho_tro' => AssistantStatus.chuaHoTro,
  'tu_choi' => AssistantStatus.tuChoi,
  'khong_quyen' => AssistantStatus.khongQuyen,
  'het_luot' => AssistantStatus.hetLuot,
  'ban' => AssistantStatus.ban,
  _ => AssistantStatus.loi,
};

ColumnKind _kindFrom(Object? raw) => switch (raw) {
  'tien' => ColumnKind.tien,
  'so' => ColumnKind.so,
  'ngay' => ColumnKind.ngay,
  'phan_tram' => ColumnKind.phanTram,
  _ => ColumnKind.chu,
};

class OpenTarget {
  const OpenTarget({required this.loai, required this.id});

  /// `san_pham` | `khach_hang` | `don_ban`.
  final String loai;
  final String id;

  static OpenTarget? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final loai = raw['loai'];
    final id = raw['id'];
    if (loai is! String || id is! String) return null;
    return OpenTarget(loai: loai, id: id);
  }
}

class TableColumn {
  const TableColumn({required this.key, required this.name, required this.kind});

  factory TableColumn.fromJson(Map<String, dynamic> json) => TableColumn(
    key: (json['khoa'] ?? '').toString(),
    name: (json['ten'] ?? '').toString(),
    kind: _kindFrom(json['kieu']),
  );

  final String key;
  final String name;
  final ColumnKind kind;
}

class TableRow {
  const TableRow({required this.cells, this.open});

  factory TableRow.fromJson(Map<String, dynamic> json) {
    final o = json['o'];
    return TableRow(
      cells: o is Map ? Map<String, Object?>.from(o) : const {},
      open: OpenTarget.tryParse(json['mo']),
    );
  }

  final Map<String, Object?> cells;
  final OpenTarget? open;
}

class TableBlock {
  const TableBlock({required this.title, required this.columns, required this.rows});

  factory TableBlock.fromJson(Map<String, dynamic> json) {
    final cot = json['cot'];
    final dong = json['dong'];
    return TableBlock(
      title: (json['tieu_de'] ?? '').toString(),
      columns: cot is List
          ? [for (final c in cot) if (c is Map) TableColumn.fromJson(Map<String, dynamic>.from(c))]
          : const [],
      rows: dong is List
          ? [for (final r in dong) if (r is Map) TableRow.fromJson(Map<String, dynamic>.from(r))]
          : const [],
    );
  }

  final String title;
  final List<TableColumn> columns;
  final List<TableRow> rows;
}

class AssistantReply {
  const AssistantReply({
    required this.status,
    required this.text,
    this.blocks = const [],
    this.remaining,
    this.tools = const [],
  });

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    final khoi = json['khoi'];
    final tools = json['cong_cu'];
    final remaining = json['luot_con_lai'];
    return AssistantReply(
      status: _statusFrom(json['trang_thai']),
      text: (json['cau_tra_loi'] ?? '').toString(),
      blocks: khoi is List
          ? [for (final b in khoi) if (b is Map) TableBlock.fromJson(Map<String, dynamic>.from(b))]
          : const [],
      remaining: remaining is num ? remaining.toInt() : null,
      tools: tools is List ? [for (final t in tools) t.toString()] : const [],
    );
  }

  final AssistantStatus status;
  final String text;
  final List<TableBlock> blocks;
  final int? remaining;
  final List<String> tools;
}

class AssistantTurn {
  const AssistantTurn({required this.role, required this.text});

  /// `user` | `assistant`.
  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}
