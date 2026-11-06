-- Short-lived, non-blocking warning overlay.
local popup = {}
local root, expires

function popup.clear()
    local old = root
    root, expires = nil, nil
    if old then pcall(function() old:Destroy() end) end
end

function popup.show(alerts, now)
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then return false end
    popup.clear()
    local ok, err = pcall(function()
        root = ui.GroupBox.new(parent)
        root.stylesheetID = id.StyleSheet.DEFAULT
        root:SetHeaderLayout(0, 0, 0, 0, 0)
        root:SetPos(-170, 45, 0.5, 0)
        root:SetSize(340, 75 + #alerts * 24)
        root.clickthrough = true
        local body = ui.Text.new(root)
        body:SetPos(10, 8); body:SetSize(-20, -16, 1, 1)
        body.font = id.Font.MUSEO_SANS_15PT_REGULAR
        body.clickthrough = true
        local lines = { "Supply Check: low supplies" }
        for _, alert in ipairs(alerts) do
            lines[#lines + 1] = alert.name .. ": " .. alert.count .. " (" .. alert.level .. ")"
        end
        lines[#lines + 1] = "Backpack + equipment only; containers excluded."
        body.content = table.concat(lines, "<br>")
        expires = now + 8
    end)
    if not ok then
        popup.clear()
        print("[supply-check] Warning popup failed: " .. tostring(err))
        return false
    end
    return true
end

function popup.update(now)
    if expires and now >= expires then popup.clear() end
end

return popup
