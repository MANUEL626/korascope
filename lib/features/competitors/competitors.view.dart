import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../account/account.service.dart';
import 'competitors.service.dart';

class CompetitorsView extends StatefulWidget {
  final AccountService accountService;
  final ValueListenable<int> refreshSignal;
  final VoidCallback? onDataChanged;

  const CompetitorsView({
    super.key,
    required this.accountService,
    required this.refreshSignal,
    this.onDataChanged,
  });

  @override
  State<CompetitorsView> createState() => _CompetitorsViewState();
}

class _CompetitorsViewState extends State<CompetitorsView> {
  late final CompetitorsService service;
  String query = '';
  bool showSearch = false;
  String? loadedUserId;

  @override
  void initState() {
    super.initState();
    service = CompetitorsService(apiClient: widget.accountService.apiClient);
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
    _loadCompetitors(userId);
  }

  Future<void> _loadCompetitors(String userId) async {
    await service.loadForUser(userId);
    if (mounted) widget.onDataChanged?.call();
  }

  void _reloadFromExternalSignal() {
    final userId = loadedUserId ?? widget.accountService.profile?.id;
    if (userId == null || service.isLoading) return;
    loadedUserId = userId;
    _loadCompetitors(userId);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: service,
    builder: (context, _) {
      final activeResults = service
          .search(query)
          .where((competitor) => competitor.active)
          .toList(growable: false);
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
                                'Concurrents',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Vos concurrents actifs à surveiller.',
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
                          tooltip: 'Voir tous les concurrents',
                          onPressed: service.hasLoaded
                              ? _openAllCompetitors
                              : null,
                          icon: const Icon(Icons.format_list_bulleted_rounded),
                        ),
                      ],
                    ),
                    if (showSearch) ...[
                      const SizedBox(height: 14),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un concurrent actif…',
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
                        else if (activeResults.isEmpty)
                          const EmptyState(
                            title: 'Aucun concurrent actif',
                            message:
                                'Activez des concurrents depuis la liste complète pour les suivre ici.',
                          )
                        else
                          for (final competitor in activeResults)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CompetitorCard(competitor: competitor),
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

  Future<void> _openAllCompetitors() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AllCompetitorsPage(
          service: service,
          accountService: widget.accountService,
          userId: loadedUserId,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
  }
}

class _AllCompetitorsPage extends StatefulWidget {
  final CompetitorsService service;
  final AccountService accountService;
  final String? userId;
  final VoidCallback? onDataChanged;

  const _AllCompetitorsPage({
    required this.service,
    required this.accountService,
    required this.userId,
    this.onDataChanged,
  });

  @override
  State<_AllCompetitorsPage> createState() => _AllCompetitorsPageState();
}

class _AllCompetitorsPageState extends State<_AllCompetitorsPage> {
  String query = '';
  bool showSearch = false;
  bool isDiscovering = false;

