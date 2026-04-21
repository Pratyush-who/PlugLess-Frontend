import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:battery_plus/battery_plus.dart';

import '../../../../core/auth/token_service.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/widgets/auth_dot_grid.dart';
import '../../../chat/presentation/providers/global_chat_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _plugOpacity;
  late final Animation<Offset> _plugSlide;
  late final Animation<double> _lessOpacity;
  late final Animation<Offset> _lessSlide;
  late final Animation<double> _tagOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _plugOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _plugSlide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));

    _lessOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _lessSlide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    ));

    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();
    _prewarmChat(); // kick off in background, don't await
    _navigate();
  }

  /// Starts loading chat data in the background during the splash animation
  /// so the history is ready by the time the user reaches home.
  Future<void> _prewarmChat() async {
    final token = await TokenService.instance.getToken();
    if (token != null && mounted) {
      ref.read(globalChatProvider.notifier).reload();
    }
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    var batteryLevel = 100;
    try {
      batteryLevel = await Battery().batteryLevel;
    } catch (_) {
      batteryLevel = 100;
    }

    if (!mounted) return;
    if (batteryLevel > 20) {
      context.go(AppRoutes.batteryGate);
      return;
    }
    await _continueToApp();
  }

  Future<void> _continueToApp() async {
    final token = await TokenService.instance.getToken();
    if (!mounted) return;
    context.go(token != null ? AppRoutes.home : AppRoutes.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthDotGrid()),
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: _plugOpacity.value,
                      child: SlideTransition(
                        position: _plugSlide,
                        child: Text(
                          'PLUG',
                          style: GoogleFonts.bungee(
                            fontSize: 72,
                            color: const Color(0xFF282828),
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _lessOpacity.value,
                      child: SlideTransition(
                        position: _lessSlide,
                        child: Text(
                          'LESS',
                          style: GoogleFonts.bungee(
                            fontSize: 72,
                            color: const Color(0xFFF2F2F2),
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _tagOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          'Meet Your People.',
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            color: const Color(0xFFC7C7C7),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _tagOpacity,
              builder: (_, __) => Opacity(
                opacity: _tagOpacity.value,
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: const Color(0xFF222222),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
