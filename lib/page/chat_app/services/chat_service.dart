import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sworld_flutter/page/chat_app/models/chat_model.dart';
import 'package:sworld_flutter/page/chat_app/models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createChat(List<UserModel> users, {required bool isGroup}) async {
    if (users.length < 2) {
      throw Exception('At least 2 users are required to create a chat');
    }

    final userIds = users.map((u) => u.id).toList()..sort();
    final existingChats = await _firestore
        .collection('chats')
        .where('userIds', isEqualTo: userIds)
        .where('isGroupChat', isEqualTo: false)
        .limit(1)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return _handleExistingChat(users, existingChats.docs.first);
    }

    return _createNewChat(users, userIds, isGroupChat: false);
  }

  Future<String> createGroupChat(List<UserModel> users, String groupName) async {
    if (users.length < 2) {
      throw Exception('At least 2 users are required to create a group chat');
    }

    final userIds = users.map((u) => u.id).toList()..sort();
    return _createNewChat(users, userIds, isGroupChat: true, groupName: groupName);
  }

  Future<String> _handleExistingChat(List<UserModel> users, QueryDocumentSnapshot existingChat) async {
    final existingChatId = existingChat.id;

    // Ensure all users have the chat in their 'user_chats'
    for (var user in users) {
      final userChatRef = _firestore
          .collection('user_chats')
          .doc(user.id)
          .collection('chats')
          .doc(existingChatId);

      final exists = await userChatRef.get();
      if (!exists.exists) {
        await userChatRef.set({
          'lastMessage': existingChat['lastMessage'] ?? '',
          'timestamp': existingChat['timestamp'] ?? FieldValue.serverTimestamp(),
          'lastMessageSenderId': existingChat['lastMessageSenderId'],
        });
      }
    }

    return existingChatId;
  }

Future<String> _createNewChat(
  List<UserModel> users,
  List<String> userIds, {
  bool isGroupChat = false,
  String? groupName,
}) async {
  // Create a new chat document
  final chatData = {
    'users': users.map((u) => u.toMap()).toList(),
    'userIds': userIds,
    'lastMessage': '',
    'timestamp': FieldValue.serverTimestamp(),
    'lastMessageSenderId': null,
    'isGroupChat': isGroupChat,
    if (isGroupChat && groupName != null) 'groupName': groupName,
    if (isGroupChat) 'adminId': users.first.id, // First user is admin
  };

  final chatDoc = await _firestore.collection('chats').add(chatData);

  // Add the chat to each user's chat list
  for (var user in users) {
    await _firestore
        .collection('user_chats')
        .doc(user.id)
        .collection('chats')
        .doc(chatDoc.id)
        .set({
      'lastMessage': '',
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': null,
      'isGroupChat': isGroupChat,
      if (isGroupChat && groupName != null) 'groupName': groupName,
      if (isGroupChat) 'adminId': users.first.id,
    });
  }

  return chatDoc.id;
}

  /// Get chats for a specific user.
  Stream<List<Chat>> getChatsForUser(String userId) {
    return _firestore
        .collection('user_chats')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Chat> chats = [];
      for (var doc in snapshot.docs) {
        final chatId = doc.id;
        final chatData = await _firestore.collection('chats').doc(chatId).get();
        if (chatData.exists) {
          chats.add(Chat.fromDoc(chatId, chatData.data()!));
        }
      }
      return chats;
    });
  }

  /// Send a message in a chat.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? fileUrl,
    String? fileType,
    String? fileName,
    String? stickerPath,
  }) async {
    final messageType = stickerPath != null
        ? 'sticker'
        : fileUrl != null
            ? 'file'
            : 'text';

    // Add message to messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'time': FieldValue.serverTimestamp(),
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'stickerPath': stickerPath,
      'messageType': messageType,
    });

    // Update main chat document with last message info
    final updateData = {
      'lastMessage': text,
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    };

    await _firestore.collection('chats').doc(chatId).update(updateData);

    // Reflect last message in all users' chat list
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final users = (chatDoc.data()!['users'] as List<dynamic>)
          .map((u) => UserModel.fromMap(u))
          .toList();

      for (var user in users) {
        await _firestore
            .collection('user_chats')
            .doc(user.id)
            .collection('chats')
            .doc(chatId)
            .update(updateData);
      }
    }
  }

  /// Add a user to an existing group chat
  Future<void> addUserToGroupChat({
    required String chatId,
    required UserModel newUser,
    required String currentUserId,
  }) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      throw Exception('Chat does not exist');
    }

    final chatData = chatDoc.data()!;
    if (!chatData['isGroupChat']) {
      throw Exception('Cannot add users to a non-group chat');
    }

    if (chatData['adminId'] != currentUserId) {
      throw Exception('Only group admin can add users');
    }

    final existingUsers = (chatData['users'] as List<dynamic>)
        .map((u) => UserModel.fromMap(u))
        .toList();

    if (existingUsers.any((u) => u.id == newUser.id)) {
      throw Exception('User already in group');
    }

    // Update chat document
    final updatedUsers = [...existingUsers, newUser];
    final updatedUserIds = updatedUsers.map((u) => u.id).toList()..sort();

    await _firestore.collection('chats').doc(chatId).update({
      'users': updatedUsers.map((u) => u.toMap()).toList(),
      'userIds': updatedUserIds,
    });

    // Add chat to new user's chat list
    await _firestore
        .collection('user_chats')
        .doc(newUser.id)
        .collection('chats')
        .doc(chatId)
        .set({
      'lastMessage': chatData['lastMessage'] ?? '',
      'timestamp': chatData['timestamp'] ?? FieldValue.serverTimestamp(),
      'lastMessageSenderId': chatData['lastMessageSenderId'],
      'isGroupChat': true,
      'groupName': chatData['groupName'],
    });
  }

  /// Fetch all registered users.
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  /// Save user in 'users' collection if not already exists.
  Future<void> saveUserIfNotExists(UserModel user) async {
    final userDoc = await _firestore.collection('users').doc(user.id).get();
    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    }
  }
}