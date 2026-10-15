import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/dimensional/scene_3d.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  const Scene3D(kind: Scene3DKind.store, size: 140),
                  const SizedBox(height: 12),
                  Text(
                    'RetailX',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your workspace to continue',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 560;
                      final cards = [
                        _RoleCard(
                          title: 'Admin',
                          subtitle:
                              'Catalog, inventory, cashiers, reports, and settings.',
                          scene: Scene3DKind.package,
                          color: AppTheme.primary,
                          onTap: () {
                            context
                                .read<AuthProvider>()
                                .selectLoginRole(UserRole.admin);
                          },
                        ),
                        _RoleCard(
                          title: 'Cashier',
                          subtitle:
                              'Ring up sales, check stock, and serve customers.',
                          scene: Scene3DKind.register,
                          color: AppTheme.accent,
                          onTap: () {
                            context
                                .read<AuthProvider>()
                                .selectLoginRole(UserRole.cashier);
                          },
                        ),
                      ];

                      if (!wide) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 16),
                            cards[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.scene,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Scene3DKind scene;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.white,
          elevation: _hover ? 8 : 0,
          shadowColor: widget.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hover
                      ? widget.color.withValues(alpha: 0.35)
                      : AppTheme.border,
                ),
              ),
              child: Column(
                children: [
                  Scene3D(
                    kind: widget.scene,
                    size: 110,
                    primary: widget.color,
                    accent: widget.color == AppTheme.primary
                        ? AppTheme.accent
                        : AppTheme.primaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 18, color: widget.color),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
