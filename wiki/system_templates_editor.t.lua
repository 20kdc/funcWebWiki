local opts = ...

local pathStr = tostring(opts.path)

local pathDot = pathStr:find(".", 1, true) or (#pathStr + 1)
local pathExt = pathStr:sub(pathDot)

-- <system/action/w/edit>

if wikiExtText(pathExt) then
	local code = tostring(opts.code or wikiRead(pathStr) or "")
	return {
		WikiLink(opts.path, {
			h("textarea", {id="editor", name="code", rows="25", cols="80"}, code),
			WikiLink("system/editorUtilities.js", {}, "raw", "script"),
			h("br"),
			opts.path, " ",
			h("input", {type="submit", name="preview", value="Preview"}),
			h("input", {type="submit", name="confirm", value="Confirm"})
		}, "w/edit", "formPost")
	}
else
	return {
		WikiLink(opts.path, {
			opts.path, " ",
			h("input", {type="file", id="fileinput"}),
			h("input", {type="hidden", id="fileshunt", name="file"}),
			h("input", {type="submit", id="filestatus", name="confirm", value="Upload"}),
			WikiLink("system/editorUtilities.js", {}, "raw", "script"),
		}, "w/edit", "formPost")
	}
end
