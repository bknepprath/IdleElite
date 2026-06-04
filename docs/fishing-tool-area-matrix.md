# Idle Elite Fishing Tool and Area Matrix
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


Design direction (2026-05): fishing is about **choosing your tool** and **choosing your spot**, not following a fixed route of “this activity art only works on this map tile.”

**Hierarchy:** **region module** (Beach, Pier, …) → **locations** inside it (Shallows, Rocky ledge, …). Activity arts become **place thumbnails**, not tools.

---

## Player fantasy

You unlock **regions** (beach → pier → … → space), **locations** within a region (e.g. beach → *shallows* + *rocky ledge*), and **tools** (hands → net → …) on separate tracks. Pick a **location** in the region card, equip a **tool** on the rack, then fish. Any unlocked tool can run at any unlocked location; affinity is **tool × location**.

- **Good match:** high success, sensible yield, fast attempts, right fish table for the spot.
- **Bad match:** still legal — harpooning a minnow, bare-handing space fish, trawling a tide pool with a boat. **Silly, slow, low payout.** The game never says “you can’t”; it says “you really shouldn’t.”

Opens with **bare hands** at the beach for **one minnow** (tutorial clarity). You later unlock a **net** and *can* use it everywhere you’ve been. You later unlock a **harpoon** and *can* use it on minnows — it’s a very bad idea, and that’s the joke.

---

## Design pillars

| Pillar | Meaning |
|--------|---------|
| **Three unlock axes** | Region access, location spots within a region, **crafted tools** — not 23 unique activity rows. |
| **Craft → tool** | Most tools are built at a bench (smithing / woodworking / fishing craft TBD), then appear in the splay list. Starter **bare hands** only. **First net:** found on **Rocky ledge** first visit (discarded net collect), not crafted. |
| **Soft gates** | Affinity math (success, yield, duration, fish pool), not hard UI locks on tool×location. |
| **Expression over puzzle** | Experts optimize; curious players experiment; both are valid idle play. |
| **Archetype = tool feel** | Hands/net/harpoon still use `novice` / `volume` / `commit` bar stories from [fishing-archetype-design.md](fishing-archetype-design.md). Area only modulates the numbers and loot. |
| **Flavor on mismatch** | Result copy and maybe a tiny UI nudge (“overkill”, “empty net”, “…why?”) — not blocking modals. |

---

## Affinity tiers (authoring)

Each **tool × location** cell gets a coarse tier (`beach.shallows`, `beach.rocky`, …). Implementation maps tier → multipliers. Region-level defaults are optional fallbacks only.

| Tier | Player read | Typical effect |
|------|-------------|----------------|
| `ideal` | “This is the spot for that gear.” | Baseline or bonus success/yield/XP |
| `good` | “Works fine.” | ~90–100% of ideal |
| `awkward` | “Waste of gear.” | Lower yield, slower, maybe wrong fish mix |
| `joke` | “Meme run.” | Very low success or 1 tiny fish; keep it funny |
| `wrong` | “Technically possible.” | Worse than joke but still >0% if we want true freedom |

Most matrix cells are **`awkward`** or **`good`**; only a handful are **`ideal`** per tool. **`joke`** cells are intentional content (harpoon + minnow, hands + space leviathan).

---

## Example beats (not final numbers)

| Tool | Beach · shallows | Beach · rocky (crabs) | Reef · open |
|------|------------------|----------------------|-------------|
| **Bare hands** | Ideal — 1 minnow tutorial | Awkward — fumbling crabs | Dangerous |
| **Net** | Good minnow haul | Awkward — mesh on rocks | Good |
| **Line** | Good | **Ideal** for crabs | Good |
| **Harpoon** | Joke on minnows | Overkill on crabs | Ideal on big fish |
| **Boat / trawl** | Joke in ankle-deep shallows | Joke | Ideal offshore |

Same region, different spots: rocky ledge isn’t “a different beach module” — it’s a **second location tile** on the Beach card.

---

## UI sketch (target)

### **Fish + gear wallet** (not inside area cards)

Pinned with the skill header, **above** region modules:

| Piece | Role |
|-------|------|
| **Gear wallet button** | Shows **fish count** + currency icon + equipped tool thumb. **Tap to splay** unlocked tools **vertically** below (accordion, not a horizontal rack). |
| **Tool splay list** | One row per tool: art, name, archetype tag, equipped badge. **Locked rows** = not crafted yet (shows craft hint, not Fishing level). |
| **Region modules** | One scroll card per region (Beach, Pier, …): shared fluid strip + region frame. **No tools** inside the card. |
| **Location row** | **1–3 location tiles** per region module — scenic thumb + spot name + fish hint (e.g. “minnows”, “crabs”). Tap location to run attempts with **equipped tool**. |

Why separate rack vs locations:

- Tool = **global loadout** (“what I’m holding”).
- Location = **where in this region** (“shallows vs rocky ledge”) — replaces activity-art methods.
- Region = **biome frame** (water tint, unlock tier for the zone).

QoL:

