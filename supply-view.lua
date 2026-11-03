local catalogue = require("supply-catalogue")
local view = {}

function view.format(snapshot)
    local lines = { "Loose supplies only.", "Pouches, quivers and other containers excluded.", "" }
    local ids = {}
    for itemId in pairs(catalogue) do ids[#ids + 1] = itemId end
    table.sort(ids)
    for _, itemId in ipairs(ids) do
        local backpack = snapshot.backpack.available and (snapshot.backpack.counts[itemId] or 0)
        local equipment = snapshot.equipment.available and (snapshot.equipment.counts[itemId] or 0)
        local name = catalogue[itemId].name:gsub("<", "["):gsub(">", "]")
        lines[#lines + 1] = name
        lines[#lines + 1] = "Backpack: " .. (backpack and tostring(backpack) or "unavailable")
            .. " | Equipment: " .. (equipment and tostring(equipment) or "unavailable")
        lines[#lines + 1] = "Total: " .. (backpack and equipment and tostring(backpack + equipment) or "unavailable")
        lines[#lines + 1] = ""
    end
    return table.concat(lines, "<br>")
end

function view.build(parent)
    local title = ui.Text.new(parent)
    title:SetPos(12, 12)
    title:SetSize(-24, 28, 1, 0)
    title.font = id.Font.MUSEO_SANS_15PT_REGULAR
    title.content = "Supply Check"

    local body = ui.Text.new(parent)
    body:SetPos(12, 48)
    body:SetSize(-24, -60, 1, 1)
    body.font = id.Font.MUSEO_SANS_15PT_REGULAR
    local previous
    return function(snapshot)
        local text = view.format(snapshot)
        if text ~= previous then
            body.content = text
            previous = text
        end
    end
end

return view
