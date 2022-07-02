/// The object that represents a node on a tree.
/// Used to store useful information about [item] in the current tree.
///
/// Instances of [TreeNode]s are created internally while flattening the tree.
///
/// The [TreeNode]s are short lived, each time the flat tree is rebuilt,
/// a new [TreeNode] is assigned for [item], so its data is never outdated.
class TreeNode<T> {
  /// Creates a [TreeNode].
  TreeNode({
    required this.id,
    required this.item,
    required this.index,
    required this.level,
    required this.isExpanded,
    required this.hasNextSibling,
    this.parent,
  }) : assert(level >= 0);

  /// An id bound to [item].
  ///
  /// Used as a key in maps to cache values for [item].
  final String id;

  /// The item attached to this node.
  final T item;

  /// The current index of this node in the flat tree.
  final int index;

  /// The level of this node on the tree.
  ///
  /// Example:
  /// ```dart
  /// /*
  ///   0
  ///   |- 1
  ///   |  '- 2
  ///   |     '- 3
  ///   0
  ///   '- 1
  /// */
  /// ```
  final int level;

  /// Whether this node is currently expanded.
  ///
  /// If `true`, the children of this node are currently visible on the tree.
  final bool isExpanded;

  /// Whether this node has another node after it at the same level.
  final bool hasNextSibling;

  /// The direct parent of this node on the tree.
  final TreeNode<T>? parent;

  /// Simple getter to check if `parent == null`.
  bool get isRoot => parent == null;

  /// Returns `true` if [ancestor] is present in the path from the root item to
  /// [item].
  ///
  /// This method can be used to forbid paradoxes when reordering.
  bool checkHasAncestor(T ancestor) {
    assert(ancestor != null);

    if (ancestor == item || parent == null) {
      return false;
    }

    bool foundAncestor = false;
    TreeNode<T>? current = parent;

    while (!(foundAncestor || current == null)) {
      foundAncestor = current.item == ancestor;
      current = current.parent;
    }

    return foundAncestor;
  }

  /// Used by [ConnectingLineGuide] to determine where to place the vertical
  /// lines based on the path from the root node to this node.
  ///
  /// Returns a list containing the levels of all nodes in the path from the
  /// root to this node that should draw a vertical line.
  Set<int> get levelsWithLineGuides {
    return _levelsWithLineGuidesCache ??= _findLevelsThatNeedLineGuides();
  }

  Set<int>? _levelsWithLineGuidesCache;

  Set<int> _findLevelsThatNeedLineGuides() {
    return <int>{
      ...?parent?.levelsWithLineGuides,
      if (hasNextSibling) level,
    };
  }

  @override
  String toString() {
    return 'TreeNode<$T>('
        'id: $id, '
        'item: $item, '
        'index: $index, '
        'level: $level, '
        'isExpanded: $isExpanded'
        'hasNextSibling: $hasNextSibling, '
        'parent: $parent'
        ')';
  }
}
