import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';

/// Session result model
class SessionResult {
  /// The card token from this submission. Null when the selected card has no
  /// client-side token (a Remember Me saved card); [sessionData] is still
  /// valid and is what pays.
  final CardTokenResult? token;
  final String sessionData;

  SessionResult({required this.token, required this.sessionData});
}
