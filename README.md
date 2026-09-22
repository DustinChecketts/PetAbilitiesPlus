# Pet Abilities Plus

Pet Abilities Plus adds hunter pet-training information to beast tooltips in **WoW Forever**.

Hover a beast and the addon shows the pet abilities and ranks that can be learned by taming it. Once Beast Training has been opened, each rank is compared with the hunter's cached training knowledge:

- **Gray** — the hunter already knows that exact ability/rank.
- **Green** — the hunter has not learned that exact ability/rank.
- **Blue** — learned-state data has not been synchronized yet.

The Beast Training snapshot is saved per character and restored between sessions. It is refreshed only when Beast Training is opened.

## Data

Classic 1-60 wild-creature ability/rank mappings are independently maintained from Petopia Classic reference data. WoW Forever-specific corrections and additions live separately in `Data/ForeverOverrides.lua`.

Petopia documents 13 abilities learned from wild creatures: Bite, Charge, Claw, Cower, Dash, Dive, Furious Howl, Lightning Breath, Prowl, Scorpid Poison, Screech, Shell Shield, and Thunderstomp. Charge Rank 4 and Lightning Breath Rank 1 have no known Classic wild training source.

## Compatibility

This release targets WoW Forever (Interface 16001). It uses Forever's unit-tooltip processing and trainer-service APIs and does not replace or control Blizzard's tooltip lifecycle.

## Installation

Install the addon so the folder is:

`World of Warcraft/_classic_beta_/Interface/AddOns/PetAbilitiesPlus/`

The folder must contain `PetAbilitiesPlus.toc`.

## License

MIT License. See `LICENSE`.
