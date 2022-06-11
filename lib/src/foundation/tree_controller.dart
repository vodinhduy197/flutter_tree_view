import 'package:flutter/widgets.dart';

import 'tree_animations_state_mixin.dart';
import 'tree_delegate.dart';
import 'tree_node.dart';

/// An interface that declares methods to dynamically update a tree.
abstract class AbstractTreeController<T> {
  /// Subclasses should override this method to rebuild the tree.
  void rebuild();

  /// Subclasses should override this method to update the expansion state of
  /// [node.item] to `true`.
  void expand(TreeNode<T> node);

  /// Subclasses should override this method to update the expansion state of
  /// [node.item] to `false`.
  void collapse(TreeNode<T> node);

  /// Subclasses should override this method to toggle the expansion state of
  /// [node.item] to the opposite state.
  void toggle(TreeNode<T> node);

  /// Subclasses should override this method to update the expansion state of
  /// [node.item] and all its descendants to `true`.
  void expandCascading(TreeNode<T> node);

  /// Subclasses should override this method to update the expansion state of
  /// [node.item] and all its descendants to `false`.
  void collapseCascading(TreeNode<T> node);

  /// Subclasses should override this method to update the expansion state of
  /// all nodes to `true`.
  void expandAll();

  /// Subclasses should override this method to update the expansion state of
  /// all nodes to `false`.
  void collapseAll();
}

