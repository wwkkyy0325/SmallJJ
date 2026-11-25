import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// 统一的可点击容器：hover / focus-visible / pressed 三态，
/// 焦点环始终可见（不靠移除 outline 换来的“干净”）。
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.radius = AppRadius.mdAll,
    this.semanticLabel,
    this.selected = false,
    this.overlayColor,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final String? semanticLabel;
  final bool selected;
  final Color? overlayColor;
  final EdgeInsets padding;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _node.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return AnimatedContainer(
      duration: AppMotion.respect(context, AppMotion.quick),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        border: Border.all(
          width: 2,
          color: _focused ? AppColor.focus : Colors.transparent,
        ),
      ),
      child: Semantics(
        button: enabled,
        selected: widget.selected,
        label: widget.semanticLabel,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: _node,
            onTap: widget.onTap,
            borderRadius: widget.radius,
            splashFactory: InkSparkle.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return (widget.overlayColor ?? AppColor.brand).withValues(
                  alpha: 0.14,
                );
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return (widget.overlayColor ?? AppColor.brand).withValues(
                  alpha: 0.07,
                );
              }
              return null;
            }),
            canRequestFocus: enabled,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
