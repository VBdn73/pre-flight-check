# Pre flight check

Get warnings about low supplies and other preparation issues when loading a bank preset or closing the bank. This development version requires Jagex moderation before distribution; approval is not implied.

## Features

- Checks runes, necromancy supplies, ammunition, armour spikes, selected consumables, Invention charge and equipped god book time.
- Warns about death reclaim items and the Sign of life, Excalibur and powerburst cooldowns (toggles under **Misc → Other**). Optional preset chat notifications report missing, insufficient or substituted items, beast of burden preset failures when the follower cannot carry items, and game-reported low item durability.
- Shows a popup and keeps the latest check's warnings in the ribbon panel. A clean check clears the popup and shows zero notifications. Adjust thresholds, colours, popup duration and visible rows in plugin settings.
- Does not load presets or perform game actions for you.

## How to use

1. Install **PrettyUI** (mod.io ID `6398181`), the required dependency, and enable the plugin.
2. Open the plugin settings. Preset-load checks are on by default; enable bank-close checks in **General** if wanted.
3. Use the combat-style tabs to enable or disable warnings and set default or custom low and critical thresholds. Quantity warnings trigger strictly below the threshold; zero counts are ignored except for Invention charge and equipped god book time.
4. Load a preset or close the bank to check. Drag the popup heading to move it, choose **Keep open** while resupplying, or **Close** to dismiss it. The ribbon shows the most recent batch.

To receive preset withdrawal messages, enable **Preset chat notifications** in General and grant optional chat access. For game-reported low durability messages, also enable **Item durability** under Misc → Other.

Enable **General → Compact notification icons** to replace the main popup's text list with coloured warning icons and hover details. This is off by default and does not affect the ribbon. **Visible notifications** limits the icon tiles before scrolling, rounded up to a complete row. Warning colours, dragging, duration, and **Keep open / Close** work in either display mode. The display choice applies to the next notification.
**Beast of burden preset** under Misc → Other reports preset failures when the follower cannot carry items. This warning is on by default and requires the same preset chat settings and permission.

## Limitations

- Ammunition counts exclude quivers.
- Necromancy nexus and Nodon spike harness contents are counted only when exactly one corresponding container is carried; multiple containers suppress the relevant warnings.
- The death reclaim warning is not a guarantee that no items are awaiting reclaim. Blessed flask, Grace of the elves and scrimshaw warnings are unavailable. Durability warnings depend on English game messages during preset loading, not an independent durability check.

See [changelog.md](changelog.md) for release notes and [planning.md](planning.md) for planned work and investigations.

## Permissions and data protection

**Optional `chatAccess`:** reads preset withdrawal and low-charge messages for the optional notifications above. Supply checks work without it. No other permissions are requested.

**Data protection — Case 1 (local only):** The plugin reads inventory, equipment, relevant game variables and, if enabled and permitted, preset-related chat messages to produce warnings. Settings and popup position are stored locally using `PersistentDB`, shared across characters on the same client type. The latest warning batch is held in memory until replaced or the plugin reloads. Data is not transmitted to the developer or external services by this plugin.

Settings have no automatic expiry. Tab resets restore defaults; disabling the plugin does not erase stored data. There is no full-data deletion control, and uninstalling should not be assumed to clear the client database. The developer cannot access or delete local data remotely.

## Local development

Follow the [RuneScape API getting-started guide](https://developer.runescape.com/rs/getting-started.html). Place the repository in `RuneScape-BETA/dev_plugins/pre-flight-check/` and install PrettyUI. In the client console (**Alt + `**), run:

```text
prf
pon pre-flight-check
```

After Lua changes, use `prl pre-flight-check`; after manifest changes, run `prf` first. Run individual mocked tests with Lua 5.4, for example `lua tests/warning-integration.lua`. Also test in-client; mocked tests do not verify client behavior.

Run the whole mocked suite from PowerShell (each file runs in a separate Lua process):

```powershell
Get-ChildItem tests/*.lua | ForEach-Object { lua $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Failed: $($_.Name)" } }
```

Before submission, review the [plugin guidelines](https://developer.runescape.com/rs/submission/guidelines.html) and [submission process](https://developer.runescape.com/rs/submission/process.html). Required description sections must also appear in the mod.io listing.

### Settings UI definitions

Edit `warnings/settings-panels.lua` to arrange supply panels. `dropdowns` and
`settings` are ordered lists; row heights and shared styling are handled by
`warnings/settings-components.lua`, not repeated for each setting. For example:

```lua
{ key = "signOfLife", name = "Sign of life cooldown", icon = 29290,
    usage = "Optional tooltip describing this warning" }
```

Use `itemId` for a quantity setting backed by an existing warning rule, `key`
for a boolean setting, or `unavailable = true` for an informational row.
Catalogue-backed dropdowns populate automatically. Their optional `settings`
list specifies leading item order and can override `name` and `icon`; remaining
items follow in rule order. For example:

```lua
{ name = "God Books", usage = "Only equipped books are checked.", settings = {
    { itemId = 51814 },
    { itemId = 52117, name = "Scripture of Wen", icon = 52117 },
} }
```

Definitions configure presentation, not new warning behaviour: new warning
types still need their rules and evaluation logic. Saving, validation, reset,
scroll clipping and ranged dropdown virtualization remain in the view.

## Feedback and collaboration

Report bugs or propose contributions through the repository's issue tracker, or email [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and your client version; avoid posting personal information publicly.

To request a new warning setting, include the exact in-game item name. If it relies on a game message, include the message text and the in-game setup and steps needed to reproduce it.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
