/// An interface for accessing tree data.
///
/// The data source will be used to build the tree hierarchy on demand.
///
/// The methods of this class are going to be called very frequently, consider
/// caching the results.
abstract class TreeDataSource<T> {
  /// Enable subclasses to define constant constructors.
  const TreeDataSource();

  /// Creates a simple [TreeDataSource] from callbacks.
  const factory TreeDataSource.simple({
    required ChildrenFinder<T> findChildren,
    required ExpansionStateFinder<T> findExpansionState,
    required ExpansionStateUpdater<T> updateExpansionState,
  }) = SimpleTreeDataSource<T>;

  /// Called, as needed when composing the tree, to get the children of [item].
  ///
  /// If [item] is `null`, the tree is requesting for the **root** items.
  List<T> findChildren(T? item);

  /// Called, as needed, to get the current expansion state of [item].
  ///
  /// This method must return `true` if the children of [item] should be
  /// displayed on the tree and `false` otherwise.
  bool findExpansionState(T item);

  /// Called, as needed, to update the expansion state of [item].
  ///
  /// The [expanded] parameter represents the item's new state.
  ///
  /// The [TreeController] will use this method to update the expansion state of
  /// [item] before rebuilding the tree.
  void updateExpansionState(T item, bool expanded);

  /// Calls [findChildren] and checks if the returned list is **not** empty.
  bool checkHasChildren(T item) => findChildren(item).isNotEmpty;
}

/// Callback used to find the children of [item].
typedef ChildrenFinder<T> = List<T> Function(T? item);

/// Callback used to find the expansion state of [item];
typedef ExpansionStateFinder<T> = bool Function(T item);

/// Callback used to update the expansion state of [item];
typedef ExpansionStateUpdater<T> = void Function(T item, bool expanded);

/// A helper class for accessing tree data through callbacks.
///
/// The data source will be used to build the tree hierarchy on demand.
///
/// The methods of this class are going to be called very frequently, consider
/// caching the results.
class SimpleTreeDataSource<T> extends TreeDataSource<T> {
  /// Creates a simple [TreeDataSource] from callbacks.
  ///
  /// - [findChildren]: a callback that should return the children of [item] or
  ///   the **root** items if [item] is `null`;
  /// - [findExpansionState]: a callback that should return the expansion state
  ///   of [item];
  /// - [updateExpansionState]: a callback that should update the expansion
  ///   state of [item];
  const SimpleTreeDataSource({
    required ChildrenFinder<T> findChildren,
    required ExpansionStateFinder<T> findExpansionState,
    required ExpansionStateUpdater<T> updateExpansionState,
  })  : _findChildren = findChildren,
        _findExpansionState = findExpansionState,
        _updateExpansionState = updateExpansionState;

  final ChildrenFinder<T> _findChildren;
  final ExpansionStateFinder<T> _findExpansionState;
  final ExpansionStateUpdater<T> _updateExpansionState;

  @override
  List<T> findChildren(T? item) => _findChildren(item);

  @override
  bool findExpansionState(T item) => _findExpansionState(item);

  @override
  void updateExpansionState(T item, bool expanded) {
    _updateExpansionState(item, expanded);
  }
}

/// A simple model for storing useful information about the current state of
/// [item] in the tree.
///
/// Instances of [TreeNode]s are created internally by the [TreeController]
/// while flattening the tree. _Users should provide tree data through the
/// [TreeDataSource] interface._
///
/// The [TreeNode]s are short lived, each time the flat tree is rebuilt,
/// a new [TreeNode] is assigned for [item], so its data is never outdated.
///
/// The expansion state of [item] is not stored in [TreeNode], it must be gotten
/// from [TreeDataSource.findExpansionState] in favor of optimizing rebuilds,
/// since a node could be expanded/collapsed but have no children, so, there's
/// no need for traversing the tree again, a simple `setState` is enough.
class TreeNode<T> {
  /// Creates an instance of [TreeNode].
  const TreeNode({
    required this.item,
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
}

/// Convenient function for traversing the tree provided by [dataSource].
///
/// This function will build the tree in depth first order and return it as a
/// plain dart list composed by [TreeNode] objects.
///
/// [TreeNode]s hold important information about the context of its item in the
/// current tree.
///
/// The returned list is composed by all nodes whose parent is **expanded**,
/// as of [dataSource.findExpansionState].
///
/// This function is a top-level function, making it possible to defer the
/// tree traversal to another [Isolate]. Though aditional work would be needed
/// to accomplish that (i.e. subclass [TreeController] and wrap the [Treeview]
/// in a [FutureBuilder]).
List<TreeNode<T>> buildFlatTree<T>(TreeDataSource<T> dataSource) {
  final List<TreeNode<T>> tree = <TreeNode<T>>[];

  void generateFlatTree({
    required List<T> items,
    required int level,
    TreeNode<T>? parent,
  }) {
    final int lastIndex = items.length - 1;

    for (int index = 0; index <= lastIndex; index++) {
      final T item = items[index];

      final TreeNode<T> node = TreeNode<T>(
        item: item,
        level: level,
        index: index,
        isLastSibling: index == lastIndex,
        parent: parent,
      );

      tree.add(node);

      // using `late` initialization avoids the unnecessary call to `findChildren`
      // since if the left side of the if statement falses out, the right side
      // is not evaluated at all (as of dart 2.16).
      late final List<T> children = dataSource.findChildren(item);

      if (dataSource.findExpansionState(item) && children.isNotEmpty) {
        generateFlatTree(
          items: children,
          level: level + 1,
          parent: node,
        );
      }
    }
  }

  final List<T> rootItems = dataSource.findChildren(null);

  generateFlatTree(
    items: rootItems,
    level: 0,
    parent: null,
  );

  return tree;
}
