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
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.radar_rounded, color: Colors.white),
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
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: child,
        ),
      ),
    ),
  );
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (MediaQuery.sizeOf(context).width < 880) const Brand(),
      const Spacer(),
      IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
      Badge(
        smallSize: 7,
        child: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ),
      const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFD8E5FF),
        child: Text(
          'AK',
          style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
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