/// A state mixin used by [SliverTree] to manage the tree provided by a [TreeDelegate].
mixin TreeControllerStateMixin<T, S extends StatefulWidget>
    on State<S>, TreeAnimationsStateMixin<S>
    implements AbstractTreeController<T> {
  /// An interface that dynamically manages the state of the tree.
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
  TreeNode<T> nodeAt(int index) {
    assert(0 <= index && index < treeSize, 'Index out of range.');
    final TreeNode<T> node = nodes[index];
    assert(node.globalIndex == index, 'The tree was malformed.');
    return node;
  }

  void _build() {
    final List<TreeNode<T>> flatTree = buildFlatTree();
    _nodes = FlatTree<T>(flatTree);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.rebuild}
  /// Rebuilds the current tree.
  ///
  /// This method will call [setState] traversing the tree to gatter the new
  /// information and store it as a flat tree in [nodes].
  ///
  /// Call this method whenever the tree items are updated (i.e child added/removed,
  /// item reordered, etc...). Most methods like `expandItem` and `collapseItem`
  /// already call rebuild. If updating the expansion state of an item from
  /// outside of the controller, this must be called to update the tree.
  ///
  /// Example:
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  ///   final List<Item> children = [];
  /// }
  ///
  /// // DON'T use rebuild when calling an expansion method of a [TreeController]:
  /// void expandNode(TreeNode<Item> node) {
  ///   treeController.expand(node);
  ///   treeController.rebuild(); // No need to call rebuild here.
  /// }
  ///
  /// // DO use rebuild when the expansion state changes from outside of a [TreeController]:
  /// void expandItem(Item item) {
  ///   item.isExpanded = !item.isExpanded;
  ///   treeController.rebuild();
  /// }
  ///
  /// // DO use rebuild when nodes are added/removed/reordered:
  /// void addChild(Item parent, Item child) {
  ///   parent.children.add(child)
  ///   treeController.rebuild();
  /// }
  ///
  /// /// Consider doing bulk updating before calling rebuild:
  /// void addChildren(Item parent, List<Item> children) {
  ///   for (final Item child in children) {
  ///     parent.children.add(child);
  ///     // DON'T rebuild after each child insertion
  ///     // treeController.rebuild();
  ///   }
  ///   // DO rebuild after all items are processed
  ///   treeController.rebuild();
  /// }
  /// ```
  /// {@endtemplate}
  @override
  void rebuild() => setState(_build);

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

  final Map<Key, bool> _expandingNodes = <Key, bool>{};
  bool _checkIsExpanding(Key key) => _expandingNodes.remove(key) ?? false;
  void _markIsExpanding(Key key) {
    _expandingNodes[key] = true;
  }

  final Map<Key, bool> _collapsingNodes = <Key, bool>{};
  bool _checkIsCollapsing(Key key) => _collapsingNodes.remove(key) ?? false;
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
    if (_checkIsExpanding(node.key)) {
      return expandAnimation;
    }

    if (_checkIsCollapsing(node.key)) {
      return collapseAnimation;
    }

    return kAlwaysCompleteAnimation;
  }

  /// {@template flutter_fancy_tree_view.tree_controller.expand}
  /// Updates [node.item] expansion state to `true` and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already expanded.
  /// {@endtemplate}
  @override
  void expand(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(
      node.item,
      (T item) => _markIsExpanding(keyFactory(item)),
    );

    rebuild();
    startExpandAnimation();
  }

  /// {@template flutter_fancy_tree_view.tree_controller.collapse}
  /// Updates [node.item] expansion state to `false` and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already collapsed.
  /// {@endtemplate}
  @override
  void collapse(TreeNode<T> node) {
    delegate.setExpansionState(node.item, false);
    for (final TreeNode<T> descendant in node.descendants) {
      _markIsCollapsing(descendant.key);
    }

    // Make sure all nodes got their animations
    setState(() {});

    startCollapseAnimation(rebuild);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.toggle}
  /// Updates [node.item] expansion state to the opposite state.
  /// {@endtemplate}
  @override
  void toggle(TreeNode<T> node) {
    delegate.getExpansionState(node.item) ? collapse(node) : expand(node);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.expandCascading}
  /// Traverses [node]'s branch updating all descendants expansion state to
  /// `true` and rebuilds the tree.
  /// {@endtemplate}
  @override
  void expandCascading(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(
      node.item,
      (T item) {
        delegate.setExpansionState(item, true);
        _markIsExpanding(keyFactory(item));
      },
    );

    rebuild();
    startExpandAnimation();
  }

  /// {@template flutter_fancy_tree_view.tree_controller.collapseCascading}
  /// Traverses [node]'s branch updating all descendants expansion state to
  /// `false` and rebuilds the tree.
  /// {@endtemplate}
  @override
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

  /// {@template flutter_fancy_tree_view.tree_controller.expandAll}
  /// Traverses the entire tree provided by [TreeDelegate] updating the
  /// expansion state of all items to `true`.
  /// {@endtemplate}
  @override
  void expandAll() {
    setState(() {
      _nodes = FlatTree<T>(_buildExpandedFlatTree());
      startExpandAnimation();
    });
  }

  /// {@template flutter_fancy_tree_view.tree_controller.collapseAll}
  /// TL;DR - Updates the expansion state of **all** items to `false`.
  ///
  /// This method is composed by three important steps:
  ///
  /// 1) it starts by gattering a list of all non-root previously visible nodes
  /// so that later they can be marked as collapsing to animate out;
  ///
  /// 2) then traverses the entire tree provided by [TreeDelegate] updating the
  /// expansion state of all items to `false`;
  ///   - meanwhile it also marks the visible nodes that must animate out;
  ///   - and also creates new root [TreeNode] instances for the next tree.
  ///
  /// 3) at last it assembles a new tree composed by the root nodes only.
  ///   - it starts animating out the collapsed node's children;
  ///   - then it updates [nodes] with the new tree composed by only root nodes.
  /// {@endtemplate}
  @override
  void collapseAll() {
    final List<T> previouslyVisibleItems = [
      for (final TreeNode<T> node in _nodes)
        if (!node.isRoot) node.item,
    ];

    final List<TreeNode<T>> tree = <TreeNode<T>>[];

    final List<T> rootItems = delegate.rootItems;
    final int lastIndex = rootItems.length - 1;

    for (int index = 0; index <= lastIndex; index++) {
      final T rootItem = rootItems[index];

      delegate.traverse(
        item: rootItem,
        shouldContinue: (_) => true,
        onTraverse: (T item) {
          if (delegate.getExpansionState(item)) {
            delegate.setExpansionState(item, false);
          }
          if (previouslyVisibleItems.remove(item)) {
            _markIsCollapsing(keyFactory(item));
          }
        },
      );

      final TreeNode<T> node = MutableTreeNode<T>(
        key: keyFactory(rootItem),
        item: rootItem,
        isExpanded: false,
        level: 0,
        localIndex: index,
        globalIndex: index,
        hasNextSibling: index < lastIndex,
        parent: null,
      );

      tree.add(node);
    }

    // Make sure all nodes got their animations
    setState(() {});

    startCollapseAnimation(() => setState(() => _nodes = FlatTree<T>(tree)));
  }

  @protected
  List<TreeNode<T>> _buildExpandedFlatTree() {
    final List<TreeNode<T>> tree = <TreeNode<T>>[];
    int globalIndex = 0;

    void generateFlatTree({
      required List<T> items,
      required int level,
      required MutableTreeNode<T>? parent,
      required bool itemsShouldAnimate,
    }) {
      final int lastIndex = items.length - 1;

      for (int index = 0; index <= lastIndex; index++) {
        final T item = items[index];
        final Key itemKey = keyFactory(item);

        if (itemsShouldAnimate) {
          _markIsExpanding(itemKey);
        }

        final bool isCollapsed = !delegate.getExpansionState(item);

        if (isCollapsed) {
          delegate.setExpansionState(item, true);

          // This item was collapsed so descendants must animate in
          itemsShouldAnimate = true;
        }

        final MutableTreeNode<T> node = MutableTreeNode<T>(
          key: itemKey,
          item: item,
          isExpanded: true,
          level: level,
          localIndex: index,
          globalIndex: globalIndex++,
          hasNextSibling: index < lastIndex,
          parent: parent,
        );

        tree.add(node);
        parent?.addChild(node);

        final List<T> children = delegate.findChildren(item);

        if (children.isNotEmpty) {
          generateFlatTree(
            items: children,
            level: level + 1,
            parent: node,
            itemsShouldAnimate: itemsShouldAnimate,
          );
        }
      }
    }

    generateFlatTree(
      items: delegate.rootItems,
      level: 0,
      parent: null,
      itemsShouldAnimate: false,
    );

    return tree;
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
