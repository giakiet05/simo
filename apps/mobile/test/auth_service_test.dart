import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simo/models/user_profile.dart';
import 'package:simo/providers/auth_provider.dart';
import 'package:simo/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfile Model Tests', () {
    test('UserProfile serializes and deserializes correctly', () {
      final user = const UserProfile(
        id: '11111111-2222-3333-4444-555555555555',
        email: 'test@simo.app',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/photo.jpg',
      );

      final jsonMap = user.toJson();
      expect(jsonMap['id'], '11111111-2222-3333-4444-555555555555');
      expect(jsonMap['email'], 'test@simo.app');
      expect(jsonMap['display_name'], 'Test User');
      expect(jsonMap['avatar_url'], 'https://example.com/photo.jpg');

      final reconstructed = UserProfile.fromJson(jsonMap);
      expect(reconstructed.id, user.id);
      expect(reconstructed.email, user.email);
      expect(reconstructed.displayName, user.displayName);
      expect(reconstructed.avatarUrl, user.avatarUrl);
    });
  });

  group('AuthService Tests', () {
    late AuthService authService;
    late http.Client mockClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/google')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final idToken = body['id_token'] as String?;
          if (idToken == 'valid_token' || idToken == 'mock_google_token_dev') {
            return http.Response(
              jsonEncode({
                'message': 'Authenticated successfully',
                'data': {
                  'token': 'jwt_session_token_12345',
                  'user': {
                    'id': '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                    'email': 'dev.user@simo.app',
                    'display_name': 'Dev User',
                    'avatar_url': null,
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'message': 'Invalid token', 'error': 'INVALID_TOKEN'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      authService = AuthService(httpClient: mockClient);
    });

    test('exchangeGoogleToken successfully saves session and returns user profile', () async {
      final result = await authService.exchangeGoogleToken('valid_token');

      expect(result.token, 'jwt_session_token_12345');
      expect(result.user.email, 'dev.user@simo.app');
      expect(result.user.displayName, 'Dev User');

      // Verify cached session
      final cached = await authService.getCachedSession();
      expect(cached.token, 'jwt_session_token_12345');
      expect(cached.user?.email, 'dev.user@simo.app');
    });

    test('exchangeGoogleToken throws exception on invalid token', () async {
      expect(
        () => authService.exchangeGoogleToken('bad_token'),
        throwsA(isA<Exception>()),
      );
    });

    test('signOut clears cached tokens', () async {
      await authService.exchangeGoogleToken('valid_token');
      var cached = await authService.getCachedSession();
      expect(cached.token, isNotNull);

      await authService.signOut();
      cached = await authService.getCachedSession();
      expect(cached.token, isNull);
      expect(cached.user, isNull);
    });
  });

  group('AuthNotifier Tests', () {
    test('AuthNotifier handles mock sign-in and sign-out states', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Authenticated',
            'data': {
              'token': 'mock_jwt_token',
              'user': {
                'id': 'user_id_123',
                'email': 'mock@simo.app',
                'display_name': 'Mock User',
                'avatar_url': null,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(httpClient: mockClient);
      final notifier = AuthNotifier(authService);

      await notifier.initializeSession();
      expect(notifier.state.status, AuthStatus.unauthenticated);

      final success = await notifier.signInWithMockToken('mock_token');
      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.token, 'mock_jwt_token');
      expect(notifier.state.user?.email, 'mock@simo.app');

      await notifier.signOut();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.token, isNull);
    });
  });
}
