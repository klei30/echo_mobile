# Echo Ultimate Product TODO

Last audited from code on 2026-05-11.

This is the execution checklist for turning the current Echo system into one clear product:

```text
Echo helps people discover their path, practice toward it, prove their growth,
and find where it can matter.
```

The product should not feel like a chatbot, productivity dashboard, journal, MCP client, or model-training demo. It should feel like a private apprenticeship layer for human potential.

Core loop:

```text
Signal -> Read -> Practice -> Outcome -> Proof -> Place -> Improve Echo
```

Product dictionary:

- `Path`: what Echo sees emerging in the user, with evidence and correction.
- `Practice`: one real-world test or rep.
- `Proof`: evidence from outcomes, artifacts, decisions, and human feedback.
- `Place`: where that proof could matter: school, job, project, scholarship, community, personal goal.
- `What Echo Uses`: memories, rules, evidence, corrections.
- `Where Echo Thinks`: Home Brain, Cloud, This Device.
- `Improve Echo`: personal model update and training readiness.

Interaction model from the Figma/HTML direction:

- One screen, one job. Every surface should push the loop forward instead of showing all available features.
- Every save needs a visible consequence: what Echo learned, what proof changed, and what to do next.
- Pairing/runtime state must be visible before the user has to debug a connection.
- Talk must show that it is using Today, You, memory, and runtime context.
- You must be a trust surface first: read, evidence, correction, proof, place.
- Advanced model/training controls belong behind `Improve Echo` or `Where Echo Thinks`.

Visual system:

- Primary AI/runtime blue: `#2D7DD2`.
- Proof navy: `#243E73`.
- Practice green: `#1FA971`.
- Memory violet: `#6F5DD3`.
- Place/opportunity gold: `#C59A34`.
- Risk/correction coral: `#D96B5F`.
- Light canvas: `#F7FAFC`; surface: `#FFFFFF`; text: `#101820`.
- Plus Jakarta Sans for UI, Newsreader for meaningful reads/insights, JetBrains Mono for labels and status metadata.

---

## Corrected Execution Snapshot

This section is the authoritative TODO as of the latest code audit. Lower sections keep the broader inventory, but this is the build order.

### Already Built

- [x] Blue-first shared visual system in `lib/echo/echo_theme.dart`.
- [x] Shared type direction in `lib/echo/echo_design_system.dart`: Plus Jakarta Sans, Newsreader, JetBrains Mono.
- [x] `You` public order: `Path -> Proof -> Place -> Control`.
- [x] `You` thesis card is now the first meaningful surface.
- [x] `You` has confidence, evidence rows, and "what would change this read".
- [x] `You` public `PLACE PLAN` card exists.
- [x] `What Echo Uses` has tabs for Memories, Rules, Evidence, and Corrections.
- [x] `EchoLoopReceipt` component exists.
- [x] `OutcomeCaptureSheet.show()` displays backend-driven `EchoLoopReceipt` after saves.
- [x] Training readiness row shows `ready` instead of broken over-ready counts like `41/20`.
- [x] `Where Echo Thinks` has a partial three-runtime surface in `local_model_setup_screen.dart`.
- [x] Talk has the five-action reply strip shape: Practice, Remember, Decide, Outcome, Proof.
- [x] Talk has a visible context row for Today, Read, and Runtime mode.
- [x] Proof Builder saves now show loop receipts and include Place-oriented quick starts.
- [x] `/v1/outcome`, `/v1/proof/items`, and `/v1/reply/action` return `loop_delta`.
- [x] Public Growth Card copy is now reframed as Proof Card with a privacy-safe "what this proves" line.

### Partially Built

- [ ] Product language cleanup is partial: public copy uses `Practice Versions` and `Personal Lens` in some places, but internal/public leaks still exist.
- [ ] `You` trust surface is partial: correction edit and next missing proof exist, but corrections still save as outcomes instead of a dedicated correction table.
- [ ] Loop receipt is functional MVP: backend returns `loop_delta`, but it is not yet an inline Today strip or offline queue receipt.
- [ ] Runtime panel is partial: capability matrix exists locally, but not fully driven by `/v1/runtime/capabilities`; no last sync time.
- [ ] Improve Echo copy is partial: visible copy says moments/lessons in places, but `adapter`, `dpo`, and `vllm` still leak in Advanced surfaces.
- [ ] Proof Builder is now Place-oriented, but feedback request and public artifact creation are still quick-start capture, not full workflows.
- [ ] Place catalog has seeds and `community`, but scoring explanations still need polish.
- [ ] Proof Card exists as share text/screen copy, but redaction preview and image export are not built.

### Not Built

