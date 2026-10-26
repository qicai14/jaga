import 'package:flutter/material.dart';

void main() => runApp(const JagaApp());

class JagaApp extends StatelessWidget {
  const JagaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Jaga',
      home: Scaffold(body: Center(child: Text('Jaga'))),
    );
  }
}
