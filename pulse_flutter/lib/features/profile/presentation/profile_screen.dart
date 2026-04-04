import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/components/pulse_avatar.dart';
import 'package:pulse_flutter/core/models/pulse_data_export.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
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
  String _selectedReminderTime =
      PulseProfileSettings.defaultPreferredReminderTime;
  bool _dailyRemindersEnabled =
      PulseProfileSettings.defaultDailyRemindersEnabled;
  bool _streakRemindersEnabled =
      PulseProfileSettings.defaultStreakRemindersEnabled;
  bool _weeklySummaryEnabled = PulseProfileSettings.defaultWeeklySummaryEnabled;
  PulseAppearanceMode _appearanceMode =
      PulseProfileSettings.defaultAppearanceMode;
  bool _isExporting = false;
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
            settings: PulseProfileSettings(
              preferredReminderTime: _selectedReminderTime,
              dailyRemindersEnabled: _dailyRemindersEnabled,
              streakRemindersEnabled: _streakRemindersEnabled,
              weeklySummaryEnabled: _weeklySummaryEnabled,
              appearanceMode: _appearanceMode,
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = 'Profile settings updated.';
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
    _selectedReminderTime = profile.settings.preferredReminderTime;
    _dailyRemindersEnabled = profile.settings.dailyRemindersEnabled;
    _streakRemindersEnabled = profile.settings.streakRemindersEnabled;
    _weeklySummaryEnabled = profile.settings.weeklySummaryEnabled;
    _appearanceMode = profile.settings.appearanceMode;
    _hasInitializedForm = true;
  }

  Future<void> _pickReminderTime() async {
    final TimeOfDay initialTime = PulseProfileSettings.timeOfDayFromStorage(
      _selectedReminderTime,
    );
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedReminderTime = PulseProfileSettings.formatStorageTime(
        selectedTime,
      );
      _successMessage = null;
    });
  }

  Future<void> _exportData(PulseUserProfile profile) async {
    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = 'Please sign in again before exporting your data.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final sessions = await ref
          .read(swipeSessionRepositoryProvider)
          .watchSessions(uid: uid)
          .first;
      final String exportJson = PulseDataExport(
        profile: profile,
        sessions: sessions,
      ).toPrettyJson();

      if (!mounted) {
        return;
      }

      setState(() {
        _isExporting = false;
      });

      await _showExportSheet(exportJson);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'We could not prepare your Pulse export right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _showExportSheet(String exportJson) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return _ExportDataSheet(
          exportJson: exportJson,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: exportJson));

            if (!sheetContext.mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Pulse export copied to clipboard.'),
              ),
            );
          },
        );
      },
    );
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
                  constraints: const BoxConstraints(maxWidth: 520),
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
                      _ProfileSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Profile basics', style: textTheme.titleLarge),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                hintText: 'How Pulse should greet you',
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _successMessage = null;
                                });
                              },
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
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: swatchColor,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.white
                                                : swatchColor.withValues(
                                                    alpha: 0.35,
                                                  ),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ProfileSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Settings', style: textTheme.titleLarge),
                            const SizedBox(height: 20),
                            Text('Reminder time', style: textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Save the time you would like Pulse to use for future nudges.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickReminderTime,
                              icon: const Icon(Icons.schedule_rounded),
                              label: Text(
                                PulseProfileSettings.formatDisplayTime(
                                  PulseProfileSettings.timeOfDayFromStorage(
                                    _selectedReminderTime,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Daily reminders'),
                              subtitle: const Text(
                                'Keep a daily Pulse check-in reminder ready.',
                              ),
                              value: _dailyRemindersEnabled,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _dailyRemindersEnabled = value;
                                        _successMessage = null;
                                      });
                                    },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Streak reminders'),
                              subtitle: const Text(
                                'Highlight when your streak could use a nudge.',
                              ),
                              value: _streakRemindersEnabled,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _streakRemindersEnabled = value;
                                        _successMessage = null;
                                      });
                                    },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Weekly summary'),
                              subtitle: const Text(
                                'Save a spot for future weekly Pulse recaps.',
                              ),
                              value: _weeklySummaryEnabled,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _weeklySummaryEnabled = value;
                                        _successMessage = null;
                                      });
                                    },
                            ),
                            const SizedBox(height: 20),
                            Text('Appearance', style: textTheme.titleMedium),
                            const SizedBox(height: 12),
                            SegmentedButton<PulseAppearanceMode>(
                              showSelectedIcon: false,
                              segments: PulseAppearanceMode.values
                                  .map((mode) {
                                    return ButtonSegment<PulseAppearanceMode>(
                                      value: mode,
                                      label: Text(mode.label),
                                    );
                                  })
                                  .toList(growable: false),
                              selected: <PulseAppearanceMode>{_appearanceMode},
                              onSelectionChanged: _isSaving
                                  ? null
                                  : (selection) {
                                      if (selection.isEmpty) {
                                        return;
                                      }

                                      setState(() {
                                        _appearanceMode = selection.first;
                                        _successMessage = null;
                                      });
                                    },
                            ),
                          ],
                        ),
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
                        onPressed: (_isSaving || _isExporting)
                            ? null
                            : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.goNamed(AppRoutes.badgesName),
                        child: const Text('View badges'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _isExporting)
                            ? null
                            : () => _exportData(profile),
                        icon: _isExporting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _isExporting
                              ? 'Preparing export...'
                              : 'Export my data',
                        ),
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

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
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

class _ExportDataSheet extends StatelessWidget {
  const _ExportDataSheet({required this.exportJson, required this.onCopy});

  final String exportJson;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export your data',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This JSON includes your saved Pulse profile, settings, progress, badges, and sessions.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    exportJson,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onCopy, child: const Text('Copy JSON')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
