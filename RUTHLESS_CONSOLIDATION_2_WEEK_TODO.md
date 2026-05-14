# Echo Ruthless Consolidation TODO

Purpose: make Echo feel like a private AI apprenticeship system, not another productivity app with many tabs.

North star:

```text
Most people are not talentless. They are under-observed.

Echo observes real conversations, decisions, struggles, feedback, and outcomes.
It turns that signal into one useful practice, captures what happened, converts
growth into proof, and improves the personal model that guides the user.
```

Core promise (use this exact wording on every screen, landing page, and demo):

```text
Echo is the only thing in your life that notices everything you do
and tells you what it means.
```

---

## Product Rules

Rules that every screen, CTA, and copy decision must pass before shipping.

- [ ] Every primary screen must support: Observe → Understand → Practice → Outcome → Improve Echo.
- [ ] Every screen must have one primary action.
- [ ] Evidence must appear before insight.
- [ ] Confidence must appear before any claim about the user.
- [ ] Outcome capture must be easier than opening another dashboard.
- [x] Technical controls must be hidden unless the user is in Advanced/Home Brain.
- [ ] No public UI should say clone, battle, tournament, DPO, LoRA, adapter, endpoint, MCP, vLLM, or pipeline unless the user opens Advanced.
- [ ] Echo should never feel like it is pretending to know the user before it has proof.
- [ ] The first 5 sessions must feel useful even when Echo has little data.
- [ ] If a feature does not feed practice, proof, memory, or model improvement, hide it for now.
- [ ] **No new screen ships unless it makes Today, Talk, or You feel more complete. Failing this test = move to Lab or delete.**
- [ ] **No gamification (XP, levels, ribbons) until the core emotional loop is working. Points compete with intrinsic growth.**
- [ ] **Copy says "building" or "learning" — not "watching". Watching implies surveillance. Building implies collaboration.**

---

## What Actually Exists (re-audited May 2026)

This section corrects the previous audit. Do not re-build things that already work.

| Feature | Status | Notes |
|---|---|---|
| Onboarding flow | ✅ Built | `lib/page/onboarding/onboarding_page.dart` — 5 steps: Promise → Areas → Brain Picker → First Question → First Read with EchoOrb. Wired in `echo_mobile.dart`. |
| EchoOrb widget | ✅ Built | `lib/echo/echo_orb.dart` — sonar-ring animated orb. Used in onboarding, DailyCheckin, TalentScreen, MirrorScreen. |
| Talk context sheet | ✅ Built | `_EchoContextSheet` in `echo_mobile.dart` — opens from runtime pill tap; shows thesis, priority, practice, runtime label, memory state, offline scope. Has action buttons: Today / Decision / Proof. |
| Runtime pill | ✅ Built | `EchoRuntimePill` in `echo_mobile.dart` — shows mode + detail (memory synced, queued count). |
| Outcome capture | ✅ Built | `OutcomeCaptureSheet` — Done/Skipped, Energy, Privacy, Confidence, note. Saves outcome + optional proof. Calls `EchoLoopState().refresh()` on save. |
| Proof Builder | ✅ Built | `ProofBuilderScreen` with `_ProofDraftSheet` bottom sheet. Has `ProofBuilderIntent` seed. |
| Daily check-in | ✅ Built | `DailyCheckinScreen` — conversational, 3 questions from API, typewriter answers, uses EchoOrb. |
| Comeback state | ✅ Built | `_TodayState.comeback` — fires at 5+ days away. No streak language. |
| Desktop navigation | ✅ Built | Talk / Today / You / Proof / Improve Echo / Home Brain / Advanced — exactly correct. |
| Decision Room entry | ✅ Built | `AskScreen` with thread support; `CouncilScreen`, `TwinScreen`, `ShadowTournamentScreen`, `ParallelSelfScreen` as modes. |
| MirrorScreen | ✅ Built | Weekly reflection with 5 staggered animations and EchoOrb. Reachable from Lab. |
| clone_battles display copy | ✅ Fine | `you_tab.dart:561` displays "decision runs"; `growth_timeline_screen.dart:57` displays "practice runs". The internal key name leaks to no user-facing text. |

---

## Feature Consolidation Map

Explicit decisions from the audit. Do not revisit without new evidence.

