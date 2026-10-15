import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retailx/services/product_excel_service.dart';

void main() {
  test('imports workbook with standard product columns', () {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow(
      ProductExcelService.templateHeaders
          .map((h) => TextCellValue(h))
          .toList(),
    );
    sheet.appendRow([
      TextCellValue('Milk 1L'),
      TextCellValue('Dairy'),
      IntCellValue(220),
      IntCellValue(260),
      IntCellValue(35),
      TextCellValue('Fresh full cream milk'),
      IntCellValue(10),
    ]);

    final bytes = excel.encode()!;
    final result = ProductExcelService().parseImportBytes(bytes);

    expect(result.canImport, isTrue);
    expect(result.rows, hasLength(1));
    expect(result.rows.first.product.name, 'Milk 1L');
    expect(result.rows.first.product.currentStock, 35);
  });
}
