import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PluglessLogo extends StatelessWidget {
  const PluglessLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PLUG',
          style: GoogleFonts.bungee(
            fontSize: size,
            color: const Color(0xFF282828),
            letterSpacing: 2,
            height: 1,
          ),
        ),
        Text(
          'LESS',
          style: GoogleFonts.bungee(
            fontSize: size,
            color: const Color(0xFFF2F2F2),
            letterSpacing: 2,
            height: 1,
          ),
        ),
      ],
    );
  }
}
