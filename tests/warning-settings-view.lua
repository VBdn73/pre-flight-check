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
    controls[#controls + 1] = c
    return c
end
ui = { Text = { new = function(parent) return control("text", parent) end },
    Button = { new = function(parent) return control("button", parent) end },
    InputField = { new = function(parent) return control("input", parent) end },
    Hook = { ONBUTTONPRESSED = "press", ONSCROLLWHEEL = "wheel" },
    TextContentVisibilityMode = { VISIBLE = 1 }, InputFieldFilterMode = { NUMBERS_AS_TEXT = 1 } }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { BUTTON_DEFAULT = 1, INPUT_DEFAULT = 2 } }
local tabs
local prettyui = { Tabs = { new = function(host, entries, options)
    tabs = { entries = entries, options = options, pages = {} }
    for i = 1, 4 do
        local page = { content = {}, scrollY = 0, contentHeight = 0 }
        page._scroll = { Refresh = function()
            page.height = math.max(1, host.height - 42)
            page.scrollbarVisible = page.contentHeight > page.height
        end }
        function page:SetContentHeight(h) self.contentHeight = h; self._scroll:Refresh() end
        function page:ScrollBy(delta) self.scrollY = math.max(0, math.min(self.contentHeight - self.height, self.scrollY + delta)) end
        tabs.pages[i] = page
    end
    function tabs:GetPage(i) return self.pages[i] end
    function tabs:Destroy() self.destroyed = true end
    return tabs
end } }
local rules = require("warnings/settings").load()
local host = { width = 400, height = 150 }
local refresh, destroy = require("warnings/settings-view").build(host, rules, function() end, prettyui)
local magic, necro = tabs.pages[1], tabs.pages[2]
assert(tabs.entries[1].text == "Magic" and tabs.entries[2].text == "Necromancy")
assert(tabs.entries[3].text == "Ranged" and tabs.entries[4].text == "Melee")
assert(magic.contentHeight == 36 + 22 * 145 and magic.scrollbarVisible)
assert(necro.contentHeight == 36 + 5 * 145 and necro.scrollbarVisible)
assert(controls[1].parent == magic.content and controls[2].parent == necro.content)
for _, c in ipairs(controls) do
    assert(c.parent ~= tabs.pages[3].content and c.parent ~= tabs.pages[4].content)
    assert(c.content ~= "Deathspore arrows")
end
local lastNecro
for _, c in ipairs(controls) do if c.parent == necro.content then lastNecro = c end end
assert(lastNecro.hidden, "off-screen controls should be hidden")
controls[2].hooks.wheel(nil, 1000)
refresh()
assert(necro.scrollY == necro.contentHeight - necro.height and not lastNecro.hidden)
host.height = 500
refresh()
assert(necro.height == 458 and necro.scrollbarVisible)
destroy()
assert(tabs.destroyed)
print("Warning settings scroll tests passed.")
