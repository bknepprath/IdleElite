# Fishing Rework - Status & Next Steps

Last updated: 2026-05-31 (in progress on branch / working tree)

**Implementation & asset checklist (HTML):** [fishing-rework-implementation-guide.html](fishing-rework-implementation-guide.html)

## Shipped in game (`FISHING_REWORK_ENABLED`)

| Area | Status |
|------|--------|
| Data-driven `fishing.areas[]` + per-action `area` | Done - 10 areas, 23 methods |
| Area modules (1-3 methods, XP/yield chips, fluid strip) | Done |
| Beach, Pier, River, Sewers, Winter Lake, Reef | Done |
| Sea (rowboat, open water, chum line) | Done |
| Deep Sea, Stormy Sea | Done |
| Space Fishing finale (2 methods) | Done |
| Skill detail header: fish currency circle | Done |
| Skills menu fishing card: fish gauge + water strip | Done |
| Per-method attempt bars (archetype curves) | Done - see `docs/fishing-archetype-design.md` |
| Method short labels, catch icons, archetype mapping | Done |
| Catch burst count/stagger tuned by archetype | Done |
| JSON `rewards.fish_min/fish_max` drives fishing yield | Done |
| Corner crop on area BG (RoundedTextureRect + UV crop) | Done |
| Archetype-specific art sway / fluid phase thresholds | Not started |

## Explicitly Deferred

- **Build skill finale** - `build-the-building-that-builds-you` is not gated on fishing
- Teaser-only area rows (hidden future areas)
- Shiny fish + phase badge UI
- Lobster cage **passive collect** module (woodcutting-style)
- Per-method fluid timing from archetype (still one strip per area)
- Lava fishing area (brainstorm only; no actions in DB)

## Current Fishing Unlocks

| Level | Area | Location |
|-------|------|----------|
| 1 | Beach | Shallows |
| 4 | Beach | Rocks |
| 7 | Pier | Dock Edge |
| 11 | Pier | Piling Line |
| 14 | River | River Bend |
| 18 | River | Rapids |
| 22 | Sewers | Drain Gate |
| 26 | Sewers | Tunnel Pool |
| 30 | Reef | Reef Pot |
| 34 | Winter Lake | Ice Hole |
| 40 | Sea | Rowboat |
| 46 | Reef | Reef Cage |
| 52 | Sea | Open Water |
| 58 | Reef | Night Reef |
| 64 | Stormy Sea | Storm Ripple |
| 70 | Sea | Chum Line |
| 74 | Reef | Pearl Bed |
| 78 | Stormy Sea | Storm Line |
| 82 | Deep Sea | Wreck Drop |
| 86 | Deep Sea | Abyss |
| 88 | Deep Sea | Deep Trench |
| 90 | Space Fishing | Starlight |
| 95 | Space Fishing | Reflection |

## Design Direction (Tool x Area)

Player unlocks **tools**, **regions**, and **locations** within each region module. Tool rack is global; location tiles replace verb/action fantasy. **Affinity** is tool x location. Spec: [fishing-tool-area-matrix.md](fishing-tool-area-matrix.md). **Module/location catalog:** [fishing-modules-and-locations-plan.md](fishing-modules-and-locations-plan.md).

## Remaining Big Wins

1. **Shiny fish** - rare flag on catch pop + album/counter
2. **Method timing** - per-archetype attempt bands (line vs net stories); fluid strip stays ambiance-only
3. **Brainstorm HTML** - sync mock areas to `sea`, `winter_lake`, `stormy_sea`, `deep_sea`, and `space`
4. **Lobster passive module** - if design locks cage as non-row activity

## Data Hygiene Commands

```powershell
python scripts\fix-fishing-action-order.py
python scripts\reorganize-fishing-areas.py
python scripts\sync-activity-database-js.py
.\scripts\audit-activity-database.ps1
.\scripts\check-project.ps1
```

## Phone Test Install

```powershell
.\scripts\install-android-phone-debug.ps1
```

Installs **Idle Elite Preview** (`com.idleelite.game.preview`) so the Play/release app and saves stay untouched.
