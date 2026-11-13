# Changelog

## 0.0.2 - 2026-11-13

### Added

- Added **Vitals** under Misc with configurable percentage thresholds for health, adrenaline, prayer points, summoning points and familiar special-move points. Summoning and familiar special-move points have separate toggles and thresholds; familiar special-move warnings are off by default.
- Added Excalibur and powerburst cooldown warnings.
- Added **Sigil ability cooldowns** under Misc: one toggle for sigil cooldown warnings, naming each affected ability and showing remaining seconds. Enabled by default.
- Added supply checks for regular and meteorite cannonballs under Ranged, and empty ushabti under Misc.
- Added **Beast of burden preset** warnings when a follower cannot carry preset items. Enabled by default; requires preset-load checks, preset chat notifications and chat access permission.
- Added optional supply checks after detected travel through War's Retreat's two attuned portals, reaper portal and featured portal. Enable **Check on War's Retreat portal entry** in General. Checks are independent of preset and bank-close settings.
- Added an optional on-screen **Check now** button to run enabled supply checks independently of automatic triggers, with a saved draggable position, an optional position lock, and native hover and click feedback.
- Added optional **Compact notification icons** for the main popup, with warning colours and hover details. The ribbon remains unchanged.

### Changed

- Moved Sign of life cooldown into **Misc → Vitals** and displayed miscellaneous standalone settings directly under Misc instead of an Other dropdown.
- Combined illuminated god books and their non-illuminated variants into shared warning settings that support either equipped variant.
- Improved settings descriptions and tooltips, with tooltips allocated on first hover instead of eagerly for every setting.
- Refactored settings into shared panel and component definitions, with reusable visible rows for large ranged sections, shared field validation and scroll handling.
- Refactored supply counting, vitals, constants and overlay positioning into shared modules, and expanded and reorganized mocked regression tests.

### Fixed

- Portal checks preserve pending travel through interface confirmation dialogs, including God Wars Dungeon teleport warnings, without checking before travel is detected.
- Fixed settings-window crashes caused by eager tooltip allocation and added diagnostic logging for settings refresh errors.
- Fixed settings flickering while scrolling and restored scrolling when hovering toggleable General options.
- Disabling **Check on preset load** now disables the **Preset chat notifications** control without clearing its saved preference.
- Warning rows without a separate label now use the full row width instead of reserving an empty label column.

## 0.0.1 - 2026-11-08

- Added supply checks on preset loads and optionally when closing the bank, covering runes, necromancy supplies, ammunition, armour spikes, consumables, Invention charge and god book time.
- Added warnings for death reclaim items and Sign of life cooldown, plus optional preset chat notifications for withdrawal issues and low item durability.
- Added combat-style tabs with per-item toggles, default or custom low and critical thresholds, and per-page resets.
- Added configurable warning colours and a draggable popup with adjustable duration, visible rows, keep-open and close controls. The ribbon shows the latest warning batch.
