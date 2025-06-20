import 'package:flutter/widgets.dart';
import 'package:sworld_flutter/page/autofill.dart';
import 'package:sworld_flutter/page/chat_app/models/chat_model.dart';
import 'package:sworld_flutter/page/chat_app/screens/call_screen.dart';
import 'package:sworld_flutter/page/chat_app/screens/chat_screen.dart';
import 'package:sworld_flutter/page/chat_app/screens/home_screen.dart';
import 'package:sworld_flutter/page/chat_app/screens/sticker_screen.dart';
import 'package:sworld_flutter/page/flashScreen.dart';
import 'package:sworld_flutter/page/home.dart';
import 'package:sworld_flutter/page/login.dart';
import 'package:sworld_flutter/page/zoom_app.dart/zoom.dart';

import 'page/googleAthenticator.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),
  SworldHomePage.routeName: (context) => const SworldHomePage(title: ''),
  LoginPage.routeName: (context) => const LoginPage(),
  Authenticator.routeName: (context) => const Authenticator(),
  OTPVerificationScreen.routeName: (context) => const OTPVerificationScreen(),
  CallScreen.routeName: (context) => const CallScreen(callID: ''),
  ZoomScreen.routeName: (context) => const ZoomScreen(),

  ChatScreen.routeName: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as ChatScreenArguments;
    return ChatScreen(
      chat: args.chat,
      currentUser: args.currentUserId,
      currentUserId: args.currentUserId,
    );
  },
  ChatHomeScreen.routeName: (context) => const ChatHomeScreen(),
  StickerScreen.routeName: (context) => const StickerScreen(),
};

class ChatScreenArguments {
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final List<String> users;
  final Chat chat; // Ensure this matches the Chat type from chat_message_model.dart

  ChatScreenArguments({
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    required this.users,
    required this.chat,
  });
}

