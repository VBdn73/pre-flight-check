-- Detect a transition of the bank's root component, independently of presets.
local bankClose = {}

function bankClose.new()
    local wasOpen = false
    return {
        reset = function() wasOpen = false end,
        update = function()
            local ok, open = pcall(function()
                local interface = ui.Interfaces:GetInterface(517)
                if not interface then return false end
                local root = ui.Interfaces:GetComponent(517, 0)
                if not root or root.isRestricted then return nil end
                return root.visibleGlobal == true
            end)
            if not ok or open == nil then wasOpen = false; return false end
            local closed = wasOpen and not open
            wasOpen = open
            return closed
        end,
    }
end

return bankClose
