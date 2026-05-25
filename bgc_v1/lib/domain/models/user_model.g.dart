// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  username: json['username'] as String? ?? '',
  email: json['email'] as String? ?? '',
  password: json['password'] as String? ?? '',
  favoriteColor: const ColorConverter().fromJson(
    (json['favoriteColor'] as num?)?.toInt(),
  ),
  invitados:
      (json['invitados'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'password': instance.password,
  'favoriteColor': const ColorConverter().toJson(instance.favoriteColor),
  'invitados': instance.invitados,
  'isActive': instance.isActive,
};
