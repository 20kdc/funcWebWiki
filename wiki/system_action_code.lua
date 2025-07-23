-- Similar to <system/action/view> but sets the 'code' flag.
-- This flag causes <system/lib/WikiTemplate> to use a level of indirection; see <system/extensions/code>.

local requestPath, requestExt = ...

wikiAST.serveRender(WikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath,
	code = true
}))
