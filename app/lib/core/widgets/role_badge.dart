import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'status_badge.dart';

/// Says whose phone this is, at the top end of a main screen (`ScreenFrame.role`).
/// Grey for the family co-pilot, so it never reads as a status; teal for the
/// protected phone. Not tappable: a long press passes through it.
class RoleBadge extends StatelessWidget {
  const RoleBadge.family({super.key}) : _family = true;
  const RoleBadge.protected({super.key}) : _family = false;

  final bool _family;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _family
        ? StatusBadge(
            label: l.roleFamily,
            tone: BadgeTone.neutral,
            icon: Icons.family_restroom,
          )
        : StatusBadge(
            label: l.roleProtected,
            tone: BadgeTone.guarded,
            icon: Icons.shield,
          );
  }
}
