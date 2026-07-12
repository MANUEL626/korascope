import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/notifications/local_notification.service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../competitors/competitors.service.dart';
import 'account.service.dart';

class AccountView extends StatefulWidget {
  final AccountService service;
  final VoidCallback onSignOut;
  final VoidCallback onProfileCompleted;
  final bool autoOpenProfileCompletion;

  const AccountView({
    super.key,
    required this.service,
    required this.onSignOut,
    required this.onProfileCompleted,
    this.autoOpenProfileCompletion = false,
  });

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  AccountService get service => widget.service;

  bool _profileCompletionOpened = false;
  bool _phoneRemindersEnabled = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _loadAppVersion();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (service.isLoading) {
          return const SizedBox(
            height: 500,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (service.profile == null) return _errorState();
        if (widget.autoOpenProfileCompletion && !_profileCompletionOpened) {
          _profileCompletionOpened = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && service.profile != null) {
              _editProfile(completingProfile: true);
            }
          });
        }

        final profile = service.profile!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon compte',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            if (service.error != null) ...[
              _ErrorBanner(message: service.error!),
              const SizedBox(height: 14),
            ],
            Panel(
              child: Row(
                children: [
                  _ProfileAvatar(profile: profile),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName?.isNotEmpty == true
                              ? profile.fullName!
                              : 'Complétez votre profil',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          profile.accountType,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Modifier le profil',
                    onPressed: service.isSaving ? null : _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Préférences',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.interests_rounded,
                    title: 'Domaines d’intérêt',
                    subtitle: _interestSummary(profile),
                    onTap: service.isSaving ? null : _editInterests,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aide',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Comment utiliser KoraScope',
                    subtitle:
                        'Comprendre les concurrents, les rapports et les rappels.',
                    onTap: _openHelp,
                  ),
                  _SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Contacter l’assistance',
                    subtitle: 'Envoyer un message si vous avez besoin d’aide.',
                    onTap: _contactSupport,
                  ),
                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.red,
                    title: 'Supprimer mon compte',
                    subtitle:
                        'Ouvrir la page de suppression de compte.',
                    titleColor: Colors.red,
                    onTap: _requestAccountDeletion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SettingsSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Rappels sur téléphone',
                    subtitle:
                        'Rappels locaux pour relancer une recherche ou vérifier les nouveaux concurrents.',
                    value: _phoneRemindersEnabled,
                    onChanged: _setPhoneRemindersEnabled,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      'Les notifications email ne sont pas encore disponibles.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    key: const Key('sign_out'),
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: 'Se déconnecter',
                    subtitle: 'Quitter cette session sur ce téléphone.',
                    titleColor: Colors.red,
                    onTap: _confirmSignOut,
                  ),
                ],
              ),
            ),
            if (_appVersion.isNotEmpty) ...[
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'KoraScope v$_appVersion',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _errorState() => Column(
    children: [
      const SizedBox(height: 60),
      EmptyState(
        title: 'Profil indisponible',
        message: service.error ?? 'Impossible de charger votre profil.',
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: service.load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Réessayer'),
      ),
    ],
  );

  String _interestSummary(UserProfile profile) {
    final domains = profile.interestDomains;
    if (domains.isEmpty) return 'Aucun domaine sélectionné';
    if (domains.length <= 3) return domains.map((item) => item.name).join(', ');
    return '${domains.take(3).map((item) => item.name).join(', ')} +${domains.length - 3}';
  }

  Future<void> _loadNotificationPreference() async {
    final enabled =
        await LocalNotificationService.instance.arePhoneRemindersEnabled();
    if (!mounted) return;
    setState(() => _phoneRemindersEnabled = enabled);
  }

  Future<void> _setPhoneRemindersEnabled(bool value) async {
    setState(() => _phoneRemindersEnabled = value);
    await LocalNotificationService.instance.setPhoneRemindersEnabled(value);
  }

  Future<void> _loadAppVersion() async {
    final version = await _resolveAppVersion();
    if (!mounted) return;
    setState(() => _appVersion = version);
  }

  Future<void> _editInterests() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _InterestsSheet(service: service),
    );
  }

  Future<void> _openHelp() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _HelpSheet(),
    );
  }

  Future<void> _contactSupport() async {
    final version = _appVersion.isEmpty
        ? await _resolveAppVersion()
        : _appVersion;
    if (_appVersion.isEmpty && mounted) {
      setState(() => _appVersion = version);
    }
    final subject = Uri.encodeComponent('Assistance KoraScope');
    final body = Uri.encodeComponent(
      'Bonjour,\n\n'
      'J’ai besoin d’aide concernant KoraScope.\n\n'
      'Version : $version\n',
    );
    final uri = Uri.parse(
      'mailto:adaptimate@gmail.com?subject=$subject&body=$body',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir votre application email.'),
        ),
      );
    }
  }

  Future<void> _requestAccountDeletion() async {
    final uri = Uri.parse('https://korascope.adaptimate.org/app/delete-account');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la page de suppression.'),
        ),
      );
    }
  }

  Future<String> _resolveAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'non disponible';
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez demander un nouveau code par email pour vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onSignOut();
  }

  Future<void> _editProfile({bool completingProfile = false}) async {
    final profile = service.profile!;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !completingProfile,
      builder: (_) => _EditProfileDialog(
        service: service,
        profile: profile,
        completingProfile: completingProfile,
      ),
    );
    if (saved != true || !mounted) return;
    if (!completingProfile) {
      widget.onProfileCompleted();
      return;
    }
    final guideCompleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FirstRunGuideDialog(service: service),
    );
    if (guideCompleted == true) widget.onProfileCompleted();
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _InterestsSheet extends StatelessWidget {
  final AccountService service;

  const _InterestsSheet({required this.service});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: AnimatedBuilder(
          animation: service,
          builder: (context, _) {
            final profile = service.profile;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Domaines d’intérêt',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez les sujets qui orientent la recherche de concurrents et les rapports.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                if (service.error != null) ...[
                  _ErrorBanner(message: service.error!),
                  const SizedBox(height: 12),
                ],
                if (service.availableDomains.isEmpty)
                  const Expanded(
                    child: Center(child: Text('Aucun domaine disponible.')),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final domain in service.availableDomains)
                            FilterChip(
                              label: Text(domain.name),
                              selected:
                                  profile?.interestDomains.any(
                                    (item) => item.id == domain.id,
                                  ) ??
                                  false,
                              onSelected: service.isSaving
                                  ? null
                                  : (_) => service.toggleDomain(domain),
                              tooltip: domain.description,
                            ),
                        ],
                      ),
                    ),
                  ),
                if (service.isSaving) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .86,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comment utiliser KoraScope',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'KoraScope vous aide à garder un œil sur votre marché sans devoir tout vérifier manuellement.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                children: const [
                  _HelpItem(
                    icon: Icons.interests_rounded,
                    title: '1. Choisissez vos domaines d’intérêt',
                    body:
                        'Ils servent à orienter la recherche de concurrents et à rendre les rapports plus pertinents pour votre activité.',
                  ),
                  _HelpItem(
                    icon: Icons.search_rounded,
                    title: '2. Lancez une recherche de concurrents',
                    body:
                        'Depuis la liste des concurrents, utilisez le bouton + pour demander une nouvelle recherche. Les résultats peuvent arriver après quelques minutes.',
                  ),
                  _HelpItem(
                    icon: Icons.toggle_on_outlined,
                    title: '3. Gardez seulement les concurrents utiles actifs',
                    body:
                        'Les concurrents actifs sont ceux que vous suivez vraiment. Si une entreprise n’est pas pertinente, désactivez-la depuis la liste complète.',
                  ),
                  _HelpItem(
                    icon: Icons.description_outlined,
                    title: '4. Consultez les rapports',
                    body:
                        'Les rapports regroupent les signaux importants détectés : nouveaux contenus, mouvements du marché, changements chez les concurrents ou autres informations utiles.',
                  ),
                  _HelpItem(
                    icon: Icons.business_rounded,
                    title: '5. Ouvrez la fiche d’un concurrent',
                    body:
                        'Touchez un concurrent pour voir sa note d’analyse, son site, son score et les informations disponibles pour décider s’il mérite d’être suivi.',
                  ),
                  _HelpItem(
                    icon: Icons.notifications_active_outlined,
                    title: '6. Activez les rappels sur téléphone',
                    body:
                        'Les rappels vous aident à revenir vérifier les nouveaux concurrents ou à relancer une recherche régulièrement.',
                  ),
                  _HelpItem(
                    icon: Icons.tips_and_updates_outlined,
                    title: 'Conseil pratique',
                    body:
                        'Revenez de temps en temps dans vos domaines d’intérêt. Plus ils sont précis, plus votre veille devient utile.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.blue, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EditProfileDialog extends StatefulWidget {
  final AccountService service;
  final UserProfile profile;
  final bool completingProfile;

  const _EditProfileDialog({
    required this.service,
    required this.profile,
    this.completingProfile = false,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.completingProfile,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        widget.completingProfile
            ? 'Complétez votre profil'
            : 'Modifier le profil',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFFD8E5FF),
              backgroundImage: _imageBytes == null
                  ? null
                  : MemoryImage(_imageBytes!),
              child: _imageBytes == null
                  ? const Icon(
                      Icons.person_outline,
                      color: AppColors.blue,
                      size: 34,
                    )
                  : null,
            ),
            TextButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir une photo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFD92D20))),
            ],
            if (_isSaving) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving || widget.completingProfile
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = 'La photo ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageFilename = image.name;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Le nom complet est obligatoire.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final success = await widget.service.updateProfile(
      fullName: _nameController.text,
      imageBytes: _imageBytes,
      imageFilename: _imageFilename,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSaving = false;
        _error = widget.service.error ?? 'Impossible de modifier le profil.';
      });
    }
  }
}

