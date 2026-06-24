import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/account/account.view.dart';
import '../../features/auth/auth.service.dart';
import '../../features/competitors/competitors.view.dart';
import '../../features/home/home.view.dart';
import '../../features/reports/reports.view.dart';
import 'common_widgets.dart';

class AppShell extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignOut;
  const AppShell({
    super.key,
    required this.authService,
    required this.onSignOut,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const items = [
    (Icons.grid_view_rounded, 'Accueil'),
    (Icons.track_changes_rounded, 'Concurrents'),
    (Icons.description_outlined, 'Rapports'),
    (Icons.person_outline_rounded, 'Compte'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeView(),
      const CompetitorsView(),
      const ReportsView(),
      AccountView(onSignOut: widget.onSignOut),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 880;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 240,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Brand(),
                  const SizedBox(height: 38),
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NavTile(
                        icon: items[i].$1,
                        label: items[i].$2,
                        active: index == i,
                        onTap: () => setState(() => index = i),
                      ),
                    ),
                  const Spacer(),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFD8E5FF),
                      child: Text(
                        'AK',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      'Ama Koffi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Plan Pro'),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.line),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.$1, color: AppColors.ink),
              selectedIcon: Icon(item.$1, color: Colors.white),
              label: item.$2,
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: active ? const Color(0xFFE8F0FF) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: active ? AppColors.blue : AppColors.muted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.blue : AppColors.muted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
