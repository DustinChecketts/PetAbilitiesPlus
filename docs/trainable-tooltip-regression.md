# Trainable-only tooltip and diagnostics regression test

Branch: `prototype/community-discovery`. No release/merge approval implied.

## Expected on Venomtail Scorpid (level 10)
- Show **Claw Rank 2** and **Scorpid Poison Rank 1** when supported by the source tables.
- Do **not** show Aggressive, Assist, Attack, Defensive, Follow, Move To, Passive, Stay, or native Faster/Slower Attack passives.
- Source confidence colors remain independent from learned-rank colors.

## In-game checks
1. Reload, hover Venomtail Scorpid. Verify only transferable wild-learned ranks.
2. Target it and run `/papdiag evidence`. Inspect NPC ID, filtered rows, confidence, inherited status, and source types.
3. Run `/papdiag verbose on` for a short Beast Training/tame session, then `/papdiag verbose off`. Normal operation should not flood chat.
4. Open Beast Training, verify hunter-known ranks, reload, and check persistence.
5. Capture a tame, inspect `/pap discoveries` and `/pap discrepancies`. Commands/passives must not appear as ability evidence or public reports, even when old SavedVariables contain them.
6. Verify that unrecognized spells remain available in raw `/pap petprobe` diagnostics, not promoted to verified sources.

## Review notes
- Shared `IsTransferableWildRank` predicate filters all evidence sources and discrepancy exports; historical SavedVariables are not deleted.
- The discovery recorder keeps filtered entries separately for diagnostics.
- Chat event diagnostics were previously always-on; they now require explicit session-only opt-in.
- A newly discovered, unrecognized ability remains raw diagnostic data until cataloged. This prevents false positives but requires manual follow-up.
- No in-game verification or automated Lua test run has been completed yet.
