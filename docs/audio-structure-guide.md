# Idle Elite Audio Structure Guide

This file is the map for anyone iterating on Idle Elite sounds. Read it before replacing, adding, moving, or rewiring audio assets. The project already has several different audio pathways, and many of them intentionally share assets at different volumes, pitches, and timings. Do not treat a sound file reference as a one-to-one feature.

## First Principles

- Runtime audio is owned almost entirely by `scripts/main.gd`.
- Runtime audio assets live in `assets/sfx/` and `assets/music/`.
- Candidate and audition-only assets live in `assets/sfx-candidates/`, `assets/content/sfx-candidates/`, `assets/sfx/pin-candidates/`, and docs audition pages.
- `project.godot` does not define the `Music` and `SFX` buses. The game creates them in code at runtime.
- Audio is locked until player input. Most sound helpers return silently until `_unlock_audio_for_gameplay()` has run.
- Music is not a normal single background loop. It is a layered, probabilistic flow system driven by player actions, streaks, success/failure, stamina cost, idle time, and saved groove state.
- New or replacement SFX should start quieter than existing cues, especially if they are rare, layered, celebratory, or repeated.
- Validate new sound in game context. Solo audition can catch obvious bad assets, but it does not catch stacking, repeated-tap fatigue, music masking, mobile speaker harshness, or lock/jingle pileups.

## Important Files

| File or folder | Role |
| --- | --- |
| `scripts/main.gd` | Main audio implementation: constants, runtime state, buses, players, SFX helpers, music flow, settings, save/load. |
| `assets/sfx/` | Shipped runtime SFX. These are safe to reference from the game and are included in exports unless filtered elsewhere. |
| `assets/music/` | Shipped runtime music layers and source loops. The `.ogg` loop files are the active runtime paths in `MUSIC_SONG_SETS`. |
| `assets/sfx-candidates/` | Audition candidates for button/click experiments. Not currently runtime-wired. |
| `assets/content/sfx-candidates/` | Audition candidates for lock/glass/metal experiments. This path is excluded from export and is not runtime-wired. |
| `assets/sfx/pin-candidates/` | Runtime-referenced pin sounds, despite the folder name. `MODULE_PIN_ENTRY_SFX_PATH` and `MODULE_PIN_EXIT_SFX_PATH` point here. |
| `docs/xp-sfx-audition.html` | Browser audition page for shipped/candidate action, crit, feedback, chain, and water sounds. Not the runtime implementation. |
| `docs/pin-sfx-audition.html` | Browser audition page for pin entry/exit sounds. Not the runtime implementation. |
| `AGENTS.md` | Process-level audio safety rules. Follow them. |
| `export_presets.cfg` | Export filters exclude candidate/source folders such as `assets/content/sfx-candidates/*` and `assets/content/*source-originals*`. |

## Where Audio Lives In `main.gd`

Line numbers move, so search symbols instead of trusting exact offsets.

| Area | Search symbols | Purpose |
| --- | --- | --- |
| Button SFX constants | `DEFAULT_BUTTON_SFX_PATH`, `DEFAULT_BUTTON_SFX_DEBOUNCE_MSEC` | Default UI button sound path and tap debounce. |
| Audio constants | `ACTIVITY_SUCCESS_SFX_PATHS`, `MUSIC_SONG_SETS`, `MUSIC_BUS_NAME`, `SFX_BUS_NAME` | Asset lists, volumes, music weights, bus names, timing knobs. |
| Runtime state | `music_volume`, `sfx_volume`, `flow_heat`, `music_players`, `audio_stream_cache`, `music_stream_cache` | Persistent settings and transient audio state. |
| Audio settings UI | `_audio_volume_control`, `_set_music_volume_from_slider`, `_set_sfx_muted_from_toggle` | Settings screen sliders and mute buttons. |
| Save/load | `_save_payload`, `_restore_audio_settings_from_save`, `_restore_music_flow_state_from_save` | Persisted audio settings and partial music-flow state. |
| Audio build/warmup | `_build_boot_audio`, `_build_extended_audio`, `_warm_extended_audio_async`, `_build_audio` | Player creation and deferred warmup. |
| Core helpers | `_sfx`, `_load_sfx_stream`, `_play`, `_play_with_pitch`, `_can_play_audio` | Shared player creation and playback gating. |
| Music flow | `_process_music_flow`, `_record_music_flow_start`, `_record_music_flow_action`, `_start_music_cycle` | Layered adaptive music state machine. |
| Gameplay SFX | `_play_activity_success_sound`, `_play_chain_move_jingle_mix`, `_play_fishing_attempt_reveal` | Actual gameplay sound entry points. |

