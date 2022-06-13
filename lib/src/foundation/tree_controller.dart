import 'package:flutter/widgets.dart';

import 'tree_animations_state_mixin.dart';
import 'tree_delegate.dart';
import 'tree_node.dart';

/// Default key factory used to get a [Key] for an [item].
///
/// This function creates a [ValueKey<T>] for [item].
///
/// When using this function, make sure [item]'s [operator ==] is consistent.
Key defaultKeyFactory<T>(T item) => ValueKey<T>(item);

/// A simple controller that when attached to a [SliverTree], delegates its
/// method calls to the underlying [TreeControllerStateMixin].
///
/// When not attached, the methods of this controller do nothing.
class TreeController<T> {
  TreeControllerStateMixin<T, StatefulWidget>? _state;

  /// Used by [SliverTree] to attach its [TreeControllerStateMixin] to this
  /// controller.
  void attach(TreeControllerStateMixin<T, StatefulWidget> state) {
    assert(_state == null, 'TreeController already attached.');
    _state = state;
  }

  /// Detaches this [TreeController] from its [TreeControllerStateMixin].
  void detach(TreeControllerStateMixin<T, StatefulWidget> state) {
    if (state == _state) {
      _state = null;
    }
  }

  /// {@macro flutter_fancy_tree_view.tree_controller.rebuild}
  void rebuild() => _state?.rebuild();

  /// {@macro flutter_fancy_tree_view.tree_controller.expand}
  void expand(TreeNode<T> node) => _state?.expand(node);

  /// {@macro flutter_fancy_tree_view.tree_controller.collapse}
  void collapse(TreeNode<T> node) => _state?.collapse(node);

  /// {@macro flutter_fancy_tree_view.tree_controller.toggle}
  void toggle(TreeNode<T> node) => _state?.toggle(node);

  /// {@macro flutter_fancy_tree_view.tree_controller.expandCascading}
  void expandCascading(TreeNode<T> node) => _state?.expandCascading(node);

  /// {@macro flutter_fancy_tree_view.tree_controller.collapseCascading}
  void collapseCascading(TreeNode<T> node) => _state?.collapseCascading(node);

  /// {@macro flutter_fancy_tree_view.tree_controller.expandAll}
  void expandAll() => _state?.expandAll();

  /// {@macro flutter_fancy_tree_view.tree_controller.collapseAll}
  void collapseAll() => _state?.collapseAll();
}

