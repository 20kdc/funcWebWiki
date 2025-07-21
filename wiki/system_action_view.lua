-- Default (view) action.

local requestPath, requestExt = ...

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath,
	opts = wikiDefaultOpts
}))
