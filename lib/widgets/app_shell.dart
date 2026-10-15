import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/cashiers/cashiers_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/pos/pos_screen.dart';
import '../features/products/products_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/sales_history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/suppliers/suppliers_screen.dart';
import '../core/constants/enums.dart';
import '../providers/auth_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavSection _section = NavSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final canUsePos = auth.canAccess(NavSection.pos);

    final items = _navItems(auth);
    if (!items.any((i) => i.section == _section)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _section = NavSection.dashboard);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final body = _buildBody();

        if (!wide) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titleFor(_section)),
              actions: [
                IconButton(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
            ),
            drawer: Drawer(
              child: _SidebarContent(
                items: items,
                selected: _section,
                userName: user.name,
                userRole: user.role.label,
                onSelect: (s) {
                  setState(() => _section = s);
                  Navigator.pop(context);
                },
                onLogout: auth.logout,
              ),
            ),
            body: body,
            floatingActionButton: canUsePos && _section != NavSection.pos
                ? FloatingActionButton.extended(
                    onPressed: () => setState(() => _section = NavSection.pos),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('New Sale'),
                  )
                : null,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 260,
                child: _SidebarContent(
                  items: items,
                  selected: _section,
                  userName: user.name,
                  userRole: user.role.label,
                  onSelect: (s) => setState(() => _section = s),
                  onLogout: auth.logout,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 68,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          bottom: BorderSide(color: AppTheme.border),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _titleFor(_section),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          if (canUsePos && _section != NavSection.pos)
                            OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _section = NavSection.pos),
                              icon: const Icon(Icons.point_of_sale, size: 18),
                              label: const Text('New Sale'),
                            ),
                          if (canUsePos && _section != NavSection.pos)
                            const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      AppTheme.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return switch (_section) {
      NavSection.dashboard => const DashboardScreen(),
      NavSection.products => const ProductsScreen(),
      NavSection.pos => const PosScreen(),
      NavSection.inventory => const InventoryScreen(),
      NavSection.sales => const SalesHistoryScreen(),
      NavSection.customers => const CustomersScreen(),
      NavSection.cashiers => const CashiersScreen(),
      NavSection.suppliers => const SuppliersScreen(),
      NavSection.reports => const ReportsScreen(),
      NavSection.settings => const SettingsScreen(),
    };
  }

  List<_NavItem> _navItems(AuthProvider auth) {
    const all = [
      _NavItem(NavSection.dashboard, 'Dashboard', Icons.dashboard_outlined),
      _NavItem(NavSection.pos, 'New Sale', Icons.point_of_sale_outlined),
      _NavItem(NavSection.products, 'Products', Icons.inventory_2_outlined),
      _NavItem(NavSection.inventory, 'Inventory', Icons.warehouse_outlined),
      _NavItem(NavSection.sales, 'Sales History', Icons.receipt_long_outlined),
      _NavItem(NavSection.customers, 'Customers', Icons.people_outline),
      _NavItem(NavSection.cashiers, 'Cashiers', Icons.badge_outlined),
      _NavItem(NavSection.suppliers, 'Suppliers', Icons.local_shipping_outlined),
      _NavItem(NavSection.reports, 'Reports', Icons.bar_chart_outlined),
      _NavItem(NavSection.settings, 'Settings', Icons.settings_outlined),
    ];
    return all.where((i) => auth.canAccess(i.section)).toList();
  }

  String _titleFor(NavSection section) => switch (section) {
        NavSection.dashboard => 'Dashboard',
        NavSection.products => 'Products',
        NavSection.pos => 'Point of Sale',
        NavSection.inventory => 'Inventory',
        NavSection.sales => 'Sales History',
        NavSection.customers => 'Customers',
        NavSection.cashiers => 'Cashiers',
        NavSection.suppliers => 'Suppliers',
        NavSection.reports => 'Reports',
        NavSection.settings => 'Settings',
      };
}

class _NavItem {
  const _NavItem(this.section, this.label, this.icon);
  final NavSection section;
  final String label;
  final IconData icon;
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.items,
    required this.selected,
    required this.userName,
    required this.userRole,
    required this.onSelect,
    required this.onLogout,
  });

  final List<_NavItem> items;
  final NavSection selected;
  final String userName;
  final String userRole;
  final ValueChanged<NavSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDeep,
            AppTheme.primary,
            Color(0xFF1C4A73),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RetailX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Point of Sale',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items.map((item) {
                final isSelected = item.section == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onSelect(item.section),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.72),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.85),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentSoft,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  userRole,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
