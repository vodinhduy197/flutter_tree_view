import 'package:flutter/widgets.dart';

import 'tree_animations_mixin.dart';
import 'tree_delegate.dart';
import 'tree_node.dart';

/// A simple controller for managing the nodes that compose the tree provided by
/// [TreeDelegate].
mixin TreeControllerMixin<T, S extends StatefulWidget>
    on State<S>, TreeAnimationsMixin<S> {
  /// An interface to dynamically manage the state of the tree.
  ///
  /// Subclass [TreeDelegate] and implement the required methods to compose the
  /// tree and its state.
  ///
  /// Checkout [TreeDelegate.fromHandlers] for a simple implementation based on
  /// handler callbacks.
  TreeDelegate<T> get delegate;

  /// A helper method to get a [Key] for [item].
  ///
  /// Make sure the key provided for an item is always the same and unique
  /// among other keys, otherwise it could lead to inconsistent tree state.
  Key keyFactory(T item);

  /// All nodes that compose the current flattened tree.
  FlatTree<T> get nodes => _nodes;
  FlatTree<T> _nodes = FlatTree<T>(const []);

  /// The length of the current flattened tree.
  int get treeSize => nodes.length;

  /// Returns the current node at [index] of the flattened tree.
  TreeNode<T> nodeAt(int index) => nodes[index];

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void dispose() {
    _nodes = FlatTree<T>(const []);
    super.dispose();
  }

  /// The list of items that are currently being expanded (animating).
  final Map<Key, bool> _expandingItems = {};

  void _markIsExpanding(T item) {
    _expandingItems[keyFactory(item)] = true;
  }

  /// Check if [item] should animate in.
  @protected
  bool isItemExpanding(T item) => _expandingItems[keyFactory(item)] ?? false;

  void _build() {
    final List<TreeNode<T>> flatTree = buildFlatTree();
    _nodes = FlatTree<T>(flatTree);
  }

  /// Rebuilds the current tree.
  ///
  /// Call this method whenever the tree state changes in any way (i.e child
  /// added/removed, expansion changed, item reordered, etc...). Most methods
  /// like `expandItem` and `collapseItem` already call rebuild.
  ///
  /// This method will traverse the tree gattering the new information and
  /// storing it as a flat tree in [nodes].
  void rebuild() => setState(_build);

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already expanded.
  void expandItem(T item) {
    delegate.setExpansionState(item, true);

    // Find all descendants that are going to be revealed after this operation
    // We don't do [delegate.traverse] directly so [item] itself doesn't animate
    // along with its branch
    final List<T> children = delegate.findChildren(item);
    for (final T child in children) {
      delegate.traverse(
        item: child,
        shouldContinue: delegate.getExpansionState,
        onTraverse: _markIsExpanding,
      );
    }

    rebuild();
    startAnimating(() => _expandingItems.clear());
  }

  /// Updates the expansion state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already collapsed.
  void collapseItem(T item) {
    delegate.setExpansionState(item, false);
    rebuild();
  }

  /// Checks the expansion state of [item] and updates it to the opposite state.
  void toggleItemExpansion(T item) {
    delegate.getExpansionState(item) ? collapseItem(item) : expandItem(item);
  }

  /// Updates the expansion state of [item] and all its descendants to `true`.
  void expandItemCascading(T item) {
    delegate.setExpansionState(item, true);

    // We don't do [_visitBranch] directly so [item] itself doesn't animate
    // along with its branch
    final List<T> children = delegate.findChildren(item);
    for (final T child in children) {
      _visitBranch(child, (T it) {
        delegate.setExpansionState(it, true);
        _markIsExpanding(it);
      });
    }

    rebuild();
    startAnimating(() => _expandingItems.clear());
  }

  /// Updates the expansion state of [item] and all its descendants to `false`.
  void collapseItemCascading(T item) {
    _visitBranch(item, (T it) => delegate.setExpansionState(it, false));
    rebuild();
  }

  /// Updates the selection state of [item] and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already selected.
  void selectItem(T item) {
    setState(() {
      delegate.setSelectionState(item, true);
    });
  }

  /// Updates the selection state of [item].
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already not selected.
  void deselectItem(T item) {
    setState(() {
      delegate.setExpansionState(item, false);
    });
  }

  /// Checks the selection state of [item] and updates it to the opposite state.
  void toggleItemSelection(T item) {
    delegate.getSelectionState(item) ? deselectItem(item) : selectItem(item);
  }

  /// Updates the selection state of [item] and all its descendants to `true`.
  void selectItemCascading(T item) {
    setState(() {
      _visitBranch(item, (T it) => delegate.setSelectionState(it, true));
    });
  }

  /// Updates the selection state of [item] and all its descendants to `false`.
  void deselectItemCascading(T item) {
    setState(() {
      _visitBranch(item, (T it) => delegate.setSelectionState(it, false));
    });
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
          isExpanded: delegate.getExpansionState(item),
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
        late final List<T> children = delegate.findChildren(item);

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
      childItems: delegate.rootItems,
      level: 0,
      parent: null,
    );

    return tree;
  }

  void _visitBranch(T item, OnTraverse<T> action) {
    action(item);

    final List<T> children = delegate.findChildren(item);

    for (final T child in children) {
      _visitBranch(child, action);
    }
  }
}
