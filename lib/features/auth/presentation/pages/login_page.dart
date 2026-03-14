import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/validators.dart';
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.22),
                            Text(
                              'MISSED US?',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 68,
                                color: const Color(0xFFF2F2F2),
                                letterSpacing: 1.5,
                                height: 1,
                              ),
                            ),
                            Text(
                              'OR THE COMMUNITY?',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 36,
                                color: const Color(0xFF979797),
                                letterSpacing: 1.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'you were gone for a while.',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: const Color(0xFFAAAAAA),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                        // ── Bottom link ──
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 36),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('NEW HERE?  ',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        color: const Color(0xFF636363))),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.signup),
                                  child: Text('MAKE AN ACCOUNT →',
                                      style: GoogleFonts.spaceMono(
                                          fontSize: 12,
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
