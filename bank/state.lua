-- Detect a transition of the bank's root component, independently of presets.
local bankClose = {}

function bankClose.new()
    local wasOpen = false
    local function isOpen()
        -- Escape can deactivate the bank while its root is still visible.
        local flagOk, active = pcall(function() return var.VarPlayer.BANK_ACTIVE.value end)
        if flagOk and (active == 0 or active == false) then return false end
        local ok, open = pcall(function()
            local interface = ui.Interfaces:GetInterface(517)
            if not interface then return false end
            local root = ui.Interfaces:GetComponent(517, 0)
            if not root or root.isRestricted then return nil end
            return root.visibleGlobal == true
        end)
        if ok and open ~= nil then return open end
        -- During teardown the root may be temporarily inaccessible.
        return nil
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
            if open == nil then return false end
            local closed = wasOpen and not open
            wasOpen = open
            return closed
        end,
    }
end

return bankClose
