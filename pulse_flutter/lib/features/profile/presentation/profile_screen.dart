import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/components/pulse_avatar.dart';
import 'package:pulse_flutter/core/models/pulse_data_export.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/account_providers.dart';
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
  static const List<String> _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

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
  bool _isDeletingAccount = false;
  String? _errorMessage;
  String? _successMessage;

  bool get _isBusy => _isSaving || _isExporting || _isDeletingAccount;

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

  Future<void> _copyReferralCode(String referralCode) async {
    await Clipboard.setData(ClipboardData(text: referralCode));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard.')),
    );
  }

  Future<void> _showReferralShareSheet(PulseUserProfile profile) async {
    final String shareText = PulseReferral.buildShareText(
      referralCode: PulseReferral.resolveReferralCode(
        profile.referralCode,
        uid: profile.uid,
      ),
      displayName: profile.displayName,
    );
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return _ReferralShareSheet(
          shareText: shareText,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: shareText));

            if (!sheetContext.mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Referral invite copied to clipboard.'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPrivacyPolicySheet() async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => const _PrivacyPolicySheet(),
    );
  }

  Future<bool> _showDeleteAccountDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _DeleteAccountDialog(),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteAccount() async {
    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = 'Please sign in again before deleting your account.';
        _successMessage = null;
      });
      return;
    }

    final bool confirmed = await _showDeleteAccountDialog();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(pulseAccountRepositoryProvider).deleteUserData(uid);
      await ref.read(firebaseAuthServiceProvider).signOut();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'We could not delete your Pulse data right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
      currentUserProfileProvider,
    );
    final PulseStreak streak = ref.watch(currentUserStreakProvider);
    final PulseLevelProgress levelProgress = ref.watch(
      currentUserLevelProgressProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              final String headline = _errorMessage == null
                  ? 'Profile unavailable'
                  : 'Account deletion incomplete';
              final String body =
                  _errorMessage ??
                  'Your Pulse profile is not ready yet. Please try again in a moment.';

              if (_isDeletingAccount) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Deleting your Pulse data...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

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
                          headline,
                          style: textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          body,
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
            final String referralCode = PulseReferral.resolveReferralCode(
              profile.referralCode,
              uid: profile.uid,
            );
            final String referralCountLabel = profile.referralCount == 1
                ? '1 referral so far'
                : '${profile.referralCount} referrals so far';

            final String previewName =
                _displayNameController.text.trim().isNotEmpty
                ? _displayNameController.text.trim()
                : profile.greetingName;
            final String previewInitial = previewName
                .substring(0, 1)
                .toUpperCase();
            final String accountSummary = _buildAccountSummary(profile);
            final List<_ProfileSummaryStat> summaryStats =
                <_ProfileSummaryStat>[
                  _ProfileSummaryStat(
                    label: 'Current streak',
                    value: '${streak.currentStreak}',
                    supportingText: streak.currentStreak == 1 ? 'day' : 'days',
                  ),
                  _ProfileSummaryStat(
                    label: 'Best streak',
                    value: '${streak.longestStreak}',
                    supportingText: streak.longestStreak == 1 ? 'day' : 'days',
                  ),
                  _ProfileSummaryStat(
                    label: 'Level',
                    value: '${levelProgress.currentLevel}',
                    supportingText: '${levelProgress.totalXp} XP',
                  ),
                  _ProfileSummaryStat(
                    label: 'Badges',
                    value: '${profile.unlockedBadgeIds.length}',
                    supportingText: profile.unlockedBadgeIds.length == 1
                        ? 'unlocked'
                        : 'unlocked',
                  ),
                ];

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
                      const SizedBox(height: 8),
                      Text(
                        accountSummary,
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _ProfileSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Account snapshot',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A quick view of the Pulse progress already tied to your account.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: summaryStats
                                  .map((stat) {
                                    return _ProfileSummaryStatCard(stat: stat);
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        ),
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
                              enabled: !_isBusy,
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
                                      onTap: _isBusy
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
                              onPressed: _isBusy ? null : _pickReminderTime,
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
                              onChanged: _isBusy
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
                              onChanged: _isBusy
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
                              onChanged: _isBusy
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
                              onSelectionChanged: _isBusy
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
                      const SizedBox(height: 24),
                      _ProfileSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Referral code', style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Keep this code ready for future Pulse friend joins.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      referralCode,
                                      style: textTheme.headlineSmall?.copyWith(
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      referralCountLabel,
                                      style: textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  key: const Key(
                                    'profile-copy-referral-button',
                                  ),
                                  onPressed: _isBusy
                                      ? null
                                      : () => _copyReferralCode(referralCode),
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy code'),
                                ),
                                OutlinedButton.icon(
                                  key: const Key(
                                    'profile-share-referral-button',
                                  ),
                                  onPressed: _isBusy
                                      ? null
                                      : () => _showReferralShareSheet(profile),
                                  icon: const Icon(Icons.share_rounded),
                                  label: const Text('Share invite'),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('profile-view-friends-button'),
                                  onPressed: _isBusy
                                      ? null
                                      : () => context.goNamed(
                                          AppRoutes.leaderboardName,
                                        ),
                                  icon: const Icon(Icons.groups_rounded),
                                  label: const Text('View friends'),
                                ),
                              ],
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
                        onPressed: _isBusy ? null : _saveProfile,
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
                        onPressed: _isBusy
                            ? null
                            : () => context.goNamed(AppRoutes.badgesName),
                        child: const Text('View badges'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('profile-privacy-policy-button'),
                        onPressed: _isBusy ? null : _showPrivacyPolicySheet,
                        icon: const Icon(Icons.privacy_tip_rounded),
                        label: const Text('Privacy policy'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : () => _exportData(profile),
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
                      const SizedBox(height: 24),
                      _ProfileSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Delete account',
                              style: textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This removes your Pulse profile, saved sessions, progress, badges, settings, and stored messaging data from Firestore, then signs you out.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type DELETE to confirm before the action can proceed.',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              key: const Key('profile-delete-account-button'),
                              onPressed: _isBusy ? null : _deleteAccount,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              icon: _isDeletingAccount
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_forever_rounded),
                              label: Text(
                                _isDeletingAccount
                                    ? 'Deleting account...'
                                    : 'Delete account',
                              ),
                            ),
                          ],
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

  String _buildAccountSummary(PulseUserProfile profile) {
    final List<String> parts = <String>[];
    final DateTime? createdAt = profile.createdAt;
    if (createdAt != null) {
      parts.add(
        'Member since ${_monthNames[createdAt.month - 1]} ${createdAt.year}',
      );
    }

    if (profile.referredByUid != null ||
        profile.referredByReferralCode != null) {
      parts.add('Joined through a Pulse invite');
    }

    if (parts.isEmpty) {
      return 'Your Pulse account is ready for daily check-ins, progress tracking, and exports.';
    }

    return parts.join(' | ');
  }
}

