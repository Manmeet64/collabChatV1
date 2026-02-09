import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final myGroups = ref.watch(myGroupsProvider);
    final usersList = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('CollabChat'),
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Profile'),
                  onTap: () => context.go('/profile'),
                ),
                PopupMenuItem(
                  child: const Text('Logout'),
                  onTap: () async {
                    await ref
                        .read(currentUserProvider.notifier)
                        .logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Direct Messages',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Groups',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildDirectMessagesTab(usersList)
                : _buildGroupsList(myGroups),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          if (_selectedTab == 0) {
            context.go('/chat', extra: '/home');
          } else {
            context.go('/create-group');
          }
        },
        child: Icon(_selectedTab == 0 ? Icons.chat_bubble_outline : Icons.group_add),
      ),
    );
  }

  Widget _buildDirectMessagesTab(AsyncValue<List<dynamic>> usersList) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Direct messages list
        Expanded(
          child: _buildDirectMessagesList(usersList, _searchQuery),
        ),
      ],
    );
  }

  Widget _buildDirectMessagesList(AsyncValue<List<dynamic>> usersList, String searchQuery) {
    return usersList.when(
      data: (users) {
        // Filter users based on search query
        final filteredUsers = searchQuery.isEmpty
            ? users
            : users
                .where((user) =>
                    user.username.toLowerCase().contains(searchQuery))
                .toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppTheme.borderColor,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No conversations yet'
                      : 'No users found matching "$searchQuery"',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return ListTile(
              onTap: () => context.go('/chat/${user.id}'),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                user.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: user.isOnline
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
      ),
      error: (error, st) => Center(
        child: Text('Error loading users: $error'),
      ),
    );
  }

  Widget _buildGroupsList(AsyncValue<List<dynamic>> groupsList) {
    return groupsList.when(
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 64,
                  color: AppTheme.borderColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No groups yet',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              onTap: () => context.go('/group-chat/${group.id}'),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.accentColor,
                child: Icon(
                  Icons.groups,
                  color: Colors.white,
                ),
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${group.members.length} members',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
      ),
      error: (error, st) => Center(
        child: Text('Error loading groups: $error'),
      ),
    );
  }
}