- [x] Remove Today XP pill and old XP messages.
- [x] Replace `Good morning. Echo is listening.` with non-surveillance copy.
- [x] Add backend `loop_delta` for saved outcomes.
- [x] Show receipt after direct Proof Builder saves.
- [x] Build `What Echo Uses` real tabs: Memories, Rules, Evidence, Corrections.
- [ ] Add proof item source, confidence, last-used, delete/correct actions in one surface.
- [ ] Merge feedback request, public-safe artifact, readiness, and Place plan into Proof Builder.
- [x] Add Talk context row: `Today`, `Read`, `Runtime`.
- [ ] Make Decision Room end in one concrete next action.
- [ ] Finish Proof Card: privacy filter, redaction preview, export/share image, "what this proves".

---

## Ultimate Build Plan

### Slice 1: First-Impression Cleanup

Goal: remove the old product signals that make Echo feel like a dashboard/game instead of an apprenticeship loop.

Files:

- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/echo_tabs/revelation_screen.dart`
- `lib/page/echo_tabs/twin_screen.dart`
- `lib/page/echo_tabs/shadow_tournament_screen.dart`
- `lib/page/echo_tabs/ask_screen.dart`
- `lib/page/echo_tabs/nightly_training_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`

Tasks:

- [ ] Remove `_xpMessage`, `_xpFade`, XP pill rendering, and all `+XP` strings from Today.
- [ ] Replace `Good morning. Echo is listening.` with `Today, Echo has one useful step for you.`
- [ ] Rename public `Revelation` copy to `Discovery`.
- [ ] Keep route/class names if needed, but public text must say `Discovery`.
- [ ] Rename visible `Twin` text to `Personal Lens`; keep endpoint names.
- [ ] Rename visible `Tournament` text to `Practice Versions`; keep endpoint names.
- [ ] Replace visible `adapter` with `personal style`.
- [ ] Replace visible `DPO` with `preference lessons`.
- [ ] Replace visible `training pairs` with `saved moments`.

Acceptance:

- [ ] A first-time user sees no XP, rank, anime/internal naming, DPO, LoRA, adapter, vLLM, or MCP outside Advanced.

### Slice 2: You Trust Surface

Goal: make Echo's read feel earned, inspectable, and correctable.

Files:

- `lib/page/echo_tabs/you_tab.dart`
- `lib/page/echo_tabs/what_echo_uses_screen.dart`
- `lib/echo/echo_api_client.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Add `Edit` beside `True / Partly / Not true`.
- [ ] `Edit` opens a short correction sheet with:
  - what Echo got wrong
  - corrected version
  - whether to save as memory/rule/evidence correction
- [ ] Convert evidence rows into compact evidence chips with expandable detail.
- [ ] Add `Next missing proof` card between `PROOF` and `PLACE`.
- [ ] Add `Why Echo thinks this` action that opens `What Echo Uses`.
- [ ] Save thesis corrections as a structured outcome/correction event.

Acceptance:

- [ ] The first 10 seconds of `You` answer: what Echo thinks, why, what is missing, and how to correct it.

### Slice 3: Real Loop Receipt

Goal: make every save visibly advance the loop.

Files:

- `lib/echo/echo_api_client.dart`
- `lib/echo/echo_loop_receipt.dart`
- `lib/page/echo_tabs/outcome_capture_sheet.dart`
- `lib/page/echo_tabs/proof_builder_screen.dart`
- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/layout/chat_page/chat_page.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Backend tasks:

- [ ] Change `/v1/outcome` response to include:
  - `loop_delta.thesis_updated`
  - `loop_delta.proof_created`
  - `loop_delta.opportunity_unlocked`
  - `loop_delta.training_signal_saved`
  - `loop_delta.next_action`
  - `loop_delta.receipt_title`
  - `loop_delta.receipt_detail`
- [ ] Add a conservative fallback `loop_delta` even when no major change happened.
- [ ] Keep old response fields for compatibility.

Flutter tasks:

- [ ] Add `recordOutcomeJson()` or change `recordOutcome()` safely to return response JSON.
- [ ] Drive `EchoLoopReceipt` from backend `loop_delta`.
- [ ] Wire receipt after Proof Builder save.
- [ ] Replace Today `_showProofCompletion` duplicate feedback with the shared receipt.
- [ ] Add offline receipt: `Queued on this device. Syncs when Home Brain reconnects.`

Acceptance:

- [ ] Every outcome/proof save tells the user exactly what changed and what to do next.

### Slice 4: Talk Context Row

Goal: make Talk visibly connected to Today, You, memory, and runtime.

Files:

- `lib/page/layout/chat_page/chat_page.dart`
- `lib/page/layout/chat_page/input_area.dart`
- `lib/page/echo_mobile.dart`
- `lib/echo/echo_loop_state.dart`
- `lib/echo/echo_runtime_service.dart`

Tasks:

- [ ] Add compact row above input:
  - `Today: <practice or priority>`
  - `Read: <confidence/stage>`
  - `<runtime mode>`