## Runtime Buses

The game creates two named buses at runtime:

| Bus | Constant | Created by | Used by |
| --- | --- | --- | --- |
| Music | `MUSIC_BUS_NAME := "Music"` | `_ensure_audio_buses()` -> `_ensure_audio_bus()` | All `music_players`. |
| SFX | `SFX_BUS_NAME := "SFX"` | `_ensure_audio_buses()` -> `_ensure_audio_bus()` | Every `_sfx()` player. |

`_apply_audio_bus_volumes()` maps player-facing settings to bus volume:

- Music bus volume is `music_volume * MUSIC_OUTPUT_GAIN`, unless muted.
- SFX bus volume is `sfx_volume`, unless muted.
- `MUSIC_OUTPUT_GAIN` is `0.32`, so music is globally reduced even when the music slider is at 100%.
- Muted buses are set to `MUSIC_SILENCE_DB`, currently `-80.0`.
- The master bus is explicitly unmuted with `AudioServer.set_bus_mute(0, false)`.

This means changing an individual `AudioStreamPlayer.volume_db` is only one stage of gain. Final output is:

`player.volume_db` + bus volume from the Music/SFX slider + device/browser output behavior.

Do not compensate for quiet audio by cranking a player to `0.0 dB` without testing it in the full stack.

## Audio Unlock Gate

Audio starts locked until user input. This is important for web/mobile autoplay policies and for avoiding surprise sounds at boot.

The flow:

1. `_note_player_input(event)` observes mouse, touch, or key input.
2. `_unlock_audio_for_gameplay()` sets `audio_unlocked_by_input = true`.
3. `_prepare_audio_buses()` ensures buses exist and applies saved volumes.
4. `_play_audio_unlock_ping()` plays `assets/sfx/click.wav` quietly once at `-16.0 dB`.
5. `_ensure_music_playing()` is allowed to start music players if the music flow says they should run.

All normal SFX helpers call `_can_play_audio()` directly or indirectly. If a new helper forgets this gate, it can behave differently from the rest of the game.

## Player Creation And Warmup

Audio players are created as child nodes in `main.gd`; there are no scene-authored audio players in `scenes/main.tscn`.

Use `_sfx(path)` to create SFX players. It:

- Creates an `AudioStreamPlayer`.
- Loads the stream through `_load_sfx_stream(path)`.
- Assigns `player.bus = SFX_BUS_NAME`.
- Adds the player to the main node.

`_load_sfx_stream(path)` uses `audio_stream_cache`, so multiple players can share a loaded stream.

There are three build levels:

| Function | What it builds | Why |
| --- | --- | --- |
| `_build_boot_audio()` | Buses, default click player, audio unlock ping player | Cheap sounds needed immediately. |
| `_build_extended_audio()` | Success, crit, failure, lock, chain-adjacent, passive, pin, bonus, fishing players | Full gameplay sound set. |
| `_warm_extended_audio_async()` | Same extended set, but spread across frames using `EXTENDED_AUDIO_WARMUP_FRAME_BUDGET_MSEC` | Avoids a large frame hitch after boot. |

Several helpers call `_ensure_extended_audio()` before playing. Do not manually instantiate duplicate players for one-off sounds unless there is a clear reason. Prefer adding to the existing build/warmup paths.

## Default Button And Tap SFX

Constants:

- `DEFAULT_BUTTON_SFX_PATH := "res://assets/sfx/Sample_0029 bowling ui snap.wav"`
- `DEFAULT_BUTTON_SFX_VOLUME_DB := -4.0`
- `DEFAULT_BUTTON_SFX_DEBOUNCE_MSEC := 180`
- `ACTIVITY_START_SFX_PATH := DEFAULT_BUTTON_SFX_PATH`
- `ACTIVITY_START_SFX_VOLUME_DB := -1.0`
- `ACTIVITY_START_SFX_PLAYER_COUNT := 3`

