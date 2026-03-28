# iOS Integration Guide

## Requirements

- **Flutter**: 3.41.0+
- **Dart**: 3.11.0+
- **iOS**: 15.0+
- **Xcode**: 16.0+
- **Swift**: 6.0
- **Architecture**: arm64 only for simulator builds

## Setup

### 1. Enable Flutter Swift Package Manager support

Run this once on the machine that builds the app:

```bash
flutter config --enable-swift-package-manager
```

### 2. Resolve Flutter and Swift packages

From the host Flutter app root:

```bash
flutter pub get
flutter build ios --debug --no-codesign
```

The Checkout iOS SDK is resolved transitively through this plugin, so you do not need to add `checkout-ios-components` manually in Xcode.

If the host app previously used an older CocoaPods-based version of this plugin, clear the old iOS integration before rebuilding:

```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/ephemeral/Packages
flutter pub get
flutter build ios --debug --no-codesign
```

If you still see `framework 'checkout_flutter_bridge' not found`, the app is still loading stale CocoaPods-generated build settings. Deleting `ios/Pods` and rebuilding forces Xcode to use the Swift package integration instead.

### 3. Configure Apple Pay (if using)

#### A. Create Apple Merchant ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles > Identifiers**
3. Click **+** and select **Merchant IDs**
4. Register a new Merchant ID (e.g., `merchant.com.yourcompany.yourapp`)

#### B. Generate and Upload Apple Pay Certificate

1. Generate a certificate signing request from Checkout.com:

   **Sandbox:**
   ```bash
   curl --location --request POST 'https://api.sandbox.checkout.com/applepay/signing-requests' \
   --header 'Authorization: Bearer pk_sbox_xxx' \
   | jq -r '.content' > ~/Desktop/cko.csr
   ```

   **Production:**
   ```bash
   curl --location --request POST 'https://api.checkout.com/applepay/signing-requests' \
   --header 'Authorization: Bearer pk_xxx' \
   | jq -r '.content' > ~/Desktop/cko.csr
   ```

2. In Apple Developer Portal, go to your Merchant ID
3. Under **Apple Pay Payment Processing Certificate**, click **Create Certificate**
4. Upload the `cko.csr` file
5. Download the generated certificate (`apple_pay.cer`)

6. Upload the certificate to Checkout.com:

   **Sandbox:**
   ```bash
   curl --location --request POST 'https://api.sandbox.checkout.com/applepay/certificates' \
   --header 'Authorization: Bearer pk_sbox_xxx' \
   --header 'Content-Type: application/json' \
   --data-raw '{
     "content": "'"$(openssl x509 -inform der -in apple_pay.cer | base64)"'"
   }'
   ```

   **Production:**
   ```bash
   curl --location --request POST 'https://api.checkout.com/applepay/certificates' \
   --header 'Authorization: Bearer pk_xxx' \
   --header 'Content-Type: application/json' \
   --data-raw '{
     "content": "'"$(openssl x509 -inform der -in apple_pay.cer | base64)"'"
   }'
   ```

#### C. Add Entitlements

1. In Xcode, select your app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **Apple Pay**
4. Add your Merchant ID to the list

Alternatively, create/edit `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>merchant.com.yourcompany.yourapp</string>
    </array>
</dict>
</plist>
```

#### D. Update Info.plist

Add Apple Pay usage description to `ios/Runner/Info.plist`:

```xml
<key>NSApplePayUsageDescription</key>
<string>This app uses Apple Pay to process secure payments</string>
```

## Usage

### Card Payment

```dart
import 'package:checkout_flutter_bridge/checkout_flutter_bridge.dart';

// Initialize
final paymentBridge = PaymentBridge();
paymentBridge.initialize();

// Configure
final config = PaymentConfig(
  paymentSessionId: "ps_xxx",
  paymentSessionSecret: "pss_xxx",
  publicKey: "pk_sbox_xxx",
  environment: PaymentEnvironment.sandbox,
);

final cardConfig = CardConfig(
  showCardholderName: false,
);

// Display card input (iOS)
CardNativeView(
  paymentConfig: config,
  cardConfig: cardConfig,
)

// Tokenize
final token = await paymentBridge.tokenizeCard();
```

### Apple Pay

```dart
// Configure Apple Pay
final applePayConfig = ApplePayConfig(
  merchantIdentifier: 'merchant.com.yourcompany.yourapp',
  merchantName: 'Your Store',
  countryCode: 'US',
  currencyCode: 'USD',
);

// Initialize
await paymentBridge.initApplePay(config, applePayConfig);

// Check availability
final isAvailable = await paymentBridge.checkApplePayAvailability();

if (isAvailable) {
  // Display Apple Pay button
  ApplePayNativeView(
    paymentConfig: config,
    applePayConfig: applePayConfig,
  )
  
  // Tokenize
  final token = await paymentBridge.tokenizeApplePay();
}
```

## Testing

- **Card payments**: Can be tested in iOS Simulator
- **Apple Pay**: Requires a physical device with Apple Pay set up
- Use [Checkout.com test cards](https://www.checkout.com/docs/testing/test-cards)

## Troubleshooting

### SPM Cache Issues

If you encounter SPM caching issues, run:

```bash
cd ios
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
rm -rf .build
rm -f Package.resolved
xcodebuild -resolvePackageDependencies
```

### Apple Pay Not Available

- Ensure you're testing on a physical device
- Verify Apple Pay is set up in Wallet app
- Check that your Merchant ID is correctly configured
- Verify entitlements file includes your Merchant ID

### Build Errors

- Ensure Xcode 16+ is installed
- Verify iOS deployment target is set to 15.0+
- Check that Swift 6 is selected in build settings
- Use an arm64 simulator on Apple Silicon, or exclude `x86_64` for `iphonesimulator` in the host app if your build system still requests both simulator architectures
- If `framework 'checkout_flutter_bridge' not found` appears, remove stale CocoaPods artifacts from the host app and rebuild

## Notes

- The iOS implementation is packaged as a Flutter Swift package at `ios/checkout_flutter_bridge`
- Card input and Apple Pay are exposed through Flutter platform views
- The plugin registers itself automatically in host apps once Swift Package Manager support is enabled
- Callbacks are used for all async operations
