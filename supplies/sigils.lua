-- Client cooldown endpoints use Event.Logic's 50 Hz clock. Never compare
-- VarPlayer endpoints to that clock: they use a different time base.
local sigils = {}
local tick
local abilities = {
    { "Aggression", "DEFENCE_AGGRESSION" },
    { "Ingenuity of the Humans", "CONSTITUTION_INGENUITY_OF_THE_HUMANS" },
    { "Demon Slayer", "CONSTITUTION_DEMON_SLAYER" },
    { "Dragon Slayer", "CONSTITUTION_DRAGON_SLAYER" },
    { "Undead Slayer", "CONSTITUTION_UNDEAD_SLAYER" },
    { "Limitless", "CONSTITUTION_LIMITLESS" },
    { "Slayer's Insight", "CONSTITUTION_SLAYING" },
    { "Slayer's Aggression", "CONSTITUTION_FEROCIOUS" },
    { "Vampyre Slayer", "CONSTITUTION_VAMPYRE_SLAYER" },
    { "Vital Drain", "CONSTITUTION_VITAL_DRAIN" },
}

function sigils.setTick(value)
    tick = type(value) == "number" and value >= 0 and value < math.huge
        and value % 1 == 0 and value or nil
end

function sigils.read()
    if not tick then return nil end
    local cooling = {}
    for _, ability in ipairs(abilities) do
        local ok, endpoint = pcall(function()
            return var.VarClient["COMBATV2_COOLDOWN_" .. ability[2] .. "_END_CLIENT"].value
        end)
        if ok and type(endpoint) == "number" and endpoint < math.huge
            and endpoint % 1 == 0 and endpoint > tick then
            cooling[#cooling + 1] = { name = ability[1], seconds = math.ceil((endpoint - tick) / 50) }
        end
    end
    return cooling
end

return sigils
