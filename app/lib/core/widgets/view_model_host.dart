import 'package:flutter/widgets.dart';

/// Creates a view model once, hands it to [builder], and disposes it with the
/// widget. A screen that is rebuilt from above keeps its view model.
class ViewModelHost<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelHost({super.key, required this.create, required this.builder});

  final T Function() create;
  final Widget Function(BuildContext context, T vm) builder;

  @override
  State<ViewModelHost<T>> createState() => _ViewModelHostState<T>();
}

class _ViewModelHostState<T extends ChangeNotifier> extends State<ViewModelHost<T>> {
  late final T _vm = widget.create();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _vm);
}
