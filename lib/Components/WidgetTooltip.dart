import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_material_next/WidgetBlur.dart';

class WidgetTooltip extends StatefulWidget {
  /// Creates a tooltip.
  ///
  /// By default, tooltips should adhere to the
  /// [Material specification](https://material.io/design/components/tooltips.html#spec).
  /// If the optional constructor parameters are not defined, the values
  /// provided by [TooltipTheme.of] will be used if a [TooltipTheme] is present
  /// or specified in [ThemeData].
  ///
  /// All parameters that are defined in the constructor will
  /// override the default values _and_ the values in [TooltipTheme.of].
  const WidgetTooltip({
    Key? key,
    required this.message,
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
    this.child,
  }) : super(key: key);

  /// The text to display in the tooltip.
  final Widget message;

  /// The height of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the tooltip's intrinsic height.
  final double? height;

  /// The amount of space by which to inset the tooltip's [child].
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry? padding;

  /// The empty space that surrounds the tooltip.
  ///
  /// Defines the tooltip's outer [Container.margin]. By default, a
  /// long tooltip will span the width of its window. If long enough,
  /// a tooltip might also span the window's height. This property allows
  /// one to define how much space the tooltip must be inset from the edges
  /// of their display window.
  ///
  /// If this property is null, then [TooltipThemeData.margin] is used.
  /// If [TooltipThemeData.margin] is also null, the default margin is
  /// 0.0 logical pixels on all sides.
  final EdgeInsetsGeometry? margin;

  /// The vertical gap between the widget and the displayed tooltip.
  ///
  /// When [preferBelow] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much vertical space
  /// tooltips will position themselves under their corresponding widgets.
  /// Otherwise, tooltips will position themselves above their corresponding
  /// widgets with the given offset.
  final double? verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool? preferBelow;

  /// Whether the tooltip's [message] should be excluded from the semantics
  /// tree.
  ///
  /// Defaults to false. A tooltip will add a [Semantics] label that is set to
  /// [Tooltip2.message]. Set this property to true if the app is going to
  /// provide its own custom semantics label.
  final bool? excludeFromSemantics;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Specifies the tooltip's shape and background color.
  ///
  /// The tooltip shape defaults to a rounded rectangle with a border radius of
  /// 4.0. Tooltips will also default to an opacity of 90% and with the color
  /// [Colors.grey[700]] if [ThemeData.brightness] is [Brightness.dark], and
  /// [Colors.white] if it is [Brightness.light].
  final Decoration? decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [TextTheme.bodyText2] of [ThemeData.textTheme] will be used with
  /// [Colors.white]. Otherwise, if [ThemeData.brightness] is set to
  /// [Brightness.light], [TextTheme.bodyText2] of [ThemeData.textTheme] will be
  /// used with [Colors.black].
  final TextStyle? textStyle;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Once the pointer leaves the widget, the tooltip will immediately
  /// disappear.
  ///
  /// Defaults to 0 milliseconds (tooltips are shown immediately upon hover).
  final Duration? waitDuration;

  /// The length of time that the tooltip will be shown after a long press
  /// is released.
  ///
  /// Defaults to 1.5 seconds.
  final Duration? showDuration;

  @override
  _WidgetTooltipState createState() => _WidgetTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // properties.add(StringProperty('message', message, showName: false));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true, defaultValue: null));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: null));
  }
}

class _WidgetTooltipState extends State<WidgetTooltip> with SingleTickerProviderStateMixin {
  static const double _defaultVerticalOffset = 24.0;
  static const bool _defaultPreferBelow = true;
  static const EdgeInsetsGeometry _defaultMargin = EdgeInsets.all(0.0);
  static const Duration _fadeInDuration = Duration(milliseconds: 150);
  static const Duration _fadeOutDuration = Duration(milliseconds: 75);
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultWaitDuration = Duration(milliseconds: 0);
  static const bool _defaultExcludeFromSemantics = false;

  double? height;
  EdgeInsetsGeometry? padding;
  EdgeInsetsGeometry? margin;
  Decoration? decoration;
  TextStyle? textStyle;
  double? verticalOffset;
  bool? preferBelow;
  bool? excludeFromSemantics;
  late AnimationController _controller;
  OverlayEntry? _entry;
  Timer? _hideTimer;
  Timer? _showTimer;
  late Duration showDuration;
  late Duration waitDuration;
  bool? _mouseIsConnected;
  bool _longPressActivated = false;

  @override
  void initState() {
    super.initState();
    _mouseIsConnected = RendererBinding.instance!.mouseTracker.mouseIsConnected;
    _controller = AnimationController(
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
    // Listen to see when a mouse is added.
    RendererBinding.instance!.mouseTracker.addListener(_handleMouseTrackerChange);
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance!.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  // https://material.io/components/tooltips#specs
  double _getDefaultTooltipHeight() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 24.0;
      default:
        return 32.0;
    }
  }

