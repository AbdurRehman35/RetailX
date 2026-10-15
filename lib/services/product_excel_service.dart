import 'package:excel/excel.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../models/product.dart';

class ProductImportRow {
  ProductImportRow({
    required this.rowNumber,
    required this.product,
  });

  final int rowNumber;
  final Product product;
}

class ProductImportParseResult {
  ProductImportParseResult({
    required this.rows,
    required this.errors,
  });

  final List<ProductImportRow> rows;
  final List<String> errors;

  bool get canImport => errors.isEmpty && rows.isNotEmpty;
}

class ProductExcelService {
  static const templateHeaders = [
    'name',
    'category',
    'purchase price',
    'sales price',
    'quantity',
    'description',
    'minimum stock',
  ];

  static const _fields = [
    _Field('name', 'name'),
    _Field('category', 'category'),
    _Field('purchase price', 'purchase'),
    _Field('sales price', 'selling'),
    _Field('quantity', 'quantity'),
    _Field('description', 'description'),
    _Field('minimum stock', 'minimum'),
  ];

  List<int> buildTemplateBytes() {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet()!;
    excel.rename(defaultName, 'Products');
    final sheet = excel['Products'];
    sheet.appendRow(
      templateHeaders.map((h) => TextCellValue(h)).toList(),
    );
    sheet.appendRow([
      TextCellValue('Sample T-Shirt'),
      TextCellValue('Apparel'),
      DoubleCellValue(8.5),
      DoubleCellValue(19.99),
      IntCellValue(50),
      TextCellValue('Cotton crew neck'),
      IntCellValue(10),
    ]);
    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Could not create Excel template');
    }
    return encoded;
  }

  ProductImportParseResult parseImportBytes(List<int> bytes, {String? fileName}) {
    final grids = _decodeWorkbook(bytes, fileName: fileName);
    if (grids.errors.isNotEmpty) {
      return ProductImportParseResult(rows: [], errors: grids.errors);
    }
    if (grids.sheets.isEmpty) {
      return ProductImportParseResult(
        rows: [],
        errors: ['The file has no worksheets with data.'],
      );
    }

    List<List<dynamic>>? sheetRows;
    int? headerRowIndex;
    Map<String, int>? columnByHeader;

    for (final grid in grids.sheets) {
      if (grid.isEmpty) continue;
      for (var r = 0; r < grid.length && r < 50; r++) {
        final mapResult = _mapHeaders(grid, r);
        if (mapResult.errors.isNotEmpty) continue;
        if (mapResult.columns.length == templateHeaders.length) {
          sheetRows = grid;
          headerRowIndex = r;
          columnByHeader = mapResult.columns;
          break;
        }
      }
      if (sheetRows != null) break;
    }

    if (sheetRows == null || headerRowIndex == null || columnByHeader == null) {
      return ProductImportParseResult(
        rows: [],
        errors: [
          'Missing or incorrect column headers. Include all of these columns '
          '(spelling may match if the column is slightly cut off in Excel): '
          '${templateHeaders.join(', ')}.',
        ],
      );
    }

    final rows = <ProductImportRow>[];
    final errors = <String>[];
    final baseId = DateTime.now().microsecondsSinceEpoch;

    for (var r = headerRowIndex + 1; r < sheetRows.length; r++) {
      final rowNum = r + 1;
      final values = <String, String>{};
      for (final field in _fields) {
        values[field.key] =
            _gridCell(sheetRows, r, columnByHeader[field.header]!);
      }

      final anyFilled = values.values.any((v) => v.trim().isNotEmpty);
      if (!anyFilled) continue;

      final missing = <String>[];
      for (final field in _fields) {
        if (values[field.key]!.trim().isEmpty) {
          missing.add(field.header);
        }
      }
      if (missing.isNotEmpty) {
        errors.add(
          'Row $rowNum: missing value(s) for ${missing.join(', ')}.',
        );
        continue;
      }

      final purchase = _parseDouble(values['purchase']!);
      final selling = _parseDouble(values['selling']!);
      final quantity = _parseInt(values['quantity']!);
      final minimum = _parseInt(values['minimum']!);

      if (purchase == null || purchase < 0) {
        errors.add('Row $rowNum: purchase price must be a valid number ≥ 0.');
        continue;
      }
      if (selling == null || selling < 0) {
        errors.add('Row $rowNum: sales price must be a valid number ≥ 0.');
        continue;
      }
      if (quantity == null || quantity < 0) {
        errors.add('Row $rowNum: quantity must be a valid whole number ≥ 0.');
        continue;
      }
      if (minimum == null || minimum < 0) {
        errors.add(
          'Row $rowNum: minimum stock must be a valid whole number ≥ 0.',
        );
        continue;
      }

      rows.add(
        ProductImportRow(
          rowNumber: rowNum,
          product: Product(
            id: '${baseId}_$r',
            name: values['name']!.trim(),
            description: values['description']!.trim(),
            category: values['category']!.trim(),
            purchasePrice: purchase,
            sellingPrice: selling,
            currentStock: quantity,
            minimumStock: minimum,
            createdAt: DateTime.now(),
          ),
        ),
      );
    }

    if (rows.isEmpty && errors.isEmpty) {
      errors.add('No product rows found below the header row.');
    }

    if (errors.isNotEmpty) {
      return ProductImportParseResult(rows: [], errors: errors);
    }

    return ProductImportParseResult(rows: rows, errors: []);
  }

  _WorkbookDecodeResult _decodeWorkbook(
    List<int> bytes, {
    String? fileName,
  }) {
    Object? primaryError;
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      final sheets = decoder.tables.values
          .map(_gridFromSpreadsheetTable)
          .where((s) => s.isNotEmpty)
          .toList();
      if (sheets.isNotEmpty) {
        return _WorkbookDecodeResult(sheets: sheets, errors: []);
      }
    } catch (e) {
      primaryError = e;
    }

    try {
      final excel = Excel.decodeBytes(bytes);
      final sheets = excel.tables.values
          .where((t) => t.maxRows > 0)
          .map((t) {
            final grid = <List<dynamic>>[];
            for (var r = 0; r < t.maxRows; r++) {
              final row = <dynamic>[];
              for (var c = 0; c < t.maxColumns; c++) {
                row.add(_excelCellText(t, r, c));
              }
              grid.add(row);
            }
            return grid;
          })
          .toList();
      if (sheets.isNotEmpty) {
        return _WorkbookDecodeResult(sheets: sheets, errors: []);
      }
    } catch (e) {
      primaryError ??= e;
    }

    return _WorkbookDecodeResult(
      sheets: [],
      errors: [
        'Could not read this file as Excel (.xlsx). '
        '${fileName != null ? 'File: $fileName. ' : ''}'
        '${primaryError != null ? 'Details: $primaryError' : 'The workbook appears empty.'}',
      ],
    );
  }

  String _excelCellText(Sheet sheet, int row, int col) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    final v = cell.value;
    if (v == null) return '';
    return switch (v) {
      TextCellValue() => v.value.toString().trim(),
      IntCellValue() => v.value.toString(),
      DoubleCellValue() => v.value.toString(),
      BoolCellValue() => v.value.toString(),
      DateCellValue() => v.asDateTimeLocal().toString(),
      DateTimeCellValue() => v.asDateTimeLocal().toString(),
      TimeCellValue() => v.toString(),
      FormulaCellValue() => v.formula.toString(),
    };
  }

  List<List<dynamic>> _gridFromSpreadsheetTable(SpreadsheetTable table) {
    final grid = <List<dynamic>>[];
    for (var r = 0; r < table.maxRows; r++) {
      final padded = List<dynamic>.filled(table.maxCols, null);
      if (r < table.rows.length) {
        final source = table.rows[r];
        for (var c = 0; c < source.length && c < table.maxCols; c++) {
          padded[c] = source[c];
        }
      }
      grid.add(padded);
    }
    return grid;
  }

  int _gridColumnCount(List<List<dynamic>> grid) {
    var cols = 0;
    for (final row in grid) {
      if (row.length > cols) cols = row.length;
    }
    return cols;
  }

  _HeaderMapResult _mapHeaders(List<List<dynamic>> grid, int rowIndex) {
    final columns = <String, int>{};
    final errors = <String>[];
    final seen = <String, int>{};
    final colCount = _gridColumnCount(grid);

    for (var c = 0; c < colCount; c++) {
      final raw = _gridCell(grid, rowIndex, c);
      if (raw.trim().isEmpty) continue;

      final canonical = _canonicalHeader(raw);
      if (canonical == null) continue;

      if (seen.containsKey(canonical)) {
        errors.add(
          'Duplicate column "$raw" in header row (column ${c + 1}).',
        );
        continue;
      }
      seen[canonical] = c;
      columns[canonical] = c;
    }

    final missing =
        templateHeaders.where((h) => !columns.containsKey(h)).toList();
    if (missing.isNotEmpty) {
      errors.add('Missing column(s): ${missing.join(', ')}.');
    }

    return _HeaderMapResult(columns: columns, errors: errors);
  }

  /// Maps header text to a template column (exact or truncated, e.g. "purchase pric").
  String? _canonicalHeader(String raw) {
    final normalized = _normalizeHeader(raw);
    if (normalized.isEmpty) return null;

    for (final expected in templateHeaders) {
      if (normalized == expected) return expected;
    }

    for (final expected in templateHeaders) {
      if (expected.startsWith(normalized) &&
          normalized.length >= expected.length - 4) {
        return expected;
      }
      if (normalized.startsWith(expected)) {
        return expected;
      }
    }

    return null;
  }

  String _normalizeHeader(String value) {
    return value.trim().toLowerCase().replaceAll('_', ' ').replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  String _gridCell(List<List<dynamic>> grid, int row, int col) {
    if (row < 0 || row >= grid.length) return '';
    final line = grid[row];
    if (col < 0 || col >= line.length) return '';
    final v = line[col];
    if (v == null) return '';
    return v.toString().trim();
  }

  double? _parseDouble(String text) {
    return double.tryParse(text.replaceAll(',', '').trim());
  }

  int? _parseInt(String text) {
    final asDouble = double.tryParse(text.replaceAll(',', '').trim());
    return asDouble?.round();
  }
}

class _Field {
  const _Field(this.header, this.key);
  final String header;
  final String key;
}

class _HeaderMapResult {
  _HeaderMapResult({required this.columns, required this.errors});
  final Map<String, int> columns;
  final List<String> errors;
}

class _WorkbookDecodeResult {
  _WorkbookDecodeResult({required this.sheets, required this.errors});
  final List<List<List<dynamic>>> sheets;
  final List<String> errors;
}
