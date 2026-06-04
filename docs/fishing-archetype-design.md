# Idle Elite Fishing Method Archetypes
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


> **Direction:** **Tool rack** (global gear) + **region modules** with **1–3 location spots** each (e.g. Beach: shallows + rocks). Tool × location **affinity**, not fixed activity arts. See [fishing-tool-area-matrix.md](fishing-tool-area-matrix.md). Archetypes = tool feel; affinity = good idea at this spot.

## Progress UI rule

| Layer | Role |
|-------|------|
| **Area fluid strip** (bottom of module) | Ambiance only — water/sewer tint, gentle motion while *any* method in that area runs. No attempt %, no timing readout. |
| **Per-method attempt bar** (under each art tile) | The only place players read **this method’s** attempt story. Small pill bar, width = art panel. |
| **Mastery bar** (below attempt bar) | Long-term mastery — unchanged. |

No full-width module progress rail for fishing rework.

### One engine, many stories (not one “fishing cycle”)

Every method still resolves the same way under the hood: **timer runs → success roll → fish pops (or miss)**. That is shared idle infrastructure.

What we **do not** ship as a global fantasy is *calm → bite → harvest* on every tool. That story fits **line / wait / hook** methods (`steady`, `novice`, parts of `commit`). It does **not** fit nets.

| Player story | Archetypes | Bar read |
|--------------|------------|----------|
| **Line** — wait, twitch, land | `novice`, `steady`, much of `commit` | pale fill → gold twitch → green/red flash |
| **Net** — drag, snag, dump | `volume` | **stepped ticks**, short early segment, “empty net” on fail |
| **Strike** — hold, lunge, whiff | `commit` | late surge, still uses line-like segments internally |
| **Grab** — fumble, maybe catch | `chaos` | jitter, messy middle band |
| **Gamble** — bait, danger, all or nothing | `risk` | smooth + caution middle band |

Implementation still uses three bar tint bands (`calm_end` / `bite_end` / reveal) in `FishingAttemptBar` — **internal names only**. Copy, art motion, and tick shape sell the fantasy. Nets should never be tuned or documented as “waiting for a bite.”

---

## Core archetypes (5)

These are the primary “engines” every method maps to.

### 1. `volume` — Net haul (the net type)

**Feel:** Busy, generous, slightly messy. You are **dragging mesh through water**, not watching a bobber.

| Axis | Spec |
|------|------|
| Player phases | **Drag → snag → spill** (not calm / bite / harvest) |
| Timing | Short drag (~42% of attempt), quick snag band, short spill |
| Bar | **Stepped** — 4–5 discrete ticks; each tick reads as a pull stroke |
| Art motion | Side-to-side sweep or net shake; **no** bobber dip on “snag” |
| Success | ~78% (many tries feel productive) |
| Catch | Extra pop chance (+1 fish); faster stagger between pops |
| Fail | Soft miss — **empty net**, not “fish got away” |

**Methods:** drag-net-through-creek, trawl-from-tiny-boat, net-the-reflection-of-a-fish

No separate seventh archetype for nets — `volume` *is* the net progression model. If a future tool feels wrong on `volume` (e.g. passive trawl that never “snags”), add a **passive module** instead of another attempt bar archetype.

---

### 2. `steady` — Reliable line

**Feel:** Honest idle rhythm. **Wait → bite → land** — the classic line fantasy.

| Axis | Spec |
|------|------|
| Player phases | Wait → bite → land |
| Timing | Baseline bands (55% wait / 88% bite end) |
| Bar | **Smooth** linear fill; wait = pale blue, bite = gold, land = green/red flash |
| Art motion | Gentle sine bob + slight scale pulse |
| Success | ~82% |
| Catch | Normal pop count from yield range |
| Fail | Standard miss text |

**Methods:** scoop, dangle, bamboo rod, fly fish, crab pot, ice hole, rowboat, lobster cage, night fish, pearl dive, sonar *(if not scan)*, magnetic hook, mailbox trap, and other “normal” tools

---

### 3. `commit` — All-in strike

**Feel:** Long setup, one decisive moment. Tension → snap.

| Axis | Spec |
|------|------|
| Timing | Long calm (~72%), **short** sharp bite window |
| Bar | **Late surge** — bar crawls to ~70%, then rushes to 100% during bite |
| Art motion | Still during calm; sharp lunge + tilt on bite |
| Success | ~70% |
| Catch | Fewer pops, bigger spacing, higher max bias |
| Fail | Harder “whiff” — bar snaps empty on reveal fail |

**Methods:** harpoon-suspicious-ripple, spear-fish-in-shallows, bait-a-tiny-leviathan, cast-storm-kite-line, dive-for-pearl-oysters

