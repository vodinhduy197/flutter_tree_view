import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import 'tree_controller.dart';
import 'tree_data_source.dart';

/// Signature for a function that creates a widget for a given node, e.g., in a
/// tree.
///
/// Used by [SliverTree] and [TreeView] to build widgets for [TreeNode]s.
typedef TreeNodeWidgetBuilder<T> = Widget Function(
  BuildContext context,
  TreeNode<T> node,
);

/// A simple, fancy and highly customizable hierarchy visualization Widget.
///
/// This widget wraps a [SliverTree] in a [CustomScrollView] with some defaults.
///
/// See also:
///
///  * [SliverTree], which could be used to build more sophisticated scrolling
///    experiences with [CustomScrollView].
class TreeView<T> extends StatefulWidget {
  /// Creates a [TreeView].
  ///
  /// Take a look at [TreeNodeTile] for your [nodeBuilder].
  const TreeView({
    Key? key,
    required this.controller,
    required this.nodeBuilder,
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
  }) : super(key: key);

  /// The controller responsible for updating the state of this [TreeView].
  ///
  /// A [TreeController] can be used to dinamically update the state of the
  /// [TreeView] when needed. Simply update your data at your [TreeDataSource]
  /// and call [TreeController.rebuild] to update the tree and rebuild the UI.
  final TreeController<T> controller;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  final TreeNodeWidgetBuilder<T> nodeBuilder;

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

  /// The [TreeView] state from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [TreeView] ancestor widget in the widget tree at the given
  /// context, then this will return null.
  ///
  /// Typical usage is as follows:
  ///
  /// TreeViewState? treeState = TreeView.maybeOf<T>(context);
  ///
  /// See also:
  ///
  ///  * [of], which will throw in debug mode if no [TreeView] ancestor widget
  ///   is in the widget tree.
  static TreeViewState<T>? maybeOf<T>(BuildContext context) {
    return context.findAncestorStateOfType<TreeViewState<T>>();
  }

  /// The [TreeView] state from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [TreeView] ancestor widget in the widget tree at the given
  /// context, then this will throw in debug mode.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TreeViewState treeState = TreeView.of<T>(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which will return null if no [TreeView] ancestor widget is
  ///    in the widget tree.
  static TreeViewState<T> of<T>(BuildContext context) {
    final TreeViewState<T>? instance = maybeOf<T>(context);
    assert(() {
      if (instance == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'TreeView.of() called with a context that does not contain a TreeView.',
          ),
          ErrorDescription(
            'No TreeView ancestor could be found starting from the context that was passed to TreeView.of<T>().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the TreeView.',
          ),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return instance!;
  }

  @override
  TreeViewState<T> createState() => TreeViewState<T>();
}

/// An object that holds the state of a [TreeView].
///
/// The current [TreeViewState] instance can be acquired in several ways:
///   - Using a [GlobalKey] in your [TreeView];
///   - Calling `TreeView.of<T>(context)` (throws if not found);
///   - Calling `TreeView.maybeOf<T>(context)` (nullable return);
class TreeViewState<T> extends State<TreeView<T>> {
  /// The [TreeController] that's currently attached to this tree widget.
  TreeController<T> get controller => widget.controller;

  final GlobalKey<SliverTreeState<T>> _sliverTreeKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: Axis.vertical,
      reverse: false,
      controller: widget.scrollController,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      slivers: [
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: SliverTree<T>(
            key: _sliverTreeKey,
            controller: controller,
            nodeBuilder: widget.nodeBuilder,
            itemExtent: widget.itemExtent,
            prototypeItem: widget.prototypeItem,
          ),
        ),
      ],
    );
  }
}

/// A simple, fancy and highly customizable hierarchy visualization Widget.
///
/// This widget is responsible for working with [TreeController] to display the
/// tree built from [TreeDataSource].
///
/// Use inside [CustomScrollView].
///
/// See also:
///
///  * [TreeView], which already covers some boilerplate for building a nice
///    tree view.
class SliverTree<T> extends StatefulWidget {
  /// Creates a [SliverTree].
  const SliverTree({
    Key? key,
    required this.controller,
    required this.nodeBuilder,
    this.itemExtent,
    this.prototypeItem,
  })  : assert(
          itemExtent == null || prototypeItem == null,
          'You can only pass itemExtent or prototypeItem, not both',
        ),
        super(key: key);

  /// The controller responsible for updating the state of this [SliverTree].
  ///
  /// A [TreeController] can be used to dinamically update the state of the
  /// [TreeView] when needed. Simply update your data at your [TreeDataSource]
  /// and call [TreeController.rebuild] to update the tree and rebuild the UI.
  final TreeController<T> controller;

  /// Callback used to map your data into widgets.
  ///
  /// The `TreeNode<T> node` parameter contains important information about the
  /// current tree context of the particular [TreeNode.item] that it holds.
  final TreeNodeWidgetBuilder<T> nodeBuilder;

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
  ///    is in the widget tree.
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
  ///  * [maybeOf], which will return null if no [SliverTree] ancestor widget is
  ///    in the widget tree.
  static SliverTreeState<T> of<T>(BuildContext context) {
    final SliverTreeState<T>? instance = maybeOf<T>(context);
    assert(() {
      if (instance == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'SliverTree.of() called with a context that does not contain a SliverTree.',
          ),
          ErrorDescription(
            'No SliverTree ancestor could be found starting from the context that was passed to SliverTree.of().',
          ),
          ErrorHint(
            'This can happen when the context provided is from the same StatefulWidget that '
            'built the SliverTree.',
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
/// The current [SlivertreeState] instance can be acquired in several ways:
///   - Using a [GlobalKey] in your [SliverTree];
///   - Calling `SliverTree.of<T>(context)` (throws if not found);
///   - Calling `SliverTree.maybeOf<T>(context)` (nullable return);
class SliverTreeState<T> extends State<SliverTree<T>> {
  /// The [TreeController] that's currently attached to this tree widget.
  TreeController<T> get controller => widget.controller;

  /// Determines if [Directionality.maybeOf] is set to [TextDirection.rtl].
  bool get isRtl => _isRtl;
  bool _isRtl = false;

  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    controller.addListener(_rebuild);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SliverChildBuilderDelegate delegate = SliverChildBuilderDelegate(
      _nodeBuilder,
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

  Widget _nodeBuilder(BuildContext context, int index) {
    final TreeNode<T> node = controller.nodeAt(index);
    return widget.nodeBuilder(context, node);
  }
}
