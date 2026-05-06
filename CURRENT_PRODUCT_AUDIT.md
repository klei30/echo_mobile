# Echo Current Product Audit

Last audited from code on 2026-05-06.

Execution checklist: [ULTIMATE_TODO.md](ULTIMATE_TODO.md).

This audit lists what exists today without repeating the same feature under multiple old names. The product should be understood as one mobile-first Echo system, powered by Home Brain when available and This Device when offline.

## Product Shape

Echo currently has four real product loops:

1. **Daily growth loop**: Talk -> Current Read -> Today priority -> Practice -> Outcome -> Proof.
2. **Opportunity loop**: Proof -> Opportunity plan -> missing evidence -> next practice.
3. **Personalization loop**: Chat/outcomes/preferences -> training pairs -> Gemma 4 LoRA -> eval -> adapter live.
4. **Runtime loop**: mobile app -> Home Brain or Cloud -> sync memory pack -> This Device offline -> queued signal syncs back.

These loops are already supported in code. The main problem is not missing endpoints; it is that the UI still exposes them as separate screens instead of one obvious journey.

## First-Class Mobile Screens

| Surface | File | What It Does | Status |
| --- | --- | --- | --- |
| Talk / Coach | `lib/page/layout/chat_page/chat_page.dart` inside `echo_mobile.dart` | Main chat, Echo context injection, runtime routing, MCP tool loop, voice input, offline Gemma routing. | Core |
| Today | `lib/page/echo_tabs/today_screen.dart` | Daily mission, priority, practice rep, check-in, intervention, revelation/decision states, outcome capture. | Core |
| Passport / You | `lib/page/echo_tabs/you_tab.dart` | Current read, proof/opportunity entries, progress, training readiness, runtime entry, Improve Echo entry. | Core |

Mobile bottom navigation is only these three tabs. This is good. More features should enter through these tabs instead of adding more bottom tabs.

## First-Class Desktop Sections

| Section | File | What It Does | Status |
| --- | --- | --- | --- |
| Coach | `echo_mobile.dart` | Desktop chat pane. | Core |
| Today | `today_screen.dart` | Same daily loop as mobile. | Core |
| Passport | `you_tab.dart` | Same personal dashboard as mobile. | Core |
| Proof | `_ProofDesktopPane` in `echo_mobile.dart` | Opens Proof Builder and Opportunities. | New / keep |
| Improve Echo | `echo_lab_screen.dart` | Training, memory, connections, signals hub. | Core but needs naming polish |
| Home Brain | `home_brain_screen.dart` | Desktop runtime status, Echo API, Gemma 4 vLLM, adapter, tunnel, QR pairing. | Core |
| Sync | `network_sync_setting.dart` | Pair/sync via QR and network settings. | Core but overlaps Home Brain |
| Tools | `mcp_server.dart` | Echo workflow cards plus raw MCP server setup. | Core but advanced |

Desktop is currently a strong control center. Product framing should keep it as Home Brain support, not the main user experience.

## Pushed Feature Screens

| Feature Group | Screens | Current Value | Recommendation |
| --- | --- | --- | --- |
| Decision Room | `ask_screen.dart`, `council_screen.dart`, `twin_screen.dart`, `parallel_self_screen.dart`, `shadow_tournament_screen.dart` | Multiple decision/perspective workflows. | Keep under one public Decision Room. Hide internal names. |
| Proof & Opportunities | `proof_builder_screen.dart`, `opportunities_screen.dart`, `outcome_capture_sheet.dart` | Turns outcomes into proof and maps proof to opportunities. | Make this one of the main value loops. |
| Training | `nightly_training_screen.dart`, training section in `echo_lab_screen.dart` | Training readiness, runs, eval, adapter status, trigger training. | Keep, but explain in user language. |
| Memory & Profile | `memories_screen.dart`, `operating_system_screen.dart`, `permanent_record_screen.dart`, `mirror_screen.dart`, `growth_timeline_screen.dart`, `talent_screen.dart` | Memory, rules, record, weekly reflection, growth, talent read. | Merge mentally into Passport. |
| Runtime | `local_model_setup_screen.dart`, `home_brain_screen.dart`, `pair_computer_screen.dart`, `remote_access_screen.dart` | Runtime selection, offline model import/download, memory sync, pairing, tunnel. | Rename to one Runtime / Home Brain panel. |
| Voice | `voice_session_screen.dart`, `voice_service.dart`, input-area voice controls | LiveKit voice session connected to `/v1/voice/token`. | Keep, but make it part of Talk/Today, not a separate product. |
| Daily Signals | `daily_checkin_screen.dart`, `outcome_capture_sheet.dart` | Check-ins, outcomes, practice logs. | Keep; feed Proof and Training visibly. |

