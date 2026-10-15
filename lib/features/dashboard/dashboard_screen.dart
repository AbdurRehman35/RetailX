import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_store.dart';
import '../../widgets/dimensional/scene_3d.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosStore>();
    final user = context.watch<AuthProvider>().currentUser;
    final symbol = store.settings.currencySymbol;
    final chartData = store.last7DaysSales();
    final maxY = chartData.isEmpty
        ? 100.0
        : (chartData.reduce((a, b) => a > b ? a : b) * 1.2).clamp(50, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryDeep,
                  AppTheme.primary,
                  AppTheme.primaryLight,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxWidth < 640;
                final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back${user != null ? ', ${user.name.split(' ').first}' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Store overview',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track sales, stock, and performance in one place.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    children: [
                      text,
                      const SizedBox(height: 8),
                      const Scene3D(
                        kind: Scene3DKind.register,
                        size: 120,
                        primary: Colors.white,
                        accent: AppTheme.accentSoft,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: text),
                    const Scene3D(
                      kind: Scene3DKind.register,
                      size: 130,
                      primary: Colors.white,
                      accent: AppTheme.accentSoft,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1100
                  ? 4
                  : c.maxWidth > 700
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: cols == 1 ? 2.8 : 2.2,
                children: [
                  StatCard(
                    title: "Today's Sales",
                    value: AppFormatters.currency(
                      store.todaySalesTotal(),
                      symbol: symbol,
                    ),
                    icon: Icons.payments_outlined,
                    iconColor: AppTheme.success,
                  ),
                  StatCard(
                    title: "Today's Orders",
                    value: '${store.todayOrdersCount()}',
                    icon: Icons.receipt_outlined,
                    iconColor: AppTheme.accent,
                  ),
                  StatCard(
                    title: 'Total Products',
                    value: '${store.products.length}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  StatCard(
                    title: 'Low Stock Items',
                    value: '${store.lowStockCount()}',
                    icon: Icons.warning_amber_outlined,
                    iconColor: AppTheme.warning,
                    subtitle: 'At or below minimum level',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales — Last 7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY.toDouble(),
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
                              reservedSize: 48,
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
                              getTitlesWidget: (v, _) {
                                final day = DateTime.now()
                                    .subtract(Duration(days: 6 - v.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('E').format(day),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(7, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartData[i],
                                width: 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.accent,
                                  ],
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
            ),
          ),
          if (store.products.any((p) => p.isLowStock)) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Low Stock Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...store.products.where((p) => p.isLowStock).map(
                          (p) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.name),
                            subtitle: Text(
                              'Stock: ${p.currentStock} (min ${p.minimumStock})',
                            ),
                            trailing: const Icon(
                              Icons.warning_amber,
                              color: AppTheme.warning,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
