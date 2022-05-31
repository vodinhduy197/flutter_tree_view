part of '../indent_guide.dart';

/// An interface for configuring how to paint line guides for a particular node
/// on the tree.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
///
///   * [IndentGuide], an interface for working with any type of decoration;
abstract class AbstractLineGuide extends IndentGuide {
  /// Constructor with requried parameters for building the indent line guides.
  const AbstractLineGuide({
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

  /// Subclasses must implement this method to define their line paths.
  ///
  /// Should return a new [Path] composed by all lines needed by [node].
  Path buildPath<T>({
    required TreeNode<T> node,
    required double height,
    required bool isRtl,
  });

  /// Responsible for creating the [Paint] object that will be used to paint
  /// the [Path] built from [buildPath].
  ///
  /// Override this method if you need a different [Paint] configuration.
  Paint createPaint() {
    return Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
  }

  @override
  Widget wrap<T>({
    required TreeNode<T> node,
    required bool isRtl,
    required Widget child,
  }) {
    return CustomPaint(
      painter: _LineGuidePainter<T>(
        node: node,
        guide: this,
        isRtl: isRtl,
      ),
      child: child,
    );
  }
}

class _LineGuidePainter<T> extends CustomPainter {
  const _LineGuidePainter({
    required this.node,
    required this.guide,
    required this.isRtl,
  });

  final TreeNode<T> node;
  final AbstractLineGuide guide;
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = guide.createPaint();

    Path path = guide.buildPath<T>(
      node: node,
      height: size.height,
      isRtl: isRtl,
    );

    if (isRtl) {
      final Matrix4 mirrored = Matrix4.identity()
        ..translate(size.width)
        ..rotateY(math.pi);

      path = path.transform(mirrored.storage);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineGuidePainter<T> oldDelegate) {
    return oldDelegate.node.level != node.level ||
        oldDelegate.node.isLastSibling != node.isLastSibling ||
        oldDelegate.guide != guide;
  }
}
