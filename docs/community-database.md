# PetAbilitiesPlus community creature database

This is a public, opt-in Forever pet ability reference, not a prerequisite to
seeing data in the addon. The addon always displays all shipped verified records.

## Evidence tiers
- **Verified**: a specific wild creature NPC ID is linked to an observed pet
  spellbook ability/rank after a documented tame, reviewed by a maintainer.
- **Candidate**: a player report, Beast Lore inference, historical Classic
  mapping, or a tame lacking a confirmed original wild NPC ID.
- **Conflicting**: different ranks or identities reported; needs investigation.

The shipped keyed database lives in `Data/CommunityVerified.lua`. Never insert
candidate data into production tooltips. In particular, a pet's current GUID
must **not** be assumed to equal the original wild creature's NPC ID.

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
