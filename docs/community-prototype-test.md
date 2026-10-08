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


## Version-aware provenance test (October 2026)

1. Reload with the latest `prototype/community-discovery` files.
2. Hover a known Classic creature (e.g. Deepmoss Creeper). Its inherited
   ability should be blue and marked `Community / Classic inherited`.
3. Hover a Forever community-report creature (e.g. Vuldren Alpha).
   Its reported Trickster's Dance Rank 1 should be blue and marked
   `Community / forever` unless stronger evidence exists.
4. Hover Daggerfang (NPC 270693). Its Bite Rank 2 should be green and
   marked `Verified / forever`, reflecting the existing reviewed override.
5. Capture a previously unknown pet using the discovery recorder. A new
   candidate ability should appear grey, marked `Lead / forever`.
6. Confirm learned/unlearned coloring remains independent of confidence.
7. Confirm Classic Screech displays as Demoralizing Screech in Forever
   wherever the compatibility naming layer applies.

Markers are ASCII `[+]` for verified/community and `[?]` for leads,
with explicit labels and color; no special glyph/font dependency.

**Known limitations:** source URLs, contributor names, and dates are
preserved in records where available but not yet shown in tooltip detail.
Classic identity and full NPC-ID coverage are still incomplete. Current
lookup uses name fallback for historical records; ambiguous names require
NPC-ID resolution. Forever suppression/field override operations are
documented but not yet enforced by the evidence resolver. The client has
not yet been tested with these changes.
