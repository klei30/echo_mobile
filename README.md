# Echo + Chat UI

Echo is a local-first personal learning system with a cross-platform Chat UI.

The system combines chat, long-term memory, daily practice, decision workflows, MCP tools, local model routing, personal model training, and desktop-to-mobile pairing. The goal is not to be another generic chatbot. Echo observes useful signals over time, builds a current read of the user, helps them make better decisions, and trains a personal model from real feedback.

## Product Idea

Most people are not talentless. They are under-observed.

Echo is designed to notice patterns across conversations, decisions, practice reps, outcomes, and corrections. It turns those signals into:

- A current read of the user.
- Daily priorities and practice reps.
- Long-term memory and personal rules.
- Decision workflows that compare multiple useful perspectives.
- Training data for a personal model.
- Local-first desktop/mobile workflows.
- MCP tools that let Echo operate across a user’s work environment.

## System Overview

```text
Mobile / Desktop Chat UI
        |
        | chat, tabs, MCP tools, sync, local brain pairing
        v
Echo FastAPI backend :8002
        |
        |-- /context memory + loop state injection
        |-- /v1/chat/completions OpenAI-compatible runtime
        |-- /save training pair capture
        |-- /v1/* product APIs
        |-- SQLite local state
        |-- mem0 / vector memory
        |-- scheduler and interventions
        |-- training orchestrator
        |
        |-- Local model lane, Gemma 4 E2B via vLLM
        |-- Personal LoRA adapters
        |-- Teacher fallback when policy allows
        |
        `-- Echo MCP server for external agents and tools
```

## Main Components

| Component | Purpose |
| --- | --- |
| Chat UI | Flutter app for mobile, desktop, and web-style layouts |
| Echo backend | FastAPI sidecar that owns context, memory, routing, training, and product APIs |
| Echo model context | `/context` builds memory and loop-state injection before chat responses |
| OpenAI-compatible runtime | `/v1/chat/completions` lets the Chat UI or other clients talk to Echo like an OpenAI provider |
| Personal model training | Collects pairs, feedback, DPO preferences, evals, and LoRA adapters |
| Local Brain | Desktop control center for API, vLLM, adapter, tunnel, and phone pairing |
| Echo MCP | FastMCP server exposing product workflows to agents and developer tools |
| MCP server manager | Chat UI can connect to external MCP servers and expose tools inside chat |

## Chat UI

The Chat UI is the user-facing app. It is built with Flutter and supports mobile and desktop layouts.

### Mobile Navigation

| Tab | Purpose |
| --- | --- |
| Talk | Main conversation surface. Calls Echo `/context` before responses and saves useful turns back into Echo. |
| Today | Daily priority, practice rep, check-in, reality check, intervention, and next useful action. |
| You | Current read, potential, progress evidence, training readiness, memory, and personal model status. |

### Desktop Navigation

| Section | Purpose |
| --- | --- |
| Talk | Main chat workspace |
| Today | Daily practice and priority dashboard |
| You | Personal dashboard |
| Studio | Training Studio for model training, memory, signals, and connections |
| Local Brain | Desktop runtime control center |
| Sync | Pair and sync data between devices |
| Tools | Echo tools and MCP server management |

## Current Screens

### Core Screens

- `Talk`: chat with Echo, tool usage, message feedback, starter actions, voice entry.
- `Today`: daily mission, priority, practice rep, check-in, reflection, intervention states.
- `You`: current read, progress, potential, training readiness, and Training Studio entry.
- `Training Studio`: model training, Decision Room, Personal Lens, memory, tools, and signal capture.
- `Local Brain`: starts/checks Echo API, local model, adapter status, secure tunnel, and mobile QR pairing.
- `Tools`: Echo workflow cards plus raw MCP server setup.
- `Sync`: local network sync and mobile/desktop data transfer.

### Echo Feature Screens

- `Decision Room`: compare multiple perspectives on a real question.
- `Perspective Panel`: multi-perspective synthesis for decisions.
- `Personal Lens`: A/B comparison between general and personal guidance.
- `Scenarios`: shows alternative paths based on observed patterns.
- `Model Training`: readiness, training runs, eval, adapter status, preference signal.
- `Potential`: hidden talent narrative and evidence.
- `Progress Evidence`: milestones, reps, decisions, and model updates.
- `Reflection`: weekly report and observed rules.
- `Daily Check-in`: structured daily signal capture.
- `Memories`: stored user memories.
- `Rules`: durable preferences and behavioral rules.
- `Record`: long-term evidence and notable moments.
- `Voice Session`: realtime voice mode through LiveKit.
- `Pair Computer`: scan/connect mobile to desktop.
- `Remote Access`: tunnel and mobile URL setup.

## How Talk Connects To Today And You

Talk is not separate from the other tabs.

Before every model response, the Chat UI calls:

```text
POST /context
```

Echo returns memory and loop state, including:

- Current read / thesis.
- Today’s priority.
- Today’s practice rep, when cached.
- Training readiness.
- Preference pair readiness.

The Chat UI then sends that context into the model path. After the assistant responds, the turn is saved back through Echo so Today and You can update.

```text
User asks in Talk
    -> Chat UI calls /context
    -> Echo injects memory + current read + today priority + practice + training readiness
    -> Model responds
    -> Chat UI saves pair/outcome
    -> Today and You refresh from Echo loop state
