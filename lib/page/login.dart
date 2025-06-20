import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sworld_flutter/page/zoom_app.dart/zoom.dart';


class LoginPage extends StatefulWidget {
  static String routeName = "LoginPage";
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  AnimationController? _animationController;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _scaleAnimation3;
  final LocalAuthentication auth = LocalAuthentication();
  String _message = 'Not authenticated';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation1 = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
    );
    _scaleAnimation2 = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
    );
    _scaleAnimation3 = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();

    _animationController!.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _message = 'Biometric authentication not supported';
        });
        return;
      }

      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      setState(() {
        _message = didAuthenticate
            ? 'Authenticated successfully ✅'
            : 'Authentication failed ❌';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        print(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 6,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Login',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ), // Login Form
          Container(
            color: Colors.black.withOpacity(0.1),
            child: Center(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                   Text(_message, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Authenticate'),
              onPressed: _authenticate,
            ),
                  // Login Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Card(
                        


                        elevation: 1,
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const TextField(
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.email, color: Colors.white),
                                  labelText: 'Email',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white54),
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              const TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.white),
                                  labelText: 'Password',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white54),
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              ScaleTransition(
                                scale: _scaleAnimation1,
                                child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor:
                                            Colors.white.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.3)),
                                        ),
                                      ),
                                      onPressed: () async {
                                        _controller1.forward().then(
                                            (_) => _controller1.reverse());
                                            Navigator.pushReplacementNamed(context, ZoomScreen.routeName);
                                          //  Navigator.pushReplacementNamed(context, ChatScreen.routeName);

                                      },
                                      child: const Text('LOGIN',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    )),
                              ),
                              const SizedBox(height: 16),
                              ScaleTransition(
                                scale: _scaleAnimation2,
                                child: TextButton(
                                  onPressed: () {
                                    _controller2
                                        .forward()
                                        .then((_) => _controller2.reverse());
                                         
                                  },
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.white)),
                      ScaleTransition(
                        scale: _scaleAnimation3,
                        child: GestureDetector(
                          onTap: () {
                            _controller3
                                .forward()
                                .then((_) => _controller3.reverse());
                          },
                          child: const Text('Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Color.fromARGB(179, 101, 52, 235),
                                decorationThickness: 4.0,
                                decorationStyle: TextDecorationStyle.solid,
                              )),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}


//TBNLXCSX4LXY23HB