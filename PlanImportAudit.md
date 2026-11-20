# PDF-to-Markdown completion audit

Compared on 18 November 2026 with `Yangon_YUST_Game_Concept_and_Development_Plan.pdf`, version 1.0 (26 physical pages: cover plus 25 numbered content pages).

## What was already updated

- `GameConcept.md`: most of the new home/café, student-life, driving and alien-incursion plan, plus the later Godot/3D decision.
- `framework.md`, `FirstDistrict.md` and `AGENTS.md`: current 3D production direction and first-district pipeline.
- `BuildingList.md`: still carried compressed tiles, sprite rendering, a dorm starting home and the former campus-first queue.

## Completed

- Added [the full Markdown reference](Yangon_YUST_Game_Concept_and_Development_Plan.md), with all 25 content sections, readable tables, the source image and a link to the unchanged PDF.
- Preserved the original CONFIRMED / PROPOSED / OPEN distinctions. PDF recommendations are document content, not instructions to execute or newly approved features.
- Kept the current **Godot 4 / 3D / fixed high camera** direction. The source PDF predates it and leaves engine/camera open while discussing pixel art.
- Filled missing operational detail in `GameConcept.md`: clock examples, school rhythm, learning rules, match scope, dialogue priority, invitation handling, passenger flow, transaction integrity, static data versus saved state, accessibility, integration checks, feature cards and the example day.
- Updated `BuildingList.md` to metres and direct 3D models; added the family café building and skybridge-side tower; aligned canonical model names, priorities and home location with `FirstDistrict.md`.
- Marked non-first-district footprint conversions as provisional inherited planning dimensions, not PDF-confirmed sizes.
- Clarified prototype car access and later hangar height in `FirstDistrict.md`; added completion checks. The exact purchase/loan progression remains a proposal.
- Marked swimming, dynamic flood rise and extra movement animations as later proposals in `framework.md`, so they do not block the first district.

## Coverage of the original 25 sections

The reference conversion retains every section below. Current project guidance is mapped separately so historical source choices do not silently overwrite later decisions.

| PDF printed page | Topic | Current project coverage |
|---|---|---|
| 01 | Concept at a glance | GameConcept 1-2 |
| 02 | Labels, contents, boundaries | GameConcept introduction; this audit |
| 03 | Design pillars | GameConcept 2 |
| 04 | Confirmed feature register | GameConcept 1, with later decisions distinguished |
| 05 | Connected gameplay loop | GameConcept 3 |
| 06 | City layers and first district | GameConcept 3; FirstDistrict |
| 07 | Original pixel-art direction | Historical source; superseded by framework's 3D direction |
| 08 | Apartment and rooftop café | GameConcept 3; FirstDistrict |
| 09 | Clock and calendar | GameConcept 3; full-cycle interpretation still open |
| 10 | YUST activities | GameConcept 3; FirstDistrict |
| 11 | Easy classes and progression | GameConcept 3 |
| 12 | Friendly matches | GameConcept 3-5 |
| 13 | External alien incursions | GameConcept 3, 5-6 |
| 14 | NPC routine and memory | GameConcept 3 |
| 15 | Interactions, crowd and animals | GameConcept 3 |
| 16 | Friendship and romance | GameConcept 3, 6 |
| 17 | Jobs and transaction integrity | GameConcept 3 |
| 18 | Ownership and decoration | GameConcept 3, 6 |
| 19 | Driving and passengers | GameConcept 3; FirstDistrict 6 |
| 20 | Reusable systems and saved state | GameConcept 5, 8 |
| 21 | First playable slice | GameConcept 4; FirstDistrict |
| 22 | Build order and dependencies | GameConcept 5; FirstDistrict 5 |
| 23 | Risks, comfort and checks | GameConcept 7; FirstDistrict 6 |
| 24 | Open decisions and feature card | GameConcept 6, 8 |
| 25 | Example day | GameConcept 9 |

## Important decisions not invented during the import

- Final title, YUST naming, calendar and 30-minute clock interpretation remain provisional/open as noted in the current plan.
- First-district dimensions and converted catalogue footprints are planning suggestions.
- Mecha ownership, pilot count, real-battle difficulty and compulsory deployment rules remain open.
- Housing progression, romance cast, economy values, controller support and target PCs remain open.
- Earlier local rules such as grades/allowance and earned uniforms are explicitly identified as retained project rules, not attributed to the PDF.
- The 300 x 300 m campus allocation remains available for later work; it does not replace the compact first-district loop.

## Verification

- 25 of 25 numbered PDF content sections converted.
- Extracted source word coverage checked: no source content words missing after removal of running footers and the repeated cover metadata.
- PDF cover and final page rendered and visually inspected; text on all 26 pages inspected through extraction.
- Markdown table structure, relative links, first-district/catalogue dimensions and remaining obsolete active rules checked.
- The PDF, models, textures, game projects and references were not overwritten. Only planning documents and document-conversion utilities were changed/added.
- Previous root Markdown files are backed up in `tmp/md_migration_before/`.

This is a documentation completion audit, not a claim that any gameplay feature, model pipeline or Godot scene has been implemented.
