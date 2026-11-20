# Cyberpunk Yangon art handoff

## First delivery

- `style_mockup.png`: target 640 x 360 night-street style reference.
- `../assets/palette.png`: one opaque swatch per pixel in a horizontal row, extracted from the delivered mockup.
- The mockup is a flattened concept reference, not a tile map or a production sprite sheet. Night lighting is intentional here. Production sprites must follow the neutral-light and separate-glow rules in `framework.md`.
- Status: initial style candidate. Validate the test batch before treating the style/palette as production-locked.

## Working decisions for Claude

- Scale: retain the framework's 32 x 16 tile = 1 metre, 48 px per storey, approximately 30 px bodies on 32 x 48 character frames. Check readability in the test batch.
- Drawing workflow: built-in image generation for concept references, Python/Pillow for exact-size PNG export and palette extraction. No Aseprite-authored source or hand-cleaned animation is claimed. Production frames need pixel cleanup and anchor validation before acceptance.
- Clock recommendation: 30 real minutes covers 06:00–02:00, with sleep skipping the remaining four hours. This is a recommendation, not an implemented setting.
- Academy placeholder: Yangon Institute of Frame Technology (YIFT).
- Creature placeholder: the Silt, matching `GameConcept.md`.
- Signs in this initial mockup use pictograms. Burmese and English pixel fonts remain undecided.

## Delivery order

1. Style mockup, then extracted palette.
2. Pipeline test: ground tiles, one wall, one sign plus glow, one character walk cycle; validate in Godot before broad asset production.
3. Thirteen P0 campus/street assets and the concrete-block kit, using footprints and companion files specified in `framework.md` and `BuildingList.md`.
4. Remaining ground tiles and props.
5. Layered player, three classmates, instructor.
6. Mech only after M3 dimensions arrive; creature afterward.

This delivery does not certify Godot imports or supply the later production assets.