## Backend Feature Map

| Domain | Main Endpoints | Status |
| --- | --- | --- |
| Auth | `/auth/register`, `/auth/login`, `/auth/me` | Built |
| Chat runtime | `/v1/chat/completions`, `/v1/models`, `/context`, `/save` | Built |
| Voice | `/v1/voice/token` | Built |
| Runtime health | `/health`, `/v1/system/health`, `/v1/experimental/gemma4/health` | Built |
| Gemma 4 lane | `/v1/experimental/gemma4/chat`, vLLM `:8003`, adapter loading | Built |
| Training | `/v1/training/status`, `/v1/training/summary`, `/v1/training/runs`, `/v1/training/eval`, `/trigger-training`, `/swap-adapter` | Built |
| Today | `/v1/today/priority`, `/v1/today/mission`, `/v1/practice/today`, `/v1/practice/log`, `/v1/outcome` | Built |
| Current read | `/v1/thesis/current`, `/v1/user/signal`, `/v1/user/stats`, `/v1/user/rank`, `/v1/user/confidence` | Built |
| Proof | `/v1/proof/items`, `/v1/proof/from-outcome`, `/v1/proof/seed` | Built |
| Opportunities | `/v1/opportunities`, `/v1/opportunities/generate` | Built |
| Memory and rules | `/v1/user/memories`, `/v1/user/rules`, `/v1/user/skills` | Built |
| Reflection/profile | `/v1/mirror/weekly`, `/v1/user/insights`, `/v1/user/talent`, `/v1/user/report`, `/v1/user/notable-quote` | Built |
| Decision workflows | `/v1/echo/decide`, `/v1/council/ask`, `/v1/twin/ask`, `/v1/twin/choose`, `/v1/tournament/run`, `/v1/tournament/choose`, `/v1/echo/simulate` | Built |
| Proactive engine | `/v1/interventions/next`, `/v1/interventions/ack`, `/v1/interventions/settings`, FCM token endpoint | Built |
| Offline | `/v1/offline/export`, mobile offline queue flush to `/save` | Built |
| Threads | `/v1/threads`, `/v1/threads/{thread_id}/resolve`, `/v1/threads/deduplicate` | Built |

The backend has more endpoints than the UI should show. The UI should expose product workflows, not endpoint categories.

## MCP Feature Map

Product workflow tools:

- `echo_training_center`
- `echo_daily_brief`
- `echo_current_read`
- `echo_decision_room`
- `echo_memory_editor`
- `echo_signal_capture`
- `echo_threads_inbox`
- `echo_proof`
- `echo_opportunities`

Older lower-level tools still exist:

- `chat`
- `get_memories`
- `get_operating_system`
- `get_growth_timeline`
- `get_today`
- `get_insights`
- `get_skills`
- `get_clone_status`
- `get_training_summary`
- `trigger_training`
- `save_training_pair`
- `save_memory`
- `add_rule`
- `run_tournament`
- `ask_twin`
- `ask_council`
- and related raw wrappers.

Recommendation: keep the product workflow tools as the public MCP story. Treat low-level tools as advanced/debug compatibility.

