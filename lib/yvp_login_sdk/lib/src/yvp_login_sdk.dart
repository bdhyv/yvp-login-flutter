import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:html' as html;
import 'dart:async';

/// Configuration for different environments
class YvpEnvironment {
  final String host;
  final int? port;
  final bool useHttps;
  final String loginPath;

  const YvpEnvironment({
    required this.host,
    this.port,
    required this.useHttps,
    required this.loginPath,
  });

  /// Get the base URL for this environment
  String get baseUrl {
    final scheme = useHttps ? 'https' : 'http';
    final portString = port != null ? ':$port' : '';
    return '$scheme://$host$portString';
  }

  /// Get the login URL for this environment
  String getLoginUrl(String appId, String language,
      {int? localhostCallbackPort}) {
    final url = Uri.parse('$baseUrl$loginPath');

    final queryParams = {
      'app_id': appId,
      'language': language,
    };

    // Add localhost_callback_port param only for local environment if provided
    if (this == YvpEnvironment.local && localhostCallbackPort != null) {
      queryParams['localhost_callback_port'] = localhostCallbackPort.toString();
    }

    return url.replace(queryParameters: queryParams).toString();
  }

  /// Local development environment
  static const local = YvpEnvironment(
    host: 'localhost',
    port: 3000,
    loginPath: '/auth/login',
    useHttps: false,
  );

  /// Android emulator environment
  static const emulator = YvpEnvironment(
    host: '10.0.2.2',
    port: 3000,
    loginPath: '/auth/login',
    useHttps: false,
  );

  /// Production environment
  static const production = YvpEnvironment(
    host: 'api-dev.youversion.com',
    //host: 'biblesdk-web-446696173378.us-central1.run.app',
    port: null,
    loginPath: '/auth/login',
    useHttps: true,
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
  final String language;

  YvpLoginSdk({
    required this.appId,
    required this.environment,
    this.language = 'en',
  });

  String get _callbackUrlScheme {
    if (kIsWeb) {
      return 'http';
    } else {
      // For mobile, use a custom URL scheme based on the app ID
      return 'yvp$appId';
    }
  }

  Future<LoginResult> _handleWebAuth() async {
    debugPrint('Starting web authentication...');

    // Get the current port from the running Flutter app
    final currentPort = Uri.base.port;
    debugPrint('Current Flutter app port: $currentPort');

    final authUrl = environment.getLoginUrl(appId, language,
        localhostCallbackPort:
            environment == YvpEnvironment.local ? currentPort : null);

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

        final authUrl = environment.getLoginUrl(appId, language,
            localhostCallbackPort:
                environment == YvpEnvironment.local ? currentPort : null);

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
