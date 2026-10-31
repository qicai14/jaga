import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pause_client.dart';

// An origin only, e.g. https://jaga-server.onrender.com (any path is dropped).
const _serverUrl = String.fromEnvironment('JAGA_SERVER_URL');
const _pauseToken = String.fromEnvironment('JAGA_PAUSE_TOKEN');

/// Standalone Demo Bank (web). English only on purpose; not part of the app.
class DemoBankApp extends StatelessWidget {
  /// Without [client]/[pauseToken] it reads --dart-define config.
  DemoBankApp({super.key, PauseClient? client, String? pauseToken})
    : client =
          client ??
          (_serverUrl.isEmpty
              ? null
              : HttpPauseClient(Uri.parse(_serverUrl), http.Client())),
      pauseToken = pauseToken ?? _pauseToken;

  final PauseClient? client;
  final String pauseToken;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Demo Bank',
    home: client == null || pauseToken.isEmpty
        ? const Scaffold(
            body: Center(
              child: Text(
                'Demo Bank is not configured. Set JAGA_SERVER_URL and '
                'JAGA_PAUSE_TOKEN with --dart-define.',
              ),
            ),
          )
        : TransferPage(client: client!, pauseToken: pauseToken),
  );
}

class TransferPage extends StatefulWidget {
  const TransferPage({
    super.key,
    required this.client,
    required this.pauseToken,
  });
  final PauseClient client;
  final String pauseToken;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _recipient = TextEditingController();
  final _amount = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    if (_recipient.text.trim().isEmpty || _amount.text.trim().isEmpty) {
      setState(() => _error = 'Enter a recipient and an amount.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await widget.client.ask(widget.pauseToken);
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => a.inScam
              ? HeldPage(answer: a)
              : SentPage(recipient: _recipient.text, amount: _amount.text),
        ),
      );
    } on PauseFailure catch (e) {
      // Fail-safe: if we cannot ask Jaga Pause, do NOT send the money.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '${e.message}. Transfer not sent. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demo Bank')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _recipient,
            decoration: const InputDecoration(labelText: 'Recipient'),
          ),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (RM)'),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton(onPressed: _transfer, child: const Text('Transfer')),
        ],
      ),
    ),
  );
}

class HeldPage extends StatelessWidget {
  const HeldPage({super.key, required this.answer});
  final PauseAnswer answer;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demo Bank')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer held',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text('Jaga detected a scam call.'),
          Text('Held for ${answer.recommendedHoldMinutes} minutes'),
          Text('Caller claims to be: ${answer.claimedAgency ?? 'unknown'}'),
        ],
      ),
    ),
  );
}

class SentPage extends StatelessWidget {
  const SentPage({super.key, required this.recipient, required this.amount});
  final String recipient;
  final String amount;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demo Bank')),
    body: Center(child: Text('Transfer sent: RM $amount to $recipient')),
  );
}
