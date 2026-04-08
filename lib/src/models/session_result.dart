import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';

/// Session result model
class SessionResult {
  final CardTokenResult token;
  final String sessionData;

  SessionResult({required this.token, required this.sessionData});
}
