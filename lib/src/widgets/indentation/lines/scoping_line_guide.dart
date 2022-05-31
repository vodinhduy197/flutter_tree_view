part of '../indent_guide.dart';

/// Simple configuration for painting vertical lines at every level of the tree.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///
///   * [IndentGuide], an interface for working with any type of decoration;
///   * [AbstractLineGuide], an interface for working with line painting;
class ScopingLineGuide extends AbstractLineGuide {
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
  Path buildPath<T>({
    required TreeNode<T> node,
    required double height,
    required bool isRtl,
  }) {
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
