import 'dart:math' as math show pi;

import 'package:flutter/material.dart';

import 'tree_data_source.dart';

/// Widget responsible for indenting tree nodes and painting guides (if needed).
class TreeIndentation<T> extends StatelessWidget {
  /// Creates a [TreeIndentation].
  const TreeIndentation({
    Key? key,
    required this.node,
    required this.guide,
    this.height,
    this.child,
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

  /// The height used for painting the [guide].
  ///
  /// If [TreeIndentation] is given unbounded height and [height] is null,
  /// the painting algorithm will not work properly, specially if using a
  /// [LineGuide].
  ///
  /// Alternatively to setting a value to this property, you could make sure
  /// that [TreeIndentation] is wrapped by any sort of [ConstrainedBox] parent
  /// that has bounded height.
  final double? height;

  /// An optional widget to place inside the tree indentation.
  ///
  /// Checkout the [Align] widget to place [child] exactly where wanted.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double indentation = node.level * guide.indent;

    final Widget content = SizedBox(
      width: indentation,
      height: height,
      child: child,
    );

    if (node.isRoot || guide is EmptyGuide) {
      return content;
    }

    return CustomPaint(
      child: content,
      painter: IndentGuidePainter<T>(
        node: node,
        guide: guide,
        isRtl: Directionality.maybeOf(context) == TextDirection.rtl,
      ),
    );
  }
}

/// A [CustomPainter] responsible for painting the [IndentGuide] of [TreeIndentation].
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
class IndentGuidePainter<T> extends CustomPainter {
  /// Creates a [IndentGuidePainter].
  const IndentGuidePainter({
    required this.node,
    required this.guide,
    required this.isRtl,
  });

  /// The actual node to paint guides for.
  final TreeNode<T> node;

  /// The configuration for painting guides for [node].
  final IndentGuide guide;

  /// Flag that indicates if `Directionality.maybeOf(context) == TextDirection.rtl`.
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    guide.paint<T>(canvas, size, node, isRtl);
  }

  @override
  bool shouldRepaint(covariant IndentGuidePainter<T> oldDelegate) {
    return oldDelegate.node.level != node.level ||
        oldDelegate.node.isLastSibling != node.isLastSibling ||
        oldDelegate.guide != guide;
  }
}

/// An interface for configuring how to paint guides for a particular node on
/// the tree.
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
abstract class IndentGuide {
  /// Allows subclasses to have constant constructors.
  const IndentGuide({
    required this.indent,
  }) : assert(indent >= 0.0, 'Negative indent values are not allowed.');

  /// Convenient factory method for creating an [EmptyGuide].
  const factory IndentGuide.empty(double indent) = EmptyGuide;

  /// The amount of indent to apply for each level of the tree.
  ///
  /// Example:
  ///
  /// ```dart
  /// final TreeNode<T> node;
  /// final IndentGuide guide;
  /// final double indentation = node.level * guide.indent;
  /// ```
  final double indent;

  /// Deferred paint method that subclasses must override.
  ///
  /// Used by [IndentGuidePainter] to paint the guides for [node].
  void paint<T>(Canvas canvas, Size size, TreeNode<T> node, bool isRtl);
}

/// Defines configurations for adding simple indentation with no painting to a
/// node on the tree.
///
/// See also:
///
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the
///     tree;
///
///   * [IndentGuide], an interface for working with any type of painting;
///   * [LineGuide], an interface for working with line painting;
class EmptyGuide extends IndentGuide {
  /// Creates an [EmptyGuide].
  const EmptyGuide(double indent) : super(indent: indent);

  @override
  void paint<T>(Canvas canvas, Size size, TreeNode<T> node, bool isRtl) {
    assert(() {
      throw Exception('EmptyGuide has no paint.');
    }());
  }
}

/// An interface for configuring how to paint line guides for a particular node
/// on the tree.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the
///     tree;
///
///   * [IndentGuide], an interface for working with any type of painting;
abstract class LineGuide extends IndentGuide {
  /// Constructor with requried parameters for building the indent line guides.
  const LineGuide({
    required double indent,
    required this.color,
    required this.thickness,
  })  : assert(
          indent >= thickness,
          '`indent` must be greater than or equal to `thickness`.',
        ),
        super(indent: indent);

  /// The color to use when painting the lines on the canvas.
  final Color color;

  /// The width each line should have.
  final double thickness;

  /// Called by [paint] for building the [Path] of the [node]'s lines.
  ///
  /// Should return a new [Path] composed by all vertical lines needed by [node].
  Path buildPath<T>(TreeNode<T> node, double height, bool isRtl);

