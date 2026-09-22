# Pet Abilities Plus

Pet Abilities Plus is a WoW Forever addon focused first on reproducing the useful behavior of the abandoned Classic/TBC addon **Pet Abilities**: hover a beast and see which hunter pet abilities and ranks can be learned from it.

## Current milestone

**Milestone 1: tooltip parity**

- Identify hovered beasts by creature ID.
- Look up teachable hunter pet abilities.
- Add the ability name and rank to the normal Blizzard unit tooltip.
- Keep Classic data separate from WoW Forever overrides.
- Use a simple, human-readable data format so new ranks and creatures can be added easily.

## Planned expansion

After tooltip parity is stable, the same data model will support an in-game Pet Ability Browser / checklist showing every pet ability and rank, learned status where the client allows it, beasts that teach missing ranks, creature levels, families, zones, and Forever-specific additions.

## Development branch

`feature/wow-forever-port`

## Data source

Classic ability/rank/beast relationships will be rebuilt from public reference data such as Petopia rather than copied from the abandoned addon source.
