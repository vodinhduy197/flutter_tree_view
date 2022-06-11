import 'package:flutter/widgets.dart';

/// An animation mixin used by [TreeControllerMixin] to animate the expansion
/// state change of tree nodes.
mixin TreeAnimationsStateMixin<S extends StatefulWidget>
    on State<S>, TickerProviderStateMixin<S> {
  late final AnimationController _expandAnimationController;
  late final AnimationController _collapseAnimationController;

  /// The animation used to expand nodes on the tree.
  Animation<double> get expandAnimation => _expandAnimationController.view;

  /// The animation used to collapse nodes on the tree.
  Animation<double> get collapseAnimation => _collapseAnimationController.view;

  /// The duration in which to play [expandAnimation].
  Duration get expandDuration => const Duration(milliseconds: 300);

  /// The duration in which to play [collapseAnimation].
  Duration get collapseDuration => const Duration(milliseconds: 150);

  /// Start the expand animation.
  @protected
  void startExpandAnimation() => _expandAnimationController.forward(from: 0.0);

  /// Start the collapse animation.
  ///
  /// This method will start [collapseAnimation] and call [whenComplete] when
  /// the animation is done.
  @protected
  void startCollapseAnimation(VoidCallback whenComplete) {
    _collapseAnimationController
        .reverse(from: 1.0)
        .whenCompleteOrCancel(whenComplete);
  }

  @override
  void initState() {
    super.initState();
    _expandAnimationController = AnimationController(
      vsync: this,
      duration: expandDuration,
    );

    _collapseAnimationController = AnimationController(
      vsync: this,
      duration: collapseDuration,
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    _collapseAnimationController.dispose();
    super.dispose();
  }
}
