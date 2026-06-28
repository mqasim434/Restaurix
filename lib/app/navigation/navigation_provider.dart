import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_role.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Sidebar expanded state — session-only UI preference (not persisted to Isar).
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

class NavItem {
  const NavItem({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}

final navigationItemsProvider = Provider<List<NavItem>>((ref) {
  final role = ref.watch(currentUserProvider).role;

  return switch (role) {
    UserRole.admin => _adminNavItems,
    UserRole.salesman => _salesmanNavItems,
  };
});

const _salesmanNavItems = [
  NavItem(label: 'Dashboard', path: '/dashboard', icon: Icons.dashboard_outlined),
  NavItem(label: 'New Order', path: '/sales', icon: Icons.point_of_sale_outlined),
  NavItem(label: 'Orders', path: '/orders', icon: Icons.receipt_long_outlined),
  NavItem(label: 'Tables', path: '/tables', icon: Icons.table_restaurant_outlined),
  NavItem(
    label: 'Kitchen Status',
    path: '/kitchen',
    icon: Icons.restaurant_menu_outlined,
  ),
];

const _adminNavItems = [
  NavItem(label: 'Dashboard', path: '/dashboard', icon: Icons.dashboard_outlined),
  NavItem(label: 'Sales (POS)', path: '/sales', icon: Icons.point_of_sale_outlined),
  NavItem(label: 'Orders', path: '/orders', icon: Icons.receipt_long_outlined),
  NavItem(
    label: 'Kitchen',
    path: '/kitchen',
    icon: Icons.restaurant_menu_outlined,
  ),
  NavItem(label: 'Products', path: '/products', icon: Icons.inventory_2_outlined),
  NavItem(label: 'Categories', path: '/categories', icon: Icons.category_outlined),
  NavItem(label: 'Deals', path: '/deals', icon: Icons.local_offer_outlined),
  NavItem(label: 'Tables', path: '/tables', icon: Icons.table_restaurant_outlined),
  NavItem(label: 'Employees', path: '/employees', icon: Icons.people_outline_rounded),
  NavItem(
    label: 'Attendance',
    path: '/attendance',
    icon: Icons.fingerprint_outlined,
  ),
  NavItem(
    label: 'Salary',
    path: '/salary',
    icon: Icons.payments_outlined,
  ),
  NavItem(label: 'Reports', path: '/reports', icon: Icons.bar_chart_rounded),
  NavItem(label: 'Analytics', path: '/analytics', icon: Icons.insights_outlined),
  NavItem(label: 'Settings', path: '/settings', icon: Icons.settings_outlined),
  NavItem(label: 'Users', path: '/users', icon: Icons.manage_accounts_outlined),
];
