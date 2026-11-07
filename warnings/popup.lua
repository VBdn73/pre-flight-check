-- Short-lived, non-blocking warning overlay.
local popup = {}
local root, expires

function popup.clear()
    local old = root
    root, expires = nil, nil
    if old then pcall(function() old:Destroy() end) end
end

function popup.show(alerts, now, duration)
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then return false end
    popup.clear()
    local ok, err = pcall(function()
        root = ui.GroupBox.new(parent)
        root.stylesheetID = id.StyleSheet.DEFAULT
        root:SetHeaderLayout(0, 0, 0, 0, 0)
        root:SetPos(-170, 45, 0.5, 0)
        root:SetSize(340, 42 + #alerts * 36)
        root.clickthrough = true
        local title = ui.Text.new(root)
        title:SetPos(10, 6); title:SetSize(320, 24)
        title.font = id.Font.MUSEO_SANS_15PT_REGULAR
        title.clickthrough = true
        title.content = "Supply Check"
        for i, alert in ipairs(alerts) do
            local critical = alert.level == "critical"
            local y = 32 + (i - 1) * 36
            local box = ui.Rectangle.new(root)
            box:SetPos(5, y); box:SetSize(324, 32)
            box.fill = true
            box.colour = critical and Vector4.new(0.34, 0.08, 0.08, 1)
                or Vector4.new(0.38, 0.20, 0.06, 1)
            box.clickthrough = true
            local accent = ui.Rectangle.new(root)
            accent:SetPos(5, y); accent:SetSize(4, 32)
            accent.fill = true
            accent.colour = critical and Vector4.new(0.95, 0.25, 0.20, 1)
                or Vector4.new(1, 0.58, 0.16, 1)
            accent.clickthrough = true
            local label = ui.Text.new(root)
            label:SetPos(17, y); label:SetSize(220, 32)
            label.font = id.Font.MUSEO_SANS_15PT_REGULAR
            label.alignVertical = ui.AlignMode.CENTRE
            label.clickthrough = true
            label.content = alert.name .. ": " .. alert.count
            local severity = ui.Text.new(root)
            severity:SetPos(247, y); severity:SetSize(75, 32)
            severity.font = id.Font.MUSEO_SANS_11PT_REGULAR
            severity.alignHorizontal = ui.AlignMode.BOTTOMRIGHT
            severity.alignVertical = ui.AlignMode.CENTRE
            severity.clickthrough = true
            severity.content = critical and "CRITICAL" or "LOW"
        end
        expires = now + (duration or 4)
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
