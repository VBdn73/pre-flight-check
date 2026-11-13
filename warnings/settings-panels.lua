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
            usage = "Requires preset checks, preset chat notifications, and chat access permission. Reports charge warnings from preset chat." },
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
        usage = "Read preset withdrawal messages for notifications. Requires chat access permission and preset checks." },
    { key = "checkOnBankClose", name = "Check on bank close" },
}, colours = {
    { key = "lowColour", name = "Low warning colour", default = "#FF9429" },
    { key = "criticalColour", name = "Critical warning colour", default = "#F24033" },
}, numbers = {
    { key = "popupDuration", name = "Notification duration (seconds)",
        usage = "How long notifications remain visible, from 1 to 3600 seconds",
        validate = settings.validDuration, invalid = "Invalid (1-3600)" },
    { key = "popupRows", name = "Visible notifications",
        usage = "Maximum visible notifications in the popup, from 1 to 20",
        validate = settings.validPopupRows, invalid = "Invalid (1-20)" },
} }

return panels
