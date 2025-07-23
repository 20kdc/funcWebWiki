local props = ...

local pathStr = tostring(props.path or wikiEditorTestPath)

-- beware!

return {
	WikiLink(pathStr, {
		h("input", {type="submit", name="confirm", value="Delete " .. pathStr})
	}, "delete", "formPost")
	-- <system/action/delete>
}
