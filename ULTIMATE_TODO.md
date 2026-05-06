# Echo Ultimate App TODO

Last updated from code search on 2026-05-06.

This is the single execution checklist for closing the final product gaps. The goal is not to add more disconnected screens. The goal is to make the app feel like one mobile-first Echo system:

```text
Talk -> Current Read -> Today Practice -> Outcome -> Proof -> Opportunity -> Improve Echo
              \-> Home Brain / This Device runtime continuity
```

## Already Built, Do Not Rebuild

- [x] Mobile shell with `Talk`, `Today`, `Passport`.
- [x] Desktop shell with Coach, Today, Passport, Proof, Improve Echo, Home Brain, Sync, Tools.
- [x] Echo backend API with chat, context, memory, Today, proof, opportunities, training, decision workflows, voice, offline export.
- [x] MCP workflow tools for training, daily brief, current read, decision room, memory, signal capture, threads, proof, opportunities.
- [x] Home Brain pairing and tunnel screens.
- [x] LiteRT-LM Android bridge and model catalog.
- [x] Offline memory pack and offline chat-pair queue.
- [x] Gemma 4 Home Brain lane through vLLM.
- [x] LoRA training, eval, adapter status, and hot-swap infrastructure.
- [x] LiveKit voice service and voice session UI.

## P0: Make The App Feel Connected

### 1. Talk Context Bridge

Problem: Talk can use Echo context, but the user cannot see what context Talk is using.

Files:

- `lib/page/echo_mobile.dart`
- `lib/page/layout/chat_page/chat_page.dart`
- `lib/echo/echo_loop_state.dart`
- `lib/echo/echo_offline_memory_service.dart`

Tasks:

- [x] Add an `Echo is using` sheet from the Talk header/runtime pill.
- [x] Show active runtime: `Home Brain`, `Echo Cloud`, or `This Device`.
- [x] Show current read/thesis.
- [x] Show Today's priority.
- [x] Show Today's practice rep.
- [x] Show memory status: full memory, synced pack, or thin cached context.
- [x] Show queued offline pairs count.
- [x] Add actions: `Work on priority`, `Practice rep`, `Think through decision`, `Build proof`.
- [x] In This Device mode, clearly say: no tools, no training, uses synced memory pack, syncs back later.

Acceptance:

- [ ] A user can open Talk and immediately understand whether it knows Today and Passport.
- [ ] Offline mode does not feel broken; it feels intentionally scoped.
- [ ] The same sheet becomes the main Runtime/context entry point.

### 2. Mobile Passport Proof Hero

Problem: Proof and opportunities exist, but mobile users can still miss the value.

Files:

- `lib/page/echo_tabs/you_tab.dart`
- `lib/page/echo_tabs/proof_builder_screen.dart`
- `lib/page/echo_tabs/opportunities_screen.dart`

Tasks:

- [x] Move Proof/Opportunity cards higher in Passport.
- [x] Add a short hero: `What your proof can unlock next`.
- [x] Show proof count and top missing proof gap.
- [x] Add primary CTA: `Build proof`.
- [x] Add secondary CTA: `Find opportunities`.
- [ ] Remove or down-rank lower-value stats if the screen feels crowded.

Acceptance:

- [ ] Passport reads as a living proof profile, not a generic profile dashboard.
- [ ] A new user understands why capturing practice outcomes matters.

### 3. Practice To Proof Completion Flow

Problem: Today can save proof, but the user does not see the full loop after completion.

Files:

- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/echo_tabs/outcome_capture_sheet.dart`
- `lib/page/echo_tabs/opportunities_screen.dart`
- `lib/echo/echo_api_client.dart`

Tasks:

- [x] After a practice outcome is saved, show a completion state.
- [x] Confirm whether proof was created.
- [ ] Show one opportunity gap this proof helps with.
- [x] Offer `Add more evidence` and `See opportunity plan`.
- [ ] If backend is unavailable, queue or explain what was saved locally.

Acceptance:

- [ ] Completing practice visibly updates Passport/Proof.
- [ ] The user sees the next practical reason to keep practicing.

## P0: Remove Confusing Product Language

### 4. Runtime Naming Cleanup

Problem: Most runtime naming is fixed, but `Offline & Privacy` still appears in user-facing copy.

Files found by search:

- `lib/page/echo_tabs/local_model_setup_screen.dart`
- `lib/echo/local_gemma_service.dart`
- `lib/page/echo_tabs/you_tab.dart`

Tasks:

- [x] Replace `Offline & Privacy` with `Runtime` or `Home Brain & Offline`.
- [x] Update local Gemma error text to point to `Runtime`.
- [x] Keep the public runtime labels only: `Home Brain`, `Echo Cloud`, `This Device`.

Acceptance:

- [ ] Search has no user-facing `Offline & Privacy`, `Local Brain`, `Desktop Echo`, or `My Computer`.

### 5. Decision Room Consolidation

Problem: Ask, Council, Twin, Tournament, and Parallel Self are one product area but still feel split.

Files:

- `lib/page/echo_tabs/ask_screen.dart`
- `lib/page/echo_tabs/council_screen.dart`
- `lib/page/echo_tabs/twin_screen.dart`
- `lib/page/echo_tabs/parallel_self_screen.dart`
- `lib/page/echo_tabs/shadow_tournament_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `lib/page/echo_tabs/today_screen.dart`
- `lib/page/layout/chat_page/chat_message_action.dart`

