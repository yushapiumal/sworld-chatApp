// // chat_screen.dart
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:sworld_flutter/page/chat_app/models/chat_model.dart';
// import 'package:sworld_flutter/page/chat_app/models/user_model.dart';
// import 'package:sworld_flutter/page/chat_app/screens/call_screen.dart';
// import 'package:sworld_flutter/page/chat_app/screens/sticker_screen.dart';
// import 'package:sworld_flutter/page/chat_app/services/chat_service.dart';

// class ChatScreen extends StatefulWidget {
//   final Chat chat;
//   final String currentUser;
//   final String currentUserId;

//   static String routeName = "ChatScreen";

//   const ChatScreen({
//     super.key,
//     required this.chat,
//     required this.currentUser,
//     required this.currentUserId,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   bool _emojiShowing = false;
//   final ScrollController _scrollController = ScrollController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   late String chatId;
//   late UserModel otherUser;
//   late ChatService _chatService;

//   @override
//   void initState() {
//     super.initState();
//     chatId = widget.chat.id;
//     otherUser = widget.chat.users.firstWhere(
//       (user) => user.id != widget.currentUserId,
//       orElse: () => UserModel(id: 'unknown', name: 'Unknown'),
//     );
//     _chatService = ChatService();
//     _focusNode.addListener(() {
//       if (_focusNode.hasFocus && _emojiShowing) {
//         setState(() => _emojiShowing = false);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     await _chatService.sendMessage(
//       chatId: chatId,
//       senderId: widget.currentUserId,
//       text: text,
//     );

//     _controller.clear();
//     _scrollToBottom();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void _openStickerScreen() async {
//     final selectedStickerPath = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const StickerScreen()),
//     );

//     if (selectedStickerPath != null) {
//       await _chatService.sendMessage(
//         chatId: chatId,
//         senderId: widget.currentUserId,
//         text: 'Sticker',
//         stickerPath: selectedStickerPath,
//       );
//       _scrollToBottom();
//     }
//   }

//  Future<void> _uploadFileAndSendMessage(File file, String fileName, String fileType) async {
//   try {
//     // Create a reference with a unique filename
//     final ref = _storage.ref()
//       .child('chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    
//     // Show upload progress
//     final uploadTask = ref.putFile(file);
    
//     // Listen for state changes and errors
//     uploadTask.snapshotEvents.listen((taskSnapshot) {
//       print('Upload progress: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100}%');
//     }, onError: (e) {
//       print('Upload error: $e');
//     });

//     // Wait for upload to complete
//     final snapshot = await uploadTask;
//     final downloadUrl = await snapshot.ref.getDownloadURL();

//     await _chatService.sendMessage(
//       chatId: chatId,
//       senderId: widget.currentUserId,
//       text: fileName,
//       fileUrl: downloadUrl,
//       fileType: fileType,
//       fileName: fileName,
//     );

//     _scrollToBottom();
//   } catch (e) {
//     print('Error uploading file: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to upload file: ${e.toString()}')),
//     );
//   }
// }

//  void _showAttachmentPopup() {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return Align(
//           alignment: Alignment.bottomCenter,
//           child: Padding(
//             padding: const EdgeInsets.only(bottom: 90.0),
//             child: Material(
//               borderRadius: BorderRadius.circular(20),
//               color: Colors.white,
//               elevation: 8,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Wrap(
//                   spacing: 24,
//                   children: [
//                     _buildAttachmentItem(Icons.insert_drive_file, 'Document', _sendDocument),
//                     _buildAttachmentItem(Icons.photo, 'Photo', _sendPhoto),
//                     _buildAttachmentItem(Icons.contacts, 'Contact', _sendContact),
//                     _buildAttachmentItem(Icons.location_on, 'Location', _sendLocation),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAttachmentItem(IconData icon, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               color: Color(0xFFE8F0FE),
//               shape: BoxShape.circle,
//             ),
//             padding: const EdgeInsets.all(12),
//             child: Icon(icon, size: 28, color: Colors.blueAccent),
//           ),
//           const SizedBox(height: 8),
//           Text(label, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendDocument() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
//     );

//     if (result != null && result.files.single.path != null) {
//       await _uploadFileAndSendMessage(
//         File(result.files.single.path!),
//         result.files.single.name,
//         'document',
//       );
//     }
//   }

//   Future<void> _sendPhoto() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//     );

//     if (result != null && result.files.single.path != null) {
//       await _uploadFileAndSendMessage(
//         File(result.files.single.path!),
//         result.files.single.name,
//         'image',
//       );
//     }
//   }

