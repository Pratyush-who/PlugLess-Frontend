import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/plugless_logo.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/auth_dot_grid.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/sheet_option.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      ref.read(onboardingProvider.notifier).pickAvatar(File(picked.path));
    }
  }

  void _showImageOptions() {
    final hasAvatar = ref.read(onboardingProvider) is OnboardingInitial &&
        (ref.read(onboardingProvider) as OnboardingInitial).avatarFile != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose Photo',
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.gallery);
              },
            ),
            SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (hasAvatar)
              SheetOption(
                icon: Icons.delete_rounded,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(onboardingProvider.notifier).removeAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(onboardingProvider.notifier).submit(
          userName: _usernameCtrl.text.trim(),
          displayName: _displayNameCtrl.text.trim(),
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingProvider, (_, next) {
      if (next is OnboardingSuccess) {
        context.go(AppRoutes.home);
      } else if (next is OnboardingFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.message,
              style: GoogleFonts.spaceMono(
                  color: const Color(0xFFCCCCCC), fontSize: 11),
            ),
            backgroundColor: const Color(0xFF141414),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    });

    final state = ref.watch(onboardingProvider);
    final isLoading = state is OnboardingLoading;
    final avatarFile = state is OnboardingInitial ? state.avatarFile : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthDotGrid()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const PluglessLogo(size: 28),
                    const SizedBox(height: 28),

                    Text(
                      'SET UP YOUR\nPROFILE',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 52,
                        color: const Color(0xFFF2F2F2),
                        letterSpacing: 1.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tell us a bit about yourself.',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: const Color(0xFFAAAAAA),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    Center(
                      child: AvatarPicker(
                        avatarFile: avatarFile,
                        onTap: _showImageOptions,
                      ),
                    ),

                    const SizedBox(height: 40),

                    AuthTextField(
                      label: 'username',
                      hint: 'plugmaster',
                      controller: _usernameCtrl,
                      validator: Validators.username,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      label: 'display name',
                      hint: 'how others see you',
                      controller: _displayNameCtrl,
                      validator: (v) => Validators.required(v, 'Display Name'),
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      label: 'bio',
                      hint: 'tell us about yourself...',
                      controller: _bioCtrl,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 40),

                    AuthButton(
                      label: "let's go",
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
