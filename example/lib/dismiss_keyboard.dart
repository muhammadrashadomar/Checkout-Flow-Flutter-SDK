// ** Important: Used to dismiss keyboard in main
import 'package:flutter/material.dart';

class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Add this
      onTap: () {
        kDismissFocusedWidget(context);
      },
      child: child,
    );
  }
}

void kDismissFocusedWidget(BuildContext context) {
  if (context.mounted) {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
