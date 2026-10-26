// NOT schema-validated. These carry commandEnglish, counterMoveEnglish and
// officialNumber, which contract v0 does not have yet (additionalProperties is
// false). Requested from contracts #1; move them into the validated set when it lands.

const extHigh = r'''{
  "callId": "call-1", "stage": "fear", "risk": "high",
  "claimedAgency": "PDRM",
  "command": "Letak telefon sekarang.",
  "commandEnglish": "Hang up now.",
  "counterMove": "Polis tidak akan minta wang atau kata laluan melalui telefon. Hubungi PDRM sendiri.",
  "counterMoveEnglish": "The police never ask for money or passwords by phone. Call PDRM yourself.",
  "officialNumber": "+60 3-2266 2222",
  "evidence": ["Akaun anda dikaitkan dengan satu kes jenayah"],
  "source": "rules", "at": "2026-10-27T10:00:40Z"
}''';

const extHighCredentials = r'''{
  "callId": "call-1", "stage": "credentials", "risk": "high",
  "claimedAgency": "Bank Negara",
  "command": "Jangan beritahu kod atau kata laluan.",
  "commandEnglish": "Do not share any code or password.",
  "counterMove": "Bank tidak akan minta kod TAC anda. Letak telefon dan hubungi bank anda sendiri.",
  "counterMoveEnglish": "A bank never asks for your TAC code. Hang up and call your bank yourself.",
  "officialNumber": "+60 3-2174 1717",
  "evidence": ["Sila beritahu kod yang kami hantar"],
  "source": "spark", "at": "2026-10-27T10:01:10Z"
}''';

/// Her language was missing, so the server sent English for both.
const extHighEnglishOnly = r'''{
  "callId": "call-1", "stage": "fear", "risk": "high",
  "claimedAgency": "LHDN",
  "command": "Hang up now.",
  "commandEnglish": "Hang up now.",
  "counterMove": "The tax office never threatens arrest by phone. Call LHDN yourself.",
  "counterMoveEnglish": "The tax office never threatens arrest by phone. Call LHDN yourself.",
  "officialNumber": "+60 3-8911 1000",
  "evidence": ["You will be arrested today"],
  "source": "rules", "at": "2026-10-27T10:00:40Z"
}''';

const extHighLongText = r'''{
  "callId": "call-1", "stage": "money", "risk": "high",
  "claimedAgency": "Bank Negara",
  "command": "Berhenti sekarang dan letak telefon, jangan pindahkan wang kepada sesiapa.",
  "commandEnglish": "Stop now and hang up. Do not move money to anyone.",
  "counterMove": "Pegawai bank atau polis yang sebenar tidak akan meminta anda memindahkan wang ke akaun lain, walau apa pun alasannya. Hubungi bank anda sendiri menggunakan nombor di belakang kad anda.",
  "counterMoveEnglish": "A real bank or police officer never asks you to move money to another account, whatever the reason. Call your bank yourself on the number on the back of your card.",
  "officialNumber": "+60 3-2174 1717",
  "evidence": ["Pindahkan semua wang anda ke akaun selamat ini sekarang juga sebelum akaun anda dibekukan oleh pihak berkuasa"],
  "source": "spark", "at": "2026-10-27T10:00:40Z"
}''';

/// A high Warning whose official number is unknown.
const extHighNoNumber = r'''{
  "callId": "call-1", "stage": "fear", "risk": "high",
  "claimedAgency": null,
  "command": "Letak telefon sekarang.",
  "commandEnglish": "Hang up now.",
  "counterMove": "Hubungi organisasi itu sendiri melalui nombor yang anda tahu.",
  "counterMoveEnglish": "Call the organisation yourself on a number you already know.",
  "officialNumber": null,
  "evidence": ["Akaun anda dikaitkan dengan satu kes jenayah"],
  "source": "rules", "at": "2026-10-27T10:00:40Z"
}''';
