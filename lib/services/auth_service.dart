/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:musify/main.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthState { authenticated, unauthenticated, loading }

class AuthResult {
  AuthResult({required this.success, this.error, this.user, this.message});
  final bool success;
  final String? error;
  final String? message;
  final RecordModel? user;
}

class AuthService {
  static late final PocketBase _pb;
  static final _authStateController = StreamController<AuthState>.broadcast();
  static final ValueNotifier<AuthState> authState = ValueNotifier(AuthState.unauthenticated);
  static final ValueNotifier<RecordModel?> currentUser = ValueNotifier(null);
  static late final _PersistentAuthStore _authStore;

  static PocketBase get pb => _pb;

  static Stream<AuthState> get authStateStream => _authStateController.stream;

  static Future<void> initialize() async {
    try {
      // Initialize persistent auth store
      _authStore = _PersistentAuthStore();
      await _authStore.init();

      // Initialize PocketBase with persistent auth store
      _pb = PocketBase('http://10.0.2.2:8090', authStore: _authStore);

      _pb.authStore.onChange.listen((e) async {
        final state = _pb.authStore.isValid ? AuthState.authenticated : AuthState.unauthenticated;
        authState.value = state;
        currentUser.value = _pb.authStore.record;
        _authStateController.add(state);

        if (state == AuthState.authenticated && _pb.authStore.record != null) {
          await _syncUserProfile();
        }
      });

      // Check if we have a stored auth session
      logger.log('Auth store isValid: ${_pb.authStore.isValid}', null, null);
      logger.log('Auth store token: ${_pb.authStore.token.isNotEmpty ? 'present' : 'empty'}', null, null);

      if (_pb.authStore.isValid) {
        try {
          logger.log('Attempting to refresh auth session...', null, null);
          await _pb.collection('users').authRefresh();
          authState.value = AuthState.authenticated;
          currentUser.value = _pb.authStore.record;
          await _syncUserProfile();
          logger.log('Auth session restored successfully for user: ${currentUser.value?.data['email']}', null, null);
        } catch (e) {
          logger.log('Auth refresh failed', e, null);
          await signOut();
        }
      } else {
        logger.log('No valid auth session found', null, null);
      }
    } catch (e) {
      logger.log('AuthService initialization failed', e, null);
      authState.value = AuthState.unauthenticated;
    }
  }

