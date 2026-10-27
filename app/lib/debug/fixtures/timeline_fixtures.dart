// Valid against contracts/stage-update.schema.json (draft v0); the schema test
// validates every string in [timelineV0Fixtures]. The timeline's own shape is
// provisional (#1): events are stage updates, calls are family alerts.
// call-1's steps are the stage-update fixtures in stage_update_fixtures.dart.

import '../../data/models/alerted_call.dart';
import '../../data/models/family_alert.dart';
import '../../data/models/stage.dart';
import '../../data/models/stage_update.dart';
import '../../data/services/timeline_service.dart';
import 'family_alert_fixtures.dart';
import 'stage_update_fixtures.dart';

const timelineCall2Authority = r'''{
  "callId": "call-2", "stage": "authority", "risk": "medium",
  "claimedAgency": "Bank Negara", "command": null, "counterMove": null,
  "evidence": ["Saya pegawai dari Bank Negara Malaysia"],
  "source": "rules", "at": "2026-10-27T10:00:30Z"
}''';

const timelineCall2Credentials = r'''{
  "callId": "call-2", "stage": "credentials", "risk": "high",
  "claimedAgency": "Bank Negara", "command": null, "counterMove": null,
  "evidence": ["Sila beritahu kod yang kami hantar"],
  "source": "spark", "at": "2026-10-27T10:01:10Z"
}''';

const timelineLongPretext = r'''{
  "callId": "call-5", "stage": "pretext", "risk": "low",
  "claimedAgency": null, "command": null, "counterMove": null,
  "evidence": [], "source": "rules", "at": "2026-10-27T10:02:00Z"
}''';

const timelineLongFear = r'''{
  "callId": "call-5", "stage": "fear", "risk": "high",
  "claimedAgency": "Suruhanjaya Pencegahan Rasuah Malaysia",
  "command": null, "counterMove": null,
  "evidence": ["Akaun anda telah digunakan untuk kegiatan pengubahan wang haram dan anda perlu memindahkan semua wang anda ke akaun selamat kami hari ini juga, jika tidak anda akan ditahan oleh polis serta-merta."],
  "source": "spark", "at": "2026-10-27T10:03:00Z"
}''';

const timelineLongIsolation = r'''{
  "callId": "call-5", "stage": "isolation", "risk": "high",
  "claimedAgency": "Suruhanjaya Pencegahan Rasuah Malaysia",
  "command": null, "counterMove": null,
  "evidence": ["Jangan beritahu keluarga atau pegawai bank anda tentang perbualan ini kerana siasatan ini adalah sulit dan boleh menjejaskan kes anda jika anda berbuat demikian.", "Jangan letak telefon sehingga kami benarkan"],
  "source": "spark", "at": "2026-10-27T10:04:00Z"
}''';

const timelineV0Fixtures = [
  timelineCall2Authority,
  timelineCall2Credentials,
  timelineLongPretext,
  timelineLongFear,
  timelineLongIsolation,
];

/// The latest alert of a call, as a row of the home list.
AlertedCall alertedCallFrom(FamilyAlert alert) => AlertedCall(
  callId: alert.callId,
  at: alert.at,
  stage: alert.stage,
  claimedAgency: alert.claimedAgency,
);

/// A stage update, as a step of the timeline.
TimelineEvent timelineEventFrom(StageUpdate update) => TimelineEvent(
  at: update.at,
  stage: update.stage,
  risk: update.risk,
  quotes: update.evidence,
);

List<TimelineEvent> _events(List<String> raw) => [
  for (final r in raw) timelineEventFrom(StageUpdate.parse(r)),
];

/// Five calls, newest first, with timelines for call-1, call-2 and call-5.
List<AlertedCall> fixtureCalls() => [
  for (final raw in [
    familyLongText,
    familyNoQuotes,
    familyNoAgency,
    familyCredentials,
    familyMoney,
  ])
    alertedCallFrom(FamilyAlert.parse(raw)),
];

/// Twelve calls a day apart, for the long list.
List<AlertedCall> manyFixtureCalls() => [
  for (var i = 0; i < 12; i++)
    AlertedCall(
      callId: 'many-$i',
      at: DateTime.utc(2026, 10, 27 - i, 10),
      stage: Stage.values[1 + i % 7],
      claimedAgency: i.isEven ? 'PDRM' : null,
    ),
];

Map<String, List<TimelineEvent>> fixtureEvents() => {
  'call-1': _events([stageLow, stageMedium, stageHigh, stageHighNoCommand]),
  'call-2': _events([timelineCall2Authority, timelineCall2Credentials]),
  'call-5': _events([
    timelineLongPretext,
    timelineLongFear,
    timelineLongIsolation,
  ]),
};

FakeTimelineService fixtureTimelineService({bool many = false}) =>
    FakeTimelineService(
      calls: many ? manyFixtureCalls() : fixtureCalls(),
      events: fixtureEvents(),
    );
