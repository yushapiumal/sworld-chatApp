import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:sworld_flutter/config/api.dart';
import 'package:sworld_flutter/page/login.dart';

class OTPVerificationScreen extends StatefulWidget {

  static String routeName = "autofill";

  const OTPVerificationScreen({super.key});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with CodeAutoFill {
  String? otpCode;
  final apiService = ApiServices();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final int _resendTimeout = 30;
  final bool _canResend = true;
  bool _isVerifying = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initAutoFill();
    _startAutoListen();
    getAppSignature();
  }

  Future<void> _initAutoFill() async {
    await SmsAutoFill().unregisterListener();
    listenForCode();
  }

  void _startAutoListen() {
    _subscription = SmsAutoFill().code.listen((code) {
      if (code.length == 6) {
        otpCode = code;
        otpController.text = code;
        _autoVerifyAndContinue();
      }
    });
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      otpCode = code;
      otpController.text = code!;
      _autoVerifyAndContinue();
    }
  }

  Future<void> _autoVerifyAndContinue() async {
    // Add slight delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 300));
    _submitOTP();
  }

  Future<void> _submitOTP() async {
    if (!_formKey.currentState!.validate() ||
        otpCode?.length != 6 ||
        _isVerifying) {
      return;
    }

    setState(() => _isVerifying = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final verified = await apiService.verifyOtp(
        '+94${phoneController.text}',
        otpCode!,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (verified) {
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phone input field
              TextFormField(
                maxLength: 9,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+94',
                  hintText: "0768024806",
                  hintStyle: TextStyle(
                    color: Colors.blue
                        .withOpacity(0.4), // makes it look "blurred" or faded
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  } else if (value.length != 9 ||
                      !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendOtp,
                child: const Text('Send OTP'),
              ),
              const SizedBox(height: 30),
              PinFieldAutoFill(
                controller: otpController,
                codeLength: 6,
                onCodeSubmitted: (code) => _submitOTP(),
                onCodeChanged: (code) {
                  if (code?.length == 6) {
                    otpCode = code;
                    _autoVerifyAndContinue();
                  }
                },
                decoration: BoxLooseDecoration(
                  strokeColorBuilder: const FixedColorBuilder(Colors.grey),
                  gapSpace: 10,
                  textStyle: const TextStyle(fontSize: 24, color: Colors.black),
                ),
              ),
              // ... (rest of the UI elements)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+94${phoneController.text}';
    try {
      await apiService.sendOtpRequest(phone);
      //  _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: ${e.toString()}')),
      );
    }
  }

  void getAppSignature() async {
    final signature = await SmsAutoFill().getAppSignature;
    print("App Signature: $signature");
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }
}
