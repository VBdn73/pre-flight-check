-- Native controls stay in content coordinates. Only input text needs special
-- clipping: the client can draw it outside an ancestor's scroll viewport.
local scroll = {}

function scroll.wheelHandler(page)
    return function(_, delta)
        if not page.scrollbarVisible then return true end
        page:ScrollBy(delta * 32)
        return false
    end
end

function scroll.registerInput(controller, field)
    local target = { root = field, interfaceID = field.interfaceID }
    function target:_SetContentClipped(clipped)
        local appearance = self.appearance
        if clipped and not appearance then
            self.appearance = {
                textRGBA = field.text.rgba, shadow = field.text.isShadowed,
                emptyTextRGBA = field.emptyTextRGBA, caretRGBA = field.caretRGBA,
                errorCaretRGBA = field.errorCaretRGBA, selectionRGBA = field.selectionHighlightRGBA,
            }
            field.text.rgba, field.text.isShadowed = 0, false
            field.emptyTextRGBA, field.caretRGBA = 0, 0
            field.errorCaretRGBA, field.selectionHighlightRGBA = 0, 0
        elseif not clipped and appearance then
            field.text.rgba, field.text.isShadowed = appearance.textRGBA, appearance.shadow
            field.emptyTextRGBA, field.caretRGBA = appearance.emptyTextRGBA, appearance.caretRGBA
            field.errorCaretRGBA, field.selectionHighlightRGBA = appearance.errorCaretRGBA, appearance.selectionRGBA
            self.appearance = nil
        end
    end
    controller:RegisterClipTarget(target)
    return target
end

return scroll
