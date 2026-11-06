-- Detect a transition of the bank's root component, independently of presets.
local bankClose = {}

function bankClose.new()
    local wasOpen = false
    local function isOpen()
        local ok, open = pcall(function()
            local interface = ui.Interfaces:GetInterface(517)
            if not interface then return false end
            local root = ui.Interfaces:GetComponent(517, 0)
            if not root or root.isRestricted then return nil end
            return root.visibleGlobal == true
        end)
        if not ok then return nil end
        return open
    end
    return {
        reset = function() wasOpen = false end,
        isOpen = function() return isOpen() end,
        isMainPanelOpen = function()
            local ok, visible = pcall(function()
                local active = var.VarPlayer.BANK_ACTIVE.value
                if active ~= 1 and active ~= true then return false end
                if isOpen() ~= true then return false end
                local panel = ui.Interfaces:GetComponent(517, 154) -- BANK__MAIN_PANEL
                return panel and not panel.isRestricted and panel.visibleGlobal == true
            end)
            return ok and visible == true
        end,
        markOpen = function() wasOpen = true end,
        update = function()
            local open = isOpen()
            if open == nil then wasOpen = false; return false end
            local closed = wasOpen and not open
            wasOpen = open
            return closed
        end,
    }
end

return bankClose
