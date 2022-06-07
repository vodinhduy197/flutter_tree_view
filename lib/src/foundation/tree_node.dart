/// A simple model for storing useful information about the current state of
/// [item] in the tree.
///
/// Instances of [TreeNode]s are created internally by the [TreeController]
/// while flattening the tree.
///
/// The [TreeNode]s are short lived, each time the flat tree is rebuilt,
/// a new [TreeNode] is assigned for [item], so its data is never outdated.
class TreeNode<T> {
  /// Creates a [TreeNode].
  const TreeNode({
    required this.item,
    required this.isExpanded,
    required this.index,
    required this.level,
    required this.isLastSibling,
    this.parent,
  });

  /// The item attached to this node.
  final T item;

  /// The current index of this node among its siblings (parent's children).
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

  /// Whether this node is the last child of its parent.
  final bool isLastSibling;

  /// The direct parent of this node on the tree.
  final TreeNode<T>? parent;

  /// Whether this node is currently expanded.
  ///
  /// If `true`, the children of this node are currently visible on the tree.
  final bool isExpanded;

  /// Simple getter to check if `parent == null`.
  bool get isRoot => parent == null;

  /// Returns `true` if [node] is present in the path from the root node to
  /// this node.
  ///
  /// This method can be used to forbid paradoxes when reordering.
  bool checkHasAncestor(TreeNode<T> node) {
    return this == node || (parent?.checkHasAncestor(node) ?? false);
  }

  /// Returns all ancestor nodes from the root to `this`, inclusive.
  ///
  /// Exemple: `[root, ..., parent, this]`.
  List<TreeNode<T>> get path => [...?parent?.path, this];

  @override
  String toString() {
    return 'TreeNode<$T>('
        'item: $item, '
        'isExpanded: $isExpanded'
        'index: $index, '
        'level: $level, '
        'isLastSibling: $isLastSibling, '
        'parent: $parent'
        ')';
  }
}
