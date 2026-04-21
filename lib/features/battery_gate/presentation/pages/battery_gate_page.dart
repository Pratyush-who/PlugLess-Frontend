import 'dart:typed_data';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../auth/presentation/widgets/auth_dot_grid.dart';
import '../../../../../core/widgets/plugless_logo.dart';
import '../../../../../core/auth/token_service.dart';
import '../../../../../router/app_routes.dart';

class BatteryGatePage extends StatefulWidget {
  const BatteryGatePage({super.key});

  @override
  State<BatteryGatePage> createState() => _BatteryGatePageState();
}

class _BatteryGatePageState extends State<BatteryGatePage> {
  static const _threshold = 20;

  static const List<_DrainAppSpec> _targetApps = [
    _DrainAppSpec(
      name: 'WhatsApp',
      packageName: 'com.whatsapp',
      fallbackIcon: Icons.chat_bubble_rounded,
    ),
    _DrainAppSpec(
      name: 'Instagram',
      packageName: 'com.instagram.android',
      fallbackIcon: Icons.camera_alt_rounded,
    ),
    _DrainAppSpec(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      fallbackIcon: Icons.ondemand_video_rounded,
    ),
    _DrainAppSpec(
      name: 'Amazon',
      packageName: 'com.amazon.mShop.android.shopping',
      fallbackIcon: Icons.shopping_bag_rounded,
    ),
    _DrainAppSpec(
      name: 'Spotify',
      packageName: 'com.spotify.music',
      fallbackIcon: Icons.graphic_eq_rounded,
    ),
    _DrainAppSpec(
      name: 'Facebook',
      packageName: 'com.facebook.katana',
      fallbackIcon: Icons.groups_rounded,
    ),
  ];

  final _battery = Battery();

  bool _isLoading = true;
  int _batteryLevel = 100;
  List<_InstalledDrainApp> _installedTargetApps = const [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);

    final level = await _readBatteryLevel();
    if (!mounted) return;

    if (level <= _threshold) {
      await _continueToApp();
      return;
    }

    final installedApps = await _readInstalledTargetApps();
    if (!mounted) return;

    setState(() {
      _batteryLevel = level;
      _installedTargetApps = installedApps;
      _isLoading = false;
    });
  }

  Future<int> _readBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return 100;
    }
  }

  Future<List<_InstalledDrainApp>> _readInstalledTargetApps() async {
    final isAndroid =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);
    if (!isAndroid) return const [];

    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );

      final appMap = <String, AppInfo>{
        for (final app in apps) app.packageName: app,
      };

      final result = <_InstalledDrainApp>[];
      for (final target in _targetApps) {
        final app = appMap[target.packageName];
        if (app == null) continue;

        result.add(
          _InstalledDrainApp(
            spec: target,
            iconBytes: app.icon,
          ),
        );
      }

      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _continueToApp() async {
    final token = await TokenService.instance.getToken();
    if (!mounted) return;
    context.go(token != null ? AppRoutes.home : AppRoutes.login);
  }

  Future<void> _openApp(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
    } catch (_) {}
  }

  Future<void> _onHiddenSkipLongPress() async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    await _continueToApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFECECEC),
            strokeWidth: 1.7,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthDotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 64,
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PLUGLESS',
                                style: GoogleFonts.bungee(
                                  color: const Color(0xFFEDEDED),
                                  fontSize: 24,
                                  letterSpacing: 1.2,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Meet Your People.',
                                style: GoogleFonts.spaceMono(
                                  color: const Color(0xFF7A7A7A),
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onLongPress: _onHiddenSkipLongPress,
                            behavior: HitTestBehavior.opaque,
                            child: Opacity(
                              opacity: 0.35,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: PluglessLogo(size: 8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFF1A1A1A)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF262626),
                          ),
                        ),
                        child: const Icon(Icons.battery_alert_rounded,
                            color: Color(0xFFCBCBCB), size: 23),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'BATTERY AT $_batteryLevel%',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFFD3D3D3),
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PLUGLESS IS FOR TIMES YOUR PHONE IS DYING',
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFFF4F4F4),
                      fontSize: 44,
                      letterSpacing: 1,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use these to drain your battery instead...',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF9C9C9C),
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'APPS YOU HAVE',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF646464),
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _installedTargetApps.isEmpty
                        ? _EmptyInstalledAppsHint()
                        : ListView.separated(
                            itemCount: _installedTargetApps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final app = _installedTargetApps[i];
                              return _AppCard(
                                app: app,
                                onTap: () => _openApp(app.spec.packageName),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadState,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEDEDED),
                        foregroundColor: const Color(0xFF0D0D0D),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'I DRAINED ENOUGH, CHECK AGAIN',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'PlugLess unlocks at ${_threshold}%.',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF656565),
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onTap});

  final _InstalledDrainApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: Colors.transparent,
        highlightColor: const Color(0xFF151515),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: app.iconBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(app.iconBytes!, fit: BoxFit.cover),
                      )
                    : Icon(app.spec.fallbackIcon,
                        color: const Color(0xFFE0E0E0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  app.spec.name,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFF3F3F3),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                'OPEN',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFFA4A4A4),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Color(0xFFA4A4A4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInstalledAppsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO SUPPORTED APPS FOUND',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFFD0D0D0),
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Install one of these: WhatsApp, Instagram, YouTube, Amazon, Spotify, Facebook.',
            style: GoogleFonts.inter(
              color: const Color(0xFF9A9A9A),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrainAppSpec {
  const _DrainAppSpec({
    required this.name,
    required this.packageName,
    required this.fallbackIcon,
  });

  final String name;
  final String packageName;
  final IconData fallbackIcon;
}

class _InstalledDrainApp {
  const _InstalledDrainApp({
    required this.spec,
    required this.iconBytes,
  });

  final _DrainAppSpec spec;
  final Uint8List? iconBytes;
}
