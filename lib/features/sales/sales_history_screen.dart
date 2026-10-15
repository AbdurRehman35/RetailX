import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/formatters.dart';
import '../../services/pos_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_header.dart';
import '../pos/receipt_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _search = '';
  PaymentMethod? _paymentFilter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final symbol = store.settings.currencySymbol;

    var sales = store.sales.toList();
    if (_paymentFilter != null) {
      sales = sales.where((s) => s.paymentMethod == _paymentFilter).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      sales = sales
          .where(
            (s) =>
                s.receiptNumber.toLowerCase().contains(q) ||
                (s.customerName?.toLowerCase().contains(q) ?? false) ||
                s.cashierName.toLowerCase().contains(q),
          )
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Sales History',
            subtitle: 'Browse past transactions and receipts.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search receipt, customer, cashier...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod?>(
                  value: _paymentFilter,
                  decoration: const InputDecoration(labelText: 'Payment'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...PaymentMethod.values.map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.label),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _paymentFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: sales.isEmpty
                  ? const EmptyState(message: 'No sales found.')
                  : ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final sale = sales[i];
                        return ListTile(
                          title: Text(sale.receiptNumber),
                          subtitle: Text(
                            '${AppFormatters.dateTime(sale.createdAt)} • ${sale.paymentMethod.label} • ${sale.items.length} item(s)${sale.customerName != null ? ' • ${sale.customerName}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppFormatters.currency(
                                  sale.total,
                                  symbol: symbol,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.receipt_outlined),
                                tooltip: 'View receipt',
                                onPressed: () =>
                                    showReceiptDialog(context, sale),
                              ),
                            ],
                          ),
                          onTap: () => _showDetail(context, sale),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, sale) {
    final store = context.read<PosStore>();
    final symbol = store.settings.currencySymbol;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sale ${sale.receiptNumber}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${AppFormatters.dateTime(sale.createdAt)}'),
                Text('Cashier: ${sale.cashierName}'),
                Text('Payment: ${sale.paymentMethod.label}'),
                if (sale.customerName != null) ...[
                  Text('Customer: ${sale.customerName}'),
                  if (sale.customerPhone != null)
                    Text('Phone: ${sale.customerPhone}'),
                ],
                const Divider(height: 24),
                ...sale.items.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${line.productName} × ${line.quantity}',
                          ),
                        ),
                        Text(
                          AppFormatters.currency(
                            line.lineTotal,
                            symbol: symbol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Text(
                  'Total: ${AppFormatters.currency(sale.total, symbol: symbol)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              showReceiptDialog(context, sale);
            },
            child: const Text('Receipt'),
          ),
        ],
      ),
    );
  }
}
