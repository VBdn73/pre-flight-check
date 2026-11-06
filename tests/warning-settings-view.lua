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
local scroll
local prettyui = { SimpleView = { new = function(host, options)
    scroll = { content = {}, scrollY = 0, width = options.width, height = options.height }
    function scroll:SetSize(w, h) self.width, self.height = w, h end
    function scroll:SetContentHeight(h) self.contentHeight = h; self.scrollbarVisible = h > self.height end
    function scroll:ScrollBy(delta) self.scrollY = math.max(0, math.min(self.contentHeight - self.height, self.scrollY + delta)) end
    function scroll:Destroy() self.destroyed = true end
    return scroll
end } }
local rules = require("warnings/settings").load()
local host = { width = 400, height = 150 }
local refresh, destroy = require("warnings/settings-view").build(host, rules, function() end, prettyui)
assert(scroll.contentHeight == 471 and scroll.scrollbarVisible)
assert(controls[1].parent == scroll.content)
assert(controls[#controls].hidden, "off-screen controls should be hidden")
controls[1].hooks.wheel(nil, 10)
refresh()
assert(scroll.scrollY == 320 and not controls[#controls].hidden)
host.height = 500
refresh()
assert(scroll.height == 500 and not scroll.scrollbarVisible)
destroy()
assert(scroll.destroyed)
print("Warning settings scroll tests passed.")
