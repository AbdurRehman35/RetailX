import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/sales_trend_point.dart';
import '../../services/pos_store.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stat_card.dart';

enum _ReportRange { daily, weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportRange _range = _ReportRange.weekly;

  (DateTime, DateTime) _datesForRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_range) {
      _ReportRange.daily => (today, today),
      _ReportRange.weekly => (
          today.subtract(const Duration(days: 6)),
          today,
        ),
      _ReportRange.monthly => (
          DateTime(now.year, now.month, 1),
          today,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final symbol = store.settings.currencySymbol;
    final (start, end) = _datesForRange();
    final sales = store.salesInRange(start, end);
    final revenue = store.revenueForSales(sales);
    final profit = store.estimatedProfitForSales(sales);
    final top = store.topSellingProductsInRange(start, end);
    final trend = store.salesTrendForRange(
      start,
      end,
      hourly: _range == _ReportRange.daily,
    );
    final payments = store.revenueByPaymentMethod(sales);
    final stockByCategory = store.stockUnitsByCategory();

    final totalStock =
        store.products.fold<int>(0, (s, p) => s + p.currentStock);
    final inventoryValue = store.products.fold<double>(
      0,
      (s, p) => s + p.purchasePrice * p.currentStock,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Reports',
            subtitle: 'Sales performance and inventory summary.',
            actions: [
              SegmentedButton<_ReportRange>(
                segments: const [
                  ButtonSegment(
                    value: _ReportRange.daily,
                    label: Text('Daily'),
                  ),
                  ButtonSegment(
                    value: _ReportRange.weekly,
                    label: Text('Weekly'),
                  ),
                  ButtonSegment(
                    value: _ReportRange.monthly,
                    label: Text('Monthly'),
                  ),
                ],
                selected: {_range},
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppFormatters.date(start)} — ${AppFormatters.date(end)}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900 ? 3 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.8 : 2.4,
                children: [
                  StatCard(
                    title: 'Total revenue',
                    value: AppFormatters.currency(revenue, symbol: symbol),
                    icon: Icons.trending_up,
                    iconColor: AppTheme.success,
                    subtitle: '${sales.length} orders',
                  ),
                  StatCard(
                    title: 'Estimated profit',
                    value: AppFormatters.currency(profit, symbol: symbol),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppTheme.accent,
                  ),
                  StatCard(
                    title: 'Inventory value (at cost)',
                    value: AppFormatters.currency(
                      inventoryValue,
                      symbol: symbol,
                    ),
                    icon: Icons.warehouse_outlined,
                    subtitle: '$totalStock units in stock',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final revenueChart = _RevenueProfitChart(
                trend: trend,
                symbol: symbol,
                title: _range == _ReportRange.daily
                    ? 'Revenue & profit by hour'
                    : 'Revenue & profit trend',
              );
              final paymentChart = _PaymentPieChart(
                payments: payments,
                symbol: symbol,
              );

              if (stacked) {
                return Column(
                  children: [
                    revenueChart,
                    const SizedBox(height: 16),
                    paymentChart,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: revenueChart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: paymentChart),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final topChart = _TopProductsBarChart(top: top);
              final stockChart = _CategoryStockChart(categories: stockByCategory);

              if (stacked) {
                return Column(
                  children: [
                    topChart,
                    const SizedBox(height: 16),
                    stockChart,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: topChart),
                  const SizedBox(width: 16),
                  Expanded(child: stockChart),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.height = 280});

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

class _RevenueProfitChart extends StatelessWidget {
  const _RevenueProfitChart({
    required this.trend,
    required this.symbol,
    required this.title,
  });

  final List<SalesTrendPoint> trend;
  final String symbol;
  final String title;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = trend.fold<double>(
      0,
      (m, p) => p.revenue > m ? p.revenue : m,
    );
    final maxProfit = trend.fold<double>(
      0,
      (m, p) => p.profit > m ? p.profit : m,
    );
    final maxY = (maxRevenue > maxProfit ? maxRevenue : maxProfit);
    final chartMax = maxY <= 0
        ? 100.0
        : (maxY * 1.25).clamp(20.0, double.infinity).toDouble();

    final showEvery = trend.length > 14 ? (trend.length / 7).ceil() : 1;

    return _ChartCard(
      title: title,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _LegendDot(color: AppTheme.primary, label: 'Revenue'),
              SizedBox(width: 16),
              _LegendDot(color: AppTheme.success, label: 'Profit'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: trend.every((p) => p.revenue == 0 && p.profit == 0)
          ? const Center(
              child: Text(
                'No sales in this period.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : BarChart(
              BarChartData(
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '$symbol${v.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % showEvery != 0 && i != trend.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            trend[i].label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(trend.length, (i) {
                  final p = trend[i];
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: p.revenue,
                        color: AppTheme.primary,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: p.profit,
                        color: AppTheme.success,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PaymentPieChart extends StatelessWidget {
  const _PaymentPieChart({
    required this.payments,
    required this.symbol,
  });

  final Map<PaymentMethod, double> payments;
  final String symbol;

  static const _colors = [
    AppTheme.primary,
    AppTheme.accent,
    AppTheme.success,
  ];

  @override
  Widget build(BuildContext context) {
    final total = payments.values.fold<double>(0, (s, v) => s + v);
    final entries = PaymentMethod.values
        .map((m) => MapEntry(m, payments[m] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    return _ChartCard(
      title: 'Revenue by payment method',
      height: 300,
      child: total <= 0
          ? const Center(
              child: Text(
                'No payment data in this period.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: List.generate(entries.length, (i) {
                        final e = entries[i];
                        final pct = (e.value / total * 100);
                        return PieChartSectionData(
                          value: e.value,
                          color: _colors[i % _colors.length],
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 72,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(entries.length, (i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colors[i % _colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              AppFormatters.currency(e.value, symbol: symbol),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopProductsBarChart extends StatelessWidget {
  const _TopProductsBarChart({required this.top});

  final List<MapEntry<String, int>> top;

  @override
  Widget build(BuildContext context) {
    final maxY = top.isEmpty
        ? 10.0
        : (top.first.value * 1.2).clamp(5, double.infinity).toDouble();

    return _ChartCard(
      title: 'Top selling products',
      height: 260,
      child: top.isEmpty
          ? const Center(
              child: Text(
                'No product sales in this period.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= top.length) {
                          return const SizedBox.shrink();
                        }
                        final name = top[i].key;
                        final short = name.length > 10
                            ? '${name.substring(0, 10)}…'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(top.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: top[i].value.toDouble(),
                        color: AppTheme.accent,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }
}

class _CategoryStockChart extends StatelessWidget {
  const _CategoryStockChart({required this.categories});

  final Map<String, int> categories;

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxY = entries.isEmpty
        ? 10.0
        : (entries.first.value * 1.2).clamp(5, double.infinity).toDouble();

    return _ChartCard(
      title: 'Inventory by category (units)',
      height: 260,
      child: entries.isEmpty
          ? const Center(
              child: Text(
                'No inventory data.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final name = entries[i].key;
                        final short = name.length > 8
                            ? '${name.substring(0, 8)}…'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value.toDouble(),
                        color: AppTheme.warning,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }
}
