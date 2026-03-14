import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFD8D8D8),
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFCCCCCC)),
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE8E8E8),
                    letterSpacing: 2.5,
                  ),
                ),
        ),
      ),
    );
  }
}
