import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class DmPage extends StatelessWidget {
  const DmPage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(height: 1, color: const Color(0xFF1A1A1A)),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: Color(0xFF888888), size: 22),
          onPressed: onMenuTap,
        ),
        title: Text(
          'Direct Messages',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: const [
          _DmTile(
            initial: 'A',
            name: 'alex_r',
            preview: 'yo you there?',
            time: '2h',
            unread: 2,
            online: true,
          ),
          _DmTile(
            initial: 'S',
            name: 'sam.dev',
            preview: 'lmk when you push the fix',
            time: 'yesterday',
            unread: 0,
            online: false,
          ),
          _DmTile(
            initial: 'M',
            name: 'maya_ui',
            preview: 'the design looks clean',
            time: 'Mon',
            unread: 0,
            online: true,
          ),
          _DmTile(
            initial: 'J',
            name: 'jk_42',
            preview: 'got it, thanks',
            time: 'Sun',
            unread: 0,
            online: false,
          ),
        ],
      ),
    );
  }
}

class _DmTile extends StatelessWidget {
  const _DmTile({
    required this.initial,
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.online,
  });

  final String initial;
  final String name;
  final String preview;
  final String time;
  final int unread;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFF888888),
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online
                          ? AppColors.online
                          : const Color(0xFF555555),
                      border: Border.all(
                          color: const Color(0xFF0A0A0A), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: unread > 0
                              ? AppColors.textPrimary
                              : const Color(0xFFAAAAAA),
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF555555),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: unread > 0
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF555555),
                            fontSize: 12,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$unread',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
