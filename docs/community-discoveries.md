# Community Pet Ability Discoveries

PetAbilitiesPlus aims to publish an open, independently verified mapping of WoW Forever tameable beasts to the abilities and ranks they teach.

## Submission workflow (v1)

1. PAP records a new observation locally in SavedVariables.
2. The player explicitly chooses **Share Discovery**; never upload automatically.
3. PAP displays a structured, copyable report and a link to create a GitHub Issue using the `pet-discovery` label.
4. The player reviews the report and submits it using a free GitHub account.
5. Maintainers validate, deduplicate, and merge approved records into the shipped creature database.
6. A scheduled GitHub Action can later compile approved data and publish addon updates.

**WoW addon Lua cannot directly make HTTP requests or open a browser.** A prefilled URL must be shown for copy/paste (or via a separately installed companion app). Do not promise that pressing an in-game button silently uploads anything.

## Record schema v1

```json
{
  "schema": 1,
  "client": "Forever",
  "build": "1.60.1",
  "npcId": 250874,
  "creatureName": "Vuldren Alpha",
  "creatureLevel": 10,
  "family": "Fox",
  "zone": "Zephras Isle",
  "subzone": "",
  "mapId": null,
  "x": null,
  "y": null,
  "ability": "Trickster's Dance",
  "rank": 1,
  "spellId": null,
  "evidence": "pet-spellbook-after-tame",
  "status": "reported"
}
```

Coordinates are optional. Never include character name, realm, GUID, account ID, or player location. Evidence must distinguish a tooltip inference from a pet spellbook observation. Keep Hunter learned-rank ledger separate from creature abilities.

## Acceptance rules

- Key: client + NPC ID + ability + rank, with optional spell ID.
- Validate all types, ranges, and allowed evidence values.
- Deduplicate identical reports, preserve conflicts and provenance.
- An unreviewed report is not verified; do not automatically publish submissions as fact.
- Keep the source catalog and generated Lua output under a documented compatible license; do not copy restricted third-party code or datasets.
- Manual approval first; automate generation and releases after the pipeline has been tested.

## Next implementation steps

- Add SavedVariables discovery queue and event capture from successful tames/pet spellbook, not merely Hunter learning notifications.
- Add /pap Discoveries view with pending entries, review/export and dismissal.
- Build issue template and validator, then a fixture-based integration test.
- Add daily scheduled build that publishes only approved changes and only when the catalog actually changes.
