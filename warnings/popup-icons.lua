-- Compact popup presentation only; ribbon formatting is deliberately independent.
local icons = {}
local named = { ["Death reclaim"] = 39559, ["Sign of life"] = 29290,
    Excalibur = 14632, Powerburst = 49095, ["Beast of burden preset"] = { sprite = 13216 } }
local byName

function icons.source(alert)
    if alert.itemId then
        local spikes = require("supplies/armour-spikes")
        return alert.itemId == spikes.ruleId and spikes.itemIds[1] or alert.itemId
    end
    if named[alert.name] then return named[alert.name] end
    if not byName then
        byName = {}
        for itemId, item in pairs(require("supplies/catalogue")) do byName[item.name] = itemId end
    end
    return byName[alert.name] or (alert.status and alert.status:match("^%d+%%$") and 2347 or nil)
end

function icons.description(alert, formatAlert)
    local detail = alert.message or formatAlert(alert)
    if alert.name and not detail:find(alert.name, 1, true) then detail = alert.name .. ": " .. detail end
    return detail .. "\n" .. (alert.status or (alert.level == "critical" and "CRITICAL" or "LOW"))
end

function icons.layout(count, width, maxVisible)
    local columns = math.max(1, math.floor((width + 4) / 46))
    local total = math.ceil(count / columns) * 46
    local visible = math.min(total, math.ceil((maxVisible or 8) / columns) * 46)
    return columns, total, visible
end

function icons.draw(context, alert, index, columns)
    local x = context.x + ((index - 1) % columns) * 46
    local y = context.y + math.floor((index - 1) / columns) * 46
    local tile = ui.Rectangle.new(context.parent)
    tile:SetPos(x, y); tile:SetSize(42, 42)
    tile.fill, tile.colour, tile.clickthrough = true, context.background, false
    local source = icons.source(alert)
    local image
    if source then
        image = ui.Sprite.new(context.parent)
        -- Optical correction for padding within the item artwork.
        image:SetPos(x + 6, y + 5); image:SetSize(32, 32)
        if type(source) == "table" then image.sprite = source.sprite else image:SetAssociatedObject(source) end
    else
        -- The native EXCLAMATION_MARK is a legacy red graphic, not a neutral warning glyph.
        image = ui.Text.new(context.parent)
        image:SetPos(x, y); image:SetSize(42, 39)
        image.font = id.Font.MUSEO_SANS_15PT_REGULAR
        image.alignHorizontal, image.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        image.colour = context.accent
        image.content = "!"
    end
    image.clickthrough = true
    local accent = ui.Rectangle.new(context.parent)
    accent:SetPos(x, y + 39); accent:SetSize(42, 3)
    accent.fill, accent.colour, accent.clickthrough = true, context.accent, true
    local tip
    tile:Subscribe(ui.Hook.ONMOUSEOVER, "supplyCheck.iconTooltipPosition", function()
        if tip then
            local origin, parentOrigin = tile.xyGlobal, context.overlay.xyGlobal
            if origin and parentOrigin then
                local tx, ty = origin.x - parentOrigin.x, origin.y - parentOrigin.y
                tip.options.x = math.max(0, math.min(tx, math.max(0, (context.overlay.width or 340) - tip.width)))
                tip.options.y = math.max(0, ty >= tip.height + 6 and ty - tip.height - 6
                    or math.min(ty + 44, math.max(0, (context.overlay.height or 600) - tip.height)))
            end
        end
        return true
    end)
    tip = context.prettyui.Tooltip.attach(tile, context.overlay, {
        text = icons.description(alert, context.formatAlert):gsub("&", "&amp;"):gsub("<", "&lt;")
            :gsub(">", "&gt;"):gsub("\n", "<br>"), placement = "above", constrainToParent = false,
    })
    context.tooltips[#context.tooltips + 1] = tip
    context.hoverTargets[#context.hoverTargets + 1] = tile
    if tip.root then context.hoverTargets[#context.hoverTargets + 1] = tip.root end
    if context.scroll then
        tile:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.iconScroll", function(_, delta)
            context.scroll:ScrollBy(delta * 46)
            tip:Hide()
            return false
        end)
    end
end

return icons
