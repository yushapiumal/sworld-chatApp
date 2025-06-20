import 'package:flutter/material.dart';
//import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

const int appId = 1230715503; 
const String appSign = "dc2e1f6391db191583668c0f020b9693c4400aa7eccdfd58f990945da08435df"; 
class CallScreen extends StatelessWidget {
  final String callID;

  static String routeName = "CallScreen";

  const CallScreen({super.key, required this.callID});

  @override
  Widget build(BuildContext context) {
    // Simple check for demo; you can customize this.
    if (appId == -1 || appSign.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Zego App ID or Sign Missing"),
            content: const Text(
                "Please replace appId and appSign with your real credentials."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
      return Scaffold(
        appBar: AppBar(title: const Text("Zego Call")),
        body: const Center(child: Text("Missing Zego credentials")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Zego Call")),
      // body: ZegoUIKitPrebuiltCall(
      //   appID: appId,
      //   appSign: appSign,
      //   userID: 'user_${DateTime.now().millisecondsSinceEpoch}',
      //   userName: 'Flutter User',
      //   callID: callID,
      //   config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      // ),
    );
  }
}