The same `Sample_0029 bowling ui snap.wav` asset is used for general button clicks and activity starts, but through different playback paths.

General buttons:

- `_attach_button_depress_animation(button, depressed_scale := 0.965, play_sfx := true)` attaches button animation and optional SFX.
- `_attach_default_button_sfx(button)` connects to `_play_default_button_sfx_for_button_bound`.
- `_play_default_button_sfx_for_button(button)` applies debounce and skips active action taps.
- `_play_default_button_sfx()` plays `click_player`.

Activity starts:

- `_play_activity_tap_sfx()` uses `click_player`, but temporarily sets `volume_db = ACTIVITY_START_SFX_VOLUME_DB`.
- There is also an `activity_start_players` pool created by `_ensure_activity_start_players()`, but current tap playback uses `click_player`.
- Starting an activity calls `_unlock_audio_for_gameplay()` and then `_play_activity_tap_sfx()`.

Common mistake: replacing the default button asset changes both ordinary UI clicks and activity-start taps. If only one should change, introduce a separate path and wire it deliberately.

## Activity Success, Failure, Crits, And Rewards

Success paths:

- `ACTIVITY_SUCCESS_SFX_PATHS` contains four glass pip WAV files:
  - `action_success_glass_pip_1.wav`
  - `action_success_glass_pip_2.wav`
  - `action_success_glass_pip_3.wav`
  - `action_success_glass_pip_4.wav`
- `_build_extended_audio()` creates one player per path in `success_players`.
- Each player uses `ACTIVITY_SUCCESS_SFX_VOLUME_DB`, currently `-1.0`.
- `_play_activity_success_sound(streak_step, medal_unlocked, streak_bonus, xp_crit, mega_crit, crit_chain_count)` chooses the pip by `streak_step`.

Crit paths:

- `ACTIVITY_CRIT_SFX_PATHS` contains five blue glass fanfare WAV files.
- `_build_extended_audio()` creates `crit_success_players`.
- Each uses `ACTIVITY_CRIT_SFX_VOLUME_DB`, currently `-10.0`.
- `_play_activity_crit_sound()` chooses by streak step.
- Mega crits increase pitch from `ACTIVITY_MEGA_CRIT_SFX_PITCH_START` by `ACTIVITY_MEGA_CRIT_SFX_PITCH_STEP`, capped by `ACTIVITY_MEGA_CRIT_SFX_PITCH_MAX`.

Failure paths:

- General failure uses `warm_reject.wav` through `failure_player`.
- Fishing failure uses `water_whoosh_subtle.wav` through `fishing_failure_player` at `FISHING_FAILURE_SFX_VOLUME_DB := -16.0`.
- Action opportunity misses use `warm_reject.wav` at `ACTION_OPPORTUNITY_MISS_SFX_VOLUME_DB := -15.0`.

Reward overlays:

- Level up uses `level_up_jingle.wav` through `level_player`.
- Medal reward currently uses `xp_spark.wav` through `medal_player`.
- Streak bonus uses `xp_spark.wav` through `bonus_jingle_player` and `bonus_jingle_echo_player`, at `-12.0 dB` and `-15.0 dB`, with two different pitches.
- Info-chip upgrades use `xp_spark.wav` in a five-player pool at `INFO_CHIP_UPGRADE_SFX_VOLUME_DB := -18.0`, with pitch stepping.

Common mistake: adding a celebratory sound to the success path without checking the existing medal/streak/level/crit overlays. A single action completion can already produce success SFX, visual reward floats, music-flow heat, and sometimes reward sounds. Do not stack another full-volume reward on top.

## Chain, Lock, And Unlock Audio

This is one of the easiest areas to break because it intentionally layers short impacts, jingles, proximity gain, random pitch, and delayed tweens.

Core constants:

- `CHAIN_MOVE_SFX_PATHS`: five short chain movement WAV files.
- `CHAIN_MOVE_PLAYER_COPIES := 3`: creates three players per chain movement asset.
- `CHAIN_JINGLE_SFX_PATH := "res://assets/sfx/Jingle Chains.wav"`
- `CHAIN_JINGLE_MIX_LAYER_COUNT := 2`
- `PADLOCK_CLUSTER_SFX_PATH := "res://assets/sfx/padlock_cluster.wav"`
- `CHAIN_OFFSCREEN_GAIN := 0.25`
- `CHAIN_SCROLL_TOWARD_GAIN := 0.74`

