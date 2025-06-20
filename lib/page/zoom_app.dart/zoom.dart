import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_browser/flutter_web_browser.dart';

class ZoomScreen extends StatefulWidget {
  static var routeName = "/ZoomScreen";

  const ZoomScreen({super.key});

  @override
  State<ZoomScreen> createState() => _ZoomScreenState();
}

class _ZoomScreenState extends State<ZoomScreen> {
  Future<void> _createAndJoinMeeting() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.11:3000/create-meeting'));
      print("Raw response: ${response.body}");

      final data = jsonDecode(response.body);
      final joinUrl = data['join_url'];

      print("Zoom meeting link: $joinUrl");
      await FlutterWebBrowser.openWebPage(
        url: joinUrl,
        customTabsOptions: const CustomTabsOptions(
          toolbarColor: Colors.blue,
          showTitle: true,
        ),
      );
    } catch (e) {
      print("Error launching Zoom meeting: $e");
      String errorMessage = "❌ Failed to launch Zoom meeting";
      if (e.toString().contains("Could not launch")) {
        errorMessage = "❌ Could not launch Zoom. Please ensure the Zoom app or a browser is installed.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zoom Flutter")),
      body: Center(
        child: ElevatedButton(
          onPressed: _createAndJoinMeeting,
          child: const Text("Create & Join Zoom Meeting"),
        ),
      ),
    );
  }
}