import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'family.g.dart';

@JsonSerializable()
class Family {
  final String id;
  final String name;
  final String inviteCode;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final List<User>? users;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.settings,
    required this.createdAt,
    this.users,
  });

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  Family copyWith({
    String? id,
    String? name,
    String? inviteCode,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    List<User>? users,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      users: users ?? this.users,
    );
  }

  // Helper methods
  List<User> get parentUsers {
    return users?.where((user) => user.role == UserRole.parent).toList() ?? [];
  }

  List<User> get childUsers {
    return users?.where((user) => user.role == UserRole.child).toList() ?? [];
  }

  int? get dailyWatchLimitMinutes {
    return settings['daily_watch_limit_minutes'] as int?;
  }

  bool get enableContentFiltering {
    return settings['enable_content_filtering'] as bool? ?? true;
  }

  bool get enableTimeRestriction {
    return settings['enable_time_restriction'] as bool? ?? false;
  }
}