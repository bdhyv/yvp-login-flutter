import 'package:flutter/material.dart';
import 'package:yvp_login_sdk/yvp_login_sdk.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if this is the authentication response
    final uri = Uri.base;
    if (uri.hasQuery && uri.queryParameters.containsKey('lat')) {
      // Send the response back to the opener window
      html.window.opener?.postMessage(uri.toString(), '*');
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Authentication Response'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentication successful!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Callback Parameters:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...uri.queryParameters.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )),
                const SizedBox(height: 20),
                const Text(
                  'You can close this window.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'YouVersion Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const environment =
      //YvpEnvironment.local; // or YvpEnvironment.production
      YvpEnvironment.production;

  final _sdk = YvpLoginSdk(
    appId: 'demo_app',
    environment: environment,
  );

  String? _lat;
  Map<String, String> _authParams = {};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initUniLinks();
    } else {
      _initWebUrlListener();
    }
  }

  Future<void> _initUniLinks() async {
    try {
      // Handle incoming links when app is in foreground
      linkStream.listen((String? link) {
        if (link != null) {
          _handleAuthResponse(link);
        }
      }, onError: (err) {
        debugPrint('Error listening to links: $err');
      });

      // Handle incoming links when app is in background
      getInitialLink().then((String? link) {
        if (link != null) {
          _handleAuthResponse(link);
        }
      });
    } on PlatformException {
      debugPrint('Failed to initialize uni_links');
    }
  }

  void _initWebUrlListener() {
    // For web, we can check the current URL for auth parameters
    final uri = Uri.base;
    if (uri.queryParameters.isNotEmpty) {
      _handleAuthResponse(uri.toString());
    }
  }

  void _handleAuthResponse(String url) {
    final uri = Uri.parse(url);
    final lat = uri.queryParameters['lat'];
    final status = uri.queryParameters['status'];

    if (mounted) {
      if (lat != null && status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful! LAT: $lat')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: Invalid response')),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    try {
      final result = await _sdk.login();
      if (result.isSuccess) {
        if (mounted) {
          setState(() {
            _lat = result.lat;
            // Parse the full response URL to get all parameters
            final uri = Uri.parse(result.responseUrl ?? '');
            _authParams = uri.queryParameters;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouVersion Login Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Example Church',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            YvpLoginButton(
              sdk: _sdk,
              onSuccess: (lat, params) {
                setState(() {
                  _lat = lat;
                  _authParams = params;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login successful!')),
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login failed: $error')),
                );
              },
            ),
            if (_lat != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Authentication Response:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._authParams.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