| Screen / Feature | Decision | Action |
|---|---|---|
| `progress_map_screen.dart` (XP / level) | Cut from primary nav | Remove from You tab PROGRESS chapter; archive file |
| `public_artifact_screen.dart` | Merge | Becomes a proof type option inside Proof Builder sheet |
| `feedback_quote_screen.dart` | Merge | Becomes a proof type option inside Proof Builder sheet |
| `readiness_score_screen.dart` | Merge | Becomes an expandable section inside the Opportunity card |
| `revelation_screen.dart` | Rename + keep | Change all user-facing `R E V E L A T I O N` labels to `D I S C O V E R Y`; keep the typewriter mechanic |
| `growth_timeline_screen.dart` | Keep, lower priority | Accessible from You tab's progress card; merge with TalentScreen idea long-term |
| `mirror_screen.dart` | Keep in Lab | Weekly reflection is valuable but not primary; reachable from Improve Echo |
| `memories_screen.dart` + `operating_system_screen.dart` + `permanent_record_screen.dart` | Merge | One "What Echo Uses" screen with tabs: Memories / Rules / Record |
| "PROGRESS" chapter in You tab | Remove | Chapter label and its three entries do not belong in primary scroll |
| Growth Card banner | Demote | Move from primary CTA to secondary link inside Proof section |
| `talent_screen.dart` | Keep, rename entry | "What Echo Sees" header is correct; discovery flow from You tab progress card should lead here after Discovery Insight |

---

## Immediate Fixes (specific code locations — do before any Day 2+ work)

Each fix is under 30 minutes. These are confirmed live copy regressions.

### Copy: "REVELATION" → "DISCOVERY"

- [x] `today_screen.dart:726` — Change `'R E V E L A T I O N'` → `'D I S C O V E R Y'`
- [ ] `today_screen.dart:738` — Change `'Echo has something to tell you.'` → `'Echo found a pattern. Tap to read.'`
- [x] `revelation_screen.dart:93` — Change `'R E V E L A T I O N'` → `'D I S C O V E R Y'`

### Copy: "watching" → "building" (specific locations)

These three are genuine surveillance-framing issues. The one in `talent_screen.dart` ("I've been watching how you think") is intentional earned-moment poetry — leave it alone.

- [x] `you_tab.dart:471` — Change default headline `'Echo is still watching for the deeper pattern.'` → `'Echo is still building a picture.'`
- [x] `operating_system_screen.dart:210` — Change `'Echo is still watching.'` → `'Echo is still building your rules.'`
- [x] `permanent_record_screen.dart:56` — Change return value `'watching and learning'` → `'building and learning'`
- [x] `onboarding_page.dart:428` — Change fallback `'Echo has enough of a first outcome to begin watching a real pattern.'` → `'Echo has enough to begin building a first picture.'`

### You tab: remove the PROGRESS chapter

- [ ] `you_tab.dart` — Remove `_chapterLabel('PROGRESS')` and the three entries that follow it: `_buildProgressMapEntry`, `_buildPublicArtifactEntry`, `_buildFeedbackQuoteEntry`. These features exist but primary navigation to them is not justified yet.
- [ ] `you_tab.dart` — Remove `_buildGrowthCardBanner` from primary CTA position. Demote to a secondary link inside the Proof section, or remove until proof export is tested.

---

## New Product Architecture

### Mobile

- [x] Keep only 3 bottom tabs: `Talk`, `Today`, `You`.
- [ ] Make `Today` the default open tab after onboarding. *(currently defaults to Today via `_selectedTab = 1` — verify)*
- [x] Keep Proof, Opportunities, Improve Echo, and Where Echo Thinks inside `You` or contextual sheets.
- [ ] Keep Decision Room as a contextual flow from Talk/Today, not a main tab.

### You Tab — Canonical Item Order

The full allowed scroll. Nothing else belongs in the primary view.

1. Runtime state pill (1 line: Home Brain / Cloud / Offline)
2. **Echo's Read** — thesis title + 2–3 evidence chips + confidence tag + `[True] [Partly] [Not true]` inline
3. Today's gap — one missing proof item with one action button
4. Proof section — proof count + "Add proof" button (opens proof-type sheet)
5. Opportunities — one gap card; readiness score lives inside as expandable detail
6. Improve Echo — training readiness row (visible when signal threshold is met)
7. What Echo Uses — memories, rules, permanent record (one combined entry)
8. Where Echo Thinks — device / home brain entry

Growth Card, Progress Map, XP, Public Artifact entry, Feedback Quote entry — none belong in the primary scroll.

