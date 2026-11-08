local controls, views = {}, {}
local function control(kind, parent)
    local item = { kind = kind, parent = parent, hooks = {} }
    function item:SetPos(x, y) self.x, self.y = x, y end
    function item:SetSize(w, h) self.width, self.height = w, h end
    function item:Subscribe(hook, _, callback) self.hooks[hook] = callback end
    function item:Destroy() self.destroyed = true end
    controls[#controls + 1] = item
    return item
end
local gameClock = "09:42"
ui = { Text = { new = function(parent) return control("text", parent) end },
    Rectangle = { new = function(parent) return control("rectangle", parent) end },
    Interfaces = { GetComponent = function(_, component) assert(component == 123); return { content = gameClock } end },
    AlignMode = { CENTRE = 1 }, Hook = { ONSCROLLWHEEL = "wheel" } }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, Component = { TOPLEVEL_V2_MINIMAP__CLOCK_TEXT = 123 } }
Vector4 = { new = function(...) return { ... } end }
config = { Font = { FromID = function() return { GetStringWidth = function(_, text) return #text * 6 end } end } }
local prettyui = { SimpleView = { new = function(_, options)
    local view = { content = {}, scrollY = 0, contentHeight = 0 }
    function view:SetSize(w, h)
        self.width, self.height = w, h
        self.scrollbarVisible = self.contentHeight > h
        self.contentWidth = w - (self.scrollbarVisible and 18 or 0)
    end
    function view:SetContentHeight(h) self.contentHeight = h; self:SetSize(self.width, self.height) end
    function view:SetScrollPosition(y) self.scrollY = math.max(0, math.min(y, math.max(0, self.contentHeight - self.height))) end
    function view:ScrollBy(y) self:SetScrollPosition(self.scrollY + y) end
    function view:Destroy() self.destroyed = true end
    view:SetSize(options.width, options.height)
    views[#views + 1] = view
    return view
end } }
local ribbon = require("warnings/ribbon")
-- Record a batch, scroll through it, and resize the panel.
local parent = { width = 250, height = 144 }
ribbon.open(parent, prettyui)
assert(controls[1].content == "Last notifications (0)")
local alerts = {}
for i = 1, 7 do alerts[i] = { name = "Rune", count = i, level = "low" } end
ribbon.record(alerts, 12)
assert(controls[1].content == "Last notifications (7): 09:42")
assert(views[1].scrollbarVisible and views[1].contentHeight == 252)
assert(controls[4].content == "Rune: 1")
assert(controls[2].colour[2] == 0.20 and controls[3].colour[2] == 0.58)
controls[4].hooks.wheel(nil, 1)
ribbon.update()
assert(controls[4].content == "Rune: 2")
views[1]:SetScrollPosition(10)
ribbon.update()
assert(not controls[4].hidden and not controls[13].hidden, "partially visible rows remain rendered")
views[1]:SetScrollPosition(10000)
ribbon.update()
assert(controls[10].content == "Rune: 7" and not controls[10].hidden, "last alert can be reached")
parent.height = 216
ribbon.update()
assert(views[1].height == 180, "view follows panel size")
-- Replacing a batch resets scrolling and updates the presentation.
ribbon.record({ { message = "Sign of life: 3 min", level = "critical" } }, 20)
assert(controls[1].content == "Last notifications (1): 09:42")
assert(views[1].scrollY == 0 and not views[1].scrollbarVisible)
assert(controls[4].content == "Sign of life: 3 min" and controls[7].hidden)
assert(controls[2].colour[2] == 0.08 and controls[3].colour[2] == 0.25)
-- Long labels reflow without hiding subsequent alerts.
local longName = "Augmented custom-fit trimmed spiked masterwork melee platebody"
ribbon.record({ { name = longName, level = "critical", status = "MISSING" },
    { name = "Rune", count = 2, level = "low" } })
assert(controls[2].height > 32 and controls[5].y == controls[2].height + 4, "long rows grow without overlapping the next row")
local pieces = {}
for _, item in ipairs(controls) do
    if item.kind == "text" and item.parent == views[1].content and not item.hidden
        and item.y < controls[5].y then pieces[#pieces + 1] = item end
end
table.sort(pieces, function(a, b) return a.y < b.y end)
local lines = {}
for _, item in ipairs(pieces) do lines[#lines + 1] = item.content end
assert(table.concat(lines, " ") == longName .. " - MISSING", "all label text and status remain visible")
local wideHeight = controls[2].height
parent.width, parent.height = 140, 120
ribbon.update()
assert(controls[2].height > wideHeight and views[1].scrollbarVisible, "narrower panels reflow and scroll")
views[1]:SetScrollPosition(10000)
ribbon.update()
local foundLast = false
for _, item in ipairs(controls) do
    if item.content == "Rune: 2" and not item.hidden then foundLast = true end
end
assert(foundLast, "scrolling reaches the row after a long label")
-- Reopening retains the batch; a missing game clock has a fallback.
parent.width, parent.height = 250, 216
ribbon.record({ { message = "Sign of life: 3 min", level = "critical" } })
ribbon.close()
assert(views[1].destroyed and controls[1].destroyed)
controls = {}
ribbon.open(parent, prettyui)
assert(controls[4].content == "Sign of life: 3 min", "reopening retains the batch")
gameClock = ""
ribbon.record({ { name = "Rune", count = 1, level = "low" } })
assert(controls[1].content == "Last notifications (1): unavailable")
gameClock = "10:15"
ribbon.record({})
assert(controls[1].content == "Last notifications (0): 10:15", "clean checks update the ribbon timestamp")
assert(controls[4].hidden and views[2].contentHeight == 0, "clean checks hide old warning rows")
print("Warning ribbon tests passed.")
