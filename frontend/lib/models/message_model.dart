import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

// Custom converter for senderId that handles both String and Object
class SenderIdConverter implements JsonConverter<String, dynamic> {
  const SenderIdConverter();

  @override
  String fromJson(dynamic value) {
    if (value is String) {
      return value;
    } else if (value is Map<String, dynamic>) {
      return value['_id'] as String;
    }
    throw Exception('Invalid senderId format: $value');
  }

  @override
  dynamic toJson(String value) => value;
}

@freezed
class Message with _$Message {
  const factory Message({
    @JsonKey(name: '_id') required String id,
    @SenderIdConverter() required String senderId,
    required String chatId,
    required String content,
    @Default('text') String type, // 'text' | 'file'
    required DateTime createdAt,
    @Default(null) User? sender,
    // File-specific fields
    @Default(null) String? fileName,
    @Default(null) int? fileSize,
    @Default(null) String? fileType,
    @Default(null) String? fileUrl, // Cloudinary URL
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