- **One global equipped tool**; switch anytime.
- **Selected location** per region (remember last spot on Beach when you return).
- Affinity chip updates on **tool × active location** (harpoon + shallows = joke; line + rocky = ideal).
- **Mastery on tools** (rack slots), not on location tiles. Locations can show fish-type hint only.

Region module layout (after migration):

- Replace method-art row with **location spots** (thumbnails of shallows / rocks / dock edge).
- Background on the module can follow **selected location** (`--area-bg` swaps when you pick rocky vs shallows).
- Right column: XP/yield for **equipped tool × selected location** (live).
- Unlock: new **locations** = spot padlock on region card; new **tools** = craft recipe elsewhere, then row appears in wallet splay (uncrafted rows stay visible with **craft** badge).

Mock: `fishing-rework-brainstorm.html` — **Beach** shows the location-row target; other regions may still show legacy method tiles until migrated.

---

## Data model (migration target)

Today: each `actions[]` row = one named method **hard-bound** to `area` + `unlock`.

Target:

```json
"tools": [
  { "id": "hands", "name": "Bare hands", "unlock": "starter", "archetype": "novice", "art": "..." },
  { "id": "net", "name": "Drag net", "unlock": "craft:drag-net", "archetype": "volume", "art": "..." }
],
"craft_recipes": {
  "drag-net": { "bench": "woodworking", "inputs": ["twine", "light-frame"] }
},
"areas": [
  {
    "id": "beach",
    "name": "Beach",
    "fluid": "water",
    "background": "assets/content/fishing/backgrounds/00-tide-pool-shallows.png",
    "locations": [
      {
        "id": "shallows",
        "name": "Shallows",
        "unlock": 1,
        "background": "assets/content/fishing/backgrounds/00-tide-pool-shallows.png",
        "fish_table": "minnow"
      },
      {
        "id": "rocky",
        "name": "Rocky ledge",
        "unlock": 5,
        "background": "assets/content/fishing/backgrounds/03-crab-pier.png",
        "fish_table": "crab"
      }
    ]
  }
],
"affinity": {
  "hands": { "beach.shallows": "ideal", "beach.rocky": "awkward", "space.void": "joke" },
  "line": { "beach.shallows": "good", "beach.rocky": "ideal" },
  "harpoon": { "beach.shallows": "joke", "reef.open": "ideal" }
}
```

Resolve at attempt time:

- `seconds`, `success`, `fish_min/max`, `xp` from **tool base** × **location tier** × **location.fish_table**.
- Keep archetype on **tool**, not on location.
- Location id in data: `beach.shallows` or `beach:shallows` (pick one in implementation).

**Collapse candidates:** many current actions become one tool with tier upgrades (e.g. dangle + bamboo + fly → `line` ranks) instead of separate area-locked buttons.

---

## What stays from current rework

- Area modules, fluid strip, fish HUD, per-tool attempt bars, archetype curves.
- Individual method unlock ceremony → becomes **tool unlock** ceremony (same padlock UX).
- Space / boat / storm as areas; tools travel with you.

## What changes

- Replace per-action art rows with **`locations[]` nested under each region** in `fishing.areas[]`.
- Add **`_render_fishing_tool_rack()`** — persistent module; `equipped_tool_id` in save/state.
- Region module renders **location tiles** (1–3); attempts = **equipped tool × selected location**.
- Authoring: **~8–12 tools** + **~10 regions** + **~2–4 locations each** + sparse **tool×location** affinity (not 23 flat actions).

---

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Choice paralysis | Rack shows equipped tool clearly; optional “good here” hint on active area only |
| Balance spreadsheet | Sparse tiers first; only tune `ideal` + flagship `joke` cells for v1 |
| Loss of bespoke method names | Flavor text per tier band, not per JSON row |
| Scope creep | Phase 1: matrix for beach/pier + 3 tools; don’t rewrite all 23 rows day one |

---

## Module & location catalog

Full region → location → tool → migration tables: **[fishing-modules-and-locations-plan.md](fishing-modules-and-locations-plan.md)**.

---

## Suggested implementation phases

1. **Design lock** — tool list + affinity table on paper/HTML (this doc + brainstorm + modules plan).
2. **Beach/Pier implementation** — tool wallet + authored Beach and Pier location tiles; continue expanding current Godot locations from there.
3. **Data** — `fishing.tools[]`, `areas[].locations[]`, `fishing.affinity{}` in `activity-database.json`; compat shim from old action ids.
4. **Rollout** — migrate areas; deprecate duplicate line methods into tool ranks.
5. **Polish** — mismatch flavor lines, efficiency chip, album fish by area table not by action id.

---

## Relation to archetypes

**Archetype** = how the attempt *feels* (bar shape, phases). **Affinity** = how good an idea it is here (numbers). Orthogonal:

- Harpoon is always `commit` (strike fantasy).
- Harpoon at beach **shallows** is `joke`; at **rocky** still awkward/overkill.
- Line at beach **rocky** is `ideal` for crabs; hands at **shallows** is `ideal` for first minnow.

See [fishing-archetype-design.md](fishing-archetype-design.md) for bar/phase detail.
