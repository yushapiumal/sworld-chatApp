import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class ApiServices {
  static const _baseUrl = 'http://192.168.1.13:3000';

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {}

  static Future<String?> getToken() async {
    return null;
  }

//SEND OTP

  Future<void> sendOtpRequest(String phone) async {
   final url = Uri.parse('$_baseUrl/api/send-otp');
    print(phone);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "OTP sent to $phone",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        print(response.body);
      } else {
        Fluttertoast.showToast(
          msg: "Failed to send OTP: ${response.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error sending OTP: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Verify OTP

Future<bool> verifyOtp(String phoneNumber, String otp) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/api/verify-otp'),
    headers: {
      'Content-Type': 'application/json', 
    },
    body: jsonEncode({ 
      "phoneNumber": phoneNumber,
      "otp": otp,
    }),
  );

  print('phone is $phoneNumber');
  print('otp is $otp');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data);
    return data['success'] == true;
  } else {
    print('Failed to verify OTP: ${response.statusCode}');
    return false;
  }
}
}

// 777477875