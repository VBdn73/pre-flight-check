-- Shared presentation primitives. Rows retain fixed content coordinates;
-- the page's native viewport owns scrolling and clipping.
local components = {}

function components.row(context, parent, y, definition)
    local track, entries = context.track, context.entries
    local frame = track(ui.Rectangle.new(parent))
    local entry = entries[#entries]
    frame:SetPos(0, y); frame:SetSize(0, context.rowHeight - 4, 1, 0)
    frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
    local background = track(ui.Rectangle.new(parent))
    background:SetPos(1, y + 1); background:SetSize(-2, context.rowHeight - 6, 1, 0)
    background.fill, background.clickthrough = true, true
    local sprite = context.icon(parent, 8, y + 3, definition.icon)
    sprite.clickthrough = true
    local label = context.text(parent, 48, y + 3, 90, definition.name)
    label:SetSize(definition.labelWidth or -300, 32, 1, 0)
    label.alignVertical, label.clickthrough = ui.AlignMode.CENTRE, true
    return entry, background, sprite, label
end

function components.dropdown(page, definition, onToggle)
    return { count = 0, section = page:AddCollapseButton(definition.name, {
        expanded = false, indent = 0, onToggle = onToggle,
    }) }
end

return components
