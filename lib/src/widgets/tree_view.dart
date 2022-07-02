import 'dart:async' show FutureOr;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../foundation.dart';

/// Signature for a function that creates a widget for a given node, e.g., in a
/// tree.
typedef TreeNodeWidgetBuilder<T> = Widget Function(
  BuildContext context,
  TreeNode<T> node,
);

/// Signature for a function that takes a widget and an animation to apply
/// transitions if needed.
typedef TreeTransitionBuilder = Widget Function(
  Widget child,
  Animation<double>,
);

/// The default [Duration] used by [SliverTreeState] to animate the expansion
/// state changes of its nodes.
///
/// Defaults to `Duration(milliseconds: 300)`.
const Duration kDefaultTreeAnimationDuration = Duration(milliseconds: 300);

/// The default [Curve] used by [SliverTreeState] to animate the expansion state
/// changes of its nodes.
///
/// Defaults to `Curves.ease`.
const Curve kDefaultTreeAnimationCurve = Curves.ease;

/// A simple, fancy and highly customizable hierarchy visualization Widget.
///
/// This widget wraps a [SliverTree] in a [CustomScrollView] with some defaults.
///
/// {@macro flutter_fancy_tree_view.sliver_tree.disable_animations}
///
/// See also:
///
///  * [SliverTree], which could be used to build more sophisticated scrolling
///    experiences with [CustomScrollView].
class TreeView<T> extends StatelessWidget {
  /// Creates a [TreeView].
  ///
  /// Take a look at [TreeTile] for your [builder].
  const TreeView({
    super.key,
    required this.delegate,
    required this.builder,
    this.controller,
    this.transitionBuilder = defaultTreeTransitionBuilder,
    this.animationDuration = kDefaultTreeAnimationDuration,
    this.animationCurve = kDefaultTreeAnimationCurve,
    this.itemExtent,
    this.prototypeItem,
    this.padding,
    this.scrollController,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  /// {@macro flutter_fancy_tree_view.sliver_tree.delegate}
  final TreeDelegate<T> delegate;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  ///
  /// Checkout the [TreeTile] widget.
  final TreeNodeWidgetBuilder<T> builder;

  /// An optional controller that can be used to dynamically update the tree.
  final TreeController<T>? controller;

  /// Callback used to animate the expansion state change of a branch.
  ///
  /// See also:
  ///
  ///   * [defaultTreeTransitionBuilder] that uses fade and size transitions.
  final TreeTransitionBuilder transitionBuilder;

  /// {@macro flutter_fancy_tree_view.sliver_tree.animationDuration}
  final Duration animationDuration;

  /// {@macro flutter_fancy_tree_view.sliver_tree.animationDuration}
  final Curve animationCurve;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? scrollController;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// {@macro flutter.widgets.scroll_view.physics}
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.shrinkWrap}
  final bool shrinkWrap;

  /// {@macro flutter.widgets.scroll_view.anchor}
  final double anchor;

  /// The amount of space by which to inset the tree contents.
  ///
  /// It defaults to `EdgeInsets.zero`.
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  ///
  /// The default is [ScrollViewKeyboardDismissBehavior.manual]
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.list_view.itemExtent}
  final double? itemExtent;

  /// {@macro flutter.widgets.list_view.prototypeItem}
  final Widget? prototypeItem;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: Axis.vertical,
      reverse: false,
      controller: scrollController,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      anchor: anchor,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverTree<T>(
            delegate: delegate,
            controller: controller,
            builder: builder,
            transitionBuilder: transitionBuilder,
            animationDuration: animationDuration,
            animationCurve: animationCurve,
            itemExtent: itemExtent,
            prototypeItem: prototypeItem,
          ),
        ),
      ],
    );
  }
}

