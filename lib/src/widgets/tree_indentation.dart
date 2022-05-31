import 'package:flutter/material.dart';

import '../tree_data_source.dart';
import '../tree_view.dart';
import 'indentation/indent_guide.dart';

/// Widget responsible for indenting tree nodes and painting guides (if needed).
class TreeIndentation<T> extends StatelessWidget {
  /// Creates a [TreeIndentation].
  const TreeIndentation({
    Key? key,
    required this.node,
    required this.guide,
    required this.child,
  }) : super(key: key);

  /// The tree node that should be used to paint guides for.
  final TreeNode<T> node;

  /// The actual guide configuration to use when painting the guide of [node].
  ///
  /// The [IndentGuide] class provides named constructors for easily finding all
  /// available indent guide types.
  ///
  /// See also:
  ///
  ///   * [EmptyGuide], which only indents nodes without painting;
  ///   * [ConnectingLineGuide], which paints lines with horizontal connections;
  ///   * [ScopingLineGuide], which paints straight lines for each level of the
  ///     tree;
  ///
  ///   * [IndentGuide], an interface for working with any type of painting;
  ///   * [LineGuide], an interface for working with line painting;
  final IndentGuide guide;

  /// The widget that is going to be displayed to the side of indentation.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (node.isRoot) {
      return child;
    }

    return guide.wrap<T>(
      node: node,
      isRtl: SliverTree.of(context).isRtl,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: node.level * guide.indent),
        child: child,
      ),
    );
  }
}
