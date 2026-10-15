import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_header.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final isAdmin = context.watch<AuthProvider>().role == UserRole.admin;
    final symbol = store.settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Customers',
            subtitle: isAdmin
                ? 'Manage customer records and purchase history.'
                : 'View customers created from completed sales.',
            actions: [
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Customer'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: store.customers.isEmpty
                  ? const EmptyState(message: 'No customers yet.')
                  : ListView.separated(
                      itemCount: store.customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = store.customers[i];
                        final history = store.salesForCustomer(c.id);
                        final spent = history.fold<double>(
                          0,
                          (s, sale) => s + sale.total,
                        );
                        return ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.phone} • ${history.length} purchase(s) • ${AppFormatters.currency(spent, symbol: symbol)} total',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history),
                                tooltip: 'Purchase history',
                                onPressed: () => _showHistory(
                                  context,
                                  c,
                                  history,
                                  symbol,
                                ),
                              ),
                              if (isAdmin) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showForm(context, customer: c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final ok = await confirmDialog(
                                      context,
                                      title: 'Delete customer',
                                      message: 'Remove ${c.name}?',
                                    );
                                    if (ok && context.mounted) {
                                      store.deleteCustomer(c.id);
                                    }
                                  },
                                ),
                              ],
                            ],
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

  Future<void> _showForm(BuildContext context, {Customer? customer}) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = customer != null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => Validators.required(v, field: 'Phone'),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final store = context.read<PosStore>();
              if (isEdit) {
                await store.updateCustomer(
                  customer.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  ),
                );
              } else {
                await store.addCustomer(
                  Customer(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showHistory(
    BuildContext context,
    Customer customer,
    List<Sale> history,
    String symbol,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${customer.name} — Purchases'),
        content: SizedBox(
          width: 440,
          child: history.isEmpty
              ? const Text('No purchases yet.')
              : ListView(
                  shrinkWrap: true,
                  children: history
                      .map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.receiptNumber),
                          subtitle: Text(
                            '${AppFormatters.dateTime(s.createdAt)}\nCashier: ${s.cashierName}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            AppFormatters.currency(
                              s.total,
                              symbol: symbol,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
