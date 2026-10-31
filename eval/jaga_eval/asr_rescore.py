"""ASR re-score on real phone calls (#69): Muse vs Whisper large-v3, WER/CER plus keyword flagging.

Pass mark (set before results): keyword hit rate >= 80% on terms said, and <= 1 false hit per call on average.
Clips, references and the keyword sheet live outside git in <clip_dir>; never commit them or print text.

  <clip_dir>/call_XX.<audio>        the recording
  <clip_dir>/call_XX.ref.txt        human reference (a few clips)
  <clip_dir>/call_XX.whisper.txt    Whisper output, made outside the repo:
      uvx whisper-ctranslate2 --model large-v3 --output_format txt --output_dir <clip_dir>
          <clip_dir>/call_XX.<audio>
      (then rename call_XX.txt to call_XX.whisper.txt)
  <clip_dir>/keywords.csv           column `clip`, then one column per term; cell = times said, blank = 0

  uv run python -m jaga_eval.asr_rescore <clip_dir> --templates call_01 call_02
      empty refs for the named clips + keywords.csv, never overwrites, no Muse call
  uv run python -m jaga_eval.asr_rescore <clip_dir>
      paid Muse run (cached in muse.local.json), prints the report

  uv run python -m jaga_eval.asr_rescore <clip_dir> --bias "Mandarin Chinese"
      a Mandarin clip dir is its own run: Muse languageBias is just that language, and a reference with
      mostly Chinese characters is scored by CER only (no word spaces, so no WER)

  uv run python -m jaga_eval.asr_rescore <clip_dir>
      --keywords "LHDN,PDRM,Bank Negara,akaun selamat,waran tangkap,TAC"
      replaces the Muse keyword bias for this run only ("" = none), e.g. 997 left out; the keyword table
      still counts every pack term. --bias/--keywords write muse.<hash>.local.json, never the default cache.

The report also checks the real stage pack (phrases and hard triggers; both speakers are in one mono
text, same on reference and Muse) on each reference and on the Muse text: which stages fire on each,
stage recall, and extra stages per call. Clips without a reference show their stages as-is, so a
genuine-speech run reads false stages per call off the same table.

Muse path: the batch endpoint from #18 (`batch_transcribe`): one POST per chunk, no socket pacing or flush,
and the chunk length is ours to control (#3 hit HTTP 400 on long calls). Audio goes through an 8 kHz mu-law
round-trip first, as a phone line would. Needs META_API_KEY in the environment.
"""

import argparse
import csv
import hashlib
import io
import json
import os
import random
import re
import subprocess
import tempfile
import wave
from dataclasses import dataclass
from pathlib import Path

import httpx

from jaga import stages
from jaga_eval import teleantifraud as tafd

CHUNK_S, OVERLAP_S = 30, 1
PASS_HIT, PASS_FALSE = 0.80, 1.0
AUDIO = {".wav", ".mp3", ".m4a", ".ogg", ".opus", ".flac", ".aac", ".amr", ".mp4"}
FILLERS = {"erm", "uh", "um", "hmm"}
# shortcut: a small fixed list of spellings, upgrade when a new variant shows up in the references.
VARIANTS = {"laa": "lah", "la": "lah", "kn": "kan", "mehh": "meh", "okay": "ok", "yaa": "yah", "ya": "yah"}
# shortcut: single words 0-9 only, compound numbers ("twenty one", "dua puluh") stay as words.
NUMBERS = {
    **{w: str(i) for i, w in enumerate("zero one two three four five six seven eight nine".split())},
    **{w: str(i) for i, w in enumerate("kosong satu dua tiga empat lima enam tujuh lapan sembilan".split())},
    "sifar": "0",
    "nol": "0",
}


def normalise(text: str) -> str:
    """Same for references and hypotheses. shortcut: no stemming, upgrade if WER is noisy."""
    text = re.sub(r"[^\w\s]", " ", text.lower().replace("[?]", " "))
    words = [w for w in text.split() if w not in FILLERS]
    return " ".join(NUMBERS.get(w, VARIANTS.get(w, w)) for w in words)


