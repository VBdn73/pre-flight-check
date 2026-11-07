-- Portable colour conversion utilities. No client API needed.
local value = {}
function value.normalize(hex)
    if type(hex) ~= "string" then return nil end
    if hex:match("^#%x%x%x%x%x%x$") then return hex:upper() end
end
function value.rgba(hex)
    hex = value.normalize(hex)
    return hex and tonumber(hex:sub(2), 16) * 256 + 255 or nil
end
function value.vector(hex)
    local rgba = value.rgba(hex)
    if not rgba then return nil end
    return { ((rgba >> 24) & 255) / 255, ((rgba >> 16) & 255) / 255,
        ((rgba >> 8) & 255) / 255, 1 }
end
return value