### Desktop

- [x] Talk / Today / You / Proof / Improve Echo / Home Brain / Advanced — already correct.
- [x] Sync / Remote Access merged under Home Brain or Advanced.
- [ ] Desktop answers: "Is my private brain running, synced, and ready to improve Echo?"

---

## Rename Map

- [x] `Training Studio` → `Improve Echo`.
- [x] `Runtime` → `Where Echo Thinks`.
- [x] `Shadow Training` → `Practice Versions`.
- [x] `Tournament` → `Practice Versions` or `Best Answer`.
- [x] `Council` → `Perspectives`.
- [x] Desktop nav fully renamed.
- [ ] `Twin` → `Personal Lens` (twin_screen.dart header still says "Twin").
- [ ] `Revelation` → `Discovery` (two code locations confirmed above).
- [x] `MCP Tools` → `Connected Actions`.
- [x] `Sync` → `Home Brain Connection`.
- [ ] `Memories / Rules / Record` → `What Echo Uses` (merge into one screen).
- [ ] `Proof Passport` → keep, subtitle as `your evidence`.

---

## Week 1: Make The Product Legible

### Day 1 — Language And Navigation Cut ✅ (mostly done)

Goal: remove conceptual noise from public-facing text.

- [x] Search and replace: clone, battle, tournament, DPO, LoRA, adapter, MCP, vLLM, endpoint, pipeline in public copy.
- [x] Desktop nav renamed correctly.
- [x] `Training Studio` → `Improve Echo`, `Runtime` → `Where Echo Thinks`.
- [ ] Complete remaining Rename Map items: Twin → Personal Lens; Revelation → Discovery; Memories/Rules/Record → What Echo Uses.
- [ ] Apply all Immediate Fixes (copy regressions listed above).
- [ ] Update README to lead with core promise, not feature list.

Acceptance:

- [ ] No screen shows `R E V E L A T I O N`, `watching` (in status/passive copy), `clone`, `battle` to the user.
- [ ] A non-technical user can scan navigation and understand it.

---

### Day 2 — Today As The Daily Apprenticeship Loop

Goal: Today creates one signal every session and shows the user exactly what was saved.

Current state: Today has the orb, runtime pill, silence/check-in/interruption/revelation/comeback/council states. Practice card and "Log outcome" CTA exist. Cold-start card exists.

What's missing:

- [ ] **Outcome completion strip** — the single highest-priority missing piece. After `OutcomeCaptureSheet.show(...)` returns `true`, Today must display an inline 3-second strip:
  ```
  ✓ Saved to Proof   ✓ Echo updated   [Add evidence →]
  ```
  Offline variant: `Queued — syncs when Home Brain reconnects`
  This closes the loop visually. Without it, the user has no idea what happened.
- [ ] Cold-start card copy: change from limitation framing (`"Echo needs a few more outcomes..."`) to an invitation: `"Tell me about something you did recently that you're proud of, even a little."` The current cold-start question in onboarding is better — use the same tone here.
- [ ] "Log outcome" label on the practice card: verify it taps directly to `OutcomeCaptureSheet`, not a new screen. *(currently calls `_openPracticeOutcome` — confirm it shows the sheet)*
- [ ] After completion strip, offer exactly one next action only: `Add evidence` / `Open opportunity` / `Improve Echo`. Not all three — pick based on what was just saved.

Acceptance:

- [ ] A new user understands what to do in under 10 seconds.
- [ ] After completing a practice + outcome, the user sees exactly what was saved.
- [ ] Today creates at least one outcome / proof / training signal per session.

---

### Day 3 — Talk As The Observation Surface

Goal: Talk must feel connected to Today and You. The user should never wonder if Echo knows their context.

Current state: `_EchoContextSheet` exists and is well-built — shows thesis, priority, practice, runtime, memory state, offline scope, and 4 action buttons. It opens from the runtime pill tap. This is the context bridge; it works as a sheet. What's missing is making the connection more visible without requiring a tap.

- [ ] Add a **compact persistent context row** above the chat input area (1 line, always visible):
  - Shows: `Today: [practice title truncated] · Read: [confidence]`
  - Tapping it opens the existing `_EchoContextSheet`.
  - If offline: row shows `Offline — using synced memory`
  - This is additive — keep the sheet, add the row as a visual anchor.
