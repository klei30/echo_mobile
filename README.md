# Echo — Mobile App

> Most people are not talentless. They are under-observed.

Echo is a private AI growth companion that travels on your phone. It watches patterns across your conversations, decisions, practice reps, and outcomes. Over time it builds a current read of who you are, proposes daily practice, simulates decisions, and records proof of what you can actually do — so you can turn that into real opportunity.

This is not another generic chatbot. Echo is built around a loop:

```
Talk → Current Read → Practice → Proof → Outcome → Improve Echo → Opportunity
```

The mobile app is the daily surface. The user's private **Home Brain** runs on their own desktop and gives the phone Gemma 4 inference, long-term memory, personal LoRA adapters, connected tools, voice, and training. When the user goes offline, the phone keeps working with on-device LiteRT-LM Gemma and a synced memory pack.

---

## What Echo Does

Echo is built for people without access to elite coaching, mentors, or constant connectivity. It gives every person a private AI that:

- **Observes patterns** across conversations, practice, decisions, and outcomes
- **Builds a current read** — a living thesis about your direction, strengths, and what to do next
- **Proposes daily practice** based on what needs deliberate work right now
- **Simulates decisions** through parallel reasoning before you commit
- **Records proof** — outcomes, artifacts, and feedback that become evidence you can use
- **Improves from your feedback** — trains a personal Gemma 4 LoRA adapter from the moments you mark as useful
- **Keeps working offline** with on-device LiteRT-LM Gemma and synced memory

---

## Mobile App — Three Tabs

### Talk
Natural conversation with Echo. Before every response, Echo injects your current read, today's priority, and relevant memories. After you respond, the turn becomes a potential training signal.

Runtime pill in the header shows whether you are using Home Brain (Gemma 4 + personal adapter), Cloud Echo, or This Device (offline LiteRT-LM). Tap it to see your current context snapshot: thesis, priority, practice rep, memory state.

### Today
Your daily action surface. Echo shows the single most useful next thing:

- Today's priority and daily mission
- Practice rep — one focused activity tied to your current read
- Daily check-in — structured outcome capture
- Decision Room entry when a choice needs parallel thinking
- Proactive interventions — trusted nudges Echo is allowed to send, each with a named reason

### You (Passport)
Your evolving profile. Echo shows what it currently believes about you, backed by evidence:

- **Current Read** — thesis with confidence label and supporting evidence chips
- **Discovery** — when Echo has enough signal, it reveals a named pattern: a strength, a direction, a readiness signal. Earned, not shown on day one.
- **Talent** — what Echo actually sees in how you think and act
- **Progress Evidence** — milestones, practice reps, decisions, model updates
- **Training State** — how close you are to the next personal model update
- **Memories and Rules** — what Echo is keeping and applying
- **Opportunities** — proof-scored paths Echo has identified (scholarship, portfolio, job, project, personal goal)
- **Runtime** — Home Brain / Cloud Echo / This Device selection

---

## Desktop Navigation

On wide screens Echo shows a full sidebar with seven sections:

| Section | Purpose |
| --- | --- |
| Talk | Main conversation workspace |
| Today | Daily practice and priority dashboard |
| You | Personal profile — thesis, talent, progress, proof, opportunities |
| Proof | Proof Builder and Opportunities — first-class on desktop |
| Improve Echo | Training Studio, memories, connected apps, signal capture |
| Home Brain | Service health, Gemma 4, tunnel, QR phone pairing |
| Advanced | Raw MCP server setup and Home Brain Connection |

---

## Runtime Modes

Echo has three runtime modes, all centered on the mobile app.

| Runtime | What it does |
| --- | --- |
| **Home Brain** | Private desktop runtime paired to the phone. Gemma 4 E2B via vLLM, personal LoRA adapter, full memory, Decision Room, Training Studio, connected tools, LiveKit voice, tunnel pairing. |
| **Cloud Echo** | Connected fallback when the desktop is off. Memory and product APIs stay live. |
| **This Device** | Offline LiteRT-LM on the phone. Synced memory pack injected into prompts. Conversations queue locally and upload to Home Brain when reconnected. |

---

## Key Screens

