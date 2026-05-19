import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/auth/onboarding_data.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  group('OnboardingNotifier', () {
    test('initial language is fr', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider).language, 'fr');
    });

    test('updateLanguage mutates language', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier).updateLanguage('en');
      expect(c.read(onboardingProvider).language, 'en');
    });

    test('updateConsent sets both flags', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier)
          .updateConsent(privacy: true, cgu: true);
      final d = c.read(onboardingProvider);
      expect(d.consentPrivacy, isTrue);
      expect(d.consentCgu, isTrue);
    });

    test('updateProfile stores name and age', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier)
          .updateProfile(name: 'Sophie', age: 28);
      final d = c.read(onboardingProvider);
      expect(d.name, 'Sophie');
      expect(d.age, 28);
    });

    test('canAdvance returns false when consent not given on step 2', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider.notifier).canAdvance(1), isFalse);
    });

    test('canAdvance returns true on step 1 always', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider.notifier).canAdvance(0), isTrue);
    });
  });
}