  List<String> get currentInterests =>
      widget.accountService.profile?.interestDomains
          .map((domain) => domain.name)
          .toList(growable: false) ??
      const <String>[];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tous les concurrents'),
      actions: [
        IconButton(
          tooltip: showSearch ? 'Masquer la recherche' : 'Rechercher',
          onPressed: () {
            setState(() {
              showSearch = !showSearch;
              if (!showSearch) query = '';
            });
          },
          icon: Icon(showSearch ? Icons.close_rounded : Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Rechercher de nouvelles entreprises',
          onPressed: isDiscovering ? null : _confirmDiscover,
          icon: isDiscovering
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'Rafraîchir',
          onPressed: widget.userId == null || widget.service.isLoading
              ? null
              : _reloadCompetitors,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: widget.service,
      builder: (context, _) {
        final results = widget.service.search(query);
        return Column(
          children: [
            if (showSearch) ...[
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher dans tous les concurrents…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        children: [
                          if (widget.service.error != null &&
                              !_isActiveLimitError(widget.service.error!)) ...[
                            EmptyState(
                              title: 'Action impossible',
                              message: widget.service.error!,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (widget.service.isLoading &&
                              !widget.service.hasLoaded)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            )
                          else if (results.isEmpty)
                            const EmptyState(
                              title: 'Aucun concurrent',
                              message:
                                  'Aucun concurrent ne correspond à cette recherche.',
                            )
                          else
                            for (final competitor in results)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CompetitorCard(
                                  competitor: competitor,
                                  onActiveChanged: (active) =>
                                      _setCompetitorActive(competitor, active),
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
    ),
  );

  Future<void> _confirmDiscover() async {
    final profile = widget.accountService.profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil en cours de chargement. Réessayez dans un instant.',
          ),
        ),
      );
      return;
    }

    var interests = currentInterests;
    if (interests.isEmpty) {
      final added = await _showQuickInterestDialog();
      if (added != true || !mounted) return;
      interests = currentInterests;
      if (interests.isEmpty) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher de nouvelles entreprises ?'),
        content: Text(
          'KoraScope va rechercher de nouvelles entreprises à surveiller selon vos centres d’intérêt : ${interests.join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => isDiscovering = true);
    try {
      await widget.service.requestDiscovery(
        userId: profile.id,
        email: profile.email,
        interests: interests,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demande envoyée. Les nouveaux concurrents apparaîtront dès qu’ils seront disponibles.',
          ),
        ),
      );
      if (widget.userId != null) {
        await _reloadCompetitors();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Liste rafraîchie. La recherche continue en arrière-plan.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Une erreur est survenue. Impossible d’envoyer la demande pour le moment.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isDiscovering = false);
    }
  }

  Future<bool?> _showQuickInterestDialog() async {
    if (widget.accountService.availableDomains.isEmpty) {
      await widget.accountService.load();
    }
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          _QuickInterestDialog(service: widget.accountService),
    );
  }

  Future<void> _reloadCompetitors() async {
    final userId = widget.userId;
    if (userId == null) return;
    await widget.service.loadForUser(userId);
    if (mounted) widget.onDataChanged?.call();
  }

  Future<void> _setCompetitorActive(Competitor competitor, bool active) async {
    if (active && !competitor.active) {
      final limit = AppConfig.maxActiveCompetitors;
      if (widget.service.activeCount >= limit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limite atteinte : vous pouvez suivre maximum $limit concurrent(s) actif(s).',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }
    await widget.service.setActive(competitor, active);
    if (!mounted) return;
    if (widget.service.error != null &&
        _isActiveLimitError(widget.service.error!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.service.error!),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    if (mounted) widget.onDataChanged?.call();
  }

  bool _isActiveLimitError(String message) =>
      message.toLowerCase().contains('limite atteinte');
}

class _QuickInterestDialog extends StatefulWidget {
  final AccountService service;

  const _QuickInterestDialog({required this.service});

  @override
  State<_QuickInterestDialog> createState() => _QuickInterestDialogState();
}

class _QuickInterestDialogState extends State<_QuickInterestDialog> {
  final Set<String> selectedIds = {};
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final domains = widget.service.availableDomains;
    return AlertDialog(
      title: const Text('Choisir vos centres d’intérêt'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez au moins un domaine pour guider la recherche d’entreprises.',
            ),
            const SizedBox(height: 16),
            if (domains.isEmpty)
              const Text('Aucun domaine disponible pour le moment.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final domain in domains)
                    FilterChip(
                      label: Text(domain.name),
                      selected: selectedIds.contains(domain.id),
                      onSelected: isSaving
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  selectedIds.add(domain.id);
                                } else {
                                  selectedIds.remove(domain.id);
                                }
                              });
                            },
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: selectedIds.isEmpty || isSaving ? null : _save,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continuer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    final selectedDomains = widget.service.availableDomains
        .where((domain) => selectedIds.contains(domain.id))
        .toList(growable: false);
    var saved = true;
    for (final domain in selectedDomains) {
      saved = await widget.service.toggleDomain(domain) && saved;
    }
    if (!mounted) return;
    Navigator.pop(context, saved);
  }
}

class _CompetitorCard extends StatelessWidget {
  final Competitor competitor;
  final ValueChanged<bool>? onActiveChanged;

  const _CompetitorCard({required this.competitor, this.onActiveChanged});

  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _openDetails(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: competitor.active
                    ? const Color(0xFFE8F0FF)
                    : const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.business_rounded,
                color: competitor.active ? AppColors.blue : AppColors.muted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          competitor.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onActiveChanged == null)
                        _StatusPill(active: competitor.active),
                    ],
                  ),
                  if (competitor.website.isNotEmpty)
                    _ExternalLink(
                      label: competitor.website,
                      url: competitor.website,
                      fontSize: 12,
                    ),
                  Text(
                    competitor.sector,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (competitor.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      competitor.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (competitor.github != null &&
                      competitor.github!.isNotEmpty)
                    _ExternalLink(
                      label: competitor.github!,
                      url: competitor.github!,
                      fontSize: 12,
                      muted: true,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (onActiveChanged == null)
              _ScoreBlock(competitor: competitor)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(value: competitor.active, onChanged: onActiveChanged),
                  Text(
                    competitor.active ? 'ACTIF' : 'INACTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: competitor.active ? Colors.green : AppColors.muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openDetails(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CompetitorDetailsSheet(competitor: competitor),
  );
}

class _CompetitorDetailsSheet extends StatelessWidget {
  final Competitor competitor;

  const _CompetitorDetailsSheet({required this.competitor});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .68,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: competitor.active
                        ? const Color(0xFFE8F0FF)
                        : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: competitor.active ? AppColors.blue : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        competitor.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (competitor.website.isEmpty)
                        Text(
                          competitor.sector,
                          style: const TextStyle(color: AppColors.muted),
                        )
                      else
                        _ExternalLink(
                          label: competitor.website,
                          url: competitor.website,
                          muted: true,
                        ),
                    ],
                  ),
                ),
                _StatusPill(active: competitor.active),
              ],
            ),
            const Divider(height: 28),
            const Text(
              'Note d’analyse',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  competitor.description ??
                      'Aucune note disponible pour ce concurrent pour le moment. '
                          'Une analyse pourra être ajoutée prochainement pour vous aider à décider s’il mérite d’être suivi.',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (competitor.github != null &&
                competitor.github!.isNotEmpty) ...[
              _ExternalLink(
                label: 'Voir le GitHub',
                url: competitor.github!,
                icon: Icons.code_rounded,
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(competitor.sector)),
                Chip(label: Text('Score ${competitor.score}')),
                Chip(label: Text(competitor.active ? 'Actif' : 'Inactif')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExternalLink extends StatelessWidget {
  final String label;
  final String url;
  final double? fontSize;
  final bool muted;
  final IconData? icon;

  const _ExternalLink({
    required this.label,
    required this.url,
    this.fontSize,
    this.muted = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _open(context),
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.blue),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted ? AppColors.muted : AppColors.blue,
                fontSize: fontSize,
                fontWeight: icon == null ? FontWeight.w500 : FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: muted ? AppColors.muted : AppColors.blue,
              ),
            ),
          ),
          if (icon == null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new_rounded,
              size: fontSize == null ? 15 : fontSize! + 2,
              color: muted ? AppColors.muted : AppColors.blue,
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _open(BuildContext context) async {
    final uri = _parseUrl(url);
    if (uri == null) {
      _showError(context);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) _showError(context);
  }

  Uri? _parseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized = RegExp(r'^https?://', caseSensitive: false).hasMatch(
      trimmed,
    )
        ? trimmed
        : 'https://$trimmed';
    return Uri.tryParse(normalized);
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d’ouvrir ce lien.')),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;

  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFDDF8E8) : const Color(0xFFE9ECF2),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      active ? 'ACTIF' : 'INACTIF',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: active ? Colors.green.shade700 : AppColors.muted,
      ),
    ),
  );
}

class _ScoreBlock extends StatelessWidget {
  final Competitor competitor;

  const _ScoreBlock({required this.competitor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        '${competitor.score}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.blue,
        ),
      ),
      const Text(
        'SCORE',
        style: TextStyle(fontSize: 9, color: AppColors.muted),
      ),
      Text(
        '${competitor.growth >= 0 ? '+' : ''}${competitor.growth.toStringAsFixed(1)}%',
        style: TextStyle(
          color: competitor.growth >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
