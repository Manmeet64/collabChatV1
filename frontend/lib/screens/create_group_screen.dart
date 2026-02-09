import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/user_tile.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  late TextEditingController _groupNameController;
  final Set<String> _selectedMembers = {};
  bool _isLoading = false;
  bool _hasGroupName = false;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _groupNameController.addListener(() {
      setState(() {
        _hasGroupName = _groupNameController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersList = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Create Group'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Name Input
                  Text(
                    'Group Name',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter group name',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: Validators.validateGroupName,
                    onChanged: (value) {
                      setState(() {
                        _hasGroupName = value.trim().isNotEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Select Members
                  Text(
                    'Select Members',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${_selectedMembers.length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Users List
                  usersList.when(
                    data: (users) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index] as User;
                          final isSelected = _selectedMembers.contains(user.id);

                          return UserTile(
                            user: user,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMembers.remove(user.id);
                                } else {
                                  _selectedMembers.add(user.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    error: (error, st) =>
                        Center(child: Text('Error loading users: $error')),
                  ),
                ],
              ),
            ),
          ),

          // Create Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading || !_hasGroupName || _selectedMembers.isEmpty
                    ? null
                    : () async {
                        print('🎯 Create group button pressed');
                        final groupName = _groupNameController.text.trim();
                        print('   Group name: $groupName');
                        print(
                          '   Selected members: ${_selectedMembers.length}',
                        );

                        final error = Validators.validateGroupName(groupName);

                        if (error != null) {
                          print('❌ Validation error: $error');
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          print('📤 Calling createGroup API...');
                          await ref
                              .read(myGroupsProvider.notifier)
                              .createGroup(
                                groupName,
                                _selectedMembers.toList(),
                              );

                          print('✅ Group created successfully');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group created successfully'),
                                backgroundColor: AppTheme.accentColor,
                              ),
                            );
                            context.go('/home');
                          }
                        } catch (e) {
                          print('❌ Error creating group: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Create Group'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
