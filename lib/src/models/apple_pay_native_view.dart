import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApplePayNativeView extends StatelessWidget {
  final PaymentConfig paymentConfig;
  final ApplePayConfig applePayConfig;

  const ApplePayNativeView({
    super.key,
    required this.paymentConfig,
    required this.applePayConfig,
  });

  @override
  Widget build(BuildContext context) {
    const viewType = NativePlatformViewType.flowApplePayView;
    final creationParams = {
      ...paymentConfig.toMap(),
      'applePayConfig': applePayConfig.toMap(),
    };

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType.name,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const SizedBox.shrink();
  }
}