def edits(a: list, b: list) -> int:
    """Levenshtein distance."""
    prev = list(range(len(b) + 1))
    for i, x in enumerate(a, 1):
        cur = [i]
        for j, y in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (x != y)))
        prev = cur
    return prev[-1]


@dataclass
class Score:
    words: tuple[int, int]  # (edits, reference length)
    chars: tuple[int, int]

    @property
    def wer(self):
        return self.words[0] / self.words[1] if self.words[1] else 0.0

    @property
    def cer(self):
        return self.chars[0] / self.chars[1] if self.chars[1] else 0.0


CJK = re.compile(r"[一-鿿]")


def score(ref: str, hyp: str) -> Score:
    """Chinese has no word spaces, so a CJK reference is scored by CER only (spaces dropped, no WER)."""
    ref, hyp = normalise(ref), normalise(hyp)
    if len(CJK.findall(ref)) > len(ref.replace(" ", "")) / 2:  # mostly Chinese
        ref, hyp = ref.replace(" ", ""), hyp.replace(" ", "")
        return Score((0, 0), (edits(list(ref), list(hyp)), len(ref)))
    return Score((edits(ref.split(), hyp.split()), len(ref.split())), (edits(list(ref), list(hyp)), len(ref)))


def pooled(rows: list[Score], unit: str) -> float:
    """Total edits over total reference length, not the mean of per-clip rates."""
    total = sum(getattr(r, unit)[1] for r in rows)
    return sum(getattr(r, unit)[0] for r in rows) / total if total else 0.0


def pack_terms(region="my") -> list[str]:
    pack, seen, terms = stages.load_pack(region), set(), []
    for t in [*pack["keywords"], *pack["hardTriggers"]]:
        if t.lower() not in seen:
            seen.add(t.lower())
            terms.append(t)
    return terms


def _spelled(text: str, known: set) -> str:
    """Joins a run of single-character tokens ("9 9 7", "l h d n") only when the joined run is a term, so
    stray letters make no false hits. Keyword counting only. shortcut: a stray letter touching a spelled
    term spoils that run (a miss), upgrade to joining sub-runs if it shows up."""
    return re.sub(
        r"(?<!\S)\w(?: \w)+(?!\S)",
        lambda m: j if (j := m.group().replace(" ", "")) in known else m.group(),
        normalise(text),
    )


def occurrences(terms, hyp: str) -> dict:
    """Times each term is in the hypothesis. Longest term first, and its span is blanked, so "kod tac"
    does not also count for "TAC"."""
    known = {normalise(t).replace(" ", "") for t in terms}
    text, out = _spelled(hyp, known), {}
    for t in sorted(terms, key=lambda t: -len(normalise(t))):
        pat = rf"(?<!\w){re.escape(_spelled(t, known))}(?!\w)"
        out[t] = len(re.findall(pat, text))
        text = re.sub(pat, " # ", text)
    return out


def stages_fired(text: str) -> set[str]:
    """Stages whose phrases or hard triggers are anywhere in the text, matched in the tracker's `norm` form.
    Both speakers are in one mono text, same on reference and Muse. shortcut: no leg or order logic
    and no user-disclosure rules, so it can differ from a live call; fine for recall."""
    t, text = stages.StageTracker(stages.load_pack("my")), stages.norm(text)
    found = {s for s, ps in t.phrases.items() if any(p in text for p in ps)}
    return found | {s for p, s in t.hard_triggers.items() if p in text}


