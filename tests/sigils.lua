local sigils = require("supplies/sigils")
local prefix = "COMBATV2_COOLDOWN_CONSTITUTION_"
var = { VarClient = {
    [prefix .. "UNDEAD_SLAYER_END_CLIENT"] = { value = 41758 },
    [prefix .. "LIMITLESS_END_CLIENT"] = { value = 41858 },
} }
assert(sigils.read() == nil)
sigils.setTick(38759)
local cooling = sigils.read()
assert(#cooling == 2 and cooling[1].name == "Undead Slayer" and cooling[1].seconds == 60)
local monitor = require("warnings/monitor").new({ sigilCooldowns = true })
assert(#monitor.update({ sigilCooldowns = cooling }) == 2)
assert(#require("warnings/monitor").new({ sigilCooldowns = false }).update({ sigilCooldowns = cooling }) == 0)
sigils.setTick(41758)
assert(#sigils.read() == 1, "natural expiry ignores stale positive endpoints")
var.VarClient[prefix .. "LIMITLESS_END_CLIENT"].value = 0
assert(#sigils.read() == 0, "altar reset")
var.VarClient[prefix .. "LIMITLESS_END_CLIENT"].value = math.huge
assert(#sigils.read() == 0)
var = nil
assert(#sigils.read() == 0, "missing variables must not warn")
sigils.setTick(nil)
assert(sigils.read() == nil)
local settings = require("warnings/settings")
assert(settings.defaults().sigilCooldowns == true)
local saved
PersistentDB = {
    SetStructuredData = function(_, _, data) saved = data; return true end,
    GetStructuredData = function() return saved end,
}
local rules = settings.defaults()
rules.sigilCooldowns = false
assert(settings.save(rules) and settings.load().sigilCooldowns == false)
print("Sigil cooldown mock tests passed.")