- [ ] Tapping row opens existing `_EchoContextSheet`.
- [ ] Make row collapse gracefully on small screens.
- [ ] Make reply strip use `EchoLoopReceipt` after action completion.
- [ ] Rename reply strip `Memory` to `Remember` for action clarity.

Acceptance:

- [ ] User no longer asks whether Talk knows what is in Today/You.

### Slice 5: Proof Builder Becomes Proof -> Place

Goal: Proof is not a drawer of items; it is how a user turns practice into real opportunity.

Files:

- `lib/page/echo_tabs/proof_builder_screen.dart`
- `lib/page/echo_tabs/opportunities_screen.dart`
- `lib/page/echo_tabs/feedback_quote_screen.dart`
- `lib/page/echo_tabs/public_artifact_screen.dart`
- `lib/echo/echo_product_contracts.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Rename UI `Opportunity` field to `Place`.
- [ ] Add `community` as first-class place type.
- [ ] Make Place selection visually required.
- [ ] Add proof types:
  - Outcome
  - Practice
  - Artifact
  - Human feedback
  - Decision
  - Story
- [ ] Add `Request feedback` flow inside Proof Builder.
- [ ] Generate share text for a teacher, mentor, friend, client, manager, or collaborator.
- [ ] Add `Create public-safe artifact` flow inside Proof Builder.
- [ ] After save, show matching Place plan and missing proof gap.
- [ ] Move readiness score into Place card detail.

Acceptance:

- [ ] User understands proof is for a place in the world, not just stored in the app.

### Slice 6: What Echo Uses Becomes Real Control

Goal: Echo earns trust by exposing its sources.

Files:

- `lib/page/echo_tabs/what_echo_uses_screen.dart`
- `lib/page/echo_tabs/memories_screen.dart`
- `lib/page/echo_tabs/operating_system_screen.dart`
- `lib/page/echo_tabs/permanent_record_screen.dart`
- `lib/page/echo_tabs/memory_consent_sheet.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Replace navigation rows with tabs:
  - Memories
  - Rules
  - Evidence
  - Corrections
- [ ] Show item source: Talk, Today, Proof, Check-in, imported memory, user correction.
- [ ] Show confidence where backend provides it.
- [ ] Show last used date where possible.
- [ ] Add delete/correct actions inline.
- [ ] Add correction history from thesis feedback.
- [ ] Add "used in current read" indicator.

Acceptance:

- [ ] User can inspect and change the material Echo uses to guide them.

### Slice 7: Where Echo Thinks Finish

Goal: make local-first runtime understandable without debugging.

Files:

- `lib/page/echo_tabs/local_model_setup_screen.dart`
- `lib/page/echo_tabs/home_brain_screen.dart`
- `lib/page/echo_tabs/pair_computer_screen.dart`
- `lib/page/echo_tabs/remote_access_screen.dart`
- `lib/echo/echo_runtime_service.dart`
- `lib/echo/local_model_download_service.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Fetch and display `/v1/runtime/capabilities` when connected.
- [ ] Keep local fallback capability matrix when offline.
- [ ] Add last memory sync time.
- [ ] Add queued upload count in the runtime cards.
- [ ] Add model download pause/resume if supported; keep stop/cancel.
- [ ] Make Home Brain QR/tunnel pairing the primary path.
- [ ] Move manual URL to Advanced.

Acceptance:

- [ ] User knows what works on Home Brain, Cloud, and This Device before they rely on it.

### Slice 8: Improve Echo Completion Story

Goal: training should feel like Echo learned from the user's life, not like ML infrastructure.

Files:

- `lib/page/echo_tabs/nightly_training_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `lib/echo/notification_service.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`
- `C:/Users/ASUS/Desktop/echo/echo_mcp.py`

Tasks:

- [ ] Public copy: `saved moments`, `preference lessons`, `personal style`, `Home Brain`.
- [ ] Move raw terms to Advanced details only.
- [ ] Show readiness checks:
  - enough saved moments
  - enough preference lessons
  - Home Brain available
  - latest update quality
- [ ] After update completes, show `What changed in Echo`:
  - style learned
  - strongest lesson
  - what Echo will do differently
  - next useful moment to save
- [ ] Align MCP `echo_training_center` with this wording.

Acceptance:

- [ ] User understands "Echo got better from me" without seeing model-training jargon.

### Slice 9: Proof Card

Goal: turn proof into a safe shareable artifact.

Files:

