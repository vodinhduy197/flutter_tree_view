import 'dart:collection' show DoubleLinkedQueue;

/// Signature of a function used by [TreeDelegate.fromHandlers] to get the root
/// items of the tree.
typedef TreeRootItemsGetter<T> = List<T> Function();

/// Signature of a function used by [TreeDelegate.fromHandlers] to get a value
/// for the provided [item].
typedef TreeItemValueGetter<T, V> = V Function(T item);

/// Signature of a function used by [TreeDelegate.fromHandlers] to set a value
/// for the provided [item].
typedef TreeItemValueSetter<T, V> = void Function(T item, V value);

/// Signature of a function used to visit [item] during tree traversal.
typedef OnTraverse<T> = void Function(T item);

/// Signature of a function used to visit [item] during tree traversal that also
/// includes its [parent].
typedef OnTraverseWithParent<T> = void Function(T item, T? parent);

/// An interface for handling the state of the items that compose the tree.
///
/// The delegate will be used to build the tree hierarchy on demand.
///
/// The methods of this class are going to be called very frequently during tree
/// flattening and tree operations, consider caching the results if needed.
///
/// See also:
///
///   * [TreeDelegate.fromHandlers] a convenient factory constructor that takes
///     handler callbacks for the different methods of this interface.
abstract class TreeDelegate<T> {
  /// Enable subclasses to declare constant constructors.
  const TreeDelegate();

  /// Convenient factory construtor that takes some handler callbacks to avoid
  /// having to subclass [TreeDelegate] on simple usecases.
  ///
  /// Example:
  ///
  /// ```dart
  /// class Item {
  ///   Item(this.id);
  ///   final String id;
  ///   List<Item> children = <Item>[];
  ///   bool isExpanded = false;
  /// }
  ///
  /// final List<Item> rootItems = <Item>[Item(), Item()];
  ///
  /// final TreeDelegate<Item> delegate = TreeDelegate<Item>.fromHandlers(
  ///   getRootItems: () => rootItems,
  ///   getUniqueId: (Item item) => item.id,
  ///   getChildren: (Item item) => item.children,
  ///   getExpansion: (Item item) => item.isExpanded,
  ///   setExpansion: (Item item, bool expanded) => item.isExpanded = expanded},
  /// );
  /// ```
  const factory TreeDelegate.fromHandlers({
    required TreeRootItemsGetter<T> getRootItems,
    required TreeItemValueGetter<T, String> getUniqueId,
    required TreeItemValueGetter<T, List<T>> getChildren,
    required TreeItemValueGetter<T, bool> getExpansion,
    required TreeItemValueSetter<T, bool> setExpansion,
  }) = _TreeDelegateFromHandlers<T>;

  /// The items that occupy the level 0 of the tree.
  ///
  /// This getter is going to be called each time the tree rebuilds, consider
  /// caching its content if needed.
  ///
  /// To update the root items of a tree, it's as simple as updating the list
  /// returned by this getter and calling [SliverTreeState.rebuild].
  List<T> get rootItems;

  /// A helper method to get a unique identifier for [item].
  ///
  /// Make sure the id provided for an item is always the same and unique
  /// among other ids, otherwise it could lead to inconsistent tree state.
  ///
  /// A unique identifier is required to enable property caching for [item], for
  /// example, to cache the animating state of each item during tree flattening.
  ///
  /// If using the id of the item as the data provided to the tree, this method
  /// can be as simple as: `String getUniqueId(String item) => item;`
  String getUniqueId(T item);

  /// Called, as needed when composing the tree, to get the children of [item].
  ///
  /// This method is going to be called very frequently during tree flattening,
  /// consider caching the results.
  List<T> getChildren(T item);

  /// Should return the current expansion state of [item].
  ///
  /// Usual implementations look something like the following:
  ///
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  /// }
  ///
  /// bool getExpansion(Item item) => item.isExpanded;
  ///
  /// // Or
  ///
  /// final Map<String, bool> expansionCache = <String, bool>{};
  ///
  /// bool getExpansion(String itemId) => expansionCache[itemId] ?? false;
  /// ```
  bool getExpansion(T item);

  /// Should update the expansion state of [item].
  /// The [expanded] parameter represents the item's **new** state.
  ///
  /// Usual implementations look something like the following:
  ///
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  /// }
  ///
  /// void setExpansion(Item item, bool expanded) {
  ///   item.isExpanded = expanded;
  /// }
  ///
  /// // Or
  ///
  /// final Map<String, bool> expansionCache = <String, bool>{};
  ///
  /// void setExpansion(String itemId, bool expanded) {
  ///   if (expanded) {
  ///     expansionCache[itemId] = true;
  ///   } else {
  ///     expansionCache.remove(itemId);
  ///   }
  /// }
  /// ```
  void setExpansion(T item, bool expanded);

