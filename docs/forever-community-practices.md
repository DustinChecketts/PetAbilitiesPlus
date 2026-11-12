# WoW Forever addon implementation references (2026-11-12)

This review compares established community approaches; it is not a claim
that PetAbilitiesPlus has been verified in-game.

## Consulted
- [Forever++ API research](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md):
  documents Forever Settings.RegisterCanvasLayoutCategory and
  Settings.RegisterAddOnCategory, the need to hide a Settings canvas before
  its first OnShow, and the distinction between in-game and inferred API
  behavior. **Adopted:** dedicated hidden canvas, normal registration order,
  registration after ADDON_LOADED, and independent fallback window.
- [Wick's Beasts and Things](https://github.com/Wicks-mods/WicksBeastsAndThings):
  independent hunter utility with status diagnostics, slash-command
  fallback, and separate pet-family data. **Adopted concept:** retain
  diagnostics without mixing native pet characteristics into teachable ranks.
- [TrueshotLodge](https://github.com/chazlander/TrueshotLodge):
  documented pet sources and dated verified tame observations, distinct
  known/learnable statuses. **Adopted concept:** retain per-observation
  provenance and do not silently promote unreviewed tame data.
- [Hunter Pet Fieldbook](https://www.curseforge.com/wow/addons/hunter-pet-fieldbook):
  presents family traits separately from ability source browsing.
  **Adopted concept:** only wild-trainable ranks on creature tooltips.
- [Tweaks Forever](https://github.com/cjber/tweaks-forever):
  documented shareable diagnostics and bug-report links. **Future work:**
  polished sanitized export and prefilled issue workflow.

## Deliberate limits
- No third-party addon code or creature database copied into PAP.
  License and data-reuse rights need checking separately.
- No extra dependencies (Ace3, WickCore, etc.) for one checkbox.
- Current Petopia reference policy remains unchanged. Full reconciliation
  against Petopia Forever is still outstanding.
- Existing discovery API uncertainty remains: `C_SpellBook.HasPetSpells`
  may not return a numeric slot count. Do not claim that automatic tame
  capture is reliable until verified in the Forever client.

## Regression checklist
1. Install this branch, `/reload`, open Options > AddOns >
   Pet Abilities Plus. Verify the checkbox is present and defaults off.
2. Toggle diagnostics on; verify `/papdiag verbose off` updates the
   preference and the panel reflects it when reopened.
3. `/pap options` should open the native category if registered, otherwise
   the standalone dialog.
4. Test a full exit/restart as well as `/reload` for SavedVariables
   persistence; historical Forever beta builds had load issues.
5. Target Venomtail Scorpid; verify only Claw Rank 2 and Scorpid Poison
   Rank 1 (if supported by records) appear, without pet commands.
6. With diagnostics off, passive event spam must stop. Manual
   `/papdiag evidence` and `/papdiag deep` must still work.
7. Record any Lua errors, build number, and which settings path worked.
