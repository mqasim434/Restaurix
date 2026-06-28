import 'dart:convert';

import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.authUserId,
    this.employeeId,
  });

  /// Row id in [app_users] (or local-only id when offline without Supabase).
  final String id;
  final String name;
  final UserRole role;
  final String? authUserId;
  final String? employeeId;

  bool get isLocalOnly => authUserId == null;

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? authUserId,
    String? employeeId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      authUserId: authUserId ?? this.authUserId,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'authUserId': authUserId,
        'employeeId': employeeId,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.salesman,
      ),
      authUserId: json['authUserId'] as String?,
      employeeId: json['employeeId'] as String?,
    );
  }

  static AppUser? decodeCached(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String encodeCached() => jsonEncode(toJson());

  /// Offline-only default when Supabase is not configured (tests / local dev).
  static const localDevAdmin = AppUser(
    id: 'local-dev-admin',
    name: 'Admin',
    role: UserRole.admin,
  );
}
