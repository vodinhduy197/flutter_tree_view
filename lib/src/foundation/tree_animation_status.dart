/// Base of the `idle`, `revealing` and `concealing` union.
///
/// This union is used by [SliverTree] to deliver the correct reveal/conceal
/// animations to its nodes.
///
/// Used to bind an animation to a node on the tree.
abstract class TreeAnimationStatus {
  /// Enable subclasses to declare constant constructors.
  const TreeAnimationStatus();

  /// The status used for a node that is not animating.
  static const TreeAnimationStatus idle = _Idle();

  /// Status used when at least one ancestor of the node was expanded.
  static const TreeAnimationStatus revealing = _Revealing();

  /// Status used when at least one ancestor of the node was collapsed.
  static const TreeAnimationStatus concealing = _Concealing();

  /// Convenient method used to map each case of the union to a value.
  ///
  /// Example:
  /// ```dart
  /// final status = TreeNodeAnimationStatus.revealing;
  ///
  /// final String result = status.when<String>(
  ///   idle: () => 'Idle',
  ///   revealing: () => 'Revealing',
  ///   concealing: () => 'Concealing',
  /// );
  ///
  /// print(result); // Revealing
  ///```
  T when<T>({
    required T Function() idle,
    required T Function() revealing,
    required T Function() concealing,
  });
}

class _Idle extends TreeAnimationStatus {
  const _Idle();

  @override
  T when<T>({
    required T Function() idle,
    required T Function() revealing,
    required T Function() concealing,
  }) {
    return idle();
  }
}

class _Revealing extends TreeAnimationStatus {
  const _Revealing();

  @override
  T when<T>({
    required T Function() idle,
    required T Function() revealing,
    required T Function() concealing,
  }) {
    return revealing();
  }
}

class _Concealing extends TreeAnimationStatus {
  const _Concealing();

  @override
  T when<T>({
    required T Function() idle,
    required T Function() revealing,
    required T Function() concealing,
  }) {
    return concealing();
  }
}