- `lib/page/echo_tabs/growth_card_screen.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Rename public `Growth Card` to `Proof Card`.
- [ ] Add `what this proves` line.
- [ ] Whitelist shareable proof only.
- [ ] Add redaction preview.
- [ ] Default private memories to excluded.
- [ ] Export/share as image where possible.
- [ ] Include one next ask: job, school, project, scholarship, feedback.

Acceptance:

- [ ] User can share progress without exposing private Echo context.

### Slice 10: Demo and Docs

Goal: make the hackathon presentation explain transformation, not features.

Files:

- `README.md`
- `C:/Users/ASUS/Desktop/echo/README.md`
- demo script/video notes

Tasks:

- [ ] Lead with: `Most people are not talentless. They are under-observed.`
- [ ] Show the loop:
  - Talk captures signal
  - Today gives practice
  - outcome becomes proof
  - feedback strengthens proof
  - Place plan emerges
  - Home Brain improves Echo
  - This Device keeps Echo offline
- [ ] Keep Gemma 4, Unsloth, LiteRT-LM, MCP as proof of technical depth, not the main story.
- [ ] Add one architecture diagram for local-first mobile + Home Brain + Cloud fallback.

Acceptance:

- [ ] A reviewer understands the human value before they understand the architecture.

---

## Recommended Build Order

1. Today first-impression cleanup.
2. You trust surface completion.
3. Backend `loop_delta` + real receipts.
4. Proof Builder save receipt.
5. Talk context row.
6. Proof Builder -> Place workflow.
7. What Echo Uses real tabs.
8. Runtime panel final polish.
9. Improve Echo completion story.
10. Proof Card.
11. Docs/demo narrative.

Do not add new standalone screens until these are done. Merge, rename, and connect what already exists.

---

## Current Audit

### Backend API Inventory

The Echo backend currently has the core product infrastructure. The issue is not missing endpoints; it is public UX consolidation.

Runtime and model:

- `GET /health`
- `GET /v1/models`
- `POST /v1/chat/completions`
- `POST /context`
- `POST /save`
- `GET /v1/system/health`
- `GET /v1/runtime/capabilities`
- `GET /v1/experimental/gemma4/health`
- `POST /v1/experimental/gemma4/chat`

Voice and proactive:

- `POST /v1/voice/token`
- `POST /v1/user/fcm-token`
- `GET /v1/events/taxonomy`
- `GET /v1/events/recent`
- `GET /v1/events/stream`
- `GET /v1/interventions/next`
- `POST /v1/interventions/ack`
- `GET /v1/interventions/settings`
- `POST /v1/interventions/settings`

Daily loop:

- `GET /v1/loop/snapshot`
- `GET /v1/today/priority`
- `GET /v1/today/mission`
- `GET /v1/reality/check`
- `GET /v1/practice/today`
- `POST /v1/practice/log`
- `GET /v1/daily/questions`
- `GET /v1/daily/checkin/status`
- `POST /v1/daily/checkin`
- `POST /v1/outcome`

Path/read:

- `GET /v1/thesis/current`
- `GET /v1/user/signal`
- `GET /v1/user/stats`
- `GET /v1/user/confidence`
- `GET /v1/user/insights`
- `POST /v1/user/talent`
- `GET /v1/user/notable-quote`
- `POST /v1/emergence`
- `GET /v1/revelation/status`
- `GET /v1/growth/timeline`
- `GET /v1/user/report`
- `POST /v1/mirror/weekly`

Proof and place:

- `GET /v1/proof/items`
- `POST /v1/proof/items`
- `DELETE /v1/proof/items/{item_id}`
- `POST /v1/proof/from-outcome`
- `POST /v1/proof/seed`
- `GET /v1/opportunities`
- `POST /v1/opportunities`
- `POST /v1/opportunities/generate`
- `GET /v1/passport/growth-card`

Decision workflows:

- `POST /v1/echo/decide`
- `POST /v1/council/ask`
- `POST /v1/twin/ask`
- `POST /v1/twin/choose`
- `POST /v1/tournament/run`
- `POST /v1/tournament/choose`
- `POST /v1/echo/simulate`
- `GET /v1/clone-mission/latest`
- `POST /v1/reply/action`

Memory and control:

- `GET /v1/user/memories`
- `POST /v1/user/memories`
- `DELETE /v1/user/memories`
- `DELETE /v1/user/memories/{memory_id}`
- `POST /v1/memory/propose`
- `GET /v1/user/rules`
- `POST /v1/user/rules`
- `DELETE /v1/user/rules/{rule_id}`
- `GET /v1/user/skills`
- `POST /v1/skills/extract`
- `GET /v1/threads`
- `POST /v1/threads/{thread_id}/resolve`
- `POST /v1/threads/deduplicate`

Training:

- `GET /v1/training/status`
- `GET /v1/training/summary`
- `GET /v1/training/runs`
- `GET /v1/training/eval`
- `GET /v1/training/history`
- `POST /trigger-training`
- `POST /swap-adapter`
- `GET /v1/teacher/policy`

Onboarding/offline/auth:

- `POST /v1/onboarding/first-read`
- `GET /v1/user/onboarding-state`
- `GET /v1/offline/export`
- `/auth/register`
- `/auth/login`
- `/auth/me`

### MCP Inventory

Public workflow tools are good:

- `echo_training_center`
- `echo_daily_brief`
- `echo_current_read`
- `echo_decision_room`
- `echo_memory_editor`
- `echo_signal_capture`
- `echo_threads_inbox`
- `echo_proof`
- `echo_opportunities`

Raw compatibility tools still exist and should not be the public story:

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
- `run_tournament`
- `ask_twin`
- `ask_council`
- lower-level save/log wrappers

MCP product rule: public MCP should speak product workflows, not endpoints.

### Flutter Screen Inventory

Primary shell:

- Mobile: `Talk`, `Today`, `You`.
- Desktop: `Talk`, `Today`, `You`, `Proof`, `Improve Echo`, `Home Brain`, `Advanced`.

Core files:

- `lib/page/echo_mobile.dart`
- `lib/page/layout/chat_page/chat_page.dart`
- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/echo_tabs/you_tab.dart`

