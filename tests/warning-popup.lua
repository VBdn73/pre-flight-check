local components, handles = {}, {}
local parent = { xyGlobal = { x = 0, y = 0 } }
local savedPosition
PersistentDB = {
    GetStructuredData = function() return savedPosition end,
    SetStructuredData = function(_, _, value) savedPosition = value; return true end,
}
local function new(kind, host)
    local control = { kind = kind, parent = host }
    function control:SetPos(...) self.pos = { ... }; self.xyGlobal = { x = self.pos[1], y = self.pos[2] } end
    function control:SetSize(...) self.size = { ... } end
    function control:SetHeaderLayout() end
    function control:Subscribe(hook, name, callback) self.hooks = self.hooks or {}; self.hooks[hook] = callback or name end
    function control:Destroy() self.destroyed = true end
    function control:MoveToFront() end
    components[#components + 1] = control
    return control
end
ui = { Interfaces = { GetComponent = function() return parent end },
    AlignMode = { CENTRE = 1, BOTTOMRIGHT = 2 }, Hook = { ONSCROLLWHEEL = "wheel",
        ONCLICK = "click", ONHOLD = "hold", ONRELEASE = "release", ONDRAGCOMPLETE = "dragComplete", ONBUTTONPRESSED = "pressed" },
    GroupBox = { new = function(host) return new("group", host) end },
    Layer = { new = function(host)
        local item = new("layer", host)
        components[#components] = nil
        handles[#handles + 1] = item
        return item
    end },
    Button = { new = function(host) return new("button", host) end },
    Rectangle = { new = function(host) return new("rectangle", host) end },
    Text = { new = function(host) return new("text", host) end } }
id = { Component = { TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP = 1 },
    StyleSheet = { DEFAULT = 1, BUTTON_DEFAULT = 2 }, Font = { MUSEO_SANS_15PT_REGULAR = 1, MUSEO_SANS_11PT_REGULAR = 2 } }
Vector4 = { new = function(r, g, b, a) return { r, g, b, a } end }
config = { Font = { FromID = function() return { GetStringWidth = function(_, text) return #text * 6 end } end } }

local popup = require("warnings/popup")
-- Colours, rows, and default expiry.
local customBackground, customAccent = popup.colours("low", { lowColour = "#0080FF" })
assert(customAccent[1] == 0 and customAccent[2] == 128 / 255 and customAccent[3] == 1)
assert(customBackground[3] == 0.36)
local _, defaultCritical = popup.colours("critical", { lowColour = "#0080FF" })
assert(defaultCritical[1] == 0.95 and defaultCritical[2] == 0.25)
assert(popup.show({ { name = "Law rune", count = 10, level = "critical" },
    { name = "Blood rune", count = 50, level = "low" } }, 100))
local root, title, red, redAccent, critical, criticalSeverity, orange, orangeAccent, low, lowSeverity = table.unpack(components)
assert(title.content == "Pre flight check (2)")
assert(root.clickthrough == false)
assert(title.clickthrough and not handles[1].clickthrough)
for i = 3, 10 do assert(components[i].clickthrough) end
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
title.isMouseOver = true
popup.update(104)
assert(not root.destroyed, "hovering the title keeps the popup open")
title.isMouseOver = false
popup.update(103.9)
assert(not root.destroyed)
popup.update(104)
assert(root.destroyed)
-- Custom duration and hover behavior.
local start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 110, 12))
local replacement = components[start + 1]
popup.update(121.9)
assert(not replacement.destroyed)
popup.update(122)
assert(replacement.destroyed)
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 130, 2))
local hovered = components[start + 1]
hovered.isMouseOver = true
popup.update(132)
assert(not hovered.destroyed)
popup.update(140)
assert(not hovered.destroyed)
hovered.isMouseOver = false
popup.update(140.1)
assert(hovered.destroyed)
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "critical" } }, 150, 5))
local leftEarly = components[start + 1]
leftEarly.isMouseOver = true
popup.update(151)
leftEarly.isMouseOver = false
popup.update(152)
assert(not leftEarly.destroyed)
popup.update(155)
assert(leftEarly.destroyed)
popup.clear()
assert(replacement.destroyed)
-- Quantity labels, message labels, and long names.
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
start = #components
assert(popup.show({ { message = "Cooldown: 1000 minutes", level = "low" } }, 200))
assert(components[start + 5].content == "Cooldown: 1000 minutes")
popup.clear()
for _, case in ipairs({ { "Powder of penance", "critical", "MISSING" },
    { "Ectoplasm", "low", "LOW" }, { "Perfect plus potion (1)", "low", "DOSE" } }) do
    start = #components
    assert(popup.show({ { name = case[1], message = "Long original message", level = case[2], status = case[3] } }, 200))
    assert(components[start + 5].content == case[1] and components[start + 6].content == case[3])
