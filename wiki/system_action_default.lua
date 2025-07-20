-- Default (view) action.
wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = {
		path = wikiResolvePage("system/templates/recursion"),
		opts = {}
	}
}))
