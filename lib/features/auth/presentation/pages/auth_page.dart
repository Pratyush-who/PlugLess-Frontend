import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/sign_in_form.dart';
import '../widgets/sign_up_form.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthPendingOnboarding) {
        // Sign-up: go collect profile details before calling the API.
        context.go(AppRoutes.onboarding);
      } else if (next is AuthSuccess) {
        // Sign-in: already authenticated, go home.
        context.go(AppRoutes.home);
      } else if (next is AuthFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.channelBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  _AuthLogo(),
                  const SizedBox(height: 32),
                  // Heading
                  Text(
                    AppStrings.appName,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tagline,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.modalBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        _AuthTabBar(controller: _tabController),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              return IndexedStack(
                                index: _tabController.index,
                                children: const [
                                  SignInForm(),
                                  SignUpForm(),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Toggle link
                  _ToggleLink(controller: _tabController),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.blurple,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.blurple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'P',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.blurple,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: AppStrings.signIn),
          Tab(text: AppStrings.signUp),
        ],
      ),
    );
  }
}

class _ToggleLink extends StatelessWidget {
  const _ToggleLink({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final isSignIn = controller.index == 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignIn
                  ? AppStrings.dontHaveAccount
                  : AppStrings.alreadyHaveAccount,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => controller.animateTo(isSignIn ? 1 : 0),
              child: Text(
                isSignIn ? AppStrings.signUp : AppStrings.signIn,
                style: GoogleFonts.inter(
                  color: AppColors.textLink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