class _ProfileSummaryStat {
  const _ProfileSummaryStat({
    required this.label,
    required this.value,
    required this.supportingText,
  });

  final String label;
  final String value;
  final String supportingText;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();

  bool get _canDelete => _controller.text.trim() == 'DELETE';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your Pulse account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This permanently deletes your Pulse-owned data from Firestore and signs you out.',
          ),
          const SizedBox(height: 12),
          const Text('Type DELETE to confirm.'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('delete-account-confirmation-input'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Confirmation',
              hintText: 'DELETE',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete-account-confirm-button'),
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Delete Pulse account'),
        ),
      ],
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

class _ProfileSummaryStatCard extends StatelessWidget {
  const _ProfileSummaryStatCard({required this.stat});

  final _ProfileSummaryStat stat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                stat.value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                stat.supportingText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
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

class _ReferralShareSheet extends StatelessWidget {
  const _ReferralShareSheet({required this.shareText, required this.onCopy});

  final String shareText;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.62,
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
              'Share your referral',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Copy this invite text to send your Pulse code anywhere.',
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
                  child: SelectableText(shareText, style: textTheme.bodyLarge),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCopy,
              child: const Text('Copy invite text'),
            ),
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

class _PrivacyPolicySheet extends StatelessWidget {
  const _PrivacyPolicySheet();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FractionallySizedBox(
      heightFactor: 0.82,
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
              'Pulse privacy policy',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This launch-ready summary reflects the Pulse data the app currently stores and uses.',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      _PrivacyPolicySection(
                        title: 'What Pulse stores',
                        body:
                            'Pulse stores your account profile, reminder settings, saved session history, streak and XP progress, unlocked badges, referrals, and messaging token data needed for the current app features.',
                      ),
                      SizedBox(height: 16),
                      _PrivacyPolicySection(
                        title: 'Why Pulse uses it',
                        body:
                            'This data keeps sign-in, daily sessions, reminders, insights, progress, social comparisons, and account recovery working across devices.',
                      ),
                      SizedBox(height: 16),
                      _PrivacyPolicySection(
                        title: 'Your controls',
                        body:
                            'You can export your current Pulse data from Profile at any time, and you can remove your Pulse-owned Firestore data with the delete-account flow.',
                      ),
                      SizedBox(height: 16),
                      _PrivacyPolicySection(
                        title: 'Offline and device data',
                        body:
                            'When the app is offline, Pulse can temporarily queue pending session data locally so it can sync cleanly once connectivity returns.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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

class _PrivacyPolicySection extends StatelessWidget {
  const _PrivacyPolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(body, style: textTheme.bodyMedium),
      ],
    );
  }
}