| Screen | Role |
| --- | --- |
| `OnboardingPage` | 5-step flow: Promise → Areas → Brain Picker → First Question → First Read |
| `ChatPage` | Talk with full Echo context, tool support, voice entry, starter actions |
| `TodayScreen` | Daily loop with seven states: silence / checking / morning check-in / interruption / council / discovery / comeback |
| `YouTab` | Personal profile — thesis, discovery, talent, proof, opportunities, training |
| `DiscoveryReadyScreen` | Earned entry to the discovery moment — cosmic orb with dashed-circle animation |
| `DiscoveryInsightScreen` | Pattern reveal — named pattern, narrative, feedback actions |
| `TalentScreen` | "What Echo Sees" — trait narrative, evidence list, correction row |
| `GrowthTimelineScreen` | Progress Evidence — milestone timeline |
| `ProofBuilderScreen` | Create proof items with intent seeding |
| `OpportunitiesScreen` | Scored opportunity paths with missing-proof tracking |
| `AskScreen` (Decision Room) | Ask a question, choose Council / Twin / Tournament |
| `CouncilScreen` | Multiple reasoning styles synthesize a question |
| `TwinScreen` | Two competing responses; choose the one that fits |
| `ShadowTournamentScreen` | Candidates compete, winner becomes an actionable mission |
| `ParallelSelfScreen` | Two diverging paths projected from current patterns |
| `OutcomeCaptureSheet` | Done/Skipped, energy, privacy, confidence, note — saves outcome and optional proof |
| `DailyCheckinScreen` | Structured daily outcome and habit capture |
| `NightlyTrainingScreen` | Training Studio — pairs, readiness, runs, eval, adapter status, trigger training |
| `HomeBrainScreen` | Echo API health, Gemma 4 vLLM, adapter status, tunnel, QR pairing |
| `LocalModelSetupScreen` | Runtime selection, LiteRT-LM model import/download, offline memory sync |
| `VoiceSessionScreen` | Realtime voice mode via LiveKit |
| `ConnectedAppsScreen` | MCP workflow cards and advanced server setup |
| `WhatEchoUsesScreen` | Memories, rules, and permanent record in one place |
| `RemoteAccessScreen` | Cloudflare tunnel and mobile URL setup |

---

## How Talk Connects to Today and You

Before every model response:

```
User types in Talk
  → EchoApiClient.fetchContext(message)
  → POST /context
  → Echo returns: memory + current read + today priority + practice + training readiness
  → Model receives full context
  → Model responds
  → Turn saved for memory and training
  → Today and You refresh from updated loop state
```

Talk is not a separate product. It is the observation surface that feeds everything else.

---

## Backend

The Echo backend is a FastAPI service in the sibling `echo/` project.

```
Echo Mobile App
  Talk / Today / You / Proof / Training / Offline
        |
        | local Wi-Fi, secure tunnel, cloud
        ↓
Echo Backend :8002
  Memory (mem0 + Qdrant), daily loop, Decision Room,
  proof, opportunities, training, voice, MCP tools
        |
        ↓
Home Brain Gemma 4 E2B vLLM :8003
  base Gemma 4 E2B or user LoRA adapter
```

