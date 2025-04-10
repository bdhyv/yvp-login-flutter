import 'package:flutter/material.dart';
import 'yvp_login_sdk.dart';

/// A pre-styled button for YouVersion login
class YvpLoginButton extends StatelessWidget {
  final YvpLoginSdk sdk;
  final Function(String lat, Map<String, String> params)? onSuccess;
  final Function(String error)? onError;
  final ButtonStyle? style;
  final Widget? child;

  const YvpLoginButton({
    Key? key,
    required this.sdk,
    this.onSuccess,
    this.onError,
    this.style,
    this.child,
  }) : super(key: key);

  Future<void> _handleLogin(BuildContext context) async {
    try {
      final result = await sdk.login();
      if (result.isSuccess && result.lat != null) {
        final uri = Uri.parse(result.responseUrl ?? '');
        final params = uri.queryParameters;
        onSuccess?.call(result.lat!, params);
      } else {
        onError?.call(result.error ?? 'Login failed');
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style ??
          ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      onPressed: () => _handleLogin(context),
      child: child ??
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login),
              SizedBox(width: 8),
              Text(
                'Login with YouVersion',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
    );
  }
}
