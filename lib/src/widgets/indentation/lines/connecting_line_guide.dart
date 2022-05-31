part of '../indent_guide.dart';

/// Simple configuration for painting vertical lines that have a horizontal
/// connection to it's node.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
///
///   * [IndentGuide], an interface for working with any type of decoration;
///   * [AbstractLineGuide], an interface for working with line painting;
class ConnectingLineGuide extends AbstractLineGuide {
  /// Creates a [ConnectingLineGuide].
  const ConnectingLineGuide({
    super.indent,
    super.color,
    super.thickness,
    this.roundCorners = false,
    this.onlyConnectToLastChild = false,
  });

  /// A flag that is used to paint rounded corners when connecting vertical
  /// lines to horizontal lines.
  final bool roundCorners;

  /// A flag that is used to restrict the painting of horizontal lines to the
  /// last child of a node, every other node will only have the vertical line.
  final bool onlyConnectToLastChild;

  @override
  Path buildPath<T>({
    required TreeNode<T> node,
    required double height,
    required bool isRtl,
  }) {
    final Path path = Path();
    final double halfIndent = indent * 0.5;

    final List<bool> skippedLevels = node.buildSkippedLevels();

    for (int level = 1; level <= node.level; level++) {
      if (skippedLevels[level]) {
        // The ancestor at this level does not have a next sibling, so there
        // should not be a straight line at this level.
        continue;
      }

      final double x = indent * level - halfIndent;
      path
        ..moveTo(x, height)
        ..lineTo(x, 0);
    }

    // Return early since no connection should be painted.
    final bool skipConnection = onlyConnectToLastChild && !node.isLastSibling;
    if (skipConnection) {
      return path;
    }

    final double connectionEnd = indent * node.level;
    final double connectionStart = connectionEnd - halfIndent;
    final double halfHeight = height * 0.5;

    path.moveTo(connectionStart, 0);

    if (roundCorners) {
      path.quadraticBezierTo(
        connectionStart,
        halfHeight,
        connectionEnd,
        halfHeight,
      );
    } else {
      if (node.isLastSibling) {
        // Add half vertical line
        path.lineTo(connectionStart, halfHeight);
      } else {
        path.moveTo(connectionStart, halfHeight);
      }

      path.lineTo(connectionEnd, halfHeight);
    }

    return path;
  }

  /// Creates a copy of this indent guide but with the given fields replaced
  /// with the new values.
  ConnectingLineGuide copyWith({
    double? indent,
    Color? color,
    double? thickness,
    bool? roundCorners,
    bool? onlyConnectToLastChild,
  }) {
    return ConnectingLineGuide(
      indent: indent ?? this.indent,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      roundCorners: roundCorners ?? this.roundCorners,
      onlyConnectToLastChild:
          onlyConnectToLastChild ?? this.onlyConnectToLastChild,
    );
  }

  @override
  int get hashCode => Object.hashAll([
        indent,
        color,
        thickness,
        roundCorners,
        onlyConnectToLastChild,
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ConnectingLineGuide &&
        other.indent == indent &&
        other.color == color &&
        other.thickness == thickness &&
        other.roundCorners == roundCorners &&
        other.onlyConnectToLastChild == onlyConnectToLastChild;
  }
}

extension _LinesX<T> on TreeNode<T> {
  /// Returns a list with each index being a level on the path of this node.
  /// The boolean indicates wheter that level (index) should be skipped when
  /// painting lines.
  ///
  /// Index `0` is ignored when painting, so its value doesn't matter.
  ///
  /// Example:
  ///
  /// ```dart
  /// final TreeNode firstChild = TreeNode();
  /// final TreeNode lastChild = TreeNode();
  /// final TreeNode root = TreeNode(
  ///   chilren: [
  ///     TreeNode(), // (isLastSibling = false)
  ///     TreeNode(), // (isLastSibling = false)
  ///     TreeNode( // (isLastSibling = true)
  ///       children: [
  ///         firstChild, // (isLastSibling = false)
  ///         lastChild, // (isLastSibling = true)
  ///       ]
  ///     ),
  ///   ]
  /// )
  ///
  /// print(lasChild.buildSkippedLevels()); // [false, true, true]
  /// print(firstChild.buildSkippedLevels()); // [false, true, false];
  /// ```
  ///
  /// Then when painting lines, where `buildSkippedLevels()[level] == false`
  /// a straight line will be painted, indicating there's siblings next, if
  /// `true`, this level is going to be skipped, so no line is painted at that
  /// level.
  List<bool> buildSkippedLevels() {
    // In short, a skipped level means that the ancestor at this level (index
    // on the list) is the last child of it's parent, therefore no vertical line
    // should be painted at that level (index) offset.
    return [
      ...?parent?.buildSkippedLevels(),
      isLastSibling,
    ];
  }
}
