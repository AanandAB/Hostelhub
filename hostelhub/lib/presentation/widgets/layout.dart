import 'package:flutter/material.dart';

/// Page-level layout constants and helpers for the responsive web build.
///
/// HostelHub is a mobile-first design that also ships as a web app. Screens are
/// laid out full-bleed (the gradient backdrop is painted once at the app root),
/// and only the *content* is constrained — so a 1920px monitor gets a wide,
/// centred workspace instead of a phone-shaped strip with empty gutters.
class Layout {
  Layout._();

  /// Content stops growing here on very wide monitors.
  static const double maxWidth = 1180;

  /// Comfortable reading width for single-column forms and auth screens.
  static const double formWidth = 460;

  /// Breakpoints (logical pixels).
  static const double tablet = 720;
  static const double desktop = 1024;

  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= desktop;

  static bool isTabletOrWider(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= tablet;

  /// Horizontal padding that grows with the viewport.
  static double gutter(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w >= desktop) return 40;
    if (w >= tablet) return 28;
    return 20;
  }

  /// Number of columns for card grids: 2 on phones, more as width allows.
  static int gridColumns(BuildContext c, {int max = 4}) {
    final w = MediaQuery.sizeOf(c).width;
    if (w >= desktop) return max;
    if (w >= tablet) return max.clamp(2, 3);
    return 2;
  }
}

extension LayoutInsets on BuildContext {
  /// Horizontal inset for a single-column form: keeps the form at
  /// [Layout.formWidth] and centres it, instead of stretching edge to edge on
  /// a desktop browser.
  EdgeInsets formInsets({
    double maxFormWidth = Layout.formWidth,
    double vertical = 24,
    double minGutter = 20,
  }) {
    final w = MediaQuery.sizeOf(this).width;
    final g = (w - maxFormWidth) / 2;
    final h = g > minGutter ? g : minGutter;
    return EdgeInsets.symmetric(horizontal: h, vertical: vertical);
  }

  /// Horizontal inset that keeps a scrolling page at a comfortable width.
  /// Long single-column lists (menus, settings rows) look stretched at 1100px+.
  EdgeInsets pageInsets({
    double maxContentWidth = 900,
    double top = 20,
    double bottom = 120,
    double minGutter = 20,
  }) {
    final w = MediaQuery.sizeOf(this).width;
    final g = (w - maxContentWidth) / 2;
    final h = g > minGutter ? g : minGutter;
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }
}

/// Centres its child and caps it at [Layout.maxWidth] with responsive gutters.
/// Used inside the tab screens and detail pages so content doesn't stretch.
class PageContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool center;

  const PageContent({
    super.key,
    required this.child,
    this.maxWidth = Layout.maxWidth,
    this.padding,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = Layout.gutter(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: g),
          child: center
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Layout.formWidth),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

/// Lays children out in a responsive grid of [minItemWidth]-wide cells.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.spacing = 14,
    this.runSpacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns = (available / minItemWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > 4) columns = 4;
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
