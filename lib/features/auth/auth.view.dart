import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';
import 'auth.service.dart';

class AuthView extends StatefulWidget {
  final AuthService authService;
  const AuthView({super.key, required this.authService});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Brand()),
                  const SizedBox(height: 42),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF071B3B), Color(0xFF1557E8)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.query_stats_rounded,
                          color: Colors.white,
                          size: 112,
                        ),
                        Positioned(
                          right: 48,
                          bottom: 38,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Surveillez vos concurrents.\nAnticipez le marché.',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Recevez des analyses automatisées sur vos concurrents et votre secteur.',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'EMAIL PROFESSIONNEL',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('auth_email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'nom@entreprise.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  if (widget.authService.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.authService.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const Key('auth_submit'),
                    onPressed: widget.authService.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: widget.authService.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accéder à mon espace  →'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() =>
      widget.authService.signIn(_emailController.text.trim());
}
