-- Native settings controls; tracking and persistence belong to the view.
local fields = {}
local LABEL_HEIGHT = 22
local INPUT_WIDTH, INPUT_HEIGHT, INPUT_MAX_LENGTH = 64, 25, 10
local ICON_WIDTH, ICON_HEIGHT, SPRITE_SIZE = 36, 32, 32

function fields.text(parent, x, y, width, value)
    local label = ui.Text.new(parent)
    label:SetPos(x, y)
    label:SetSize(width, LABEL_HEIGHT)
    label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    label.content = value
    return label
end

function fields.input(parent, x, y, value)
    local field = ui.InputField.new(parent)
    field:SetPos(x, y)
    field:SetSize(INPUT_WIDTH, INPUT_HEIGHT)
    field.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    field:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NUMBERS_AS_TEXT, INPUT_MAX_LENGTH)
    field.content = tostring(value)
    return field
end

function fields.icon(parent, x, y, itemId)
    local sprite = ui.Sprite.new(parent)
    sprite:SetPos(x, y)
    sprite:SetSize(ICON_WIDTH, ICON_HEIGHT)
    if type(itemId) == "table" then
        sprite:SetPos(x + (ICON_WIDTH - SPRITE_SIZE) / 2, y)
        sprite:SetSize(SPRITE_SIZE, SPRITE_SIZE)
        sprite.sprite = itemId.sprite
    else
        sprite:SetAssociatedObject(itemId)
    end
    return sprite
end

return fields
