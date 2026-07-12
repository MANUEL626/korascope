import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../account/account.service.dart';
import 'reports.service.dart';

class ReportsView extends StatefulWidget {
  final AccountService accountService;
  final ValueListenable<int> refreshSignal;
  final VoidCallback? onDataChanged;

  const ReportsView({
    super.key,
    required this.accountService,
    required this.refreshSignal,
    this.onDataChanged,
  });

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late final ReportsService service;
  String query = '';
  bool showSearch = false;
  String? loadedUserId;

  @override
  void initState() {
    super.initState();
    service = ReportsService(apiClient: widget.accountService.apiClient);
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
    _loadReports(userId);
  }

  Future<void> _loadReports(String userId) async {
    await service.loadForUser(userId);
    if (mounted) widget.onDataChanged?.call();
  }

  void _reloadFromExternalSignal() {
    final userId = loadedUserId ?? widget.accountService.profile?.id;
    if (userId == null || service.isLoading) return;
    loadedUserId = userId;
    _loadReports(userId);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: service,
    builder: (context, _) {
      final reports = service.search(query);
      return Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rapports',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Consultez les rapports générés pour votre compte.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: showSearch
                              ? 'Masquer la recherche'
                              : 'Rechercher',
                          onPressed: () {
                            setState(() {
                              showSearch = !showSearch;
                              if (!showSearch) query = '';
                            });
                          },
                          icon: Icon(
                            showSearch
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Rafraîchir les rapports',
                          onPressed: loadedUserId == null || service.isLoading
                              ? null
                              : () => _loadReports(loadedUserId!),
                          icon: service.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    if (showSearch) ...[
                      const SizedBox(height: 14),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un rapport…',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      children: [
                        if (service.error != null) ...[
                          EmptyState(
                            title: 'Chargement impossible',
                            message: service.error!,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (service.isLoading && !service.hasLoaded)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          )
                        else if (reports.isEmpty)
                          const EmptyState(
                            title: 'Aucun rapport',
                            message:
                                'Aucun rapport ne correspond à cette recherche.',
                          )
                        else
                          for (final report in reports)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReportCard(
                                report: report,
                                onOpen: () => _openReport(report),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Future<void> _openReport(WatchReport report) async {
    WatchReport selected = report;
    try {
      selected = await service.getById(report.id);
    } catch (_) {
      // La liste contient déjà assez d'informations pour rester consultable.
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ReportDetails(report: selected),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final WatchReport report;
  final VoidCallback onOpen;

  const _ReportCard({required this.report, required this.onOpen});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    report.date,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (report.isNew)
              const Chip(
                label: Text('NOUVEAU'),
                side: BorderSide.none,
                backgroundColor: Color(0xFFDDF8E8),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(report.summary.isEmpty ? 'Rapport disponible.' : report.summary),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Consulter'),
          ),
        ),
      ],
    ),
  );
}

class _ReportDetails extends StatelessWidget {
  final WatchReport report;

  const _ReportDetails({required this.report});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(report.date, style: const TextStyle(color: AppColors.muted)),
            const Divider(height: 28),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  report.plainTextContent.isEmpty
                      ? 'Ce rapport ne contient pas encore de contenu.'
                      : report.plainTextContent,
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
