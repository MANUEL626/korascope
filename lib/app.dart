import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth.service.dart';
import 'features/auth/auth.view.dart';
import 'shared/widgets/app_shell.dart';

class KoraScopeApp extends StatefulWidget {
  const KoraScopeApp({super.key});

  @override
  State<KoraScopeApp> createState() => _KoraScopeAppState();
}

class _KoraScopeAppState extends State<KoraScopeApp> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KoraScope',
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: _authService,
        builder: (context, _) => _authService.isAuthenticated
            ? AppShell(
                authService: _authService,
                onSignOut: _authService.signOut,
              )
            : AuthView(authService: _authService),
      ),
    );
  }
}
