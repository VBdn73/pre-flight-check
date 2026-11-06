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

The **General** tab has separate, immediately saved switches for checking on
**preset load** and **bank close**. Both default off. When enabled, these check
configured supply rules after the action. No popup is shown when no enabled supply
is below its threshold.

Preset checks cover bank menu actions, the selected preset's Load button, the
bank chest's Load Last Preset action, and the bank's numbered and beast-of-burden
shortcuts. The detection observes an action or keypress, not confirmation of a
successful load; shortcuts used for other purposes while banking may trigger a
check. Preset checks run on the next server update; bank-close checks wait at least
1.2 seconds and for a server update. Supply data may not yet be fresh, particularly
for preset checks; unavailable sources remain suppressed. If backpack or equipment
data stays unavailable for five seconds, the check is dropped.

The Magic and Necromancy tabs provide individual warning controls for elemental,
catalytic and combination runes, all four necrotic runes and ectoplasm.
Magic tab groups runes into collapsible Elemental, Catalytic and Combination sections.
The Necromancy tab has collapsible Necrotic Runes and Ectoplasm sections.
The Melee tab provides one Armour Spikes warning for all six variants combined,
and the Ranged tab provides a Deathspore arrow warning. Each tab has always-visible
style defaults above the item sections for thresholds and zero warnings. Every item
starts enabled and uses its style defaults. Use the eye icon to control that
warning independently, or the pencil icon to switch between Style and Custom.
Inherited fields show the style values but cannot be edited. Switching back
retains the custom values for later use. Use the Save button after changing either
the style defaults or an individual item; hover over icons for their functions.

Each style starts with a low threshold of 1000, critical threshold of 250, and zero
warnings off. Thresholds mean strictly below.
Settings are shared across characters on this client type. The new settings format
does not import the previous experimental per-item settings.

Rune warnings use the client combat rune counts, without adding loose counts;
law and blood counts were tested with pouches, but the other variables and
effects of combination runes or infinite-rune equipment require in-client tests.
An unavailable rune variable suppresses its warning. Necromancy warnings add
loose backpack and equipped supplies to inventory 953 when exactly one nexus
is carried. Multiple nexuses or an unavailable inventory suppress these warnings;
with no nexus they count loose supplies only. Switching nexuses and inventory
freshness need further in-client testing. Deathspore warnings count
loose backpack plus equipment only, excluding quivers. Unavailable relevant sources
suppress warnings.
The popup shows critical alerts in red and low warnings in orange, and disappears
after four seconds.
The tester reports that warnings work in-client; individual settings and timing
cases have not been documented separately. Warning modules live in `warnings/`.

Armour spike warnings total all variants in the backpack and equipment, plus
inventory 974 when exactly one Nodon spike harness is carried. No harness means
only loose spikes are counted; multiple harnesses or unavailable sources suppress
the warning. Inventory 974 was observed updating in combat with one worn harness,
and showing its contents in the backpack. Multiple harnesses remain untested.
