import 'package:flutter/foundation.dart' show ChangeNotifier, protected;

import 'tree_node.dart';

/// Callback definition used by [TreeController] to find the roots of the tree.
typedef RootsFinder<T> = List<T> Function();

/// Callback definition used by [TreeController] to find the children of [item].
typedef ChildrenFinder<T> = List<T> Function(T item);

/// Callback definition used by [TreeController] to find the expansion state of [item].
typedef ExpansionStateFinder<T> = bool Function(T item);

/// Callback definition used by [TreeController] to update the expansion state of [item].
typedef ExpansionStateUpdater<T> = void Function(T item, bool expanded);

/// A simple controller for managing the nodes that compose a tree.
class TreeController<T> with ChangeNotifier {
  /// Creates a [TreeController].
  ///
  /// If [buildImediatelly] is set to `false`, [TreeController.rebuild] must be
  /// called to build the tree for the first time, otherwise [TreeController.nodes]
  /// would be empty. This could be used to defer the first traversal of the
  /// tree to a more convenient moment.
  TreeController({
    required this.findRoots,
    required this.findChildren,
    required this.findExpansionState,
    required this.updateExpansionState,
    bool buildImediatelly = true,
  }) : _nodes = FlatTree<T>(const []) {
    if (buildImediatelly) {
      rebuild();
    }
  }

  /// Called, as needed when composing the tree, to get the root items.
  ///
  /// Avoid making expensive or time consuming operations in this callback, as
  /// it is called every time the tree is rebuilt.
  final RootsFinder<T> findRoots;

  /// Called, as needed when composing the tree, to get the children of [item].
  ///
  /// Avoid making expensive or time consuming operations in this callback, as
  /// it is called a lot during tree flattening.
  ///
  /// If the children of an item needs to be dynamically loaded, consider doing
  /// it when the user taps the expand action of a widget (e.g [TreeTile.onTap]
  /// or [FolderButton.onPressed]), fetching the children before calling
  /// [TreeController.expandItem].
  final ChildrenFinder<T> findChildren;

  /// Called, as needed, to get the current expansion state of [item].
  ///
  /// This method must return `true` if the children of [item] should be
  /// displayed on the tree and `false` otherwise.
  final ExpansionStateFinder<T> findExpansionState;

  /// Called, as needed, to update the expansion state of [item].
  ///
  /// The [expanded] parameter represents the item's new state.
  ///
  /// This method  will be used to update the expansion state of [item] before
  /// rebuilding the tree.
  final ExpansionStateUpdater<T> updateExpansionState;

  /// All nodes that compose the current flattened tree.
  FlatTree<T> get nodes => _nodes;
  FlatTree<T> _nodes;

  /// The length of the current flattened tree.
  int get treeSize => nodes.length;

  /// Returns the current node at [index] of the flattened tree.
  TreeNode<T> nodeAt(int index) => nodes[index];

  /// Rebuilds the current tree.
  ///
  /// Call this method whenever the tree state changes in any way (i.e child
  /// added/removed, expansion changed, item reordered, etc...). Most methods
  /// like `expandItem` and `collapseItem` already call rebuild.
  ///
  /// This method will traverse the tree gattering the new information and
  /// storing it as a flat tree in [nodes]. Then it calls [notifyListeners] so
  /// consumers can rebuild their view.
  void rebuild() {
    final List<TreeNode<T>> flatTree = buildFlatTree();
    _nodes = FlatTree<T>(flatTree);
    notifyListeners();
  }

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already expanded.
  void expandItem(T item) {
    updateExpansionState(item, true);
    rebuild();
  }

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already collapsed.
  void collapseItem(T item) {
    updateExpansionState(item, false);
    rebuild();
  }

  /// Checks the expansion state of [item] and updates it to the opposite state.
  void toggleItemExpansion(T item) {
    findExpansionState(item) ? collapseItem(item) : expandItem(item);
  }

  void _toggleItemsCascading(T item, bool expanded) {
    updateExpansionState(item, expanded);

    final List<T> children = findChildren(item);

    for (final T child in children) {
      _toggleItemsCascading(child, expanded);
    }
  }

  /// Updates the expansion state of [item] and all its descendants to `true`.
  void expandItemCascading(T item) {
    _toggleItemsCascading(item, true);
    rebuild();
  }

  /// Updates the expansion state of [item] and all its descendants to `false`.
  void collapseItemCascading(T item) {
    _toggleItemsCascading(item, false);
    rebuild();
  }

  /// Convenient function for traversing the tree.
  ///
  /// This function will build the flat tree in depth first order and return it
  /// as a plain dart list composed by [TreeNode] objects.
  ///
  /// [TreeNode]s hold important information about the context of its item in the
  /// current tree.
  ///
  /// The returned list is composed by all nodes whose parent is **expanded**,
  /// as of [findExpansionState].
  @protected
  List<TreeNode<T>> buildFlatTree() {
    final List<TreeNode<T>> tree = <TreeNode<T>>[];
    int globalIndex = 0;

    void generateFlatTree({
      required List<T> childItems,
      required int level,
      required MutableTreeNode<T>? parent,
    }) {
      final int lastIndex = childItems.length - 1;

      for (int index = 0; index <= lastIndex; index++) {
        final T item = childItems[index];

        final MutableTreeNode<T> node = MutableTreeNode<T>(
          item: item,
          isExpanded: findExpansionState(item),
          level: level,
          localIndex: index,
          globalIndex: globalIndex++,
          hasNextSibling: index < lastIndex,
          parent: parent,
        );

        tree.add(node);
        parent?.addChild(node);

        // using `late` initialization avoids the unnecessary calls to
        //`findChildren` since if the left side of the if statement falses out,
        // the right side is not evaluated at all.
        late final List<T> children = findChildren(item);

        if (node.isExpanded && children.isNotEmpty) {
          generateFlatTree(
            childItems: children,
            level: level + 1,
            parent: node,
          );
        }
      }
    }

    generateFlatTree(
      childItems: findRoots(),
      level: 0,
      parent: null,
    );

    return tree;
  }

  @override
  void dispose() {
    _nodes = FlatTree<T>(const []);
    super.dispose();
  }
}