def stage_scores(ref: dict, muse: dict, resamples=1000, seed=0) -> dict:
    """ref, muse: clip -> set of stages. Recall = reference stages also on Muse; extras = Muse stages not on
    the reference (all of them for a clip without one). CIs are a percentile bootstrap over clips."""
    clips = list(muse)

    def tally(picks):
        got = sum(len(ref.get(c, set()) & muse[c]) for c in picks)
        total = sum(len(ref.get(c, set())) for c in picks)
        extra = sum(len(muse[c] - ref.get(c, set())) for c in picks)
        return (got / total if total else 0.0), extra / len(picks)

    rng, boots = random.Random(seed), []
    if not clips:
        return {"n": 0, "recall": 0.0, "extra_per_call": 0.0, "recall_ci": (0.0, 0.0), "extra_ci": (0.0, 0.0)}
    boots = [tally([rng.choice(clips) for _ in clips]) for _ in range(resamples)]
    recall, extra = tally(clips)
    return {
        "n": len(clips),
        "recall": recall,
        "extra_per_call": extra,
        "recall_ci": _ci([b[0] for b in boots]),
        "extra_ci": _ci([b[1] for b in boots]),
    }


def _tally(said: dict, hyp: dict, picks: list) -> tuple[dict, float, float]:
    """In keywords.csv, mark only the longest term said ("kod tac" is not also "TAC")."""
    terms = {}
    for c in picks:
        occ = occurrences(said[c], hyp[c])
        for t, n in said[c].items():
            s, h, f = terms.get(t, (0, 0, 0))
            terms[t] = (s + n, h + min(n, occ[t]), f + max(0, occ[t] - n))
    said_total = sum(s for s, _, _ in terms.values())
    hit = sum(h for _, h, _ in terms.values()) / said_total if said_total else 0.0
    return terms, hit, sum(f for _, _, f in terms.values()) / len(picks)


def _ci(xs):
    xs = sorted(xs)
    return xs[int(0.025 * len(xs))], xs[int(0.975 * len(xs)) - 1]


def keyword_scores(said: dict, hyp: dict, resamples=1000, seed=0) -> dict:
    """said: clip -> {term: times said}; hyp: clip -> Muse text. Clips without a hypothesis are skipped.
    CIs are a percentile bootstrap over calls."""
    clips = [c for c in said if c in hyp]
    if not clips:
        return {
            "n": 0,
            "terms": {},
            "hit_rate": 0.0,
            "false_per_call": 0.0,
            "hit_ci": (0.0, 0.0),
            "false_ci": (0.0, 0.0),
            "go": False,
        }
    terms, hit, false = _tally(said, hyp, clips)
    rng, hits, falses = random.Random(seed), [], []
    for _ in range(resamples):
        _, h, f = _tally(said, hyp, [rng.choice(clips) for _ in clips])
        hits.append(h)
        falses.append(f)
    return {
        "n": len(clips),
        "terms": terms,
        "hit_rate": hit,
        "false_per_call": false,
        "hit_ci": _ci(hits),
        "false_ci": _ci(falses),
        "go": hit >= PASS_HIT and false <= PASS_FALSE,
    }


def boot_pooled(rows: list[Score], unit: str, resamples=1000, seed=0):
    rng = random.Random(seed)
    return _ci([pooled([rng.choice(rows) for _ in rows], unit) for _ in range(resamples)])


def merge(parts: list[str], max_overlap=12) -> str:
    """Joins chunk transcripts, dropping the words repeated by the 1 s overlap at each seam.
    shortcut: exact word match on the seam (a mis-heard word leaves a duplicate), upgrade to fuzzy."""
    out: list[str] = []
    for part in parts:
        words = part.split()
        for k in range(min(max_overlap, len(out), len(words)), 0, -1):
            if [normalise(w) for w in out[-k:]] == [normalise(w) for w in words[:k]]:
                words = words[k:]
                break
        out += words
    return " ".join(out)


def split_wav(wav: bytes, chunk=CHUNK_S, overlap=OVERLAP_S) -> list[bytes]:
    with wave.open(io.BytesIO(wav)) as w:
        rate, width, channels = w.getframerate(), w.getsampwidth(), w.getnchannels()
        frames = w.readframes(w.getnframes())
    size = width * channels
    n, step, start, out = len(frames) // size, (chunk - overlap) * rate, 0, []
    while True:
        end = min(start + chunk * rate, n)
        buf = io.BytesIO()
        with wave.open(buf, "wb") as w:
            w.setnchannels(channels)
            w.setsampwidth(width)
            w.setframerate(rate)
            w.writeframes(frames[start * size : end * size])
        out.append(buf.getvalue())
        if end >= n:
            return out
        start += step