Path/read screens:

- `talent_screen.dart`
- `discovery_ready_screen.dart`
- `discovery_insight_screen.dart`
- `revelation_screen.dart`
- `growth_timeline_screen.dart`
- `mirror_screen.dart`

Practice/decision screens:

- `ask_screen.dart`
- `council_screen.dart`
- `twin_screen.dart`
- `parallel_self_screen.dart`
- `shadow_tournament_screen.dart`
- `daily_checkin_screen.dart`
- `outcome_capture_sheet.dart`

Proof/place screens:

- `proof_builder_screen.dart`
- `opportunities_screen.dart`
- `public_artifact_screen.dart`
- `feedback_quote_screen.dart`
- `readiness_score_screen.dart`
- `growth_card_screen.dart`

Memory/control screens:

- `memories_screen.dart`
- `operating_system_screen.dart`
- `permanent_record_screen.dart`
- `memory_consent_sheet.dart`

Runtime/Home Brain:

- `home_brain_screen.dart`
- `local_model_setup_screen.dart`
- `pair_computer_screen.dart`
- `remote_access_screen.dart`
- `connected_apps_screen.dart`
- `voice_session_screen.dart`

Training:

- `echo_lab_screen.dart`
- `nightly_training_screen.dart`

The screen count is too high for a user-facing mental model. Keep the files if useful, but merge the public concepts.

---

## Product Diagnosis

### What is strong

- Backend product primitives exist: thesis, events, practice, outcomes, proof, opportunities, memory, runtime, training, offline export.
- Mobile already has the right 3-tab shell.
- Desktop already works as a Home Brain/control center.
- Proof and opportunity logic exists.
- On-device Gemma and Home Brain Gemma give Echo a real technical moat.
- MCP workflows already moved toward product-level tools.

### What is weak

- `You` still feels like a dashboard instead of a path/proof/place surface.
- The app still exposes old concepts: XP, rank, progress map, revelation, twin, clone/tournament internals.
- Outcome completion is not a strong universal receipt.
- Proof Builder, feedback quote, public artifact, readiness score, opportunities, and growth card are separate surfaces instead of one proof-to-place workflow.
- Memory, rules, and record are separate screens instead of one trust/control surface.
- The backend still has older endpoint names and docs that say clone/revelation/passport; this is fine internally but should not leak into user/product copy.
- The biggest missing product object is `Place`: where the user's proof could matter in the world.

### The exact gap Echo should own

```text
Most systems sort people after they already have credentials.
Echo helps people before they are fully proven: it finds signals, gives practice,
captures outcomes, builds proof, and points that proof toward real places it can matter.
```

---

## P0: Product Spine

### 1. Lock the product language

Files:

- `README.md`
- `CURRENT_PRODUCT_AUDIT.md`
- `RUTHLESS_CONSOLIDATION_2_WEEK_TODO.md`
- `lib/page/echo_tabs/*`
- `C:/Users/ASUS/Desktop/echo/README.md`
- `C:/Users/ASUS/Desktop/echo/main.py`
- `C:/Users/ASUS/Desktop/echo/echo_mcp.py`

Tasks:

- [ ] Replace public `Passport` with `Proof` or `Capability Record`.
- [ ] Replace public `Revelation` with `Discovery`.
- [ ] Replace public `Twin` with `Personal Lens`.
- [ ] Replace public `Tournament` with `Practice Versions` or `Scenario Test`.
- [ ] Replace public `clone` language with `practice version`, `candidate`, or `personal model`.
- [ ] Replace public XP/rank framing with proof/outcome/readiness framing.
- [ ] Keep technical names only in backend code, training internals, and Advanced.
- [ ] Update the core promise everywhere:

```text
Discover your path. Practice it. Prove it. Find where it matters.
```

Acceptance:

- [ ] A nontechnical user never sees DPO, LoRA, adapter, vLLM, MCP, endpoint, clone, battle, tournament, or ANBU outside Advanced.
- [ ] The product can be explained in one sentence without listing features.