Tasks:

- [x] Make `AskScreen` the canonical public `Decision Room`.
- [x] Public modes: `Perspectives`, `Personal Lens`, `Scenario Test`.
- [x] Hide public `Shadow`, `Clone`, `Battle`, and `Tournament` language from the main visible entry points.
- [ ] Keep backend endpoint names for compatibility, but sanitize UI copy.
- [x] Route chat message action into Decision Room, not directly into `ShadowTournamentScreen`.
- [ ] Rename visible Echo Lab cards to user-safe language.

Acceptance:

- [ ] A user sees one Decision Room, not several competing decision products.
- [ ] Search still may find internal class/endpoint names, but visible strings are clean.

## P1: Training And Home Brain Trust

### 6. Training Readiness Story

Problem: Training is technically strong but still reads like engineering status.

Files:

- `lib/page/echo_tabs/nightly_training_screen.dart`
- `lib/page/echo_tabs/echo_lab_screen.dart`
- `lib/echo/echo_api_client.dart`

Tasks:

- [ ] Show readiness as: enough moments, enough preferences, adapter status, latest eval.
- [ ] Explain what signal is missing.
- [ ] After training, show `What changed in Echo`.
- [x] Separate Home Brain training from This Device offline capability.
- [x] Show offline queued pairs as future training signal.

Acceptance:

- [ ] User understands why training is not always available.
- [ ] User understands that on-device Gemma does not train LoRA locally yet.

### 7. Runtime Panel Unification

Problem: Runtime controls are spread across Talk pill, Passport device card, Local Model setup, Home Brain, Pair Computer, Remote Access, Sync.

Files:

- `lib/page/echo_tabs/local_model_setup_screen.dart`
- `lib/page/echo_tabs/home_brain_screen.dart`
- `lib/page/echo_tabs/pair_computer_screen.dart`
- `lib/page/echo_tabs/remote_access_screen.dart`
- `lib/page/setting/network_sync_setting.dart`
- `lib/page/echo_mobile.dart`

Tasks:

- [x] Rename `LocalModelSetupScreen` conceptually to Runtime panel in visible UI.
- [ ] Show three runtime cards with clear capability matrix.
- [ ] Keep model download running when leaving the screen.
- [ ] Keep stop/resume controls visible.
- [ ] Show last memory sync time.
- [ ] Show queued upload count.
- [ ] Make Home Brain pairing the preferred flow; keep manual remote URL as advanced.

Acceptance:

- [ ] User can switch modes without guessing what breaks.
- [ ] Reconnecting to Wi-Fi/Home Brain has a clear sync-back path.

### 8. Home Brain Service Reliability Surface

Problem: Users need a simple way to start API, Gemma, LiveKit, voice agent, and tunnel.

Backend files:

- `C:/Users/ASUS/Desktop/echo/start_echo_services.ps1`
- `C:/Users/ASUS/Desktop/echo/start_echo_services.bat`
- `C:/Users/ASUS/Desktop/echo/start_all.ps1`
- `C:/Users/ASUS/Desktop/echo/README.md`

Tasks:

- [ ] Document one command for normal use.
- [ ] Document flags: skip Gemma, skip LiveKit, with voice, timeout.
- [ ] Surface service health in Home Brain screen: API, Gemma 4 vLLM, adapter, LiveKit, voice agent, tunnel.
- [ ] Add clear recovery text when mobile cannot reach `10.0.2.2:8002` or tunnel URL.

Acceptance:

- [ ] After laptop restart, one command and one Home Brain screen tell the user what is running.

## P1: MCP As Product, Not Tool Soup

### 9. MCP Workflow Presentation

Problem: Raw MCP server setup exists, but the product story is the Echo workflow tools.

Files:

