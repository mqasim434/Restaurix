import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../core/auth/auth_session_cache.dart';
import '../../../core/sync/realtime_auth_binder.dart';
import '../../../core/config/env_config.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/remote/supabase_service.dart';
import '../../../data/repositories/app_setting_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/app_user.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.unauthenticated({String? errorMessage})
      : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  const AuthState.authenticated(AppUser user)
      : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
}

final authSessionCacheProvider = Provider<AuthSessionCache?>((ref) {
  if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
    return null;
  }
  return AuthSessionCache(
    AppSettingRepository(ref.watch(isarProvider)),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  supa.SupabaseClient? client;
  if (EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized) {
    client = supa.Supabase.instance.client;
  }

  return AuthRepository(
    cache: ref.watch(authSessionCacheProvider),
    deviceId: ref.watch(deviceIdServiceProvider),
    client: client,
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

/// Signed-in profile for the rest of the app.
///
/// Only valid while [AuthStatus.authenticated]. Callers on gated routes
/// should rely on the router sending unauthenticated users to `/login` first.
final currentUserProvider = Provider<AppUser>((ref) {
  final auth = ref.watch(authControllerProvider);

  if (auth.user != null) {
    return auth.user!;
  }

  if (!EnvConfig.isSupabaseConfigured || !SupabaseService.isInitialized) {
    return AppUser.localDevAdmin;
  }

  throw StateError('No authenticated user');
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState.loading()) {
    if (!_ref.read(authRepositoryProvider).isAuthEnabled) {
      state = const AuthState.authenticated(AppUser.localDevAdmin);
      return;
    }

    // No Supabase session → login immediately instead of briefly opening the shell.
    if (supa.Supabase.instance.client.auth.currentSession == null) {
      state = const AuthState.unauthenticated();
    }

    _listenToAuthChanges();
    bootstrap();
  }

  /// Widget/integration tests — skips Supabase and Isar bootstrap.
  AuthController.forTesting(this._ref)
      : super(const AuthState.authenticated(AppUser.localDevAdmin));

  final Ref _ref;
  StreamSubscription<supa.AuthState>? _authSub;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    if (!_repository.isAuthEnabled) {
      state = const AuthState.authenticated(AppUser.localDevAdmin);
      return;
    }

    final cached = await _repository.loadCachedUser();
    if (cached != null) {
      await RealtimeAuthBinder.applySession();
      state = AuthState.authenticated(cached);
    }

    try {
      final remote = await _repository.restoreRemoteSession();
      if (remote != null) {
        await RealtimeAuthBinder.applySession();
        state = AuthState.authenticated(remote);
        return;
      }

      if (cached == null) {
        state = const AuthState.unauthenticated();
      }
    } catch (error) {
      debugPrint('AuthController bootstrap: $error');
      if (cached == null) {
        state = AuthState.unauthenticated(
          errorMessage: error.toString(),
        );
      }
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      await RealtimeAuthBinder.applySession();
      state = AuthState.authenticated(user);
    } on AuthException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }

  void _listenToAuthChanges() {
    if (!_repository.isAuthEnabled) return;

    _authSub = supa.Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) async {
        if (event.event == supa.AuthChangeEvent.signedOut) {
          await _repository.clearCachedUser();
          state = const AuthState.unauthenticated(
            errorMessage: 'Session expired — please sign in again',
          );
          return;
        }

        if (event.event == supa.AuthChangeEvent.tokenRefreshed ||
            event.event == supa.AuthChangeEvent.signedIn) {
          try {
            await RealtimeAuthBinder.applySession();
            final user = await _repository.restoreRemoteSession();
            if (user != null) {
              await _repository.cacheUser(user);
              state = AuthState.authenticated(user);
            }
          } catch (error) {
            debugPrint('AuthController auth change: $error');
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