```

## Echo Backend

The backend lives in the sibling `echo/` project. It is a FastAPI service that owns the product intelligence.

### Core Runtime APIs

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Basic health check |
| GET | `/v1/models` | OpenAI-style model list |
| POST | `/v1/chat/completions` | Main OpenAI-compatible chat endpoint |
| POST | `/context` | Memory and loop-state context injection |
| POST | `/save` | Save conversation pair for memory/training |
| GET | `/v1/system/health` | Echo API, DB, model, adapter, and training health |

### Auth

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/auth/register` | Create local user |
| POST | `/auth/login` | Login and receive JWT |
| GET | `/auth/me` | Current authenticated user |

### Daily Loop

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/v1/loop/snapshot` | Overall loop state |
| GET | `/v1/today/priority` | Today’s priority |
| GET | `/v1/today/mission` | Daily mission |
| GET | `/v1/reality/check` | Reality check |
| GET | `/v1/practice/today` | Daily practice rep |
| POST | `/v1/practice/log` | Mark practice done/skipped |
| GET | `/v1/daily/questions` | Daily check-in questions |
| GET | `/v1/daily/checkin/status` | Check-in state |
| POST | `/v1/daily/checkin` | Submit check-in |
| GET | `/v1/interventions/next` | Next trusted nudge |
| POST | `/v1/interventions/ack` | Acknowledge intervention |

### Current Read And Growth

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/v1/thesis/current` | Current read with evidence |
| GET | `/v1/growth/timeline` | Progress evidence |
| GET | `/v1/revelation/status` | Readiness for deeper insight |
| GET | `/v1/user/talent` | Potential/talent narrative |
| GET | `/v1/user/signal` | Current signal |
| GET | `/v1/user/rank` | Progress rank |
| GET | `/v1/user/report` | Full user report |

### Memory And Rules

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/v1/user/memories` | List memories |
| POST | `/v1/user/memories` | Add memory |
| DELETE | `/v1/user/memories` | Delete all memories |
| DELETE | `/v1/user/memories/{memory_id}` | Delete one memory |
| GET | `/v1/user/rules` | List rules |
| POST | `/v1/user/rules` | Add rule |
| DELETE | `/v1/user/rules/{rule_id}` | Delete rule |
| GET | `/v1/user/skills` | Extracted skills |
| GET | `/v1/user/stats` | User stats |
| GET | `/v1/user/confidence` | Topic confidence |
| GET | `/v1/user/insights` | Pattern insights |

### Decision Workflows

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/v1/echo/decide` | Decide what Echo should do next |
| POST | `/v1/council/ask` | Perspective Panel |
| POST | `/v1/tournament/run` | Compare multiple candidate responses |
| POST | `/v1/tournament/choose` | Save winning perspective |
| POST | `/v1/twin/ask` | Personal Lens A/B comparison |
| POST | `/v1/twin/choose` | Save preferred answer |
| POST | `/v1/echo/simulate` | Scenario simulation |
| GET | `/v1/threads` | Active pattern threads |
| POST | `/v1/threads/{thread_id}/resolve` | Resolve thread |
| POST | `/v1/threads/deduplicate` | Deduplicate threads |

### Training

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/v1/training/status` | Current training state |
| GET | `/v1/training/summary` | Training readiness |
| GET | `/v1/training/runs` | Training run history |
| GET | `/v1/training/eval` | Latest eval |
| GET | `/v1/training/history` | Checkpoint history |
| POST | `/trigger-training` | Trigger training manually |
| POST | `/swap-adapter` | Hot-swap adapter into vLLM |

### Voice And Notifications

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/v1/voice/token` | LiveKit voice room token |
| POST | `/v1/user/fcm-token` | Register mobile push token |
| GET | `/v1/interventions/settings` | Read nudge settings |
| POST | `/v1/interventions/settings` | Update nudge settings |

## Model And Context Path

Echo can operate as an OpenAI-compatible provider.

Main chat flow:

```text
Chat UI
  -> EchoClient.fetchContext(message)
  -> POST /context
  -> system injection + loop state
  -> selected model route
  -> POST /v1/chat/completions
  -> stream response
  -> save pair or outcome
```

Routing supports:

- Local Gemma 4 E2B lane.
- User LoRA adapter when available.
- OpenAI-compatible fallback through Echo.
- Tool-safe prompt injection when MCP tools are active.
- Direct external LLM provider mode when configured.

## Personal Training

Echo learns from:

- Chat pairs.
- Thumbs up/down.
- “Useful” / “Not true” feedback.
- Decision Room choices.
- Personal Lens choices.
- Daily check-ins.
- Practice completion.
- Life events and outcomes.
- Manually saved memories and rules.

