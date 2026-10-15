import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/low_stock_badge.dart';
import '../../widgets/page_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final isAdmin =
        context.watch<AuthProvider>().role == UserRole.admin;
    var products = store.products.toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Inventory',
              subtitle: 'Stock levels, adjustments, and movement history.',
            ),
            const SizedBox(height: 16),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'Stock levels'),
                Tab(text: 'Movement history'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _StockTab(
                    products: products,
                    search: _search,
                    onSearch: (v) => setState(() => _search = v),
                    canAdjustStock: isAdmin,
                  ),
                  _HistoryTab(movements: store.stockMovements),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockTab extends StatelessWidget {
  const _StockTab({
    required this.products,
    required this.search,
    required this.onSearch,
    required this.canAdjustStock,
  });

  final List<Product> products;
  final String search;
  final ValueChanged<String> onSearch;
  final bool canAdjustStock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search inventory...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: products.isEmpty
                ? const EmptyState(message: 'No inventory items found.')
                : ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ListTile(
                        title: Row(
                          children: [
                            Text(p.name),
                            const SizedBox(width: 8),
                            if (p.isLowStock) const LowStockBadge(isLow: true),
                          ],
                        ),
                        subtitle: Text(
                          '${p.category} • Min: ${p.minimumStock}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${p.currentStock}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: p.isLowStock
                                    ? AppTheme.warning
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (canAdjustStock)
                              IconButton(
                                tooltip: 'Add stock',
                                icon: const Icon(Icons.add_box_outlined),
                                onPressed: () =>
                                    _showAddStock(context, p.id, p.name),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddStock(
    BuildContext context,
    String productId,
    String name,
  ) async {
    final qtyController = TextEditingController();
    final noteController = TextEditingController(text: 'Manual adjustment');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add stock — $name'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity to add'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Reference / note'),
                validator: (v) => Validators.required(v, field: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              context.read<PosStore>().addStock(
                    productId: productId,
                    quantity: int.parse(qtyController.text),
                    reference: noteController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const Card(
        child: EmptyState(message: 'No stock movements yet.'),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: movements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = movements[i];
          final change = m.quantityChange;
          final isPositive = change >= 0;
          return ListTile(
            title: Text(m.productName),
            subtitle: Text(
              '${m.type.label} • ${m.reference} • ${AppFormatters.dateTime(m.createdAt)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}$change',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isPositive ? AppTheme.success : AppTheme.danger,
                  ),
                ),
                Text(
                  'After: ${m.stockAfter}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
