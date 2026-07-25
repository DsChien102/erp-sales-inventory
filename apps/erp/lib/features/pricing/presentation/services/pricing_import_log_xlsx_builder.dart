import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:vet45_pricing_application/application.dart';

/// FE-only helper: encode import result rows to a minimal `.xlsx` workbook.
abstract final class PricingImportLogXlsxBuilder {
  static const headers = [
    'rule_id',
    'customer_id',
    'product_id',
    'product_unit_id',
    'rule_price',
    'effective_from',
    'effective_to',
    'note',
    'status',
    'action',
    'error_codes',
    'warning_codes',
  ];

  static Uint8List build({
    required List<CustomerPriceRuleImportRowPreviewDto> rows,
  }) {
    final dataRows = rows
        .map(
          (row) => [
            row.ruleId ?? '',
            row.customerId ?? '',
            row.productId ?? '',
            row.productUnitId ?? '',
            row.price ?? '',
            row.effectiveFrom ?? '',
            row.effectiveTo ?? '',
            row.note ?? '',
            row.status.name,
            row.action.name,
            row.errorCodes.join('|'),
            row.warningCodes.join('|'),
          ],
        )
        .toList(growable: false);

    const instructionsText =
        'Nhật ký kết quả nhập — mỗi dòng tương ứng một dòng trong file Excel.';
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

    void addXml(String path, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXml(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>',
    );
    addXml(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>',
    );
    addXml(
      'xl/workbook.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets>'
      '<sheet name="import_log" sheetId="1" r:id="rId1"/>'
      '<sheet name="summary" sheetId="2" r:id="rId2"/>'
      '</sheets></workbook>',
    );
    addXml(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>'
      '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>',
    );
    addXml(
      'xl/styles.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>'
      '<borders count="1"><border/></borders>'
      '<cellStyleXfs count="1"><xf/></cellStyleXfs>'
      '<cellXfs count="1"><xf/></cellXfs>'
      '</styleSheet>',
    );

    final sharedXml = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'count="${uniqueStrings.length}" uniqueCount="${uniqueStrings.length}">',
    );
    for (final value in uniqueStrings) {
      sharedXml.write(
        '<si><t>${_escapeXml(value)}</t></si>',
      );
    }
    sharedXml.write('</sst>');
    addXml('xl/sharedStrings.xml', sharedXml.toString());

    addXml(
      'xl/worksheets/sheet1.xml',
      _sheetXml(
        headers: headers,
        dataRows: dataRows,
        sharedIndex: sharedIndex,
      ),
    );
    addXml(
      'xl/worksheets/sheet2.xml',
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetData><row r="1">'
      '<c r="A1" t="s"><v>${sharedIndex(instructionsText)}</v></c>'
      '</row></sheetData></worksheet>',
    );

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _sheetXml({
    required List<String> headers,
    required List<List<String>> dataRows,
    required int Function(String) sharedIndex,
  }) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetData>',
    );
    buffer.write('<row r="1">');
    for (var c = 0; c < headers.length; c++) {
      final ref = '${_columnName(c)}1';
      buffer.write(
        '<c r="$ref" t="s"><v>${sharedIndex(headers[c])}</v></c>',
      );
    }
    buffer.write('</row>');
    for (var r = 0; r < dataRows.length; r++) {
      final rowNumber = r + 2;
      buffer.write('<row r="$rowNumber">');
      final values = dataRows[r];
      for (var c = 0; c < headers.length; c++) {
        final value = c < values.length ? values[c] : '';
        final ref = '${_columnName(c)}$rowNumber';
        buffer.write(
          '<c r="$ref" t="s"><v>${sharedIndex(value)}</v></c>',
        );
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  static String _columnName(int index) {
    var n = index;
    final chars = StringBuffer();
    do {
      chars.writeCharCode(65 + (n % 26));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return chars.toString().split('').reversed.join();
  }

  static String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
