import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../account/account.service.dart';
import 'home.service.dart';

class HomeView extends StatefulWidget {
  final AccountService accountService;
  final ValueListenable<int> refreshSignal;

  const HomeView({
    super.key,
    required this.accountService,
    required this.refreshSignal,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeService service;
  String? loadedUserId;

  @override
  void initState() {
    super.initState();
    service = HomeService(apiClient: widget.accountService.apiClient);
    widget.accountService.addListener(_loadWhenProfileIsReady);
    widget.refreshSignal.addListener(_reloadFromExternalSignal);
    _loadWhenProfileIsReady();
  }

  @override
  void dispose() {
    widget.accountService.removeListener(_loadWhenProfileIsReady);
    widget.refreshSignal.removeListener(_reloadFromExternalSignal);
    service.dispose();
    super.dispose();
  }

  void _loadWhenProfileIsReady() {
    final userId = widget.accountService.profile?.id;
    if (userId == null) return;
    if (userId == loadedUserId && (service.hasLoaded || service.isLoading)) {
      return;
    }
    loadedUserId = userId;
    service.loadForUser(userId);
  }

  Future<void> _refresh() async {
    final userId = loadedUserId;
    if (userId == null) return;
    await service.loadForUser(userId);
    await widget.accountService.load();
  }

  void _reloadFromExternalSignal() {
    final userId = loadedUserId;
    if (userId == null || service.isLoading) return;
    service.loadForUser(userId);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([service, widget.accountService]),
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 760;
      final profile = widget.accountService.profile;
      final interestCount = profile?.interestDomains.length ?? 0;
      final metrics = service.metrics(interestCount);
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vue d’ensemble',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _subtitle(profile?.fullName),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    if (service.error != null) ...[
                      EmptyState(
                        title: 'Vue indisponible',
                        message: service.error!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: wide ? 1.05 : .95,
                      ),
                      itemBuilder: (context, index) => _MetricCard(
                        metric: metrics[index],
                        icon: const [
                          Icons.remove_red_eye_outlined,
                          Icons.pause_circle_outline_rounded,
                          Icons.description_outlined,
                          Icons.interests_rounded,
                        ][index],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PriorityPanel(message: service.priorityMessage),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _CoveragePanel(
                              active: service.activeCompetitors,
                              total: service.totalCompetitors,
                              reports: service.reportCount,
                              interests: interestCount,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _ActivityPanel(
                              activities: service.activities,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _CoveragePanel(
                        active: service.activeCompetitors,
                        total: service.totalCompetitors,
                        reports: service.reportCount,
                        interests: interestCount,
                      ),
                      const SizedBox(height: 16),
                      _ActivityPanel(activities: service.activities),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  String _subtitle(String? fullName) {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) {
      return 'Synthèse de votre veille concurrentielle.';
    }
    return 'Bonjour $name, voici l’état actuel de votre veille.';
  }
}

class _MetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final IconData icon;

  const _MetricCard({required this.metric, required this.icon});

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: metric.attention
                    ? const Color(0xFFFFF3F2)
                    : const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: metric.attention ? Colors.red : AppColors.blue,
                size: 21,
              ),
            ),
            const Spacer(),
            if (metric.attention)
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 18,
              ),
          ],
        ),
        const Spacer(),
        Text(
          metric.value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        Text(
          metric.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric.hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _PriorityPanel extends StatelessWidget {
  final String message;

  const _PriorityPanel({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0FF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFC7D7FE)),
    ),
    child: Row(
      children: [
        const Icon(Icons.insights_rounded, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CoveragePanel extends StatelessWidget {
  final int active;
  final int total;
  final int reports;
  final int interests;

  const _CoveragePanel({
    required this.active,
    required this.total,
    required this.reports,
    required this.interests,
  });

  @override
  Widget build(BuildContext context) {
    final coverage = total == 0 ? 0.0 : active / total;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Couverture de veille',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: coverage,
              minHeight: 12,
              backgroundColor: const Color(0xFFE9ECF2),
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            total == 0
                ? 'Aucun concurrent configuré.'
                : '$active concurrent(s) actif(s) sur $total.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '$reports rapport(s) disponible(s) • $interests centre(s) d’intérêt.',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  final List<MarketActivity> activities;

  const _ActivityPanel({required this.activities});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Derniers signaux',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Les rapports et concurrents actifs apparaîtront ici.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          for (final item in activities)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                item.badge,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      ],
    ),
  );
}
