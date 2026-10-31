// Valid against contracts/family-alert.schema.json (draft v0); the schema test
// validates every string in [familyAlertFixtures].
// Parse them with FamilyAlert.parse so tests and the gallery use the real model.

import '../../data/models/linked_person.dart';

const familyPerson = LinkedPerson(name: 'Mum', phoneNumber: '+60 12-345 6789');
const familyPersonNoNumber = LinkedPerson(name: 'Mum');
const familyPersonLongName = LinkedPerson(
  name: 'Puan Sri Rajeswari binti Abdullah',
  phoneNumber: '+60 12-345 6789',
);

const familyIsolation = r'''{
  "kind": "alert", "callId": "call-1", "protectedUserName": "Mummy", "stage": "isolation",
  "claimedAgency": "PDRM",
  "summary": "The caller says Mum's bank account is linked to a crime and tells her not to tell anyone.",
  "quotes": ["Jangan beritahu sesiapa tentang kes ini"],
  "at": "2026-10-27T10:00:40Z"
}''';

/// Same call as [familyIsolation], a minute later.
const familyMoney = r'''{
  "kind": "alert", "callId": "call-1", "protectedUserName": "Mummy", "stage": "money",
  "claimedAgency": "PDRM",
  "summary": "The caller now asks Mum to move her savings to a 'safe account'.",
  "quotes": ["Pindahkan wang ke akaun selamat ini sekarang", "Jangan letak telefon"],
  "at": "2026-10-27T10:01:40Z"
}''';

const familyCredentials = r'''{
  "kind": "alert", "callId": "call-2", "protectedUserName": "Mummy", "stage": "credentials",
  "claimedAgency": "Bank Negara",
  "summary": "The caller is asking Mum to read out the code sent to her phone.",
  "quotes": ["Sila beritahu kod yang kami hantar"],
  "at": "2026-10-27T10:01:10Z"
}''';

const familyNoAgency = r'''{
  "kind": "alert", "callId": "call-3", "protectedUserName": "Mummy", "stage": "handoff",
  "claimedAgency": null,
  "summary": "The caller passed Mum to a second person who says he is an officer.",
  "quotes": ["Saya akan sambungkan anda kepada pegawai kanan"],
  "at": "2026-10-27T10:02:00Z"
}''';

const familyNoQuotes = r'''{
  "kind": "alert", "callId": "call-4", "protectedUserName": "Mummy", "stage": "isolation",
  "claimedAgency": "LHDN", "summary": "The caller says Mum owes tax and must keep the call secret.",
  "quotes": [], "at": "2026-10-27T10:03:00Z"
}''';

const familyLongText = r'''{
  "kind": "alert", "callId": "call-5", "protectedUserName": "Mummy", "stage": "money",
  "claimedAgency": "Suruhanjaya Pencegahan Rasuah Malaysia",
  "summary": "The caller says Mum is under investigation and must move all of her savings into a safe account today, and that she must not tell her family or her bank, or she will be arrested.",
  "quotes": [
    "Akaun anda telah digunakan untuk kegiatan pengubahan wang haram dan anda perlu memindahkan semua wang anda ke akaun selamat kami hari ini juga, jika tidak anda akan ditahan oleh polis serta-merta.",
    "Jangan beritahu keluarga atau pegawai bank anda tentang perbualan ini kerana siasatan ini adalah sulit dan boleh menjejaskan kes anda jika anda berbuat demikian."
  ],
  "at": "2026-10-27T10:04:00Z"
}''';

/// Same call as [familyMoney]: Jaga now thinks it is less likely to be a scam.
const familyMayBeGenuine = r'''{
  "kind": "mayBeGenuine", "callId": "call-1", "protectedUserName": "Mummy", "stage": "money",
  "claimedAgency": "PDRM",
  "summary": "The caller gave details that match a real case.",
  "quotes": [],
  "at": "2026-10-27T10:03:40Z"
}''';

const familyAlertFixtures = [
  familyIsolation,
  familyMoney,
  familyCredentials,
  familyNoAgency,
  familyNoQuotes,
  familyLongText,
  familyMayBeGenuine,
];