Runtime setup:

- `_ensure_chain_move_audio()` lazily builds `chain_move_players` and `chain_jingle_players`.
- Chain impact players are selected by `_chain_move_player_for_hit()`.
- If no idle player is available, a random player is stopped and reused.

Playback helpers:

- `_play_chain_move_jingle_mix(kind, intensity, source)` plays one or more chain impacts and may add a jingle.
- `_play_chain_impact_cluster(hit_count, intensity, kind, proximity_gain)` schedules short delayed impacts.
- `_play_chain_impact_hit()` sets loudness and pitch with random variation.
- `_play_chain_jingle_mix()` layers up to two jingle players with pitch offsets.
- `_play_capped_chain_jingle()` forcibly fades and stops the jingle after a capped duration.
- `_play_padlock_cluster_sfx()` plays the padlock cluster.
- `_play_chain_fall_sfx_sequence(source)` sequences jingle, chain hit, second jingle, second chain hit for unlock ceremonies.

Proximity gain:

- `_chain_proximity_gain(source)` quiets chain audio when the relevant lock is offscreen.
- It uses the visible overlap of the lock rig in the skill detail viewport.
- It can raise gain when the user is scrolling toward an offscreen chain.
- This prevents hidden lock rigs from sounding as loud as visible lock rigs.

Signals:

- Activity lock overlays connect `group.chain_moved` to `_play_chain_move_jingle_mix`.
- Activity lock overlays connect `group.padlock_clicked` to `_play_padlock_cluster_sfx`.
- Unlock ceremonies call `_play_chain_fall_sfx_sequence()`.

Common mistakes:

- Do not play `Jingle Chains.wav` directly as a normal full-length one-shot. The runtime caps and fades it.
- Do not remove proximity gain. Offscreen locks can otherwise become loud and confusing.
- Do not add more layers to `CHAIN_JINGLE_MIX_LAYER_COUNT` without testing repeated unlocks and drag/click gestures.
- Do not replace all chain movement files with long tails. These players are pooled and reused rapidly.

## Pin Module Audio

Constants:

- `MODULE_PIN_ENTRY_SFX_PATH := "res://assets/sfx/pin-candidates/pin_exit_pull_04_bright_tick.wav"`
- `MODULE_PIN_EXIT_SFX_PATH := "res://assets/sfx/pin-candidates/pin_entry_thwick_01_tight.wav"`
- `MODULE_PIN_ENTRY_SFX_VOLUME_DB := -5.0`
- `MODULE_PIN_EXIT_SFX_VOLUME_DB := -7.0`

This looks backwards by filename, but it is current runtime behavior: entry uses an exit-pull candidate, and exit uses an entry-thwick candidate. Treat that as intentional unless you are specifically revisiting pin feel.

Playback:

- `_play_module_pin_confirm_animation()` schedules `_play_module_pin_entry_sfx()`.
- `_play_module_pin_unpin_animation()` calls `_play_module_pin_exit_sfx()`.

Common mistake: assuming `assets/sfx/pin-candidates/` is unused because it says "candidates". It is runtime-wired.

## Passive Module Audio

Passive module sounds are intentionally quiet.

Runtime players:

- `passive_log_land_players`: four `click.wav` players.
- Their base volumes are `-18.0`, `-19.5`, `-21.0`, and `-22.5`.
- `_play_passive_log_land_sfx(index)` adds pitch variation around `1.12+`.
- `passive_upgrade_player`: `click.wav` at `-15.0 dB`, pitch `1.28`.

These sounds are meant to support repeated log collection without fatigue. If you replace them, test several passive ticks and upgrade taps in sequence.

## Fishing Audio

Fishing currently reuses several shared families.

Important helpers:

