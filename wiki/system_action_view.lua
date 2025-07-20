-- Default (view) action.

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = wikiDefaultOpts
}))
