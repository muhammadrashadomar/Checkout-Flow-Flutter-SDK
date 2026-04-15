/// Utility class to handle Checkout.com's specific amount formatting rules.
///
/// Checkout.com requires amounts as integers, with the multiplier depending on the currency.
class AmountUtils {
  /// Currencies that use the full amount (zero decimals).
  static const Set<String> _zeroDecimalCurrencies = {
    'BIF',
    'DJF',
    'GNF',
    'ISK',
    'JPY',
    'KMF',
    'KRW',
    'PYG',
    'RWF',
    'UGX',
    'VUV',
    'VND',
    'XAF',
    'XOF',
    'XPF',
  };

  /// Currencies that require the amount divided by 1000 (three decimals).
  static const Set<String> _threeDecimalCurrencies = {
    'BHD',
    'IQD',
    'JOD',
    'KWD',
    'LYD',
    'OMR',
    'TND',
  };

  /// Converts a human-readable amount (major unit) to the raw integer value expected by Checkout.com.
  ///
  /// Example:
  /// * USD 100.50 -> 10050
  /// * JPY 100 -> 100
  /// * BHD 100 -> 100000
  static int toRawAmount(double majorAmount, String currency) {
    if (majorAmount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }

    final currencyUpper = currency.toUpperCase();
    int rawValue;

    if (_zeroDecimalCurrencies.contains(currencyUpper)) {
      rawValue = majorAmount.round();
    } else if (_threeDecimalCurrencies.contains(currencyUpper)) {
      rawValue = (majorAmount * 1000).round();
    } else {
      // Default to 100 for all other currencies
      rawValue = (majorAmount * 100).round();
    }

    _validate(rawValue, currencyUpper);
    return rawValue;
  }

  /// Validates the raw amount against currency-specific constraints.
  static void _validate(int rawAmount, String currency) {
    final amountStr = rawAmount.toString();

    // Global constraint: Not contain more than nine digits
    if (amountStr.length > 9) {
      throw ArgumentError(
        'Amount value must not contain more than nine digits',
      );
    }

    // Constraint: Three-decimal currencies must end with 0
    if (_threeDecimalCurrencies.contains(currency) &&
        !amountStr.endsWith('0')) {
      throw ArgumentError(
        'For $currency, the last digit of the raw amount must be 0',
      );
    }

    // Constraint: CLP (Chilean Peso) must end with 00
    if (currency == 'CLP' && !amountStr.endsWith('00')) {
      throw ArgumentError(
        'For CLP, the last two digits of the raw amount must be 00',
      );
    }
  }

  /// Returns the decimal multiplier for a given currency.
  static int getMultiplier(String currency) {
    final currencyUpper = currency.toUpperCase();
    if (_zeroDecimalCurrencies.contains(currencyUpper)) return 1;
    if (_threeDecimalCurrencies.contains(currencyUpper)) return 1000;
    return 100;
  }
}
