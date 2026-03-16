import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/plugless_logo.dart';

class DmPage extends StatelessWidget {
  const DmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: Row(
          children: [
            const PluglessLogo(size: 14),
            const SizedBox(width: 12),
            Container(width: 1, height: 28, color: const Color(0xFF3A3A3A)),
            const SizedBox(width: 12),
            Text(
              'Direct Messages',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NO MESSAGES YET',
              style: GoogleFonts.bebasNeue(
                color: AppColors.textPrimary,
                fontSize: 28,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'start a conversation with someone.',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF636363),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD8D8D8), width: 1),
                ),
                child: Text(
                  'NEW MESSAGE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE8E8E8),
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
