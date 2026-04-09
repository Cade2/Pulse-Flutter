import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/firebase/firebase_auth_service.dart';
import 'package:pulse_flutter/core/firebase/social_auth_clients.dart';
import 'package:pulse_flutter/core/firestore/user_profile_repository.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

enum _AuthAction { signIn, createAccount, googleSignIn, appleSignIn }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _isSubmitting = false;
  String? _errorMessage;
  _AuthAction? _activeAction;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth(_AuthAction action) async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    await _authenticate(action, (authService) {
      if (action == _AuthAction.signIn) {
        return authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      return authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    });
  }

  Future<void> _submitSocialAuth(_AuthAction action) async {
    await _authenticate(action, (authService) {
      if (action == _AuthAction.googleSignIn) {
        return authService.signInWithGoogle();
      }

      return authService.signInWithApple();
    });
  }

  Future<void> _authenticate(
    _AuthAction action,
    Future<UserCredential> Function(FirebaseAuthService authService)
    authenticate,
  ) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _activeAction = action;
      _errorMessage = null;
    });

    bool didAuthenticate = false;

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      final String? referralCode = await _resolveReferralCodeForAction(
        action,
        userProfileRepository,
      );
      final UserCredential userCredential = await authenticate(authService);

      didAuthenticate = true;

      final User? user = userCredential.user ?? authService.currentUser;
      if (user == null) {
        throw StateError('Authentication completed without a user.');
      }

      await userProfileRepository.ensureUserProfile(
        user,
        referralCode: _shouldRedeemReferralCode(action, userCredential)
            ? referralCode
            : null,
      );

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoutes.homeName);
    } on PulseSocialAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } on PulseReferralRedemptionException catch (error) {
      if (didAuthenticate) {
        await _rollbackAuthenticatedSession();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _firebaseAuthMessage(error);
      });
    } catch (_) {
      if (didAuthenticate) {
        await _rollbackAuthenticatedSession();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = didAuthenticate
            ? 'We couldn\'t finish setting up your profile. Please try again.'
            : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _activeAction = null;
        });
      }
    }
  }

  Future<String?> _resolveReferralCodeForAction(
    _AuthAction action,
    UserProfileRepository userProfileRepository,
  ) async {
    if (action == _AuthAction.signIn) {
      return null;
    }

    final String rawReferralCode = _referralCodeController.text.trim();
    if (rawReferralCode.isEmpty) {
      return null;
    }

    final String? normalizedReferralCode = PulseReferral.normalizeReferralCode(
      rawReferralCode,
    );
    if (normalizedReferralCode == null) {
      throw PulseReferralRedemptionException.invalidCode();
    }

    await userProfileRepository.validateReferralCodeForRegistration(
      normalizedReferralCode,
    );
    return normalizedReferralCode;
  }

  bool _shouldRedeemReferralCode(
    _AuthAction action,
    UserCredential credential,
  ) {
    if (action == _AuthAction.signIn) {
      return false;
    }

    if (_referralCodeController.text.trim().isEmpty) {
      return false;
    }

    if (action == _AuthAction.createAccount) {
      return true;
    }

    return credential.additionalUserInfo?.isNewUser ?? false;
  }

  Future<void> _rollbackAuthenticatedSession() async {
    try {
      await ref.read(firebaseAuthServiceProvider).signOut();
    } catch (_) {
      // Best effort only. The UI still surfaces the original error.
    }
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOffline = ref.watch(isOfflineProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use your Pulse email and password to sign in, or create an account to get started.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        if (!_isSubmitting) {
                          _submitEmailAuth(_AuthAction.signIn);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('login-referral-code-field'),
                      controller: _referralCodeController,
                      enabled: !_isSubmitting,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Referral code (optional)',
                        hintText: 'PULSE1234ABCD',
                        helperText:
                            'Only used when creating a new Pulse account.',
                      ),
                    ),
                    if (isOffline) ...[
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You\'re offline. Pulse sign-in and account creation still need a connection, but your local data will stay on this device once you\'re back online.',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitEmailAuth(_AuthAction.signIn),
                      child: _activeAction == _AuthAction.signIn
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitEmailAuth(_AuthAction.createAccount),
                      child: _activeAction == _AuthAction.createAccount
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitSocialAuth(_AuthAction.googleSignIn),
                      icon: _activeAction == _AuthAction.googleSignIn
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.public_rounded),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitSocialAuth(_AuthAction.appleSignIn),
                      icon: _activeAction == _AuthAction.appleSignIn
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.apple),
                      label: const Text('Continue with Apple'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
