local props = ...

local errorMessage = props.errorMessage or "This is an example error message."

if errorMessage ~= "" then
	errorMessage = h("p", {class="editor-error"}, tostring(errorMessage))
end

-- see also <system/templates/editorAndPreview>
local pathStr, pathExt = tostring(props.path or wikiEditorTestPath), tostring(props.ext or wikiDefaultExt)

-- <system/action/edit>

if wikiExtText(pathExt) then
	local wouldAppendGoHere = {}
	if props.append then
		wouldAppendGoHere = h("script", {}, "editor.scrollTop = editor.scrollHeight;")
	end
	local code = tostring(props.code or wikiRead(pathStr) or "")
	return {
		errorMessage,
		WikiLink(pathStr, {
			h("textarea", {id="editor", name="code", rows=(props.rows or "25"), cols="80"}, code),
			WikiLink("system/editorUtilities.js", {}, "raw", "script"),
			wouldAppendGoHere,
			h("br"),
			pathStr, " ",
			h("input", {type="submit", name="preview", value="Preview"}),
			h("input", {type="submit", name="confirm", value="Confirm"})
		}, "edit", "formPost")
	}
else
	return {
		errorMessage,
		WikiLink(pathStr, {
			pathStr, " ",
			h("input", {type="file", id="fileinput"}),
			h("input", {type="hidden", id="fileshunt", name="file"}),
			h("input", {type="submit", id="filestatus", name="confirm", value="Upload"}),
			WikiLink("system/editorUtilities.js", {}, "raw", "script"),
		}, "edit", "formPost")
	}
end
