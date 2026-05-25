import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

class ColorConverter implements JsonConverter<Color?, int?> {
  const ColorConverter();

  @override
  Color? fromJson(int? json) => json != null ? Color(json) : null;

  @override
  int? toJson(Color? object) => object?.toARGB32();
}

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    @Default('') String username,
    @Default('') String email,
    @Default('') String password,
    @ColorConverter() Color? favoriteColor,
    @Default([]) List<String> invitados,
    @Default(true) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