### 2. Rebuild `You` as Path + Proof + Place

File:

- `lib/page/echo_tabs/you_tab.dart`

Current issue:

`You` currently starts with Proof Passport, rank bar, primary CTA, growth card, opportunity card, Direction, Proof, Progress, public artifact, feedback quote, lab, device. This is too much.

New order:

1. `Echo's Read` / `Path`
2. Evidence and correction
3. Today's next proof gap
4. Proof Builder
5. Place / Opportunity Plan
6. Improve Echo
7. What Echo Uses
8. Where Echo Thinks

Tasks:

- [x] Move `_buildThesisCard` to the top and make it the hero.
- [ ] Add `Edit` beside `True / Partly / Not true`.
- [ ] Show 2-3 evidence chips before any strong claim.
- [ ] Show confidence and "what would change this read".
- [x] Remove `_buildRankBar` from primary view.
- [x] Remove `_chapterLabel('PROGRESS')`.
- [x] Remove `_buildProgressMapEntry` from primary view.
- [x] Remove direct `_buildPublicArtifactEntry`; fold into Proof Builder.
- [x] Remove direct `_buildFeedbackQuoteEntry`; fold into Proof Builder.
- [x] Demote `_buildGrowthCardBanner` to Proof detail or remove from primary.
- [x] Rename `_buildOpportunityCard` to the user concept: `Place` or `Opportunity Plan`.
- [ ] Add one card: `Next missing proof`.
- [x] Add one card: `What Echo Uses`.

Acceptance:

- [ ] The first 10 seconds of `You` answer: what Echo thinks, why, how to correct it, what to do next.
- [ ] No XP/rank/progress-map card competes with proof and opportunity.

### 3. Universal loop receipt

Files:

- `lib/page/echo_tabs/outcome_capture_sheet.dart`
- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/layout/chat_page/chat_message_action.dart`
- `lib/echo/echo_api_client.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Current issue:

`OutcomeCaptureSheet` saves an outcome and optional proof, but callers get only `true/false`. Users get a snackbar instead of feeling the loop advance.

Tasks:

- [ ] Change `EchoApiClient.recordOutcome()` to return response JSON, not only bool.
- [ ] Add backend `loop_delta` to `/v1/outcome`:
  - `thesis_updated`
  - `proof_created`
  - `opportunity_unlocked`
  - `training_signal_saved`
  - `next_action`
- [x] Create shared Flutter component: `EchoLoopReceipt`.
- [x] Use receipt after Today practice outcome.
- [x] Use receipt after Talk `Practice`, `Outcome`, and `Proof` actions through `OutcomeCaptureSheet.show`.
- [ ] Use receipt after Proof Builder save.
- [ ] Offline variant: `Queued on this device. Syncs when Home Brain reconnects.`

Acceptance:

- [ ] Every saved outcome visibly says what changed.
- [ ] The user sees one next action, not a generic snackbar.

### 4. Merge proof, feedback, artifact, readiness, and opportunities

Files:

