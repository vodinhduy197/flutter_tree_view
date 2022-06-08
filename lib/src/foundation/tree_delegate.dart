import 'dart:collection' show DoubleLinkedQueue;

/// Callback definition used by [TreeDelegate.fromHandlers] to find the roots of
/// the tree.
typedef RootsFinder<T> = List<T> Function();

/// Callback definition used by [TreeDelegate.fromHandlers] to find the children
/// of [item].
typedef ChildrenFinder<T> = List<T> Function(T item);

/// Callback definition used by [TreeDelegate.fromHandlers] to get some state
/// from the provided [item].
typedef TreeItemStateGetter<T> = bool Function(T item);

/// Callback definition used by [TreeDelegate.fromHandlers] to set [state] for
/// the provided [item].
typedef TreeItemStateSetter<T> = void Function(T item, bool state);

/// Callback definition used to act on an item during tree traversal.
typedef OnTraverse<T> = void Function(T item);

/// An interface for handling the state of the items that compose the tree.
///
/// The delegate will be used to build the tree hierarchy on demand.
///
/// This method is going to be called very frequently during tree flattening,
/// consider caching the results.
///
/// By default selection is disabled, therefore [TreeDelegate.getSelectedState]
/// always returns false and [TreeDelegate.setSelectedState] has an empty body.
/// Subclasses should override these methods to enable selection.
///
/// See also:
///
///   * [TreeDelegate.fromHandlers] a convenient factory constructor that takes
///     handler callbacks for the different methods of this interface.
abstract class TreeDelegate<T> {
  /// Enable subclasses to define constant constructors.
  const TreeDelegate();

  /// Convenient factory construtor that takes some handler callbacks to avoid
  /// having to subclass [TreeDelegate] on simple usecases.
  ///
  /// Example:
  ///
  /// ```dart
  /// class Item {
  ///   List<Item> children = <Item>[];
  ///   bool isExpanded = false;
  ///   bool isSelected = false;
  /// }
  ///
  /// final List<Item> rootItems = <Item>[Item(), Item()];
  ///
  /// final TreeDelegate<Item> delegate = TreeDelegate<Item>.fromHandlers(
  ///   findRootItems: () => rootItems,
  ///   findChildren: (Item item) => item.children,
  ///   getExpansionState: (Item item) => item.isExpanded,
  ///   getSelectionState: (Item item) => item.isSelected,
  ///   setExpansionState: (Item item, bool expanded) {
  ///     item.isExpanded = expanded;
  ///   },
  ///   setSelectionState: (Item item, bool selected) {
  ///     item.isSelected = selected
  ///   },
  /// );
  /// ```
  const factory TreeDelegate.fromHandlers({
    required RootsFinder<T> findRootItems,
    required ChildrenFinder<T> findChildren,
    required TreeItemStateGetter<T> getExpansionState,
    required TreeItemStateSetter<T> setExpansionState,
    TreeItemStateGetter<T>? getSelectionState,
    TreeItemStateSetter<T>? setSelectionState,
  }) = _TreeDelegateFromHandlers<T>;

  /// The items that occupy the level 0 of the tree.
  ///
  /// This getter is going to be called each time the tree rebuilds, consider
  /// caching its content.
  List<T> get rootItems;

  /// Called, as needed when composing the tree, to get the children of [item].
  ///
  /// This method is going to be called very frequently during tree flattening,
  /// consider caching the results.
  List<T> findChildren(T item);

  /// Convenient method to get the current expansion state of [item].
  ///
  /// This method must return `true` if the children of [item] should be
  /// displayed on the tree and `false` otherwise.
  ///
  /// Usual implementations look something like:
  ///
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  /// }
  ///
  /// bool getExpansionState(Item item) => item.isExpanded;
  ///
  /// // Or
  ///
  /// final Map<int, bool> expansionCache = <int, bool>{};
  ///
  /// bool getExpansionState(int itemId) => expansionCache[itemId] ?? false;
  /// ```
  bool getExpansionState(T item);

  /// Convenient method used by [TreeController] to update the expansion state
  /// of [item].
  ///
  /// The [expanded] parameter represents the item's new state.
  ///
  /// Usual implementations look something like:
  ///
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  /// }
  ///
  /// void setExpansionState(Item item, bool expanded) {
  ///   item.isExpanded = expanded;
  /// }
  ///
  /// // Or
  ///
  /// final Map<int, bool> expansionCache = <int, bool>{};
  ///
  /// void setExpansionState(int itemId, bool expanded) {
  ///   if (expanded) {
  ///     expansionCache[itemId] = true;
  ///   } else {
  ///     expansionCache.remove(itemId);
  ///   }
  /// }
  /// ```
  void setExpansionState(T item, bool expanded);

