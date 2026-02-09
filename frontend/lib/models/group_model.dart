import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

// Custom converter for adminId that handles both String and Object
class AdminIdConverter implements JsonConverter<String, dynamic> {
  const AdminIdConverter();

  @override
  String fromJson(dynamic value) {
    if (value is String) {
      return value;
    } else if (value is Map<String, dynamic>) {
      return value['_id'] as String;
    }
    throw Exception('Invalid adminId format: $value');
  }

  @override
  dynamic toJson(String value) => value;
}

// Custom converter for members list that handles both String and Object
class MembersConverter implements JsonConverter<List<String>, dynamic> {
  const MembersConverter();

  @override
  List<String> fromJson(dynamic value) {
    if (value is List) {
      return value.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map<String, dynamic>) {
          return item['_id'] as String;
        }
        throw Exception('Invalid member format: $item');
      }).toList();
    }
    throw Exception('Invalid members format: $value');
  }

  @override
  dynamic toJson(List<String> value) => value;
}

@freezed
class Group with _$Group {
  const factory Group({
    @JsonKey(name: '_id') required String id,
    required String name,
    @MembersConverter() required List<String> members,
    @AdminIdConverter() required String adminId,
    required DateTime createdAt,
    @Default(null) String? description,
    @Default(null) String? chatId,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
