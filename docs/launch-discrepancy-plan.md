# Launch preparation and discrepancy review

## Source policy

Classic creature and ability mappings are the historical baseline. Petopia Forever
is the preferred, trusted published Forever reference, attributed to Petopia.
Do not imply that the current bundled Classic/community tables are an exact
Petopia Forever import. The Petopia Forever ability list has not yet been
fully ingested or cross-checked; its redistribution terms must be reviewed.
An observed difference from an imported source becomes a **lead**, not a
correction or a claim that Petopia is wrong. A reviewed observation can
promote a specific versioned assertion to verified. Preserve dates/builds.

## Implemented for offline launch preparation

- `/pap discoveries`: inspect and select all local tame candidates and
  discrepancy reports; share manually if desired.
- `/pap discrepancies`: opens the same export view and identifies candidate
  deviations from the *PAP bundled baseline*, not Petopia directly.
- New post-tame positive abilities absent from the bundled baseline are
  queued by NPC ID + ability + rank in SavedVariables, with observation
  count, build, and evidence. No negative inference from missing abilities.
- No data is transmitted by the addon. The export deliberately omits player
  name and account identifiers. Players should review it before posting.
- Future public queue: GitHub Issues, with a human-review template and
  duplicate checks. Issue creation is not automated.

## Launch test sequence (blocked until servers reopen)

1. Confirm addon loads without Lua errors; open `/pap`.
2. Open Beast Training; check learned ranks and reload persistence.
3. Tame a beast with a documented ability; inspect `/pap discoveries`.
4. Tame a beast with an ability not in PAP's baseline; verify one candidate
   entry appears under `/pap discrepancies` and survives reload.
5. Verify a missing spell does not create a false negative discrepancy.
6. Verify existing green/blue/grey tooltip markers and Screech naming.
7. Check pet passives and rank parsing; note that spellbook API availability
   and return values are not yet confirmed on launch client.
8. Only after testing, reconcile Petopia-specific source mappings and
   independently reviewed October balance notes.

## Known gaps

The complete Classic NPC-ID catalog and Petopia Forever import are not
finished. Client-specific balance numbers are not asserted as verified.
A public Issues template and an in-game browser-opening action are not
yet implemented. The current discrepancy queue only identifies *new
positive ability observations* relative to PAP's bundled records; it
cannot prove that Petopia differs. No beta/launch client test has occurred.
