import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/env_config.dart';
import '../../core/remote/supabase_table_names.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../local/device_id_service.dart';
import '../remote/supabase_service.dart';
import '../../core/auth/auth_session_cache.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUserRecord {
  const AppUserRecord({
    required this.id,
    required this.authUserId,
    required this.displayName,
    required this.role,
    this.employeeId,
    this.email,
  });

  final String id;
  final String authUserId;
  final String displayName;
  final UserRole role;
  final String? employeeId;
  final String? email;
}

class AuthRepository {
  AuthRepository({
    required AuthSessionCache? cache,
    required DeviceIdService deviceId,
    SupabaseClient? client,
  })  : _cache = cache,
        _deviceId = deviceId,
        _client = client;

  final AuthSessionCache? _cache;
  final DeviceIdService _deviceId;
  final SupabaseClient? _client;

  bool get isAuthEnabled =>
      EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;

  SupabaseClient get _supabase {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not available');
    }
    return client;
  }

  Future<AppUser?> loadCachedUser() async => _cache?.load();

  Future<void> cacheUser(AppUser user) async => _cache?.save(user);

  Future<void> clearCachedUser() async => _cache?.clear();

  Future<AppUser?> restoreRemoteSession() async {
    if (!isAuthEnabled) return null;

    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    try {
      return await _fetchProfileForCurrentAuthUser();
    } catch (error) {
      debugPrint('AuthRepository: profile fetch failed ($error)');
      return null;
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!isAuthEnabled) {
      throw AuthException('Supabase is not configured');
    }

    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session == null || response.user == null) {
      throw AuthException('Sign in failed — no session returned');
    }

    final profile = await _fetchProfileForCurrentAuthUser();
    await cacheUser(profile);
    return profile;
  }

  Future<void> signOut() async {
    await clearCachedUser();
    if (isAuthEnabled) {
      await _supabase.auth.signOut();
    }
  }

  Future<AppUser> createAppUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? employeeId,
  }) async {
    if (!isAuthEnabled) {
      throw AuthException('Supabase is not configured');
    }

    final adminSession = _supabase.auth.currentSession;
    if (adminSession == null) {
      throw AuthException('You must be signed in as admin to create users');
    }

    final signUpResponse = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final authUserId = signUpResponse.user?.id;
    if (authUserId == null) {
      throw AuthException('User account was not created');
    }

    await _supabase.auth.recoverSession(jsonEncode(adminSession.toJson()));

    final now = DateTime.now().toUtc().toIso8601String();
    final id = const Uuid().v4();
    await _supabase.from(SupabaseTableNames.appUsers).insert({
      'id': id,
      'auth_user_id': authUserId,
      'employee_id': employeeId,
      'role': role.name,
      'display_name': displayName.trim(),
      'created_at': now,
      'updated_at': now,
      'is_synced': true,
      'sync_action': 'create',
      'device_id': _deviceId.id,
      'version': 1,
    });

    return AppUser(
      id: id,
      authUserId: authUserId,
      employeeId: employeeId,
      name: displayName.trim(),
      role: role,
    );
  }

  Future<List<AppUserRecord>> listAppUsers() async {
    if (!isAuthEnabled) return [];

    final rows = await _supabase
        .from(SupabaseTableNames.appUsers)
        .select('id, auth_user_id, employee_id, role, display_name')
        .isFilter('deleted_at', null)
        .order('display_name');

    return (rows as List<dynamic>).map(_parseAppUserRecord).toList();
  }

  Future<AppUser> _fetchProfileForCurrentAuthUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      throw AuthException('No authenticated user');
    }

    final row = await _supabase
        .from(SupabaseTableNames.appUsers)
        .select('id, auth_user_id, employee_id, role, display_name')
        .eq('auth_user_id', authUser.id)
        .isFilter('deleted_at', null)
        .maybeSingle();

    if (row == null) {
      throw AuthException(
        'No app profile found for this login. Ask an admin to create your user.',
      );
    }

    return _appUserFromRow(Map<String, dynamic>.from(row));
  }

  AppUser _appUserFromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      authUserId: row['auth_user_id'] as String?,
      employeeId: row['employee_id'] as String?,
      name: row['display_name'] as String? ?? 'User',
      role: UserRole.values.firstWhere(
        (role) => role.name == row['role'],
        orElse: () => UserRole.salesman,
      ),
    );
  }

  AppUserRecord _parseAppUserRecord(dynamic row) {
    final map = row as Map<String, dynamic>;
    return AppUserRecord(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'User',
      employeeId: map['employee_id'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.salesman,
      ),
    );
  }
}
