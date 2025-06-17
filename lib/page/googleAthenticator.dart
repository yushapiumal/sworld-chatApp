import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sworld_flutter/page/autofill.dart';

class Authenticator extends StatefulWidget {
  static String routeName = "authenticator";

  const Authenticator({super.key});

  @override
  _AuthenticatorState createState() => _AuthenticatorState();
}

class _AuthenticatorState extends State<Authenticator> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  String? _secretKey;
  String _code = '';
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSecretKey();
  }

  Future<void> _loadSecretKey() async {
    _secretKey = await _storage.read(key: 'secretKey');
    if (_secretKey == null) {
      _generateNewSecret();
    }
    setState(() {});
  }

  void _generateNewSecret() async {
    try {
      _secretKey = OTP.randomSecret();
      await _storage.write(key: 'secretKey', value: _secretKey);
      setState(() {});
    } catch (e) {
      debugPrint('Error generating new secret: $e');
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate secret key')),
      );
    }
  }

  String _getOtpUrl() {
   return 'otpauth://totp/Sworld:yushanpiumal.com?secret=$_secretKey&issuer=Sworld&algorithm=SHA1&digits=6&period=30';
  }

  void _verifyCode() {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(
          DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch));
      print('Formatted Timestamp: $formattedTimestamp');

      // Generate the expected TOTP code
      final currentCode = OTP.generateTOTPCodeString(
        _secretKey!,
        timestamp,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      // Validate the entered code
      if (_code == currentCode) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success!'),
            content: const Text('Code verification successful'),
            actions: [
              TextButton(
                onPressed: () =>  Navigator.pushReplacementNamed(context, OTPVerificationScreen.routeName),
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again')),
        );
      }
    } catch (e) {
      debugPrint('Error verifying code: $e');
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while verifying code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sworld Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async => _generateNewSecret(),
            tooltip: 'Generate New Secret',
          )
        ],
      ),
      body: _secretKey == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Scan QR Code with Authenticator App',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: _getOtpUrl(),
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text('Or enter this secret key manually:',
                      style: TextStyle(fontSize: 16)),
                  SelectableText(_secretKey!,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit code',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.length != 6) {
                              return 'Please enter a valid 6-digit code';
                            }
                            return null;
                          },
                          onChanged: (value) => _code = value,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user),
                          label: const Text('Verify Code'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _verifyCode();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
