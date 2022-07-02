import 'package:flutter/material.dart';

/// A simple widget that animates between open/closed folder icons depending on
/// the [isOpen] flag.
class FolderButton extends StatelessWidget {
  /// Creates a [FolderButton].
  const FolderButton({
    super.key,
    required this.isOpen,
    this.openedIcon = const Icon(Icons.folder_open),
    this.closedIcon = const Icon(Icons.folder),
    this.padding = const EdgeInsets.all(8.0),
    this.color,
    this.iconSize,
    this.splashRadius,
    this.tooltip,
    this.onPressed,
  });

  /// The icon shown when [isOpen] is set to `true`.
  ///
  /// Defaults to `const Icon(Icons.folder_open)`.
  final Widget openedIcon;

  /// The icon shown when [isOpen] is set to `false`.
  ///
  /// Defaults to `const Icon(Icons.folder)`.
  final Widget closedIcon;

  /// Whether the icon shown is open or closed.
  ///
  /// Rebuilding the widget with a different [isOpen] value will trigger
  /// the animation, but will not trigger the [onPressed] callback.
  final bool isOpen;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The padding around the button's icon. The entire padded icon will react
  /// to input gestures.
  final EdgeInsetsGeometry padding;

  /// The color to use for the icon inside the button, if the icon is enabled.
  /// Defaults to leaving this up to the icon widget.
  ///
  /// The icon is enabled if [onPressed] is not null.
  ///
  /// ```dart
  /// IconButton(
  ///   color: Colors.blue,
  ///   onPressed: _handleTap,
  ///   icon: Icons.widgets,
  /// )
  /// ```
  final Color? color;

  /// The size of the icon inside the button.
  ///
  /// If null, uses [IconThemeData.size]. If it is also null, the default size
  /// is 24.0.
  ///
  /// The size given here is passed down to the widget in the [icon] property
  /// via an [IconTheme]. Setting the size here instead of in, for example, the
  /// [Icon.size] property allows the [IconButton] to size the splash area to
  /// fit the [Icon]. If you were to set the size of the [Icon] using
  /// [Icon.size] instead, then the [IconButton] would default to 24.0 and then
  /// the [Icon] itself would likely get clipped.
  final double? iconSize;

  /// The splash radius used in [IconButton].
  ///
  /// If null, default splash radius of [Material.defaultSplashRadius] is used.
  final double? splashRadius;

  /// Text that describes the action that will occur when the button is pressed.
  ///
  /// This text is displayed when the user long-presses on the button and is
  /// used for accessibility.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: color,
      tooltip: tooltip,
      padding: padding,
      iconSize: iconSize,
      splashRadius: splashRadius,
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: kThemeAnimationDuration,
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        transitionBuilder: (Widget? child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: Key('$isOpen'),
          child: isOpen ? openedIcon : closedIcon,
        ),
      ),
    );
  }
}
