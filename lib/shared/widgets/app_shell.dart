import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/sync/local_sync.service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/account/account.service.dart';
import '../../features/account/account.view.dart';
import '../../features/competitors/competitors.service.dart';
import '../../features/auth/auth.service.dart';
import '../../features/competitors/competitors.view.dart';
import '../../features/home/home.view.dart';
import '../../features/reports/reports.view.dart';
import 'common_widgets.dart';

class AppShell extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignOut;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.authService,
    required this.onSignOut,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int index;
  late final AccountService accountService;
  late final ValueNotifier<int> homeRefreshSignal;
  late final ValueNotifier<int> competitorsRefreshSignal;
  late final ValueNotifier<int> reportsRefreshSignal;
  late final CompetitorsService competitorLimitService;
  bool _checkingLocalSync = false;
  bool _checkingCompetitorLimit = false;
  bool _competitorLimitDialogOpen = false;
  String? _competitorLimitCheckedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    index = widget.initialIndex;
    homeRefreshSignal = ValueNotifier<int>(0);
    competitorsRefreshSignal = ValueNotifier<int>(0);
    reportsRefreshSignal = ValueNotifier<int>(0);
    accountService = AccountService(apiClient: widget.authService.apiClient)
      ..load();
    competitorLimitService = CompetitorsService(
      apiClient: widget.authService.apiClient,
    );
    accountService.addListener(_runDueLocalSync);
    accountService.addListener(_checkActiveCompetitorLimit);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    accountService.removeListener(_runDueLocalSync);
    accountService.removeListener(_checkActiveCompetitorLimit);
    competitorLimitService.dispose();
    homeRefreshSignal.dispose();
    competitorsRefreshSignal.dispose();
    reportsRefreshSignal.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSessionAndRunDueLocalSync();
    }
  }

  static const items = [
    (Icons.grid_view_rounded, 'Accueil'),
    (Icons.track_changes_rounded, 'Concurrents'),
    (Icons.description_outlined, 'Rapports'),
    (Icons.person_outline_rounded, 'Compte'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(
        accountService: accountService,
        refreshSignal: homeRefreshSignal,
      ),
      CompetitorsView(
        accountService: accountService,
        refreshSignal: competitorsRefreshSignal,
        onDataChanged: _refreshHomeOverview,
      ),
      ReportsView(
        accountService: accountService,
        refreshSignal: reportsRefreshSignal,
        onDataChanged: _refreshHomeOverview,
      ),
      AccountView(
        service: accountService,
        onSignOut: widget.onSignOut,
        onProfileCompleted: widget.authService.markProfileCompleted,
        autoOpenProfileCompletion: widget.authService.isNewUser,
      ),
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
                  AnimatedBuilder(
                    animation: accountService,
                    builder: (context, _) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD8E5FF),
                        child: Text(
                          _initials(accountService.profile?.fullName),
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        accountService.profile?.fullName ?? 'Mon compte',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        accountService.profile?.accountType ?? 'Chargement…',
                      ),
                      onTap: () => setState(() => index = 3),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.line),
            Expanded(child: _content(pages)),
          ],
        ),
      );
    }
    return Scaffold(
      body: _content(pages),
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

  Widget _content(List<Widget> pages) => Column(
    children: [
      AnimatedBuilder(
        animation: accountService,
        builder: (context, _) => AppTopBar(
          fullName: accountService.profile?.fullName,
          profileUrl: accountService.profile?.profileUrl,
          onProfile: () => setState(() => index = 3),
        ),
      ),
      const Divider(height: 1, color: AppColors.line),
      Expanded(
        child: IndexedStack(index: index, children: pages),
      ),
    ],
  );

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) return '?';
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  void _refreshHomeOverview() {
    homeRefreshSignal.value++;
  }

  Future<void> _runDueLocalSync() async {
    if (_checkingLocalSync || accountService.profile == null) return;
    _checkingLocalSync = true;
    try {
      final plan = await LocalSyncService.instance.consumeDueSyncs();
      if (!plan.hasWork) return;
      if (plan.competitors) {
        competitorsRefreshSignal.value++;
      }
      if (plan.reports) {
        reportsRefreshSignal.value++;
      }
      homeRefreshSignal.value++;
    } finally {
      _checkingLocalSync = false;
    }
  }

  Future<void> _validateSessionAndRunDueLocalSync() async {
    final isValid = await widget.authService.validateCurrentSessionIfDue();
    if (!isValid || !mounted) return;
    await _runDueLocalSync();
  }

  Future<void> _checkActiveCompetitorLimit() async {
    final userId = accountService.profile?.id;
    if (userId == null ||
        _checkingCompetitorLimit ||
        _competitorLimitDialogOpen ||
        _competitorLimitCheckedUserId == userId) {
      return;
    }
    _checkingCompetitorLimit = true;
    try {
      await competitorLimitService.loadForUser(userId);
      _competitorLimitCheckedUserId = userId;
      if (!mounted) return;
      final limit = AppConfig.maxActiveCompetitors;
      if (competitorLimitService.activeCount <= limit) return;
      _competitorLimitDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ActiveCompetitorLimitDialog(
          service: competitorLimitService,
          limit: limit,
        ),
      );
      if (!mounted) return;
      competitorsRefreshSignal.value++;
      homeRefreshSignal.value++;
    } finally {
      _checkingCompetitorLimit = false;
      _competitorLimitDialogOpen = false;
    }
  }
}

class _ActiveCompetitorLimitDialog extends StatelessWidget {
  final CompetitorsService service;
  final int limit;

  const _ActiveCompetitorLimitDialog({
    required this.service,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: service,
    builder: (context, _) {
      final activeCompetitors = service.competitors
          .where((item) => item.active)
          .toList(growable: false);
      final overflow = (activeCompetitors.length - limit).clamp(0, 999);
      final canContinue = overflow == 0;

      return PopScope(
        canPop: canContinue,
        child: AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: const Text('Limite de concurrents actifs atteinte'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre compte autorise maximum $limit concurrent(s) actif(s). '
                  'Désactivez encore $overflow concurrent(s) pour continuer.',
                ),
                const SizedBox(height: 14),
                if (service.error != null) ...[
                  Text(
                    service.error!,
                    style: const TextStyle(color: Color(0xFFD92D20)),
                  ),
                  const SizedBox(height: 10),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeCompetitors.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, index) {
                      final competitor = activeCompetitors[index];
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: competitor.active,
                        onChanged: service.isLoading
                            ? null
                            : (value) => service.setActive(competitor, value),
                        title: Text(
                          competitor.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          competitor.website.isEmpty
                              ? competitor.sector
                              : competitor.website,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                if (service.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: canContinue ? () => Navigator.pop(context) : null,
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    },
  );
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
