/// Pins the `cardConfig` map the native card views read Remember Me from:
/// no `rememberMe` key hides it, and the phone goes out as digits only, and
/// only when both parts are present.
library;

import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardConfig.toMap', () {
    test('leaves out rememberMe when it is null, which hides Remember Me', () {
      expect(const CardConfig().toMap().containsKey('rememberMe'), isFalse);
    });

    test('sends an empty rememberMe map when nothing is prefilled', () {
      expect(
        const CardConfig(rememberMe: RememberMeConfig()).toMap()['rememberMe'],
        isEmpty,
      );
    });
  });

  group('RememberMeConfig.toMap', () {
    test('sends the trimmed email and a digits-only phone', () {
      const config = RememberMeConfig(
        email: ' guest@example.com ',
        phoneCountryCode: '+966',
        phoneNumber: '50 123-4567',
      );

      expect(config.toMap(), {
        'email': 'guest@example.com',
        'phone': {'countryCode': '966', 'number': '501234567'},
      });
    });

    test('drops the phone when either part is missing', () {
      expect(
        const RememberMeConfig(phoneCountryCode: '966').toMap(),
        isEmpty,
      );
      expect(
        const RememberMeConfig(phoneNumber: '501234567').toMap(),
        isEmpty,
      );
    });

    test('drops a blank email', () {
      expect(const RememberMeConfig(email: '  ').toMap(), isEmpty);
    });
  });

  test('configs with the same values compare equal', () {
    expect(
      const CardConfig(rememberMe: RememberMeConfig(email: 'a@b.co')),
      const CardConfig(rememberMe: RememberMeConfig(email: 'a@b.co')),
    );
  });
}
