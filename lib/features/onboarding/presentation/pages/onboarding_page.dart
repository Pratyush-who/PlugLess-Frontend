import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../router/app_routes.dart';
import '../providers/onboarding_provider.dart';

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
      backgroundColor: AppColors.modalBg,
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose Photo',
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.gallery);
              },
            ),
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (hasAvatar)
              _SheetOption(
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
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final state = ref.watch(onboardingProvider);
    final isLoading = state is OnboardingLoading;
    final avatarFile = state is OnboardingInitial ? state.avatarFile : null;

    return Scaffold(
      backgroundColor: AppColors.channelBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Complete Your Profile',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us a bit about yourself to get started.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 36),
                Center(
                  child: _AvatarPicker(
                    avatarFile: avatarFile,
                    onTap: _showImageOptions,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Username',
                  hint: 'e.g. plugmaster',
                  controller: _usernameCtrl,
                  validator: Validators.username,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Display Name',
                  hint: 'How others see you',
                  controller: _displayNameCtrl,
                  validator: (v) => Validators.required(v, 'Display Name'),
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.badge_rounded,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Bio',
                  hint: 'Tell us about yourself...',
                  controller: _bioCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: "Let's Go",
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Skip for now',
                  onPressed: isLoading
                      ? null
                      : () => ref.read(onboardingProvider.notifier).skip(),
                  isOutlined: true,
                  color: AppColors.textMuted,
                  textColor: AppColors.textSecondary,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.onTap, this.avatarFile});

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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inputBg,
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
                    size: 52,
                    color: AppColors.textMuted,
                  )
                : null,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.blurple,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.channelBg, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(
        label,
        style: GoogleFonts.inter(color: c, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
