import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/bootstrap_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/dimensional/scene_3d.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _init();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final bootstrap = BootstrapService().ensureDefaultAdmin();
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 2400));
    await Future.wait([bootstrap, minDisplay]);
    if (!mounted) return;
    await context.read<AuthProvider>().finishSplash();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        dark: true,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Scene3D(kind: Scene3DKind.store, size: 180),
                const SizedBox(height: 20),
                Text(
                  'RetailX',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modern point of sale for modern stores',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      color: AppTheme.accentSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
