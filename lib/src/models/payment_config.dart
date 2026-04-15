import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';

/// Payment configuration models for platform channels
class PaymentConfig {
  final String paymentSessionId;
  final String paymentSessionSecret;
  final String publicKey;
  final PaymentEnvironment environment;
  final AppearanceConfig? appearance;

  const PaymentConfig({
    required this.paymentSessionId,
    required this.paymentSessionSecret,
    required this.publicKey,
    this.environment = PaymentEnvironment.sandbox,
    this.appearance,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentSessionID': paymentSessionId,
      'paymentSessionSecret': paymentSessionSecret,
      'publicKey': publicKey,
      'environment': environment.name,
      if (appearance != null) 'appearance': appearance!.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentConfig &&
          runtimeType == other.runtimeType &&
          paymentSessionId == other.paymentSessionId &&
          paymentSessionSecret == other.paymentSessionSecret &&
          publicKey == other.publicKey &&
          environment == other.environment &&
          appearance == other.appearance;

  @override
  int get hashCode =>
      paymentSessionId.hashCode ^
      paymentSessionSecret.hashCode ^
      publicKey.hashCode ^
      environment.hashCode ^
      appearance.hashCode;
}

enum PaymentEnvironment { sandbox, production }

class AppearanceConfig {
  final ColorTokens? colorTokens;
  final int? borderRadius;
  final FontConfig? fontConfig;

  const AppearanceConfig({
    this.colorTokens,
    this.borderRadius,
    this.fontConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      if (colorTokens != null) 'colorTokens': colorTokens!.toMap(),
      if (borderRadius != null) 'borderRadius': borderRadius,
      if (fontConfig != null) 'fontConfig': fontConfig!.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearanceConfig &&
          runtimeType == other.runtimeType &&
          colorTokens == other.colorTokens &&
          borderRadius == other.borderRadius &&
          fontConfig == other.fontConfig;

  @override
  int get hashCode =>
      colorTokens.hashCode ^ borderRadius.hashCode ^ fontConfig.hashCode;
}

class ColorTokens {
  final int? colorAction;
  final int? colorPrimary;
  final int? colorBorder;
  final int? colorFormBorder;
  final int? colorBackground;

  const ColorTokens({
    this.colorAction,
    this.colorPrimary,
    this.colorBorder,
    this.colorFormBorder,
    this.colorBackground,
  });

  Map<String, dynamic> toMap() {
    return {
      if (colorAction != null) 'colorAction': colorAction,
      if (colorPrimary != null) 'colorPrimary': colorPrimary,
      if (colorBorder != null) 'colorBorder': colorBorder,
      if (colorFormBorder != null) 'colorFormBorder': colorFormBorder,
      if (colorBackground != null) 'colorBackground': colorBackground,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorTokens &&
          runtimeType == other.runtimeType &&
          colorAction == other.colorAction &&
          colorPrimary == other.colorPrimary &&
          colorBorder == other.colorBorder &&
          colorFormBorder == other.colorFormBorder &&
          colorBackground == other.colorBackground;

  @override
  int get hashCode =>
      colorAction.hashCode ^
      colorPrimary.hashCode ^
      colorBorder.hashCode ^
      colorFormBorder.hashCode ^
      colorBackground.hashCode;
}

class FontConfig {
  final int? fontSize;
  final String? fontWeight;

  const FontConfig({this.fontSize, this.fontWeight});

  Map<String, dynamic> toMap() {
    return {
      if (fontSize != null) 'fontSize': fontSize,
      if (fontWeight != null) 'fontWeight': fontWeight,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontConfig &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          fontWeight == other.fontWeight;

  @override
  int get hashCode => fontSize.hashCode ^ fontWeight.hashCode;
}

class CardConfig {
  final bool showCardholderName;
  final bool enableBillingAddress;

  const CardConfig({
    this.showCardholderName = false,
    this.enableBillingAddress = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'showCardholderName': showCardholderName,
      'enableBillingAddress': enableBillingAddress,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardConfig &&
          runtimeType == other.runtimeType &&
          showCardholderName == other.showCardholderName &&
          enableBillingAddress == other.enableBillingAddress;

  @override
  int get hashCode =>
      showCardholderName.hashCode ^ enableBillingAddress.hashCode;
}

class GooglePayConfig {
  final String merchantId;
  final String merchantName;
  final String countryCode;
  final String currencyCode;
  final double totalPrice;
  final String totalPriceLabel;

  const GooglePayConfig({
    required this.merchantId,
    required this.merchantName,
    required this.countryCode,
    required this.currencyCode,
    required this.totalPrice,
    this.totalPriceLabel = 'Total',
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'merchantName': merchantName,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'totalPrice': AmountUtils.toRawAmount(totalPrice, currencyCode),
      'totalPriceLabel': totalPriceLabel,
    };
  }
}

/// Apple Pay Configuration (iOS)
class ApplePayConfig {
  /// Apple Pay merchant identifier (e.g., 'merchant.com.company.app')
  /// This must be configured in Apple Developer Portal
  final String merchantIdentifier;
  final String merchantName;
  final String countryCode;
  final String currencyCode;
  final double amount;

  const ApplePayConfig({
    required this.merchantIdentifier,
    required this.merchantName,
    required this.countryCode,
    required this.currencyCode,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'merchantName': merchantName,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'amount': AmountUtils.toRawAmount(amount, currencyCode),
    };
  }
}
