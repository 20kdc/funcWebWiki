-- Nav panel for frame.

local props, renderOptions = ...

local nonSystemPages = {}

for _, v in ipairs(wikiPathList()) do
	local visible = true -- Written this way for easier rebasing for downstreams.

	-- Hide hidden pages.
	if v:find(".z.", 1, true) then visible = false end

	-- Hide system pages.
	if v:sub(1, 7) == "system/" then visible = false end

	-- option: Hide special pages when in read-only mode. Not an access restriction, just a UI cleanup.
	-- if wikiReadOnly and v:sub(1, 8) == "special/" then visible = false end

	if visible then
		table.insert(nonSystemPages, v)
	end
end

local requestPath = props.parentPath or props.path or wikiEditorTestPath

return {
	-- <system/action/navigate>
	WikiLink(wikiDefaultPage, {
		h("input", {name = "to", value = requestPath}),
		h("input", {type = "submit", value = "Go"})
	}, "navigate", "formPost"),
	WikiDepMarker(),
	WikiTemplate("system/templates/sortedPageList", {
		tree = true,
		pageList = nonSystemPages
	})
}
