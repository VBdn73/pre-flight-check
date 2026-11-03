# Supply Check

A planned RuneScape plugin for warning when supplies such as runes or ammunition
are running low, potentially when entering a boss arena or loading a preset.

The current plugin is a temporary data-source diagnostic. See
[DATA-SOURCES.md](DATA-SOURCES.md) for documented findings and the in-client
verification procedure. It does not yet display supply counts or warnings.

`inventory-reader.lua` provides separate backpack and equipment snapshots for
future features. Each source has `available`; when true, `counts` maps item IDs
to quantities. Missing or malformed slot data makes that source unavailable.
Run the mock tests with `lua tests/inventory-reader.lua`.

`supply-catalogue.lua` lists exact item IDs and names. Deathspore arrows, blood
runes and law runes have been checked in-client. No container contents are
included.
