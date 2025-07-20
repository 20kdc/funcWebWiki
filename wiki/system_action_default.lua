-- Default (view) action.
wikiAST.render(Write, wikiLoadTemplate("system/templates/frame")({
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = {
		path = "system/templates/recursion",
		opts = {}
	}
}), false)
