import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth.service.dart';
import 'features/auth/auth.view.dart';
import 'shared/widgets/app_shell.dart';

class KoraScopeApp extends StatefulWidget {
  final AuthService? authService;
  const KoraScopeApp({super.key, this.authService});

  @override
  State<KoraScopeApp> createState() => _KoraScopeAppState();
}

class _KoraScopeAppState extends State<KoraScopeApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _authService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KoraScope',
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: _authService,
        builder: (context, _) {
          if (_authService.isInitializing) return const _SplashView();
          return _authService.isAuthenticated
              ? AppShell(
                  authService: _authService,
                  onSignOut: _authService.signOut,
                  initialIndex: _authService.isNewUser ? 3 : 0,
                )
              : AuthView(authService: _authService);
        },
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            image: AssetImage('assets/image/logo_korascope.png'),
            width: 72,
            height: 72,
          ),
          SizedBox(height: 18),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
