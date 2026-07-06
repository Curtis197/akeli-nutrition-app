import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;
import '../../core/logger.dart';

/// Renders Google's own GSI button widget, which is the only supported way
/// to trigger Google Sign-In on Flutter Web (see
/// `docs/superpowers/specs/2026-07-06-google-signin-web-support-design.md`).
/// The actual sign-in result arrives asynchronously via
/// `GoogleSignIn.instance.authenticationEvents`, handled in `AuthNotifier`.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isLoading, super.key});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    appLogger.provider('GoogleWebSignInButton build() | isLoading: $isLoading');
    return IgnorePointer(
      ignoring: isLoading,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: web_only.renderButton(
            configuration: web_only.GSIButtonConfiguration(
              theme: web_only.GSIButtonTheme.outline,
              size: web_only.GSIButtonSize.large,
              shape: web_only.GSIButtonShape.pill,
              text: web_only.GSIButtonText.continueWith,
              logoAlignment: web_only.GSIButtonLogoAlignment.center,
              minimumWidth: 320,
            ),
          ),
        ),
      ),
    );
  }
}
