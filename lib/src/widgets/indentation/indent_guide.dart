import 'dart:math' as math show pi;

import 'package:flutter/material.dart';

import '../../tree_data_source.dart' show TreeNode;

part 'lines/abstract_line_guide.dart';
part 'lines/connecting_line_guide.dart';
part 'lines/scoping_line_guide.dart';

/// An interface for configuring how to paint guides for a particular node on
/// the tree.
///
/// See also:
///
///   * [EmptyGuide], which only indents nodes without painting;
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
///
///   * [AbstractLineGuide], an interface for working with line painting;
abstract class IndentGuide {
  /// Allows subclasses to have constant constructors.
  const IndentGuide({
    required this.indent,
  }) : assert(indent >= 0.0, 'Negative indent values are not allowed.');

  /// Convenient factory constructor for creating an [EmptyGuide].
  const factory IndentGuide.empty([double indent]) = EmptyGuide;

  /// Convenient factory constructor for creating a [ScopingLineGuide].
  const factory IndentGuide.scopingLines({
    required double indent,
    Color color,
    double thickness,
    double horizontalOffset,
  }) = ScopingLineGuide;

  /// Convenient factory constructor for creating a [ConnectingLineGuide].
  const factory IndentGuide.connectingLines({
    required double indent,
    Color color,
    double thickness,
    bool roundCorners,
    bool onlyConnectToLastChild,
  }) = ConnectingLineGuide;

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

  /// Method used to wrap [child] in the desired decoration/painting.
  ///
  /// Subclasses must override this method if they want to customize whats
  /// shown inside of [TreeIndentation].
  ///
  /// See also:
  ///
  ///   * [AbstractLineGuide], an interface for working with line painting;
  Widget wrap<T>({
    required TreeNode<T> node,
    required bool isRtl,
    required Widget child,
  });
}

/// Defines configurations for adding simple indentation with no painting to a
/// node on the tree.
///
/// See also:
///
///   * [ConnectingLineGuide], which paints lines with horizontal connections;
///   * [ScopingLineGuide], which paints straight lines for each level of the tree;
///
///   * [IndentGuide], an interface for working with any type of decoration;
///   * [AbstractLineGuide], an interface for working with line painting;
class EmptyGuide extends IndentGuide {
  /// Creates an [EmptyGuide].
  const EmptyGuide([double indent = 24.0]) : super(indent: indent);

  @override
  Widget wrap<T>({
    required TreeNode<T> node,
    required bool isRtl,
    required Widget child,
  }) {
    return child;
  }
}
