# YouVersion Login SDK for Flutter

A Flutter SDK that provides a simple way to integrate YouVersion login into your Flutter applications.

## Features

- Cross-platform support (Web, iOS, Android)
- Simple API for login integration
- Handles OAuth flow automatically
- Returns authorization code for further processing

## Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  yvp_login_sdk:
    path: ../path/to/yvp_login_sdk
```

## Usage

1. Initialize the SDK with your credentials:

```dart
final sdk = YvpLoginSdk(
  clientId: 'your_client_id',
  clientSecret: 'your_client_secret',
  redirectUri: 'http://localhost:3000/authenticate', // For web
  appId: 'your_app_id',
);
```

2. Call the login method and handle the result:

```dart
try {
  final result = await sdk.login();
  if (result.isSuccess) {
    final code = result.code;
    // Use the authorization code to get access tokens, etc.
    print('Login successful! Code: $code');
  } else {
    final error = result.error;
    // Handle the error
    print('Login failed: $error');
  }
} catch (e) {
  // Handle any unexpected errors
  print('Error: $e');
}
```

## Platform Configuration

### Web

For web platforms, the redirect URI should be a valid web URL that your application can handle. The SDK will automatically handle the OAuth flow in a popup window.

### iOS

Add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yvp{your_app_id}</string>
        </array>
    </dict>
</array>
```

### Android

Add the following to your `AndroidManifest.xml` inside the `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="yvp{your_app_id}" />
</intent-filter>
```

## Example

Here's a complete example of how to use the SDK in a Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:yvp_login_sdk/yvp_login_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  final _sdk = YvpLoginSdk(
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret',
    redirectUri: 'http://localhost:3000/authenticate',
    appId: 'your_app_id',
  );

  Future<void> _handleLogin() async {
    try {
      final result = await _sdk.login();
      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful! Code: ${result.code}')),
          );
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
      body: Center(
        child: ElevatedButton(
          onPressed: _handleLogin,
          child: const Text('Login with YouVersion'),
        ),
      ),
    );
  }
}
```

## License

This SDK is provided under the MIT License. 