  static Future<AuthResult> signUp({required String email, required String password, required String username}) async {
    try {
      authState.value = AuthState.loading;

      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': username,
        'username': username,
        'emailVisibility': false,
        'verified': false,
      };

      await _pb.collection('users').create(body: userData);

      final authResult = await signIn(email: email, password: password);

      if (authResult.success) {
        await _createUserProfile();
        await _syncUserProfile();
      }

      return authResult;
    } catch (e) {
      authState.value = AuthState.unauthenticated;
      logger.log('Sign up failed', e, null);
      return AuthResult(success: false, error: _parseError(e.toString()));
    }
  }

  static Future<AuthResult> signIn({required String email, required String password}) async {
    try {
      authState.value = AuthState.loading;

      final authData = await _pb.collection('users').authWithPassword(email, password);

      authState.value = AuthState.authenticated;
      currentUser.value = authData.record;

      await _syncUserProfile();
      await _updateLastLogin();

      return AuthResult(success: true, user: authData.record);
    } catch (e) {
      authState.value = AuthState.unauthenticated;
      logger.log('Sign in failed', e, null);
      return AuthResult(success: false, error: _parseError(e.toString()));
    }
  }

  static Future<void> signOut() async {
    try {
      await _clearUserProfile();
      _pb.authStore.clear();
      authState.value = AuthState.unauthenticated;
      currentUser.value = null;
      logger.log('User signed out successfully', null, null);
    } catch (e) {
      logger.log('Sign out failed', e, null);
    }
  }

  static bool get isAuthenticated => _pb.authStore.isValid;

  static String? get userEmail => currentUser.value?.data['email'];

  static String? get userName => currentUser.value?.data['username'];

  static String? get userId => currentUser.value?.id;

  static String? get userAvatar => currentUser.value?.data['avatar'];

  static String? get userDisplayName =>
    currentUser.value?.data['name'] ?? currentUser.value?.data['username'];

  static DateTime? get userCreated =>
    currentUser.value?.data['created'] != null ?
    DateTime.tryParse(currentUser.value!.data['created']) : null;

  static DateTime? get lastLogin =>
    currentUser.value?.data['lastLogin'] != null ?
    DateTime.tryParse(currentUser.value!.data['lastLogin']) : null;

  static bool get isVerified => currentUser.value?.data['verified'] ?? false;

  // Helper methods for profile management
  static Future<void> _syncUserProfile() async {
    try {
      if (!isAuthenticated || currentUser.value == null) return;

      final userData = currentUser.value!.data;

      // Sync to both Hive (for app data) and SharedPreferences (for auth data)
      final userBox = await Hive.openBox('user');
      await userBox.putAll({
        'userId': currentUser.value!.id,
        'email': userData['email'],
        'username': userData['username'] ?? userData['name'],
        'name': userData['name'],
        'avatar': userData['avatar'],
        'created': userData['created'],
        'lastLogin': userData['lastLogin'],
        'verified': userData['verified'],
        'lastSyncTime': DateTime.now().toIso8601String(),
      });

      // Also sync to SharedPreferences for consistent access
      await _syncUserToPreferences();

      logger.log('User profile synced successfully', null, null);
    } catch (e) {
      logger.log('Failed to sync user profile', e, null);
    }
  }

  static Future<void> _syncUserToPreferences() async {
    try {
      if (!isAuthenticated || currentUser.value == null) return;

      final prefs = await SharedPreferences.getInstance();
      final userData = currentUser.value!.data;

      // Sync current user data to SharedPreferences
      await prefs.setString('current_user_id', currentUser.value!.id);
      await prefs.setString('current_user_email', userData['email'] ?? '');
      await prefs.setString('current_user_name', userData['name'] ?? '');
      await prefs.setString('current_user_username', userData['username'] ?? userData['name'] ?? '');
      await prefs.setString('current_user_avatar', userData['avatar'] ?? '');
      await prefs.setBool('current_user_verified', userData['verified'] ?? false);
      await prefs.setString('current_user_created', userData['created'] ?? '');
      await prefs.setString('sync_timestamp', DateTime.now().toIso8601String());

      logger.log('User data synced to SharedPreferences', null, null);
    } catch (e) {
      logger.log('Failed to sync user data to SharedPreferences', e, null);
    }
  }

  static Future<void> _createUserProfile() async {
    try {
      if (!isAuthenticated || currentUser.value == null) return;

      // Create initial user profile data
      final userBox = await Hive.openBox('user');
      await userBox.putAll({
        'firstTimeSetup': true,
        'profileCreated': DateTime.now().toIso8601String(),
        'preferences': {
          'theme': 'system',
          'language': 'auto',
          'notifications': true,
          'autoBackup': true,
        },
      });

      logger.log('User profile created successfully', null, null);
    } catch (e) {
      logger.log('Failed to create user profile', e, null);
    }
  }

  static Future<void> _updateLastLogin() async {
    try {
      if (!isAuthenticated || currentUser.value == null) return;

      await _pb.collection('users').update(
        currentUser.value!.id,
        body: {'lastLogin': DateTime.now().toIso8601String()},
      );

      logger.log('Last login updated', null, null);
    } catch (e) {
      logger.log('Failed to update last login', e, null);
    }
  }

  static Future<void> _clearUserProfile() async {
    try {
      final userBox = await Hive.openBox('user');
      await userBox.clear();

      // Keep some non-sensitive settings
      final settingsBox = await Hive.openBox('settings');
      final keepSettings = {
        'themeMode': settingsBox.get('themeMode'),
        'language': settingsBox.get('language'),
        'audioQuality': settingsBox.get('audioQuality'),
      };

      await settingsBox.clear();
      await settingsBox.putAll(keepSettings);

      // Clear user data from SharedPreferences
      await _clearUserFromPreferences();

      logger.log('User profile cleared', null, null);
    } catch (e) {
      logger.log('Failed to clear user profile', e, null);
    }
  }

  static Future<void> _clearUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear current user data from SharedPreferences
      await prefs.remove('current_user_id');
      await prefs.remove('current_user_email');
      await prefs.remove('current_user_name');
      await prefs.remove('current_user_username');
      await prefs.remove('current_user_avatar');
      await prefs.remove('current_user_verified');
      await prefs.remove('current_user_created');
      await prefs.remove('sync_timestamp');

      logger.log('User data cleared from SharedPreferences', null, null);
    } catch (e) {
      logger.log('Failed to clear user data from SharedPreferences', e, null);
    }
  }

  static String _parseError(String error) {
    try {
      // Parse PocketBase errors
      if (error.contains('Failed to authenticate')) {
        return 'Email hoặc mật khẩu không đúng';
      }
      if (error.contains('email must be a valid email')) {
        return 'Email không hợp lệ';
      }
      if (error.contains('password must be at least')) {
        return 'Mật khẩu phải có ít nhất 8 ký tự';
      }
      if (error.contains('email already exists')) {
        return 'Email này đã được đăng ký';
      }
      if (error.contains('username already exists')) {
        return 'Tên người dùng đã tồn tại';
      }
      if (error.contains('network')) {
        return 'Lỗi kết nối mạng. Vui lòng thử lại';
      }

      return 'Đã xảy ra lỗi. Vui lòng thử lại';
    } catch (e) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại';
    }
  }

  // Profile management methods
  static Future<AuthResult> updateProfile({
    String? name,
    String? username,
  }) async {
    try {
      if (!isAuthenticated || currentUser.value == null) {
        return AuthResult(success: false, error: 'Chưa đăng nhập');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (username != null) updateData['username'] = username;

      if (updateData.isEmpty) {
        return AuthResult(success: true);
      }

      final updatedUser = await _pb.collection('users').update(
        currentUser.value!.id,
        body: updateData,
      );

      currentUser.value = updatedUser;
      await _syncUserProfile();

      return AuthResult(success: true, user: updatedUser);
    } catch (e) {
      logger.log('Profile update failed', e, null);
      return AuthResult(success: false, error: _parseError(e.toString()));
    }
  }

  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (!isAuthenticated || currentUser.value == null) {
        return AuthResult(success: false, error: 'Chưa đăng nhập');
      }

      await _pb.collection('users').update(
        currentUser.value!.id,
        body: {
          'oldPassword': currentPassword,
          'password': newPassword,
          'passwordConfirm': newPassword,
        },
      );

      return AuthResult(success: true, message: 'Đổi mật khẩu thành công');
    } catch (e) {
      logger.log('Password change failed', e, null);
      return AuthResult(success: false, error: _parseError(e.toString()));
    }
  }

  static Future<bool> isEmailVerified() async {
    try {
      if (!isAuthenticated) return false;

      await _pb.collection('users').authRefresh();
      return currentUser.value?.data['verified'] ?? false;
    } catch (e) {
      logger.log('Email verification check failed', e, null);
      return false;
    }
  }

  static Future<AuthResult> requestPasswordReset(String email) async {
    try {
      await _pb.collection('users').requestPasswordReset(email);
      return AuthResult(success: true, message: 'Email đặt lại mật khẩu đã được gửi');
    } catch (e) {
      logger.log('Password reset request failed', e, null);
      return AuthResult(success: false, error: _parseError(e.toString()));
    }
  }

  // Session management
  static Future<void> refreshSession() async {
    try {
      if (_pb.authStore.isValid) {
        await _pb.collection('users').authRefresh();
        currentUser.value = _pb.authStore.record;
        await _syncUserProfile();
      }
    } catch (e) {
      logger.log('Session refresh failed', e, null);
      await signOut();
    }
  }

  static void dispose() {
    _authStateController.close();
  }
}