See the [Echo backend repository](https://github.com/klei30/echo) for full API documentation and setup.

---

## Training and Personalization

Echo collects training signal from real interaction:

- Chat turns marked useful with thumbs up
- Decision Room choices (Twin, Tournament)
- Practice outcomes and daily check-ins
- Explicit feedback ("Not true", "Helpful")
- Life events and outcomes logged in Today

When enough signal is collected, Training Studio shows the readiness indicator. Training uses Unsloth/LlamaFactory to fine-tune a personal Gemma 4 E2B LoRA adapter on the user's own desktop. The adapter hot-swaps into vLLM and becomes Echo's default response lane.

The mobile app never trains locally. Training runs on Home Brain. Offline conversations queue and upload when reconnected.

---

## Offline Mode

Echo's offline mode is continuity, not a fallback product.

- Import or download a `.litertlm` Gemma 4 E2B model
- Sync an Echo memory pack from Home Brain or Cloud Echo
- Compressed memory injects into LiteRT-LM prompts
- Talk stays live without network
- Conversations queue locally
- Offline signal uploads to training when reconnected

Offline sync is available at: **You → Runtime → This Device → Sync Echo memory to this phone**

---

## MCP — Connected Tools

Echo uses MCP as the foundation for connected-action workflows.

Built-in Echo MCP product tools:

| Tool | Purpose |
| --- | --- |
| `echo_training_center` | Training readiness, DPO pairs, runs, eval, adapter status, trigger |
| `echo_daily_brief` | Priority, mission, practice, check-in, next intervention |
| `echo_current_read` | Thesis, evidence, discovery status, loop snapshot, user signal |
| `echo_decision_room` | Decide, Council, Twin, Tournament |
| `echo_memory_editor` | View, add, delete memories and rules |
| `echo_signal_capture` | Save pair, memory, rule, life event, outcome, practice result |
| `echo_threads_inbox` | List and resolve recurring threads |
| `echo_proof` | Proof items, from-outcome, missing proof tracking |
| `echo_opportunities` | Scored opportunity paths from current proof |

External MCP servers can be added from **Connected Apps** (Advanced on desktop). Supports stdio, SSE, and in-memory servers.

---

## Local Notifications

- Evening check-in reminder
- Echo intervention tap → routes to Today, Decision Room, or Opportunities
- Training-ready notification when enough outcomes exist
- Notification sync on app resume

---

## Download

| Platform | File | Notes |
| --- | --- | --- |
| Android | [echo-android.apk](https://github.com/klei30/echo_mobile/releases/latest/download/echo-android.apk) | Enable "Install unknown apps" in Android settings |
| Windows | [echo-windows.zip](https://github.com/klei30/echo_mobile/releases/latest/download/echo-windows.zip) | Extract and run `chatmcp.exe` |

---

## Getting Started

### Prerequisites

- Flutter 3.x
- Android toolchain (for mobile) or macOS/Windows (for desktop)
- Echo backend running at `http://localhost:8002` (or a tunnel URL)

### Install and Run

```powershell
flutter pub get
flutter run
```

### Build Debug APK

```powershell
flutter build apk --debug
```

### Connect to Echo Backend

On first launch, Echo shows the onboarding flow. Choose:

- **Home Brain** — pair with your desktop if it is running the Echo backend
- **Cloud Echo** — use an external API key
- **This Device** — offline LiteRT-LM mode (import a `.litertlm` model)

To pair with Home Brain:
1. Start the Echo backend on your desktop: `.\start_echo_services.bat`
2. Open **Home Brain** in the desktop app → generate a QR code
3. Scan the QR from **You → Runtime → Pair Computer** on mobile

---

## Hackathon — Gemma 4 Good

Echo was built for the [Kaggle Gemma 4 Good Hackathon](https://www.kaggle.com/competitions/gemma-4-good-hackathon).

**Digital Equity**: a private growth companion for people without access to elite coaching, mentorship, or reliable internet.

**Future of Education**: not a generic tutor, but a meta-learning system that discovers how each person learns, what they avoid, and what to practice next.

**Gemma 4 technical fit**:

- Home Brain runs Gemma 4 E2B locally via vLLM
- Offline mode runs LiteRT-LM Gemma 4 E2B on the Android device itself
- Personal LoRA adapters trained from user interaction using Unsloth
- Echo MCP server exposes product workflows for agentic use

---

## Project Layout

```
lib/
  echo/                 Echo API client, services, theme, design system
  page/
    echo_mobile.dart    Root shell, onboarding gate, runtime pill, navigation
    onboarding/         5-step onboarding flow
    echo_tabs/          All Echo product screens
    layout/             Chat page, sidebar, input area
    setting/            App and provider settings
  provider/             State: chat, models, settings
  mcp/                  MCP client — stdio, SSE, in-memory, streamable
  llm/                  Direct provider clients (OpenAI, Gemini, Ollama, etc.)
  dao/                  SQLite chat history
assets/
  echo_logo.png
pubspec.yaml
```

---

## Notes

- The Flutter package is named `chatmcp` internally. The product is **Echo**.
- Use product language everywhere user-facing: Talk, Today, You, Current Read, Practice, Proof, Decision Room, Home Brain, This Device, Improve Echo.
- Avoid internal/development language: shadow clone, twin battle, tournament, Genin/Chunin/Kage (shown in Talk header as level 1/2/3/mastery instead).

## License

See `LICENSE`.