/// A simple, fancy and highly customizable hierarchy visualization Sliver.
///
/// {@template flutter_fancy_tree_view.sliver_tree.disable_animations}
/// Regarding expand/collapse animations:
/// - All methods from [SliverTreeState] like `expand` and `collapse` gather
///   information to animate the reveal/conceal operations.
/// - The "collapsing" methods in particular could take some time to process
///   depending on the size of the collapsed branch. This should not be a
///   problem in most scenarios.
/// - Consider awaiting the "collapsing" methods, as they need to rebuild the
///   tree after the animation is done playing.
/// - To disable animations, simply update the state of the items direclty from
/// [TreeDelegate] and then call [SliverTreeState.rebuild]. This will skip the
/// animation status processing.
/// {@endtemplate}
///
/// See also:
///
///  * [TreeView], which already covers some of the [CustomScrollView] boilerplate.
class SliverTree<T> extends StatefulWidget {
  /// Creates a [SliverTree].
  const SliverTree({
    super.key,
    required this.delegate,
    required this.builder,
    this.controller,
    this.transitionBuilder = defaultTreeTransitionBuilder,
    this.animationDuration = kDefaultTreeAnimationDuration,
    this.animationCurve = kDefaultTreeAnimationCurve,
    this.itemExtent,
    this.prototypeItem,
  }) : assert(
          itemExtent == null || prototypeItem == null,
          'You can only pass itemExtent or prototypeItem, not both',
        );

  /// {@macro flutter_fancy_tree_view.sliver_tree.delegate}
  final TreeDelegate<T> delegate;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  final TreeNodeWidgetBuilder<T> builder;

  /// An optional controller that can be used to dynamically update the tree.
  final TreeController<T>? controller;

  /// Callback used to animate the expansion state change of a branch.
  ///
  /// See also:
  ///
  ///   * [defaultTreeTransitionBuilder] that uses fade and size transitions.
  final TreeTransitionBuilder transitionBuilder;

  /// {@macro flutter_fancy_tree_view.sliver_tree.animationDuration}
  final Duration animationDuration;

  /// {@macro flutter_fancy_tree_view.sliver_tree.animationCurve}
  final Curve animationCurve;

  /// {@macro flutter.widgets.list_view.itemExtent}
  final double? itemExtent;

  /// {@macro flutter.widgets.list_view.prototypeItem}
  final Widget? prototypeItem;

  /// The [SliverTree] state from the closest instance of this class that
  /// encloses the given context.
  ///
  /// If there is no [SliverTree] ancestor widget in the widget tree at the
  /// given context, then this will return null.
  ///
  /// Typical usage is as follows:
  ///
  /// SliverTreeState<T>? treeState = SliverTree.maybeOf<T>(context);
  ///
  /// See also:
  ///
  ///  * [of], which will throw in debug mode if no [SliverTree] ancestor widget
  ///    exists in the widget tree.
  static SliverTreeState<T>? maybeOf<T>(BuildContext context) {
    return context.findAncestorStateOfType<SliverTreeState<T>>();
  }

