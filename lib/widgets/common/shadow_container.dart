import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ShadowContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const ShadowContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppTheme.primaryWhite,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ?? AppTheme.lightShadow,
        ),
        child: child,
      ),
    );
  }
}
