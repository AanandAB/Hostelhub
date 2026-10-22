import 'package:flutter/material.dart';

import 'layout.dart';

/// Constrains the app to a wide, centred workspace on large screens.
///
/// The gradient backdrop is painted once behind everything (see main.dart), so
/// this only limits the *layout* width — there is no visible column edge and no
/// empty gutter: the background runs edge to edge and content is centred inside
/// it, the way a normal responsive web app behaves.
///
/// Below [Layout.maxWidth] the child is returned untouched, so phones and the
/// native apps keep the full-bleed mobile layout.
class ResponsiveFrame extends StatelessWidget {
  final Widget child;
  const ResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= Layout.maxWidth) return child;

    return Center(
      child: SizedBox(
        width: Layout.maxWidth,
        height: media.size.height,
        child: MediaQuery(
          // Keep layout code (grids, dialogs, sheets) in sync with the width
          // the widgets are actually laid out at.
          data: media.copyWith(size: Size(Layout.maxWidth, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}
