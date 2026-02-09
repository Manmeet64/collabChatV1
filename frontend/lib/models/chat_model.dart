import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    @Default('private') String type, // 'private' | 'group'
    required List<String> members,
    required DateTime createdAt,
    @Default(null) String? lastMessage,
    @Default(null) DateTime? lastMessageTime,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
}
