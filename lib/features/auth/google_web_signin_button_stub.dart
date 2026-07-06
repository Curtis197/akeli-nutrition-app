import 'package:flutter/widgets.dart';
import '../../core/logger.dart';

/// Non-web stub. `auth_page.dart` only ever instantiates the real
/// [GoogleWebSignInButton] (from `google_web_signin_button_web.dart`) when
/// `kIsWeb` is true, so this branch is never actually built — it exists so
/// mobile builds don't pull in `dart:ui_web` / `package:web`, which the web
/// implementation depends on.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isLoading, super.key});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    appLogger.provider('GoogleWebSignInButton (stub) build() | isLoading: $isLoading');
    return const SizedBox.shrink();
  }
}
