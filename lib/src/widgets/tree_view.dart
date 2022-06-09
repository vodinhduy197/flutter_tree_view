import 'dart:math' as math show max;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../foundation.dart';

/// Signature for a function that creates a widget for a given node, e.g., in a
/// tree.
typedef TreeNodeWidgetBuilder<T> = Widget Function(
  BuildContext context,
  TreeNode<T> node,
);

/// Signature for a function that takes a widget and an animation and applies
/// transitions if needed.
typedef ExpandTransitionBuilder = Widget Function(
  Widget child,
  Animation<double>,
);

/// A simple, fancy and highly customizable hierarchy visualization Widget.
///
/// This widget wraps a [SliverTree] in a [CustomScrollView] with some defaults.
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
    required this.controller,
    required this.builder,
    this.expandTransitionBuilder = kDefaultExpandTransitionBuilder,
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

  /// The controller responsible for updating the state of this [TreeView].
  ///
  /// A [TreeController] can be used to dinamically update the state of the
  /// [TreeView] when needed.
  /// Simply update your data and call [TreeController.rebuild] which will use
  /// its finder callbacks to update the tree and then rebuild the view.
  final TreeController<T> controller;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  ///
  /// Checkout the [TreeTile] widget.
  final TreeNodeWidgetBuilder<T> builder;

  /// Callback used to add animations to the expansion of a branch.
  ///
  /// When an item is expanded, all its descendants that will be revealed are
  /// wrapped by this callback.
  ///
  /// See also:
  ///
  ///   * [kDefaultExpandTransitionBuilder] that uses some standard slide and
  ///     grow transitions.
  final ExpandTransitionBuilder expandTransitionBuilder;

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
            controller: controller,
            builder: builder,
            expandTransitionBuilder: expandTransitionBuilder,
            itemExtent: itemExtent,
            prototypeItem: prototypeItem,
          ),
        ),
      ],
    );
  }
}

/// A simple, fancy and highly customizable hierarchy visualization Widget.
///
/// This widget is responsible for working with [TreeController] to display the
/// tree.
///
/// Use inside [CustomScrollView].
///
/// See also:
///
///  * [TreeView], which already covers some of the [CustomScrollView] boilerplate.
class SliverTree<T> extends StatefulWidget {
  /// Creates a [SliverTree].
  const SliverTree({
    super.key,
    required this.controller,
    required this.builder,
    this.expandTransitionBuilder = kDefaultExpandTransitionBuilder,
    this.itemExtent,
    this.prototypeItem,
  }) : assert(
          itemExtent == null || prototypeItem == null,
          'You can only pass itemExtent or prototypeItem, not both',
        );

  /// The controller responsible for updating the state of this [SliverTree].
  ///
  /// A [TreeController] can be used to dinamically update the state of the
  /// [TreeView] when needed.
  /// Simply update your data and call [TreeController.rebuild] which will use
  /// its finder callbacks to update the tree and then rebuild the view.
  final TreeController<T> controller;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  final TreeNodeWidgetBuilder<T> builder;

  /// Callback used to add animations to the expansion of a branch.
  ///
  /// When an item is expanded, all its descendants that will be revealed are
  /// wrapped by this callback.
  ///
  /// See also:
  ///
  ///   * [kDefaultExpandTransitionBuilder] that uses some standard slide and
  ///     grow transitions.
  final ExpandTransitionBuilder expandTransitionBuilder;

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
  /// SliverTreeState? treeState = SliverTree.maybeOf<T>(context);
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
  /// SliverTreeState treeState = SliverTree.of<T>(context);
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

/// An object that holds the state of a [SliverTree].
///
/// The current [SliverTreeState] instance can be acquired in several ways:
///   - Using a [GlobalKey] in your [SliverTree];
///   - Calling `SliverTree.of<T>(context)` (throws if not found);
///   - Calling `SliverTree.maybeOf<T>(context)` (nullable return);
class SliverTreeState<T> extends State<SliverTree<T>>
    with SingleTickerProviderStateMixin {
  /// The [TreeController] that's currently attached to this tree widget.
  TreeController<T> get controller => widget.controller;

  /// Determines if [Directionality.maybeOf] is set to [TextDirection.rtl].
  bool get isRtl => _isRtl;
  bool _isRtl = false;

  /// The ancestor scrollable state this sliver is attached to.
  ScrollableState? get scrollable => Scrollable.of(context);

  void _rebuild() {
    bool shouldAnimate = false;

    setState(() {
      shouldAnimate = controller.shouldPlayExpansionAnimation;
    });

    if (shouldAnimate) {
      _animationController
          .forward(from: 0.0)
          .whenComplete(controller.onDoneAnimating);
    }
  }

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    controller.addListener(_rebuild);

    _animationController = AnimationController(
      vsync: this,
      duration: kThemeAnimationDuration,
    );
  }

  @override
  void didUpdateWidget(covariant SliverTree<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_rebuild);
      controller.addListener(_rebuild);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
  }

  @override
  void dispose() {
    controller.removeListener(_rebuild);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SliverChildBuilderDelegate delegate = SliverChildBuilderDelegate(
      _builder,
      childCount: controller.treeSize,
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
    final TreeNode<T> node = controller.nodeAt(index);

    late final Widget child = widget.builder(context, node);

    if (controller.isItemExpanding(node.item)) {
      return widget.expandTransitionBuilder(
        child,
        _animationController.view,
      );
    }

    return child;
  }
}

/// The default transition builder used by the tree view for when a branch is
/// revealed (node is expanded so descendants animate in).
Widget kDefaultExpandTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  final Animation<double> sizeAnimation = CurvedAnimation(
    curve: Curves.decelerate,
    parent: animation,
  );

  final Animation<Offset> slideAnimation = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(sizeAnimation);

  return ClipRect(
    child: SlideTransition(
      position: slideAnimation,

      /// workaround for [SizeTransition] messing with the width of [child]
      child: AnimatedBuilder(
        animation: sizeAnimation,
        builder: (BuildContext context, Widget? child) {
          return Align(
            alignment: const AlignmentDirectional(-1.0, 0.0),
            heightFactor: math.max(sizeAnimation.value, 0.0),
            child: child,
          );
        },
        child: child,
      ),
    ),
  );
}