- `_play_fishing_attempt_reveal(skill_id, action_id, success)` handles attempt result presentation.
- `_play_fishing_catch_burst()` and `_play_fishing_catch_burst_for_action()` handle catch visuals and may accompany success flow.
- `_play_fishing_wallet_circle_pop(delay)` plays delayed wallet collection feedback.
- `_play_fishing_wallet_open_sfx()` uses chain impact plus a very short, quiet chain jingle.
- `_play_fishing_gear_selected_sfx()` uses a single chain click.
- `_play_fishing_method_unlock_ceremony()` uses padlock and unlock motion sounds.
- `_play_padlock_click_shake()` plays `padlock_cluster_player`.

Fishing failure:

- Uses `water_whoosh_subtle.wav`.
- Player volume is `-16.0 dB`.

Fishing gear and wallet:

- These are not separate fishing-only WAVs. They reuse chain/lock impact helpers.
- This is intentional because fishing methods/tools are tied to lock/wallet UI affordances.

Common mistake: adding a new fishing success sound while normal activity success sound already fires through `_play_activity_success_sound()` for many fishing completions. Trace the reward path before adding anything.

## Action Opportunity Audio

Action opportunities have separate quiet success/miss feedback:

- Success uses `xp_spark.wav` through `opportunity_success_player` at `-18.0 dB`, random pitch `1.12` to `1.24`.
- Miss uses `warm_reject.wav` through `opportunity_miss_player` at `-15.0 dB`, random pitch `0.86` to `0.94`.
- `_play_action_opportunity_window_feedback()` calls `_play_action_opportunity_sfx(success)`.

These should stay smaller than regular action success and crit sounds.

## Music System

Music is a layered adaptive system, not a simple background track.

Song sets:

| Set | Weight | Layers |
| --- | ---: | --- |
| `original` | `0.70` | `base_loop.ogg`, `heavy_loop.ogg`, `ultimate_loop.ogg` |
| `guitar` | `0.15` | `guitar_base_loop.ogg`, `guitar_heavy_loop.ogg` |
| `piano` | `0.15` | `piano_base_loop.ogg`, `piano_heavy_loop.ogg`, `piano_ultimate_loop.ogg` |

There are also source WAVs in `assets/music/` with long descriptive names. The active runtime paths in `MUSIC_SONG_SETS` are the shorter `.ogg` loop files.

Player setup:

- `_select_music_song_for_cycle()` chooses the next song set for a music cycle.
- If the selected song set name, layer count, and track paths already match the prepared players, the existing `music_players` pool is reused and only layer gains are reset.
- `_build_music_players()` creates one `AudioStreamPlayer` per track when the selected song set changes or no prepared pool exists.
- `_load_music_stream(path)` uses `music_stream_cache`, so repeated cycles do not reload the same loop resources.
- WAV streams are forced to `AudioStreamWAV.LOOP_FORWARD` inside the music cache helper if used.
- Ogg streams are set to loop inside the music cache helper.
- Every music player starts at `MUSIC_SILENCE_DB`.
- Music players use the `Music` bus.

Music start rules:

- Music does not immediately blast at launch.
- `_record_music_flow_start()` raises `flow_heat` when an activity starts.
- `_record_music_flow_action()` raises or lowers heat after completions.
- `music_start_chance_unlocked` becomes true after enough actions.
- A music cycle can start on completion with `MUSIC_COMPLETION_START_CHANCE := 0.10`.
- A saved player with enough prior groove can get launch start chance through `_maybe_start_music_cycle_on_launch()`, with `MUSIC_LAUNCH_START_CHANCE := 0.25`.

Music intensity:

`_music_flow_target_intensity()` returns:

- `0`: silence.
- `1`: base layer only.
- `2`: base plus heavy layer.
- `3`: base, heavy, and ultimate layer.

Targets from `_music_targets_for_intensity()`:

- Intensity 0: `[0.0, 0.0, 0.0]`
- Intensity 1: `[1.0, 0.0, 0.0]`
- Intensity 2: `[0.70, 1.0, 0.0]`
- Intensity 3: `[0.56, 0.82, 1.0]`

Layer volume boosts:

- `MUSIC_LAYER_VOLUME_BOOST_DB := [1.5, -3.5, 2.2]`
- This means the middle/heavy layer is intentionally pulled down relative to base and ultimate.

Fade behavior:

