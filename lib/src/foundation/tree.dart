import 'dart:collection' show UnmodifiableListView;

import 'tree_delegate.dart';
import 'tree_node.dart';

/// Signature for an unmodifiable list of [TreeNode<T>].
typedef FlatTree<T> = UnmodifiableListView<TreeNode<T>>;

/// A simple object that holds the flat representation of a tree.
class Tree<T> {
  /// Creates a [Tree] from its flat representation of [nodes].
  Tree({required this.nodes});

  /// Convenient constructor for an empty tree;
  Tree.empty() : this(nodes: FlatTree<T>(const []));

  /// Convenient constructor that takes a [List] of nodes and wraps it with an
  /// [UnmodifiableListView].
  Tree.fromList(List<TreeNode<T>> nodes) : this(nodes: FlatTree<T>(nodes));

  /// Convenient static method that flattens the tree provided by [delegate].
  ///
  /// This method will build the flat tree in depth first order and return a new
  /// [Tree] instance with the flattened tree as a plain dart list composed by
  /// [TreeNode]s in [Tree.nodes].
  ///
  /// [TreeNode]s hold important information about the context of its item in
  /// the current tree build.
  ///
  /// The returned [Tree] is composed by all nodes whose parent meets the
  /// condition checked by [descenCondition], if `null`, defaults to
  /// `(TreeNode<T> node) => node.isExpanded`.
  ///
  /// This static method also includes two usefull parameters:
  ///   - [onPreTraverse], an optional callback called **before** creating
  ///     a [TreeNode] for the given item, it also includes the item's parent.
  ///
  ///   - [onTraverse], an optional callback that is called **after** creating
  ///     a [TreeNode] but before descending to its branch.
  static Tree<T> flatten<T>(
    TreeDelegate<T> delegate, {
    TreeItemValueGetter<TreeNode<T>, bool>? descendCondition,
    OnTraverseWithParent<T>? onPreTraverse,
    OnTraverse<TreeNode<T>>? onTraverse,
  }) {
    final TreeItemValueGetter<TreeNode<T>, bool> shouldDescend =
        descendCondition ?? (TreeNode<T> node) => node.isExpanded;

    int globalIndex = 0;

    Iterable<TreeNode<T>> generateFlatTree({
      required List<T> childItems,
      required int level,
      required TreeNode<T>? parent,
    }) sync* {
      final int lastIndex = childItems.length - 1;

      for (int index = 0; index <= lastIndex; index++) {
        final T item = childItems[index];

        onPreTraverse?.call(item, parent?.item);

        final TreeNode<T> node = TreeNode<T>(
          id: delegate.getUniqueId(item),
          item: item,
          isExpanded: delegate.getExpansion(item),
          level: level,
          index: globalIndex++,
          hasNextSibling: index < lastIndex,
          parent: parent,
        );

        onTraverse?.call(node);
        yield node;

        // using `late` initialization avoids the unnecessary calls to
        //`getChildren` since if the left side of the if statement falses out,
        // the right side shouldn't get evaluated at all.
        late final List<T> children = delegate.getChildren(item);

        if (shouldDescend(node) && children.isNotEmpty) {
          yield* generateFlatTree(
            childItems: children,
            level: level + 1,
            parent: node,
          );
        }
      }
    }

    final List<TreeNode<T>> flatTree = generateFlatTree(
      childItems: delegate.rootItems,
      level: 0,
      parent: null,
    ).toList();

    return Tree<T>.fromList(flatTree);
  }

  /// The flat representation of this tree.
  final FlatTree<T> nodes;

  /// Convenient getter that delegates its call to `nodes.length`.
  int get size => nodes.length;
}
