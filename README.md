# Supply Check

A planned RuneScape plugin for warning when supplies such as runes or ammunition
are running low, potentially when entering a boss arena or loading a preset.

Configure supply warnings in the plugin settings; alerts appear as popups.

**Development limitation:** In testing, the client disabled this local plugin
when returning to the lobby. After logging in, use `pon supply-check` to enable
it again. Whether an installed plugin behaves the same way is not yet verified.

`inventory-reader.lua` provides separate backpack and equipment snapshots for
future features. Each source has `available`; when true, `counts` maps item IDs
to quantities. Missing or malformed slot data makes that source unavailable.
Run the mock tests with `lua tests/inventory-reader.lua`.

## Container data findings

In-client testing found that `COMBATV2_RUNECOUNT_LAW` and
`COMBATV2_RUNECOUNT_BLOOD` tracked loose and pouched runes together when runes
were moved or consumed. Their exact semantics and freshness are not documented.
Make-X rune-count variables remained zero in that test.

Inventory 953 (`NECROMANCY_NEXUS`) exposed ectoplasm and all four necrotic
runes through the inventory API, updating after additions and spell consumption.
Availability and freshness across logout and switching multiple nexuses still
need verification. Nexus contents are included in necromancy warnings.

## Quiver diagnostic

The separate `[supply-check] Quiver field probe` looks for Pernix's quiver in
the backpack and worn inventory and attempts to read undocumented slot fields
`legacyvarobj` and `objvar_1` directly or through `slot.vars`. `not exposed`
means the binding did not yield a number, not that the quiver is empty. Compare
with `!listinv inv` or `!listinv worn` on the development server. These fields
are experimental and never used for counts. Mock test: `lua tests/quiver-diagnostic.lua`.

`supply-catalogue.lua` lists item IDs, names and combat-variable bindings.

## Experimental warnings

The settings panel uses the required PrettyUI dependency for tabs and scrolling. After
changing the plugin manifest, run `prf` before enabling or reloading the plugin.

The Magic and Necromancy tabs provide individual warning controls for elemental,
catalytic and combination runes, all four necrotic runes and ectoplasm.
Magic tab groups runes into collapsible Elemental, Catalytic and Combination sections.
The Necromancy tab has collapsible Necrotic Runes and Ectoplasm sections.
The Melee tab provides one Armour Spikes warning for all six variants combined.
The Ranged tab is empty for now; existing Deathspore arrow warnings still
run using their saved settings. Law runes, blood runes and
Deathspore arrows start enabled; newly added warnings start disabled.
All have a default low threshold of 1000 and critical threshold of 250. Existing
saved settings are preserved. All use a low repeat of 300 seconds, critical repeat of 60
seconds, and zero warnings off. Thresholds mean strictly below. Set a repeat
interval from 1 to 86400 seconds, and press Save for each item. Settings are
shared across characters on this client type.

Rune warnings use the client combat rune counts, without adding loose counts;
law and blood counts were tested with pouches, but the other variables and
effects of combination runes or infinite-rune equipment require in-client tests.
An unavailable rune variable suppresses its warning. Necromancy warnings add
loose backpack and equipped supplies to inventory 953 when exactly one nexus
is carried. Multiple nexuses or an unavailable inventory suppress these warnings;
with no nexus they count loose supplies only. Switching nexuses and inventory
freshness need further in-client testing. Deathspore warnings count
loose backpack plus equipment only, excluding quivers. Monitoring continues
without a ribbon panel; unavailable relevant sources suppress warnings.
Entering the critical range can alert immediately even during a low cooldown.
The popup shows critical alerts in red and low warnings in orange, and disappears
after eight seconds. Cooldowns use client logic ticks and
reset when the game leaves GAME, settings are saved, or the plugin is reloaded.
The tester reports that warnings work in-client; individual settings and timing
cases have not been documented separately. Warning modules live in `warnings/`.

Armour spike warnings total all variants in the backpack and equipment, plus
inventory 974 when exactly one Nodon spike harness is carried. No harness means
only loose spikes are counted; multiple harnesses or unavailable sources suppress
the warning. Inventory 974 was observed updating in combat with one worn harness,
and showing its contents in the backpack. Multiple harnesses remain untested.
