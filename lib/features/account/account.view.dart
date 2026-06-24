import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'account.service.dart';

class AccountView extends StatefulWidget {
  final VoidCallback onSignOut;
  const AccountView({super.key, required this.onSignOut});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final service = AccountService();

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTopBar(),
        const SizedBox(height: 30),
        const Text(
          'Mon compte',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 29,
                backgroundColor: Color(0xFFD8E5FF),
                child: Text(
                  'AK',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ama Koffi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ama@korascope.com',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
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
                'Ma veille',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const _SettingLink(
                icon: Icons.track_changes_rounded,
                title: 'Concurrents suivis',
                subtitle: '3 entreprises actives',
              ),
              const Divider(color: AppColors.line),
              const _SettingLink(
                icon: Icons.interests_outlined,
                title: 'Centres d’intérêt',
                subtitle: 'SaaS, IA, Fintech, SEO',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: service,
          builder: (context, _) => Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications email'),
                  value: service.emailNotifications,
                  onChanged: service.setEmailNotifications,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alertes du tableau de bord'),
                  value: service.dashboardAlerts,
                  onChanged: service.setDashboardAlerts,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Résumé chaque lundi'),
                  value: service.weeklySummary,
                  onChanged: service.setWeeklySummary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Abonnement',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'KoraScope Pro',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '29 000 FCFA / mois',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              const Text(
                '✓  Concurrents illimités\n\n✓  Analyses IA en temps réel\n\n✓  Exports PDF & Excel',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('GÉRER MON ABONNEMENT'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: TextButton.icon(
            key: const Key('sign_out'),
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SettingLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingLink({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.blue),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
