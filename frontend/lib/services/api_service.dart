import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import 'storage_service.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storageService;

  ApiService(this._storageService) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.apiTimeout,
        receiveTimeout: ApiConstants.apiTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  // Auth Endpoints
  Future<AuthResponse> register(String username, String password) async {
    try {
      print('📤 Sending register request for: $username');
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: {'username': username, 'password': password},
      );
      print('📥 Register response: ${response.data}');
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Register API error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login(String username, String password) async {
    try {
      print('📤 Sending login request for: $username');
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {'username': username, 'password': password},
      );
      print('📥 Login response: ${response.data}');
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print('❌ Login API error: $e');
      rethrow;
    }
  }

  // User Endpoints
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.userMe);
      return User.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getUserList() async {
    try {
      print('📤 Fetching user list...');
      final response = await _dio.get(ApiConstants.userList);
      print('✅ Users response received: ${response.data.length} users');
      final users = (response.data as List).map((user) {
        print('   User: ${user['username']} (${user['_id']})');
        return User.fromJson(user);
      }).toList();
      print('✅ Parsed ${users.length} users');
      return users;
    } catch (e) {
      print('❌ Error fetching users: $e');
      rethrow;
    }
  }

  // Chat Endpoints
  Future<List<Message>> getPrivateChatMessages(
    String currentUserId,
    String otherUserId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final endpoint =
          '${ApiConstants.chatsPrivate}/$currentUserId/$otherUserId';
      print('🔗 GET $endpoint?limit=$limit&offset=$offset');
      print('   📍 Fetching between: $currentUserId ↔️ $otherUserId');
      final response = await _dio.get(
        endpoint,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      print('   ✅ Status: ${response.statusCode}');
      print('   📦 Response type: ${response.data.runtimeType}');

      // Handle both list and object responses
      if (response.data is List) {
        final list = response.data as List;
        print('   📦 Messages returned: ${list.length}');
        return list
            .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('messages') && map['messages'] is List) {
          final messages = map['messages'] as List;
          print('   📦 Messages found in "messages" key: ${messages.length}');
          return messages
              .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
              .toList();
        } else if (map.containsKey('data') && map['data'] is List) {
          final messages = map['data'] as List;
          print('   📦 Messages found in "data" key: ${messages.length}');
          return messages
              .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
              .toList();
        }
      }

      print('   ⚠️ Unexpected response format');
      return [];
    } catch (e) {
      print('   ❌ Error: $e');
      if (e is DioException) {
        print('   📋 Response body: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<List<Message>> getGroupChatMessages(
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.chatsGroup}/$groupId',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return (response.data as List)
          .map((msg) => Message.fromJson(msg))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Send Message via API (fallback if socket is not available)
  Future<Message> sendMessage(
    String chatId,
    String message, {
    String type = 'text',
    bool isGroupChat = false,
    String? recipientId,
  }) async {
    try {
      final data = {'content': message, 'type': type};

      // For private chats, use recipientId
      if (!isGroupChat && recipientId != null) {
        data['recipientId'] = recipientId;
      } else if (isGroupChat) {
        data['chatId'] = chatId;
      } else {
        // Fallback: assume chatId is the recipientId
        data['recipientId'] = chatId;
      }

      final response = await _dio.post(ApiConstants.chatsSend, data: data);
      return Message.fromJson(response.data);
    } catch (e) {
      print('❌ Error sending message via API: $e');
      rethrow;
    }
  }

  // Upload File Endpoint (Metadata only - old method)
  Future<Message> uploadFile(String chatId, FormData formData) async {
    try {
      print('📤 Uploading file metadata to API...');
      final endpoint = '${ApiConstants.chatsPrivate}/$chatId/messages';
      print('🔗 Full endpoint: $endpoint');
      print(
        '📋 FormData fields: ${formData.fields.map((e) => e.key).toList()}',
      );
      print('📋 FormData files: ${formData.files.map((e) => e.key).toList()}');

      final response = await _dio.post(endpoint, data: formData);
      print('✅ File uploaded: ${response.statusCode}');
      print('📦 Response data: ${response.data}');
      return Message.fromJson(response.data);
    } catch (e) {
      print('❌ Error uploading file: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        print('   Request Path: ${e.requestOptions.path}');
      }
      rethrow;
    }
  }

  // Upload File to Cloudinary (New method with actual file upload)
  Future<Message> uploadFileToCloudinary(
    String chatId,
    FormData formData,
  ) async {
    try {
      print('☁️ Uploading file to Cloudinary via API...');
      final endpoint = '/chats/upload/$chatId';
      print('🔗 Full endpoint: $endpoint');
      print(
        '📋 FormData fields: ${formData.fields.map((e) => e.key).toList()}',
      );
      print('📋 FormData files: ${formData.files.map((e) => e.key).toList()}');

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      print('✅ File uploaded to Cloudinary: ${response.statusCode}');
      print('📦 Response data: ${response.data}');
      return Message.fromJson(response.data);
    } catch (e) {
      print('❌ Error uploading file to Cloudinary: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        print('   Request Path: ${e.requestOptions.path}');
      }
      rethrow;
    }
  }

  // Group Endpoints
  Future<Group> createGroup(String name, List<String> members) async {
    try {
      print('📤 Creating group: $name with ${members.length} members');
      print('   Members: ${members.join(", ")}');
      final response = await _dio.post(
        ApiConstants.groupsCreate,
        data: {'name': name, 'members': members},
      );
      print('✅ Group created successfully');
      print('   Response: ${response.data}');
      return Group.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating group: $e');
      if (e is DioException) {
        print('   Status: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<List<Group>> getMyGroups() async {
    try {
      final response = await _dio.get(ApiConstants.groupsMy);
      return (response.data as List)
          .map((group) => Group.fromJson(group))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addGroupMember(String groupId, String userId) async {
    try {
      await _dio.post(
        '${ApiConstants.groupsAdd}/$groupId/add',
        data: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
