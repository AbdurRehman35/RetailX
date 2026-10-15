import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/empty_state.dart';
import 'receipt_dialog.dart';

enum _PosStep { selectItems, checkout }

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  _PosStep _step = _PosStep.selectItems;
  PaymentMethod _payment = PaymentMethod.cash;
  final _discountController = TextEditingController(text: '0');
  final _cashController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _discountController.dispose();
    _cashController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  int _qtyInCart(PosStore store, String productId) {
    for (final item in store.cart) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  void _goToCheckout(PosStore store) {
    if (store.cart.isEmpty) return;
    setState(() {
      _step = _PosStep.checkout;
      _error = null;
    });
  }

  Future<void> _complete(PosStore store, AuthProvider auth) async {
    setState(() => _error = null);
    final discount = double.tryParse(_discountController.text) ?? 0;
    store.setCartDiscount(discount);

    double? received;
    if (_payment == PaymentMethod.cash) {
      received = double.tryParse(_cashController.text);
      if (received == null) {
        setState(() => _error = 'Enter amount received');
        return;
      }
    }

    final sale = await store.completeSale(
      paymentMethod: _payment,
      cashierName: auth.currentUser!.name,
      cashierId: auth.currentUser!.id,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      amountReceived: received,
    );

    if (sale == null) {
      setState(
        () => _error = 'Unable to complete sale. Check cart and payment.',
      );
      return;
    }

    _discountController.text = '0';
    _cashController.clear();
    _customerNameController.clear();
    _customerPhoneController.clear();
    setState(() => _step = _PosStep.selectItems);
    showReceiptDialog(context, sale);
  }

  Widget _stepIndicator(PosStore store) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _stepTile(
              index: 1,
              label: 'Select items',
              active: _step == _PosStep.selectItems,
              done: _step == _PosStep.checkout,
              onTap: () => setState(() => _step = _PosStep.selectItems),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
            _stepTile(
              index: 2,
              label: 'Checkout',
              active: _step == _PosStep.checkout,
              done: false,
              onTap: store.cart.isEmpty
                  ? null
                  : () => _goToCheckout(store),
              enabled: store.cart.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile({
    required int index,
    required String label,
    required bool active,
    required bool done,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final color = active
        ? AppTheme.primary
        : done
            ? AppTheme.success
            : AppTheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active
                    ? AppTheme.primary
                    : done
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.border,
                child: done
                    ? const Icon(Icons.check, size: 16, color: AppTheme.success)
                    : Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: enabled ? color : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectItemsStep({
    required PosStore store,
    required String symbol,
    required List<Product> products,
    required double total,
    required BoxConstraints constraints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search products by name or category...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: store.setCartSearch,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: products.isEmpty
                ? const EmptyState(message: 'No products match your search.')
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = products[i];
                      final inCart = _qtyInCart(store, p.id);
                      return ListTile(
                        title: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${p.category} • Stock: ${p.currentStock}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormatters.currency(
                                p.sellingPrice,
                                symbol: symbol,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (inCart > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$inCart in cart',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppTheme.primary,
                              tooltip: 'Add to cart',
                              onPressed: () => store.addToCart(p),
                            ),
                          ],
                        ),
                        onTap: () => store.addToCart(p),
                      );
                    },
                  ),
          ),
        ),
        if (store.cart.isNotEmpty) ...[
          const SizedBox(height: 12),
          _selectedItemsPanel(store: store, symbol: symbol),
        ],
        const SizedBox(height: 12),
        _selectItemsBottomBar(store: store, symbol: symbol, total: total),
      ],
    );
  }

  Widget _selectedItemsPanel({
    required PosStore store,
    required String symbol,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selected items',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: store.cart.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = store.cart[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.product.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.quantity} × ${AppFormatters.currency(item.product.sellingPrice, symbol: symbol)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.currency(
                            item.lineTotal,
                            symbol: symbol,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          tooltip: 'Remove one',
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppTheme.danger,
                            size: 22,
                          ),
                          onPressed: () {
                            store.updateCartQuantity(
                              item.product.id,
                              item.quantity - 1,
                            );
                            if (store.cart.isEmpty) {
                              setState(() => _step = _PosStep.selectItems);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectItemsBottomBar({
    required PosStore store,
    required String symbol,
    required double total,
  }) {
    final itemCount =
        store.cart.fold<int>(0, (sum, item) => sum + item.quantity);

    return Card(
      color: AppTheme.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemCount == 0
                        ? 'No items selected'
                        : '$itemCount item${itemCount == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(total, symbol: symbol),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: store.cart.isEmpty ? null : () => store.clearCart(),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: store.cart.isEmpty ? null : () => _goToCheckout(store),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSelector({required double maxWidth}) {
    if (maxWidth < 300) {
      return DropdownButtonFormField<PaymentMethod>(
        initialValue: _payment,
        decoration: const InputDecoration(labelText: 'Payment method'),
        items: PaymentMethod.values
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(m.label),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _payment = v);
        },
      );
    }

    return SegmentedButton<PaymentMethod>(
      segments: PaymentMethod.values
          .map(
            (m) => ButtonSegment(
              value: m,
              label: Text(m.label),
            ),
          )
          .toList(),
      selected: {_payment},
      onSelectionChanged: (s) => setState(() => _payment = s.first),
    );
  }

  Widget _cartLineItem({
    required CartItem item,
    required String symbol,
    required PosStore store,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  AppFormatters.currency(
                    item.product.sellingPrice,
                    symbol: symbol,
                  ),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const Spacer(),
                _compactIconButton(
                  icon: Icons.remove,
                  onPressed: () {
                    store.updateCartQuantity(
                      item.product.id,
                      item.quantity - 1,
                    );
                    if (store.cart.isEmpty) {
                      setState(() => _step = _PosStep.selectItems);
                    }
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                _compactIconButton(
                  icon: Icons.add,
                  onPressed: () => store.updateCartQuantity(
                    item.product.id,
                    item.quantity + 1,
                  ),
                ),
              _compactIconButton(
                icon: Icons.remove_circle_outline,
                color: AppTheme.danger,
                onPressed: () {
                  store.updateCartQuantity(
                    item.product.id,
                    item.quantity - 1,
                  );
                  if (store.cart.isEmpty) {
                    setState(() => _step = _PosStep.selectItems);
                  }
                },
              ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line: ${AppFormatters.currency(item.lineTotal, symbol: symbol)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCheckoutStep({
    required PosStore store,
    required AuthProvider auth,
    required String symbol,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double? change,
    required double maxWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _step = _PosStep.selectItems),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to items'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review cart, payment, and complete the sale.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ...store.cart.map(
                      (item) => _cartLineItem(
                        item: item,
                        symbol: symbol,
                        store: store,
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Customer details (optional)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'If provided, the customer is saved when the sale completes.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Customer name (optional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Customer phone (optional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Discount ($symbol)',
                              ),
                              onChanged: (v) {
                                store.setCartDiscount(
                                  double.tryParse(v) ?? 0,
                                );
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
                            _totalRow('Subtotal', subtotal, symbol),
                            _totalRow('Discount', discount, symbol),
                            _totalRow(
                              'Tax (${store.settings.taxRatePercent}%)',
                              tax,
                              symbol,
                            ),
                            const Divider(height: 24),
                            _totalRow('Total', total, symbol, bold: true),
                            const SizedBox(height: 16),
                            const Text(
                              'Payment method',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _paymentSelector(maxWidth: maxWidth),
                            if (_payment == PaymentMethod.cash) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _cashController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount received ($symbol)',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              if (change != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Change: ${AppFormatters.currency(change, symbol: symbol)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.danger),
                              ),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _complete(store, auth),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Complete Sale'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalRow(
    String label,
    double amount,
    String symbol, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            AppFormatters.currency(amount, symbol: symbol),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final auth = context.watch<AuthProvider>();
    final symbol = store.settings.currencySymbol;
    final products = store.productsForPos();

    final subtotal = store.cartSubtotal;
    final discount = store.cartDiscount;
    final tax = store.cartTaxAmount();
    final total = store.cartTotal();

    double? change;
    if (_payment == PaymentMethod.cash) {
      final received = double.tryParse(_cashController.text);
      if (received != null && received >= total) {
        change = received - total;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final checkoutMaxWidth = constraints.maxWidth.clamp(320.0, 560.0);

          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stepIndicator(store),
                const SizedBox(height: 16),
                Expanded(
                  child: _step == _PosStep.selectItems
                      ? _buildSelectItemsStep(
                          store: store,
                          symbol: symbol,
                          products: products,
                          total: total,
                          constraints: constraints,
                        )
                      : _buildCheckoutStep(
                          store: store,
                          auth: auth,
                          symbol: symbol,
                          subtotal: subtotal,
                          discount: discount,
                          tax: tax,
                          total: total,
                          change: change,
                          maxWidth: checkoutMaxWidth,
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
