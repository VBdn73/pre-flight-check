-- Shared presentation primitives. The view supplies tracking so scrolling,
-- clipping and lazy row destruction work identically for every setting type.
local components = {}

function components.row(context, parent, y, definition)
    local track, entries = context.track, context.entries
    local frame = track(ui.Rectangle.new(parent))
    local entry = entries[#entries]
    frame:SetPos(0, y); frame:SetSize(0, context.rowHeight - 4, 1, 0)
    frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
    entry.background = { x = 0, y = y, width = 0, height = context.rowHeight - 4 }
    local background = track(ui.Rectangle.new(parent))
    background:SetPos(1, y + 1); background:SetSize(-2, context.rowHeight - 6, 1, 0)
    background.fill, background.clickthrough = true, true
    entries[#entries].background = { x = 1, y = y + 1, width = -2, height = context.rowHeight - 6 }
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
