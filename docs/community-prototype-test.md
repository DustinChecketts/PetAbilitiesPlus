# Community discovery prototype test plan

Branch: `prototype/community-discovery`. This is a beta diagnostic, not an
automatic publishing pipeline. No submissions or web requests occur in WoW.

1. Install the branch, enable the addon, and `/reload`.
2. With an existing pet summoned, run `/pap petprobe` **without opening the spellbook**.
   Run `/pap discoveries` and verify readable spell names/ranks appear.
3. Dismiss/stable your pet as normal, target a wild beast, and channel Tame Beast.
   The chat should say `Observing Tame Beast`. Let the tame complete.
4. A new pet with readable spells should produce `New pet discovery`. Run
   `/pap discoveries`, select all, and copy the output for review.
5. Interrupt a tame: it must not create a completed record. If no new pet
   appears within 35 seconds, the pending observation expires.
6. Repeat the same creature type at a different location/level. The record
   should merge levels/coordinates, not erase prior abilities.
7. Test tooltips on a community-reported creature, an existing verified
   creature, and a locally discovered creature.

The automatic detection listens for spell ID 1515 and pet/spellbook events.
Some Forever beta builds may suppress or redact these events or spellbook
results. The raw `/pap petprobe` output helps distinguish these failures.
`/pap discover` and `/pap capture` remain available as manual fallbacks.

Confidence: green = verified, blue = attributed community report, grey =
unreviewed local capture/lead. Checkmarks do not indicate Hunter training
knowledge; existing learned/unlearned colors remain separate.

The original spreadsheet provides 21 ability assertions, 10 explicit
"no ability" reports and 3 uninspected creatures (one name was normalized
from "Vulgren Alpha" to "Vuldren Alpha"). Reports are not silently promoted
to verified. The underlying source is
https://forums.wow-petopia.com/viewtopic.php?t=27358 .
