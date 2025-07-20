local opts = ...

local code = opts.code or ""

return {
	WikiLink(opts.path, {
		h("textarea", {id="editor", name="code", rows="25", cols="80"}, code),
		h("script", {}, Slurp("system/editorUtilities.js")),
		h("br"),
		h("input", {type="submit", name="preview", value="Preview"}),
		h("input", {type="submit", name="confirm", value="Confirm"})
	}, "edit", "formPost"),
	function (c)
		if opts.preview then
			local templatePath, templateExt = wikiResolvePage(opts.path)
			local renderer = wikiRenderer(templateExt)
			c(renderer(templatePath, code, {}))
		end
	end
}
