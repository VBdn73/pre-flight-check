local catalogue = require("supply-catalogue")
local settings = require("warnings/settings")
local view = {}

local function text(parent, x, y, width, value)
    local label = ui.Text.new(parent)
    label:SetPos(x, y); label:SetSize(width, 22)
    label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    label.content = value
    return label
end

local function button(parent, x, y, width, label, callback)
    local b = ui.Button.new(parent)
    b:SetPos(x, y); b:SetSize(width, 25)
    b.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    b.label = label
    b:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return b
end

local function input(parent, x, y, value)
    local field = ui.InputField.new(parent)
    field:SetPos(x, y); field:SetSize(64, 25)
    field.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    field:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NUMBERS_AS_TEXT, 10)
    field.content = tostring(value)
    return field
end

function view.build(parent, rules, onChange)
    text(parent, 10, 8, 460, "Warnings: loose backpack + equipment only; containers excluded.")
    for index, rule in ipairs(rules) do
        local y = 36 + (index - 1) * 145
        text(parent, 10, y, 300, catalogue[rule.itemId].name)
        local enabled, zero = rule.enabled, rule.warnAtZero
        local enabledButton, zeroButton
        enabledButton = button(parent, 10, y + 23, 150, enabled and "Enabled" or "Disabled", function()
            enabled = not enabled
            enabledButton.label = enabled and "Enabled" or "Disabled"
        end)
        zeroButton = button(parent, 170, y + 23, 150, zero and "Warn at zero: on" or "Warn at zero: off", function()
            zero = not zero
            zeroButton.label = zero and "Warn at zero: on" or "Warn at zero: off"
        end)
        text(parent, 10, y + 53, 140, "Low / critical below")
        local low = input(parent, 10, y + 75, rule.low)
        local critical = input(parent, 80, y + 75, rule.critical)
        text(parent, 155, y + 53, 180, "Low / critical repeat (sec)")
        local lowCooldown = input(parent, 155, y + 75, rule.lowCooldown)
        local criticalCooldown = input(parent, 225, y + 75, rule.criticalCooldown)
        local status = text(parent, 110, y + 108, 330, "")
        button(parent, 10, y + 106, 90, "Save", function()
            local candidate = { itemId = rule.itemId, enabled = enabled, warnAtZero = zero,
                low = tonumber(low.content), critical = tonumber(critical.content),
                lowCooldown = tonumber(lowCooldown.content), criticalCooldown = tonumber(criticalCooldown.content) }
            if not settings.valid(candidate) then
                status.content = "Invalid: thresholds > 0, critical <= low; seconds 1-86400."
                return
            end
            local old = rules[index]
            rules[index] = candidate
            if not settings.save(rules) then
                rules[index] = old
                status.content = "Could not save settings."
                return
            end
            onChange()
            status.content = "Saved."
        end)
    end
end

return view
