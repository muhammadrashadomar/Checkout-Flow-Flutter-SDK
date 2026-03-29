import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardNativeView extends StatelessWidget {
  final PaymentConfig paymentConfig;
  final CardConfig cardConfig;
  final SavedCardConfig? savedCardConfig;
  final Function(int)? onPlatformViewCreated;

  const CardNativeView({
    super.key,
    required this.paymentConfig,
    this.cardConfig = const CardConfig(),
    this.savedCardConfig,
    this.onPlatformViewCreated,
  });

  @override
  Widget build(BuildContext context) {
    const viewType = NativePlatformViewType.flowCardView;
    final creationParams = {
      ...paymentConfig.toMap(),
      'cardConfig': cardConfig.toMap(),
      if (savedCardConfig != null) 'savedCardConfig': savedCardConfig!.toMap(),
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType.name,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType.name,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }

    return const SizedBox.shrink();
  }
}