  /// Traverses the tree in depth first order looking for an item that matches
  /// the condition provided by [returningCondition] and returns it.
  ///
  /// If no item matches the [returningCondition], null is returned.
  ///
  /// If provided, [onTraverse] is going to be called before checking the
  /// [returningCondition]. Use [onTraverse] to keep track of visited items or
  /// apply actions on traversal.
  ///
  /// Example:
  ///
  /// ```dart
  /// class Item {
  ///   String label = 'Foo';
  /// }
  ///
  /// int visitedItemCount = 0;
  ///
  /// final Item? fooItem = treeDelegate.depthFirstSearch(
  ///   returningCondition: (Item item) => item.label == 'Foo',
  ///   onTraverse: (Item item) => visitedItemCount++,
  /// );
  /// ```
  ///
  /// **Depth-first search** is an algorithm for traversing or searching tree
  /// data structures. The algorithm starts at the root node(s) and explores
  /// as far as possible along each branch before backtracking.
  /// Source: [Wikipedia](https://en.wikipedia.org/wiki/Depth-first_search).
  ///
  /// See also:
  ///
  ///   * [TreeDelegate.breadthFirstSearch] which does the same thing but in
  ///     breadth first order.
  T? depthFirstSearch({
    required TreeItemValueGetter<T, bool> returningCondition,
    OnTraverse<T>? onTraverse,
  }) {
    final List<T> stack = List<T>.of(rootItems);

    while (stack.isNotEmpty) {
      final T item = stack.removeAt(0);

      onTraverse?.call(item);

      if (returningCondition(item)) {
        return item;
      }

      stack.insertAll(0, getChildren(item));
    }

    return null;
  }

  /// Traverses the tree in breadth first order looking for an item that matches
  /// the condition provided by [returningCondition] and returns it.
  ///
  /// If no item matches the [returningCondition], `null` is returned.
  ///
  /// If provided, [onTraverse] is going to be called before checking the
  /// [returningCondition]. Use [onTraverse] to keep track of visited items or
  /// apply actions on traversal.
  ///
  /// Example:
  ///
  /// ```dart
  /// class Item {
  ///   String label = 'Foo';
  /// }
  ///
  /// int visitedItemCount = 0;
  ///
  /// final Item? fooItem = treeDelegate.breadthFirstSearch(
  ///   returningCondition: (Item item) => item.label == 'Foo',
  ///   onTraverse: (Item item) => visitedItemCount++,
  /// );
  /// ```
  ///
  /// **Breadth-first search** is an algorithm for searching a tree data structure
  /// for a node that satisfies a given property. It starts at the tree root and
  /// explores all nodes at the present depth prior to moving on to the nodes at
  /// the next depth level.
  /// Source: [Wikipedia](https://en.wikipedia.org/wiki/Breadth-first_search).
  ///
  /// See also:
  ///
  ///   * [TreeDelegate.depthFirstSearch] which does the same thing but in depth
  ///     first order.
  T? breadthFirstSearch({
    required TreeItemValueGetter<T, bool> returningCondition,
    OnTraverse<T>? onTraverse,
  }) {
    final DoubleLinkedQueue<T> queue = DoubleLinkedQueue<T>.of(rootItems);

    while (queue.isNotEmpty) {
      final T item = queue.removeFirst();

      onTraverse?.call(item);

      if (returningCondition(item)) {
        return item;
      }

      queue.addAll(getChildren(item));
    }

    return null;
  }
}

class _TreeDelegateFromHandlers<T> extends TreeDelegate<T> {
  const _TreeDelegateFromHandlers({
    required TreeRootItemsGetter<T> getRootItems,
    required TreeItemValueGetter<T, String> getUniqueId,
    required TreeItemValueGetter<T, List<T>> getChildren,
    required TreeItemValueGetter<T, bool> getExpansion,
    required TreeItemValueSetter<T, bool> setExpansion,
  })  : _rootItemsGetter = getRootItems,
        _uniqueIdGetter = getUniqueId,
        _childrenGetter = getChildren,
        _expansionGetter = getExpansion,
        _expansionSetter = setExpansion;

  final TreeRootItemsGetter<T> _rootItemsGetter;
  final TreeItemValueGetter<T, String> _uniqueIdGetter;
  final TreeItemValueGetter<T, List<T>> _childrenGetter;
  final TreeItemValueGetter<T, bool> _expansionGetter;
  final TreeItemValueSetter<T, bool> _expansionSetter;

  @override
  List<T> get rootItems => _rootItemsGetter();

  @override
  String getUniqueId(T item) => _uniqueIdGetter(item);

  @override
  List<T> getChildren(T item) => _childrenGetter(item);

  @override
  bool getExpansion(T item) => _expansionGetter(item);

  @override
  void setExpansion(T item, bool expanded) => _expansionSetter(item, expanded);
}
