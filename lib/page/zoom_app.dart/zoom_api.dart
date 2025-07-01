import 'dart:convert';
import 'package:http/http.dart' as http;

class ZoomApiService {
  static const String _baseUrl = 'http://192.168.1.12:3000/zoom';

  /// Get Zoom OAuth authorization URL
  static Future<String> getAuthUrl() async {
    final response = await http.get(Uri.parse('$_baseUrl/auth-url'));
    final data = jsonDecode(response.body);
    return data['url'];
  }

  /// Create a new Zoom meeting
  static Future<Map<String, dynamic>> createMeeting({String? topic}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/createMeeting'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "topic": topic ?? "New Flutter Meeting",
      }),
    );
    return jsonDecode(response.body);
  }

  /// List Zoom meetings
  static Future<Map<String, dynamic>> listMeetings() async {
    final response = await http.get(Uri.parse('$_baseUrl/listMeetings'));
    return jsonDecode(response.body);
  }

  /// Get meeting details
  static Future<Map<String, dynamic>> getMeeting(String meetingId) async {
    final response = await http.get(Uri.parse('$_baseUrl/getMeeting/$meetingId'));
    return jsonDecode(response.body);
  }

  /// Update a meeting
  static Future<Map<String, dynamic>> updateMeeting(
      String meetingId, Map<String, dynamic> updateData) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/updateMeeting/$meetingId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    return jsonDecode(response.body);
  }

  /// Delete a meeting
  static Future<Map<String, dynamic>> deleteMeeting(String meetingId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/deleteMeeting/$meetingId'));
    return jsonDecode(response.body);
  }

  /// Get participants for a past meeting
  static Future<Map<String, dynamic>> getParticipants(String meetingId) async {
    final response = await http.get(Uri.parse('$_baseUrl/getParticipants/$meetingId'));
    return jsonDecode(response.body);
  }

  /// List recordings
  static Future<Map<String, dynamic>> listRecordings() async {
    final response = await http.get(Uri.parse('$_baseUrl/listRecordings'));
    return jsonDecode(response.body);
  }

  /// Delete a recording
  static Future<Map<String, dynamic>> deleteRecording(String recordingId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/deleteRecording/$recordingId'));
    return jsonDecode(response.body);
  }
}
