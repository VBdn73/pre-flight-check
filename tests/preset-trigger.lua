local presetTest = require("bank/preset-trigger")
assert(presetTest.isShortcut({ gameKey = 16, modifiers = 0, isRepeat = false }))
assert(presetTest.isShortcut({ gameKey = 1, modifiers = 0, isRepeat = false }))
assert(presetTest.isShortcut({ gameKey = 3, modifiers = 0, isRepeat = false }))
assert(presetTest.isShortcut({ gameKey = 18, modifiers = 2, isRepeat = false }))
assert(presetTest.isShortcut({ gameKey = 18, modifiers = 4, isRepeat = false }, 2))
assert(presetTest.isShortcut({ gameKey = 68, modifiers = 2, isRepeat = false }))
assert(not presetTest.isShortcut({ gameKey = 18, modifiers = 0, isRepeat = false }))
assert(not presetTest.isShortcut({ gameKey = 68, modifiers = 0, isRepeat = false }))
assert(not presetTest.isShortcut({ gameKey = 1, modifiers = 2, isRepeat = false }))
assert(not presetTest.isShortcut({ gameKey = 16, modifiers = 0, isRepeat = true }))
assert(not presetTest.isShortcut({ gameKey = 16, modifiers = 1, isRepeat = false }))
assert(not presetTest.isShortcut({ gameKey = 30, modifiers = 0, isRepeat = false }))
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
