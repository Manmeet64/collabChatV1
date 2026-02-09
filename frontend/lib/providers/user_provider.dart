import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Users List Provider
final usersListProvider = FutureProvider<List<User>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getUserList();
});

// My Groups Provider
final myGroupsProvider =
    StateNotifierProvider<MyGroupsNotifier, AsyncValue<List<Group>>>((ref) {
  return MyGroupsNotifier(ref);
});

class MyGroupsNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  final StateNotifierProviderRef ref;

  MyGroupsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);
      return api.getMyGroups();
    });
  }

  Future<void> createGroup(String name, List<String> memberIds) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.createGroup(name, memberIds);
      await _loadGroups();
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadGroups();
  }
}

// Create Group Provider
final createGroupProvider =
    FutureProvider.family<void, (String name, List<String> members)>((ref, params) {
  return ref.read(myGroupsProvider.notifier).createGroup(params.$1, params.$2);
});

// Add Group Member Provider
final addGroupMemberProvider = FutureProvider.family<void, (String groupId, String userId)>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  await api.addGroupMember(params.$1, params.$2);
  await ref.refresh(myGroupsProvider);
});
