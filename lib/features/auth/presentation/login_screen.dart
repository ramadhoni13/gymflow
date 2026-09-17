import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login gagal: $err')),
          );
        },
      );
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wordmark: garis emas tipis sebagai satu-satunya aksen
                  // dekoratif di halaman ini — bukan gradient/ikon besar.
                  Container(width: 40, height: 2, color: AppColors.gold),
                  const SizedBox(height: 20),
                  Text(
                    'GYM MANAGEMENT',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          letterSpacing: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Portal khusus pengelola',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            style: const TextStyle(color: AppColors.ivory),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            style: const TextStyle(color: AppColors.ivory),
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink,
                                      ),
                                    )
                                  : const Text('Masuk'),
                            ),
                          ),
                        ],
                      ),
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }
}
