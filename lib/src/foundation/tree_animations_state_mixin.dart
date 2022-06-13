import 'package:flutter/widgets.dart';

/// The default transition builder used by the tree view to animate the
/// expansion state changes of a node.
///
/// This function applies a [Curves.decelerate] to [animation] and uses it to
/// wrap [child] with fade and size transitions.
Widget defaultTreeTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  final Animation<double> sizeAnimation = CurvedAnimation(
    curve: Curves.decelerate,
    parent: animation,
  );

  return FadeTransition(
    opacity: Tween(begin: 0.5, end: 1.0).animate(animation),
    child: SizeTransition(
      sizeFactor: sizeAnimation,
      child: child,
    ),
  );
}

/// An animation mixin used by [TreeControllerStateMixin] to animate the
/// expansion state changes of tree nodes.
mixin TreeAnimationsStateMixin<S extends StatefulWidget>
    on State<S>, TickerProviderStateMixin<S> {
  late final AnimationController _revealAnimationController;
  late final AnimationController _concealAnimationController;

  /// The animation played when a node is expanded.
  Animation<double> get revealAnimation => _revealAnimationController.view;

  /// The animation played when a node is collapsed.
  Animation<double> get concealAnimation => _concealAnimationController.view;

  /// The duration in which to play [revealAnimation].
  Duration get revealDuration => const Duration(milliseconds: 300);

  /// The duration in which to play [concealAnimation].
  Duration get concealDuration => const Duration(milliseconds: 150);

  /// Starts animating the [revealAnimation].
  @protected
  void startRevealAnimation() => _revealAnimationController.forward(from: 0.0);

  /// Starts animating the [concealAnimation].
  ///
  /// This method will start [concealAnimation] and call [whenComplete] when
  /// the animation is done.
  @protected
  void startConcealAnimation(VoidCallback whenComplete) {
    _concealAnimationController
        .reverse(from: 1.0)
        .whenCompleteOrCancel(whenComplete);
  }

  @override
  void initState() {
    super.initState();
    _revealAnimationController = AnimationController(
      vsync: this,
      duration: revealDuration,
    );

    _concealAnimationController = AnimationController(
      vsync: this,
      duration: concealDuration,
    );
  }

  @override
  void dispose() {
    _revealAnimationController.dispose();
    _concealAnimationController.dispose();
    super.dispose();
  }
}