- [ ] Simplify after-reply strip to exactly five named actions:
  - `Practice` · `Remember` · `Decide` · `Outcome` · `Proof`
  - Move `Correct`, `Plan`, and advanced actions to an overflow `···` menu.
- [ ] Make every strip action either save a signal or open a loop surface — no dead ends.

Acceptance:

- [ ] The user can see what Echo is using before trusting a reply.
- [ ] Every useful reply can become a practice, memory, outcome, decision, or proof.
- [ ] Talk does not feel like a standalone chatbot — it feels like part of Echo.

---

### Day 4 — You As The Mirror, Not A Dashboard

Goal: You becomes "what Echo believes, why, and how to correct it." One scroll tells the complete story.

Current state: You tab has Passport hero (thesis title + metrics), rank bar, primary CTA, growth card banner, opportunity card, DIRECTION/PROOF/PROGRESS chapters, Lab entry, Device entry. It is a dashboard. The thesis evidence and correction buttons are not inline.

- [ ] Apply Immediate Fixes: remove PROGRESS chapter, demote Growth Card banner.
- [ ] Implement canonical You tab item order (listed in New Product Architecture above).
- [ ] **Thesis evidence chips inline**: under the thesis statement in the Passport hero, show 2–3 evidence chips. Example: `"kept a commitment · 3×"` / `"asked for feedback"` / `"shipped under pressure"`. These should come from the thesis's evidence list in the API response. Tapping a chip opens the source proof item.
- [ ] **Correction buttons inline** (same card, directly under thesis statement):
  `[True]` · `[Partly]` · `[Not true]` · `[Edit]`
  Save the correction via `EchoApiClient().recordOutcome()` or a dedicated correction endpoint. This is the trust moment.
- [ ] Move Readiness Score out of its own screen — render as a collapsible `›` row inside the Opportunity card. The `ReadinessScoreScreen` file remains, but the entry from You tab changes.
- [ ] Improve Echo entry: visible only when `can_train_now == true` or `dpo_ready_pairs >= threshold`.
- [ ] What Echo Uses entry: one row that opens a unified screen (three tabs: Memories / Rules / Record). Until `WhatEchoUsesScreen` is built, point to `MemoriesScreen` as a placeholder.

Acceptance:

- [ ] You feels like a living mirror with receipts — not a dashboard.
- [ ] Thesis evidence is visible without any tap.
- [ ] The user can correct Echo without hunting.
- [ ] The scroll from top to bottom takes under 3 seconds and tells a complete story.

---

### Day 5 — Consolidate And Hide The Lab

Goal: fold scattered screens into their parent surfaces; advanced power stays accessible.

**Proof Builder consolidation:**

- [ ] Add a "proof type" bottom sheet to `ProofBuilderScreen` — shown when the user taps "Add proof" from You tab.
- [ ] Proof types: `Outcome` · `Artifact` · `Feedback` · `Decision` · `Small win`.
- [ ] Move forms from `public_artifact_screen.dart` and `feedback_quote_screen.dart` into this sheet as type-specific sections. The files stay as implementations; remove direct navigation entries from You tab (already done via Immediate Fixes).

**What Echo Uses consolidation:**

- [ ] Create `what_echo_uses_screen.dart` with tab bar: Memories / Rules / Record.
- [ ] Wire `memories_screen.dart`, `operating_system_screen.dart`, `permanent_record_screen.dart` as the tab bodies.
- [ ] Replace the three separate navigation entries in Lab/You with the single combined entry.

**Decision Room consolidation:**

- [ ] One Decision Room entry point: reachable from Talk's `Decide` after-reply action and Today's stuck button.
- [ ] Inside: three visible modes — `Perspectives`, `Personal Lens`, `Test Best Answer`.
- [ ] Internal screens (`CouncilScreen`, `TwinScreen`, `ShadowTournamentScreen`) remain as implementations. Users see mode names.

**Advanced area:**

- [ ] Move raw MCP server manager under Advanced.
- [ ] Move manual Remote Access under Advanced.
- [ ] Move low-level training run details (raw JSON) under Advanced.
- [ ] Keep `Improve Echo` as the user-facing training surface.

Acceptance:

- [ ] You tab scroll shows ≤ 8 items.
- [ ] Proof Builder offers all proof types from one entry point.
- [ ] Power users reach advanced controls in ≤ 2 taps from anywhere.

---

## Week 2: Make The Loop Valuable

### Day 6 — Onboarding: Improve What's There

