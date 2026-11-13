# Pre flight check

Warnings about low supplies and preparation issues when loading a bank preset, closing the bank or checking manually. Optional checks also run after War's Retreat portal travel. This development version requires Jagex moderation before distribution; approval is not implied.

## Features

- Checks runes, necromancy supplies, ammunition, armour spikes, selected consumables, Invention charge and equipped god book time.
- Warns about death reclaim items and Sign of life, Excalibur, powerburst and sigil ability cooldowns.
- Optional preset chat warnings report missing, insufficient or substituted items, beast of burden preset failures and game-reported low durability.
- Shows warnings in a popup and ribbon panel. Customise thresholds, colours, duration and text or compact-icon display. A clean check clears old warnings.
- Does not load presets or perform game actions for you.

## How to use

1. Install **PrettyUI** (mod.io ID `6398181`), the required dependency, and enable the plugin.
2. Open the plugin settings. Preset-load checks are on by default; enable bank-close checks in **General** if wanted.
3. Use the combat-style tabs to enable or disable warnings and set default or custom low and critical thresholds. Quantity warnings trigger strictly below the threshold; zero counts are ignored except for Invention charge and equipped god book time.
4. Load a preset or close the bank to check. Drag the popup heading to move it, choose **Keep open** while resupplying, or **Close** to dismiss it. The ribbon shows the most recent batch.

### Optional settings

- **General → Preset chat notifications:** enable and grant chat access for preset messages. Under **Misc → Other**, **Beast of burden preset** is on by default; enable **Item durability** for low-durability messages.
- **General → Show on-screen check button:** adds a **Check now** button. Drag to move it; **Lock check button position** prevents movement without disabling checks. Manual checks do not generate preset-chat warnings.
- **General → Compact notification icons:** replaces popup text with coloured icons and hover details on the next notification. **Visible notifications** sets the scroll limit, rounded up to a full row. The ribbon is unchanged.
- **General → Check on War's Retreat portal entry:** checks after detected travel through either attuned portal, the reaper portal or the featured portal. Independent of bank checks; no chat permission needed.
- **Misc → Other → Sigil ability cooldowns:** one toggle for Aggression, Ingenuity of the Humans, the four Slayer sigils, Limitless, Slayer's Insight, Slayer's Aggression and Vital Drain. Enabled by default; warnings show remaining seconds.

The check button, position lock, compact icons and portal checks are off by default.

## Limitations

- Ammunition counts exclude quivers.
- Necromancy nexus and Nodon spike harness contents are counted only when exactly one corresponding container is carried; multiple containers suppress the relevant warnings.
- The death reclaim warning is not a guarantee that no items are awaiting reclaim. Blessed flask, Grace of the elves and scrimshaw warnings are unavailable. Durability warnings depend on English game messages during preset loading, not an independent durability check.
- Portal checks infer travel from a location jump near a selected portal, not boss-instance entry. An unrelated nearby teleport can match. Attempts expire after 30 seconds or another selected world action; unavailable inventory data is retried for up to five seconds after arrival.

See [changelog.md](changelog.md) for release notes and [planning.md](planning.md) for planned work and investigations.

## Feedback and collaboration

Report bugs or propose contributions through the repository's issue tracker or email [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com). Include reproduction steps and your client version; avoid posting personal information publicly.

For new warnings, include the exact item name and any relevant game message, setup and reproduction steps.

## Permissions

**Optional `chatAccess`:** reads preset withdrawal and low-charge messages for the optional notifications above. Supply checks work without it. No other permissions are requested.

## Data protection

**Case 1 (local only):** The plugin reads inventory, equipment, relevant game variables, portal interactions and player location for checks, plus preset-related chat when enabled and permitted. Settings and popup/check-button positions are stored locally using `PersistentDB`, shared across characters on the same client type. The latest warnings remain in memory until replaced or the plugin reloads. No data is transmitted to the developer or external services by this plugin.

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

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
