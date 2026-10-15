import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/low_stock_badge.dart';
import '../../widgets/page_header.dart';
import 'product_form_dialog.dart';
import 'product_import_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final isAdmin = context.watch<AuthProvider>().role == UserRole.admin;
    final symbol = store.settings.currencySymbol;

    var list = store.products.toList();
    if (_category != null && _category!.isNotEmpty) {
      list = list.where((p) => p.category == _category).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Products',
            subtitle: 'Manage catalog, pricing, and stock levels.',
            actions: [
              if (isAdmin) ...[
                OutlinedButton.icon(
                  onPressed: () => showProductImportDialog(context),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Import Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => showProductFormDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 560;
              final search = TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or category...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              );
              final categoryFilter = DropdownButtonFormField<String?>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...store.categories.map(
                    (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v),
              );
              if (stacked) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 12),
                    categoryFilter,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: search),
                  const SizedBox(width: 12),
                  Expanded(child: categoryFilter),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: list.isEmpty
                  ? const EmptyState(message: 'No products found.')
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final table = DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Cost')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: list.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(p.name),
                                      if (p.isLowStock) ...[
                                        const SizedBox(height: 4),
                                        LowStockBadge(isLow: true),
                                      ],
                                    ],
                                  ),
                                ),
                                DataCell(Text(p.category)),
                                DataCell(
                                  Text(
                                    p.description.isEmpty ? '—' : p.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(
                                  AppFormatters.currency(
                                    p.purchasePrice,
                                    symbol: symbol,
                                  ),
                                )),
                                DataCell(Text(
                                  AppFormatters.currency(
                                    p.sellingPrice,
                                    symbol: symbol,
                                  ),
                                )),
                                DataCell(Text('${p.currentStock}')),
                                DataCell(
                                  Row(
                                    children: [
                                      if (isAdmin) ...[
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () =>
                                              showProductFormDialog(
                                            context,
                                            product: p,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.danger,
                                          ),
                                          onPressed: () async {
                                            final ok = await confirmDialog(
                                              context,
                                              title: 'Delete product',
                                              message:
                                                  'Remove "${p.name}" from catalog?',
                                            );
                                            if (ok && context.mounted) {
                                              store.deleteProduct(p.id);
                                            }
                                          },
                                        ),
                                      ] else
                                        const Text(
                                          'View only',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        );

                        return Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            primary: false,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              primary: false,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: table,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
