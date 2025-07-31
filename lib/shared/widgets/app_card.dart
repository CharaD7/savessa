import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BoxBorder? border;
  final bool hasShadow;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.elevation = 2.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.shadowColor,
    this.border,
    this.hasShadow = true,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both title and titleWidget',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final cardShadowColor = shadowColor ?? theme.shadowColor;

    Widget cardContent = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || titleWidget != null) ...[
            _buildTitle(theme),
            const SizedBox(height: 12.0),
          ],
          child,
        ],
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: cardShadowColor.withOpacity(0.1),
                  blurRadius: elevation * 2,
                  spreadRadius: elevation / 2,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: cardContent,
    );
  }

  Widget _buildTitle(ThemeData theme) {
    if (titleWidget != null) {
      if (trailing != null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget!),
            trailing!,
          ],
        );
      }
      return titleWidget!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// A card with an icon and title at the top
class AppIconCard extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String title;
  final Color? iconColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const AppIconCard({
    super.key,
    required this.child,
    required this.icon,
    required this.title,
    this.iconColor,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.elevation = 2.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      elevation: elevation,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      width: width,
      height: height,
      titleWidget: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

// A card with a gradient background
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final Gradient gradient;
  final Color? shadowColor;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const AppGradientCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.elevation = 2.0,
    this.borderRadius = 12.0,
    required this.gradient,
    this.shadowColor,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both title and titleWidget',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardShadowColor = shadowColor ?? theme.shadowColor;

    Widget cardContent = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || titleWidget != null) ...[
            _buildTitle(theme),
            const SizedBox(height: 12.0),
          ],
          child,
        ],
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor.withOpacity(0.1),
            blurRadius: elevation * 2,
            spreadRadius: elevation / 2,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: cardContent,
    );
  }

  Widget _buildTitle(ThemeData theme) {
    if (titleWidget != null) {
      if (trailing != null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleWidget!),
            trailing!,
          ],
        );
      }
      return titleWidget!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}