## Runtime And Model Capabilities

| Runtime | Current Capabilities | Boundaries |
| --- | --- | --- |
| Home Brain | Echo backend, full memory, Gemma 4 E2B via vLLM, LoRA adapter hot-swap, Training Studio, MCP, LiveKit voice, tunnel pairing. | Requires desktop services running. |
| Echo Cloud | Online fallback through backend-compatible runtime. | Less private than Home Brain; depends on hosted backend. |
| This Device | Android LiteRT-LM `.litertlm` model, offline Talk, synced memory pack, cached Today/Passport state, queued chat pairs. | No MCP tools, no on-device LoRA loading, no on-device training, smaller context. |

Current mobile model catalog:

- Qwen3 0.6B `.litertlm` for emulator testing.
- Gemma 4 E2B `.litertlm` as primary offline Echo model.
- Gemma 4 E4B `.litertlm` as heavier offline option.

Native Android bridge exists in `MainActivity.kt` using `com.google.ai.edge.litertlm:litertlm-android:0.10.2`, CPU backend, `maxNumTokens = 2048`.

## Training Capabilities

Built training assets:

- training pair capture from chat and offline queue;
- preference/DPO-style signals from choices and feedback;
- Unsloth/LlamaFactory training path;
- SFT and additional adapter variants in naming/docs;
- eval and rollback concepts;
- adapter status and hot-swap;
- scheduler infrastructure;
- MCP training workflow.

Training is currently a Home Brain/cloud capability, not a mobile offline capability.

## Duplicates And Naming Debt

| Issue | Details | Action |
| --- | --- | --- |
| `experiment_screen.dart` removed | It was dead code with no imports/routes. | Done. Fold future experiments into Today/Practice if needed. |
| Decision workflows are split | Ask, Council, Twin, Tournament, Parallel Self all represent parts of Decision Room. | Keep one public Decision Room entry and make other screens submodes. |
| Internal names leak | `ShadowTournamentScreen`, clone terminology, `get_clone_status`, and some internal copy still exist. | Rename public copy to perspectives, candidates, practice, or Decision Room. |
| Runtime naming is cleaner | Visible runtime labels are Home Brain, Echo Cloud, This Device, and Runtime. | Keep checking new copy for old labels. |
| Home Brain and Sync overlap | Pairing appears in Home Brain, Pair Computer, Remote Access, and Sync. | Make Runtime panel the primary entry; keep Sync as advanced settings. |
| Proof is still partially buried on mobile | Desktop has first-class Proof now. Mobile Proof lives inside Passport and Today outcomes. | Add a clearer Passport proof hero and opportunity gap card. |
| `FEATURES.md` replaced | Backend feature doc now reflects current product loops and endpoints. | Keep audit/TODO as source of truth. |

## What Not To Rebuild

Do not rebuild these from scratch:

- chat/runtime routing;
- backend endpoint layer;
- proof CRUD;
- opportunity generation;
- training summary/runs/eval;
- LiteRT-LM bridge;
- offline queue;
- Home Brain pairing;
- MCP workflow server.

The right work is orchestration, naming, and surfacing.

## Best Next Product Slices

1. **Talk Context Bridge**: show what Talk is using from Today, Passport, memory, runtime, and pending practice.
2. **Mobile Passport Proof Hero**: make Proof and Opportunities visible on mobile without adding a new bottom tab.
3. **Practice To Proof Completion Flow**: after a practice/outcome, show saved proof and next opportunity gap.
4. **Decision Room Consolidation**: one entry, three modes: Perspectives, Personal Lens, Scenario Test.
5. **Runtime Panel Unification**: unify Home Brain, This Device, Echo Cloud, downloads, memory sync, queued uploads.
6. **Training Readiness Story**: show what signal is missing and what changed after training.
7. **MCP Public Story**: expose workflow tools first; move raw tools to advanced/debug.
8. **Stale File Cleanup**: keep docs/screens from drifting again.
