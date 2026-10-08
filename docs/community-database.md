# PetAbilitiesPlus community creature database

This is a public, opt-in Forever pet ability reference, not a prerequisite to
seeing data in the addon. The addon always displays all shipped verified records.

## Evidence tiers and UI presentation
Confidence belongs to each **creature-to-ability/rank assertion**, not the creature
as a whole. The same creature may have records at different confidence levels.

- **verified** (green check): original wild NPC ID was captured before taming,
  pet spellbook ability and rank were read after a successful tame, and evidence
  was reviewed. This is the strongest available observation, not a guarantee
  that a later beta build has not changed the pet.
- **community** (blue check): attributed player/forum/spreadsheet report with
  identifiable source, not independently validated by our capture pipeline.
- **lead** (grey check): incomplete, indirect, conflicting, or outdated claim
  needing investigation. A conflicting observation stays recorded as its own
  lead rather than overwriting prior evidence.

The check is a compact display affordance; provide text in tooltips and a
color-independent accessible description. Never use a check without its label
in detailed views. Tooltip provenance should include source URL, contributor
(where publicly credited), observation date, and client build **when known**.

Recommended source assertion schema (all fields optional except NPC identity
or explicit unresolved identity, ability name, rank when applicable, and tier):

```lua
{
  npcId = 250874, creature = "Vuldren Alpha",
  ability = "Trickster's Dance", rank = 1,
  tier = "verified", sourceType = "in-game-tame",
  sourceUrl = nil, contributor = nil,
  observedAt = nil, clientBuild = nil,
  evidence = "wild-target-and-pet-spellbook",
  notes = nil,
}
```

Preserve multiple dated observations rather than overwriting conflicts. A
report of "no ability" must be distinguished from "not inspected" or "unknown".
Imported forum and spreadsheet records start as community or lead, never
verified. An automatically captured record remains a candidate until identity,
spellbook extraction, and evidence review pass.

The shipped keyed database lives in `Data/CommunityVerified.lua`. Do not
silently promote community or lead records into verified production tooltips.
A pet's current GUID must **not** be assumed to equal its original wild NPC ID.

## First community observation
Giant Moss Creeper, observed at levels 24–25, had Bite rank 4 and Web rank 2
after taming. Evidence: direct player tame and spell/action bar screenshots.
Original wild NPC ID still needs to be captured, so it remains a candidate.

## Contribution plan
1. The optional beta recorder saves wild target snapshots locally.
2. On taming, match only when the player has deliberately armed a snapshot and
   the subsequent pet appears within the same short session. Mark this as a
   **candidate** until spellbook rank extraction and identity are validated.
3. Show the candidate and its provenance in the UI immediately.
4. The player can copy a privacy-safe payload to a public, no-login form.
5. A maintainer reviews and merges evidence into the public GitHub database.
6. Publish updated addon data without requiring a new discovery workflow.

No character names, realms, GUIDs, or account IDs are needed for submission.
No automatic network submission is attempted from WoW Lua. The form endpoint
will be configured only after the user creates an owned public form.


## Baseline-first versioning contract (Classic → Forever)

The complete Classic creature and pet-ability dataset is the canonical baseline.
Forever inherits Classic by default. Its layer consists of **new NPCs**,
**additive sources**, and **explicit, narrowly scoped corrections**. Do not
duplicate unchanged Classic rows in a separate Forever database.

Every exception has an audit record with: stable NPC ID or ability key,
field/association affected, previous value, replacement or removal,
reason/evidence, source URL (if available), observed build/date, and
verification tier. Preserve the original Classic value for other clients.

Operations are distinct:
- `addCreature`: Forever-only NPC, not present in Classic.
- `addSource`: a new creature–ability–rank association.
- `removeSource`: explicitly suppress an inherited Classic association;
  **never** infer removal from an empty spellbook or missing report.
- `overrideField`: adjust family, tameability, level range, zone, etc.
- `renameAbility`: map Classic display identity to a Forever display name,
  keeping a stable canonical key for learned-rank tracking.

Current example: Classic **Screech** displays as **Demoralizing Screech**
in Forever. This is a documented alias, not a second independent ability.
An unreviewed report may suggest a correction but must not mutate the
production baseline. Unresolved NPC names/IDs remain explicitly unresolved;
do not silently match a new Forever NPC to a similarly named Classic one.

Migration order: populate historical Classic NPC IDs and metadata; ingest
Forever-only NPCs; apply reviewed overrides; overlay attributed community
reports and local candidate captures for display/review. The same resolved
catalog and query API serve both PetAbilitiesPlus and ForeverPets.