Training readiness is shown in the Chat UI and available through the API. Training can be triggered manually from the Training Studio or through Echo MCP. The backend also contains scheduled training infrastructure.

## Local Brain And Desktop Pairing

The desktop Chat UI includes a Local Brain screen for running Echo on the user’s computer.

It can:

- Check Echo API health.
- Start Echo API on Windows/WSL.
- Check local vLLM model status.
- Check whether the personal adapter is loaded.
- Start a Cloudflare quick tunnel.
- Generate a QR code so the mobile app can pair with the desktop.
- Store the resolved Echo host through `EchoHostService`.

Typical pairing flow:

```text
Desktop Chat UI
  -> Local Brain
  -> Start Echo API
  -> Start Local Model
  -> Start Tunnel
  -> Show QR
  -> Mobile scans QR
  -> Mobile uses desktop Echo backend
```

## MCP Support

There are two MCP layers.

### 1. Echo MCP

The `echo/echo_mcp.py` server exposes Echo product workflows through FastMCP.

Primary workflow tools:

| Tool | Purpose |
| --- | --- |
| `echo_training_center` | Training readiness, latest run, eval, adapter, trigger training |
| `echo_daily_brief` | Priority, mission, practice, check-in, next intervention |
| `echo_current_read` | Thesis, evidence, loop state, rank, signal |
| `echo_decision_room` | Decide, Perspective Panel, Decision Room, Personal Lens, scenarios |
| `echo_memory_editor` | View/add/delete memories and rules |
| `echo_signal_capture` | Save pairs, memory, rule, life event, outcome, practice, check-in |
| `echo_threads_inbox` | List, resolve, and deduplicate active threads |

Echo MCP also keeps lower-level legacy tools for direct access to memories, rules, stats, training, thesis, daily questions, practice, decisions, and conversation history.

### 2. Chat UI MCP Manager

The Chat UI can install and run MCP servers from the Tools screen.

It supports:

- stdio MCP servers.
- SSE / streamable MCP clients.
- In-memory MCP servers.
- Tool visibility inside the chat loop.
- Tool-safe Echo context injection when tools are active.
- Server add/edit/delete/start/stop from the UI.

When MCP tools are enabled, the Chat UI preserves the tool prompt and asks Echo to use tool-safe memory context instead of blocking tool calls.

## Notifications And Interactivity

The mobile app includes local notification support:

- Evening Signal notification.
- Backend-driven Echo intervention notification.
- Training-ready notification when enough signal exists.
- Notification tap routing to Today, Training, Potential, Progress, or Decision Room.
- Notification sync on app resume.

Current limitation:

- Mobile does not auto-start training in the background.
- Training should be started by the backend/desktop scheduler or by explicit user confirmation.

## Data Storage

The Chat UI stores local app data under the platform app data directory.

Common files:

- `chatmcp.db`: local chat database.
- `shared_preferences.json`: app settings.
- `mcp_server.json`: MCP server configuration.
- `logs/`: app logs.

Echo backend stores product intelligence in its own local database and training folders:

- SQLite tables for users, pairs, rules, theses, events, outcomes, interventions, training runs, and device tokens.
- Vector memory through the configured memory layer.
- Training data and adapters under the Echo training directories.

## Running Locally

### Start Echo Backend

From the `echo/` project:

```powershell
python main.py
```

Expected local URL:

```text
http://localhost:8002
```

### Start Local Model

The current desktop helper expects the Gemma 4 E2B vLLM script in the Echo project:

```powershell
wsl -d Ubuntu-24.04 bash /mnt/c/Users/ASUS/Desktop/echo/start_gemma4_e2b_vllm.sh
```

### Run Chat UI

From this project:

```powershell
flutter pub get
flutter run
```

Build debug APK:

```powershell
flutter build apk --debug
```

## Development Notes

- The Flutter package is still named `chatmcp` internally.
- The user-facing product should be described as **Echo + Chat UI**.
- Some route names still refer to older internal concepts for backward compatibility.
- The active product language should use: Current Read, Priority, Practice, Decision Room, Personal Lens, Training Studio, Local Brain, Memory, Rules, Progress Evidence.
- Avoid user-facing “clone” or anime-inspired naming unless describing old/internal implementation.

## Current Status

Implemented:

- Cross-platform Flutter Chat UI.
- Mobile tabs and desktop navigation.
- Echo auth and API client.
- Echo context injection into Talk.
- Today, You, Training Studio, Local Brain, Tools, Sync.
- OpenAI-compatible Echo runtime.
- Memory, rules, thesis/current read, practice, outcomes, growth timeline.
- Decision workflows.
- Voice session screen.
- Local notifications.
- Desktop tunnel pairing.
- MCP server manager.
- Echo FastMCP workflow server.
- Personal model training APIs and adapter status.

Still improving:

- Full product naming cleanup in every internal file.
- More responsive desktop layouts for all screens.
- Safer autonomous training controls.
- Stable named tunnel support.
- More polished MCP workflow execution inside the Chat UI.
