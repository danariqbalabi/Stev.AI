import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../application/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(bool registering) {
    if (_registering == registering) return;
    AuthScope.read(context).clearFeedback();
    setState(() => _registering = registering);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = AuthScope.read(context);
    final success = _registering
        ? await auth.signUp(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await auth.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (success && auth.isSignedIn && mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.watch(context);

    return Scaffold(
      key: const ValueKey('authScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s4,
              StevSpace.s5,
              StevSpace.s7,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const ValueKey('authBackButton'),
                  tooltip: 'Kembali',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/profile'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: StevSpace.s3),
              const StevLogo(markSize: 32),
              const SizedBox(height: StevSpace.s6),
              Text(
                _registering ? 'Buat akun Stev.AI' : 'Masuk ke Stev.AI',
                style: StevType.title,
              ),
              const SizedBox(height: StevSpace.s2),
              Text(
                'Dengan masuk, profil dan catatan kesehatanmu dicadangkan ke akun agar bisa dipulihkan di perangkat lain. Mode tamu tetap hanya menyimpan data lokal.',
                style: StevType.body.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s5),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Masuk'),
                    icon: Icon(Icons.login_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Daftar'),
                    icon: Icon(Icons.person_add_alt_1_rounded),
                  ),
                ],
                selected: {_registering},
                onSelectionChanged: (selection) => _setMode(selection.first),
              ),
              const SizedBox(height: StevSpace.s4),
              if (!auth.isAvailable)
                _MessageCard(
                  key: const ValueKey('authUnavailableMessage'),
                  icon: Icons.cloud_off_outlined,
                  message: 'Layanan akun belum dikonfigurasi. Mode tamu tetap bisa dipakai di perangkat ini.',
                )
              else if (auth.confirmationPending)
                _MessageCard(
                  key: const ValueKey('authConfirmationMessage'),
                  icon: Icons.mark_email_read_outlined,
                  message: 'Akun berhasil dibuat. Cek email untuk mengonfirmasi akun, lalu masuk.',
                ),
              if (auth.errorMessage case final error?) ...[
                _MessageCard(
                  key: const ValueKey('authErrorMessage'),
                  icon: Icons.error_outline_rounded,
                  message: error,
                  error: true,
                ),
                const SizedBox(height: StevSpace.s3),
              ],
              GlassCard(
                padding: const EdgeInsets.all(StevSpace.s5),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email', style: StevType.label),
                      const SizedBox(height: StevSpace.s2),
                      TextFormField(
                        key: const ValueKey('authEmailField'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'nama@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                            return 'Masukkan email yang valid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: StevSpace.s4),
                      Text('Kata sandi', style: StevType.label),
                      const SizedBox(height: StevSpace.s2),
                      TextFormField(
                        key: const ValueKey('authPasswordField'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: _registering
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Minimal 8 karakter',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            key: const ValueKey('toggleAuthPassword'),
                            tooltip: _obscurePassword
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) < 8
                            ? 'Gunakan minimal 8 karakter.'
                            : null,
                      ),
                      const SizedBox(height: StevSpace.s5),
                      StevButton(
                        key: const ValueKey('authSubmitButton'),
                        label: auth.isLoading
                            ? 'Memproses...'
                            : _registering
                            ? 'Buat akun'
                            : 'Masuk',
                        variant: StevButtonVariant.ink,
                        onPressed: auth.isAvailable && !auth.isLoading
                            ? _submit
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              StevButton(
                key: const ValueKey('continueAsGuestButton'),
                label: 'Lanjut sebagai tamu',
                variant: StevButtonVariant.ghost,
                onPressed: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.error = false,
  });

  final IconData icon;
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Theme.of(context).colorScheme.error : StevColors.ink2;
    return Padding(
      padding: const EdgeInsets.only(bottom: StevSpace.s3),
      child: GlassCard(
        padding: const EdgeInsets.all(StevSpace.s3),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: StevSpace.s2),
            Expanded(
              child: Text(
                message,
                style: StevType.caption.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
