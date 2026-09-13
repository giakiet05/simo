import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simo/models/user_profile.dart';
import 'package:simo/providers/auth_provider.dart';
import 'package:simo/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Continuity & Session Restoration Tests', () {
    test('App restores cached user session offline without any network call', () async {
      final user = const UserProfile(
        id: '12345678-1234-1234-1234-123456789abc',
        email: 'offline.user@simo.app',
        displayName: 'Offline User',
      );

      // Pre-populate SharedPreferences with existing offline session
      SharedPreferences.setMockInitialValues({
        'auth_session_token': 'cached_jwt_token_xyz',
        'sync_auth_token': 'cached_jwt_token_xyz',
        'auth_user_profile': jsonEncode(user.toJson()),
      });

      final authService = AuthService();
      final notifier = AuthNotifier(authService);

      await notifier.initializeSession();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.token, 'cached_jwt_token_xyz');
      expect(notifier.state.user?.email, 'offline.user@simo.app');
      expect(notifier.state.user?.displayName, 'Offline User');
    });

    test('App initializes in unauthenticated state if no cached session exists', () async {
      SharedPreferences.setMockInitialValues({});

      final authService = AuthService();
      final notifier = AuthNotifier(authService);

      await notifier.initializeSession();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.token, isNull);
      expect(notifier.state.user, isNull);
    });

    test('Corrupted profile JSON gracefully falls back to unauthenticated state', () async {
      SharedPreferences.setMockInitialValues({
        'auth_session_token': 'cached_jwt_token_xyz',
        'auth_user_profile': '{invalid_json',
      });

      final authService = AuthService();
      final notifier = AuthNotifier(authService);

      await notifier.initializeSession();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, isFalse);
    });
  });
}
