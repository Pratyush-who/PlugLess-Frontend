import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/plugless_logo.dart';
import '../../../../router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_dot_grid.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthSuccess) context.go(AppRoutes.home);
      if (next is AuthFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message,
                style: GoogleFonts.spaceMono(
                    color: const Color(0xFFCCCCCC), fontSize: 11)),
            backgroundColor: const Color(0xFF141414),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    });

    final isLoading = ref.watch(authProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthDotGrid()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // ── Hero: Logo centered ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.10),
                            const Center(child: PluglessLogo(size: 64)),
                            const SizedBox(height: 12),
                            Text(
                              'Missed the community?.',
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                color: const Color(0xFF888888),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),

                        // ── Form section ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME BACK',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 53,
                                color: const Color(0xFFBBBBBB),
                                letterSpacing: 2,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You were gone for a while.',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: const Color(0xFF777777),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AuthTextField(
                                    label: 'email',
                                    hint: 'you@example.com',
                                    controller: _emailCtrl,
                                    validator: Validators.email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus),
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 28),
                                  AuthTextField(
                                    label: 'password',
                                    hint: '••••••••',
                                    controller: _passwordCtrl,
                                    validator: Validators.password,
                                    isPassword: true,
                                    focusNode: _passwordFocus,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    enabled: !isLoading,
                                  ),
                                  const SizedBox(height: 32),
                                  AuthButton(
                                    label: 'sign in',
                                    onPressed: isLoading ? null : _submit,
                                    isLoading: isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ── Footer ──
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 36),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('NEW HERE?  ',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: const Color(0xFF666666))),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.signup),
                                  child: Text('MAKE AN ACCOUNT →',
                                      style: GoogleFonts.spaceMono(
                                          fontSize: 11,
                                          color: const Color(0xFFCCCCCC))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
