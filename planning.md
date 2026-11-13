# Planned work and investigations

This is a backlog of ideas and known limitations to investigate, not a promise that the client API supports them or that they will be implemented.
Some items are not currently possible due to API limitations and may depend on future API changes.

## General

- 

## Supply and preparation checks

- Investigate reading specific rune types and quantities in rune pouches for more accurate warnings.
- Investigate reading specific ammunition types and quantities in quivers; current ammunition counts exclude quivers.
- Investigate warnings for Archaeology relics, including checking active relics where available.
- Investigate warnings for the Blessed flask, Grace of the elves and scrimshaws; these warnings are currently unavailable.
- Investigate god book timers for books in the backpack; only equipped books are currently checked.
- Investigate reliable contents attribution when carrying multiple necromancy nexuses or Nodon spike harnesses; the relevant warnings are currently suppressed.
- Investigate more reliable death reclaim detection and independent item durability checks. Current durability warnings depend on English preset-load messages.

## Warning triggers

- Investigate improving preset and bank-close trigger reliability and handling delayed or unavailable data; observed actions do not always confirm a successful preset load.

## Add supply warnings for

- warning when low on health, prayer, adren, sum points -> probably only when entering a boss instance/portal?
- warning when abilities are on cooldown?
- Warning if any sigils are on cooldown: Dragon slayer, demon slayer, ...
- Familiar about to despawn

## Catalogue verification

- Verify the IDs, icons and counts for Elder rune, Bane, Necronium and Orikalkum arrows and bolts in the beta client. The catalogue notes that their icons do not match.
