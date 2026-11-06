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

## Temporary rune-count diagnostic

After `prl supply-check`, the console prints `[supply-check] Supply diagnostic`
when readings change. It compares `GetTotal` for the backpack and worn inventory
with the law and blood combat client variables and Make-X player variables; it
also reports loose Deathspore arrows. These experimental variables are not used
for warnings and may be stale or have a different meaning. Unavailable is not zero.

For a controlled test, use one pouch with a known number of law runes and no
other pouches. Record readings with no loose law runes, add a known loose stack,
move runes into and out of the pouch, and consume some. Repeat with the magic
interface closed and open, and note the action alongside each console reading.
Try equipping the pouch and changing characters or logging out and back in too.
For arrows, compare loose/equipped counts before and after putting arrows in a
quiver; this diagnostic does not read a quiver-specific variable. Mock test:
`lua tests/rune-diagnostic.lua`.

`supply-catalogue.lua` lists exact item IDs and names. Deathspore arrows, blood
runes and law runes have been checked in-client. No container contents are
included.

## Experimental warnings

The settings panel uses the required PrettyUI dependency for scrolling. After
changing the plugin manifest, run `prf` before enabling or reloading the plugin.

The settings icon provides individual warning controls for law runes, blood
runes and Deathspore arrows. Each starts enabled with a low threshold of 100,
critical threshold of 25, low repeat of 300 seconds, critical repeat of 60
seconds, and zero warnings off. Thresholds mean strictly below. Set a repeat
interval from 1 to 86400 seconds, and press Save for each item. Settings are
shared across characters on this client type.

Warnings monitor backpack plus equipment even while the ribbon is closed;
container contents are not counted. Unavailable sources suppress warnings.
Entering the critical range can alert immediately even during a low cooldown.
The popup disappears after eight seconds. Cooldowns use client logic ticks and
reset when the game leaves GAME, settings are saved, or the plugin is reloaded.
The tester reports that warnings work in-client; individual settings and timing
cases have not been documented separately. Warning modules live in `warnings/`.
