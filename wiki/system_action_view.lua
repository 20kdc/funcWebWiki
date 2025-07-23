-- Default (view) action.

local requestPath, requestExt = ...

wikiAST.serveRender(WikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath
}))
