import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/theme_context.dart';

/// A number pad for a short PIN: dots on top, three columns of keys below.
/// With [onCompleted], it is called with the digits once [length] are typed and
/// the pad clears itself. Without it, the pad keeps the digits and only reports
/// every change to [onChanged]; the host decides when to submit and resets the
/// pad by giving it a new key.
class PinPad extends StatefulWidget {
  const PinPad({super.key, this.onCompleted, this.onChanged, this.length = 4});

  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _type(String digit) {
    if (_digits.length >= widget.length) return;
    final digits = _digits + digit;
    final complete = digits.length == widget.length;
    final onCompleted = widget.onCompleted;
    if (complete && onCompleted != null) {
      setState(() => _digits = '');
      onCompleted(digits);
      return;
    }
    setState(() => _digits = digits);
    widget.onChanged?.call(digits);
  }

  void _delete() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
    widget.onChanged?.call(_digits);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.commonPinEntered(_digits.length, widget.length),
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++)
                  Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.only(right: m.m),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _digits.length ? scheme.primary : null,
                      border: Border.all(color: scheme.outline, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: m.l),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Padding(
            padding: EdgeInsets.only(bottom: m.s),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: m.xs),
                      child: switch (key) {
                        '' => const SizedBox(height: _keyHeight),
                        '<' => _Key(
                          onPressed: _delete,
                          semanticsLabel: l.commonDelete,
                          child: const Icon(Icons.backspace_outlined),
                        ),
                        _ => _Key(
                          onPressed: () => _type(key),
                          child: Text(key),
                        ),
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

const _keyHeight = 72.0;

class _Key extends StatelessWidget {
  const _Key({
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
  });

  final VoidCallback onPressed;
  final Widget child;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        minimumSize: const Size.fromHeight(_keyHeight),
        padding: EdgeInsets.zero,
        textStyle: Theme.of(context).textTheme.headlineMedium,
      ),
      child: child,
    );
    return semanticsLabel == null
        ? key
        : Semantics(
            label: semanticsLabel,
            excludeSemantics: true,
            button: true,
            child: key,
          );
  }
}
