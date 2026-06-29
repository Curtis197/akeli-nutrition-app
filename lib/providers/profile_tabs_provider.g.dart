// ignore_for_file: type=lint, invalid_use_of_internal_member, subtype_of_sealed_class, deprecated_member_use
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_tabs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSavedRecipesHash() => r'userSavedRecipes';

/// See also [userSavedRecipes].
@ProviderFor(userSavedRecipes)
const userSavedRecipesProvider = UserSavedRecipesFamily();

/// See also [userSavedRecipes].
class UserSavedRecipesFamily extends Family<AsyncValue<List<Recipe>>> {
  /// See also [userSavedRecipes].
  const UserSavedRecipesFamily();

  /// See also [userSavedRecipes].
  UserSavedRecipesProvider call(
    String userId,
  ) {
    return UserSavedRecipesProvider(
      userId,
    );
  }

  @override
  UserSavedRecipesProvider getProviderOverride(
    covariant UserSavedRecipesProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'userSavedRecipesProvider';
}

/// See also [userSavedRecipes].
class UserSavedRecipesProvider extends AutoDisposeFutureProvider<List<Recipe>> {
  /// See also [userSavedRecipes].
  UserSavedRecipesProvider(
    String userId,
  ) : this._internal(
          (ref) => userSavedRecipes(
            ref as Ref,
            userId,
          ),
          from: userSavedRecipesProvider,
          name: r'userSavedRecipesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userSavedRecipesHash,
          dependencies: UserSavedRecipesFamily._dependencies,
          allTransitiveDependencies:
              UserSavedRecipesFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserSavedRecipesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<Recipe>> Function(UserSavedRecipesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserSavedRecipesProvider._internal(
        (ref) => create(ref as UserSavedRecipesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Recipe>> createElement() {
    return _UserSavedRecipesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSavedRecipesProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = _SystemHash.combine(hash, userId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin UserSavedRecipesRef on AutoDisposeFutureProviderRef<List<Recipe>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserSavedRecipesProviderElement
    extends AutoDisposeFutureProviderElement<List<Recipe>>
    with UserSavedRecipesRef {
  _UserSavedRecipesProviderElement(super.provider);

  @override
  String get userId => (provider as UserSavedRecipesProvider).userId;
}

String _$userCommentsHash() => r'userComments';

/// See also [userComments].
@ProviderFor(userComments)
const userCommentsProvider = UserCommentsFamily();

/// See also [userComments].
class UserCommentsFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [userComments].
  const UserCommentsFamily();

  /// See also [userComments].
  UserCommentsProvider call(
    String userId,
  ) {
    return UserCommentsProvider(
      userId,
    );
  }

  @override
  UserCommentsProvider getProviderOverride(
    covariant UserCommentsProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'userCommentsProvider';
}

/// See also [userComments].
class UserCommentsProvider extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [userComments].
  UserCommentsProvider(
    String userId,
  ) : this._internal(
          (ref) => userComments(
            ref as Ref,
            userId,
          ),
          from: userCommentsProvider,
          name: r'userCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userCommentsHash,
          dependencies: UserCommentsFamily._dependencies,
          allTransitiveDependencies:
              UserCommentsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(UserCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserCommentsProvider._internal(
        (ref) => create(ref as UserCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _UserCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCommentsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = _SystemHash.combine(hash, userId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin UserCommentsRef on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserCommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with UserCommentsRef {
  _UserCommentsProviderElement(super.provider);

  @override
  String get userId => (provider as UserCommentsProvider).userId;
}

String _$userGroupsHash() => r'userGroups';

/// See also [userGroups].
@ProviderFor(userGroups)
const userGroupsProvider = UserGroupsFamily();

/// See also [userGroups].
class UserGroupsFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [userGroups].
  const UserGroupsFamily();

  /// See also [userGroups].
  UserGroupsProvider call(
    String userId,
  ) {
    return UserGroupsProvider(
      userId,
    );
  }

  @override
  UserGroupsProvider getProviderOverride(
    covariant UserGroupsProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'userGroupsProvider';
}

/// See also [userGroups].
class UserGroupsProvider extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [userGroups].
  UserGroupsProvider(
    String userId,
  ) : this._internal(
          (ref) => userGroups(
            ref as Ref,
            userId,
          ),
          from: userGroupsProvider,
          name: r'userGroupsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userGroupsHash,
          dependencies: UserGroupsFamily._dependencies,
          allTransitiveDependencies:
              UserGroupsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserGroupsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(UserGroupsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserGroupsProvider._internal(
        (ref) => create(ref as UserGroupsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _UserGroupsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserGroupsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = _SystemHash.combine(hash, userId.hashCode);
    return _SystemHash.finish(hash);
  }
}

mixin UserGroupsRef on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserGroupsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with UserGroupsRef {
  _UserGroupsProviderElement(super.provider);

  @override
  String get userId => (provider as UserGroupsProvider).userId;
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