Goal: first value before feature explanation. **The flow exists and is well-built — this day is polish, not rebuild.**

Current state: 5 steps — Promise (good copy) → Areas (Direction/Work/Learning/Relationships toggles) → Brain Picker (Cloud/Home Brain/Device) → First Question → First Read (EchoOrb + title + read text + next_move). Wired in `echo_mobile.dart` via `hasCompletedOnboarding()`. This is solid.

Improvements:

- [ ] **First Question** (step 3): current prompt is `"What's something you've been putting off thinking about?"` — this is good but slightly anxiety-adjacent. Consider A/B: `"Tell me about one thing you did recently that went better than you expected."` The positive framing gets a richer signal and sets a better tone for what Echo is for.
- [ ] **First Read** (step 4): the fallback read text currently says `'Echo has enough of a first outcome to begin watching a real pattern.'` — fix the "watching" copy (covered in Immediate Fixes above).
- [ ] **First Read** next_move card: verify the API returns a specific, actionable first practice, not a generic placeholder. The fallback (`'Keep talking until Echo can test this with real feedback.'`) is too vague — change fallback to `'Try one thing Echo mentioned today. Come back and tell it what happened.'`
- [ ] **Trust message** at step 0 (The Promise): current copy `"No personality test. No fake certainty."` is good. Add one line: `"Everything stays on your device unless you choose Home Brain or Cloud."` — this addresses privacy before the user has to ask.
- [ ] **Step count label**: Step 3 reads "Step 4 of 4" (line 344) but Step 2 reads "Step 2 of 4" — check if numbering skips anywhere in the UI.
- [ ] **Skip option** on Brain Picker: currently Home Brain and This Device both push a new screen immediately. Add a `"Skip for now — decide later"` option that goes to Cloud and continues. Don't force a setup decision in onboarding.

Acceptance:

- [ ] Onboarding produces: one saved signal, one first read, one first practice queued.
- [ ] User reaches the main app in under 2 minutes.
- [ ] Echo feels observant, not creepy, by the end of step 4.

---

### Day 7 — Practice To Proof Completion

Goal: one outcome visibly ripples into proof, memory, and training signal. The loop must be felt, not inferred.

Current state: `OutcomeCaptureSheet` saves outcome + optional proof, calls `EchoLoopState().refresh()`, then pops. Today does nothing visible after the pop. The loop works in the backend but is invisible to the user.

- [ ] **Outcome completion strip** (highest priority, repeated from Day 2):
  After `OutcomeCaptureSheet.show(...)` returns `true`, Today shows a non-blocking inline strip for 4 seconds:
  ```
  ✓ Saved to Proof   ✓ Echo updated   [Add evidence →]
  ```
  Offline: `Queued — syncs when Home Brain reconnects`
  Auto-dismisses. Tap to expand into full completion sheet.

- [ ] **Completion sheet** (expanded view when strip is tapped):
  - What was saved: outcome record / proof item / memory candidate / training signal.
  - One opportunity or proof gap this outcome affects.
  - Exactly one next action: `Add evidence` / `Open opportunity` / `Improve Echo`.

- [ ] **Proof Builder one-tap from Today**: after logging an outcome, "Save as proof" should be reachable without a separate screen navigation. Use the existing `ProofBuilderScreen(initialIntent: ..., autoOpenDraft: true)` pattern.

- [ ] In offline mode: show queue count with `Syncs when Home Brain reconnects`.

Acceptance:

- [ ] The user sees exactly what was saved — immediately after saving.
- [ ] Practice feels like it compounds into something real.
- [ ] Offline outcomes feel safely held, not lost.

---

### Day 8 — Improve Echo Without Technical Jargon

Goal: make model improvement emotionally understandable.

Current state: `NightlyTrainingScreen` (`Improve Echo`) exists. Header is already renamed. Has training summary, eval, health. Sections: training / memory / connections / signals.

- [ ] Replace readiness jargon in visible metrics:
  - `untrained_pairs` → `Moments saved`
  - `dpo_pairs` / correction count → `Corrections saved`
  - tournament/choice count → `Choices compared`
  - `can_train_now` → `Ready to update`
- [ ] Show what is *missing* before Echo can improve — specific: `"3 more choices needed before Echo can update."`
- [ ] Show `What changed` after training/eval — one plain-language paragraph. Not raw eval JSON.
- [ ] Hide LoRA/DPO/adapter details behind Advanced toggle inside the screen.
- [ ] This Device explanation: `"Your offline conversations are saved locally. They sync into Echo's learning when you reconnect."`

