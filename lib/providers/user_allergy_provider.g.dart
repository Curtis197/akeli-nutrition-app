// ignore_for_file: type=lint, invalid_use_of_internal_member, subtype_of_sealed_class, deprecated_member_use
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_allergy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userAllergyHash() => r'userAllergy';

abstract class _$UserAllergy
    extends AutoDisposeAsyncNotifier<List<AllergenModel>> {
  @override
  FutureOr<List<AllergenModel>> build();
}

/// See also [UserAllergy].
@ProviderFor(UserAllergy)
final userAllergyProvider =
    AutoDisposeAsyncNotifierProvider<UserAllergy, List<AllergenModel>>.internal(
  UserAllergy.new,
  name: r'userAllergyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userAllergyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
