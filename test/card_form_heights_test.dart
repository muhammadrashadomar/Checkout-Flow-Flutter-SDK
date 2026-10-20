/// Pins how the card form's native view is sized: it keeps spare room below
/// the fields and never shrinks, so expanding and collapsing the form only
/// moves the clipped window over it (a resize shows stretched fields on
/// Android). It grows only when the form outgrows that room.
library;

import 'package:checkout_flow_flutter_sdk/src/widgets/card_form_heights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const headroom = CardFormHeights.headroom;

  test('starts with spare room below the starting height', () {
    final heights = CardFormHeights.initial(132);

    expect(heights.visible, 132);
    expect(heights.native, 132 + headroom);
  });

  test('expanding within the room moves only the visible height', () {
    final expanded = CardFormHeights.initial(132).withContentHeight(250);

    expect(expanded.visible, 250);
    expect(expanded.native, 132 + headroom);
  });

  test('collapsing never shrinks the native view', () {
    final collapsed = CardFormHeights.initial(
      132,
    ).withContentHeight(250).withContentHeight(132);

    expect(collapsed.visible, 132);
    expect(collapsed.native, 132 + headroom);
  });

  test('outgrowing the room grows the native view once, with room again', () {
    final heights = CardFormHeights.initial(132);
    final tall = heights.withContentHeight(heights.native + 10);

    expect(tall.visible, heights.native + 10);
    expect(tall.native, heights.native + 10 + headroom);
  });
}