class _FirstRunGuideDialog extends StatefulWidget {
  final AccountService service;

  const _FirstRunGuideDialog({required this.service});

  @override
  State<_FirstRunGuideDialog> createState() => _FirstRunGuideDialogState();
}

class _FirstRunGuideDialogState extends State<_FirstRunGuideDialog> {
  final Set<String> selectedIds = {};
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    for (final domain in widget.service.profile?.interestDomains ?? const []) {
      selectedIds.add(domain.id);
    }
    if (widget.service.availableDomains.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDomains());
    }
  }

  @override
  Widget build(BuildContext context) {
    final domains = widget.service.availableDomains;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('Bienvenue dans KoraScope'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KoraScope surveille vos concurrents, collecte les signaux utiles et génère des rapports exploitables.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Pour bien démarrer, choisissez vos centres d’intérêt puis lancez une première recherche de concurrents.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              if (domains.isEmpty)
                const Text('Chargement des domaines…')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final domain in domains)
                      FilterChip(
                        label: Text(domain.name),
                        selected: selectedIds.contains(domain.id),
                        onSelected: isLoading
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
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Color(0xFFD92D20))),
              ],
              if (isLoading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: isLoading ? null : _sendFirstCompetitorSearch,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Lancer ma première recherche'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDomains() async {
    setState(() => isLoading = true);
    await widget.service.load();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _sendFirstCompetitorSearch() async {
    final profile = widget.service.profile;
    if (profile == null) {
      setState(() => error = 'Profil indisponible. Réessayez dans un instant.');
      return;
    }
    if (selectedIds.isEmpty) {
      setState(() => error = 'Choisissez au moins un centre d’intérêt.');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    final domains = widget.service.availableDomains;
    final currentIds = profile.interestDomains
        .map((domain) => domain.id)
        .toSet();
    final selectedDomains = domains
        .where((domain) => selectedIds.contains(domain.id))
        .toList(growable: false);

    for (final domain in domains) {
      final isCurrentlySelected = currentIds.contains(domain.id);
      final shouldBeSelected = selectedIds.contains(domain.id);
      if (isCurrentlySelected != shouldBeSelected) {
        final saved = await widget.service.toggleDomain(domain);
        if (!saved) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            error =
                widget.service.error ??
                'Impossible d’enregistrer vos intérêts.';
          });
          return;
        }
      }
    }

    try {
      await CompetitorsService(
        apiClient: widget.service.apiClient,
      ).requestDiscovery(
        userId: profile.id,
        email: profile.email,
        interests: selectedDomains.map((domain) => domain.name).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error =
            'Une erreur est survenue. Impossible d’envoyer la première recherche pour le moment.';
      });
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  final UserProfile profile;
  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 29,
    backgroundColor: const Color(0xFFD8E5FF),
    backgroundImage: profile.profileUrl == null
        ? null
        : NetworkImage(profile.profileUrl!),
    onBackgroundImageError: profile.profileUrl == null ? null : (_, __) {},
    child: profile.profileUrl == null
        ? Text(
            _initials(profile.fullName),
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w800,
            ),
          )
        : null,
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
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFD92D20))),
  );
}
