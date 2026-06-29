// ignore_for_file: type=lint, invalid_use_of_internal_member, subtype_of_sealed_class, deprecated_member_use
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_allergen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchAllergenHash() => r'searchAllergen';

/// See also [searchAllergen].
@ProviderFor(searchAllergen)
const searchAllergenProvider = SearchAllergenFamily();

/// See also [searchAllergen].
class SearchAllergenFamily extends Family<AsyncValue<List<AllergenModel>>> {
  /// See also [searchAllergen].
  const SearchAllergenFamily();

  /// See also [searchAllergen].
  SearchAllergenProvider call(
    String query,
  ) {
    return SearchAllergenProvider(
      query,
    );
  }

  @override
  SearchAllergenProvider getProviderOverride(
    covariant SearchAllergenProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchAllergenProvider';
}

/// See also [searchAllergen].
class SearchAllergenProvider extends AutoDisposeFutureProvider<List<AllergenModel>> {
  /// See also [searchAllergen].
  SearchAllergenProvider(
    String query,
  ) : this._internal(
          (ref) => searchAllergen(
            ref as SearchAllergenRef,
            query,
          ),
          from: searchAllergenProvider,
          name: r'searchAllergenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchAllergenHash,
          dependencies: SearchAllergenFamily._dependencies,
          allTransitiveDependencies:
              SearchAllergenFamily._allTransitiveDependencies,
          query: query,
        );

  SearchAllergenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<AllergenModel>> Function(SearchAllergenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchAllergenProvider._internal(
        (ref) => create(ref as SearchAllergenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AllergenModel>> createElement() {
    return _SearchAllergenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchAllergenProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = _SystemHash.combine(hash, query.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin SearchAllergenRef on AutoDisposeFutureProviderRef<List<AllergenModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchAllergenProviderElement
    extends AutoDisposeFutureProviderElement<List<AllergenModel>>
    with SearchAllergenRef {
  _SearchAllergenProviderElement(super.provider);

  @override
  String get query => (provider as SearchAllergenProvider).query;
}

class _SystemHash {
  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
