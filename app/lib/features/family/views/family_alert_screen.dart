import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/stage_progress_bar.dart';
import '../../../data/models/family_alert.dart';
import '../view_models/family_alert_view_model.dart';
import 'widgets/name_band.dart';
import 'widgets/quote_block.dart';

/// The family co-pilot's alert: who and when, how far the scam got, who the
/// caller claims to be, what is happening, proof, and one button to call.
class FamilyAlertScreen extends StatefulWidget {
  const FamilyAlertScreen({super.key, required this.vm, this.autoDial = false});

  final FamilyAlertViewModel vm;

  /// Opened from the notification's Call action: dial after the first frame.
  final bool autoDial;

  @override
  State<FamilyAlertScreen> createState() => _FamilyAlertScreenState();
}

class _FamilyAlertScreenState extends State<FamilyAlertScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoDial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.vm.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: widget.vm,
          builder: (context, _) {
            final s = widget.vm.state;
            final genuine = s.kind == FamilyAlertKind.mayBeGenuine;
            final agency = s.agency;
            return Column(
              children: [
                // The band scrolls with the rest, so a long name at large text
                // can never push the Call button off screen.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NameBand(
                          genuine: genuine,
                          headline: genuine
                              ? l.familyGenuineHeadline(s.personName)
                              : l.familyAlertHeadline(s.personName),
                          time: l.familyAlertTime(_when(context, s.at)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(m.l),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (genuine) ...[
                                Text(
                                  l.familyGenuineBody(s.personName),
                                  style: text.bodyLarge,
                                ),
                                SizedBox(height: m.l),
                              ],
                              StageProgressBar(stage: s.stage),
                              if (agency != null) ...[
                                SizedBox(height: m.l),
                                Text(
                                  l.familyAlertAgencyLabel,
                                  style: text.bodyMedium,
                                ),
                                Text(agency, style: text.titleLarge),
                              ],
                              SizedBox(height: m.l),
                              Text(s.summary, style: text.bodyLarge),
                              if (s.quotes.isNotEmpty) ...[
                                SizedBox(height: m.l),
                                Text(
                                  l.familyAlertQuotesLabel,
                                  style: text.bodyMedium,
                                ),
                                for (final quote in s.quotes) ...[
                                  SizedBox(height: m.s),
                                  QuoteBlock(quote: quote),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(m.l, m.s, m.l, m.m),
                    child: BigButton(
                      tone: genuine
                          ? BigButtonTone.genuine
                          : BigButtonTone.guarded,
                      icon: Icons.call,
                      label: s.canDial
                          ? l.familyAlertCall(s.personName)
                          : l.familyAlertOpenDialer,
                      onPressed: widget.vm.call,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Time only for today, date and time before that.
String _when(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  final local = at.toLocal();
  final now = DateTime.now();
  final today =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  return (today ? DateFormat.jm(locale) : DateFormat.yMMMd(locale).add_jm())
      .format(local);
}