- `lib/page/setting/mcp_server.dart`
- `C:/Users/ASUS/Desktop/echo/echo_mcp.py`
- `C:/Users/ASUS/Desktop/echo/README.md`

Tasks:

- [x] Make workflow cards the top MCP UI.
- [x] Public MCP tools: daily brief, current read, decision room, memory editor, signal capture, proof, opportunities, training center.
- [ ] Move raw low-level tools into Advanced/Debug.
- [ ] Rename low-level public descriptions that say clone/shadow/battle.
- [ ] Add an example agent flow: `daily brief -> practice -> proof -> opportunity`.

Acceptance:

- [ ] MCP feels like Echo operating across the user's work environment, not just 30 endpoint wrappers.

## P1: Docs And Demo

### 10. Remove Stale Docs And Dead Screens

Problem: Some docs and files describe old screens that no longer exist.

Files:

- `C:/Users/ASUS/Desktop/echo/FEATURES.md`
- `lib/page/echo_tabs/experiment_screen.dart`

Tasks:

- [x] Replace stale `FEATURES.md` with current product feature map or archive it.
- [x] Delete `experiment_screen.dart` if we are not going to route it.
- [ ] If experiment is still valuable, fold it into Today as a practice/outcome variant.
- [ ] Keep `CURRENT_PRODUCT_AUDIT.md` and this TODO as the source of truth.

Acceptance:

- [ ] No doc claims removed screens exist.
- [ ] No dead Flutter screen remains unless intentionally archived.

### 11. Hackathon Demo Flow

Problem: The app has enough features, but the demo needs a clear story.

Tasks:

- [ ] Demo account with meaningful memory, current read, practice, proof, opportunity.
- [ ] Script: mobile Today -> Talk context -> practice -> proof -> opportunity -> offline -> reconnect -> training.
- [ ] Show Gemma 4 Home Brain lane.
- [ ] Show LiteRT-LM This Device mode.
- [ ] Show Unsloth/LoRA readiness or completed run.
- [ ] Show MCP workflow call from an external agent.
- [ ] Update screenshots/video path in README.

Acceptance:

- [ ] 3-minute demo proves Digital Equity and Future of Education.
- [ ] Technical differentiators are visible: Gemma 4, LiteRT, Unsloth, MCP, Home Brain.

## P2: Polish And Quality

### 12. UI Consistency Pass

Tasks:

- [ ] Make Ask/Decision Room typography match Plus Jakarta Sans.
- [ ] Remove duplicate back buttons in pushed screens.
- [ ] Make screen titles consistent: Coach, Today, Passport, Proof, Improve Echo, Home Brain, Runtime, Tools.
- [ ] Check mobile text overflow on Pixel emulator.
- [ ] Check desktop wide layout for nested-card clutter.

Acceptance:

- [ ] No obvious repeated screen or duplicate navigation path.
- [ ] Screens feel like one product family.

### 13. Analyzer And Build Cleanup

Current analyzer state: `flutter analyze` reports existing warnings/info but no new compile error from the latest slices.

Tasks:

- [ ] Fix unused imports in touched Echo screens.
- [ ] Fix high-signal analyzer warnings in Echo-specific files first.
- [ ] Keep generic Chat UI warnings for later unless they block release.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter build apk --debug`.

Acceptance:

- [ ] Echo-specific files are clean enough that new regressions are easy to spot.

## Recommended Build Order

1. Runtime naming cleanup.
2. Talk Context Bridge.
3. Mobile Passport Proof Hero.
4. Practice To Proof Completion Flow.
5. Decision Room Consolidation.
6. Training Readiness Story.
7. Runtime Panel Unification.
8. MCP Workflow Presentation.
9. Stale docs/dead screen cleanup.
10. Hackathon demo flow.
11. UI consistency pass.
12. Analyzer/build cleanup.

## Final App Acceptance Checklist

- [ ] User can onboard by choosing Echo Cloud, Home Brain, or This Device.
- [ ] User can open Talk and see what Echo currently knows and which runtime is active.
- [ ] User can complete Today's practice and turn it into proof.
- [ ] User can see what opportunity the proof unlocks or what proof is missing.
- [ ] User can ask a decision question through one clear Decision Room.
- [ ] User can go offline with Gemma and synced memory.
- [ ] User can reconnect and upload offline signal back into training.
- [ ] User can start/check Home Brain services without guessing.
- [ ] User can see whether training is ready and what changed after training.
- [ ] MCP presents Echo product workflows first.
- [ ] Public UI avoids clone/shadow/battle/tournament/anime language.
- [ ] README and demo explain mobile-first Home Brain, Gemma 4, LiteRT-LM, Unsloth, and MCP clearly.
