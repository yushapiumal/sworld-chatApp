// import 'package:sworld_flutter/page/chat_app/models/chat_message_model.dart';
// import 'package:sworld_flutter/page/chat_app/models/user_model.dart';

// class Chat {
//   final String id;
//   final List<UserModel> users;
//   final List<ChatMessage> messages;

//   Chat({
//     this.id = '',
//     required this.users,
//     required this.messages,
//   });
// }


// chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class Chat {
  final String id;
  final List<UserModel> users;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
   final bool isGroupChat;
  final String? groupName;
  final String? adminId;

  Chat({
    required this.id,
    required this.users,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.isGroupChat = false,
    this.groupName,
    this.adminId,
  });

factory Chat.fromDoc(String id, Map<String, dynamic> data) {
  var usersData = data['users'] as List<dynamic>? ?? [];
  List<UserModel> users = usersData.map((u) {
    if (u is Map<String, dynamic>) {
      return UserModel.fromMap(u);
    } else if (u is String) {
      return UserModel(id: u, name: 'Unknown');
    }
    return UserModel(id: '', name: 'Unknown');
  }).toList();

  return Chat(
    id: id,
    users: users,
    lastMessage: data['lastMessage'] ?? '',
    lastMessageTime: data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : null,
    lastMessageSenderId: data['lastMessageSenderId'],
    isGroupChat: data['isGroupChat'] ?? false, // Add isGroupChat
    groupName: data['groupName'], // Add groupName
    adminId: data['adminId'], // Add adminId
  );
}

  Map<String, dynamic> toMap() {
    return {
      'users': users.map((user) => user.toMap()).toList(),
      'lastMessage': lastMessage,
      'timestamp': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }
}