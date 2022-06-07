import 'dart:collection' show UnmodifiableListView;

/// Simple typedef for an unmodifiable list of [TreeNode<T>].
typedef FlatTree<T> = UnmodifiableListView<TreeNode<T>>;

/// A simple interface for storing useful information about the current state of
/// [item] in the tree.
///
/// Instances of [TreeNode]s are created internally by the [TreeController]
/// while flattening the tree.
///
/// The [TreeNode]s are short lived, each time the flat tree is rebuilt,
/// a new [TreeNode] is assigned for [item], so its data is never outdated.
abstract class TreeNode<T> {
  /// Defines the constructor configuration for subclasses to implement.
  const TreeNode({
    required this.item,
    required this.isExpanded,
    required this.localIndex,
    required this.globalIndex,
    required this.level,
    required this.hasNextSibling,
    this.parent,
  }) : assert(level >= 0);

  /// The direct children of this node in the current flat tree.
  FlatTree<T> get children;

  /// Used by [ConnectingLineGuide] to determine where to place the straight
  /// lines based on the path from the root node to this node.
  ///
  /// Returns a list containing all levels that **should** have a line drawn.
  List<int> get levelsWithLineGuides;

  /// The item attached to this node.
  final T item;

  /// The current index of this node among its siblings (parent's children).
  final int localIndex;

  /// The current index of this node in the flat tree.
  final int globalIndex;

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

  /// Whether this node has another node after it at the same level.
  final bool hasNextSibling;

  /// The direct parent of this node on the tree.
  final TreeNode<T>? parent;

  /// Whether this node is currently expanded.
  ///
  /// If `true`, the children of this node are currently visible on the tree.
  final bool isExpanded;

  /// Returns `true` if [TreeNode.children] is not empty, `false` otherwise.
  bool get hasChildren => children.isNotEmpty;

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
        'localIndex: $localIndex, '
        'globalIndex: $globalIndex, '
        'level: $level, '
        'hasNextSibling: $hasNextSibling, '
        'parent: $parent'
        ')';
  }
}

/// An implementation of [TreeNode] that allows the [TreeController] to set some
/// protected properties.
///
/// Instances of [TreeNode]s are created internally by the [TreeController]
/// while flattening the tree.
///
/// The only purpose of this class is to be used by [TreeController] to cache
/// some values and setup the flat tree when rebuilding.
class MutableTreeNode<T> extends TreeNode<T> {
  /// Creates a [MutableTreeNode].
  MutableTreeNode({
    required super.item,
    required super.isExpanded,
    required super.localIndex,
    required super.globalIndex,
    required super.level,
    required super.hasNextSibling,
    super.parent,
  }) : _children = <TreeNode<T>>[];

  @override
  FlatTree<T> get children => FlatTree<T>(_children);
  final List<TreeNode<T>> _children;

  /// Used by [TreeController] to inject the children of this node.
  void addChild(TreeNode<T> child) {
    assert(child.parent == this);
    assert(child.localIndex == _children.length);
    _children.add(child);
  }

  @override
  List<int> get levelsWithLineGuides {
    return _levelsWithLineGuidesCache ??= _findLevelsThatNeedLineGuides();
  }

  List<int>? _levelsWithLineGuidesCache;

  List<int> _findLevelsThatNeedLineGuides() {
    return [
      ...?parent?.levelsWithLineGuides,
      if (hasNextSibling) level,
    ];
  }
}
