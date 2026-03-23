import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/domain/entities/user_entity.dart';

class PublicProfileHeader extends StatelessWidget {
  const PublicProfileHeader({
    super.key,
    this.title = 'PUBLIC PROFILE',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.spaceMono(
            color: const Color(0xFF8E8E93),
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF77777A)),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 18,
        ),
      ],
    );
  }
}

class PublicProfileAvatar extends StatelessWidget {
  const PublicProfileAvatar({
    super.key,
    required this.user,
    required this.size,
  });

  final UserEntity user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user.profileImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    _AvatarFallback(name: user.displayName, size: size),
              )
            : _AvatarFallback(name: user.displayName, size: size),
      ),
    );
  }
}

class PublicProfileMetaRow extends StatelessWidget {
  const PublicProfileMetaRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF7C7C82),
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: const Color(0xFFCBCBD0),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicProfileErrorState extends StatelessWidget {
  const PublicProfileErrorState({
    super.key,
    this.userName,
  });

  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PublicProfileHeader(),
          const SizedBox(height: 18),
          const Icon(Icons.person_off_rounded,
              color: Color(0xFF55555A), size: 34),
          const SizedBox(height: 10),
          Text(
            userName != null
                ? 'Could not load @$userName profile.'
                : 'Could not load this profile.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFFB6B6BC),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF202025),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.bebasNeue(
          color: const Color(0xFF9B9BA1),
          fontSize: math.max(20, 0.35 * size),
        ),
      ),
    );
  }
}
