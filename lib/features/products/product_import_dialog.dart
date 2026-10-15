import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/download_bytes.dart';
import '../../services/pos_store.dart';
import '../../services/product_excel_service.dart';

Future<void> showProductImportDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _ProductImportDialog(),
  );
}

class _ProductImportDialog extends StatefulWidget {
  const _ProductImportDialog();

  @override
  State<_ProductImportDialog> createState() => _ProductImportDialogState();
}

class _ProductImportDialogState extends State<_ProductImportDialog> {
  final _excel = ProductExcelService();
  bool _loading = false;
  String? _status;
  List<String> _errors = [];
  int? _previewCount;

  Future<void> _downloadTemplate() async {
    try {
      final bytes = _excel.buildTemplateBytes();
      downloadBytes(bytes, 'retailx_products_template.xlsx');
      if (mounted) {
        setState(() => _status = 'Template downloaded.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Could not create template: $e');
      }
    }
  }

  Future<void> _pickAndImport() async {
    setState(() {
      _loading = true;
      _status = null;
      _errors = [];
      _previewCount = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() {
          _loading = false;
          _status = 'Import cancelled.';
        });
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _loading = false;
          _status = 'Could not read the selected file.';
        });
        return;
      }

      final parsed = _excel.parseImportBytes(
        bytes,
        fileName: file.name,
      );

      if (!parsed.canImport) {
        setState(() {
          _loading = false;
          _errors = parsed.errors;
          _status = parsed.errors.isEmpty
              ? 'No valid products to import.'
              : 'Import rejected — fix the file and try again.';
        });
        return;
      }

      if (!context.mounted) return;
      final count = await context.read<PosStore>().importProductsBulk(
            parsed.rows.map((r) => r.product).toList(),
          );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _previewCount = count;
        _errors = [];
        _status = 'Imported $count product(s).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import products from Excel'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Any Excel workbook (.xlsx) is accepted. The header row must use '
              'these column names (order can differ; slight truncation like '
              '"purchase pric" is OK). Every product row must fill all columns — '
              'one missing value rejects the whole import.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              ProductExcelService.templateHeaders.join(' • '),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _downloadTemplate,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download template'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndImport,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_loading ? 'Importing…' : 'Choose Excel file'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                style: TextStyle(
                  color: _previewCount != null
                      ? AppTheme.success
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _errors
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
