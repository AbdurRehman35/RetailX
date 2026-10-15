import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale.dart';
import '../../services/pos_store.dart';

Future<void> showReceiptDialog(BuildContext context, Sale sale) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReceiptDialog(sale: sale),
  );
}

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final s = store.settings;
    final symbol = s.currencySymbol;

    return AlertDialog(
      title: const Text('Receipt'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.storeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sale.receiptNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                AppFormatters.dateTime(sale.createdAt),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 24),
              ...sale.items.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${line.productName}\n${line.quantity} × ${AppFormatters.currency(line.unitPrice, symbol: symbol)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        AppFormatters.currency(line.lineTotal, symbol: symbol),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
              _line('Subtotal', sale.subtotal, symbol),
              if (sale.discount > 0)
                _line('Discount', -sale.discount, symbol),
              _line('Tax', sale.tax, symbol),
              const SizedBox(height: 8),
              _line('Total', sale.total, symbol, bold: true),
              const SizedBox(height: 8),
              Text(
                'Payment: ${sale.paymentMethod.label}',
                style: const TextStyle(fontSize: 13),
              ),
              if (sale.paymentMethod == PaymentMethod.cash &&
                  sale.amountReceived != null) ...[
                _line('Received', sale.amountReceived!, symbol),
                _line('Change', sale.changeGiven ?? 0, symbol),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sale.customerName ?? '—',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (sale.customerPhone != null)
                      Text(
                        sale.customerPhone!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cashier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sale.cashierName,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.receiptFooter,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _line(String label, double amount, String symbol, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
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
}
