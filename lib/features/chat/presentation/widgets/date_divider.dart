import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFF1E1E1E), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF444444),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: Color(0xFF1E1E1E), thickness: 1)),
        ],
      ),
    );
  }
}
