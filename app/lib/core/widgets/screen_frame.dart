import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context.dart';

/// Page scaffold: safe area, 24dp side padding, optional title, scrolling body,
/// and a bottom action pinned above the gesture bar.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    this.appBar,
    this.title,
    this.titleStyle,
    this.role,
    required this.body,
    this.bottomAction,
  });

  /// Setup steps put the back arrow and progress here.
  final PreferredSizeWidget? appBar;
  final String? title;

  /// A smaller title for long ones; the default is headlineMedium.
  final TextStyle? titleStyle;

  /// A [RoleBadge] on its own row at the top end, above the title.
  final Widget? role;
  final Widget body;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: m.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role != null)
                  Padding(
                    padding: EdgeInsets.only(top: m.m, bottom: m.s),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: role,
                    ),
                  ),
                if (title != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: role == null ? m.l : 0,
                      bottom: m.m,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style:
                            titleStyle ??
                            Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: title == null && role == null ? m.l : 0,
                    ),
                    child: SizedBox(width: double.infinity, child: body),
                  ),
                ),
                if (bottomAction != null)
                  Padding(
                    padding: EdgeInsets.only(top: m.m, bottom: m.m),
                    child: bottomAction,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
