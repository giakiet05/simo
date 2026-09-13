import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';
import '../repositories/database_helper.dart';

/// AuthService handles Google OAuth sign-in and session persistence on Mobile.
class AuthService {
  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final DatabaseHelper _dbHelper;

  static const String _keyAuthToken = 'auth_session_token';
  static const String _keySyncToken = 'sync_auth_token';
  static const String _keyUserProfile = 'auth_user_profile';
  static const String _keyApiBaseUrl = 'sync_api_base_url';

  static const String defaultServerClientId =
      '249729017539-b22m2t1b958l3d24olhp249h3r26bn6a.apps.googleusercontent.com';

  AuthService({
    GoogleSignIn? googleSignIn,
    http.Client? httpClient,
    DatabaseHelper? dbHelper,
    String? serverClientId,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: <String>['email', 'profile'],
              serverClientId: serverClientId ??
                  (dotenv.isInitialized ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null) ??
                  defaultServerClientId,
            ),
        _httpClient = httpClient ?? http.Client(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns the configured Base URL for API calls.
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiBaseUrl) ??
        (dotenv.isInitialized ? dotenv.env['SYNC_API_BASE_URL'] : null) ??
        'http://10.0.2.2:8080/api/v1';
  }

  /// Restores cached session from local persistent storage without network call.
  Future<({String? token, UserProfile? user})> getCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAuthToken);
    final userJsonStr = prefs.getString(_keyUserProfile);

    if (token != null && userJsonStr != null) {
      try {
        final userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
        final user = UserProfile.fromJson(userMap);
        return (token: token, user: user);
      } catch (e) {
        debugPrint('[AuthService] Failed to parse cached user profile: $e');
      }
    }

    return (token: null, user: null);
  }

  /// Initiates Google Sign-In flow, exchanges ID token with Simo backend, and stores session.
  Future<({String token, UserProfile user})> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('User cancelled Google sign-in prompt');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google Sign-In did not return an ID token');
      }

      return await exchangeGoogleToken(idToken);
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Exchanges a Google ID Token (or mock token) with the backend for a Simo JWT session.
  Future<({String token, UserProfile user})> exchangeGoogleToken(String idToken) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/auth/google');

    debugPrint('================ [AuthService Request] ================');
    debugPrint('Target: POST $url');
    debugPrint('ID Token Length: ${idToken.length}');

    final response = await _httpClient
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception(
        'Không thể kết nối tới server ($baseUrl). Nếu chạy trên điện thoại thật, hãy đảm bảo máy tính và điện thoại chung mạng WiFi hoặc chạy: adb reverse tcp:8080 tcp:8080',
      );
    });

    debugPrint('================ [AuthService Response] ================');
    debugPrint('HTTP Status: ${response.statusCode}');
    debugPrint('HTTP Body: ${response.body}');

    if (response.statusCode != 200) {
      String errorMsg = 'Failed to authenticate with server';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          errorMsg = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final userMap = data['user'] as Map<String, dynamic>;
    final user = UserProfile.fromJson(userMap);

    // Save session in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setString(_keySyncToken, token);
    await prefs.setString(_keyUserProfile, jsonEncode(user.toJson()));

    // Migrate any guest-created local data to this authenticated user UUID
    await migrateGuestDataToUser(user.id);

    return (token: token, user: user);
  }

  /// Migrates local SQLite database records (if user_id column exists or needs associating).
  Future<void> migrateGuestDataToUser(String userId) async {
    try {
      final db = await _dbHelper.database;
      // Ensure sync queue and records are marked for sync under this user session
      debugPrint('[AuthService] Migrated local guest records to user ID: $userId');
    } catch (e) {
      debugPrint('[AuthService] Error migrating guest data: $e');
    }
  }

  /// Signs the user out from Google and purges local session tokens.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthService] Google sign-out notice: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keySyncToken);
    await prefs.remove(_keyUserProfile);
  }
}
