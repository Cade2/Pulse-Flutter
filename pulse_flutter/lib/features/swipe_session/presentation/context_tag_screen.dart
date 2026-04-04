import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class ContextTagScreen extends ConsumerStatefulWidget {
  const ContextTagScreen({super.key, this.summary});

  final SwipeSessionSummary? summary;

  @override
  ConsumerState<ContextTagScreen> createState() => _ContextTagScreenState();
}

class _ContextTagScreenState extends ConsumerState<ContextTagScreen> {
  static const List<String> _socialOptions = <String>[
    'Alone',
    'Friends',
    'Partner',
    'Family',
    'Crowded',
  ];

  static const List<String> _energyOptions = <String>['Low', 'Steady', 'High'];

  static const List<String> _sleepOptions = <String>['Poor', 'Okay', 'Good'];

  String? _socialContext;
  String? _energy;
  String? _sleep;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _saveSession() async {
    final SwipeSessionSummary? summary = widget.summary;
    if (summary == null || summary.responses.isEmpty) {
      setState(() {
        _errorMessage = 'There is no completed swipe session to save yet.';
      });
      return;
    }

    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      setState(() {
        _errorMessage = 'Please sign in again before saving this session.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final SwipeSessionRecord record = await ref
          .read(swipeSessionRepositoryProvider)
          .saveSession(
            uid: uid,
            summary: summary,
            contextSocial: _socialContext,
            contextEnergy: _energy,
            contextSleep: _sleep,
          );

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoutes.swipeSessionCompleteName, extra: record);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'We could not save this session right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SwipeSessionSummary? summary = widget.summary;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (summary == null || summary.responses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session context')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'No session found',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start a swipe session from Home before adding context tags.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.goNamed(AppRoutes.homeName),
                      child: const Text('Return home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Session context')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add optional context',
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tag this session before saving it. You reviewed ${summary.totalCards} cards and accepted ${summary.acceptedCount}.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _ContextChipSection(
                    title: 'Social context',
                    selectedValue: _socialContext,
                    options: _socialOptions,
                    onSelected: (value) {
                      setState(() {
                        _socialContext = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _ContextChipSection(
                    title: 'Energy',
                    selectedValue: _energy,
                    options: _energyOptions,
                    onSelected: (value) {
                      setState(() {
                        _energy = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _ContextChipSection(
                    title: 'Sleep',
                    selectedValue: _sleep,
                    options: _sleepOptions,
                    onSelected: (value) {
                      setState(() {
                        _sleep = value;
                      });
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveSession,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save session'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextChipSection extends StatelessWidget {
  const _ContextChipSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options
              .map((option) {
                final bool isSelected = selectedValue == option;

                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) {
                    onSelected(isSelected ? null : option);
                  },
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
