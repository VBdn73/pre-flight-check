-- Experimental reads of undocumented per-instance fields; never used for counts.
local probe = {}
local previous

local function get(object, key)
    local ok, result = pcall(function() return object[key] end)
    if ok then return result end
end

local function describe(source)
    local ok, result = pcall(function()
        local inventory = Inventory.Find(config.Inv[source])
        if not inventory or not inventory.isValid then return source .. ": unavailable" end
        local slots = inventory:GetSlots()
        if type(slots) ~= "table" then return source .. ": slots unavailable" end
        local entries = {}
        for index, slot in pairs(slots) do
            local obj = slot and slot.obj
            local id = obj and obj.id
            if id == 52532 or (type(id) == "number" and id >= 52580 and id <= 52586) then
                local vars = get(slot, "vars")
                local fields = {}
                for _, key in ipairs({ "legacyvarobj", "objvar_1" }) do
                    local field = get(slot, key)
                    if field == nil and vars ~= nil then field = get(vars, key) end
                    fields[#fields + 1] = key .. "=" .. (type(field) == "number" and tostring(field) or "not exposed")
                end
                entries[#entries + 1] = "slot=" .. tostring(index) .. " id=" .. id .. " " .. table.concat(fields, " ")
            end
        end
        table.sort(entries)
        return source .. ": " .. (#entries > 0 and table.concat(entries, "; ") or "no Pernix quiver found")
    end)
    return ok and result or (source .. ": read failed: " .. tostring(result))
end

function probe.read()
    return describe("INV") .. "\n" .. describe("WORN")
end

function probe.update()
    local result = probe.read()
    if result ~= previous then
        print("[supply-check] Quiver field probe (experimental):\n" .. result)
        previous = result
    end
end

function probe.reset() previous = nil end
return probe
