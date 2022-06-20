import 'package:flutter/widgets.dart';

/// The default transition builder used by the tree view to animate the
/// expansion state changes of a node.
///
/// Wraps [child] in [FadeTransition] and [SizeTransition].
Widget defaultTreeTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  return FadeTransition(
    opacity: animation,
    child: SizeTransition(
      sizeFactor: animation,
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

  late Animation<double> _revealAnimation;
  late Animation<double> _concealAnimation;

  /// The animation played for the descendants of a node when it is expanded.
  Animation<double> get revealAnimation => _revealAnimation;

  /// The animation played for the descendants of a node when it is collapsed.
  Animation<double> get concealAnimation => _concealAnimation;

  /// The duration used by [revealAnimation].
  ///
  /// Defaults to `Duration(milliseconds: 300)`.
  Duration get revealDuration => const Duration(milliseconds: 300);

  /// The [Curve] used by [revealAnimation].
  ///
  /// Defaults to `Curves.decelerate`.
  Curve get revealCurve => Curves.decelerate;

  /// The duration used by [concealAnimation].
  ///
  /// Defaults to [revealDuration] which defaults to `Duration(milliseconds: 300)`.
  Duration get concealDuration => revealDuration;

  /// The [Curve] used by [concealAnimation].
  ///
  /// Defaults to `Curves.ease`.
  Curve get concealCurve => Curves.ease;

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

  void _setupAnimations() {
    _revealAnimation = CurveTween(
      curve: revealCurve,
    ).animate(_revealAnimationController);

    _concealAnimation = CurveTween(
      curve: concealCurve,
    ).animate(_concealAnimationController);
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

    _setupAnimations();
  }

  @override
  void didUpdateWidget(covariant S oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revealAnimationController.duration = revealDuration;
    _concealAnimationController.duration = concealDuration;
    _setupAnimations();
  }

  @override
  void dispose() {
    _revealAnimationController.dispose();
    _concealAnimationController.dispose();
    super.dispose();
  }
}
