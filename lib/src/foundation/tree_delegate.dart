import 'dart:collection' show DoubleLinkedQueue;

import 'package:flutter/foundation.dart' show Key, ValueKey;

/// Callback definition used by [TreeDelegate.fromHandlers] to find the roots of
/// the tree.
typedef RootsFinder<T> = List<T> Function();

/// Callback definition used by [TreeDelegate.fromHandlers] to get a value for
/// the provided [item].
typedef TreeItemValueGetter<T, V> = V Function(T item);

/// Callback definition used by [TreeDelegate.fromHandlers] to set a value for
/// the provided [item].
typedef TreeItemValueSetter<T, V> = void Function(T item, V value);

/// Callback definition used to act on an item during tree traversal.
typedef OnTraverse<T> = void Function(T item);

/// Signature for a function that takes a tree item and returns a [Key].
///
/// Used by [TreeDelegate.fromHandlers] to get a [Key] for the provided [item].
typedef KeyGetter<T> = Key Function(T item);

/// An interface for handling the state of the items that compose the tree.
///
/// The delegate will be used to build the tree hierarchy on demand.
///
/// This method is going to be called very frequently during tree flattening,
/// consider caching the results.
///
/// By default selection is disabled, therefore [TreeDelegate.getSelection]
/// always returns false and [TreeDelegate.setSelection] has an empty body.
/// Subclasses should override both methods to enable selection.
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
  ///   final Key key = UniqueKey();
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
  ///   getKey: (Item item) => item.key,
  ///   getExpansion: (Item item) => item.isExpanded,
  ///   setExpansion: (Item item, bool expanded) {
  ///     item.isExpanded = expanded;
  ///   },
  ///   getSelection: (Item item) => item.isSelected,
  ///   setSelection: (Item item, bool selected) {
  ///     item.isSelected = selected
  ///   },
  /// );
  /// ```
  ///
  /// If not provided, [getKey] defaults to [ValueKey<T>.new].
  const factory TreeDelegate.fromHandlers({
    required RootsFinder<T> findRootItems,
    required TreeItemValueGetter<T, List<T>> findChildren,
    required TreeItemValueGetter<T, bool> getExpansion,
    required TreeItemValueSetter<T, bool> setExpansion,
    KeyGetter<T>? getKey,
    TreeItemValueGetter<T, bool>? getSelection,
    TreeItemValueSetter<T, bool>? setSelection,
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

  /// A helper method to get a [Key] for [item].
  ///
  /// Make sure the key provided for an item is always the same and unique
  /// among other keys, otherwise it could lead to inconsistent tree state.
  ///
  /// Defaults to creating a new [ValueKey] for the provided item.
  Key getKey(T item) => ValueKey<T>(item);

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
  /// bool getExpansion(Item item) => item.isExpanded;
  ///
  /// // Or
  ///
  /// final Map<int, bool> expansionCache = <int, bool>{};
  ///
  /// bool getExpansion(int itemId) => expansionCache[itemId] ?? false;
  /// ```
  bool getExpansion(T item);

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
  /// void setExpansion(Item item, bool expanded) {
  ///   item.isExpanded = expanded;
  /// }
  ///
  /// // Or
  ///
  /// final Map<int, bool> expansionCache = <int, bool>{};
  ///
  /// void setExpansion(int itemId, bool expanded) {
  ///   if (expanded) {
  ///     expansionCache[itemId] = true;
  ///   } else {
  ///     expansionCache.remove(itemId);
  ///   }
  /// }
  /// ```
  void setExpansion(T item, bool expanded);

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
  /// bool getSelected(Item item) => item.isSelected;
  ///
  /// // Or
  ///
  /// final Map<int, bool> selectionCache = <int, bool>{};
  ///
  /// bool getSelected(int itemId) => selectionCache[itemId] ?? false;
  /// ```
  ///
  /// The implementation is optional. By default it always returns `false`.
  bool getSelection(T item) => false;

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
  /// void setSelected(Item item, bool selected) {
  ///   item.isSelected = selected;
  /// }
  ///
  /// // Or
  ///
  /// final Map<int, bool> selectionCache = <int, bool>{};
  ///
  /// void setSelection(int itemId, bool selected) {
  ///   if (selected) {
  ///     selectionCache[itemId] = true;
  ///   } else {
  ///     selectionCache.remove(itemId);
  ///   }
  /// }
  /// ```
  ///
  /// The implementation is optional. It has an empty body by default.
  void setSelection(T item, bool selected) {}

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
    required TreeItemValueGetter<T, bool> shouldContinue,
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

      queue.addAll(findChildren(item));
    }

    return null;
  }
}

class _TreeDelegateFromHandlers<T> extends TreeDelegate<T> {
  const _TreeDelegateFromHandlers({
    required RootsFinder<T> findRootItems,
    required TreeItemValueGetter<T, List<T>> findChildren,
    required TreeItemValueGetter<T, bool> getExpansion,
    required TreeItemValueSetter<T, bool> setExpansion,
    KeyGetter<T>? getKey,
    TreeItemValueGetter<T, bool>? getSelection,
    TreeItemValueSetter<T, bool>? setSelection,
  })  : _rootItemsFinder = findRootItems,
        _childrenFinder = findChildren,
        _expansionGetter = getExpansion,
        _expansionSetter = setExpansion,
        _keyGetter = getKey ?? ValueKey<T>.new,
        _selectionGetter = getSelection,
        _selectionSetter = setSelection;

  final RootsFinder<T> _rootItemsFinder;
  final TreeItemValueGetter<T, List<T>> _childrenFinder;
  final TreeItemValueGetter<T, bool> _expansionGetter;
  final TreeItemValueSetter<T, bool> _expansionSetter;
  final KeyGetter<T> _keyGetter;
  final TreeItemValueGetter<T, bool>? _selectionGetter;
  final TreeItemValueSetter<T, bool>? _selectionSetter;

  @override
  List<T> get rootItems => _rootItemsFinder();

  @override
  List<T> findChildren(T item) => _childrenFinder(item);

  @override
  Key getKey(T item) => _keyGetter(item);

  @override
  bool getExpansion(T item) => _expansionGetter(item);

  @override
  void setExpansion(T item, bool expanded) {
    _expansionSetter(item, expanded);
  }

  @override
  bool getSelection(T item) => _selectionGetter?.call(item) ?? false;

  @override
  void setSelection(T item, bool selected) {
    _selectionSetter?.call(item, selected);
  }
}
