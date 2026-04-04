import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/components/pulse_avatar.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();

  bool _hasInitializedForm = false;
  bool _isSaving = false;
  String _selectedAvatarColour = PulseUserProfile.defaultAvatarColour;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = 'Please sign in again before updating your profile.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref
          .read(userProfileRepositoryProvider)
          .updateProfile(
            uid: uid,
            displayName: _displayNameController.text,
            avatarColour: _selectedAvatarColour,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = 'Profile updated.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'We could not save your profile right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _initializeForm(PulseUserProfile profile) {
    if (_hasInitializedForm) {
      return;
    }

    _displayNameController.text = profile.displayName ?? '';
    _selectedAvatarColour = profile.avatarColour;
    _hasInitializedForm = true;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
      currentUserProfileProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Profile unavailable',
                          style: textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Pulse profile is not ready yet. Please try again in a moment.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            _initializeForm(profile);

            final String previewName =
                _displayNameController.text.trim().isNotEmpty
                ? _displayNameController.text.trim()
                : profile.greetingName;
            final String previewInitial = previewName
                .substring(0, 1)
                .toUpperCase();

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: PulseAvatar(
                          initial: previewInitial,
                          avatarColour: _selectedAvatarColour,
                          radius: 42,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        previewName,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.email,
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'How Pulse should greet you',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Avatar colour', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: PulseUserProfile.avatarColourOptions
                            .map((color) {
                              final bool isSelected =
                                  _selectedAvatarColour == color;
                              final Color swatchColor =
                                  PulseUserProfile.colorFromHex(color);

                              return InkWell(
                                onTap: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedAvatarColour = color;
                                          _successMessage = null;
                                        });
                                      },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: swatchColor,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : swatchColor.withValues(alpha: 0.35),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded)
                                      : null,
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 24),
                        _ProfileMessageCard(
                          message: _errorMessage!,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                      ],
                      if (_successMessage != null) ...[
                        const SizedBox(height: 24),
                        _ProfileMessageCard(
                          message: _successMessage!,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save profile'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Unable to load profile',
                        style: textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please try again in a moment.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileMessageCard extends StatelessWidget {
  const _ProfileMessageCard({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: foregroundColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