---

### 4. `chaos` — Sewer grab

**Feel:** Unreliable, janky, funny-dangerous. You might get nothing or a surprise.

| Axis | Spec |
|------|------|
| Timing | Medium calm, jittery bite band |
| Bar | **Jitter** — fill wobbles ±8% visually; bite phase flickers |
| Art motion | Erratic sway, occasional micro-twitch |
| Success | ~62% |
| Catch | Low min yield; high variance; rare spike pops |
| Fail | Common; reveal fail feels “slipped away” |

**Methods:** hand-grab-muddy-catfish, catch-the-fishing-mechanic-itself

---

### 5. `risk` — Chum the waters

**Feel:** High upside, zero on fail. The bar *warns* you during bite.

| Axis | Spec |
|------|------|
| Timing | Medium calm; bite band tinted caution |
| Bar | Smooth fill + **amber bite stripe** overlay; on fail, bar drains before reveal |
| Art motion | Slow sway; bite = stronger pulse |
| Success | ~68% |
| Catch | High max yield; fail = **0 fish** (not low roll) |
| Fail | Deliberate empty reveal — no pity fish |

**Methods:** chum-open-water

---

## Removed / deferred

- **Sonar** — cut (no electronics in fantasy tone).
- **Bargain** archetype + negotiate method — cut for now.
- **Catch the fishing mechanic** — finale method cut; space area capped at 2 live methods (max 3 slots).

---

## Fishing Lv 1 opener (Beach)

| | |
|--|--|
| **Place** | **Beach · Shallows** (Lv **1**). |
| **Method** | **Bare hands** — cup the ankle-deep water; one minnow = **1 fish** in the pile. **Rocks** unlocks Beach Lv **5**. **Pier** module Lv **7**. |
| **Archetype** | `novice` — smooth bar, long calm, ~3.2s attempts, 92% success, yield **1–1**. |
| **UI** | Short label **Dip**; minnow catch icon. |

Drag net moves to **Fishing Lv 4** so the first hour is not a volume net.

## Space Fishing area (2 locations · module Lv 90)

| Slot | Location / tool | Feel |
|------|-----------------|------|
| 1 | **Starlight pool** @ Lv 90 | `starlight-dip` steady |
| 2 | **Mirror surface** @ Lv 95 | `reflection-net` volume |

---

## Full method → archetype map (23)

| Method | Archetype |
|--------|-----------|
| dip-a-tidepool-minnow | novice |
| drag-net-through-creek | volume |
| scoop-pond-minnows | steady |
| dangle-string-from-dock | steady |
| cast-bamboo-rod | steady |
| hand-grab-muddy-catfish | chaos |
| set-tiny-crab-pot | steady |
| ice-fish-through-nervous-hole | steady |
| spear-fish-in-shallows | commit |
| fly-fish-at-river-bend | steady |
| cast-from-rowboat | steady |
| drop-lobster-cage | steady |
| trawl-from-tiny-boat | volume |
| night-fish-with-lantern | steady |
| harpoon-suspicious-ripple | commit |
| chum-open-water | risk |
| cast-storm-kite-line | commit |
| dive-for-pearl-oysters | commit |
| fish-with-magnetic-hook | steady |
| bait-a-tiny-leviathan | commit |
| open-deep-sea-mailbox-trap | steady |
| skim-a-starlight-minnow | steady |
| net-the-reflection-of-a-fish | volume |

---

## Bar tint bands (implementation)

Same four fills for every archetype; **meaning depends on archetype** (see table above).

| Band (code) | Fill | Line methods | Net (`volume`) |
|-------------|------|--------------|----------------|
| early | `#9ad4e8` | Waiting | Dragging |
| middle | `#fff2a8` | Bite / twitch | Snag in mesh |
| end OK | `#8ee4a8` | Landed | Spill out catch |
| end miss | `#e8b0b0` | Got away | Empty net |

---

## Implementation phases

1. **Done / starting:** Per-method `FishingAttemptBar` under art; archetype display curves; expanded `_fishing_method_archetype()`.
2. **Next:** Per-archetype `calm_end` / `bite_end` on fluid strip *optional* ambient boost only.
3. **Next:** Archetype sway profiles on active art.
4. **Next:** `archetype` field in `activity-database.json` (optional; code map remains fallback).
5. **Later:** Shiny fish bias per archetype; JSON yield min/max.

---

## Open questions

- Third space slot (max 3): e.g. moon-thread rod or whisper-lure when ready.
- Lobster cage stays **passive module** (no attempt bar).
- Optional: per-archetype phase labels in UI; hide "bite" on `volume` modules in the Godot game.
