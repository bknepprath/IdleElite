# Combo And Event Contact Sheet Status V3

Purpose: record the approved source direction after the action/background split was corrected.

## Current Source Files

- Combo action cutouts: `docs/art-source/asset-sources/combo-event-source-assets/contact-sheet-combo-actions-v3.png`
- Combo action chroma source: `docs/art-source/asset-sources/combo-event-source-assets/contact-sheet-combo-actions-v3-source-chroma.png`
- Combo background plates: `docs/art-source/asset-sources/combo-event-source-assets/contact-sheet-combo-backgrounds-v2.png`
- Event action cutouts: `docs/art-source/asset-sources/event-source-assets/contact-sheet-event-actions-v3.png`
- Event action chroma source: `docs/art-source/asset-sources/event-source-assets/contact-sheet-event-actions-v3-source-chroma.png`
- Event background plates: `docs/art-source/asset-sources/event-source-assets/contact-sheet-event-backgrounds-v2.png`

## Approval Notes

- V2 background sheets are the current approved direction: wide cartoony module plates, no characters, broad readable spaces, and usable left-to-right location variation for later module cropping.
- V3 action sheets correct the button contract: transparent cutout sprites with no scenic panel, no rectangular frame, and no full background.
- The blue player character can appear in action art, but it must match the existing cobalt-blue stick-figure button assets and stay large enough to read as the main actor.
- V1 combo/event/lock master sheet is rejected as runtime source.
- V2 action sheets are rejected because they were full mini-scenes, not transparent button sprites.
- Generated lock contact sheets remain rejected. Runtime lock art uses the corrected neutral two-piece assets in `assets/content/ui/`.

## Alpha QA

Compared against existing action assets such as `assets/content/fight/actions/01-shove-wobbly-hay-bale.png`, `assets/content/build/actions/02-patch-fence-with-confidence.png`, `assets/content/fishing/actions/12-trawl-from-tiny-boat.png`, and `assets/content/thieving/actions/12-heist-the-museum-gift-shop.png`.

Latest audit:

```text
contact-sheet-combo-actions-v3.png: 2048x768 alpha0=99.1% semi=0.8%
contact-sheet-event-actions-v3.png: 1983x793 alpha0=99.2% semi=0.7%
```

These sheets are still source contact sheets. Slice and approve individual 256x256 runtime PNGs before wiring them into `docs/activity-database.json`.
