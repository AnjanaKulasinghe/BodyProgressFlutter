import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:body_progress/core/design_system.dart';
import 'package:body_progress/core/router.dart';

/// The main tab bar shell — equivalent to iOS MainTabView.
/// Wraps all 5 tabs: Home, Photos, Stats, Progress, Settings.
/// Uses StatefulShellRoute for optimal performance and state preservation.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({required this.navigationShell, super.key});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,          activeIcon: Icons.home,              label: 'Home'),
    _TabItem(icon: Icons.photo_library_outlined,  activeIcon: Icons.photo_library,     label: 'Photos'),
    _TabItem(icon: Icons.straighten_outlined,     activeIcon: Icons.straighten,        label: 'Stats'),
    _TabItem(icon: Icons.show_chart_outlined,     activeIcon: Icons.show_chart,        label: 'Progress'),
    _TabItem(icon: Icons.settings_outlined,       activeIcon: Icons.settings,          label: 'Settings'),
  ];

  void _onTabTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = navigationShell.currentIndex == i;
                return GestureDetector(
                  onTap: () => _onTabTap(context, i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            key: ValueKey(isActive),
                            color: isActive ? AppColors.brandPrimary : AppColors.textTertiary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? AppColors.brandPrimary : AppColors.textTertiary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}
