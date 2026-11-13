local messages = require("bank/preset-messages")
local header = "Your preset is being withdrawn. Please see below for any issues whilst trying to load it..."
local bob = "Unable to load beast of burden preset as this follower can't hold any items."
local cases = {
    { header, "start" },
    { "Item could not be found: Powder of protection", "issue", "Powder of protection", "critical", "MISSING" },
    { "Item could not be found in the quantity required: Ectoplasm", "issue", "Ectoplasm", "low", "LOW" },
    { "Perfect plus potion (1) could not be found. Perfect plus potion (4) was loaded instead.",
        "issue", "Perfect plus potion (1)", "low", "DOSE" },
    { bob, "issue", "Beast of burden preset", "critical", "FAILED" },
    { "Your Test armour has 3.9% of its charges left.", "charge", "Test armour", "critical", "3.9%" },
    { "Your Test armour has 0% of its charges left.", "charge", "Test armour", "critical", "0%" },
    { "Your Test armour has 100% of its charges left.", "charge", "Test armour", "critical", "100%" },
}
for _, case in ipairs(cases) do
    local text, expected, name, level, status = table.unpack(case)
    for _, chatType in ipairs({ 0, 4, 109 }) do
        local kind, alert = messages.parse({ chatMessage = " <col=ff0000>" .. text .. "</col> ", chatType = chatType })
        assert(kind == expected, text)
        if name then
            assert(alert.name == name and alert.level == level and alert.status == status, text)
            if kind == "issue" then assert(alert.message == text, text) end
        end
    end
    assert(not messages.parse({ chatMessage = text, chatType = 2 }), "player chat: " .. text)
end
for _, text in ipairs({ "Unrelated message", "Item could not be found: ",
    "Your armour has 101% of its charges left.", "Your armour has -1% of its charges left.",
    "Your armour has many% of its charges left." }) do
    assert(not messages.parse({ chatMessage = text, chatType = 0 }), text)
end
assert(not messages.parse(nil))
assert(not messages.parse({ chatMessage = 42, chatType = 0 }))
assert(not messages.parse({ chatMessage = header }))
print("Preset message tests passed.")
