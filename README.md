# Jaga

Scam-call guardian for Malaysian families: it listens to *what* a caller says, not just *who* is calling, and stops the
money before it moves. Meta Global AI Developer Hackathon 2026, Indie track.

- The plan: [`docs/plan.md`](docs/plan.md) · Decisions: [`docs/adr/`](docs/adr) · Vocabulary: [`GLOSSARY.md`](GLOSSARY.md)
- Rules for humans and agents: [`AGENTS.md`](AGENTS.md)
- New here? Read the [team brief](docs/team-brief.md), then open the [call-flow diagram](docs/diagrams/jaga-call-flow.html) in a browser.
- Spec: [`docs/spec.md`](docs/spec.md) · Tickets: [GitHub Issues](https://github.com/qicai14/jaga/issues)

## Built before the Hackathon
The Official Rules require new work to be clearly identified. Everything up to the git tag `pre-hackathon` was written
before kickoff (26 Oct 2026, 12:00 PM ET) and is setup only: the plan, ADRs, spec and tickets, toolchain pins, agent
config, CI workflows, the `flutter create` app shell and a `/health` endpoint. All product features (telephony, ASR,
stage tracker, Muse Spark escalation, warnings, family alerts, Jaga Pause, Demo Bank, evaluation) are built during the
Hackathon, after that tag: `git log pre-hackathon..main`.

## One-time setup (Windows, macOS or Linux)
Everyone uses the same pinned versions (ADR 0004). Install these once:

| Tool | Why | Install |
|---|---|---|
| Git | version control | git-scm.com |
| FVM 4.3.1 | pins Flutter 3.47.7 | Windows: standalone zip, see below (no Chocolatey needed). Turn on Developer Mode (Settings → System → For developers) so FVM can create links. macOS/Linux: the install script at fvm.app |
| Android SDK + emulator | build and run the app | Android Studio (developer.android.com/studio), or the command-line tools only plus **Temurin JDK 21** (`winget install EclipseAdoptium.Temurin.21.JDK`; IntelliJ's bundled JBR can't build Android). Then `fvm flutter doctor --android-licenses` |
| uv 0.12.24 | pins Python 3.13 + packages | `powershell -c "irm https://astral.sh/uv/0.12.24/install.ps1 \| iex"` (Windows), `curl -LsSf https://astral.sh/uv/0.12.24/install.sh \| sh` (macOS/Linux) |
| Docker Desktop | runs the server exactly as deployed | docker.com |
| GitHub CLI | issues and PRs | cli.github.com, then `gh auth login` |

FVM on Windows (normal PowerShell, no admin), then open a new terminal and check `fvm --version`:
```powershell
$dir = "$env:USERPROFILE\.fvm-cli"
Invoke-WebRequest https://github.com/leoafarias/fvm/releases/download/4.3.1/fvm-4.3.1-windows-x64.zip -OutFile "$env:TEMP\fvm.zip"
Expand-Archive "$env:TEMP\fvm.zip" -DestinationPath $dir -Force
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$dir\fvm", "User")
```

Android SDK without Android Studio (command-line tools in `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest`, with
`ANDROID_HOME` and `JAVA_HOME` set), in a new terminal:
```powershell
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "emulator" "system-images;android-36;google_apis;x86_64"
avdmanager create avd -n jaga -k "system-images;android-36;google_apis;x86_64"   # answer "no" to the custom hardware profile
cd app; fvm flutter config --android-sdk "$env:ANDROID_HOME" --jdk-dir "$env:JAVA_HOME"; cd ..
```
Run the app: `fvm flutter emulators --launch jaga`, then `cd app && fvm flutter run -d emulator-5554`. On a Xiaomi/Redmi/POCO
phone, turn on **Install via USB** in Developer options first. Ignore `flutter doctor`'s Visual Studio line (Windows desktop only).

Then, from the repo root:
```bash
cd app && fvm install && fvm flutter pub get && fvm flutter test && cd ..
uv sync --locked --all-packages && uv run --all-packages pytest -q server/tests eval/tests
cp .env.example .env    # fill in keys later; JAGA_USE_FAKES=true works without any
docker compose up server   # http://localhost:8000/health -> {"status":"ok"}
```

## Agent setup
- **Claude Code:** `claude plugin install mattpocock-skills@claude-plugins-official`. Project skills and subagents load
  from `.claude/`.
- **GitHub Copilot (CLI or VS Code):** `copilot plugin marketplace add mattpocock/skills`, then
  `copilot plugin install mattpocock-skills@mattpocock` (VS Code: **Chat: Install Plugin From Source**, then
  `https://github.com/mattpocock/skills`). Copilot reads `AGENTS.md`, `.claude/skills/` and `.github/agents/`.

## How we work
1. Pick an unblocked ticket in your lane from GitHub Issues (filter by your `lane-x` label) and assign yourself.
2. `git switch -c <name>/<ticket-id>-<slug>`, then `/implement <ticket>` (Matt Pocock skills).
3. Review (`reviewer` agent or `/code-review`), rebase on `main`, open the PR (the template follows the `pr` skill).
4. CI green plus one approval from the folder owner (`.github/CODEOWNERS`), then squash-merge.
5. `/handoff` before you stop for the day.
