-- Panel and dropdown order is the order of these lists. Setting metadata lives
-- here, not in the rendering code. Catalogue-backed groups retain rule order.
local panels = {
    { name = "Magic", usage = "Rune counts include combat rune sources.", dropdowns = {
        { name = "Elemental" }, { name = "Catalytic" }, { name = "Combination" },
    } },
    { name = "Necromancy", usage = "Counts include loose supplies and the nexus.", dropdowns = {
        { name = "Necrotic Runes" },
    }, settings = { { itemId = 55336 } }, settingsFirst = true },
    { name = "Ranged", usage = "Quivers unreadable; only loose supplies count.", dropdowns = {
        { name = "Elder God Arrows", lazy = true }, { name = "Special Arrows", lazy = true },
        { name = "Enchanted Bakriminel Bolts", lazy = true }, { name = "Chinchompas", lazy = true },
    }, settings = {
        { name = "Cannonballs", icon = 2 }, { name = "Arrows", icon = 882 },
        { name = "Bolts", icon = 877 }, { name = "Gem Bolts", icon = 879 },
        { name = "Bakriminel Bolts", icon = 24116 }, { name = "Enchanted Gem Bolts", icon = 9236 },
    } },
    { name = "Melee", usage = "Counts include loose spikes and one harness.", dropdowns = {},
        settings = { { itemId = require("supplies/armour-spikes").ruleId } } },
    { name = "Misc", usage = "Counts include supplies in the backpack and equipment.", dropdowns = {
        { name = "Bombs" }, { name = "Invention" }, { name = "God Books",
            usage = "Only equipped books are checked; backpack timers are unavailable.", settings = {
                { itemId = 51814 }, { itemId = 52117 }, { itemId = 52347 },
                { itemId = 52494 }, { itemId = 57126 }, { itemId = 57526 },
                { itemId = 42787 }, { itemId = 61425 },
            } },
    }, settings = {
        { key = "signOfLife", name = "Sign of life cooldown", icon = 29290 },
        { key = "deathReclaim", name = "Death reclaim", icon = 39559 },
        { key = "itemDurability", name = "Item durability", icon = 2347,
            usage = "Reports charge warnings from preset chat.<br><br>Requires:<br>- Check on preset load<br>- Preset chat notifications<br>- Chat access permission" },
        { key = "beastOfBurden", name = "Beast of burden preset", icon = { sprite = 13216 },
            usage = "Warns if your follower cannot carry the preset's items.<br><br>Requires:<br>- Check on preset load<br>- Preset chat notifications<br>- Chat access permission" },
        { key = "excalibur", name = "Excalibur cooldown", icon = 14632 },
        { key = "powerburst", name = "Powerburst cooldown", icon = 49095 },
        { itemId = 22370 }, { itemId = 22371 }, { itemId = 40407 },
        { name = "Blessed flask", icon = 48680, unavailable = true },
        { name = "Grace of the elves", icon = 44548, unavailable = true },
        { name = "Scrimshaw", icon = 26295, unavailable = true },
    } },
}

local settings = require("warnings/settings")
panels.general = { toggles = {
    { key = "checkOnPreset", name = "Check on preset load" },
    { key = "presetChatNotifications", name = "Preset chat notifications", indent = 15,
        usage = "Reads preset withdrawal messages for notifications.<br><br>Requires:<br>- Check on preset load<br>- Chat access permission" },
    { key = "checkOnBankClose", name = "Check on bank close" },
    { key = "checkOnPortalEntry", name = "Check on War's Retreat portal entry",
        usage = "Checks supplies after detected travel through either attuned portal, the reaper portal or the featured portal. Independent of preset and bank checks. Uses a location-jump heuristic, not boss-instance detection." },
    { key = "showCheckButton", name = "Show on-screen check button",
        usage = "Keeps a Check now button on screen. Click to check, or hold and drag the button to move it; the position is saved. Runs your enabled supply checks independently of automatic triggers." },
    { key = "popupIconMode", name = "Compact notification icons",
        usage = "Shows coloured warning icons with hover details in the main popup only. The ribbon is unchanged." },
}, colours = {
    { key = "lowColour", name = "Low warning colour", default = "#FF9429" },
    { key = "criticalColour", name = "Critical warning colour", default = "#F24033" },
}, numbers = {
    { key = "popupDuration", name = "Notification duration (seconds)",
        usage = "How long notifications remain visible, from 1 to 3600 seconds",
        validate = settings.validDuration, invalid = "Invalid (1-3600)" },
    { key = "popupRows", name = "Visible notifications",
        usage = "Maximum visible notifications in the popup, from 1 to 20. In icon mode this limits tiles before scrolling (rounded up to a full row).",
        validate = settings.validPopupRows, invalid = "Invalid (1-20)" },
} }

return panels