- `lib/page/echo_tabs/proof_builder_screen.dart`
- `lib/page/echo_tabs/opportunities_screen.dart`
- `lib/page/echo_tabs/feedback_quote_screen.dart`
- `lib/page/echo_tabs/public_artifact_screen.dart`
- `lib/page/echo_tabs/readiness_score_screen.dart`
- `lib/echo/echo_product_contracts.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Current issue:

These are conceptually one workflow but still separate screens.

New workflow:

```text
Add proof -> choose type -> choose place -> save -> show missing proof gap
```

Proof types:

- Outcome
- Practice
- Artifact
- Human feedback
- Decision
- Story

Places:

- Job
- School
- Scholarship
- Project
- Community
- Personal goal

Tasks:

- [ ] Make `place` mandatory when adding proof.
- [ ] Rename `opportunity_type` in UI to `place`.
- [ ] Add `Request feedback` inside Proof Builder.
- [ ] Add `Create public-safe artifact` inside Proof Builder.
- [ ] Move readiness score into Opportunity/Place card as expandable detail.
- [ ] After proof save, show matching Place plan.
- [ ] Keep `feedback_quote_screen.dart` and `public_artifact_screen.dart` as internal helper flows or delete once merged.
- [ ] Add opportunity seed category: `community`.
- [ ] Add a simple `Place Plan` object in frontend contracts.

Acceptance:

- [ ] User understands proof is for something.
- [ ] Human feedback is not hidden as a separate screen.
- [ ] The app can say: `Missing: one feedback quote` and help request it immediately.

### 5. Build `What Echo Uses`

Files:

- `lib/page/echo_tabs/memories_screen.dart`
- `lib/page/echo_tabs/operating_system_screen.dart`
- `lib/page/echo_tabs/permanent_record_screen.dart`
- `lib/page/echo_tabs/memory_consent_sheet.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `lib/page/echo_tabs/you_tab.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Current issue:

Memories, rules, record, and corrections are split. This weakens trust.

Tasks:

- [x] Create `what_echo_uses_screen.dart`.
- [ ] Tabs: `Memories`, `Rules`, `Evidence`, `Corrections`.
- [ ] Show source, confidence, and last used date where possible.
- [ ] Let user delete/correct each item.
- [ ] Add correction history from thesis feedback outcomes.
- [ ] Replace Echo Lab memory rows with one `What Echo Uses` row.
- [x] Add `What Echo Uses` entry to `You`.

Acceptance:

- [ ] User can see and control the material Echo uses to judge/guide them.
- [ ] Echo does not feel like surveillance.

---

## P1: Daily Product Loop

### 6. Make Today the Practice surface

File:

- `lib/page/echo_tabs/today_screen.dart`

Tasks:

- [ ] Remove XP pill from primary interaction.
- [ ] Replace `Good morning. Echo is listening.` with less surveillance-coded copy.
- [ ] Make cold start ask for one real recent moment, not generic setup.
- [ ] Show one practice, one outcome button, one proof consequence.
- [ ] After outcome save, show `Echo updated`, `Proof saved`, `Next missing proof`.
- [ ] If no backend, show offline queue state instead of repeated connection warnings.
- [ ] Keep check-in primary because it feeds the whole loop.

Acceptance:

- [ ] Today produces at least one signal per useful session.
- [ ] User knows why the practice matters.

### 7. Make Talk visibly connected

Files:

- `lib/page/echo_mobile.dart`
- `lib/page/layout/chat_page/chat_page.dart`
- `lib/page/layout/chat_page/chat_message_action.dart`
- `lib/page/layout/chat_page/input_area.dart`

Tasks:

- [ ] Add compact persistent context row above input:
  - `Today: <practice>`
  - `Read: <confidence>`
  - runtime label
- [ ] Tapping row opens existing Echo context sheet.
- [ ] Keep reply strip at five actions:
  - Practice
  - Remember
  - Decide
  - Outcome
  - Proof
- [ ] Add `Place`/`Use this` action only after proof exists.
- [ ] After any strip action, show `EchoLoopReceipt`.

Acceptance:

- [ ] User never wonders whether Talk knows Today/You.
- [ ] Chat is a signal source, not a separate product.

### 8. Consolidate Decision Room

Files:

- `lib/page/echo_tabs/ask_screen.dart`
- `lib/page/echo_tabs/council_screen.dart`
- `lib/page/echo_tabs/twin_screen.dart`
- `lib/page/echo_tabs/parallel_self_screen.dart`
- `lib/page/echo_tabs/shadow_tournament_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`
- `C:/Users/ASUS/Desktop/echo/thesis.py`

Public modes:

- Perspectives
- Personal Lens
- Scenario Test
- Practice Versions

Tasks:

- [ ] Rename visible `Twin` copy to `Personal Lens`.
- [ ] Rename visible `Tournament` copy to `Practice Versions` or `Scenario Test`.
- [ ] Remove "Send clones" labels from `thesis.py` action labels.
- [ ] Keep endpoint names for compatibility.
- [ ] Make Decision Room always end with one of:
  - save memory
  - log outcome
  - add proof
  - create practice

Acceptance:

- [ ] Decision Room feels like one product, not four experiments.

---

## P1: Runtime and Training

### 9. Where Echo Thinks

Files:

- `lib/page/echo_tabs/local_model_setup_screen.dart`
- `lib/page/echo_tabs/home_brain_screen.dart`
- `lib/page/echo_tabs/pair_computer_screen.dart`
- `lib/page/echo_tabs/remote_access_screen.dart`
- `lib/page/setting/network_sync_setting.dart`
- `lib/echo/echo_runtime_service.dart`

Tasks:

- [ ] One runtime panel with three cards: Home Brain, Echo Cloud, This Device.
- [ ] Show capability matrix from `/v1/runtime/capabilities`.
- [ ] Keep model downloads running when user leaves the screen.
- [ ] Add visible pause/stop/resume for model downloads.
- [ ] Show last memory sync time.
- [ ] Show queued upload count.
- [ ] Make QR/tunnel pair flow primary.
- [ ] Keep manual URL as Advanced.

Acceptance:

- [ ] User knows what works in each runtime.
- [ ] Reconnecting to Home Brain has a clear sync-back path.

### 10. Improve Echo without technical overload

Files:

- `lib/page/echo_tabs/nightly_training_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `lib/echo/echo_api_client.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`
- `C:/Users/ASUS/Desktop/echo/echo_mcp.py`

Tasks:

