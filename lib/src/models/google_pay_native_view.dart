import 'package:checkout_flutter_bridge/checkout_flutter_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GooglePayNativeView extends StatelessWidget {
  final PaymentConfig paymentConfig;
  final GooglePayConfig googlePayConfig;

  const GooglePayNativeView({
    super.key,
    required this.paymentConfig,
    required this.googlePayConfig,
  });

  @override
  Widget build(BuildContext context) {
    const viewType = NativePlatformViewType.flowGooglePayView;
    final creationParams = {
      ...paymentConfig.toMap(),
      'googlePayConfig': googlePayConfig.toMap(),
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType.name,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const SizedBox.shrink();
  }
}
