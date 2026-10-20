/// The two heights behind `CheckoutFlowCardView`: what the user sees, and the
/// native platform view underneath it.
///
/// Resizing a native view isn't smooth: on Android its texture is scaled to
/// the new size for a frame before Checkout redraws, so the fields look
/// stretched. The native view therefore keeps [headroom] of spare room below
/// the fields and is never resized as the form expands and collapses (a
/// validation message, Remember Me's email and phone). Only [visible] follows
/// the form, animated and clipped. The native view grows only when the form
/// outgrows that room, and then by the room again, so that is rare too.
class CardFormHeights {
  const CardFormHeights._({required this.visible, required this.native});

  /// Before the form reports its own height.
  factory CardFormHeights.initial(double height) =>
      CardFormHeights._(visible: height, native: height + headroom);

  /// Spare room below the starting height. Measured on Android (Components
  /// 2.9.0): the fields are 132, the form with Remember Me's checkbox 257,
  /// and 415 once it is ticked, so the room has to cover 283 from the start
  /// plus Remember Me's one-time-code step. A resize shows the whole form
  /// stretched for a frame on Android.
  static const double headroom = 400;

  /// The form's own height, shown through a clip.
  final double visible;

  /// The native platform view's height. It never shrinks.
  final double native;

  /// The form now measures [contentHeight].
  CardFormHeights withContentHeight(double contentHeight) => CardFormHeights._(
    visible: contentHeight,
    native: contentHeight > native ? contentHeight + headroom : native,
  );
}
