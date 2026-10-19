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

  /// Checkout's Remember Me section under the card fields. `null` hides it.
  final RememberMeConfig? rememberMe;

  const CardConfig({
    this.showCardholderName = false,
    this.enableBillingAddress = false,
    this.rememberMe,
  });

  Map<String, dynamic> toMap() {
    return {
      'showCardholderName': showCardholderName,
      'enableBillingAddress': enableBillingAddress,
      if (rememberMe != null) 'rememberMe': rememberMe!.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardConfig &&
          runtimeType == other.runtimeType &&
          showCardholderName == other.showCardholderName &&
          enableBillingAddress == other.enableBillingAddress &&
          rememberMe == other.rememberMe;

  @override
  int get hashCode =>
      showCardholderName.hashCode ^
      enableBillingAddress.hashCode ^
      rememberMe.hashCode;
}

/// Prefills Checkout's Remember Me section.
///
/// Remember Me also has to be enabled on the Checkout account, and the
/// payment session request needs `customer.email` for the sign-up option to
/// appear. These values only prefill the fields: Checkout looks returning
/// customers up by them and sends the one-time code there.
///
/// Checkout's own Remember Me pay button is always hidden, so the payment
/// stays with the app's pay button.
class RememberMeConfig {
  final String? email;

  /// Dial code, with or without a leading `+` (`'966'` or `'+966'`).
  final String? phoneCountryCode;

  /// National number without the dial code.
  final String? phoneNumber;

  const RememberMeConfig({
    this.email,
    this.phoneCountryCode,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    final email = this.email?.trim() ?? '';
    // Checkout's mobile SDKs take digits only ('44', not '+44').
    final countryCode = _digitsOnly(phoneCountryCode);
    final number = _digitsOnly(phoneNumber);
    return {
      if (email.isNotEmpty) 'email': email,
      if (countryCode.isNotEmpty && number.isNotEmpty)
        'phone': {'countryCode': countryCode, 'number': number},
    };
  }

  static String _digitsOnly(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RememberMeConfig &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          phoneCountryCode == other.phoneCountryCode &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode =>
      email.hashCode ^ phoneCountryCode.hashCode ^ phoneNumber.hashCode;
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

/// The label on the Apple Pay button, mirroring `PKPaymentButtonType`.
///
/// Prefixed so it doesn't clash with the `pay` package's `ApplePayButtonType`
/// in apps that use both.
enum CheckoutApplePayButtonType {
  plain,
  buy,
  book,
  checkout,
  inStore,
  subscribe,
}

/// The Apple Pay button variant, mirroring `PKPaymentButtonStyle`.
///
/// Apple's guidelines require the variant that contrasts with the background:
/// [black] on light backgrounds, [white] or [whiteOutline] on dark ones.
enum CheckoutApplePayButtonStyle { black, white, whiteOutline }

/// Apple Pay Configuration (iOS)
class ApplePayConfig {
  /// Apple Pay merchant identifier (e.g., 'merchant.com.company.app')
  /// This must be configured in Apple Developer Portal
  final String merchantIdentifier;
  final String merchantName;
  final String countryCode;
  final String currencyCode;
  final double amount;

  /// When set, the plugin draws Apple's own `PKPaymentButton` with this label
  /// instead of the Checkout SDK's button, whose label, style and corners
  /// can't be configured, and starts the payment when it is tapped.
  /// When null, the Checkout SDK's button is shown as before.
  final CheckoutApplePayButtonType? buttonType;

  /// Style of the button drawn for [buttonType]. Ignored without it.
  final CheckoutApplePayButtonStyle buttonStyle;

  /// Corner radius of the button drawn for [buttonType], in points; half the
  /// view's height gives a pill. Null keeps Apple's default. Ignored without
  /// [buttonType].
  final double? buttonCornerRadius;

  const ApplePayConfig({
    required this.merchantIdentifier,
    required this.merchantName,
    required this.countryCode,
    required this.currencyCode,
    required this.amount,
    this.buttonType,
    this.buttonStyle = CheckoutApplePayButtonStyle.black,
    this.buttonCornerRadius,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'merchantName': merchantName,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'amount': AmountUtils.toRawAmount(amount, currencyCode),
      if (buttonType != null) ...{
        'buttonType': buttonType!.name,
        'buttonStyle': buttonStyle.name,
        if (buttonCornerRadius != null)
          'buttonCornerRadius': buttonCornerRadius,
      },
    };
  }
}
