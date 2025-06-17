import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:sworld_flutter/page/flashScreen.dart';
import 'package:sworld_flutter/route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';



// ✅ Declare it here
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background message: ${message.messageId}");
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
 const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default channel for notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(const SWORLD());
}

void _signInAnonymously() async {
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("✅ Signed in anonymously as: ${userCredential.user?.uid}");
  } catch (e) {
    print("❌ Anonymous sign-in failed: $e");
  }
}




class SWORLD extends StatefulWidget {
  const SWORLD({super.key});

  @override
  State<SWORLD> createState() => _SWORLDState();
}

class _SWORLDState extends State<SWORLD> {
  @override
  void initState() {
    super.initState();
    setupFCM();
    _signInAnonymously();
  }

void setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (iOS)
  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    print("✅ FCM Token: $token");
  }

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📬 Foreground message received: ${message.notification?.title}');
  });

  // When opened from terminated state
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("🚀 App launched via FCM");
    }
  });

  // When app is in background but opened via notification
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("📲 Notification clicked (background)");
  });
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: routes,
      title: 'Sworld App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
