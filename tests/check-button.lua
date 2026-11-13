local components, saved, checks = {}, nil, 0
local parent = { width = 800, height = 600, xyGlobal = { x = 0, y = 0 } }
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value)
        assert(key == "supplyWarnings.checkButtonPosition")
        saved = value; return true
    end,
}
local function new(host)
    local control = { parent = host, hooks = {} }
    function control:SetPos(x, y) self.xyGlobal = { x = x, y = y } end
    function control:SetSize(...) self.size = { ... } end
    function control:MoveToFront() end
    function control:Destroy() self.destroyed = true end
    function control:Subscribe(hook, name, callback) self.hooks[hook] = callback or name end
    components[#components + 1] = control
    return control
end
ui = { Interfaces = { GetComponent = function() return parent end },
    Layer = { new = new }, Button = { new = new }, Text = { new = new },
    AlignMode = { CENTRE = 1 }, Hook = { ONBUTTONPRESSED = "press", ONCLICK = "click",
        ONHOLD = "hold", ONRELEASE = "release", ONDRAGCOMPLETE = "complete" } }
id = { Component = { TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP = 1 },
    StyleSheet = { BUTTON_DEFAULT = 1 }, Font = { MUSEO_SANS_11PT_REGULAR = 1 } }
local button = require("warnings/check-button")
local function check() checks = checks + 1 end
button.update(false, check)
assert(#components == 0)
button.update(true, check)
assert(#components == 4)
local root, control, handle = components[1], components[2], components[4]
assert(handle.size[1] == 36 and handle.size[2] == 36, "whole square button is draggable")
handle.hooks.click(nil, 50, 14)
assert(checks == 0, "wait for release before checking")
handle.hooks.hold(nil, 71, 115) -- One-pixel jitter is still a click.
handle.hooks.release()
handle.hooks.complete()
assert(checks == 1)
handle.hooks.click(nil, 5, 5)
handle.hooks.hold(nil, 225, 255)
handle.hooks.release()
assert(saved.x == 220 and saved.y == 250 and checks == 1, "dragging must not run a check")
button.update(true, check)
assert(#components == 4, "reuse controls")
button.close()
assert(root.destroyed and handle.destroyed)
button.update(true, check)
assert(components[5].xyGlobal.x == 220 and components[5].xyGlobal.y == 250)
parent.width, parent.height = 20, 20
button.update(true, check)
assert(components[5].xyGlobal.x == 0 and components[5].xyGlobal.y == 0)
button.update(false, check)
assert(components[5].destroyed and components[8].destroyed)
saved = { x = 0 / 0, y = 100 }
parent.width, parent.height = 800, 600
button.update(true, check)
assert(components[9].xyGlobal.x == 20, "invalid positions use defaults")
button.close()
-- Global positions may be scaled/offset: never feed them back into SetPos.
local originalNew = ui.Layer.new
ui.Layer.new = function(host)
    local item = originalNew(host)
    function item:SetPos(x, y) self.xyGlobal = { x = x * 2 + 40, y = y * 2 + 60 } end
    return item
end
saved = { x = 100, y = 120 }
local start = #components
button.update(true, check)
local scaledRoot, scaledHandle = components[start + 1], components[start + 4]
for _ = 1, 100 do button.update(true, check) end
assert(scaledRoot.xyGlobal.x == 240 and scaledRoot.xyGlobal.y == 300, "updates must not cause global-coordinate drift")
-- Raw mouse motion is converted once using interface scale.
game = { options = { InterfaceScale = { setting = "200" } } }
local mouse = { x = 250, y = 310 }
Mouse = { GetPosition = function() return mouse end }
scaledHandle.hooks.click(nil, 5, 5)
mouse = { x = 330, y = 370 }
scaledHandle.hooks.hold(nil, 0, 0)
scaledHandle.hooks.release()
assert(saved.x == 140 and saved.y == 150, "scaled dragging follows mouse deltas")
for _ = 1, 100 do button.update(true, check) end
assert(scaledRoot.xyGlobal.x == 320 and scaledRoot.xyGlobal.y == 360)
button.close()
print("Check button tests passed.")
