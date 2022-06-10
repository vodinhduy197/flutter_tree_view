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

  // The list of nodes that are currently animating in.
  final Map<Key, bool> _expandingNodes = {};

  // The list of nodes that are currently animating out.
  final Map<Key, bool> _collapsingNodes = {};

  void _markIsExpanding(T item) {
    _expandingNodes[keyFactory(item)] = true;
  }

  void _markIsCollapsing(Key key) {
    _collapsingNodes[key] = true;
  }

  /// Returns and Animation<double> based on the current state of [node].
  ///
  /// If [node] is neither expanding nor collapsing, [kAlwaysCompleteAnimation]
  /// is returned.
  ///
  /// This method also removes [node] from its animating list.
  @protected
  Animation<double> findAnimation(TreeNode<T> node) {
    if (_expandingNodes.remove(node.key) ?? false) {
      return expandAnimation;
    }

    if (_collapsingNodes.remove(node.key) ?? false) {
      return collapseAnimation;
    }

    return kAlwaysCompleteAnimation;
  }

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
  /// This method will call [setState] traversing the tree to gatter the new
  /// information and store it as a flat tree in [nodes].
  void rebuild() => setState(_build);

  /// Updates the expansion state of [node.item] and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already expanded.
  void expand(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(node.item, _markIsExpanding);

    rebuild();
    startExpandAnimation();
  }

  /// Updates the expansion state of [node.item] and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already collapsed.
  void collapse(TreeNode<T> node) {
    delegate.setExpansionState(node.item, false);
    for (final TreeNode<T> descendant in node.descendants) {
      _markIsCollapsing(descendant.key);
    }

    // Make sure all nodes got their animations
    setState(() {});

    startCollapseAnimation(rebuild);
  }

  /// Checks the expansion state of [node.item] and updates it to the opposite
  /// state.
  void toggle(TreeNode<T> node) {
    delegate.getExpansionState(node.item) ? collapse(node) : expand(node);
  }

  /// Updates the expansion state of [node.item] and all its descendants to
  /// `true`.
  void expandCascading(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(
      node.item,
      (T item) {
        delegate.setExpansionState(item, true);
        _markIsExpanding(item);
      },
    );

    rebuild();
    startExpandAnimation();
  }

  /// Updates the expansion state of [node.item] and all its descendants to
  /// `false`.
  void collapseCascading(TreeNode<T> node) {
    delegate.setExpansionState(node.item, false);
    for (final TreeNode<T> descendant in node.descendants) {
      delegate.setExpansionState(descendant.item, false);
      _markIsCollapsing(descendant.key);
    }

    // Make sure all nodes got their animations
    setState(() {});

    startCollapseAnimation(rebuild);
  }

  /// Convenient method for traversing the tree.
  ///
  /// This method will build the flat tree in depth first order and return it
  /// as a plain dart list composed by [TreeNode] objects.
  ///
  /// [TreeNode]s hold important information about the context of its item in
  /// the current tree.
  ///
  /// The returned list is composed by all nodes whose parent is **expanded**,
  /// as of [TreeDelegate.getExpansionState].
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
          key: keyFactory(item),
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

  void _visitVisibleDescendants(T item, OnTraverse<T> action) {
    final List<T> children = delegate.findChildren(item);

    for (final T child in children) {
      delegate.traverse(
        item: child,
        shouldContinue: delegate.getExpansionState,
        onTraverse: action,
      );
    }
  }
}