//   void _sendContact() {
//     // TODO: Implement contact sharing
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Contact sharing not implemented yet')),
//     );
//   }

//   void _sendLocation() {
//     // TODO: Implement location sharing
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Location sharing not implemented yet')),
//     );
//   }

//   void _onEmojiSelected(Emoji emoji) {
//     final text = _controller.text;
//     final cursorPos = _controller.selection.baseOffset;

//     String newText;
//     int newCursorPos;

//     if (cursorPos >= 0) {
//       newText = text.replaceRange(cursorPos, cursorPos, emoji.emoji);
//       newCursorPos = cursorPos + emoji.emoji.length;
//     } else {
//       newText = text + emoji.emoji;
//       newCursorPos = newText.length;
//     }

//     _controller.text = newText;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _controller.selection = TextSelection.fromPosition(
//         TextPosition(offset: newCursorPos),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: otherUser.profileImage != null
//                   ? NetworkImage(otherUser.profileImage!)
//                   : null,
//               child: otherUser.profileImage == null
//                   ? Text(otherUser.name.isNotEmpty
//                       ? otherUser.name[0].toUpperCase()
//                       : '?')
//                   : null,
//             ),
//             const SizedBox(width: 10),
//             Text(otherUser.name),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.videocam),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CallScreen(callID: chatId)),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => CallScreen(callID: chatId)),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(chatId)
//                   .collection('messages')
//                   .orderBy('time', descending: false)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final docs = snapshot.data!.docs;
//                 if (docs.isEmpty) {
//                   return const Center(child: Text('No messages yet'));
//                 }

//                 return ListView.builder(
//                   controller: _scrollController,
//                   itemCount: docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     final isMe = data['senderId'] == widget.currentUserId;

//                     return _buildMessage(
//                       context,
//                       data,
//                       isMe,
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.attach_file),
//                   onPressed: _showAttachmentPopup,
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.emoji_emotions),
//                   onPressed: () {
//                     setState(() {
//                       _emojiShowing = !_emojiShowing;
//                       if (_emojiShowing) {
//                         _focusNode.unfocus();
//                       } else {
//                         _focusNode.requestFocus();
//                       }
//                     });
//                   },
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     focusNode: _focusNode,
//                     decoration: const InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(20)),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                     ),
//                     onSubmitted: (text) => _sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//           if (_emojiShowing)
//             SizedBox(
//               height: 250,
//               child: EmojiPicker(
//                 onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
//                 onBackspacePressed: () {
//                   final text = _controller.text;
//                   final cursorPos = _controller.selection.baseOffset;

//                   if (cursorPos > 0) {
//                     final newText = text.substring(0, cursorPos - 1) +
//                         text.substring(cursorPos);
//                     _controller.text = newText;
//                     _controller.selection = TextSelection.fromPosition(
//                       TextPosition(offset: cursorPos - 1),
//                     );
//                   }
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(BuildContext context, Map<String, dynamic> data, bool isMe) {
//     final messageType = data['messageType'] ?? 'text';
//     final text = data['text'] ?? '';
//     final timestamp = (data['time'] as Timestamp?)?.toDate() ?? DateTime.now();
//     final fileUrl = data['fileUrl'];
//     final fileType = data['fileType'];
//     final fileName = data['fileName'];
//     final stickerPath = data['stickerPath'];

//     final timeStr = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

//     if (messageType == 'sticker' && stickerPath != null) {
//       print('Uploading to: uploads/${fileName}');
//       return Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               Image.asset(
//                 stickerPath,
//                 width: 150,
//                 height: 150,
//                 fit: BoxFit.contain,
//               ),
//               Text(
//                 timeStr,
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (messageType == 'file' && fileUrl != null) {
//       if (fileType == 'image') {
//         return Align(
//           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   constraints: const BoxConstraints(maxWidth: 250),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.network(
//                       fileUrl,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   timeStr,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         );
//       } else {
//         return Align(
//           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isMe ? Colors.blue : Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.black),
//                       const SizedBox(width: 8),
//                       Flexible(
//                         child: Text(
//                           fileName ?? 'File',
//                           style: TextStyle(color: isMe ? Colors.white : Colors.black),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   timeStr,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//     }

//     // Text message
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 10,
//               ),
//               decoration: BoxDecoration(
//                 color: isMe ? Colors.blue : Colors.grey[300],
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   color: isMe ? Colors.white : Colors.black,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Text(
//               timeStr,
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }