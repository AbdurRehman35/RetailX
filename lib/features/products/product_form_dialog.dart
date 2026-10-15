import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../models/product.dart';
import '../../services/pos_store.dart';

Future<void> showProductFormDialog(
  BuildContext context, {
  Product? product,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _ProductFormDialog(product: product),
  );
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _purchase;
  late final TextEditingController _selling;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _purchase = TextEditingController(
      text: p?.purchasePrice.toString() ?? '',
    );
    _selling = TextEditingController(
      text: p?.sellingPrice.toString() ?? '',
    );
    _stock = TextEditingController(
      text: isEdit ? p!.currentStock.toString() : '',
    );
    _minStock = TextEditingController(
      text: p?.minimumStock.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _category.dispose();
    _purchase.dispose();
    _selling.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<PosStore>();

    if (isEdit) {
      await store.updateProduct(
        widget.product!.copyWith(
          name: _name.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          purchasePrice: double.parse(_purchase.text),
          sellingPrice: double.parse(_selling.text),
          currentStock: int.parse(_stock.text),
          minimumStock: int.parse(_minStock.text),
        ),
      );
    } else {
      await store.addProduct(
        Product(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: _name.text.trim(),
          description: _description.text.trim(),
          category: _category.text.trim(),
          purchasePrice: double.parse(_purchase.text),
          sellingPrice: double.parse(_selling.text),
          currentStock: int.parse(_stock.text),
          minimumStock: int.parse(_minStock.text),
          createdAt: DateTime.now(),
        ),
      );
    }
    if (context.mounted) Navigator.pop(context);
  }

  Widget _fieldPair({
    required bool narrow,
    required Widget first,
    required Widget second,
  }) {
    if (narrow) {
      return Column(
        children: [
          first,
          const SizedBox(height: 12),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final narrow = MediaQuery.sizeOf(context).width < 520;

    return AlertDialog(
      scrollable: true,
      title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: narrow ? MediaQuery.sizeOf(context).width * 0.9 : 480,
          maxHeight: maxHeight,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) => Validators.required(v, field: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => Validators.required(v, field: 'Category'),
              ),
              const SizedBox(height: 12),
              _fieldPair(
                narrow: narrow,
                first: TextFormField(
                  controller: _purchase,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Purchase price',
                  ),
                  validator: (v) => Validators.positiveNumber(
                    v,
                    field: 'Purchase price',
                  ),
                ),
                second: TextFormField(
                  controller: _selling,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Selling price',
                  ),
                  validator: (v) => Validators.positiveNumber(
                    v,
                    field: 'Selling price',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldPair(
                narrow: narrow,
                first: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Current stock' : 'Initial stock',
                  ),
                  validator: (v) => Validators.positiveInt(v, field: 'Stock'),
                ),
                second: TextFormField(
                  controller: _minStock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum stock',
                  ),
                  validator: (v) =>
                      Validators.positiveInt(v, field: 'Minimum stock'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
