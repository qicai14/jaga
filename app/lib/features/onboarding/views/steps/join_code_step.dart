import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../data/services/onboarding_api_service.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/inline_error.dart';

/// Co-pilot step 3: the six-digit code, then who you are and what you call her.
class JoinCodeStep extends StatelessWidget {
  const JoinCodeStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) =>
      vm.joinStage == JoinStage.code ? _CodeEntry(vm: vm) : _NamesEntry(vm: vm);
}

class _CodeEntry extends StatefulWidget {
  const _CodeEntry({required this.vm});

  final OnboardingViewModel vm;

  @override
  State<_CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<_CodeEntry> {
  late final _controller = TextEditingController(text: widget.vm.code);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final vm = widget.vm;
    final error = switch (vm.joinError) {
      JoinError.invalid => l.onboardingCodeWrong,
      JoinError.expired => l.onboardingCodeExpired,
      JoinError.full => l.onboardingCopilotsFull,
      null => vm.networkError ? l.onboardingNetworkError : null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One real field laid over six boxes that show its digits.
        Semantics(
          label: l.onboardingJoinCode,
          textField: true,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < linkCodeLength; i++)
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        margin: EdgeInsets.symmetric(horizontal: m.xs),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(m.radiusSmall),
                          border: Border.all(
                            color: i == vm.code.length
                                ? scheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          i < vm.code.length ? vm.code[i] : '',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                ],
              ),
              Positioned.fill(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: null,
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(linkCodeLength),
                  ],
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: vm.setCode,
                ),
              ),
            ],
          ),
        ),
        if (error != null) InlineError(error),
      ],
    );
  }
}

class _NamesEntry extends StatefulWidget {
  const _NamesEntry({required this.vm});

  final OnboardingViewModel vm;

  @override
  State<_NamesEntry> createState() => _NamesEntryState();
}

class _NamesEntryState extends State<_NamesEntry> {
  late final _yourName = TextEditingController(text: widget.vm.yourName);
  late final _callName = TextEditingController(text: widget.vm.callName);

  @override
  void dispose() {
    _yourName.dispose();
    _callName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final vm = widget.vm;
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _yourName,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: style,
          decoration: InputDecoration(labelText: l.onboardingYourName),
          onChanged: vm.setYourName,
        ),
        SizedBox(height: m.m),
        TextField(
          controller: _callName,
          textCapitalization: TextCapitalization.words,
          style: style,
          decoration: InputDecoration(
            labelText: l.onboardingCallHer,
            helperText: l.onboardingCallHerHelper,
            helperMaxLines: 3,
          ),
          onChanged: vm.setCallName,
        ),
        if (vm.networkError) InlineError(l.onboardingNetworkError),
      ],
    );
  }
}
