# Changelog

## [1.0.0-dev18.3] - 2026-10-07

### Added
- `ApplePayConfig.buttonType`, `buttonStyle` and `buttonCornerRadius` (iOS). When `buttonType` is set, the plugin draws Apple's own `PKPaymentButton` (for example "Book with Apple Pay", black or white, pill-shaped) instead of the Checkout SDK's button, whose label, style and corners can't be configured, and starts the Apple Pay flow when it is tapped. Without `buttonType` nothing changes.

## [1.0.0-dev18.2] - 2026-10-06

### Fixed
- iOS Apple Pay button no longer draws above its platform-view frame when it sits over the home-indicator safe area, which showed as a strip across Flutter UI overlapping it (such as a toast). The hosting controller now ignores safe-area insets (iOS 16.4+) and the container clips to its bounds.

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