  EdgeInsets _getDefaultPadding() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const EdgeInsets.symmetric(horizontal: 8.0);
      default:
        return const EdgeInsets.symmetric(horizontal: 16.0);
    }
  }

  double _getDefaultFontSize() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 10.0;
      default:
        return 14.0;
    }
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected = RendererBinding.instance!.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      setState(() {
        _mouseIsConnected = mouseIsConnected;
      });
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideTooltip(immediately: true);
    }
  }

  void _hideTooltip({bool immediately = false}) {
    _showTimer?.cancel();
    _showTimer = null;
    if (immediately) {
      _removeEntry();
      return;
    }
    if (_longPressActivated) {
      // Tool tips activated by long press should stay around for the showDuration.
      _hideTimer ??= Timer(showDuration, _controller.reverse);
    } else {
      // Tool tips activated by hover should disappear as soon as the mouse
      // leaves the control.
      _controller.reverse();
    }
    _longPressActivated = false;
  }

  void _showTooltip({bool immediately = false}) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (immediately) {
      ensureTooltipVisible();
      return;
    }
    _showTimer ??= Timer(waitDuration, ensureTooltipVisible);
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible or if the context has
  /// become null.
  bool ensureTooltipVisible() {
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry != null) {
      // Stop trying to hide, if we were.
      _hideTimer?.cancel();
      _hideTimer = null;
      _controller.forward();
      return false; // Already visible.
    }
    _createNewEntry();
    _controller.forward();
    return true;
  }

  void _createNewEntry() {
    final OverlayState overlayState = Overlay.of(
      context,
      debugRequiredFor: widget,
    )!;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Widget overlay = Directionality(
      textDirection: Directionality.of(context),
      child: _TooltipOverlay(
        child: widget.message,
        height: height,
        padding: padding,
        margin: margin,
        decoration: decoration,
        textStyle: textStyle,
        animation: CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ),
        target: target,
        verticalOffset: verticalOffset,
        preferBelow: preferBelow,
      ),
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    overlayState.insert(_entry!);
    // SemanticsService.tooltip(widget.message);
  }

  void _removeEntry() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    _entry?.remove();
    _entry = null;
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_entry == null) {
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _hideTooltip();
    } else if (event is PointerDownEvent) {
      _hideTooltip(immediately: true);
    }
  }

  @override
  void deactivate() {
    if (_entry != null) {
      _hideTooltip(immediately: true);
    }
    _showTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    GestureBinding.instance!.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance!.mouseTracker.removeListener(_handleMouseTrackerChange);
    if (_entry != null) _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    _longPressActivated = true;
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated) Feedback.forLongPress(context);
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    final ThemeData theme = Theme.of(context);
    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);
    TextStyle defaultTextStyle;
    BoxDecoration defaultDecoration;
    if (theme.brightness == Brightness.dark) {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        // ??
        color: Colors.black,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    } else {
      defaultTextStyle = theme.textTheme.bodyText2!.copyWith(
        // ?
        color: Colors.white,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.grey[700]!.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    }

    height = widget.height ?? tooltipTheme.height ?? _getDefaultTooltipHeight();
    padding = widget.padding ?? tooltipTheme.padding ?? _getDefaultPadding();
    margin = widget.margin ?? tooltipTheme.margin ?? _defaultMargin;
    verticalOffset = widget.verticalOffset ?? tooltipTheme.verticalOffset ?? _defaultVerticalOffset;
    preferBelow = widget.preferBelow ?? tooltipTheme.preferBelow ?? _defaultPreferBelow;
    excludeFromSemantics = widget.excludeFromSemantics ?? tooltipTheme.excludeFromSemantics ?? _defaultExcludeFromSemantics;
    decoration = widget.decoration ?? tooltipTheme.decoration ?? defaultDecoration;
    textStyle = widget.textStyle ?? tooltipTheme.textStyle ?? defaultTextStyle;
    waitDuration = widget.waitDuration ?? tooltipTheme.waitDuration ?? _defaultWaitDuration;
    showDuration = widget.showDuration ?? tooltipTheme.showDuration ?? _defaultShowDuration;

    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _handleLongPress,
      excludeFromSemantics: true,
      child: Semantics(
        label: null, // excludeFromSemantics ? null : widget.message,
        child: widget.child,
      ),
    );

    // Only check for hovering if there is a mouse connected.
    if (_mouseIsConnected!) {
      result = MouseRegion(
        onEnter: (PointerEnterEvent event) => _showTooltip(),
        onExit: (PointerExitEvent event) => _hideTooltip(),
        child: result,
      );
    }

    return result;
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// bellow a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _TooltipPositionDelegate({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  })  : assert(target != null),
        assert(verticalOffset != null),
        assert(preferBelow != null);

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target || verticalOffset != oldDelegate.verticalOffset || preferBelow != oldDelegate.preferBelow;
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    Key? key,
    required this.child,
    required this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    required this.animation,
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  }) : super(key: key);

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Animation<double> animation;
  final Offset target;
  final double? verticalOffset;
  final bool? preferBelow;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipPositionDelegate(
            target: target,
            verticalOffset: verticalOffset!,
            preferBelow: preferBelow!,
          ),
          child: WidgetBlur(
            child: FadeTransition(
              opacity: animation,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Theme.of(context).cardColor.withAlpha(96),
                    padding: padding,
                    margin: margin,
                    child: Center(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
