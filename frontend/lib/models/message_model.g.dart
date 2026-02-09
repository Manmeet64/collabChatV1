// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['_id'] as String,
      senderId: const SenderIdConverter().fromJson(json['senderId']),
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: json['sender'] == null
          ? null
          : User.fromJson(json['sender'] as Map<String, dynamic>),
      fileName: json['fileName'] as String? ?? null,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? null,
      fileType: json['fileType'] as String? ?? null,
      fileUrl: json['fileUrl'] as String? ?? null,
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'senderId': const SenderIdConverter().toJson(instance.senderId),
      'chatId': instance.chatId,
      'content': instance.content,
      'type': instance.type,
      'createdAt': instance.createdAt.toIso8601String(),
      'sender': instance.sender,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'fileType': instance.fileType,
      'fileUrl': instance.fileUrl,
    };
