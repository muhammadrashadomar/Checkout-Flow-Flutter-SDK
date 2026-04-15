class SavedCardConfig {
  // Checkout.com payment source ID (required for CVV-only)
  final String paymentSourceId;
  final String last4;
  final String scheme; // visa, mastercard, amex, etc.
  final int expiryMonth;
  final int expiryYear;
  final String? cardholderName;
  final String? bin;
  final String? issuer; // Bank name
  final String? issuerCountryCode; // ISO 3166-1 alpha-2 country code
  final String? issuerCountryName; // Bank country name

  SavedCardConfig({
    required this.paymentSourceId,
    required this.last4,
    required this.scheme,
    required this.expiryMonth,
    required this.expiryYear,
    this.cardholderName,
    this.bin,
    this.issuer,
    this.issuerCountryCode,
    this.issuerCountryName,
  });

  Map<String, dynamic> toMap() => {
    'paymentSourceId': paymentSourceId,
    'last4': last4,
    'scheme': scheme,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    if (cardholderName != null) 'cardholderName': cardholderName,
    if (bin != null) 'bin': bin,
    if (issuer != null) 'issuer': issuer,
    if (issuerCountryCode != null) 'issuerCountry': issuerCountryCode,
    if (issuerCountryName != null) 'issuerCountryName': issuerCountryName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCardConfig &&
          runtimeType == other.runtimeType &&
          paymentSourceId == other.paymentSourceId &&
          last4 == other.last4 &&
          scheme == other.scheme &&
          expiryMonth == other.expiryMonth &&
          expiryYear == other.expiryYear &&
          cardholderName == other.cardholderName &&
          bin == other.bin &&
          issuer == other.issuer &&
          issuerCountryCode == other.issuerCountryCode &&
          issuerCountryName == other.issuerCountryName;

  @override
  int get hashCode =>
      paymentSourceId.hashCode ^
      last4.hashCode ^
      scheme.hashCode ^
      expiryMonth.hashCode ^
      expiryYear.hashCode ^
      cardholderName.hashCode ^
      bin.hashCode ^
      issuer.hashCode ^
      issuerCountryCode.hashCode ^
      issuerCountryName.hashCode;

  @override
  String toString() {
    return 'SavedCardConfig(sourceId: $paymentSourceId, scheme: $scheme, last4: $last4, expiry: $expiryMonth/$expiryYear, issuer: $issuer, issuerCountry: $issuerCountryCode, issuerCountryName: $issuerCountryName)';
  }
}
