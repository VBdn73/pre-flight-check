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
