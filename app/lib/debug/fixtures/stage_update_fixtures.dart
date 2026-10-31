// Valid against contracts/stage-update.schema.json (v1, ADR 0007). The
// canonical fixtures live in contracts/fixtures/stage-update.
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
  "counterMove": "Polis tidak akan minta wang atau kata laluan melalui telefon. Hubungi PDRM sendiri di 03-2266 2222.",
  "evidence": ["Akaun anda dikaitkan dengan satu kes jenayah"],
  "source": "rules", "at": "2026-10-27T10:00:40Z"
}''';

const stageHighCredentials = r'''{
  "callId": "call-1", "stage": "credentials", "risk": "high",
  "claimedAgency": "Bank Negara",
  "command": "Jangan beritahu kod atau kata laluan.",
  "counterMove": "Bank tidak akan minta kod TAC anda. Letak telefon dan hubungi bank anda sendiri di 03-2174 1717.",
  "evidence": ["Sila beritahu kod yang kami hantar"],
  "source": "spark", "at": "2026-10-27T10:01:10Z"
}''';

// Malformed at high in v1 (command required): kept to test the safety net.
const stageHighNoCommand = r'''{
  "callId": "call-1", "stage": "money", "risk": "high",
  "claimedAgency": null, "command": null, "counterMove": null,
  "evidence": [], "source": "rules", "at": "2026-10-27T10:01:30Z"
}''';

const stageHighLongText = r'''{
  "callId": "call-1", "stage": "money", "risk": "high",
  "claimedAgency": "Bank Negara",
  "command": "Berhenti sekarang dan letak telefon, jangan pindahkan wang kepada sesiapa.",
  "counterMove": "Pegawai bank atau polis yang sebenar tidak akan meminta anda memindahkan wang ke akaun lain, walau apa pun alasannya. Hubungi bank anda sendiri menggunakan nombor di belakang kad anda: 03-2174 1717.",
  "evidence": ["Pindahkan semua wang anda ke akaun selamat ini sekarang juga sebelum akaun anda dibekukan oleh pihak berkuasa"],
  "source": "spark", "at": "2026-10-27T10:00:40Z"
}''';
