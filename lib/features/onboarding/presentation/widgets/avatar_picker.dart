import 'dart:io';
import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.onTap, this.avatarFile});

  final VoidCallback onTap;
  final File? avatarFile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
              image: avatarFile != null
                  ? DecorationImage(
                      image: FileImage(avatarFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarFile == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Color(0xFF3A3A3A),
                  )
                : null,
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFD8D8D8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ],
      ),
    );
  }
}
