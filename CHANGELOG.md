# Changelog

## [1.0.0-dev19] - 2026-10-19

### Added
- Remember Me in the card component: `CardConfig.rememberMe` takes a `RememberMeConfig` (optional email and phone to prefill). Checkout's own Remember Me pay button stays hidden. Leaving it `null` hides Remember Me. It also has to be enabled on the Checkout account, and the payment session needs `customer.email`.
- The card form sizes itself: iOS and Android report the form's natural height when it changes (coalesced to one report per 50 ms, no polling), with the fields pinned to the top, and `CheckoutFlowCardView` resizes to it. `height` is now only the starting height. Reports carry the platform view id (`PaymentBridge.setCardHeightListener`), so two card views can't resize each other.
- `PaymentBridge.nativeCallbackTimeout` (30 s): `submit`, `tokenizeCard`, `tokenizeAndGetSessionData` and `tokenizeSavedCard` fail with a `TIMEOUT` `PlatformException` instead of waiting forever, and fail straight away with the native error code when native reports a `paymentError` while they wait.

### Changed
- Checkout Components 2.9.0 on iOS and Android (from 1.8.0 / 1.2.0), with the Remember Me fixes since then (`handleSubmit` with Remember Me cards, missing `onError` for invalid Remember Me fields, hiding Remember Me with `nil`, Android payments cancelled inside a bottom sheet).
- iOS: Checkout Risk SDK pinned to exactly 6.0.1, as Components 2.9.0 requires. Building needs Xcode 26.2 or later (the framework is built with Swift 6.2.3).
- Android: minimum SDK fallback 23 and compile SDK fallback 36, as Components 2.9.0 requires.
- iOS 1.8.0's checksum no longer matched Checkout's re-published zip, so a clean package resolve failed; the 2.9.0 checksum is current.
- **Breaking:** `SessionResult.token` is nullable. `submit()` returns the token from that submission only, and none for a Remember Me saved card, which has no client-side token. It no longer falls back to a token cached from an earlier card. `tokenizeCard` / `tokenizeAndGetSessionData` still need a typed card.
- `CheckoutFlowCardView` recreates the native view when `paymentConfig` or `cardConfig` changes, since native reads them only at creation (a new payment session, Remember Me prefill).
- Card views and Android Google Pay no longer send Checkout's `merchantHandleSubmitCallbackFailed` error to Flutter. `handleSubmit` returns a failure on purpose so the app's backend completes the payment, and every card payment logged it as an error.
- A native `paymentError` that ends a card call is reported to `onPaymentError` once, not twice.
- iOS card view: safe-area and keyboard insets no longer move the fields inside the platform view (iOS 16.4+), and the hosting view no longer fights Flutter's frame with required Auto Layout priorities.

### Fixed
- Android: since Checkout 2.3.0 a dismissed Google Pay sheet calls `onError` (`PAYMENT_CANCELLED`). It is now sent to Flutter as `onDismissed`, not as a `paymentError`.
- Android: a successful Google Pay payment no longer also sends `onDismissed`. The activity-result check compared Google Play's status code (0 = success) with `Activity.RESULT_CANCELED` (also 0).

### Removed
- `CardConfig.showRememberMe`. Both platforms ignored it and always passed no Remember Me configuration. Use `CardConfig.rememberMe`.

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