  /// Callback responsible for creating the [Paint] object that will be used by
  /// the [paint] method to paint the [Path] built from [buildPath].
  ///
  /// Override this method if you need a different configuration for your [Paint].
  Paint createPaint() {
    return Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
  }

  @override
  void paint<T>(Canvas canvas, Size size, TreeNode<T> node, bool isRtl) {
    final Paint paint = createPaint();
    Path path = buildPath<T>(node, size.height, isRtl);

    if (isRtl) {
      final Matrix4 mirrored = Matrix4.identity()
        ..translate(size.width)
        ..rotateY(math.pi);

      path = path.transform(mirrored.storage);
    }

    canvas.drawPath(path, paint);
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

/// Simple configuration for painting vertical lines that have a horizontal
/// connection to it's node.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ScopingLineGuide], which paints straight lines for each level of the
///     tree;
///
///   * [IndentGuide], an interface for working with any type of painting;
///   * [LineGuide], an interface for working with line painting;
class ConnectingLineGuide extends LineGuide {
  /// Creates a [ConnectingLineGuide].
  const ConnectingLineGuide({
    required double indent,
    Color color = Colors.grey,
    double thickness = 2.0,
    this.roundCorners = false,
    this.onlyConnectToLastChild = false,
  }) : super(indent: indent, color: color, thickness: thickness);

  /// A flag that is used to paint rounded corners when connecting vertical
  /// lines to horizontal lines.
  final bool roundCorners;

  /// A flag that is used to restrict the painting of horizontal lines to the
  /// last child of a node, every other node will only have the vertical line.
  final bool onlyConnectToLastChild;

  @override
  Path buildPath<T>(TreeNode<T> node, double height, bool isRtl) {
    final Path path = Path();
    final double halfIndent = indent * 0.5;

    final List<bool> skippedLevels = node.buildSkippedLevels();

    for (int level = 1; level <= node.level; level++) {
      if (skippedLevels[level]) {
        // The ancestor at this level does not have a next sibling, so there
        // should not be a line at this level.
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

/// Simple configuration for painting vertical lines at every level of the tree.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///
///   * [IndentGuide], an interface for working with any type of painting;
///   * [LineGuide], an interface for working with line painting;
class ScopingLineGuide extends LineGuide {
  /// Creates a [ScopingLineGuide].
  const ScopingLineGuide({
    required double indent,
    Color color = Colors.grey,
    double thickness = 2.0,
    this.horizontalOffset = 1.0,
  })  : assert(
          0.0 <= horizontalOffset && horizontalOffset <= 1.0,
          '`horizontalOffset` must be between `0.0` and `1.0`.',
        ),
        super(indent: indent, color: color, thickness: thickness);

  /// Defines where inside indent to start painting the vertical lines.
  /// A line offset is calculated from [indent] and [horizontalOffset]
  /// like follows:
  ///
  /// ```dart
  /// final double offset = indent - (indent * horizontalOffset);
  /// ```
  ///
  /// Must be a value between `0.0` and `1.0`.
  ///
  /// If using right-to-left directionality, the [horizontalOffset] will
  /// automatically adjust itself.
  ///
  /// Example values:
  ///   - `horizontalOffset = 1.0`, paints lines at the **end** of each indent;
  ///   - `horizontalOffset = 0.5`, paints lines in the **center** of each indent;
  ///   - `horizontalOffset = 0.0`, paints lines in the **start** of each indent;
  final double horizontalOffset;

  @override
  Path buildPath<T>(TreeNode<T> node, double height, bool isRtl) {
    final Path path = Path();

    final double origin = isRtl ? 1.0 - horizontalOffset : horizontalOffset;
    final double offset = indent - (indent * origin);

    for (int level = 1; level <= node.level; level++) {
      final double x = indent * level - offset;
      path
        ..moveTo(x, height)
        ..lineTo(x, 0);
    }

    return path;
  }

  /// Creates a copy of this indent guide but with the given fields replaced
  /// with the new values.
  ScopingLineGuide copyWith({
    double? indent,
    Color? color,
    double? thickness,
    double? horizontalOffset,
  }) {
    return ScopingLineGuide(
      indent: indent ?? this.indent,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
    );
  }

  @override
  int get hashCode => Object.hashAll([
        indent,
        color,
        thickness,
        horizontalOffset,
      ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ScopingLineGuide &&
        other.indent == indent &&
        other.color == color &&
        other.thickness == thickness &&
        other.horizontalOffset == horizontalOffset;
  }
}
