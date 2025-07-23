local props = ...

local pathStr = tostring(props.path or wikiEditorTestPath)

return {
	WikiLink(pathStr, {
		h("input", {type="submit", name="confirm", value=(props.text or "?")})
	}, nil, "formPost")
}
