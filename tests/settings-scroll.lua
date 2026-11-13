local scroll = require("warnings/settings-scroll")
local controller = {}
function controller:RegisterClipTarget(target) self.target = target end
local field = { interfaceID = 123, content = "1234", enabled = true,
    text = { rgba = 42, isShadowed = true }, emptyTextRGBA = 43,
    caretRGBA = 44, errorCaretRGBA = 45, selectionHighlightRGBA = 46 }
local target = scroll.registerInput(controller, field)
assert(controller.target == target and target.root == field and target.interfaceID == 123)
target:_SetContentClipped(true)
assert(field.text.rgba == 0 and not field.text.isShadowed)
assert(field.emptyTextRGBA == 0 and field.caretRGBA == 0)
assert(field.errorCaretRGBA == 0 and field.selectionHighlightRGBA == 0)
assert(field.content == "1234" and field.enabled and field.hidden == nil)
target:_SetContentClipped(true)
target:_SetContentClipped(false)
assert(field.text.rgba == 42 and field.text.isShadowed)
assert(field.emptyTextRGBA == 43 and field.caretRGBA == 44)
assert(field.errorCaretRGBA == 45 and field.selectionHighlightRGBA == 46)
target:_SetContentClipped(false)
assert(field.text.rgba == 42 and target.appearance == nil)
print("Settings native scroll tests passed.")