- [ ] Replace public `training pairs` with `saved moments`.
- [ ] Replace public `adapter` with `personal style`.
- [ ] Replace public `DPO` with `preference lessons`.
- [ ] Keep exact technical terms inside Advanced details only.
- [ ] Show four readiness checks:
  - enough moments
  - enough preference lessons
  - Home Brain available
  - latest update quality
- [ ] After update, show `What changed in Echo`.
- [ ] MCP `echo_training_center` should use same labels.

Acceptance:

- [ ] User understands training as "Echo learned from me", not as ML infrastructure.

---

## P2: Place Engine

### 11. Add real Place catalog seeds

Files:

- `lib/echo/echo_product_contracts.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Current seeds are useful but too generic. Add concrete initial catalogs:

- School: application story, class project, tutoring contribution.
- Scholarship: obstacle/proof/future plan narrative.
- Job: entry-level role proof, career switch proof, reliability proof.
- Project: community contribution, open-source task, creator collaboration.
- Personal: habit proof, communication proof, health routine proof.

Tasks:

- [ ] Add `community` place type.
- [ ] Add `mentor` or `teacher feedback` proof gap.
- [ ] Add `public-safe artifact` proof gap.
- [ ] Add `measured outcome` proof gap.
- [ ] Add `next ask` proof gap.
- [ ] Add scoring explanations: why this readiness changed.

Acceptance:

- [ ] Place plan feels like an actual next step, not a generated card.

### 12. Human feedback as viral loop

Files:

- `lib/page/echo_tabs/proof_builder_screen.dart`
- `lib/page/echo_tabs/feedback_quote_screen.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Create `Request feedback` flow inside Proof Builder.
- [ ] Generate copy template based on proof/place.
- [ ] Use native share sheet where available.
- [ ] Let user paste returned quote.
- [ ] Save quote as `feedback` proof.
- [ ] Mark private details before saving.
- [ ] Later: create tokenized public feedback endpoint.

Acceptance:

- [ ] A feedback request introduces Echo's value to another person.
- [ ] External validation improves the Place plan.

### 13. Shareable proof card with privacy filter

Files:

- `lib/page/echo_tabs/growth_card_screen.dart`
- `C:/Users/ASUS/Desktop/echo/main.py`

Tasks:

- [ ] Rename visible concept from Growth Card to Proof Card.
- [ ] Whitelist shareable proof only.
- [ ] Never include private memory by default.
- [ ] Add redaction preview.
- [ ] Add export/share image.
- [ ] Add "what this proves" line.

Acceptance:

- [ ] User can share proof without leaking private Echo context.

---

## P2: Product Quality

### 14. Clean old visual and copy debt

Files:

- `lib/page/echo_tabs/*`
- `lib/page/echo_mobile.dart`
- `lib/echo/echo_theme.dart`
- `lib/echo/echo_design_system.dart`

Tasks:

- [x] Remove black/orange dominance in shared Echo theme tokens.
- [x] Use blue as primary, green/proof as success, amber only for earned moments in the shared palette.
- [ ] Audit overflows in sign-up and training screens.
- [ ] Apply theme mode globally, not only settings.
- [ ] Remove weird top lines/artifacts in Talk.
- [ ] Remove nested cards where sections should be flat bands.
- [ ] Keep cards only for items/tools/modals.

Acceptance:

- [ ] Mobile and desktop look like one product.
- [ ] Theme switch persists and updates all screens.

### 15. Docs and presentation

Files:

- `README.md`
- `CURRENT_PRODUCT_AUDIT.md`
- `ECHO_TRUST_PROOF_PRODUCT_AUDIT.md`
- `C:/Users/ASUS/Desktop/echo/README.md`

Tasks:

- [ ] Rewrite docs around Path, Practice, Proof, Place, Home Brain.
- [ ] Keep Gemma 4, Unsloth, LiteRT-LM, MCP as technical proof, not the product pitch.
- [ ] Add one architecture diagram for the loop.
- [ ] Add one demo script:
  - cold start
  - Talk captures signal
  - Today gives practice
  - outcome becomes proof
  - feedback quote improves Place plan
  - Home Brain updates Echo
  - This Device works offline

Acceptance:

- [ ] Hackathon reviewer understands the user transformation before the architecture.

---

## Stop Building For Now

- More standalone screens.
- More public training dashboards.
- More raw MCP/endpoint UI.
- More XP/rank mechanics.
- More separate "profile" surfaces.
- More feature names inspired by internals.

---

## Build Order

1. `You` Path/Proof/Place rebuild.
2. Universal loop receipt.
3. Proof Builder merge: feedback, artifact, readiness, place.
4. What Echo Uses.
5. Today practice loop cleanup.
6. Talk context row and receipt.
7. Runtime panel unification.
8. Improve Echo copy and readiness story.
9. Place catalog and scoring explanations.
10. Shareable Proof Card.

This order is intentional: fix the product spine before polishing secondary screens.
