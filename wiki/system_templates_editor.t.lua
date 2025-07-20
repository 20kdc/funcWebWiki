local opts = ...

local code = tostring(opts.code or Slurp(tostring(opts.path)) or "")
return {
	WikiLink(opts.path, {
		h("textarea", {id="editor", name="code", rows="25", cols="80"}, code),
		h("script", {}, Slurp("system/editorUtilities.js")),
		h("br"),
		opts.path, " ",
		h("input", {type="submit", name="preview", value="Preview"}),
		h("input", {type="submit", name="confirm", value="Confirm"})
	}, "edit", "formPost")
}
