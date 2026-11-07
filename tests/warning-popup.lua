local components = {}
local parent = {}
local function new(kind, host)
    local control = { kind = kind, parent = host }
    function control:SetPos(...) self.pos = { ... } end
    function control:SetSize(...) self.size = { ... } end
    function control:SetHeaderLayout() end
    function control:Destroy() self.destroyed = true end
    components[#components + 1] = control
    return control
end
ui = { Interfaces = { GetComponent = function() return parent end },
    AlignMode = { CENTRE = 1, BOTTOMRIGHT = 2 },
    GroupBox = { new = function(host) return new("group", host) end },
    Rectangle = { new = function(host) return new("rectangle", host) end },
    Text = { new = function(host) return new("text", host) end } }
id = { Component = { TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP = 1 },
    StyleSheet = { DEFAULT = 1 }, Font = { MUSEO_SANS_15PT_REGULAR = 1, MUSEO_SANS_11PT_REGULAR = 2 } }
Vector4 = { new = function(r, g, b, a) return { r, g, b, a } end }

local popup = require("warnings/popup")
assert(popup.show({ { name = "Law rune", count = 10, level = "critical" },
    { name = "Blood rune", count = 50, level = "low" } }, 100))
local root, title, red, redAccent, critical, criticalSeverity, orange, orangeAccent, low, lowSeverity = table.unpack(components)
assert(root.clickthrough == false)
for i = 2, #components do assert(components[i].clickthrough) end
assert(red.fill and orange.fill and redAccent.fill and orangeAccent.fill)
assert(red.colour[1] > red.colour[2] and orange.colour[2] > red.colour[2])
assert(critical.content == "Law runes: 10" and low.content == "Blood runes: 50")
assert(criticalSeverity.content == "CRITICAL" and lowSeverity.content == "LOW")
for _, label in ipairs({ critical, low, criticalSeverity, lowSeverity }) do
    assert(label.alignVertical == ui.AlignMode.CENTRE and label.size[2] == 32)
end
for _, severity in ipairs({ criticalSeverity, lowSeverity }) do
    assert(severity.alignHorizontal == ui.AlignMode.BOTTOMRIGHT)
    assert(severity.pos[1] + severity.size[1] == red.pos[1] + red.size[1] - 7)
end
assert(red.parent == root and critical.parent == root and orange.parent == root and low.parent == root)
assert(red.pos[2] ~= orange.pos[2])
popup.update(103.9)
assert(not root.destroyed)
popup.update(104)
assert(root.destroyed)
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 110, 12))
local replacement = components[11]
popup.update(121.9)
assert(not replacement.destroyed)
popup.update(122)
assert(replacement.destroyed)
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 130, 2))
local hovered = components[17]
hovered.isMouseOver = true
popup.update(132)
assert(not hovered.destroyed)
popup.update(140)
assert(not hovered.destroyed)
hovered.isMouseOver = false
popup.update(140.1)
assert(hovered.destroyed)
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 150, 5))
local leftEarly = components[23]
leftEarly.isMouseOver = true
popup.update(151)
leftEarly.isMouseOver = false
popup.update(152)
assert(not leftEarly.destroyed)
popup.update(155)
assert(leftEarly.destroyed)
popup.clear()
assert(replacement.destroyed)
local cases = {
    { "Fire rune", 1, "Fire rune: 1" }, { "Fire rune", 100, "Fire runes: 100" },
    { "Ectoplasm", 10, "Ectoplasm: 10" }, { "Ruby bolts (e)", 1, "Ruby bolt (e): 1" },
    { "Ruby bolts (e)", 10, "Ruby bolts (e): 10" }, { "Havensilver bolt +1", 10, "Havensilver bolts +1: 10" },
    { "Armour spikes", 1, "Armour spike: 1" }, { "Chinchompa", 10, "Chinchompas: 10" },
    { "Invention charge", 10, "Invention charges: 10" },
    { "Invention charge", 999, "Invention charges: 999" },
    { "Invention charge", 1000, "Invention charges: 1,000" },
    { "Invention charge", 1234567, "Invention charges: 1,234,567" },
}
for _, case in ipairs(cases) do
    local start = #components
    assert(popup.show({ { name = case[1], count = case[2], level = "low" } }, 200))
    assert(components[start + 5].content == case[3])
end
local start = #components
assert(popup.show({ { message = "Cooldown: 1000 minutes", level = "low" } }, 200))
assert(components[start + 5].content == "Cooldown: 1000 minutes")
popup.clear()
print("Warning popup tests passed.")
