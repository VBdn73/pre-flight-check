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
for _, control in ipairs(components) do assert(control.clickthrough) end
assert(red.fill and orange.fill and redAccent.fill and orangeAccent.fill)
assert(red.colour[1] > red.colour[2] and orange.colour[2] > red.colour[2])
assert(critical.content == "Law rune: 10" and low.content == "Blood rune: 50")
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
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 110))
local replacement = components[11]
popup.clear()
assert(replacement.destroyed)
print("Warning popup tests passed.")