def phone_wav(path) -> bytes:
    """ffmpeg round-trip through 8 kHz mu-law (a phone line), back to mono 16 kHz PCM WAV."""
    with tempfile.TemporaryDirectory() as tmp:
        mu, out = Path(tmp) / "mu.wav", Path(tmp) / "out.wav"

        def ff(src, dst, rate, codec):
            cmd = [
                "ffmpeg",
                "-v",
                "error",
                "-y",
                "-i",
                str(src),
                "-ar",
                rate,
                "-ac",
                "1",
                "-c:a",
                codec,
                str(dst),
            ]
            subprocess.run(cmd, check=True)

        ff(path, mu, "8000", "pcm_mulaw")
        ff(mu, out, "16000", "pcm_s16le")
        return out.read_bytes()


def muse_post(bias=None, keywords=None):
    key = os.environ.get("META_API_KEY", "")
    if not key:
        raise SystemExit("META_API_KEY is not set")
    base = os.environ.get("META_API_BASE_URL", "https://api.meta.ai/v1").rstrip("/")
    client = httpx.Client(base_url=base, headers={"Authorization": f"Bearer {key}"}, timeout=300)
    return lambda wav, name: " ".join(t for _, t in tafd.batch_transcribe(wav, name, client, bias, keywords))


def clips_in(d: Path) -> list[Path]:
    return sorted(p for p in d.glob("*") if p.suffix.lower() in AUDIO)


def read_said(d: Path) -> dict:
    with (d / "keywords.csv").open(encoding="utf-8", newline="") as f:
        return {
            row["clip"]: {t: int(v or 0) for t, v in row.items() if t != "clip"} for row in csv.DictReader(f)
        }


def templates(d: Path, names: list[str]):
    """Never overwrites an existing file."""
    for n in names:
        p = d / f"{n}.ref.txt"
        if not p.exists():
            p.write_text("", encoding="utf-8")
    kw = d / "keywords.csv"
    if not kw.exists():
        with kw.open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f)
            w.writerow(["clip", *pack_terms()])
            w.writerows([c.stem] + [""] * len(pack_terms()) for c in clips_in(d))


def _wer(s: Score) -> str:
    return f"{s.wer:.3f}" if s.words[1] else "n/a"


