import 'package:flutter/widgets.dart';

/// An animation mixin used by [TreeControllerMixin] to animate the expansion
/// state change of tree nodes.
mixin TreeAnimationsMixin<S extends StatefulWidget>
    on State<S>, SingleTickerProviderStateMixin<S> {
  late final AnimationController _animationController;

  /// The animation used to expand/collapse nodes on the tree.
  Animation<double> get animation => _animationController.view;

  /// The duration in which to play [animation].
  Duration get duration => const Duration(milliseconds: 300);

  /// Start animating forward.
  ///
  /// This method will play [animation] and call [whenComplete] when the
  /// animation is done playing.
  @protected
  void startAnimating(VoidCallback whenComplete) {
    _animationController.forward(from: 0.0).whenComplete(whenComplete);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: duration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
