import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/models/voice_token.dart';
import 'package:jaga/data/repositories/call_repository.dart';
import 'package:jaga/data/services/call_service.dart';
import 'package:jaga/data/services/network_exception.dart';
import 'package:jaga/data/services/voice_token_service.dart';

class _Tokens implements VoiceTokenService {
  _Tokens(this.clock);

  final DateTime Function() clock;
  int fetches = 0;
  bool failing = false;

  @override
  Future<VoiceToken> fetch() async {
    fetches++;
    if (failing) throw const NetworkException();
    return VoiceToken(
      token: 'tok$fetches',
      expiresAt: clock().add(const Duration(hours: 1)),
    );
  }
}

void main() {
  test('start registers the first token and follows the call', () async {
    final service = FakeCallService();
    final repo = CallRepository(
      service: service,
      tokens: FakeVoiceTokenService(),
    );
    await repo.start();
    expect(service.registered, hasLength(1));
    service.emit(const CallSnapshot(phase: CallPhase.active));
    expect(repo.snapshot.value.phase, CallPhase.active);
    repo.dispose();
  });

  test('a call already on when the app starts is picked up', () async {
    final repo = CallRepository(
      service: FakeCallService(const CallSnapshot(phase: CallPhase.active)),
      tokens: FakeVoiceTokenService(),
    );
    await repo.watch();
    expect(repo.snapshot.value.live, isTrue);
    repo.dispose();
  });

  testWidgets('a new token is fetched 5 minutes before the old one expires', (
    tester,
  ) async {
    DateTime now() => tester.binding.clock.now();
    final tokens = _Tokens(now);
    final service = FakeCallService();
    final repo = CallRepository(service: service, tokens: tokens, now: now);
    await repo.start();
    expect(service.registered, ['tok1']);
    await tester.pump(const Duration(minutes: 54));
    expect(tokens.fetches, 1);
    await tester.pump(const Duration(minutes: 2));
    expect(service.registered, ['tok1', 'tok2']);
    repo.dispose();
  });

  testWidgets(
    'a register in flight when stop() runs does not re-arm the timer',
    (tester) async {
      final tokens = _Tokens(DateTime.now);
      final repo = CallRepository(service: FakeCallService(), tokens: tokens);
      final starting = repo.start();
      repo.stop(); // before the fetch completes
      await starting;
      await tester.pump(const Duration(hours: 2));
      expect(tokens.fetches, 1);
      repo.dispose();
    },
  );

  testWidgets('a failed fetch is retried', (tester) async {
    final tokens = _Tokens(DateTime.now)..failing = true;
    final service = FakeCallService();
    final repo = CallRepository(service: service, tokens: tokens);
    await repo.start();
    expect(service.registered, isEmpty);
    tokens.failing = false;
    await tester.pump(CallRepository.retryAfter);
    expect(service.registered, ['tok2']);
    repo.dispose();
  });
}
