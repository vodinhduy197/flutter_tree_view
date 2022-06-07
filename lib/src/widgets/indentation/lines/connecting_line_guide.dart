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

    for (final int level in node.levelsWithLineGuides) {
      final double x = indent * level - halfIndent;
      path
        ..moveTo(x, height)
        ..lineTo(x, 0);
    }

    // Return early since no connection should be painted.
    final bool skipConnection = onlyConnectToLastChild && node.hasNextSibling;
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
      if (node.hasNextSibling) {
        path.moveTo(connectionStart, halfHeight);
      } else {
        // Add half vertical line
        path.lineTo(connectionStart, halfHeight);
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
