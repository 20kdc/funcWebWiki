-- Default (view) action.

local requestPath, requestExt = ...

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, WikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath,
	opts = wikiDefaultOpts
}))
