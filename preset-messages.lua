-- Parse only the server's preset withdrawal messages, not player chat.
local messages = {}

function messages.parse(event)
    if not event or (event.chatType ~= 0 and event.chatType ~= 4 and event.chatType ~= 109)
        or type(event.chatMessage) ~= "string" then return end
    local text = event.chatMessage:gsub("<[^>]*>", ""):match("^%s*(.-)%s*$")
    local chargedName, percent = text:match("^Your (.+) has (%d+%.?%d*)%% of its charges left%.$")
    if chargedName and tonumber(percent) <= 100 then
        return "charge", { name = chargedName, level = "critical", status = percent .. "%" }
    end
    if text == "Your preset is being withdrawn. Please see below for any issues whilst trying to load it..." then
        return "start"
    end
    local name = text:match("^Item could not be found: (.+)$")
    if name then return "issue", { name = name, message = text, level = "critical", status = "MISSING" } end
    name = text:match("^Item could not be found in the quantity required: (.+)$")
    if name then return "issue", { name = name, message = text, level = "low", status = "LOW" } end
    name = text:match("^(.+) could not be found%. .+ was loaded instead%.$")
    if name then return "issue", { name = name, message = text, level = "low", status = "DOSE" } end
end

return messages