/// A state mixin used by [SliverTree] to manage the tree provided by a [TreeDelegate].
///
/// See also:
///
///   * [TreeController] which when attached to a [SliverTree], delegates its
///     method calls to this mixin, useful to dynamically update the tree.
mixin TreeControllerStateMixin<T, S extends StatefulWidget>
    on State<S>, TreeAnimationsStateMixin<S> {
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
  TreeNode<T> nodeAt(int index) => nodes[index];

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

  final Map<Key, bool> _revealingNodes = <Key, bool>{};
  void _markIsRevealing(Key key) => _revealingNodes[key] = true;

  final Map<Key, bool> _concealingNodes = <Key, bool>{};
  void _markIsConcealing(Key key) => _concealingNodes[key] = true;

  /// Returns an Animation<double> based on the current state of [node].
  ///
  /// Returns a [kAlwaysCompleteAnimation] if [node] is neither being revealed
  /// nor concealed.
  ///
  /// This method also removes [node] from its animating list.
  @protected
  Animation<double> findAnimation(TreeNode<T> node) {
    if (_revealingNodes.remove(node.key) ?? false) {
      return revealAnimation;
    }

    if (_concealingNodes.remove(node.key) ?? false) {
      return concealAnimation;
    }

    return kAlwaysCompleteAnimation;
  }

  /// {@template flutter_fancy_tree_view.tree_controller.expand}
  /// Updates [node.item] expansion state to `true` and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already expanded.
  /// {@endtemplate}
  void expand(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(
      node.item,
      (T item) => _markIsRevealing(keyFactory(item)),
    );

    rebuild();
    startRevealAnimation();
  }

  /// {@template flutter_fancy_tree_view.tree_controller.collapse}
  /// Updates [node.item] expansion state to `false` and rebuilds the tree.
  ///
  /// No checks are done to [node.item]. So, this will execute even if the item
  /// is already collapsed.
  /// {@endtemplate}
  void collapse(TreeNode<T> node) {
    delegate.setExpansionState(node.item, false);

    setState(() => _concealNodes(node.descendants));
    startConcealAnimation(rebuild);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.toggle}
  /// Updates [node.item] expansion state to the opposite state.
  /// {@endtemplate}
  void toggle(TreeNode<T> node) {
    delegate.getExpansionState(node.item) ? collapse(node) : expand(node);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.expandCascading}
  /// Traverses [node]'s branch updating all descendants expansion state to
  /// `true` and rebuilds the tree.
  /// {@endtemplate}
  void expandCascading(TreeNode<T> node) {
    // Don't call [delegate.traverse] directly with [node.item] so that the
    // expanding node itself doesn't animate.
    delegate.setExpansionState(node.item, true);
    _visitVisibleDescendants(
      node.item,
      (T item) {
        delegate.setExpansionState(item, true);
        _markIsRevealing(keyFactory(item));
      },
    );

    rebuild();
    startRevealAnimation();
  }

  /// {@template flutter_fancy_tree_view.tree_controller.collapseCascading}
  /// Traverses [node]'s branch updating all descendants expansion state to
  /// `false` and rebuilds the tree.
  /// {@endtemplate}
  void collapseCascading(TreeNode<T> node) {
    delegate.traverse(
      item: node.item,
      shouldContinue: (_) => true,
      onTraverse: (T item) => delegate.setExpansionState(item, false),
    );

    setState(() => _concealNodes(node.descendants));
    startConcealAnimation(rebuild);
  }

  /// {@template flutter_fancy_tree_view.tree_controller.expandAll}
  /// Traverses the entire tree provided by [TreeDelegate] updating the
  /// expansion state of all items to `true`.
  /// {@endtemplate}
  void expandAll() {
    setState(() {
      _nodes = FlatTree<T>(_buildExpandedFlatTree());
      startRevealAnimation();
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
  void collapseAll() {
    final List<TreeNode<T>> tree = <TreeNode<T>>[];

    final List<T> rootItems = delegate.rootItems;
    final int lastIndex = rootItems.length - 1;

    for (int index = 0; index <= lastIndex; index++) {
      final T rootItem = rootItems[index];

      delegate.traverse(
        item: rootItem,
        shouldContinue: (_) => true,
        onTraverse: (T item) => delegate.setExpansionState(item, false),
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

    setState(_concealNodes);
    startConcealAnimation(() => setState(() => _nodes = FlatTree<T>(tree)));
  }

  void _concealNodes([Iterable<TreeNode<T>>? branch]) {
    branch ??= _nodes;

    for (final TreeNode<T> node in branch) {
      if (node.isRoot) {
        // Root nodes should not animate.
        continue;
      }
      _markIsConcealing(node.key);
    }
  }

  @protected
  List<TreeNode<T>> _buildExpandedFlatTree() {
    final List<TreeNode<T>> tree = <TreeNode<T>>[];
    int globalIndex = 0;

    void generateFlatTree({
      required List<T> items,
      required int level,
      required MutableTreeNode<T>? parent,
      required bool itemsAreBeingRevealed,
    }) {
      final int lastIndex = items.length - 1;

      for (int index = 0; index <= lastIndex; index++) {
        final T item = items[index];
        final Key itemKey = keyFactory(item);

        if (itemsAreBeingRevealed) {
          _markIsRevealing(itemKey);
        }

        final bool isCollapsed = !delegate.getExpansionState(item);

        if (isCollapsed) {
          delegate.setExpansionState(item, true);

          // This item was collapsed so descendants must animate in
          itemsAreBeingRevealed = true;
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
            itemsAreBeingRevealed: itemsAreBeingRevealed,
          );
        }
      }
    }

    generateFlatTree(
      items: delegate.rootItems,
      level: 0,
      parent: null,
      itemsAreBeingRevealed: false,
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
