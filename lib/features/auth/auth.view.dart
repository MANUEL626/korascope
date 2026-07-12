import 'dart:async';

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
  static const _resendCooldown = 60;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpRequested = false;
  Timer? _resendTimer;
  int _resendDelay = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
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
                  const SizedBox(height: 36),
                  if (!_otpRequested) ...[
                    Container(
                      height: 190,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF071B3B), Color(0xFF1557E8)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.query_stats_rounded,
                        color: Colors.white,
                        size: 104,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    _otpRequested
                        ? 'Vérifiez votre boîte mail.'
                        : 'Surveillez vos concurrents.\nAnticipez le marché.',
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _otpRequested
                        ? 'Saisissez le code à 6 chiffres envoyé à ${_emailController.text.trim()}.'
                        : 'Recevez des analyses automatisées sur vos concurrents et votre secteur.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_otpRequested)
                    TextField(
                      key: const Key('auth_email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _requestOtp(),
                      decoration: const InputDecoration(
                        labelText: 'Email professionnel',
                        hintText: 'nom@entreprise.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    )
                  else
                    TextField(
                      key: const Key('auth_otp'),
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      onSubmitted: (_) => _verifyOtp(),
                      decoration: const InputDecoration(
                        labelText: 'Code de connexion',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.lock_clock_outlined),
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
                    onPressed: widget.authService.isLoading
                        ? null
                        : (_otpRequested ? _verifyOtp : _requestOtp),
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
                          : Text(
                              _otpRequested
                                  ? 'Vérifier le code'
                                  : 'Recevoir mon code  →',
                            ),
                    ),
                  ),
                  if (_otpRequested) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.authService.isLoading || _resendDelay > 0
                          ? null
                          : _resendOtp,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _resendDelay > 0
                            ? 'Renvoyer le code dans ${_resendDelay}s'
                            : 'Renvoyer le code',
                      ),
                    ),
                    TextButton(
                      onPressed: widget.authService.isLoading
                          ? null
                          : () => setState(() {
                              _otpRequested = false;
                              _otpController.clear();
                              _stopResendTimer();
                            }),
                      child: const Text('Modifier mon adresse email'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestOtp() async {
    final sent = await widget.authService.requestOtp(
      _emailController.text.trim(),
    );
    if (sent && mounted) {
      setState(() => _otpRequested = true);
      _startResendTimer();
    }
  }

  Future<void> _resendOtp() async {
    _otpController.clear();
    final sent = await widget.authService.requestOtp(
      _emailController.text.trim(),
    );
    if (sent && mounted) _startResendTimer();
  }

  Future<void> _verifyOtp() => widget.authService.verifyOtp(
    email: _emailController.text.trim(),
    otp: _otpController.text.trim(),
  );

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendDelay = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendDelay <= 1) {
        timer.cancel();
        setState(() => _resendDelay = 0);
      } else {
        setState(() => _resendDelay--);
      }
    });
  }

  void _stopResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
    _resendDelay = 0;
  }
}
