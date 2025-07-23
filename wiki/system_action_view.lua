-- Default (view) action.

local requestPath, requestExt = ...

SetHeader("Content-Type", "text/html")

wikiAST.serveRender(WikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath
}))