  /// The [SliverTree] state from the closest instance of this class that
  /// encloses the given context.
  ///
  /// If there is no [SliverTree] ancestor widget in the widget tree at the
  /// given context, then this will throw in debug mode.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// SliverTreeState<T> treeState = SliverTree.of<T>(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which will return null if no [SliverTree] ancestor widget
  ///    exists in the widget tree.
  static SliverTreeState<T> of<T>(BuildContext context) {
    final SliverTreeState<T>? instance = maybeOf<T>(context);
    assert(() {
      if (instance == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'SliverTree.of() called with a context that does not contain a '
            'SliverTree.',
          ),
          ErrorDescription(
            'No SliverTree ancestor could be found starting from the context '
            'that was passed to SliverTree.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same '
            'StatefulWidget that built the SliverTree.',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return instance!;
  }

  @override
  SliverTreeState<T> createState() => SliverTreeState<T>();
}

/// A simple controller that when attached to a [SliverTree], delegates its
/// method calls to the underlying [SliverTreeState].
///
/// When not attached, the methods of this controller do nothing.
class TreeController<T> {
  SliverTreeState<T>? _state;

  void _attach(SliverTreeState<T> state) {
    assert(_state == null, 'TreeController already attached.');
    _state = state;
  }

  void _detach(SliverTreeState<T> state) {
    if (state == _state) {
      _state = null;
    }
  }

  /// Simple getter to check if this [TreeController] is currently attached to
  /// a [SliverTreeState].
  ///
  /// When unattached, the method calls of this controller do nothing.
  bool get isAttached => _state != null;

  /// {@macro flutter_fancy_tree_view.sliver_tree.rebuild}
  void rebuild() => _state?.rebuild();

  /// {@macro flutter_fancy_tree_view.sliver_tree.toggle}
  void toggle(T item) => _state?.toggle(item);

  /// {@macro flutter_fancy_tree_view.sliver_tree.expand}
  void expand(T item) => _state?.expand(item);

  /// {@macro flutter_fancy_tree_view.sliver_tree.expandCascading}
  void expandCascading(T item) => _state?.expandCascading(item);

  /// {@macro flutter_fancy_tree_view.sliver_tree.expandAll}
  void expandAll() => _state?.expandAll();

  /// {@macro flutter_fancy_tree_view.sliver_tree.collapse}
  FutureOr<void> collapse(T item) => _state?.collapse(item);

  /// {@macro flutter_fancy_tree_view.sliver_tree.collapseCascading}
  FutureOr<void> collapseCascading(T item) => _state?.collapseCascading(item);

  /// {@macro flutter_fancy_tree_view.sliver_tree.collapseAll}
  FutureOr<void> collapseAll() => _state?.collapseAll();
}

/// The default transition builder used by [SliverTree] to animate the expansion
/// state changes of a node.
///
/// Wraps [child] in [FadeTransition] and [SizeTransition].
Widget defaultTreeTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  return FadeTransition(
    opacity: animation,
    child: SizeTransition(
      sizeFactor: animation,
      child: child,
    ),
  );
}

/// An object that holds the state of a [SliverTree].
///
/// The current [SliverTreeState] instance can be acquired in several ways:
///   - Using a [GlobalKey] in your [SliverTree];
///   - Calling `SliverTree.of<T>(context)` (throws if not found);
///   - Calling `SliverTree.maybeOf<T>(context)` (nullable return);
///
/// See also:
///   * [TreeController], which delegates its method calls to [SliverTreeState].
class SliverTreeState<T> extends State<SliverTree<T>>
    with SingleTickerProviderStateMixin {
  /// {@template flutter_fancy_tree_view.sliver_tree.delegate}
  /// An interface to dynamically manage the state of the tree.
  ///
  /// Subclass [TreeDelegate] and implement the required methods to compose the
  /// tree and its state.
  ///
  /// Checkout [TreeDelegate.fromHandlers] for a simple implementation based on
  /// handler callbacks.
  /// {@endtemplate}
  TreeDelegate<T> get delegate => widget.delegate;

  /// {@template flutter_fancy_tree_view.sliver_tree.animationDuration}
  /// The duration used to play the expand/collapse animations.
  ///
  /// Defaults to [kDefaultTreeAnimationDuration], `Duration(milliseconds: 300)`.
  /// {@endtemplate}
  Duration get animationDuration => widget.animationDuration;

  /// {@template flutter_fancy_tree_view.sliver_tree.animationCurve}
  /// The [Curve] applied to the expand/collapse animations.
  ///
  /// Defaults to [kDefaultTreeAnimationDuration], `Curves.ease`.
  /// {@endtemplate}
  Curve get curve => widget.animationCurve;

  /// Determines if [Directionality.maybeOf] is set to [TextDirection.rtl].
  bool get isRtl => _isRtl;
  bool _isRtl = false;

  /// The most recent tree built from [TreeDelegate].
  Tree<T> get tree => _tree;
  Tree<T> _tree = Tree<T>.empty();

  Map<String, TreeAnimationStatus> _animationStatus = const {};

  TreeAnimationStatus _getAnimationStatus(String id) {
    return _animationStatus[id] ?? TreeAnimationStatus.idle;
  }

  late final AnimationController _animationController;

  late Animation<double> _revealAnimation;
  late Animation<double> _concealAnimation;

  void _setupAnimations() {
    _revealAnimation = CurveTween(curve: curve).animate(_animationController);
    _concealAnimation = ReverseAnimation(_revealAnimation);
  }

  TickerFuture _startAnimating() => _animationController.forward(from: 0.0);

  /// {@template flutter_fancy_tree_view.sliver_tree.rebuild}
  /// Rebuilds the current tree.
  ///
  /// This method will call [setState] traversing the tree to gatter the
  /// information and store its flat tree representation in [tree].
  ///
  /// Call this method whenever the tree items are updated (i.e child added/removed,
  /// item reordered, etc...). Most methods like `expand`, `collapse` already
  /// call rebuild.
  ///
  /// When updating the expansion state of an item from outside of the methods
  /// of [SliverTreeState], [rebuild] must be called to update the tree.
  ///
  /// Example:
  /// ```dart
  /// class Item {
  ///   bool isExpanded = false;
  ///   final List<Item> children = [];
  /// }
  ///
  /// // DON'T use rebuild when calling an expansion method of [SliverTreeState]:
  /// void expand(Item item) {
  ///   SliverTree.of<Item>(context).expand(item);
  ///   // SliverTree.of<Item>(context).rebuild(); // No need to call rebuild here.
  /// }
  ///
  /// // DO use rebuild when the expansion state is changed by outside sources:
  /// void expand(Item item) {
  ///   item.isExpanded = !item.isExpanded;
  ///   SliverTree.of<Item>(context).rebuild(); // Call rebuild to update the tree
  /// }
  ///
  /// // DO use rebuild when nodes are added/removed/reordered:
  /// void addChild(Item parent, Item child) {
  ///   parent.children.add(child)
  ///   SliverTree.of<Item>(context).rebuild();
  /// }
  ///
  /// /// Consider doing bulk updating before calling rebuild:
  /// void addChildren(Item parent, List<Item> children) {
  ///   for (final Item child in children) {
  ///     parent.children.add(child);
  ///     // DON'T rebuild after each child insertion
  ///     // SliverTree.of<Item>(context).rebuild();
  ///   }
  ///   // DO rebuild after all items are processed
  ///   SliverTree.of<Item>(context).rebuild();
  /// }
  /// ```
  ///
  /// [rebuild] can also be used to update the tree without animating.
  /// {@endtemplate}
  void rebuild() => setState(_build);

  void _build() => _tree = Tree.flatten<T>(delegate);

  /// {@template flutter_fancy_tree_view.sliver_tree.toggle}
  /// Updates [item] expansion state to the opposite state.
  ///
  /// (i.e, `true` -> `false` and `false` -> `true`).
  /// {@endtemplate}
  void toggle(T item) {
    delegate.getExpansion(item) ? collapse(item) : expand(item);
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.expand}
  /// Updates [item]'s expansion state to `true` and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already expanded.
  /// {@endtemplate}
  void expand(T item) {
    delegate.expand(item);

    // keep track of all items whose descendants are going to be revealed after
    // this operation.
    // used when flattening the tree to check if an item must be marked as revealing.
    final Set<String> revealingCache = <String>{
      delegate.idOf(item),
    };

    bool isRevealing(String? id) => revealingCache.contains(id);

    final Map<String, TreeAnimationStatus> animationStatus = {};

    final Tree<T> newTree = Tree.flatten<T>(
      delegate,
      onTraverse: (TreeNode<T> node) {
        if (isRevealing(node.parent?.id)) {
          // Our parent is marked as revealing, meaning that itself or an ancestor
          // was expanded, so we should mark ourselves as revealing too
          revealingCache.add(node.id);
          animationStatus[node.id] = TreeAnimationStatus.revealing;
        }
      },
    );

    setState(() {
      _tree = newTree;
      _animationStatus = animationStatus;
    });

    _startAnimating();
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.expandCascading}
  /// Traverses [item]'s branch updating all descendants expansion state to
  /// `true` and rebuilds the tree.
  /// {@endtemplate}
  void expandCascading(T item) {
    // keep track of all items whose descendants are going to be revealed after
    // this operation.
    // used when flattening the tree to check if an item must be expanded and
    // marked as revealing.
    final Set<String> revealingCache = <String>{
      delegate.idOf(item),
    };

    final Map<String, TreeAnimationStatus> animationStatus = {
      for (final TreeNode<T> node in tree.nodes)
        if (node.parent != null) node.id: TreeAnimationStatus.idle,
    };

    /// checks if [parent] was expanded or is currenlty revealing (i.e an
    /// ancestor was expanded).
    bool isRevealing(T? item) {
      return item != null && revealingCache.contains(delegate.idOf(item));
    }

    delegate.expand(item);

    // we operate on pre traverse so we can expand an item before its node is
    // created so that [TreeNode.isExpanded] doesn't get outdated imediatelly.
    final Tree<T> newTree = Tree.flatten<T>(
      delegate,
      onPreTraverse: (T item, T? parent) {
        if (isRevealing(parent)) {
          // Our parent is marked as revealing, meaning that itself or an ancestor
          // was expanded, so we should expand and mark ourselves as revealing too
          delegate.expand(item);

          final String id = delegate.idOf(item);
          revealingCache.add(id);
          animationStatus.putIfAbsent(
            id,
            () => TreeAnimationStatus.revealing,
          );
        }
      },
    );

    setState(() {
      _tree = newTree;
      _animationStatus = animationStatus;
    });

    _startAnimating();
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.expandAll}
  /// Updates the expansion state of all items to `true` and rebuilds the tree.
  /// {@endtemplate}
  void expandAll() {
    final Map<String, TreeAnimationStatus> animationStatus = {
      for (final TreeNode<T> node in tree.nodes)
        node.id: TreeAnimationStatus.idle,
    };

    final Tree<T> newTree = Tree.flatten<T>(
      delegate,
      descendCondition: (_) => true,
      onPreTraverse: (T item, _) {
        delegate.expand(item);

        animationStatus.putIfAbsent(
          delegate.idOf(item),
          () => TreeAnimationStatus.revealing,
        );
      },
    );

    setState(() {
      _tree = newTree;
      _animationStatus = animationStatus;
    });

    _startAnimating();
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.collapse}
  /// Updates [item]'s expansion state to `false` and rebuilds the tree.
  ///
  /// No checks are done to [item]. So, this will execute even if the item is
  /// already collapsed.
  ///
  /// This method returns a [Future] because we first animate the concealing of
  /// the nodes, await the animation to finish and then rebuild the tree.
  /// If we don't await the animation to finish, the tree will be rebuilt and
  /// the nodes that should animate won't be part of the new tree, so no
  /// animations are played at all.
  ///
  /// Add spam protection to your tree by awaiting this future, if desired.
  /// {@endtemplate}
  Future<void> collapse(T item) async {
    final Map<String, TreeAnimationStatus> animationStatus = {};

    delegate.visitVisibleDescendants(item, (T descendant) {
      final String id = delegate.idOf(descendant);
      animationStatus[id] = TreeAnimationStatus.concealing;
    });

    delegate.collapse(item);

    setState(() {
      _animationStatus = animationStatus;
    });

    await _startAnimating();

    rebuild();
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.collapseCascading}
  /// Traverses [item]'s branch updating all descendants expansion state to
  /// `false` and rebuilds the tree.
  ///
  /// This method returns a [Future] because we first animate the concealing of
  /// the nodes, await the animation to finish and then rebuild the tree.
  /// If we don't await the animation to finish, the tree will be rebuilt and
  /// the nodes that should animate won't be part of the new tree, so no
  /// animations are played at all.
  ///
  /// Add spam protection to your tree by awaiting this future, if desired.
  /// {@endtemplate}
  Future<void> collapseCascading(T item) async {
    delegate.collapse(item);

    final Map<String, TreeAnimationStatus> animationStatus = {};

    delegate.visitDescendants(item, (T descendant) {
      delegate.collapse(descendant);

      final String id = delegate.idOf(descendant);
      animationStatus[id] = TreeAnimationStatus.concealing;
    });

    setState(() {
      _animationStatus = animationStatus;
    });

    await _startAnimating();

    rebuild();
  }

  /// {@template flutter_fancy_tree_view.sliver_tree.collapseAll}
  /// Updates the expansion state of all items to `false` and rebuilds the tree.
  ///
  /// This method returns a [Future] because we first animate the concealing of
  /// the nodes, await the animation to finish and then rebuild the tree.
  /// If we don't await the animation to finish, the tree will be rebuilt and
  /// the nodes that should animate won't be part of the new tree, so no
  /// animations are played at all.
  ///
  /// Add spam protection to your tree by awaiting this future, if desired.
  /// {@endtemplate}
  Future<void> collapseAll() async {
    final Map<String, TreeAnimationStatus> animationStatus = {
      for (final TreeNode<T> node in tree.nodes)
        if (node.parent != null) node.id: TreeAnimationStatus.concealing,
    };

    delegate.collapseAll();

    setState(() {
      _animationStatus = animationStatus;
    });

    await _startAnimating();

    final Tree<T> newTree = Tree.flatten<T>(
      delegate,
      descendCondition: (_) => false, // Include root nodes only
    );

    setState(() {
      _tree = newTree;
    });
  }

  @override
  void initState() {
    super.initState();
    _build();
    widget.controller?._attach(this);

    _animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _setupAnimations();
  }

  @override
  void didUpdateWidget(covariant SliverTree<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _animationController.duration = animationDuration;
    _setupAnimations();

    if (oldWidget.delegate != delegate) {
      _build();
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
  }

  @override
  void dispose() {
    _tree = Tree<T>.empty();
    widget.controller?._detach(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SliverChildBuilderDelegate delegate = SliverChildBuilderDelegate(
      _builder,
      childCount: tree.size,
    );

    if (widget.itemExtent != null) {
      return SliverFixedExtentList(
        delegate: delegate,
        itemExtent: widget.itemExtent!,
      );
    } else if (widget.prototypeItem != null) {
      return SliverPrototypeExtentList(
        delegate: delegate,
        prototypeItem: widget.prototypeItem!,
      );
    }

    return SliverList(delegate: delegate);
  }

  Widget _builder(BuildContext context, int index) {
    final TreeNode<T> node = tree.nodes[index];

    Widget content = widget.builder(context, node);

    content = _getAnimationStatus(node.id).when<Widget>(
      idle: () => content,
      revealing: () => widget.transitionBuilder(content, _revealAnimation),
      concealing: () => widget.transitionBuilder(content, _concealAnimation),
    );

    return KeyedSubtree(
      key: Key(node.id),
      child: content,
    );
  }
}

/// Convenient extension methods to reduce code repetition.
extension _TreeDelegateExtension<T> on TreeDelegate<T> {
  String idOf(T item) => getUniqueId(item);
  void expand(T item) => setExpansion(item, true);
  void collapse(T item) => setExpansion(item, false);

  void collapseAll() => visitAllItems(collapse);

  void visitAllItems(OnTraverse<T> visit) {
    for (final T rootItem in rootItems) {
      visitBranch(rootItem, visit);
    }
  }

  void visitBranch(T item, OnTraverse<T> visit) {
    visit(item);
    for (final T child in getChildren(item)) {
      visitBranch(child, visit);
    }
  }

  void visitDescendants(T item, OnTraverse<T> visit) {
    for (final T descendant in getChildren(item)) {
      visit(descendant);
      visitDescendants(descendant, visit);
    }
  }

  void visitVisibleDescendants(T item, OnTraverse<T> visit) {
    if (getExpansion(item)) {
      for (final T descendant in getChildren(item)) {
        visit(descendant);
        visitVisibleDescendants(descendant, visit);
      }
    }
  }
}
