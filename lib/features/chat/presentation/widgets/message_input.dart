import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isConnected,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isConnected;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: Color(0xFF4A4A4A), size: 20),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(
                  color: const Color(0xFFDCDDDE),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isConnected ? 'Message #general' : 'Connecting…',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4A4A4A),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isSending ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Color(0xFFCCCCCC), size: 18),
                onPressed: isSending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