  /// Convenient method to get the current selection state of [item].
  ///
  /// This method must return `true` if the [item] is currently selected or
  /// `false` otherwise.
  ///
  /// Usual implementations look something like:
  ///
  /// ```dart
  /// class Item {
  ///   bool isSelected = false;
  /// }
  ///
  /// bool getSelectedState(Item item) => item.isSelected;
  ///
  /// // Or
  ///
  /// final Map<int, bool> selectionCache = <int, bool>{};
  ///
  /// bool getSelectedState(int itemId) => selectionCache[itemId] ?? false;
  /// ```
  ///
  /// The implementation is optional. By default it always returns `false`.
  bool getSelectionState(T item) => false;

  /// Convenient method used by [TreeController] to update the selection state
  /// of [item].
  ///
  /// The [selected] parameter represents the item's new state.
  ///
  /// Usual implementations look something like:
  ///
  /// ```dart
  /// class Item {
  ///   bool isSelected = false;
  /// }
  ///
  /// void setSelectedState(Item item, bool selected) {
  ///   item.isExpanded = expanded;
  /// }
  ///
  /// // Or
  ///
  /// final Map<int, bool> selectionCache = <int, bool>{};
  ///
  /// void setSelectionState(int itemId, bool selected) {
  ///   if (selected) {
  ///     selectionCache[itemId] = true;
  ///   } else {
  ///     selectionCache.remove(itemId);
  ///   }
  /// }
  /// ```
  ///
  /// The implementation is optional. It has an empty body by default.
  void setSelectionState(T item, bool selected) {}

  /// Traverses [item]'s branch in depth first order.
  ///
  /// The [shouldContinue] callback can be used to decide if the recursion
  /// continues through the children of the current item or if it should be
  /// skipped. Example:
  ///
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  /// }
  ///
  /// treeController.traverse(
  ///   item: item,
  ///   // Avoid operating on a collapsed branch
  ///   shouldContinue: (Item item) => item.isExpanded,
  ///   // Apply an action during traversal
  ///   onTraverse: (Item item) => reportVisitedItem(item),
  /// );
  /// ```
  ///
  /// If provided, [onTraverse] will be called before [shouldContinue] for every
  /// visited item.
  void traverse({
    required T item,
    required TreeItemStateGetter<T> shouldContinue,
    OnTraverse<T>? onTraverse,
  }) {
    onTraverse?.call(item);

    if (shouldContinue(item)) {
      final List<T> children = findChildren(item);

      for (final T child in children) {
        traverse(
          item: child,
          shouldContinue: shouldContinue,
          onTraverse: onTraverse,
        );
      }
    }
  }

  /// Traverses the tree looking for an item that matches the condition provided
  /// by [returningCondition] and returns it.
  ///
  /// If no item matches the [returningCondition] null is returned.
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
  /// See also:
  ///
  ///   * [TreeDelegate.traverse] which traverses the branch of the provided
  ///     item in depth first order.
  T? breadthFirstSearch({
    required TreeItemStateGetter<T> returningCondition,
    OnTraverse<T>? onTraverse,
  }) {
    final DoubleLinkedQueue<T> queue = DoubleLinkedQueue<T>.of(rootItems);

    while (queue.isNotEmpty) {
      final T item = queue.removeFirst();

      onTraverse?.call(item);

      if (returningCondition(item)) {
        return item;
      }

      queue.addAll(findChildren(item));
    }

    return null;
  }
}

class _TreeDelegateFromHandlers<T> extends TreeDelegate<T> {
  const _TreeDelegateFromHandlers({
    required RootsFinder<T> findRootItems,
    required ChildrenFinder<T> findChildren,
    required TreeItemStateGetter<T> getExpansionState,
    required TreeItemStateSetter<T> setExpansionState,
    TreeItemStateGetter<T>? getSelectionState,
    TreeItemStateSetter<T>? setSelectionState,
  })  : _rootItemsFinder = findRootItems,
        _childrenFinder = findChildren,
        _expansionGetter = getExpansionState,
        _expansionSetter = setExpansionState,
        _selectionGetter = getSelectionState,
        _selectionSetter = setSelectionState;

  final RootsFinder<T> _rootItemsFinder;
  final ChildrenFinder<T> _childrenFinder;
  final TreeItemStateGetter<T> _expansionGetter;
  final TreeItemStateSetter<T> _expansionSetter;
  final TreeItemStateGetter<T>? _selectionGetter;
  final TreeItemStateSetter<T>? _selectionSetter;

  @override
  List<T> get rootItems => _rootItemsFinder();

  @override
  List<T> findChildren(T item) => _childrenFinder(item);

  @override
  bool getExpansionState(T item) => _expansionGetter(item);

  @override
  void setExpansionState(T item, bool expanded) {
    _expansionSetter(item, expanded);
  }

  @override
  bool getSelectionState(T item) => _selectionGetter?.call(item) ?? false;

  @override
  void setSelectionState(T item, bool selected) {
    _selectionSetter?.call(item, selected);
  }
}
