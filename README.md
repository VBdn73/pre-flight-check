# Supply Check

A planned RuneScape plugin for warning when supplies such as runes or ammunition
are running low, potentially when entering a boss arena or loading a preset.

Configure supply warnings in the plugin settings; alerts appear as popups.
Popup headings show the total issue count. Popups show up to 8 notifications at once by default, with a scrollbar for longer
lists or when the available screen height is smaller. Set the visible notification
limit (1–20) in General settings.
The ribbon displays the most recent batch of notifications, its issue count, and the client clock time in its heading,
with a scrollbar for longer lists. A new notification replaces the batch;
checks without warnings leave it unchanged. The batch is kept in memory until the
plugin is reloaded. The clock follows the in-game clock's server/local setting;
set it to server time for game time. If the clock cannot be read, it shows unavailable.

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
**preset load** and **bank close**. Preset load defaults on; bank close defaults off. When enabled, these check
configured supply rules after the action. No popup is shown when no enabled supply
is below its threshold.

Preset checks cover bank menu actions, the selected preset's Load button, the
bank chest's Load Last Preset action, and the bank's numbered and beast-of-burden
shortcuts. The detection observes an action or keypress, not confirmation of a
successful load; shortcuts used for other purposes while banking may trigger a
check. Preset checks wait 0.6 seconds before the next server update to allow supply
data to settle; other bank-close checks run on the next server update. Supply data may
still be delayed; unavailable sources remain suppressed. If backpack or equipment
data stays unavailable for five seconds, the check is dropped.
Escape schedules a bank-close check as soon as it is pressed while the main bank
panel is open; it may also check if Escape dismisses something instead of the bank.
Bank preset load actions and shortcuts also schedule that delayed check while the
bank is open, even if the load fails or does not end up closing the bank.

The Magic and Necromancy tabs provide individual warning controls for elemental,
catalytic and combination runes, all four necrotic runes and ectoplasm.
Magic tab groups runes into collapsible Elemental, Catalytic and Combination sections.
The Necromancy tab has collapsible Necrotic Runes and Ectoplasm sections.
The Melee tab provides one Armour Spikes warning for all six variants combined,
and the Ranged tab groups arrows, bolts and chinchompas into collapsible sections, with commonly
used ammunition first. Each ammunition variant has its own warning.
The Misc tab includes vulnerability, poison and sticky bombs, counted in the backpack and equipment,
and an Invention charge pack warning. Charge is read from VarPlayer 5984 (`INVENT_CHARGE`)
and converted to whole charges by dividing by 3,000. Adding a divine charge increased the
raw value by 9,000,000 and the converted value matched the displayed pack charge; ongoing
drain and update timing still need in-client verification. An unavailable variable suppresses
the warning. Thresholds are in pack charges, not divine charge items.
The Misc tab's Other section has an optional Sign of life cooldown warning, on by
default. It reports the shared revive cooldown during the same preset/bank checks,
without a quantity threshold. It reads VarPlayer `DIV_LIFE_COOLDOWN`: a proc was
observed setting it to 30, and a cooldown refresh returned it to 0. If the variable
is unavailable, the warning is suppressed. The notification displays the reported
cooldown in minutes.
Each tab has always-visible style defaults above the item sections for thresholds. Every item
starts enabled and uses its style defaults. Use an item's checkbox to toggle
its warning immediately: green means enabled and red means disabled. Use the
Defaults/Custom button to switch threshold modes; that change is saved immediately.
The fields always show the item's own thresholds, but are read-only in Defaults
mode, when the style thresholds are used. Custom lets you edit the item values.
The two fields are low and critical
thresholds, respectively, and show descriptions on hover. Threshold changes are
saved when you leave a field or press Enter. Invalid values or save failures are
shown beside the fields; correct the values and leave the field to retry.
Only one section per combat style can be open at a time. Ranged sections load
their rows on demand to keep the panel within the client's UI resource limits.
Each tab has a **Restore to defaults** button. Confirm the action to reset only
that tab's settings, including its item overrides; Cancel leaves them unchanged.

Each style starts with a low threshold of 1000 and a critical threshold of 250.
Invention charge instead starts in Custom mode with thresholds of 50,000 low and
10,000 critical; existing saved settings are retained.
Thresholds mean strictly below; zero counts do not trigger warnings.
Settings are shared across characters on this client type. The new settings format
does not import the previous experimental per-item settings.

Rune warnings use the client combat rune counts, without adding loose counts;
law and blood counts were tested with pouches, but the other variables and
effects of combination runes or infinite-rune equipment require in-client tests.
An unavailable rune variable suppresses its warning. Necromancy warnings add
loose backpack and equipped supplies to inventory 953 when exactly one nexus
is carried. Multiple nexuses or an unavailable inventory suppress these warnings;
with no nexus they count loose supplies only. Switching nexuses and inventory
freshness need further in-client testing. Ammunition warnings count
loose backpack plus equipment only, excluding quivers. Unavailable relevant sources
suppress warnings.
The popup shows critical alerts in red and low warnings in orange. Its duration
can be set in the General tab from 1 to 3600 seconds (default: four seconds).
Hovering over a popup keeps it visible after its duration expires; it disappears
when the pointer leaves. The popup captures mouse input while it is visible.
The tester reports that warnings work in-client; individual settings and timing
cases have not been documented separately. Warning modules live in `warnings/`.

Armour spike warnings total all variants in the backpack and equipment, plus
inventory 974 when exactly one Nodon spike harness is carried. No harness means
only loose spikes are counted; multiple harnesses or unavailable sources suppress
the warning. Inventory 974 was observed updating in combat with one worn harness,
and showing its contents in the backpack. Multiple harnesses remain untested.
