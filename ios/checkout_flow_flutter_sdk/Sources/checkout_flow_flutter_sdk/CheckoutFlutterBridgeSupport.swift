import CheckoutComponentsSDK
import SwiftUI
import UIKit

typealias CheckoutSDK = CheckoutComponentsSDK.CheckoutComponents
typealias CheckoutActionable = CheckoutSDK.Actionable
typealias CheckoutPaymentSession = CheckoutComponentsSDK.PaymentSession
typealias CheckoutCardMetadata = CheckoutComponentsSDK.CardMetadata

enum CheckoutFlutterBridgeConstants {
    static let channelName = "checkout_bridge"
    static let cardViewType = "flow_card_view"
    static let applePayViewType = "flow_applepay_view"
}

func checkoutEnvironment(from rawValue: String?) -> CheckoutSDK.Environment {
    rawValue?.lowercased() == "production" ? .production : .sandbox
}

func checkoutDesignTokens(from params: [String: Any]) -> CheckoutSDK.DesignTokens {
    let appearance = params["appearance"] as? [String: Any]
    let colorTokens = appearance?["colorTokens"] as? [String: Any] ?? [:]
    let borderRadius = CGFloat((appearance?["borderRadius"] as? NSNumber)?.doubleValue ?? 8)

    return CheckoutSDK.DesignTokens(
        colorTokensMain: CheckoutSDK.ColorTokens(
            action: checkoutColor(from: colorTokens["colorAction"], fallback: .brightBlue),
            background: checkoutColor(from: colorTokens["colorBackground"], fallback: .white),
            border: checkoutColor(from: colorTokens["colorBorder"], fallback: .softGray),
            formBackground: checkoutColor(from: colorTokens["colorBackground"], fallback: .white),
            formBorder: checkoutColor(
                from: colorTokens["colorFormBorder"] ?? colorTokens["colorBorder"],
                fallback: .mediumGray
            ),
            primary: checkoutColor(from: colorTokens["colorPrimary"], fallback: .black)
        ),
        borderButtonRadius: .init(radius: borderRadius),
        borderFormRadius: .init(radius: borderRadius)
    )
}

func checkoutCardConfiguration(from params: [String: Any]) -> CheckoutSDK.CardConfigurations {
    let cardConfig = params["cardConfig"] as? [String: Any]
    let displayCardholderName: CheckoutSDK.DisplayCardHolderName =
        (cardConfig?["showCardholderName"] as? Bool ?? false) ? .top : .hidden

    return CheckoutSDK.CardConfigurations(
        displayCardHolderName: displayCardholderName
    )
}

func checkoutTokenDetailsMap(_ tokenDetails: CheckoutSDK.TokenDetails) -> [String: Any] {
    var map: [String: Any] = [
        "type": tokenDetails.type.rawValue,
        "token": tokenDetails.token,
        "expiresOn": tokenDetails.expiresOn,
        "expiryMonth": tokenDetails.expiryMonth,
        "expiryYear": tokenDetails.expiryYear,
        "last4": tokenDetails.last4,
        "bin": tokenDetails.bin,
    ]

    map["scheme"] = tokenDetails.scheme
    map["schemeLocal"] = tokenDetails.schemeLocal
    map["cardType"] = tokenDetails.cardType
    map["cardCategory"] = tokenDetails.cardCategory
    map["issuer"] = tokenDetails.issuer
    map["issuerCountry"] = tokenDetails.issuerCountry
    map["productId"] = tokenDetails.productId
    map["productType"] = tokenDetails.productType
    map["name"] = tokenDetails.name

    if let billingAddress = tokenDetails.billingAddress {
        map["billingAddress"] = checkoutAddressMap(billingAddress)
    }

    if let phone = tokenDetails.phone {
        map["phone"] = checkoutPhoneMap(phone)
    }

    return map
}

func checkoutCardMetadataMap(_ metadata: CheckoutCardMetadata) -> [String: Any] {
    var map: [String: Any] = [
        "bin": metadata.bin,
        "scheme": metadata.scheme,
    ]

    map["localSchemes"] = metadata.localSchemes
    map["cardType"] = metadata.cardType
    map["cardCategory"] = metadata.cardCategory
    map["currency"] = metadata.currency
    map["issuer"] = metadata.issuer
    map["issuerCountry"] = metadata.issuerCountry
    map["issuerCountryName"] = metadata.issuerCountryName
    map["productId"] = metadata.productId
    map["productType"] = metadata.productType
    map["subProductId"] = metadata.subProductId
    map["regulatedIndicator"] = metadata.regulatedIndicator
    map["regulatedType"] = metadata.regulatedType

    return map
}

func checkoutErrorPayload(
    code: String,
    message: String,
    details: [String: Any]? = nil
) -> [String: Any] {
    var payload: [String: Any] = [
        "errorCode": code,
        "errorMessage": message,
    ]

    details?.forEach { key, value in
        payload[key] = value
    }

    return payload
}

func checkoutErrorPayload(from error: CheckoutSDK.Error, code: String = "CHECKOUT_ERROR")
    -> [String: Any]
{
    var details: [String: Any] = [
        "sdkErrorCode": error.errorCode.description,
        "sdkErrorType": error.type.rawValue,
        "componentType": error.details.type.rawValue,
        "mobileSessionId": error.details.mobileSessionID,
    ]

    if let paymentSessionId = error.details.paymentSessionID {
        details["paymentSessionId"] = paymentSessionId
    }

    if let paymentId = error.details.paymentID {
        details["paymentId"] = paymentId
    }

    return checkoutErrorPayload(
        code: code,
        message: error.localizedDescription,
        details: details
    )
}

private func checkoutPhoneMap(_ phone: CheckoutSDK.Phone) -> [String: Any] {
    [
        "countryCode": phone.countryCode,
        "number": phone.number,
    ]
}

private func checkoutAddressMap(_ address: CheckoutSDK.Address) -> [String: Any] {
    var map: [String: Any] = [
        "country": address.country.rawValue
    ]

    map["addressLine1"] = address.addressLine1
    map["addressLine2"] = address.addressLine2
    map["city"] = address.city
    map["state"] = address.state
    map["zip"] = address.zip

    return map
}

private func checkoutColor(from rawValue: Any?, fallback: Color) -> Color {
    guard let argbValue = checkoutARGBValue(from: rawValue) else {
        return fallback
    }

    return Color(uiColor: UIColor(argb: argbValue))
}

private func checkoutARGBValue(from rawValue: Any?) -> UInt32? {
    switch rawValue {
    case let value as NSNumber:
        return UInt32(truncatingIfNeeded: value.uint64Value)
    case let value as Int:
        return UInt32(truncatingIfNeeded: value)
    case let value as Int64:
        return UInt32(truncatingIfNeeded: value)
    case let value as UInt64:
        return UInt32(truncatingIfNeeded: value)
    default:
        return nil
    }
}

extension UIColor {
    fileprivate convenience init(argb: UInt32) {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255
        let red = CGFloat((argb >> 16) & 0xFF) / 255
        let green = CGFloat((argb >> 8) & 0xFF) / 255
        let blue = CGFloat(argb & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
