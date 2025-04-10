# YouVersion Login SDK for Flutter

A Flutter package that provides easy integration with YouVersion login functionality.

## Features

- Simple "Login with YouVersion" button widget
- Handles both web and mobile authentication flows
- Returns LAT token and additional parameters
- Supports custom styling and callbacks

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  yvp_login_sdk:
    path: ../yvp_login_sdk  # Adjust the path as needed
```

## Usage

### Basic Integration

1. Initialize the SDK with your app ID:

```dart
final sdk = YvpLoginSdk(
  appId: 'your_app_id',
  environment: YvpEnvironment.production, // or YvpEnvironment.local for development
);
```

2. Add the login button to your UI:

```dart
YvpLoginButton(
  sdk: sdk,
  onSuccess: (lat, params) {
    // Handle successful login
    print('LAT token: $lat');
    print('Additional params: $params');
  },
  onError: (error) {
    // Handle login error
    print('Login error: $error');
  },
)
```

### Custom Styling

You can customize the button's appearance:

```dart
YvpLoginButton(
  sdk: sdk,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    // Add more custom styles
  ),
  child: const Text('Custom Login Text'),
)
```

### Callback Parameters

The SDK returns the following parameters in the success callback:

- `lat`: The login access token
- `yvp_user_id`: The YouVersion user ID
- `status`: The login status (usually "success")

## Web Integration

For web applications, make sure to:

1. Configure your callback URL in the YouVersion developer portal
2. Handle the redirect in your web application

## Mobile Integration

For mobile applications:

1. Add the following to your `AndroidManifest.xml`:

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity">
    <intent-filter android:label="flutter_web_auth_2">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="yvp{your_app_id}" />
    </intent-filter>
</activity>
```

2. Add the following to your `Info.plist`:

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

## Example

See the example app in the `example` directory for a complete implementation.

## License

This package is licensed under the MIT License. 