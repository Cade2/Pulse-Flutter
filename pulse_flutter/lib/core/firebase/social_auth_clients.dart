import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class PulseSocialAuthException implements Exception {
  const PulseSocialAuthException({
    required this.providerLabel,
    required this.message,
    this.code = 'unknown',
  });

  factory PulseSocialAuthException.cancelled(String providerLabel) {
    return PulseSocialAuthException(
      providerLabel: providerLabel,
      message: '$providerLabel sign-in was cancelled.',
      code: 'cancelled',
    );
  }

  factory PulseSocialAuthException.unavailable(String providerLabel) {
    return PulseSocialAuthException(
      providerLabel: providerLabel,
      message: '$providerLabel sign-in is not available on this device yet.',
      code: 'unavailable',
    );
  }

  factory PulseSocialAuthException.failed(
    String providerLabel, {
    String? message,
    String code = 'failed',
  }) {
    return PulseSocialAuthException(
      providerLabel: providerLabel,
      message:
          message ?? '$providerLabel sign-in could not be completed right now.',
      code: code,
    );
  }

  final String providerLabel;
  final String message;
  final String code;

  @override
  String toString() => message;
}

class PulseSocialAuthCredential {
  const PulseSocialAuthCredential({
    this.idToken,
    this.accessToken,
    this.displayName,
  });

  final String? idToken;
  final String? accessToken;
  final String? displayName;
}

abstract class PulseGoogleSignInClient {
  bool get isSupported;

  Future<PulseSocialAuthCredential?> signIn();

  Future<void> signOut();
}

abstract class PulseAppleSignInClient {
  Future<bool> isAvailable();

  Future<PulseSocialAuthCredential?> signIn();
}

class PulseGoogleSignInClientImpl implements PulseGoogleSignInClient {
  PulseGoogleSignInClientImpl({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  @override
  bool get isSupported {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Future<PulseSocialAuthCredential?> signIn() async {
    if (!isSupported) {
      throw PulseSocialAuthException.unavailable('Google');
    }

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;

      return PulseSocialAuthCredential(
        idToken: authentication.idToken,
        accessToken: authentication.accessToken,
        displayName: account.displayName,
      );
    } on PlatformException catch (error) {
      throw PulseSocialAuthException.failed(
        'Google',
        message: error.message,
        code: error.code,
      );
    } catch (_) {
      throw PulseSocialAuthException.failed('Google');
    }
  }

  @override
  Future<void> signOut() async {
    if (!isSupported) {
      return;
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best effort only.
    }
  }
}

class PulseAppleSignInClientImpl implements PulseAppleSignInClient {
  const PulseAppleSignInClientImpl();

  @override
  Future<bool> isAvailable() async {
    if (!_supportsAppleSignIn) {
      return false;
    }

    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PulseSocialAuthCredential?> signIn() async {
    if (!await isAvailable()) {
      throw PulseSocialAuthException.unavailable('Apple');
    }

    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      return PulseSocialAuthCredential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
        displayName: _combineName(
          credential.givenName,
          credential.familyName,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }

      throw PulseSocialAuthException.failed(
        'Apple',
        message: error.message,
        code: error.code.name,
      );
    } on PlatformException catch (error) {
      throw PulseSocialAuthException.failed(
        'Apple',
        message: error.message,
        code: error.code,
      );
    } catch (_) {
      throw PulseSocialAuthException.failed('Apple');
    }
  }

  static bool get _supportsAppleSignIn {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String? _combineName(String? givenName, String? familyName) {
    final String combined = <String?>[givenName, familyName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');

    return combined.isEmpty ? null : combined;
  }
}
