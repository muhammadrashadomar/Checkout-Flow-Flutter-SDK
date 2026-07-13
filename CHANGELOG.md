# Changelog

## [1.0.0-dev19] - 2026-07-13

### Changed
- Updated Android Checkout Components SDK to `2.2.0`.

## [1.0.0-dev18] - 2026-07-13

### Fixed
- Apple Pay amount updates now pass the Flutter-provided currency to `UpdateDetails`.

## [1.0.0-dev17] - 2026-07-13

### Fixed
- Apple Pay amount updates no longer set `UpdateDetails.currency`, avoiding `0.00` totals for non-SAR currencies.
- Apple Pay now reports ready only after the amount update succeeds.

## [1.0.0-dev16] - 2026-07-12

### Fixed
- Apple Pay now applies the currency code received from Flutter when updating the payment amount.

## [0.1.0] - 2025-11-26

### Added
- Initial release of checkout_flow_flutter_sdk
- Card tokenization support via Checkout.com SDK
- Google Pay integration with tokenization
- Saved card flow with CVV input
- Comprehensive payment configuration models
- PaymentBridge service for unified payment handling
- Platform views for native card input components
- Android native implementation with Kotlin
- Complete error handling and logging
- Production-ready architecture with clean separation of concerns

### Features
- 🎯 Card Tokenization - Tokenize cards directly from Flutter
- 💳 Google Pay - Native Google Pay sheet integration
- 🎨 Customizable UI - Full appearance control from Flutter
- 🔧 Dynamic Configuration - No hardcoded values
- 🔒 Secure - Best practices for payment data handling
- 🧪 Production Ready - Comprehensive error handling

### Documentation
- Architecture guide
- Integration examples
- API reference
- Android setup instructions