- Base layer fade: `MUSIC_BASE_FADE_SECONDS := 1.6`
- Upper layer fade: `MUSIC_LAYER_FADE_SECONDS := 4.5`
- Ultimate fade: `MUSIC_ULTIMATE_FADE_SECONDS := 2.8`
- Start fade: `MUSIC_START_FADE_SECONDS := 14.4`
- Quiet break fade: `MUSIC_QUIET_BREAK_FADE_SECONDS := 8.0`

Quiet breaks:

- `_maybe_trigger_music_quiet_break(stamina_cost)` can trigger a break for low-stamina-cost actions.
- Break chance is `MUSIC_QUIET_BREAK_CHANCE := 0.01`.
- Break lockout is `MUSIC_QUIET_BREAK_LOCKOUT_SECONDS := 30.0`.
- `_process_music_base_loop_guard()` also prevents base-only music from lingering too long.

Common mistakes:

- Do not replace a layered loop with a full mix unless you understand how it will combine with other layers.
- Do not assume every song set has three tracks. The guitar set has only base and heavy.
- Do not set music player volumes directly as a "fix" without considering `music_layer_gains`, `MUSIC_LAYER_VOLUME_BOOST_DB`, and `MUSIC_OUTPUT_GAIN`.
- Do not add constant background music behavior unless that is the explicit design goal. The current system intentionally breathes.

## Settings And Save Data

Saved audio fields in `_save_payload()`:

- `audio_settings_version`
- `music_volume`
- `sfx_volume`
- `music_muted`
- `sfx_muted`
- `music_start_chance_unlocked`
- `flow_heat`
- `flow_active_action_seconds`

Restore paths:

- `_restore_audio_settings_from_save(data)` restores `music_volume` and `sfx_volume`.
- `_load_game_core(data)` restores `music_muted` and `sfx_muted`.
- `_restore_music_flow_state_from_save(data)` restores `music_start_chance_unlocked`, `flow_heat`, and `flow_active_action_seconds`.
- `_load_game_core(data)` calls `_apply_audio_bus_volumes()` after restore.

Not saved:

- Individual `AudioStreamPlayer` instances.
- Player pools.
- `audio_stream_cache`.
- `music_stream_cache`.
- `music_players`.
- `music_started`.
- Current active song set.
- Current music layer gains.
- Chain jingle fade tweens.
- Audio unlock ping state.

Do not rename saved keys without migration. Do not rely on runtime-only player state surviving a restart.

## Asset Ownership And Export Notes

Runtime-safe locations:

- Put shipped SFX in `assets/sfx/`.
- Put shipped music loops in `assets/music/`.
- Keep `.import` metadata paired with the sound asset when moving tracked runtime assets.

Candidate locations:

- `assets/sfx-candidates/` is for audition candidates.
- `assets/content/sfx-candidates/` is for audition/source candidates and is excluded from Android export.
- `docs/*.html` audition pages may reference candidates for browser playback.

Export caveat:

`export_presets.cfg` excludes candidate/source-style paths such as:

- `assets/content/*preview*`
- `assets/content/*source-originals*`
- `assets/content/sfx-candidates/*`
- `docs/*.html`

If you wire runtime code to an excluded asset, it may work locally and fail in an exported build. Use `assets/sfx/` or `assets/music/` for anything the game actually plays.

## Adding Or Replacing A Sound

Use this checklist.

1. Identify the exact runtime helper that should play the sound.
2. Search current references with `rg`:
   - Asset path.
   - Helper name.
   - Player variable.
   - Related constants.
3. Decide whether this is a replacement or a new sound family.
4. Put shipped assets under `assets/sfx/` or `assets/music/`, not a candidate folder.
5. Add a named constant for the path if the sound is feature-owned.
6. Add a player in `_build_extended_audio()` or `_build_boot_audio()` as appropriate.
7. Add the same player setup to `_warm_extended_audio_async()` if it belongs to extended audio.
8. Route playback through `_play()` or `_play_with_pitch()` unless you need custom capped/faded behavior.
9. Respect `_can_play_audio()`.
10. Set `volume_db` conservatively.
11. If sound can repeat or stack, test repeated taps, multiple completions, failures, and unlock sequences.
12. If the change affects UI, visuals, layout, animation, scenes, or other player-visible behavior, capture/report a screenshot per `AGENTS.md`.
13. Run validation through the safe Godot wrapper or preferred project script.

Good starting volume guesses:

