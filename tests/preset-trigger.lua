local presetTest = require("bank/preset-trigger")
-- Supported shortcuts and rejected modifiers, repeats, and keys.
local shortcutCases = {
    { "preset key", 16, 0, false, true },
    { "first number key", 1, 0, false, true },
    { "number key", 3, 0, false, true },
    { "modified shortcut", 18, 2, false, true },
    { "custom modifier", 18, 4, false, true, 2 },
    { "modified letter", 68, 2, false, true },
    { "missing modifier", 18, 0, false, false },
    { "unmodified letter", 68, 0, false, false },
    { "modified number", 1, 2, false, false },
    { "repeat", 16, 0, true, false },
    { "wrong modifier", 16, 1, false, false },
    { "unrelated key", 30, 0, false, false },
}
for _, case in ipairs(shortcutCases) do
    local name, key, modifiers, repeatKey, expected, customModifier = table.unpack(case)
    local result = presetTest.isShortcut({ gameKey = key, modifiers = modifiers, isRepeat = repeatKey }, customModifier)
    assert(not not result == expected, name)
end
-- Menu actions must match a supported bank component and verb.
local function entry(verb, interface, component)
    return { verbText = verb, componentData = { component = {
        interfaceID = interface, staticID = component } } }
end
for _, component in ipairs({ 84, 117, 119, 133, 266, 267 }) do
    assert(presetTest.isLoad(entry("Load", 517, component)))
end
assert(not presetTest.isLoad(nil))
assert(not presetTest.isLoad(entry("Select", 517, 267)))
assert(presetTest.isLoad(entry("Select", 517, 84)))
assert(not presetTest.isLoad(entry("Select", 518, 84)))
assert(not presetTest.isLoad(entry("Load", 518, 267)))
assert(not presetTest.isLoad(entry("Load", 517, 999)))
assert(presetTest.isLoad({ verbText = "Load Last Preset from" }))
assert(presetTest.isLoad({ verbText = "Load Last Preset" }))
assert(not presetTest.isLoad({ verbText = "Examine" }))
local restricted = entry("Load", 517, 267)
restricted.componentData.component.isRestricted = true
assert(not presetTest.isLoad(restricted))
print("Preset trigger tests passed.")
