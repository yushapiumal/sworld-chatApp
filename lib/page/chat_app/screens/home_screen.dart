import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sworld_flutter/page/chat_app/models/chat_model.dart' show Chat;
import 'package:sworld_flutter/page/chat_app/models/user_model.dart';
import 'package:sworld_flutter/page/chat_app/screens/chat_screen.dart';
import 'package:sworld_flutter/page/chat_app/services/chat_service.dart';

class ChatHomeScreen extends StatefulWidget {
  static const String routeName = '/chat_home';

  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final ChatService _chatService = ChatService();

  late final String currentUserId;
  String currentUserName = 'Unknown User';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid ?? '';

    if (currentUserId.isNotEmpty) {
      _checkAndPromptUserName();
    }
  }

  Future<void> _checkAndPromptUserName() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

    if (userDoc.exists && userDoc.data()?['name'] != null) {
      currentUserName = userDoc['name'];
    } else {
      await _promptForUserName();
    }
    setState(() {});
  }

  Future<void> _promptForUserName() async {
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  currentUserName = name;
                  await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
                    'id': currentUserId,
                    'name': currentUserName,
                    'profileImage': null,
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGroupCreationDialog(BuildContext context) async {
    final users = await _chatService.getAllUsers();
    final otherUsers = users.where((user) => user.id != currentUserId).toList();
    final selectedUsers = <UserModel>[];
    final TextEditingController groupNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group Chat'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: groupNameController,
                      decoration: const InputDecoration(
                        hintText: 'Group name (required)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select participants:'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: otherUsers.length,
                        itemBuilder: (context, index) {
                          final user = otherUsers[index];
                          final isSelected = selectedUsers.contains(user);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedUsers.add(user);
                                } else {
                                  selectedUsers.remove(user);
                                }
                              });
                            },
                            title: Text(user.name),
                            secondary: CircleAvatar(
                              backgroundImage: user.profileImage != null
                                  ? NetworkImage(user.profileImage!)
                                  : null,
                              child: user.profileImage == null
                                  ? Text(user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?')
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUsers.length >= 2 && groupNameController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      await _createGroupChat(selectedUsers, groupNameController.text.trim());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a group name and select at least 2 participants'),
                        ),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createGroupChat(List<UserModel> selectedUsers, String groupName) async {
    final currentUser = UserModel(
      id: currentUserId,
      name: currentUserName,
    );

    final allParticipants = [currentUser, ...selectedUsers];
    final chatId = await _chatService.createGroupChat(allParticipants, groupName);
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final chat = Chat.fromDoc(chatId, chatDoc.data()!);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: chat,
            currentUserId: currentUserId,
            currentUser: currentUserId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showGroupCreationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getChatsForUser(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No chats yet. Tap the + button to start a new chat.'),
            );
          }

          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              String displayName;
              Widget avatar;
              Widget? trailingIcon;

              if (chat.isGroupChat) {
                displayName = chat.groupName ?? 'Unnamed Group';
                avatar = CircleAvatar(
                  backgroundColor: Colors.blueGrey[200],
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                );
                trailingIcon = const Icon(Icons.group, color: Colors.blueGrey); // Group icon
              } else {
                final otherUser = chat.users.firstWhere(
                  (user) => user.id != currentUserId,
                  orElse: () => UserModel(id: 'unknown', name: 'Unknown'),
                );
                displayName = otherUser.name;
                avatar = CircleAvatar(
                  backgroundImage: otherUser.profileImage != null
                      ? NetworkImage(otherUser.profileImage!)
                      : null,
                  child: otherUser.profileImage == null
                      ? Text(otherUser.name.isNotEmpty
                          ? otherUser.name[0].toUpperCase()
                          : '?')
                      : null,
                );
                trailingIcon = null; // No icon for one-on-one chats
              }

              return ListTile(
                leading: avatar,
                title: Text(displayName),
                subtitle: Text(
                  chat.lastMessageSenderId == currentUserId
                      ? 'You: ${chat.lastMessage}'
                      : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chat.lastMessageTime != null)
                      Text(
                        '${chat.lastMessageTime!.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon,
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chat: chat,
                        currentUserId: currentUserId,
                        currentUser: currentUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSelectionDialog(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  Future<void> _showUserSelectionDialog(BuildContext context) async {
    final users = await _chatService.getAllUsers();
    final otherUsers = users.where((user) => user.id != currentUserId).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a user to chat with'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: otherUsers.length,
              itemBuilder: (context, index) {
                final user = otherUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
                        ? Text(user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  title: Text(user.name),
                  onTap: () async {
                    Navigator.pop(context);
                    await _startNewChat(context, user);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _startNewChat(BuildContext context, UserModel otherUser) async {
    final currentUser = UserModel(
      id: currentUserId,
      name: currentUserName,
    );

    final chatId = await _chatService.createChat([currentUser, otherUser], isGroup: false);

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final chat = Chat.fromDoc(chatId, chatDoc.data()!);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: chat,
            currentUserId: currentUserId,
            currentUser: currentUserId,
          ),
        ),
      );
    }
  }
}