# Supply Check

A planned RuneScape plugin for warning when supplies such as runes or ammunition
are running low, potentially when entering a boss arena or loading a preset.

Open the ribbon panel to see loose backpack and equipped supplies separately.
Totals are shown only when both sources are available. Pouch, quiver and other
container contents are excluded. See
[DATA-SOURCES.md](DATA-SOURCES.md) for data-source and panel verification findings.

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
need verification. Nexus contents are included in necromancy warnings, but not
in the loose-item panel totals.

## Quiver diagnostic

The separate `[supply-check] Quiver field probe` looks for Pernix's quiver in
the backpack and worn inventory and attempts to read undocumented slot fields
`legacyvarobj` and `objvar_1` directly or through `slot.vars`. `not exposed`
means the binding did not yield a number, not that the quiver is empty. Compare
with `!listinv inv` or `!listinv worn` on the development server. These fields
are experimental and never used for counts. Mock test: `lua tests/quiver-diagnostic.lua`.

`supply-catalogue.lua` lists item IDs, names and combat-variable bindings. The
panel remains a loose-item view; its totals do not include container contents.

## Experimental warnings

The settings panel uses the required PrettyUI dependency for tabs and scrolling. After
changing the plugin manifest, run `prf` before enabling or reloading the plugin.

The Magic and Necromancy tabs provide individual warning controls for elemental,
catalytic and combination runes, all four necrotic runes and ectoplasm.
Magic tab groups runes into collapsible Elemental, Catalytic and Combination sections.
The Necromancy tab has collapsible Necrotic Runes and Ectoplasm sections.
The Ranged and Melee tabs are empty for now; existing Deathspore arrow warnings still
run using their saved settings. Law runes, blood runes and
Deathspore arrows start enabled; newly added warnings start disabled.
Each has a default low threshold of 100,
critical threshold of 25, low repeat of 300 seconds, critical repeat of 60
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
while the ribbon is closed; unavailable relevant sources suppress warnings.
Entering the critical range can alert immediately even during a low cooldown.
The popup disappears after eight seconds. Cooldowns use client logic ticks and
reset when the game leaves GAME, settings are saved, or the plugin is reloaded.
The tester reports that warnings work in-client; individual settings and timing
cases have not been documented separately. Warning modules live in `warnings/`.