- Frequent UI tick: `-12.0 dB` to `-18.0 dB`.
- Regular button pop: compare against `DEFAULT_BUTTON_SFX_VOLUME_DB := -4.0`, but start quieter for new assets.
- Passive/repeated ambient UI: `-18.0 dB` or quieter.
- Reward accent: `-10.0 dB` to `-16.0 dB`, unless replacing an existing reward at a known level.
- Chain/lock impacts: use existing chain helpers and intensity/proximity instead of raw player volume.

## Replacing Music Layers

Music loops are special.

Checklist:

1. Confirm whether you are replacing a runtime `.ogg` loop or only a source `.wav`.
2. Keep loop length and musical alignment compatible across layers in the same song set.
3. Export to `.ogg` for runtime if following the existing pattern.
4. Update `MUSIC_SONG_SETS` only after the asset is in `assets/music/`.
5. Test intensity 1, 2, and 3 transitions.
6. Test quiet breaks and idle fade.
7. Test with music slider around 55%, because that is the default.
8. Test SFX over music, especially action success, crit, chain unlock, and failure sounds.

Do not add a third layer to the guitar set without checking array assumptions around layer gains and boosts. The system usually tolerates fewer players, but the shared target arrays and boost arrays are written around a three-layer maximum.

## Validation Commands

Follow `AGENTS.md`: never call `Godot.exe` directly.

Preferred full validation:

```powershell
.\scripts\check-project.ps1
```

Quick Godot startup validation:

```powershell
.\run-godot-safe.ps1 --path . --quit-after 1
```

After any Godot command, verify no headless Godot process was left behind by that command. Only terminate headless/non-interactive Godot processes that were launched by the validation command and should have exited.

Audio-specific manual validation to do when possible:

- Start from fresh launch and verify no sound plays before first input except allowed platform behavior.
- Tap normal buttons and activity buttons separately.
- Complete normal successful actions repeatedly.
- Force or find a failure.
- Trigger a crit or use test state if available.
- Tap/drag/click lock overlays.
- Unlock an activity with chains.
- Open/select fishing gear and trigger a fishing failure.
- Pin and unpin a module.
- Lower SFX slider, mute SFX, unmute SFX.
- Lower music slider, mute music, unmute music.
- Leave the game idle long enough to confirm music fades down instead of droning.

## Common Agent Mistakes To Avoid

- Do not wire runtime code to `assets/content/sfx-candidates/`; it is excluded from export.
- Do not assume `assets/sfx/pin-candidates/` is unused. It has runtime references.
- Do not replace `DEFAULT_BUTTON_SFX_PATH` unless you want to affect both normal UI clicks and activity-start taps.
- Do not add new full-volume reward sounds on action success without checking streak bonus, medal, level-up, crit, and music heat behavior.
- Do not play `Jingle Chains.wav` directly without the capped fade helper.
- Do not remove `_can_play_audio()` gating.
- Do not create a new bus in `project.godot` for this system unless you are intentionally changing the runtime bus architecture.
- Do not ignore `MUSIC_OUTPUT_GAIN` when judging music loudness.
- Do not hand-edit or delete `.import` files casually when moving runtime audio.
- Do not validate only by opening an audio file. Validate in game because timing, bus volume, pitch, and stacking are the actual experience.

## 2026-06-20 Button SFX Incident Notes

This pass replaced the default button/activity tap sound, and several mistakes made the work noisy and confusing. Treat these as specific rules for future audio edits:

