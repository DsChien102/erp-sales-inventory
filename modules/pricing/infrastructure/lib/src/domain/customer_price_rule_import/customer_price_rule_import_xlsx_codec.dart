import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

enum CustomerPriceRuleImportXlsxFailure {
  unsupportedFile,
  templateSheetInvalid,
  formulaNotSupported,
  archiveLimitExceeded,
}

final class CustomerPriceRuleImportXlsxException implements Exception {
  const CustomerPriceRuleImportXlsxException(this.failure, this.message);

  final CustomerPriceRuleImportXlsxFailure failure;
  final String message;

  @override
  String toString() => 'CustomerPriceRuleImportXlsxException: $message';
}

final class CustomerPriceRuleImportXlsxRow {
  const CustomerPriceRuleImportXlsxRow({
    required this.rowNumber,
    required this.values,
  });

  final int rowNumber;
  final List<String?> values;
}

abstract final class CustomerPriceRuleImportXlsxCodec {
  static const maxArchiveEntries = 128;
  static const maxUncompressedBytes = 16 * 1024 * 1024;

  static Uint8List encodeWorkbook({
    required String dataSheetName,
    required String instructionsSheetName,
    required List<String> headers,
    required List<List<String>> dataRows,
    String instructionsText = 'Customer price rules import template V1',
  }) {
    final archive = Archive();
    final sharedStrings = <String>[instructionsText, ...headers];
    for (final row in dataRows) {
      sharedStrings.addAll(row);
    }
    final uniqueStrings = <String>[];
    final stringIndexes = <String, int>{};
    for (final value in sharedStrings) {
      stringIndexes.putIfAbsent(value, () {
        uniqueStrings.add(value);
        return uniqueStrings.length - 1;
      });
    }

    int sharedIndex(String value) => stringIndexes[value] ?? 0;

    archive.addFile(
      ArchiveFile('[Content_Types].xml', 0, utf8.encode(_contentTypesXml())),
    );
    archive.addFile(ArchiveFile('_rels/.rels', 0, utf8.encode(_rootRelsXml())));
    archive.addFile(
      ArchiveFile(
        'xl/workbook.xml',
        0,
        utf8.encode(
          _workbookXml(
            dataSheetName: dataSheetName,
            instructionsSheetName: instructionsSheetName,
          ),
        ),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/_rels/workbook.xml.rels',
        0,
        utf8.encode(_workbookRelsXml()),
      ),
    );
    archive.addFile(ArchiveFile('xl/styles.xml', 0, utf8.encode(_stylesXml())));
    archive.addFile(
      ArchiveFile(
        'xl/sharedStrings.xml',
        0,
        utf8.encode(_sharedStringsXml(uniqueStrings)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/worksheets/sheet1.xml',
        0,
        utf8.encode(
          _sheetXml(
            headers: headers,
            dataRows: dataRows,
            sharedIndex: sharedIndex,
          ),
        ),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/worksheets/sheet2.xml',
        0,
        utf8.encode(
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<sheetData><row r="1">'
          '<c r="A1" t="s"><v>${sharedIndex(instructionsText)}</v></c>'
          '</row></sheetData></worksheet>',
        ),
      ),
    );

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static ({
    int headerRowNumber,
    List<String> headers,
    List<CustomerPriceRuleImportXlsxRow> rows,
  })
  decodeWorkbook(
    Uint8List bytes,
    String dataSheetName, {
    String? instructionsSheetName,
  }) {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (error) {
      throw CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.unsupportedFile,
        'Invalid ZIP archive: $error',
      );
    }
    _validateArchiveBounds(archive);

    final workbookFile = _requiredFile(archive, 'xl/workbook.xml');
    final workbookXml = XmlDocument.parse(
      utf8.decode(_fileBytes(workbookFile)),
    );
    final sheets = workbookXml.findAllElements('sheet').toList(growable: false);
    final sheetNames = sheets
        .map((sheet) => sheet.getAttribute('name'))
        .whereType<String>()
        .toSet();
    if (!sheetNames.contains(dataSheetName) ||
        (instructionsSheetName != null &&
            (sheetNames.length != 2 ||
                !sheetNames.contains(instructionsSheetName)))) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.templateSheetInvalid,
        'Required template sheets are missing or unexpected sheets exist.',
      );
    }
    final dataSheet = sheets.firstWhere(
      (sheet) => sheet.getAttribute('name') == dataSheetName,
    );
    final sheetId = dataSheet.getAttribute('r:id');
    if (sheetId == null) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.templateSheetInvalid,
        'Data sheet relationship is missing.',
      );
    }

    final relsFile = _requiredFile(archive, 'xl/_rels/workbook.xml.rels');
    final relsXml = XmlDocument.parse(utf8.decode(_fileBytes(relsFile)));
    final target = relsXml
        .findAllElements('Relationship')
        .firstWhere(
          (rel) => rel.getAttribute('Id') == sheetId,
          orElse: () => throw const CustomerPriceRuleImportXlsxException(
            CustomerPriceRuleImportXlsxFailure.templateSheetInvalid,
            'Data sheet relationship target is missing.',
          ),
        )
        .getAttribute('Target');
    if (target == null) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.templateSheetInvalid,
        'Data sheet target is missing.',
      );
    }

    final sheetPath = _resolveWorkbookTarget(target);
    final sheetFile = _requiredFile(
      archive,
      sheetPath,
      failure: CustomerPriceRuleImportXlsxFailure.templateSheetInvalid,
    );
    final sharedStrings = _readSharedStrings(archive);
    final dateStyleIndexes = _readDateStyleIndexes(archive);
    final uses1904Dates =
        workbookXml
                .findAllElements('workbookPr')
                .firstOrNull
                ?.getAttribute('date1904') ==
            '1' ||
        workbookXml
                .findAllElements('workbookPr')
                .firstOrNull
                ?.getAttribute('date1904') ==
            'true';
    final sheetXml = XmlDocument.parse(utf8.decode(_fileBytes(sheetFile)));
    final parsedRows = <CustomerPriceRuleImportXlsxRow>[];
    var previousRowNumber = 0;
    for (final row in sheetXml.findAllElements('row')) {
      final rowNumber =
          int.tryParse(row.getAttribute('r') ?? '') ?? previousRowNumber + 1;
      if (rowNumber <= previousRowNumber) {
        throw const CustomerPriceRuleImportXlsxException(
          CustomerPriceRuleImportXlsxFailure.unsupportedFile,
          'Worksheet row numbers must be strictly increasing.',
        );
      }
      previousRowNumber = rowNumber;
      final cells = <String?>[];
      for (final cell in row.findElements('c')) {
        final column = _columnIndex(cell.getAttribute('r') ?? '');
        if (column < 0) {
          throw const CustomerPriceRuleImportXlsxException(
            CustomerPriceRuleImportXlsxFailure.unsupportedFile,
            'Cell reference is invalid.',
          );
        }
        while (cells.length <= column) {
          cells.add(null);
        }
        cells[column] = _readCellValue(
          cell,
          sharedStrings,
          dateStyleIndexes: dateStyleIndexes,
          uses1904Dates: uses1904Dates,
        );
      }
      parsedRows.add(
        CustomerPriceRuleImportXlsxRow(
          rowNumber: rowNumber,
          values: List.unmodifiable(cells),
        ),
      );
    }

    if (parsedRows.isEmpty) {
      return (
        headerRowNumber: 0,
        headers: <String>[],
        rows: <CustomerPriceRuleImportXlsxRow>[],
      );
    }

    final headers = parsedRows.first.values
        .map((value) => value?.trim().toLowerCase() ?? '')
        .toList(growable: false);
    final rows = parsedRows.skip(1).toList(growable: false);
    return (
      headerRowNumber: parsedRows.first.rowNumber,
      headers: headers,
      rows: rows,
    );
  }

  static void _validateArchiveBounds(Archive archive) {
    if (archive.files.length > maxArchiveEntries) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.archiveLimitExceeded,
        'Archive contains too many entries.',
      );
    }
    var totalBytes = 0;
    for (final file in archive.files) {
      final name = file.name.replaceAll('\\', '/');
      if (name.startsWith('/') || name.split('/').contains('..')) {
        throw const CustomerPriceRuleImportXlsxException(
          CustomerPriceRuleImportXlsxFailure.unsupportedFile,
          'Archive entry path is unsafe.',
        );
      }
      totalBytes += file.size;
      if (totalBytes > maxUncompressedBytes) {
        throw const CustomerPriceRuleImportXlsxException(
          CustomerPriceRuleImportXlsxFailure.archiveLimitExceeded,
          'Archive uncompressed size exceeds the limit.',
        );
      }
    }
  }

  static ArchiveFile _requiredFile(
    Archive archive,
    String name, {
    CustomerPriceRuleImportXlsxFailure failure =
        CustomerPriceRuleImportXlsxFailure.unsupportedFile,
  }) {
    return archive.files.firstWhere(
      (file) => file.name == name,
      orElse: () => throw CustomerPriceRuleImportXlsxException(
        failure,
        'Required OOXML part is missing: $name',
      ),
    );
  }

  static List<int> _fileBytes(ArchiveFile file) =>
      List<int>.from(file.content as List<int>);

  static String _resolveWorkbookTarget(String target) {
    final normalized = target.replaceAll('\\', '/');
    if (normalized.split('/').contains('..')) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.unsupportedFile,
        'Worksheet target path is unsafe.',
      );
    }
    return normalized.startsWith('/')
        ? normalized.substring(1)
        : 'xl/$normalized';
  }

  static List<String> _readSharedStrings(Archive archive) {
    final file = archive.files.where((f) => f.name == 'xl/sharedStrings.xml');
    if (file.isEmpty) {
      return const [];
    }
    final xml = XmlDocument.parse(utf8.decode(_fileBytes(file.first)));
    return xml
        .findAllElements('si')
        .map((item) => item.findAllElements('t').map((t) => t.innerText).join())
        .toList(growable: false);
  }

  static Set<int> _readDateStyleIndexes(Archive archive) {
    final matches = archive.files.where((file) => file.name == 'xl/styles.xml');
    if (matches.isEmpty) {
      return const {};
    }
    final document = XmlDocument.parse(utf8.decode(_fileBytes(matches.first)));
    final customFormats = <int, String>{};
    for (final format in document.findAllElements('numFmt')) {
      final id = int.tryParse(format.getAttribute('numFmtId') ?? '');
      final code = format.getAttribute('formatCode');
      if (id != null && code != null) {
        customFormats[id] = code;
      }
    }
    final cellXfs = document.findAllElements('cellXfs').firstOrNull;
    if (cellXfs == null) {
      return const {};
    }
    final result = <int>{};
    final styles = cellXfs.findElements('xf').toList(growable: false);
    for (var index = 0; index < styles.length; index++) {
      final numberFormatId =
          int.tryParse(styles[index].getAttribute('numFmtId') ?? '') ?? 0;
      if (_builtinDateFormatIds.contains(numberFormatId) ||
          _looksLikeDateFormat(customFormats[numberFormatId])) {
        result.add(index);
      }
    }
    return result;
  }

  static const _builtinDateFormatIds = <int>{
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    27,
    30,
    36,
    45,
    46,
    47,
    50,
    57,
  };

  static bool _looksLikeDateFormat(String? formatCode) {
    if (formatCode == null) {
      return false;
    }
    final normalized = formatCode
        .replaceAll(RegExp(r'"[^"]*"'), '')
        .replaceAll(RegExp(r'\\.'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .toLowerCase();
    return RegExp(r'[dy]').hasMatch(normalized);
  }

  static String? _readCellValue(
    XmlElement cell,
    List<String> sharedStrings, {
    required Set<int> dateStyleIndexes,
    required bool uses1904Dates,
  }) {
    if (cell.findElements('f').isNotEmpty) {
      throw const CustomerPriceRuleImportXlsxException(
        CustomerPriceRuleImportXlsxFailure.formulaNotSupported,
        'Formula cells are not supported.',
      );
    }
    final type = cell.getAttribute('t');
    if (type == 'inlineStr') {
      return cell.findAllElements('t').map((node) => node.innerText).join();
    }
    final value = cell
        .findElements('v')
        .map((node) => node.innerText)
        .firstOrNull;
    if (value == null) {
      return null;
    }
    if (type == 's') {
      final index = int.tryParse(value);
      if (index == null || index < 0 || index >= sharedStrings.length) {
        return null;
      }
      return sharedStrings[index];
    }
    if (type == 'b') {
      return value == '1' ? 'TRUE' : 'FALSE';
    }
    final styleIndex = int.tryParse(cell.getAttribute('s') ?? '');
    if (styleIndex != null && dateStyleIndexes.contains(styleIndex)) {
      final serial = double.tryParse(value);
      if (serial == null || !serial.isFinite) {
        return value;
      }
      return _excelDate(serial, uses1904Dates: uses1904Dates);
    }
    return value;
  }

  static String _excelDate(double serial, {required bool uses1904Dates}) {
    final base = uses1904Dates
        ? DateTime.utc(1904, 1, 1)
        : DateTime.utc(1899, 12, 30);
    final date = base.add(Duration(days: serial.floor()));
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  static int _columnIndex(String cellRef) {
    final letters = cellRef.replaceAll(RegExp(r'[^A-Z]'), '');
    var index = 0;
    for (var i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  static String _contentTypesXml() => '''
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>''';

  static String _rootRelsXml() => '''
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

  static String _workbookXml({
    required String dataSheetName,
    required String instructionsSheetName,
  }) =>
      '''
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="$dataSheetName" sheetId="1" r:id="rId1"/>
    <sheet name="$instructionsSheetName" sheetId="2" r:id="rId2"/>
  </sheets>
</workbook>''';

  static String _workbookRelsXml() => '''
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>''';

  static String _stylesXml() =>
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"/>';

  static String _sharedStringsXml(List<String> values) {
    final buffer = StringBuffer(
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${values.length}" uniqueCount="${values.length}">',
    );
    for (final value in values) {
      buffer.write('<si><t>${_xmlEscape(value)}</t></si>');
    }
    buffer.write('</sst>');
    return buffer.toString();
  }

  static String _sheetXml({
    required List<String> headers,
    required List<List<String>> dataRows,
    required int Function(String value) sharedIndex,
  }) {
    final buffer = StringBuffer(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
    );
    _writeRow(buffer, rowNumber: 1, values: headers, sharedIndex: sharedIndex);
    var rowNumber = 2;
    for (final row in dataRows) {
      _writeRow(
        buffer,
        rowNumber: rowNumber,
        values: row,
        sharedIndex: sharedIndex,
      );
      rowNumber++;
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  static void _writeRow(
    StringBuffer buffer, {
    required int rowNumber,
    required List<String> values,
    required int Function(String value) sharedIndex,
  }) {
    buffer.write('<row r="$rowNumber">');
    for (var index = 0; index < values.length; index++) {
      final column = String.fromCharCode(65 + index);
      final value = values[index];
      buffer.write(
        '<c r="$column$rowNumber" t="s"><v>${sharedIndex(value)}</v></c>',
      );
    }
    buffer.write('</row>');
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
