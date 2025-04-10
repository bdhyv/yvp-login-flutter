import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:async';

/// Configuration for different environments
class YvpEnvironment {
  final String authHost;
  final String redirectHost;
  final int? authPort;
  final int? redirectPort;
  final String redirectPath;
  final bool useHttps;
  final String clientId;
  final String clientSecret;
  final String callbackUri;

  const YvpEnvironment({
    required this.authHost,
    required this.redirectHost,
    this.authPort,
    this.redirectPort,
    required this.redirectPath,
    required this.useHttps,
    required this.clientId,
    required this.clientSecret,
    required this.callbackUri,
  });

  /// Local development environment
  static const local = YvpEnvironment(
    authHost: 'localhost',
    redirectHost: 'localhost',
    authPort: 3001,
    redirectPort: 3000,
    redirectPath: '/authenticate',
    useHttps: false,
    clientId: '618ab8038deee8f4ab48e1ccc122e320',
    clientSecret: '3ce345b71168a613540ed1e268bac402',
    callbackUri: 'http://localhost:3000/authenticate',
  );

  /// Production environment
  static const production = YvpEnvironment(
    authHost: 'login-staging.youversion.com',
    redirectHost: 'biblesdk-web-890431326916.us-central1.run.app',
    authPort: null,
    redirectPort: null,
    redirectPath: '/auth/callback',
    useHttps: true,
    clientId: '5d00f7937d507f61b8fcfc693c32095e',
    clientSecret: '311cbf75048acbd93fa01d3d543fa945',
    callbackUri:
        'https://biblesdk-web-890431326916.us-central1.run.app/auth/callback',
  );
}

/// Represents the result of a login attempt
class LoginResult {
  final String? lat;
  final String? error;
  final bool isSuccess;
  final String? responseUrl;

  LoginResult.success(this.lat, {this.responseUrl})
      : error = null,
        isSuccess = true;

  LoginResult.error(this.error)
      : lat = null,
        responseUrl = null,
        isSuccess = false;
}

/// The main SDK class for YouVersion login integration
class YvpLoginSdk {
  final String appId;
  final YvpEnvironment environment;

  YvpLoginSdk({
    required this.appId,
    required this.environment,
  });

  String get _callbackUrlScheme {
    if (kIsWeb) {
      return Uri.parse(environment.callbackUri).scheme;
    } else {
      // For mobile, use a custom URL scheme based on the app ID
      return 'yvp$appId';
    }
  }

  String get _mobileRedirectUri {
    return 'yvp$appId://authenticate';
  }

  /// Constructs the authentication URL with all necessary parameters
  String _buildAuthUrl(String callbackUri) {
    final scheme = environment.useHttps ? 'https' : 'http';

    final redirectUrl = Uri(
      scheme: environment.useHttps ? 'https' : 'http',
      host: environment.redirectHost,
      port: environment.redirectPort,
      path: environment.redirectPath,
      queryParameters: {
        'app_id': appId,
        'callback_uri': environment.authHost == 'localhost'
            ? callbackUri
            : 'https://lifechurch.gitlab.io/biblelabs/yvp-login-flutter',
      },
    ).toString();

    return Uri(
      scheme: scheme,
      host: environment.authHost,
      port: environment.authPort,
      queryParameters: {
        'client_id': environment.clientId,
        'client_secret': environment.clientSecret,
        'redirect_uri': redirectUrl,
      },
    ).toString();
  }

  Future<LoginResult> _handleWebAuth() async {
    debugPrint('Starting web authentication...');

    // Get the current port from the running Flutter app
    final currentPort = Uri.base.port;
    debugPrint('Current Flutter app port: $currentPort');

    final callbackUri = 'http://localhost:$currentPort/';
    final authUrl = _buildAuthUrl(callbackUri);

    debugPrint('Opening popup with URL: $authUrl');
    // Open the auth URL in a popup window
    final popup = html.window.open(authUrl, 'auth', 'width=800,height=600');

    if (popup == null) {
      debugPrint('Failed to open popup window');
      return LoginResult.error('Failed to open authentication window');
    }

    // Create a completer to handle the result
    final completer = Completer<LoginResult>();

    // Function to handle the message event
    void handleMessage(dynamic event) {
      debugPrint('Received message event');
      if (event is html.MessageEvent) {
        final data = event.data as String;
        debugPrint('Parsing message data: $data');
        final uri = Uri.parse(data);
        final lat = uri.queryParameters['lat'];
        final status = uri.queryParameters['status'];

        debugPrint('Auth result - lat: $lat, status: $status');

        if (lat != null && status == 'success') {
          debugPrint('Authentication successful');
          completer.complete(LoginResult.success(lat, responseUrl: data));
        } else {
          debugPrint('Authentication failed - no lat or invalid status');
          completer.complete(LoginResult.error(
              'Authentication failed or no LAT token received'));
        }
        popup.close();
        // Remove the event listener after handling the response
        html.window.removeEventListener('message', handleMessage);
      }
    }

    // Listen for messages from the popup
    html.window.addEventListener('message', handleMessage);

    return completer.future;
  }

  /// Initiates the login process and returns a [LoginResult]
  ///
  /// Example usage:
  /// ```dart
  /// final result = await sdk.login();
  /// if (result.isSuccess) {
  ///   final lat = result.lat;
  ///   // Use the LAT token
  /// } else {
  ///   final error = result.error;
  ///   // Handle the error
  /// }
  /// ```
  Future<LoginResult> login() async {
    debugPrint('Starting login process...');
    try {
      if (kIsWeb) {
        debugPrint('Running in web environment');
        return await _handleWebAuth();
      } else {
        debugPrint('Running in mobile environment');

        // Get the current port from the running Flutter app
        final currentPort = Uri.base.port;
        debugPrint('Current Flutter app port: $currentPort');

        final callbackUri = 'http://localhost:$currentPort/';
        final authUrl = _buildAuthUrl(callbackUri);

        debugPrint('Starting mobile authentication with URL: $authUrl');
        final result = await FlutterWebAuth2.authenticate(
          url: authUrl,
          callbackUrlScheme: _callbackUrlScheme,
        );

        debugPrint('Received mobile authentication result: $result');
        final uri = Uri.parse(result);
        final lat = uri.queryParameters['lat'];
        final status = uri.queryParameters['status'];

        debugPrint('Mobile auth result - lat: $lat, status: $status');

        if (lat != null && status == 'success') {
          debugPrint('Mobile authentication successful');
          return LoginResult.success(lat, responseUrl: result);
        } else {
          debugPrint('Mobile authentication failed - no lat or invalid status');
          return LoginResult.error(
              'Authentication failed or no LAT token received');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return LoginResult.error(e.toString());
    }
  }
}
