// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
  id: json['id'] as String,
  name: json['name'] as String,
  inviteCode: json['inviteCode'] as String,
  settings: json['settings'] as Map<String, dynamic>,
  createdAt: DateTime.parse(json['createdAt'] as String),
  users:
      (json['users'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'inviteCode': instance.inviteCode,
  'settings': instance.settings,
  'createdAt': instance.createdAt.toIso8601String(),
  'users': instance.users,
};