end
popup.clear()
start = #components
assert(popup.show({ { name = "Augmented custom-fit trimmed spiked masterwork platebody", level = "critical", status = "MISSING" } }, 200))
local longLabel, secondLine, longSeverity = components[start + 5], components[start + 6], components[start + 7]
assert(longLabel.content .. " " .. secondLine.content == "Augmented custom-fit trimmed spiked masterwork platebody")
assert(#longLabel.content * 6 <= longLabel.size[1] and #secondLine.content * 6 <= secondLine.size[1])
assert(secondLine.pos[2] > longLabel.pos[2] and components[start + 3].size[2] > 32)
assert(longSeverity.content == "MISSING" and longLabel.pos[1] + longLabel.size[1] <= longSeverity.pos[1])
popup.clear()
-- Scrolling, configurable row limits, and small screens.
local views = {}
local prettyui = { SimpleView = { new = function(host, options)
    local view = { parent = host, content = {}, width = options.width, height = options.height, scrollY = 0 }
    for _, key in ipairs({ "root", "viewport", "upArrow", "downArrow", "track", "trackTop",
        "trackCentre", "trackBottom", "thumbDrag" }) do view[key] = {} end
    function view:SetContentHeight(height)
        self.contentHeight = height
        self.scrollbarVisible = height > self.height
        self.contentWidth = self.width - (self.scrollbarVisible and 18 or 0)
    end
    function view:ScrollBy(delta) self.scrollY = math.max(0, math.min(self.contentHeight - self.height, self.scrollY + delta)) end
    function view:Destroy() self.destroyed = true end
    views[#views + 1] = view
    return view
end } }
local alerts = {}
for i = 1, 11 do alerts[i] = { name = "Rune", count = i, level = "low" } end
parent.height = 140
start = #components
assert(popup.show({ { name = string.rep("wideword ", 20), level = "critical", status = "MISSING" } }, 200, 4, prettyui))
assert(views[1].scrollbarVisible and views[1].contentHeight > views[1].height, "a tall row scrolls on a small screen")
assert(components[start + 5].parent == views[1].content and components[start + 5].hooks.wheel)
popup.clear()
parent.height = nil
views = {}
start = #components
assert(popup.show({ table.unpack(alerts, 1, 8) }, 200, 4, prettyui))
assert(components[start + 1].size[2] == 330 and #views == 0, "eight rows need no scrollbar by default")
start = #components
assert(popup.show({ table.unpack(alerts, 1, 9) }, 200, 4, prettyui))
assert(components[start + 1].size[2] == 330 and views[1].scrollbarVisible)
popup.clear()
views = {}
start = #components
assert(popup.show({ table.unpack(alerts, 1, 10) }, 200, 4, prettyui, 10))
assert(components[start + 1].size[2] == 402 and #views == 0, "ten rows need no scrollbar")
start = #components
assert(popup.show(alerts, 200, 4, prettyui, 10))
local view = views[1]
assert(components[start + 2].content == "Pre flight check (11)", "title counts all alerts, not just visible rows")
assert(components[start + 1].size[2] == 402 and view.height == 360)
assert(view.scrollbarVisible and view.contentHeight == 396)
assert(components[start + 5].parent == view.content)
components[start + 5].hooks.wheel(nil, 1)
assert(view.scrollY == 36 and components[start + 45].content == "Rune: 11")
local scrollingRoot, scrollingLabel = components[start + 1], components[start + 5]
for _, target in ipairs({ scrollingLabel, view.content, view.viewport, view.root, view.upArrow,
    view.downArrow, view.track, view.trackTop, view.trackCentre, view.trackBottom, view.thumbDrag }) do
    target.isMouseOver = true
    popup.update(204)
    assert(not scrollingRoot.destroyed, "hovering a scroll control keeps the popup open")
    target.isMouseOver = false
end
view.dragStart = {}
popup.update(204)
assert(not scrollingRoot.destroyed, "dragging the scrollbar keeps the popup open")
view.dragStart = nil
popup.update(204)
assert(scrollingRoot.destroyed, "popup closes after the pointer leaves")
assert(view.destroyed)
parent.height = 250
assert(popup.show({ table.unpack(alerts, 1, 10) }, 200, 4, prettyui))
assert(views[2].height == 163 and views[2].scrollbarVisible, "small screens limit popup height")
popup.clear()
-- Dragging, saved positions, display scaling, and screen bounds.
parent.width, parent.height = 800, 600
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 300))
local draggable, handle = components[start + 1], handles[#handles]
draggable.xyGlobal = { x = 230, y = 45 }
local mouse = { x = 260, y = 61 }
Mouse = { GetPosition = function() return mouse end }
handle.hooks.click(handle, 20, 10)
assert(handle.pos[1] == 0 and handle.size[3] == 1, "drag captures the whole parent")
popup.update(305)
assert(not draggable.destroyed, "dragging keeps the popup open")
mouse = { x = 360, y = 111 }
handle.hooks.hold(handle, 120, 60)
assert(draggable.pos[1] == 330 and draggable.pos[2] == 95)
mouse = { x = 660, y = 311 }
handle.hooks.hold(handle, 420, 260)
assert(draggable.pos[1] == 460 and draggable.pos[2] == 295, "fast drags remain captured and clamped")
handle.hooks.release()
assert(savedPosition.x == 460 and savedPosition.y == 295)
assert(handle.size[1] == 225 and handle.pos[1] == 470, "release restores the handle")
popup.clear()
assert(handle.destroyed, "popup cleanup destroys the sibling handle")
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 310))
assert(components[start + 1].pos[1] == 460 and components[start + 1].pos[2] == 295)
local scaledRoot, scaledHandle = components[start + 1], handles[#handles]
mouse = { x = (460 + 10 + 20) * 2, y = (295 + 6 + 10) * 2 }
scaledHandle.hooks.click(scaledHandle, 20, 10)
mouse = { x = mouse.x - 100, y = mouse.y - 80 }
scaledHandle.hooks.hold(scaledHandle, -30, -30)
assert(scaledRoot.pos[1] == 410 and scaledRoot.pos[2] == 255, "drag accounts for display scaling")
scaledHandle.hooks.release()
popup.clear()
parent.width, parent.height = 400, 150
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 320))
assert(components[#components - 7].pos[1] == 60 and components[#components - 7].pos[2] == 72,
    "saved positions are clamped to the available screen")
popup.clear()
-- Pinning, closing, and replacement notifications.
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 400, 4))
local pinnedRoot, pin, pinLabel = components[start + 1], components[start + 7], components[start + 8]
assert(pinLabel.content == "Keep open")
pin.hooks.pressed()
assert(pinLabel.content == "Close")
popup.update(500)
assert(not pinnedRoot.destroyed, "pinned popup remains open after expiry")
pinnedRoot.isMouseOver = true
pin.hooks.pressed()
assert(pinnedRoot.destroyed, "closing a pinned popup ignores hover")
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 510, 100))
components[start + 7].hooks.pressed()
components[start + 7].hooks.pressed()
assert(components[start + 1].destroyed, "closing a pinned popup ignores remaining duration")
start = #components
assert(popup.show({ { name = "Law rune", count = 1, level = "low" } }, 520))
components[start + 7].hooks.pressed()
assert(popup.show({ { name = "Blood rune", count = 1, level = "low" } }, 530))
local nextRoot = components[start + 9]
popup.update(534)
assert(nextRoot.destroyed, "replacement notifications are not pinned")
print("Warning popup tests passed.")
