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
            local y = options.contentLayout.startY
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
local host = { width = 400, height = 600 }
local refresh, destroy = require("warnings/settings-view").build(host, rules, function() end, prettyui)
local magic, necro, ranged, melee = table.unpack(tabs.pages)
assert(tabs.entries[1].text == "Magic" and tabs.entries[4].text == "Melee")
assert(magic.sections[1].name == "Elemental" and magic.sections[2].name == "Catalytic")
assert(necro.sections[1].name == "Necrotic Runes" and ranged.sections[1].name == "Ammunition")
assert(melee.sections[1].name == "Armour Spikes")
local function find(parent, kind, x, y)
    for _, c in ipairs(controls) do
        if c.parent == parent and c.kind == kind and c.x == x and c.y == y then return c end
    end
    error("control not found: " .. kind .. " " .. x .. "," .. y)
end
local style = magic.content
assert(not find(style, "input", 10, 87).hidden)
assert(find(style, "text", 10, 40).content == "Magic defaults")
find(style, "input", 10, 87).content = "5000"
find(style, "button", 312, 39).hooks.press()
assert(saved.styles.Magic.low == 5000 and rules.styles.Magic.low == 5000)
host.height = 600
magic.sections[1]:SetExpanded(true)
refresh()
local fire = magic.sections[1].content
local override = find(fire, "button", 227, 3)
local customLow = find(fire, "input", 10, 51)
local inherited = find(fire, "text", 10, 43)
assert(override.label == "Style" and customLow.hidden and not inherited.hidden)
assert(inherited.content:find("5000", 1, true))
override.hooks.press()
refresh()
assert(not customLow.hidden and inherited.hidden)
customLow.content = "7000"
find(fire, "button", 312, 3).hooks.press()
assert(saved["554"].custom and saved["554"].low == 7000)
override.hooks.press()
find(fire, "button", 312, 3).hooks.press()
assert(not saved["554"].custom and saved["554"].low == 7000)
override.hooks.press()
refresh()
assert(customLow.content == "7000")
local enabled = find(fire, "button", 150, 3)
enabled.hooks.press()
find(fire, "button", 312, 3).hooks.press()
assert(not saved["554"].enabled)
tabs.active = 3
ranged.sections[1]:SetExpanded(true)
refresh()
local arrow = ranged.sections[1].content
assert(find(arrow, "sprite", 10, 0).itemId == 52299)
assert(not find(arrow, "button", 227, 3).hidden)
tabs.active = 4
melee.sections[1]:SetExpanded(true)
refresh()
assert(find(melee.sections[1].content, "sprite", 10, 0).itemId == 59925)
destroy()
assert(tabs.destroyed)
print("Warning settings view tests passed.")
