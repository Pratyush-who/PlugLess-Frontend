import 'dart:async';

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

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  static const List<String> _greetings = [
    'HELLO',
    'HOLA',
    'नमस्ते',
    'BONJOUR',
    'CIAO',
    '안녕하세요',
    'NAMASTE',
    '你好',
    'KONNICHIWA',
    'مرحبا',
    'NI HAO',
  ];

  int _greetingIndex = 0;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _greetingTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      setState(() {
        _greetingIndex = (_greetingIndex + 1) % _greetings.length;
      });
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).stagePendingSignup(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthPendingOnboarding) context.go(AppRoutes.onboarding);
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

                        // ── Hero: Logo only ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.10),
                            const Center(child: PluglessLogo(size: 64)),
                            const SizedBox(height: 28),
                          ],
                        ),

                        // ── Form section: greeting + fields ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ClipRect(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder: (currentChild, previous) {
                                    return Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        ...previous,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final isIncoming = child.key ==
                                        ValueKey(_greetings[_greetingIndex]);
                                    final slideAnimation = Tween<Offset>(
                                      begin: isIncoming
                                          ? const Offset(0, 1)
                                          : Offset.zero,
                                      end: isIncoming
                                          ? Offset.zero
                                          : const Offset(0, -1),
                                    ).animate(CurvedAnimation(
                                      parent: isIncoming
                                          ? animation
                                          : ReverseAnimation(animation),
                                      curve: Curves.easeInOutCubic,
                                    ));
                                    final fadeAnimation = CurvedAnimation(
                                      parent: isIncoming
                                          ? animation
                                          : ReverseAnimation(animation),
                                      curve: Curves.easeInOut,
                                    );
                                    return FadeTransition(
                                      opacity: fadeAnimation,
                                      child: SlideTransition(
                                        position: slideAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _greetings[_greetingIndex],
                                    key: ValueKey(_greetings[_greetingIndex]),
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 52,
                                      color: const Color(0xFFBBBBBB),
                                      letterSpacing: 1.5,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Meet your people.',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: const Color(0xFF888888),
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
                                    label: 'continue',
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
                                Text('ALREADY HERE?  ',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: const Color(0xFF666666))),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.login),
                                  child: Text('SIGN IN →',
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
