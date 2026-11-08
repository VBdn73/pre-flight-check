-- Identify bank preset menu actions and keyboard shortcuts.
local presetTest = {}
-- Client GameKey codes for the bank's numbered and beast-of-burden shortcuts.
function presetTest.isShortcut(event, modifiers)
    local key = event.gameKey
    modifiers = modifiers or event.modifiers
    if event.isRepeat or type(key) ~= "number" then return false end
    if key >= 1 and key <= 9 then return modifiers == 0 end -- F1-F9
    if key == 16 or key == 17 then return modifiers == 0 or modifiers == 2 end
    if key >= 18 and key <= 24 or key == 68 then return modifiers == 2 end
    return false
end
local bankInterface = 517
local presetComponents = {
    [84] = true,  -- Selected preset's load button.
    [117] = true, -- Compact preset labels/buttons.
    [119] = true, -- Compact preset click targets.
    [133] = true, -- Compact beast-of-burden preset.
    [266] = true, -- Preset list labels.
    [267] = true, -- Preset list hit targets.
}

function presetTest.isLoad(entry)
    if entry and type(entry.verbText) == "string"
        and (entry.verbText == "Load Last Preset" or entry.verbText == "Load Last Preset from") then
        return true
    end
    local component = entry and entry.componentData and entry.componentData.component
    if not component or component.isRestricted or component.interfaceID ~= bankInterface then return false end
    return entry.verbText == "Load" and presetComponents[component.staticID] == true
        or entry.verbText == "Select" and component.staticID == 84
end

return presetTest
