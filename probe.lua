-- Temporary diagnostic: WORN and its slot layout must be verified in-client.
local probe = {}
local previous = {}

local function describe(name)
    local ok, result = pcall(function()
        if not Inventory or not config or not config.Inv then return "API unavailable" end
        local binding = config.Inv[name]
        if not binding then return "config.Inv." .. name .. " unavailable" end
        local inv = Inventory.Find(binding)
        if not inv then return "Inventory.Find returned nil" end
        if not inv.isValid then return "inventory invalid" end
        local slots = inv:GetSlots()
        if type(slots) ~= "table" then return "GetSlots unavailable" end

        local lines = { "valid; slotCount=" .. tostring(inv.slotCount)
            .. ", usedSlotCount=" .. tostring(inv.usedSlotCount) }
        local entries = {}
        for index, slot in pairs(slots) do
            local obj = slot and slot.obj
            entries[#entries + 1] = "slot=" .. tostring(index)
                .. " id=" .. tostring(obj and obj.id)
                .. " count=" .. tostring(slot and slot.count)
        end
        table.sort(entries)
        if #entries == 0 then entries[1] = "GetSlots returned an empty table" end
        for _, entry in ipairs(entries) do lines[#lines + 1] = entry end
        return table.concat(lines, "\n")
    end)
    if not ok then return "read failed: " .. tostring(result) end
    return result
end

function probe.update()
    for _, name in ipairs({ "INV", "WORN" }) do
        local result = describe(name)
        if result ~= previous[name] then
            print("[supply-check] " .. name .. ": " .. result)
            previous[name] = result
        end
    end
end

return probe