def run(d, transcribe=None, phone=phone_wav, split=split_wav, out=print, bias=None, keywords=None):
    d = Path(d)
    cache_path = d / "muse.local.json"
    if (
        bias is not None or keywords is not None
    ):  # own cache, so the default run's transcripts stay as they are
        tag = hashlib.sha256(json.dumps([bias, keywords]).encode()).hexdigest()[:8]
        cache_path = d / f"muse.{tag}.local.json"
    out(f"Muse cache: {cache_path.name}")
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.exists() else {}
    for clip in clips_in(d):
        if cache.get(clip.name):  # an empty entry is done again
            continue
        transcribe = transcribe or muse_post(bias, keywords)
        cache[clip.name] = merge([transcribe(c, clip.name) for c in split(phone(clip))])
        tmp = cache_path.with_name(cache_path.name + ".tmp")
        tmp.write_text(json.dumps(cache, ensure_ascii=False), encoding="utf-8")
        os.replace(tmp, cache_path)  # a crash never leaves half a cache
    muse = {Path(k).stem: v for k, v in cache.items()}
    refs = {p.name.removesuffix(".ref.txt"): p.read_text(encoding="utf-8") for p in d.glob("*.ref.txt")}
    refs = {k: v for k, v in refs.items() if v.strip()}
    whisper = {
        k: (d / f"{k}.whisper.txt").read_text(encoding="utf-8")
        for k in refs
        if (d / f"{k}.whisper.txt").exists()
    }
    lines = ["# ASR re-score (#69)", "", f"## Error rates (n = {len(refs)} clips with references)", ""]
    lines += ["| System | Clip | WER | CER |", "|---|---|---|---|"]
    for name, hyps in {"Muse": muse, "Whisper": whisper}.items():
        rows = {k: score(refs[k], hyps[k]) for k in refs if k in hyps}
        lines += [f"| {name} | {k} | {_wer(s)} | {s.cer:.3f} |" for k, s in rows.items()]
        if rows:
            r = list(rows.values())
            w, c = boot_pooled(r, "words"), boot_pooled(r, "chars")
            has_words = any(x.words[1] for x in r)
            wp = f"{pooled(r, 'words'):.3f} (95% CI {w[0]:.3f} to {w[1]:.3f})" if has_words else "n/a"
            lines.append(
                f"| {name} | pooled (n={len(r)}) | {wp}"
                f" | {pooled(r, 'chars'):.3f} (95% CI {c[0]:.3f} to {c[1]:.3f}) |"
            )
    if muse:
        fired = {k: stages_fired(t) for k, t in muse.items()}
        ref_fired = {k: stages_fired(t) for k, t in refs.items() if k in muse}
        st = stage_scores(ref_fired, fired)
        lines += ["", f"## Stage recall, real stage tracker (n = {st['n']} calls)", ""]
        lines += ["| Clip | On reference | On Muse | Extra on Muse |", "|---|---|---|---|"]
        for k, f in fired.items():
            ref_f = ref_fired.get(k)
            ref_txt = "no reference"
            show = lambda x: ", ".join(sorted(x)) or "-"  # noqa: E731
            on_ref = ref_txt if ref_f is None else show(ref_f)
            lines.append(f"| {k} | {on_ref} | {show(f)} | {show(f - (ref_f or set()))} |")
        lines += [
            "",
            f"Recall {st['recall']:.3f} (95% CI {st['recall_ci'][0]:.3f} to {st['recall_ci'][1]:.3f}), "
            "reference stages also on Muse.",
            f"Extra stages per call {st['extra_per_call']:.2f} (95% CI {st['extra_ci'][0]:.2f} to "
            f"{st['extra_ci'][1]:.2f}), Muse stages not on the reference (all of them without one).",
        ]
    if (d / "keywords.csv").exists():
        k = keyword_scores(read_said(d), muse)
        lines += ["", f"## Keyword flagging, Muse (n = {k['n']} calls)", ""]
        lines += ["| Term | Said | Hit | False hits |", "|---|---|---|---|"]
        lines += [f"| {t} | {s} | {h} | {f} |" for t, (s, h, f) in k["terms"].items()]
        lines += [
            "",
            f"Hit rate {k['hit_rate']:.3f} (95% CI {k['hit_ci'][0]:.3f} to {k['hit_ci'][1]:.3f}), "
            f"pass mark >= {PASS_HIT}.",
            f"False hits per call {k['false_per_call']:.2f} (95% CI {k['false_ci'][0]:.2f} to "
            f"{k['false_ci'][1]:.2f}), pass mark <= {PASS_FALSE:g}.",
            f"Decision: {'GO' if k['go'] else 'NO-GO'}",
        ]
    out("\n".join(lines))


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("clip_dir")
    ap.add_argument("--templates", nargs="+", metavar="CLIP", help="write empty refs + keywords.csv, no Muse")
    ap.add_argument("--bias", help='Muse languageBias for this run, e.g. "Mandarin Chinese"')
    ap.add_argument(
        "--keywords", help="comma-separated Muse keywords for this run, '' for none (term table unchanged)"
    )
    args = ap.parse_args(argv)
    if args.templates:
        templates(Path(args.clip_dir), args.templates)
    else:
        kw = None if args.keywords is None else [k.strip() for k in args.keywords.split(",") if k.strip()]
        run(args.clip_dir, bias=[args.bias] if args.bias else None, keywords=kw)


if __name__ == "__main__":
    main()
