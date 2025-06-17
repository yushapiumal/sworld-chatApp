import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sworld_flutter/page/chat_app/models/chat_model.dart';
import 'package:sworld_flutter/page/chat_app/models/user_model.dart';
import 'package:sworld_flutter/page/chat_app/screens/call_screen.dart';
import 'package:sworld_flutter/page/chat_app/screens/sticker_screen.dart';
import 'package:sworld_flutter/page/chat_app/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String currentUser;
  final String currentUserId;

  static String routeName = "ChatScreen";

  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUser,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;
  bool _isUploading = false;
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String chatId;
  late ChatService _chatService;
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  Map<String, String> userNames = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    chatId = widget.chat.id;
    _chatService = ChatService();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    // Fetch names for all users in the chat
    for (var user in widget.chat.users) {
      if (!userNames.containsKey(user.id)) {
        final userDoc = await _firestore.collection('users').doc(user.id).get();
        if (userDoc.exists) {
          userNames[user.id] = userDoc['name'] ?? 'Unknown';
        } else {
          userNames[user.id] = 'Unknown';
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _emojiShowing) {
      setState(() => _emojiShowing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    String newText;
    int newCursorPos;

    if (cursorPos >= 0) {
      newText = text.replaceRange(cursorPos, cursorPos, emoji.emoji);
      newCursorPos = cursorPos + emoji.emoji.length;
    } else {
      newText = text + emoji.emoji;
      newCursorPos = newText.length;
    }

    _controller.text = newText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: widget.currentUserId,
        text: text,
      );
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _openStickerScreen() async {
    final selectedStickerPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StickerScreen()),
    );

    if (selectedStickerPath != null && mounted) {
      setState(() => _isUploading = true);
      try {
        await _chatService.sendMessage(
          chatId: chatId,
          senderId: widget.currentUserId,
          text: 'Sticker',
          stickerPath: selectedStickerPath,
        );
        _scrollToBottom();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send sticker: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

void _groupMembers() {
  if (widget.chat.isGroupChat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.75, // 75% width of screen
            child: Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    title: Text('Group Members'),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Group Name: ${widget.chat.groupName}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Admin ID: ${widget.chat.adminId}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                  const Divider(),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'List of group members goes here...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This is not a group chat')),
    );
  }
}


  Future<void> _uploadFileAndSendMessage(
      File file, String fileName, String fileType) async {
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final ref = _storage.ref().child(
          'chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getMimeType(fileName),
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _chatService.sendMessage(
        chatId: chatId,
        senderId: widget.currentUserId,
        text: fileName,
        fileUrl: downloadUrl,
        fileType: fileType,
        fileName: fileName,
      );

      _scrollToBottom();
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String? _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  void _showAttachmentPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 90.0),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 24,
                  children: [
                    _buildAttachmentItem(
                        Icons.insert_drive_file, 'Document', _sendDocument),
                    _buildAttachmentItem(Icons.photo, 'Photo', _sendPhoto),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _sendDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx'
        ],
        withData: true,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (file.lengthSync() > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 10MB limit')),
          );
          return;
        }
        await _uploadFileAndSendMessage(
          file,
          result.files.single.name,
          'document',
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File picker error: ${e.message}')),
      );
    }
  }

  Future<void> _sendPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (file.lengthSync() > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size exceeds 5MB limit')),
          );
          return;
        }
        await _uploadFileAndSendMessage(
          file,
          result.files.single.name,
          'image',
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image picker error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  widget.chat.isGroupChat ? Colors.blueGrey[200] : null,
              backgroundImage: !widget.chat.isGroupChat &&
                      widget.chat.users.any((user) => user.profileImage != null)
                  ? NetworkImage(widget.chat.users
                      .firstWhere((user) => user.id != widget.currentUserId)
                      .profileImage!)
                  : null,
              child: widget.chat.isGroupChat ||
                      !widget.chat.users
                          .any((user) => user.profileImage != null)
                  ? Text(
                      widget.chat.isGroupChat
                          ? (widget.chat.groupName?.isNotEmpty ?? false
                              ? widget.chat.groupName![0].toUpperCase()
                              : '?')
                          : widget.chat.users
                                  .firstWhere(
                                      (user) => user.id != widget.currentUserId)
                                  .name
                                  .isNotEmpty
                              ? widget.chat.users
                                  .firstWhere(
                                      (user) => user.id != widget.currentUserId)
                                  .name[0]
                                  .toUpperCase()
                              : '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.isGroupChat
                        ? (widget.chat.groupName ?? 'Unnamed Group')
                        : widget.chat.users
                            .firstWhere(
                                (user) => user.id != widget.currentUserId)
                            .name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.chat.isGroupChat)
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(widget.chat.users
                              .firstWhere(
                                  (user) => user.id != widget.currentUserId)
                              .id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'offline';
                          return Text(
                            status,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: status == 'online'
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CallScreen(callID: chatId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CallScreen(callID: chatId)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _groupMembers
,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('time', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Start a conversation!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;

                    return _buildMessageBubble(
                      context,
                      data,
                      isMe,
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentPopup,
                ),
                IconButton(
                  icon: const Icon(Icons.add_reaction),
                  onPressed: _openStickerScreen,
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () {
                    setState(() {
                      _emojiShowing = !_emojiShowing;
                      if (_emojiShowing) {
                        _focusNode.unfocus();
                      } else {
                        _focusNode.requestFocus();
                      }
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          if (_emojiShowing)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                onBackspacePressed: () {
                  final text = _controller.text;
                  final cursorPos = _controller.selection.baseOffset;

                  if (cursorPos > 0) {
                    final newText = text.substring(0, cursorPos - 1) +
                        text.substring(cursorPos);
                    _controller.text = newText;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: cursorPos - 1),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, Map<String, dynamic> data, bool isMe) {
    final messageType = data['messageType'] ?? 'text';
    final text = data['text'] ?? '';
    final timestamp = (data['time'] as Timestamp?)?.toDate() ?? DateTime.now();
    final fileUrl = data['fileUrl'];
    final fileType = data['fileType'];
    final fileName = data['fileName'];
    final stickerPath = data['stickerPath'];
    final timeStr = _timeFormat.format(timestamp);
    final senderId = data['senderId'] ?? '';
    final senderName = userNames[senderId] ?? 'Unknown';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.chat.isGroupChat && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            if (messageType == 'sticker' && stickerPath != null)
              Image.asset(
                stickerPath,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            if (messageType == 'file' && fileUrl != null)
              if (fileType == 'image')
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 250,
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 250,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening $fileName')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(fileName),
                          color: isMe ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            fileName ?? 'File',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (messageType == 'text')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(0),
                    bottomRight: isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(16),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    final extension = fileName?.split('.').last.toLowerCase() ?? '';
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.note;
      default:
        return Icons.insert_drive_file;
    }
  }
}
