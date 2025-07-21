-- Default (view) action.

local requestPath, requestExt = ...

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, wikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath,
	opts = wikiDefaultOpts
}))
