import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/purchase_record.dart';
import '../../models/supplier.dart';
import '../../services/pos_store.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_header.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final symbol = store.settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Suppliers',
            subtitle: 'Vendor contacts and stock purchases.',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showSupplierForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Supplier'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: store.suppliers.isEmpty
                  ? const EmptyState(message: 'No suppliers yet.')
                  : ListView.separated(
                      itemCount: store.suppliers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = store.suppliers[i];
                        final purchases = store.purchasesForSupplier(s.id);
                        return ExpansionTile(
                          title: Text(s.name),
                          subtitle: Text(
                            '${s.contactPerson} • ${s.phone}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.email),
                                  Text(s.address),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _showSupplierForm(
                                          context,
                                          supplier: s,
                                        ),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _showPurchaseForm(
                                          context,
                                          supplierId: s.id,
                                        ),
                                        icon: const Icon(Icons.inventory, size: 16),
                                        label: const Text('Add stock purchase'),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () async {
                                          final ok = await confirmDialog(
                                            context,
                                            title: 'Delete supplier',
                                            message: 'Remove ${s.name}?',
                                          );
                                          if (ok && context.mounted) {
                                            store.deleteSupplier(s.id);
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  if (purchases.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Recent purchases',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ...purchases.take(5).map(
                                          (p) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              AppFormatters.dateTime(p.createdAt),
                                            ),
                                            subtitle: Text(
                                              '${p.items.length} line(s) • ${p.note}',
                                            ),
                                            trailing: Text(
                                              AppFormatters.currency(
                                                p.total,
                                                symbol: symbol,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSupplierForm(
    BuildContext context, {
    Supplier? supplier,
  }) async {
    final isEdit = supplier != null;
    final name = TextEditingController(text: supplier?.name ?? '');
    final contact = TextEditingController(text: supplier?.contactPerson ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final email = TextEditingController(text: supplier?.email ?? '');
    final address = TextEditingController(text: supplier?.address ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Supplier name'),
                    validator: (v) => Validators.required(v, field: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contact,
                    decoration: const InputDecoration(labelText: 'Contact person'),
                    validator: (v) =>
                        Validators.required(v, field: 'Contact person'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => Validators.required(v, field: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (v) => Validators.required(v, field: 'Address'),
                  ),
                ],
              ),
            ),
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
              final store = context.read<PosStore>();
              if (isEdit) {
                store.updateSupplier(
                  supplier.copyWith(
                    name: name.text.trim(),
                    contactPerson: contact.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    address: address.text.trim(),
                  ),
                );
              } else {
                store.addSupplier(
                  Supplier(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name.text.trim(),
                    contactPerson: contact.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    address: address.text.trim(),
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

  Future<void> _showPurchaseForm(
    BuildContext context, {
    required String supplierId,
  }) async {
    final store = context.read<PosStore>();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? productId = store.products.isNotEmpty ? store.products.first.id : null;
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController();
    final lines = <PurchaseLineItem>[];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Record purchase'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: productId,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: store.products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => productId = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Unit cost',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        if (productId == null) return;
                        final qty = int.tryParse(qtyController.text);
                        final cost = double.tryParse(costController.text);
                        if (qty == null || qty <= 0 || cost == null) return;
                        final product = store.productById(productId!)!;
                        lines.add(
                          PurchaseLineItem(
                            productId: product.id,
                            productName: product.name,
                            quantity: qty,
                            unitCost: cost,
                          ),
                        );
                        qtyController.text = '1';
                        costController.clear();
                        setLocal(() {});
                      },
                      child: const Text('Add line'),
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...lines.asMap().entries.map(
                            (e) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(e.value.productName),
                              subtitle: Text(
                                '${e.value.quantity} × ${e.value.unitCost}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  lines.removeAt(e.key);
                                  setLocal(() {});
                                },
                              ),
                            ),
                          ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Note'),
                      validator: (v) => Validators.required(v, field: 'Note'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (lines.isEmpty || !formKey.currentState!.validate()) return;
                context.read<PosStore>().recordPurchase(
                      supplierId: supplierId,
                      items: List.from(lines),
                      note: noteController.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save purchase'),
            ),
          ],
        ),
      ),
    );
  }
}
