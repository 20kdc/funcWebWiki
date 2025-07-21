-- Similar to <system/action/view> but sets the 'code' flag.
-- This flag causes <system/lib/wikiLoadTemplate> to use a level of indirection; see <system/extensions/code>.

local requestPath, requestExt = ...

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, wikiTemplate("system/index/frame", {
	title = wikiTitleStylize(requestPath),
	path = requestPath,
	opts = wikiDefaultOpts,
	code = true
}))
