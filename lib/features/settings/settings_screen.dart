import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/validators.dart';
import '../../models/store_settings.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/page_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeFormKey = GlobalKey<FormState>();
  late TextEditingController _storeName;
  late TextEditingController _currency;
  late TextEditingController _tax;
  late TextEditingController _footer;

  @override
  void initState() {
    super.initState();
    final s = context.read<PosStore>().settings;
    _storeName = TextEditingController(text: s.storeName);
    _currency = TextEditingController(text: s.currencySymbol);
    _tax = TextEditingController(text: s.taxRatePercent.toString());
    _footer = TextEditingController(text: s.receiptFooter);
  }

  @override
  void dispose() {
    _storeName.dispose();
    _currency.dispose();
    _tax.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<void> _saveStoreSettings() async {
    if (!_storeFormKey.currentState!.validate()) return;
    final store = context.read<PosStore>();
    await store.updateSettings(
      StoreSettings(
        storeName: _storeName.text.trim(),
        currencySymbol: _currency.text.trim(),
        taxRatePercent: double.parse(_tax.text),
        receiptFooter: _footer.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final admins =
        store.users.where((u) => u.role == UserRole.admin).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Store configuration and administrator profile.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _storeFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store & tax',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeName,
                      decoration: const InputDecoration(
                        labelText: 'Store name',
                      ),
                      validator: (v) =>
                          Validators.required(v, field: 'Store name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Currency symbol',
                            ),
                            validator: (v) =>
                                Validators.required(v, field: 'Currency'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tax,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tax rate (%)',
                            ),
                            validator: (v) => Validators.positiveNumber(
                              v,
                              field: 'Tax rate',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _footer,
                      decoration: const InputDecoration(
                        labelText: 'Receipt footer message',
                      ),
                      validator: (v) =>
                          Validators.required(v, field: 'Receipt footer'),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveStoreSettings,
                        child: const Text('Save settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Administrators',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...admins.map(
                    (u) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(u.name),
                      subtitle: Text('${u.email} • ${u.role.label}'),
                      trailing: OutlinedButton(
                        onPressed: () => _editAdmin(context, u.id),
                        child: const Text('Edit'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAdmin(BuildContext context, String userId) async {
    final user =
        context.read<PosStore>().users.firstWhere((u) => u.id == userId);
    final auth = context.read<AuthProvider>();

    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit admin'),
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
}
