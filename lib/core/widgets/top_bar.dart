import 'package:flutter/material.dart';

import 'circle_icon_button.dart';

/// App bar with a centred title and a round back button when the page can
/// go back, as in the design.
PreferredSizeWidget appTopBar(
  BuildContext context, {
  required String title,
  List<Widget> actions = const [],
  PreferredSizeWidget? bottom,
}) {
  final canPop = ModalRoute.of(context)?.canPop ?? false;
  return AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 64,
    leadingWidth: 68,
    leading: canPop
        ? Center(
            child: CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: 'Back',
              size: 42,
              iconSize: 18,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          )
        : null,
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: [...actions, const SizedBox(width: 12)],
    bottom: bottom,
  );
}
