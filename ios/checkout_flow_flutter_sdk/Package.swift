// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "checkout_flow_flutter_sdk",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "checkout-flow-flutter-sdk",
            targets: ["checkout_flow_flutter_sdk"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/checkout/checkout-risk-sdk-ios", from: "4.0.2")
    ],
    targets: [
        .target(
            name: "CheckoutComponentsShim",
            dependencies: [
                .product(name: "Risk", package: "checkout-risk-sdk-ios"),
                .target(name: "CheckoutComponentsSDK"),
            ]
        ),
        .target(
            name: "checkout_flow_flutter_sdk",
            dependencies: [
                .target(name: "CheckoutComponentsShim"),
                .target(name: "CheckoutComponentsSDK"),
            ]
        ),
        .binaryTarget(
            name: "CheckoutComponentsSDK",
            url:
                "https://github.com/checkout/checkout-ios-components/releases/download/1.8.0/CheckoutComponentsSDK.xcframework.zip",
            checksum: "9b97ce5f673903e01a0a5566c696aaf415ea950ead60ab9598d749dd90225b94"
        ),
    ]
)