Acceptance:

- [ ] User understands how Echo improves without knowing what LoRA means.
- [ ] "What changed" is explained in language the user can feel.

---

### Day 9 — Where Echo Thinks

Goal: runtime becomes trust, not setup friction.

Current state: `LocalModelSetupScreen` handles This Device. `HomeBrainScreen` handles Home Brain. `PairComputerScreen` handles Wi-Fi pairing. `RemoteAccessScreen` handles tunnel. These are separate. `EchoRuntimePill` → `_EchoContextSheet` gives a good real-time summary already.

- [ ] Unify `LocalModelSetupScreen` + `HomeBrainScreen` entry into one **Where Echo Thinks** panel — the user should see all three runtimes in one place, with the active one highlighted.
- [ ] Show three capability cards: Home Brain / This Device / Cloud — each with a short capability list.
- [ ] Show last memory sync time.
- [ ] Show queued upload count (already shown in runtime pill; surface it more prominently here).
- [ ] Keep model download progress alive outside the screen.
- [ ] **Echo's Boundary Card**: one line per runtime: `"Home Brain — stays on your desktop."` / `"This Device — offline, synced memory only."` / `"Cloud — processed remotely."`

Acceptance:

- [ ] User can switch runtime without guessing what breaks.
- [ ] Offline mode feels intentional, not broken.
- [ ] Privacy state visible without opening Advanced.

---

### Day 10 — Demo Mode And Story

Goal: a 3-minute story that proves the human idea. Technology appears as proof of execution.

- [ ] Create a seeded demo account/state under Advanced → `Seed demo data`:
  - Current read with medium confidence and 3 evidence items.
  - Today's practice with a clear rep title.
  - One completed outcome with a proof item saved.
  - One opportunity gap with one missing evidence item.
  - Training: `can_train_now = true`, "3 choices compared".
  - Synced offline memory pack (5 memories, 2 rules).

- [ ] **Video script — human story first**:
  1. Open Today. See the orb. See the current read. See one practice rep.
  2. Do the practice. Log what happened. See the completion strip.
  3. Turn the outcome into proof. See it appear in You tab under Proof.
  4. Open You. See the thesis confidence. See the opportunity gap.
  5. Tap "Where Echo Thinks" — switch to This Device (offline Gemma).
  6. Talk offline. Answer uses local model + synced memory.
  7. Reconnect to Home Brain. See queued outcome sync back.
  8. Open Improve Echo. Signal is ready. Run update. See "What changed."

- [ ] Update README.md: lead with the core promise sentence, not a feature list.

Acceptance:

- [ ] Demo communicates human transformation in the first 30 seconds.
- [ ] Gemma 4, LiteRT-LM, Unsloth, MCP, Home Brain appear as *how it works*, not *what it is*.

---

## Better Product Ideas (strengthen the loop — not new feature sprawl)

### 1. Weak Read Protocol

- [ ] Every thesis/read has a visible confidence tier: `early signal` / `forming` / `confident`.
- [ ] Every read shows 2–3 evidence chips inline.
- [ ] Every read has correction inline: `True` / `Partly` / `Not true`.
- [ ] Reads below the confidence threshold must say `early signal`, not state a claim as fact.
- [ ] "Echo thinks" precedes every claim until confidence is high.

### 2. One-Minute Outcome

- [ ] Universal floating outcome button reachable from Talk, Today, You, voice, and notifications.
- [ ] Asks only: Did it happen? · What changed? · Any proof?
- [ ] Saves as: outcome record + proof candidate + training signal.
- [ ] Fewer taps than opening any new screen.

### 3. Proof From Ordinary Life

- [ ] Let users save small evidence, not only impressive artifacts.
- [ ] Proof type labels that feel human: kept a promise / asked for feedback / made a decision / finished a hard rep / helped someone / shipped something / admitted I was wrong.
- [ ] Echo should teach that proof is built from small repeated evidence, not resume bullets.

### 4. Discovery Moments With Restraint

- [ ] Discovery (formerly Revelation) only fires after an evidence threshold — not on a timer.
- [ ] It must show: why now / evidence count / confidence / next practice.
- [ ] It must never be a dramatic dead end — it leads somewhere actionable.
- [ ] **Unify the aesthetic**: Discovery screens use cosmic dark palette. The `EchoOrb` widget already exists and is used in onboarding and TalentScreen. Use it for Discovery too — don't invent a second visual language. Cosmic dark + `_DashedCirclePainter` should feel like the same system as the Today orb, not a different product.

