enum NativePlatformViewType {
  flowCardView('flow_card_view'),
  flowGooglePayView('flow_googlepay_view'),
  flowApplePayView('flow_applepay_view');

  final String name;

  const NativePlatformViewType(this.name);
}
