-- Stored overlay positions must be finite and within a reasonable client range.
local position = {}
local MAX_COORDINATE = 100000

function position.valid(value)
    return type(value) == "table" and type(value.x) == "number" and type(value.y) == "number"
        and value.x == value.x and value.y == value.y
        and math.abs(value.x) < MAX_COORDINATE and math.abs(value.y) < MAX_COORDINATE
end

function position.clamp(x, y, parent, width, height)
    if type(parent.width) == "number" and parent.width > 0 then
        x = math.max(0, math.min(x, math.max(0, parent.width - width)))
    end
    if type(parent.height) == "number" and parent.height > 0 then
        y = math.max(0, math.min(y, math.max(0, parent.height - height)))
    end
    return x, y
end

return position