### 5. Gentle Comeback

- [x] Comeback state is built (`_TodayState.comeback` at 5+ days away).
- [ ] Verify copy has no streak language: no "streak broken", no day-count guilt.
- [ ] Comeback card offers: `Resume` and `Recover proof from the gap` — confirm both work.
- [ ] If more than 14 days away: reset thesis confidence tier to `early signal` and explain why.

### 6. Private Share Card

- [ ] Growth Card export must whitelist only: title / category / date / outcome.
- [ ] Never export memories, rules, or raw training pairs by default.
- [ ] Card must be reviewable before export.

### 7. Echo's Boundary Card

- [ ] Visible from the runtime pill (one tap) on any main screen.
- [ ] Shows: active runtime / privacy state / what Echo can do right now / what it cannot.
- [ ] Builds trust and reduces failed expectations before they become frustration.

---

## What To Stop Building For Now

- [ ] No new top-level screens.
- [ ] No new decision workflow modes.
- [ ] No new MCP workflow tools.
- [ ] No new training variants in UI.
- [ ] No extra analytics dashboards or stats panels.
- [ ] No more proof/opportunity categories until the first loop is obvious and tested.
- [ ] No social/community features until private proof export is working.
- [ ] No autonomous training without explicit user confirmation and a clear "what changed" screen.
- [ ] **No gamification (XP, levels, point systems, ribbons) until the emotional core loop is working.**
- [ ] **No new "progress visualization" screens.** Progress Map, Growth Timeline, Talent Screen — one of these survives long-term. Do not add a fourth.

---

## Final Acceptance Gates

### Comprehension (30 seconds)

- [ ] A new user understands Echo in 30 seconds from the onboarding step 0 headline alone.
- [ ] The main app can be explained as: `Talk / Today / You`.
- [ ] No screen requires a tooltip to understand its purpose.

### First value (2 minutes)

- [x] Onboarding flow exists and ends with a first read + practice queued.
- [ ] Onboarding improvements (Day 6) applied: correct fallback copy, skip option on Brain Picker.

### Daily loop (every session)

- [ ] Today has one obvious action — the practice rep.
- [ ] After completing a practice + outcome, the user sees exactly what was saved (completion strip).
- [ ] Proof visibly compounds: practice → outcome → proof item → opportunity progress.

### Trust (any session)

- [ ] Talk visibly knows Today, current read, and active memory — before the user asks. *(context sheet exists; persistent row is still missing)*
- [ ] You shows read, confidence tier, 2–3 evidence chips, and correction buttons above everything else.
- [ ] Privacy state visible from the runtime pill on any main screen.

### Technical depth (power user)

- [ ] Improve Echo explains personalization in plain language — no jargon.
- [ ] Where Echo Thinks explains Home Brain / Cloud / This Device with capability matrix.
- [ ] Advanced tools available in ≤ 2 taps.

### Demo

- [ ] Hackathon video leads with human transformation in first 30 seconds.
- [ ] Gemma 4, LiteRT-LM, Unsloth, MCP, Home Brain appear as proof of execution — not the pitch.

---

## Color / UI Direction

V3 light palette aligned in `lib/echo/echo_theme.dart`. Dark mode direction: premium blue-ink, away from green-black.

| Token | Light | Dark |
|---|---|---|
| Canvas | #F4F7F6 | #0B1118 |
| Surface | #EAEFF0 | #111A24 |
| AI blue | #4A90D9 | #83BDF2 |
| Practice green | #3DAD78 | #68D99D |
| Proof blue | #5B7FC2 | #A8C3F2 |
| Memory violet | #7B6FD4 | #B8ABFF |
| Opportunity gold | #B8902A | #E3BD61 |

Discovery screens use their own cosmic dark palette intentionally. The `EchoOrb` widget (`lib/echo/echo_orb.dart`) exists and is already used in onboarding, DailyCheckin, TalentScreen, and MirrorScreen. The Discovery orb language (gold rings, breathing core) should feel continuous with Today's orb — reuse `EchoOrb` or at minimum share the `_DashedCirclePainter` visual language. Don't maintain two separate ring implementations for the same concept.
