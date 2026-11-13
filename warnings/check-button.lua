-- Persistent, optional manual-check control on the game's overlay layer.
local button = {}
local root, handle, host, drag, skin
local positionX, positionY
local moveDrag, locked
local width, height = 36, 36
local positionKey = "supplyWarnings.checkButtonPosition"
local overlayPosition = require("warnings/overlay-position")

local valid = overlayPosition.valid

local function clamp(x, y)
    return overlayPosition.clamp(x, y, host, width, height)
end

local function placeHandle()
    handle:SetPos(positionX, positionY)
    handle:SetSize(width, height)
    handle:MoveToFront()
    root:MoveToFront() -- Click-through label layer stays above the native button.
end

local function mousePosition()
    local ok, value = pcall(function() return Mouse.GetPosition() end)
    -- Client vectors can be userdata, unlike the tables stored in PersistentDB.
    if ok and value and type(value.x) == "number" and type(value.y) == "number" then return value end
end

function button.close()
    drag = nil
    moveDrag = nil
    if handle then pcall(function() handle:Destroy() end) end
    if root then pcall(function() root:Destroy() end) end
    skin = nil
    root, handle, host = nil, nil, nil
    positionX, positionY = nil, nil
end

function button.update(enabled, onCheck, lockPosition)
    locked = lockPosition == true
    if not enabled then button.close(); return end
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then button.close(); return end
    if root and host == parent then
        skin.rgba = drag and 0xAAAAAAFF or (handle.isMouseOver and 0xFFFFFFFF or 0xCCCCCCFF)
        if drag and moveDrag and drag.raw then
            -- Hold events can be sparse during fast motion. Follow the raw
            -- cursor on every plugin update as well, using the same delta logic.
            moveDrag(nil, drag.x, drag.y)
        end
        if not drag then
            positionX, positionY = clamp(positionX, positionY)
            root:SetPos(positionX, positionY)
            placeHandle()
        end
        return
    end
    button.close()
    host = parent
    local ok, err = pcall(function()
        root = ui.Layer.new(host)
        root:SetSize(width, height)
        root.clickthrough = true
        local loaded, position = pcall(function() return PersistentDB:GetStructuredData(positionKey) end)
        if not loaded or not valid(position) then position = { x = 20, y = 100 } end
        positionX, positionY = clamp(position.x, position.y)
        root:SetPos(positionX, positionY)
        skin = ui.Button.new(root)
        skin:SetPos(0, 0)
        skin:SetSize(width, height)
        skin.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        skin.clickthrough = true
        skin.rgba = 0xCCCCCCFF
        handle = ui.Layer.new(host)
        handle.clickthrough = false
        placeHandle()
        local caption
        local function label(x, w, text)
            local item = ui.Text.new(root)
            caption = item
            item:SetPos(x, 0); item:SetSize(w, height)
            item.font = id.Font.MUSEO_SANS_11PT_REGULAR
            item.alignHorizontal, item.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
            item.clickthrough = true
            item.content = text
        end
        label(0, width, "PFC")
        handle:Subscribe(ui.Hook.ONCLICK, "supplyCheck.buttonDragStart", function(_, x, y)
            if type(x) ~= "number" or type(y) ~= "number" then return false end
            local raw = mousePosition()
            local scale = (game and game.options and game.options.InterfaceScale
                and tonumber(game.options.InterfaceScale.setting) or 100) / 100
            if scale <= 0 then scale = 1 end
            drag = { x = positionX + x, y = positionY + y, rootX = positionX,
                rootY = positionY, raw = raw, scale = scale }
            -- Capture fast motion outside the button without stretching its skin.
            handle:SetPos(0, 0)
            handle:SetSize(0, 0, 1, 1)
            handle:MoveToFront()
            skin.rgba = 0xAAAAAAFF
            return false
        end)
        local function move(_, x, y)
            if locked then return false end
            if not drag or type(x) ~= "number" or type(y) ~= "number" then return false end
            local raw = mousePosition()
            local dx, dy = x - drag.x, y - drag.y
            if raw and drag.raw then dx, dy = (raw.x - drag.raw.x) / drag.scale, (raw.y - drag.raw.y) / drag.scale end
            -- Ignore small hand movements on a normal click.
            if not drag.moved and dx * dx + dy * dy < 16 then return false end
            drag.moved = true
            drag.lastX, drag.lastY = clamp(math.floor(drag.rootX + dx + 0.5), math.floor(drag.rootY + dy + 0.5))
            positionX, positionY = drag.lastX, drag.lastY
            root:SetPos(positionX, positionY)
            return false
        end
        moveDrag = move
        root:Subscribe(ui.Hook.ONHOLD, "supplyCheck.buttonDragCapture", move)
        handle:Subscribe(ui.Hook.ONHOLD, "supplyCheck.buttonDragMove", function(_, x, y)
            return move(nil, x, y)
        end)
        local function finish()
            local clicked = drag and not drag.moved
            if drag and drag.moved then
                local saved, result = pcall(function()
                    return PersistentDB:SetStructuredData(positionKey, { x = drag.lastX, y = drag.lastY })
                end)
                if not saved or result ~= true then print("[pre-flight-check] Could not save check button position") end
            end
            drag = nil
            root.clickthrough = true
            root:SetPos(positionX, positionY)
            root:SetSize(width, height)
            caption:SetPos(0, 0)
            skin.rgba = 0xCCCCCCFF
            placeHandle()
            if clicked then onCheck() end
            return false
        end
        handle:Subscribe(ui.Hook.ONRELEASE, "supplyCheck.buttonDragEnd", finish)
        handle:Subscribe(ui.Hook.ONDRAGCOMPLETE, "supplyCheck.buttonDragComplete", finish)
        root:Subscribe(ui.Hook.ONRELEASE, "supplyCheck.buttonCaptureEnd", finish)
        root:Subscribe(ui.Hook.ONDRAGCOMPLETE, "supplyCheck.buttonCaptureComplete", finish)
    end)
    if not ok then
        button.close()
        print("[pre-flight-check] Check button creation failed: " .. tostring(err))
    end
end

return button
