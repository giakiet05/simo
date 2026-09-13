import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// AuthStatus reflects the lifecycle state of user authentication.
enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// AuthState encapsulates the current user session and authentication status.
class AuthState {
  final AuthStatus status;
  final String? token;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.token,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  bool get isAuthenticated => status == AuthStatus.authenticated && token != null;
  bool get isLoading => status == AuthStatus.authenticating || status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// AuthNotifier manages the global authentication state across the app.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    initializeSession();
  }

  /// Initializes session from local persistent cache without blocking offline usage.
  Future<void> initializeSession() async {
    try {
      final cached = await _authService.getCachedSession();
      if (cached.token != null && cached.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          token: cached.token,
          user: cached.user,
        );
        return;
      }
    } catch (_) {}

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Triggers Google Sign-In flow.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final session = await _authService.signInWithGoogle();
      state = AuthState(
        status: AuthStatus.authenticated,
        token: session.token,
        user: session.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Authenticates using a mock ID token (for local development/testing).
  Future<bool> signInWithMockToken([String mockToken = 'mock_google_token_dev']) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final session = await _authService.exchangeGoogleToken(mockToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        token: session.token,
        user: session.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Logs out the user and clears stored session credentials.
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider for AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for global AuthState.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
