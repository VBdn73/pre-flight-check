local controls = {}
local function control(kind, parent)
    local c = { kind = kind, parent = parent, hooks = {} }
    function c:SetPos(x, y) self.x, self.y = x, y end
    function c:SetSize(w, h) self.width, self.height = w, h end
    function c:Subscribe(hook, id, callback)
        if type(id) == "function" then callback = id end
        self.hooks[hook] = callback
    end
    function c:Setup() end
    function c:SetAssociatedObject(itemId, ...)
        assert(select("#", ...) == 0, "SetAssociatedObject takes one argument")
        self.itemId = itemId
    end
    controls[#controls + 1] = c
    return c
end
ui = { Text = { new = function(parent) return control("text", parent) end },
    Sprite = { new = function(parent) return control("sprite", parent) end },
    Button = { new = function(parent) return control("button", parent) end },
    InputField = { new = function(parent) return control("input", parent) end },
    Hook = { ONBUTTONPRESSED = "press", ONSCROLLWHEEL = "wheel" },
    TextContentVisibilityMode = { VISIBLE = 1 }, InputFieldFilterMode = { NUMBERS_AS_TEXT = 1 } }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { BUTTON_DEFAULT = 1, INPUT_DEFAULT = 2 } }
local tabs
local prettyui = { Tabs = { new = function(host, entries, options)
    tabs = { entries = entries, options = options, pages = {}, active = 1 }
    for i = 1, 4 do
        local page = { content = {}, scrollY = 0, contentHeight = 0, sections = {} }
        page._scroll = { Refresh = function()
            page.height = math.max(1, host.height - 42)
            page.scrollbarVisible = page.contentHeight > page.height
        end }
        function page:SetContentHeight(h) self.contentHeight = h; self._scroll:Refresh() end
        function page:ScrollBy(delta) self.scrollY = math.max(0, math.min(self.contentHeight - self.height, self.scrollY + delta)) end
        function page:reflow()
            local y = 36
            for _, section in ipairs(self.sections) do
                section.root.y = y
                y = y + 20 + (section.expanded and 4 + section.contentHeight or 0) + 8
            end
            self:SetContentHeight(y + 6)
            self.scrollY = math.min(self.scrollY, math.max(0, self.contentHeight - self.height))
        end
        function page:AddCollapseButton(name, opts)
            local section = { name = name, expanded = opts.expanded, root = {},
                content = { y = 24 }, contentHeight = 0 }
            function section:_SetContentHeight(h) self.contentHeight = h; page:reflow() end
            function section:SetExpanded(value)
                self.expanded = value; page:reflow(); opts.onToggle(self, value)
            end
            self.sections[#self.sections + 1] = section
            self:reflow()
            return section
        end
        tabs.pages[i] = page
    end
    function tabs:GetPage(i) return self.pages[i] end
    function tabs:GetActiveIndex() return self.active end
    function tabs:Destroy() self.destroyed = true end
    return tabs
end } }
local saved
PersistentDB = { GetStructuredData = function() return saved end,
    SetStructuredData = function(_, _, data) saved = data; return true end }
local rules = require("warnings/settings").load()
local host = { width = 400, height = 150 }
local refresh, destroy = require("warnings/settings-view").build(host, rules, function() end, prettyui)
local magic, necro = tabs.pages[1], tabs.pages[2]
assert(tabs.entries[1].text == "Magic" and tabs.entries[2].text == "Necromancy")
assert(tabs.entries[3].text == "Ranged" and tabs.entries[4].text == "Melee")
assert(#magic.sections == 3 and magic.sections[1].name == "Elemental"
    and magic.sections[2].name == "Catalytic" and magic.sections[3].name == "Combination")
assert(magic.sections[1].contentHeight == 4 * 105)
assert(magic.sections[2].contentHeight == 12 * 105)
assert(magic.sections[3].contentHeight == 6 * 105)
local fire, law, lava
for _, c in ipairs(controls) do
    if c.content == "Fire rune" then fire = c end
    if c.content == "Law rune" then law = c end
    if c.content == "Lava rune" then lava = c end
end
assert(fire.parent == magic.sections[1].content and law.parent == magic.sections[2].content
    and lava.parent == magic.sections[3].content)
assert(fire.hidden and law.hidden and lava.hidden)
magic.sections[1]:SetExpanded(true)
refresh()
assert(not fire.hidden and law.hidden and lava.hidden and magic.scrollbarVisible)
local fireToggle, fireSave, fireIcon
for _, c in ipairs(controls) do
    if c.parent == fire.parent and c.kind == "sprite" and c.itemId == 554 then fireIcon = c end
    if c.parent == fire.parent and c.kind == "button" and c.y == fire.y - 2 and c.x == 150 then fireToggle = c end
    if c.parent == fire.parent and c.kind == "button" and c.y == fire.y - 2 and c.x == 312 then fireSave = c end
end
assert(fireIcon and not fireIcon.hidden)
fireToggle.hooks.press()
magic.sections[1]:SetExpanded(false)
refresh()
assert(fire.hidden)
assert(fireIcon.hidden)
magic.sections[1]:SetExpanded(true)
refresh()
assert(fireToggle.label == "Enabled", "unsaved edits should survive collapsing")
fireSave.hooks.press()
assert(saved["554"].enabled, "saving a grouped rune should update its original rule")
assert(#necro.sections == 2 and necro.sections[1].name == "Necrotic Runes"
    and necro.sections[2].name == "Ectoplasm")
assert(necro.sections[1].contentHeight == 4 * 105 and necro.sections[2].contentHeight == 105)
local spirit, ectoplasm
for _, c in ipairs(controls) do
    if c.content == "Spirit rune" then spirit = c end
    if c.content == "Ectoplasm" then ectoplasm = c end
end
assert(spirit.parent == necro.sections[1].content and ectoplasm.parent == necro.sections[2].content)
assert(spirit.hidden and ectoplasm.hidden)
assert(controls[1].parent == magic.content and controls[2].parent == necro.content)
local melee = tabs.pages[4]
assert(#melee.sections == 1 and melee.sections[1].name == "Armour Spikes"
    and melee.sections[1].contentHeight == 105)
local spikeLabels, spikeSave, spikeToggle = 0
for _, c in ipairs(controls) do
    assert(c.parent ~= tabs.pages[3].content)
    assert(c.content ~= "Deathspore arrows")
    if c.parent == melee.sections[1].content then
        if c.kind == "sprite" then assert(c.itemId == 59925) end
        if c.content == "Armour spikes" then spikeLabels = spikeLabels + 1 end
        if c.kind == "button" and c.label == "Save" then spikeSave = c end
        if c.kind == "button" and c.label == "Disabled" then spikeToggle = c end
    end
end
assert(spikeLabels == 1 and spikeSave and spikeToggle)
tabs.active = 4
melee.sections[1]:SetExpanded(true)
refresh()
spikeToggle.hooks.press()
spikeSave.hooks.press()
assert(saved["armour-spikes"].enabled and saved["armour-spikes"].low == 1000
    and saved["armour-spikes"].critical == 250)
local lastNecro
for _, c in ipairs(controls) do
    if c.parent == necro.sections[1].content and c.kind == "text" and c.y == 3 * 105 + 79 then lastNecro = c end
end
assert(lastNecro.hidden, "off-screen controls should be hidden")
tabs.active = 2
necro.sections[1]:SetExpanded(true)
refresh()
assert(not spirit.hidden and ectoplasm.hidden and necro.scrollbarVisible)
controls[2].hooks.wheel(nil, 1000)
refresh()
assert(necro.scrollY == necro.contentHeight - necro.height and not lastNecro.hidden)
necro.sections[1]:SetExpanded(false)
necro.sections[2]:SetExpanded(true)
necro:ScrollBy(32)
refresh()
assert(spirit.hidden and not ectoplasm.hidden)
host.height = 500
refresh()
assert(necro.height == 458 and not necro.scrollbarVisible)
destroy()
assert(tabs.destroyed)
print("Warning settings scroll tests passed.")
