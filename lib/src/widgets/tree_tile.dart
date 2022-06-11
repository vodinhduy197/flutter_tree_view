import 'package:flutter/material.dart';

import '../foundation.dart';
import 'tree_indentation.dart';

/// A Simple widget to display [TreeNode]s on the [TreeView].
///
/// The [guide] can be used to define the indent decoration of this tile.
///
/// The [child] is usually composed of a [Row] with 2 widgets, the title of
/// [node] and a button to toggle the expansion state of [node].
///
/// Examples:
///
/// ```dart
/// TreeTile(
///   node: node,
///   child: Row(
///     children: [
///       const Expanded(
///         child: Text('My node Title'),
///       ),
///       ExpandIcon(
///         isExpanded: node.isExpanded,
///         onPressed: (_) => treeController.toggleItemExpansion(node.item),
///       ),
///     ],
///   ),
/// );
///
/// ```
/// Or whithout a button, using `onTap`:
///
/// ```dart
/// TreeTile(
///   node: node,
///   onTap: () => treeController.toggleItemExpansion(node.item),
///   child: const Text('My node Title'),
/// );
/// ```
///
/// See also:
///
///   * [FolderButton], a button that when tapped toggles between open and
///     closed folder icons, usefull for expanding/collapsing a [TreeTile];
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
///
///   * [IndentGuide], an interface for working with any type of decoration;
///   * [AbstractLineGuide], an interface for working with line painting;
class TreeTile<T> extends StatelessWidget {
  /// Creates a [TreeTile].
  const TreeTile({
    super.key,
    required this.child,
    required this.node,
    this.guide = const EmptyGuide(),
    this.focusNode,
    this.autofocus = false,
    this.focusColor,
    this.hoverColor,
    this.enableFeedback,
    this.mouseCursor,
    this.shape,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  });

  /// The widget to display to the side of [TreeIndentation].
  final Widget child;

  /// The tree node at this tile on the tree.
  ///
  /// This [node] holds important information for building the [TreeIndentation].
  final TreeNode<T> node;

  /// The guide that will be used by [TreeIndentation] to indent the levels of
  /// [node].
  ///
  /// See also:
  ///
  ///   * [EmptyGuide], which only indents nodes without painting;
  ///   * [ConnectingLineGuide], which paints lines with horizontal connections;
  ///   * [ScopingLineGuide], which paints straight lines for each level of the
  ///     tree;
  ///
  ///   * [IndentGuide], an interface for working with any type of decoration;
  ///   * [AbstractLineGuide], an interface for working with line painting;
  final IndentGuide guide;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The color of the ink response when the parent widget is focused. If this
  /// property is null then the focus color of the theme,
  /// [ThemeData.focusColor], will be used.
  ///
  /// See also:
  ///
  ///  * [hoverColor], the color of the hover highlight.
  final Color? focusColor;

  /// The color of the ink response when a pointer is hovering over it. If this
  /// property is null then the hover color of the theme,
  /// [ThemeData.hoverColor], will be used.
  ///
  /// See also:
  ///
  ///  * [focusColor], the color of the focus highlight.
  final Color? hoverColor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// See also:
  ///
  ///  * [Feedback] for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  ///
  /// If this property is null, [MaterialStateMouseCursor.clickable] will be used.
  final MouseCursor? mouseCursor;

  /// Defines the tile's [InkWell.customBorder].
  final ShapeBorder? shape;

  /// The clipping radius of the containing rect. This is effective only if
  /// [shape] is null.
  ///
  /// If this is null, it is interpreted as [BorderRadius.zero].
  final BorderRadius? borderRadius;

  /// Callback fired when the user taps on this [TreeTile].
  final VoidCallback? onTap;

  /// Callback fired when the user long presses this [TreeTile].
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      focusColor: focusColor,
      hoverColor: hoverColor,
      enableFeedback: enableFeedback,
      mouseCursor: mouseCursor,
      customBorder: shape,
      borderRadius: borderRadius,
      child: TreeIndentation<T>(
        node: node,
        guide: guide,
        child: child,
      ),
    );
  }
}
