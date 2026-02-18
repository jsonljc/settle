import 'package:flutter/material.dart';

class SettleBottomNavItem {
  const SettleBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
