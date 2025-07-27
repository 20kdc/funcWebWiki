local props, renderOptions = ...

-- see also <system/templates/editor>
local pathStr, pathExt = tostring(props.path or wikiEditorTestPath), tostring(props.ext or wikiDefaultExt)

local code = tostring(props.code or wikiRead(pathStr) or "")

local leftColumn = WikiTemplate("system/templates/editor", props)

local renderer = wikiRenderer(pathExt)

local rightColumnOk, rightColumn = wikiPCall(renderer, pathStr, code, {}, renderOptions)
if not rightColumnOk then
	rightColumn = h("pre", {}, tostring(rightColumn))
end

return h("div", {class = "editor2pane"},
	h("div", {class = "editor2pane-left"}, leftColumn),
	h("div", {class = "editor2pane-right"}, rightColumn)
)