- Scope the request before touching assets. The request was about button press sounds, not XP success sounds. Do not change `ACTIVITY_SUCCESS_SFX_PATHS` or overwrite `action_success_glass_pip_1..4.wav` when the user asks for button clicks.
- Preserve deliberately tuned reward cues. The glass pip XP success sounds are pitched variants selected by streak step in `_play_activity_success_sound()`. They are not generic button sounds.
- Find all active playback paths before editing. Activity taps can involve `_attach_default_button_sfx()`, `_play_default_button_sfx_for_button()`, `_start_action()`, and `_play_activity_tap_sfx()`. Changing only one constant may not affect the audible path.
- Watch for duplicate playback. Activity buttons should not play both the generic button-down SFX and `_play_activity_tap_sfx()` for the same press.
- Remember Godot import caching. After replacing runtime audio source files, run a safe import pass such as `.\run-godot-safe.ps1 --path . --import`; otherwise the game can keep playing stale `.godot/imported/*.sample` data.
- Avoid broad legacy-file overwrites. Copying a candidate over `click.wav`, `activity_start_badge_whisk.wav`, and the XP pips was too aggressive. If legacy filename compatibility is needed, overwrite only the legacy button/start filenames and document why.
- Do not restore binary files with shell redirection. PowerShell `>` corrupted WAV restoration by writing text-style output. Use `git checkout HEAD -- path` or another binary-safe copy path.
- Normalize and trim user-recorded sounds before wiring them. The manual Small Pop had about 177 ms of leading delay and mouth noise; it needed leading trim plus subtle attack/release fades before it felt like a button.
- Validate restart timing. If a visible Godot process predates the edit or import pass, it can keep old streams/players in memory. Tell the tester to restart and include exact process/edit timestamps when relevant.
- Use the audition page for auditioning, but validate final timing in the game. Browser playback does not prove Godot bus volume, import cache, debounce, duplicate handlers, or action-start routing.

## Quick Reference

| Sound family | Runtime asset(s) | Player/helper | Notes |
| --- | --- | --- | --- |
| Default UI click | `assets/sfx/Sample_0029 bowling ui snap.wav` | `click_player`, `_play_default_button_sfx()` | Debounced; also used by activity tap at different volume. |
| Audio unlock ping | `assets/sfx/click.wav` | `audio_unlock_ping_player` | Quiet one-time sound after first input. |
| Activity start tap | `assets/sfx/Sample_0029 bowling ui snap.wav` | `_play_activity_tap_sfx()` | Uses `ACTIVITY_START_SFX_VOLUME_DB`. |
| Activity success | `action_success_glass_pip_1..4.wav` | `success_players`, `_play_activity_success_sound()` | Streak step selects variant. |
| Activity crit | `action_crit_blue_glass_fanfare_1..5.wav` | `crit_success_players`, `_play_activity_crit_sound()` | Mega crit increases pitch. |
| General failure | `warm_reject.wav` | `failure_player` | Used for negative feedback paths. |
| Fishing failure | `water_whoosh_subtle.wav` | `fishing_failure_player` | Quiet at `-16.0 dB`. |
| Opportunity success | `xp_spark.wav` | `opportunity_success_player` | Quiet, pitched up. |
| Opportunity miss | `warm_reject.wav` | `opportunity_miss_player` | Quiet, pitched down. |
| Level up | `level_up_jingle.wav` | `level_player` | Reward jingle path. |
| Medal / bonus / info chips | `xp_spark.wav` | `medal_player`, `bonus_jingle_player`, `info_chip_upgrade_players` | Same asset, different volume/pitch/timing. |
| Passive log land | `click.wav` | `passive_log_land_players` | Very quiet repeated feedback. |
| Passive upgrade | `click.wav` | `passive_upgrade_player` | Quiet pitched click. |
| Chain movement | `chain_move_*.wav` | `chain_move_players`, `_play_chain_impact_cluster()` | Pooled, randomized, proximity-aware. |
| Chain jingle | `Jingle Chains.wav` | `chain_jingle_players`, `_play_capped_chain_jingle()` | Capped and faded. |
| Padlock cluster | `padlock_cluster.wav` | `padlock_cluster_player` | Lock clicks and unlock ceremonies. |
| Pin entry | `pin_exit_pull_04_bright_tick.wav` | `module_pin_entry_player` | Runtime path is in `pin-candidates`. |
| Pin exit | `pin_entry_thwick_01_tight.wav` | `module_pin_exit_player` | Runtime path is in `pin-candidates`. |
| Music original | `base_loop.ogg`, `heavy_loop.ogg`, `ultimate_loop.ogg` | `music_players`, music flow helpers | Weighted 70%. |
| Music guitar | `guitar_base_loop.ogg`, `guitar_heavy_loop.ogg` | `music_players`, music flow helpers | Weighted 15%; two layers. |
| Music piano | `piano_base_loop.ogg`, `piano_heavy_loop.ogg`, `piano_ultimate_loop.ogg` | `music_players`, music flow helpers | Weighted 15%. |
