import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/image/logo_korascope.png',
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      const Text(
        'KoraScope',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.blue,
        ),
      ),
    ],
  );
}

class PageFrame extends StatelessWidget {
  final Widget child;
  const PageFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: child,
      ),
    ),
  );
}

class AppTopBar extends StatelessWidget {
  final String? fullName;
  final String? profileUrl;
  final VoidCallback onProfile;

  const AppTopBar({
    super.key,
    required this.fullName,
    required this.profileUrl,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            const Brand(),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Ouvrir mon compte',
              child: InkWell(
                onTap: onProfile,
                customBorder: const CircleBorder(),
                child: _HeaderAvatar(
                  fullName: fullName,
                  profileUrl: profileUrl,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeaderAvatar extends StatelessWidget {
  final String? fullName;
  final String? profileUrl;

  const _HeaderAvatar({required this.fullName, required this.profileUrl});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 19,
    backgroundColor: const Color(0xFFD8E5FF),
    backgroundImage: profileUrl == null ? null : NetworkImage(profileUrl!),
    onBackgroundImageError: profileUrl == null ? null : (_, __) {},
    child: profileUrl == null
        ? Text(
            _initials(fullName),
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

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A101828),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  const EmptyState({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 40, color: AppColors.muted),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
