import 'package:flutter/material.dart';

import '../foundation.dart' show TreeNode;
import 'indentation/indent_guide.dart';
import 'tree_view.dart';

export 'indentation/indent_guide.dart';

/// Widget responsible for indenting tree nodes and painting guides (if needed).
class TreeIndentation<T> extends StatelessWidget {
  /// Creates a [TreeIndentation].
  const TreeIndentation({
    super.key,
    required this.node,
    required this.guide,
    required this.child,
  });

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
  ///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
  ///
  ///   * [IndentGuide], an interface for working with any type of decoration;
  ///   * [AbstractLineGuide], an interface for working with line painting;
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