// Custom AuthStore for persistent authentication with SharedPreferences
class _PersistentAuthStore extends AuthStore {
  static const String _tokenKey = 'pb_auth_token';
  static const String _recordKey = 'pb_auth_record';
  static const String _userIdKey = 'pb_user_id';
  static const String _userEmailKey = 'pb_user_email';
  static const String _userNameKey = 'pb_user_name';
  static const String _userAvatarKey = 'pb_user_avatar';
  static const String _userVerifiedKey = 'pb_user_verified';
  static const String _lastLoginKey = 'pb_last_login';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Restore token and record from SharedPreferences
    final storedToken = _prefs.getString(_tokenKey);
    final storedRecordJson = _prefs.getString(_recordKey);

    if (storedToken != null && storedRecordJson != null) {
      try {
        final recordData = jsonDecode(storedRecordJson) as Map<String, dynamic>;
        final record = RecordModel.fromJson(recordData);
        super.save(storedToken, record);
        logger.log('Auth session restored from SharedPreferences', null, null);
      } catch (e) {
        logger.log('Failed to restore auth record', e, null);
        // Clear corrupted data
        await _clearStoredAuth();
      }
    }
  }

  @override
  void save(String token, RecordModel? record) {
    super.save(token, record);

    // Persist to SharedPreferences
    _prefs.setString(_tokenKey, token);
    if (record != null) {
      _prefs.setString(_recordKey, jsonEncode(record.toJson()));

      // Save individual user fields for easy access
      final data = record.data;
      _prefs.setString(_userIdKey, record.id);
      _prefs.setString(_userEmailKey, data['email'] ?? '');
      _prefs.setString(_userNameKey, data['name'] ?? '');
      _prefs.setString(_userAvatarKey, data['avatar'] ?? '');
      _prefs.setBool(_userVerifiedKey, data['verified'] ?? false);
      _prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    }

    logger.log('Auth session saved to SharedPreferences', null, null);
  }

  @override
  void clear() {
    super.clear();
    _clearStoredAuth();
    logger.log('Auth session cleared from SharedPreferences', null, null);
  }

  Future<void> _clearStoredAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_recordKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userAvatarKey);
    await _prefs.remove(_userVerifiedKey);
    await _prefs.remove(_lastLoginKey);
  }

  // Helper methods to get user info directly from SharedPreferences
  static Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getStoredUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getStoredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<bool> hasStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey) && prefs.containsKey(_recordKey);
  }

  // Public helper method to check if user is logged in via SharedPreferences
  static Future<Map<String, dynamic>?> getStoredUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('current_user_id')) return null;

      return {
        'id': prefs.getString('current_user_id'),
        'email': prefs.getString('current_user_email'),
        'name': prefs.getString('current_user_name'),
        'username': prefs.getString('current_user_username'),
        'avatar': prefs.getString('current_user_avatar'),
        'verified': prefs.getBool('current_user_verified') ?? false,
        'created': prefs.getString('current_user_created'),
        'syncTime': prefs.getString('sync_timestamp'),
      };
    } catch (e) {
      logger.log('Failed to get stored user info', e, null);
      return null;
    }
  }
}
