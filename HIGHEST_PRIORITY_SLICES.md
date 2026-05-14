# Echo Highest-Priority Product Slices

Echo already has the raw system pieces: mobile Talk, Today, Passport, Home Brain pairing, offline Gemma, memory sync, proof capture, opportunities, training, MCP workflows, and desktop runtime controls. The next work should make those pieces feel like one product.

## Product North Star

Echo is the mobile-first personal learning system that helps a person notice their signal, practice in the right direction, turn effort into proof, and unlock real opportunities. Home Brain is the private desktop runtime that powers stronger memory, Gemma 4, LoRA adapters, MCP tools, voice, and training.

## Status

| Slice | Status | Goal |
| --- | --- | --- |
| Home Brain language | Done | Replace desktop/local wording with a clearer private-runtime concept. |
| Runtime visibility | Done | Show This Device, Home Brain, or Echo Cloud from the main Talk header. |
| Proof and Opportunities | Now | Make proof creation and opportunity planning first-class, not buried inside Passport. |
| Talk context bridge | Next | Make Talk visibly aware of Today, Passport, memory, runtime, and pending practice. |
| Practice to proof loop | Next | Connect Today practice, outcome capture, proof creation, and opportunity progress. |
| Passport reframing | Next | Turn You/Passport into a living proof profile, not a generic personal dashboard. |
| Decision Room cleanup | Next | Rename internal experimental language into user-safe decision and perspective language. |
| Offline roundtrip | Next | Make offline memory pack, queued chats, and sync-back status obvious and reliable. |
| Training readiness | Next | Show when Echo can train, what signal is missing, and what changed after a run. |
| MCP workflows | Next | Present MCP as Echo workflows: brief, decision, memory, proof, opportunities, training. |
| Voice accessibility | Later | Use voice for check-ins, practice reps, decision capture, and low-literacy access. |
| Hackathon demo path | Later | Build a clean 3-minute story: onboard, practice, proof, opportunity, offline, Home Brain. |

## Slice 1: Proof And Opportunities

Why this matters: Echo should not only produce advice. It should help users create evidence they can use for jobs, school, scholarships, projects, or personal goals.

Current assets:

- `ProofBuilderScreen`
- `OpportunitiesScreen`
- `OutcomeCaptureSheet`
- `/v1/proof/items`
- `/v1/proof/from-outcome`
- `/v1/opportunities`
- `/v1/opportunities/generate`
- `echo_proof` and `echo_opportunities` MCP tools

Next implementation steps:

1. Add a first-class Proof entry in the desktop shell.
2. Add a mobile Passport hero that says what proof can unlock next.
3. Make Today's completed practice offer `Save as proof`.
4. Show missing proof directly inside each opportunity.
5. Let Talk answer "what should I work on today?" using opportunity gaps.

## Slice 2: Talk Context Bridge

Why this matters: Talk should feel connected to the rest of Echo. The user should not wonder whether chat knows Today, Passport, memories, runtime, or practice state.

Current assets:

- `/context`
- `EchoLoopState`
- runtime pill in Talk
- offline memory pack
- queued offline pairs
- Today and Passport APIs

Next implementation steps:

1. Add a compact "Echo is using" context sheet from Talk.
2. Show current read, priority, practice rep, and runtime in that sheet.
3. Add one-tap actions: work on priority, practice rep, think through decision, find avoided pattern.
4. Save useful Talk turns into memory, proof, rule, or training pair from message actions.
5. If offline, clearly show that answers use the synced memory pack and will sync back later.

## Slice 3: Practice To Proof Loop

Why this matters: Daily practice becomes valuable when it compounds into visible proof and opportunity progress.

Current assets:

- Today priority
- practice reps
- check-ins
- outcome capture
- proof creation
- opportunity generation

Next implementation steps:

1. Make Today's main CTA a loop: practice, capture outcome, save proof, update opportunity.
2. Add post-practice feedback states: did it work, what changed, what artifact exists.
3. Convert repeated practice wins into Passport milestones.
4. Use weak outcomes as training signal instead of treating them as failure.
5. Show one small next rep, not a large generic task.

## Slice 4: Home Brain And Offline Continuity

Why this matters: The product promise is mobile-first but privately powered. The user needs to trust what happens when Wi-Fi changes.

Current assets:

- Home Brain screen
- Pair Computer
- Remote Access
- local Wi-Fi and tunnel URL setup
- LiteRT-LM Gemma import
- offline memory export
- offline queue flush
- runtime selector

Next implementation steps:

1. Add a single Runtime panel entry everywhere: This Device, Home Brain, Echo Cloud.
2. Show what each runtime can do: memory, tools, LoRA, training, voice, offline.
3. Let users switch runtime from the panel with clear consequences.
4. Keep downloads alive when leaving setup screen and expose stop/resume.
5. On reconnect, show what was synced back into memory and training.

## Slice 5: Training And Personalization

Why this matters: Echo's strongest technical differentiator is a loop from user signal to better personal guidance.

Current assets:

- training summary
- untrained pairs
- DPO pairs
- LoRA adapter status
- eval results
- trigger training
- swap adapter
- Gemma 4 via Home Brain
- Unsloth pipeline

Next implementation steps:

1. Make Training Studio explain readiness with concrete missing signal.
2. Show latest run, eval, adapter status, and what changed in plain language.
3. Capture corrections from chat as preference pairs.
4. Keep LoRA training on Home Brain/cloud, not on mobile.
5. Sync mobile/offline signal into the desktop training queue.

## Slice 6: Demo And Competition Story

Why this matters: For Gemma 4 Good, the demo should prove social value, not only architecture.

Recommended category framing:

- Future of Education: daily practice, personal tutoring, offline learning continuity, talent discovery.
- Digital Equity: private mobile-first learning assistant that still works offline and can use a home computer instead of a paid cloud.

Demo path:

1. User opens mobile Echo and sees today's priority.
2. Echo explains the current read and a small practice rep.
3. User captures the outcome and turns it into proof.
4. Echo maps proof to an opportunity.
5. User disconnects Wi-Fi and continues with This Device Gemma.
6. User reconnects to Home Brain and the signal syncs into memory/training.
