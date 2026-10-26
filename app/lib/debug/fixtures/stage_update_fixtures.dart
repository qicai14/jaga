// Valid against contracts/stage-update.schema.json (draft v0); the schema test
// validates every string in [stageUpdateV0Fixtures].
// Parse them with StageUpdate.parse so tests and the gallery use the real model.

const stageLow = r'''{
  "callId": "call-1", "stage": "pretext", "risk": "low",
  "claimedAgency": null, "command": null, "counterMove": null,
  "evidence": [], "source": "rules", "at": "2026-10-27T10:00:00Z"
}''';

const stageMedium = r'''{
  "callId": "call-1", "stage": "authority", "risk": "medium",
  "claimedAgency": "PDRM", "command": null, "counterMove": null,
  "evidence": ["Saya pegawai polis dari Bukit Aman"],
  "source": "rules", "at": "2026-10-27T10:00:20Z"
}''';

const stageHigh = r'''{
  "callId": "call-1", "stage": "fear", "risk": "high",
  "claimedAgency": "PDRM",
  "command": "Letak telefon sekarang.",
  "counterMove": "Polis tidak akan minta wang atau kata laluan melalui telefon. Hubungi PDRM sendiri.",
  "evidence": ["Akaun anda dikaitkan dengan satu kes jenayah"],
  "source": "rules", "at": "2026-10-27T10:00:40Z"
}''';

const stageHighCredentials = r'''{
  "callId": "call-1", "stage": "credentials", "risk": "high",
  "claimedAgency": "Bank Negara",
  "command": "Jangan beritahu kod atau kata laluan.",
  "counterMove": "Bank tidak akan minta kod TAC anda. Letak telefon dan hubungi bank anda sendiri.",
  "evidence": ["Sila beritahu kod yang kami hantar"],
  "source": "spark", "at": "2026-10-27T10:01:10Z"
}''';

const stageHighNoCommand = r'''{
  "callId": "call-1", "stage": "money", "risk": "high",
  "claimedAgency": null, "command": null, "counterMove": null,
  "evidence": [], "source": "rules", "at": "2026-10-27T10:01:30Z"
}''';

const stageUpdateV0Fixtures = [
  stageLow,
  stageMedium,
  stageHigh,
  stageHighCredentials,
  stageHighNoCommand,
];
