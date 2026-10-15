import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_header.dart';

class CashiersScreen extends StatelessWidget {
  const CashiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final symbol = store.settings.currencySymbol;
    final cashiers = store.cashiers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Cashiers',
            subtitle: 'Create login accounts and review cashier performance.',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showCreateCashier(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Create cashier'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (cashiers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No cashiers yet.')),
              ),
            )
          else
            ...cashiers.map(
              (c) => _cashierTile(context, store, c, symbol),
            ),
        ],
      ),
    );
  }

  Widget _cashierTile(
    BuildContext context,
    PosStore store,
    AppUser cashier,
    String symbol,
  ) {
    final sales = store.salesForCashier(cashier.id);
    final revenue = store.revenueForSales(sales);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(cashier.name),
        subtitle: Text(
          '${cashier.email} • ${sales.length} sale(s) • ${AppFormatters.currency(revenue, symbol: symbol)}',
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _showCashierDetails(context, cashier),
              child: const Text('View data'),
            ),
            OutlinedButton(
              onPressed: () => _editCashier(context, cashier.id),
              child: const Text('Edit'),
            ),
            IconButton(
              tooltip: 'Delete cashier',
              onPressed: () => _deleteCashier(context, cashier),
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCashier(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create cashier'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => Validators.required(v, field: 'Password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: AppTheme.danger)),
                ],
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
                final err = await context.read<AuthProvider>().createCashier(
                      name: name.text.trim(),
                      email: email.text.trim(),
                      password: password.text,
                    );
                if (!ctx.mounted) return;
                if (err != null) {
                  setLocal(() => error = err);
                  return;
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCashier(BuildContext context, String userId) async {
    final store = context.read<PosStore>();
    final user = store.users.firstWhere((u) => u.id == userId);

    final auth = context.read<AuthProvider>();
    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit cashier'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final err = await auth.sendPasswordReset(user.email);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        err ?? 'Password reset email sent',
                      ),
                    ),
                  );
                },
                child: const Text('Send password reset email'),
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
              final err = await auth.updateUserProfile(
                user.copyWith(
                  name: name.text.trim(),
                  email: email.text.trim(),
                ),
              );
              if (!ctx.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(err)),
                );
                return;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCashier(BuildContext context, AppUser cashier) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete cashier',
      message:
          'Remove ${cashier.name}? Their past sales will remain in history.',
    );
    if (!ok || !context.mounted) return;

    final err = await context.read<PosStore>().deleteUser(cashier.id);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _showCashierDetails(BuildContext context, AppUser cashier) {
    final store = context.read<PosStore>();
    final symbol = store.settings.currencySymbol;
    final sales = store.salesForCashier(cashier.id);
    final revenue = store.revenueForSales(sales);

    final customerIds = <String>{};
    for (final s in sales) {
      if (s.customerId != null) customerIds.add(s.customerId!);
    }
    final customers = store.customers
        .where((c) => customerIds.contains(c.id))
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${cashier.name} — Performance'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${cashier.email}'),
                const SizedBox(height: 8),
                Text('Total sales: ${sales.length}'),
                Text(
                  'Revenue: ${AppFormatters.currency(revenue, symbol: symbol)}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Customers served',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (customers.isEmpty)
                  const Text('No customers yet.')
                else
                  ...customers.map(
                    (c) {
                      final cSales =
                          sales.where((s) => s.customerId == c.id).toList();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.phone} • ${cSales.length} purchase(s)',
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Recent sales',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (sales.isEmpty)
                  const Text('No sales yet.')
                else
                  ...sales.take(10).map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.receiptNumber),
                          subtitle: Text(
                            '${s.customerName ?? '—'} • ${AppFormatters.dateTime(s.createdAt)}',
                          ),
                          trailing: Text(
                            AppFormatters.currency(s.total, symbol: symbol),
                          ),
                        ),
                      ),
              ],
            ),
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
